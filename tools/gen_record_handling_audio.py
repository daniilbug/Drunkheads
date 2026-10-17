#!/usr/bin/env python3
"""Generate a short, soft record-handling foley sound, without external samples."""
import math
from pathlib import Path
import random
import struct
import wave

OUT = Path(__file__).resolve().parents[1] / 'assets/audio/cafe/record_handling.wav'
RATE = 44100
DURATION = 0.22


def generate():
    rng = random.Random(71)
    samples = []
    noise = 0.0
    dc = 0.0
    for i in range(round(RATE * DURATION)):
        t = i / RATE
        # Low-pass filtered friction, followed by a muted plastic/wood contact.
        noise += 0.16 * (rng.uniform(-1.0, 1.0) - noise)
        brush = 0.16 * noise * math.sin(math.pi * min(t / 0.11, 1.0)) ** 2
        contact = 0.0
        for start, frequency, decay, amplitude in [
            (0.035, 210.0, 42.0, 0.13),
            (0.035, 510.0, 65.0, 0.045),
            (0.061, 340.0, 90.0, 0.025),
        ]:
            age = t - start
            if age >= 0.0:
                attack = min(age / 0.003, 1.0)
                contact += amplitude * attack * math.exp(-decay * age) * math.sin(2 * math.pi * frequency * age)
        value = brush + contact
        dc += 0.003 * (value - dc)
        fade = min(1.0, t / 0.004, (DURATION - t) / 0.025)
        samples.append((value - dc) * max(fade, 0.0))
    gain = 0.6 / max(abs(value) for value in samples)
    data = b''.join(struct.pack('<h', round(value * gain * 32767)) for value in samples)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(OUT), 'wb') as wav:
        wav.setparams((1, 2, RATE, 0, 'NONE', 'not compressed'))
        wav.writeframes(data)
    print(f'Generated {OUT}: {DURATION:.2f}s mono PCM, {RATE} Hz')


if __name__ == '__main__':
    generate()
