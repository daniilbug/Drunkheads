#!/usr/bin/env python3
"""Generate distinct soft placement and lifting foley, without external samples."""
import math
from pathlib import Path
import random
import struct
import wave

OUT = Path(__file__).resolve().parents[1] / 'assets/audio/cafe'
RATE = 44100


def generate(action, duration, seed, friction, brush_duration, contacts, peak, click_at=None):
    rng = random.Random(seed)
    samples = []
    noise = 0.0
    dc = 0.0
    for i in range(round(RATE * duration)):
        t = i / RATE
        # Low-pass filtered friction, with a brief broadband click on placement.
        raw_noise = rng.uniform(-1.0, 1.0)
        noise += friction * (raw_noise - noise)
        brush = 0.16 * noise * math.sin(math.pi * min(t / brush_duration, 1.0)) ** 2
        click = 0.0
        if click_at is not None and t >= click_at:
            age = t - click_at
            click = 0.24 * (raw_noise - noise) * min(age / 0.0004, 1.0) * math.exp(-280.0 * age)
        contact = 0.0
        for start, frequency, decay, amplitude in contacts:
            age = t - start
            if age >= 0.0:
                attack = min(age / 0.003, 1.0)
                contact += amplitude * attack * math.exp(-decay * age) * math.sin(2 * math.pi * frequency * age)
        value = brush + contact + click
        dc += 0.003 * (value - dc)
        fade = min(1.0, t / 0.004, (duration - t) / 0.025)
        samples.append((value - dc) * max(fade, 0.0))
    gain = peak / max(abs(value) for value in samples)
    data = b''.join(struct.pack('<h', round(value * gain * 32767)) for value in samples)
    OUT.mkdir(parents=True, exist_ok=True)
    path = OUT / f'record_{action}.wav'
    with wave.open(str(path), 'wb') as wav:
        wav.setparams((1, 2, RATE, 0, 'NONE', 'not compressed'))
        wav.writeframes(data)
    print(f'Generated {path}: {duration:.2f}s mono PCM, {RATE} Hz')


if __name__ == '__main__':
    # A short dry click marks contact, followed by a muted platter resonance.
    generate('place', 0.22, 71, 0.16, 0.11, [
        (0.018, 210.0, 55.0, 0.10),
        (0.018, 1450.0, 180.0, 0.055),
        (0.024, 510.0, 85.0, 0.025),
    ], 0.6, click_at=0.018)
    # Lifting has a lighter initial release, followed by a longer vinyl brush.
    generate('remove', 0.18, 97, 0.24, 0.15, [
        (0.008, 390.0, 95.0, 0.055),
        (0.008, 730.0, 120.0, 0.018),
    ], 0.45)
