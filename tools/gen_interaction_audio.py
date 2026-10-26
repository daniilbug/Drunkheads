#!/usr/bin/env python3
"""Generate short scissors, fabric and transport foley without external samples."""
import math
from pathlib import Path
import random
import struct
import wave

OUT = Path(__file__).resolve().parents[1] / "assets/audio/interactions"
RATE = 44100


def brush(samples, rng, start, duration, gain, cutoff, flutter=0.0):
    """Band-limited friction with a rounded envelope and irregular pressure."""
    low = 0.0
    rumble = 0.0
    alpha = 1.0 - math.exp(-math.tau * cutoff / RATE)
    first = round(start * RATE)
    for offset in range(round(duration * RATE)):
        t = offset / RATE
        low += alpha * (rng.uniform(-1.0, 1.0) - low)
        rumble += 0.025 * (low - rumble)
        envelope = math.sin(math.pi * t / duration) ** 1.4
        pressure = 0.72 + 0.18 * math.sin(math.tau * flutter * t) + 0.1 * math.sin(151.0 * t)
        index = first + offset
        if index < len(samples):
            samples[index] += gain * (low - rumble) * envelope * pressure


def contact(samples, rng, start, gain, frequency, decay):
    """A dry contact with a short, damped body resonance."""
    first = round(start * RATE)
    duration = min(0.28, 9.0 / decay)
    for offset in range(round(duration * RATE)):
        t = offset / RATE
        attack = min(t / 0.0015, 1.0)
        tone = math.sin(math.tau * frequency * t)
        tone += 0.3 * math.sin(math.tau * frequency * 2.37 * t)
        click = 0.65 * rng.uniform(-1.0, 1.0) * math.exp(-700.0 * t)
        index = first + offset
        if index < len(samples):
            samples[index] += gain * attack * (tone * math.exp(-decay * t) + click)


def write(name, samples, peak=0.65):
    dc = 0.0
    for index, value in enumerate(samples):
        dc += 0.003 * (value - dc)
        fade = min(1.0, index / (RATE * 0.004), (len(samples) - 1 - index) / (RATE * 0.025))
        samples[index] = (value - dc) * fade
    gain = peak / max(abs(value) for value in samples)
    data = b"".join(struct.pack("<h", round(value * gain * 32767)) for value in samples)
    OUT.mkdir(parents=True, exist_ok=True)
    with wave.open(str(OUT / f"{name}.wav"), "wb") as wav:
        wav.setparams((1, 2, RATE, 0, "NONE", "not compressed"))
        wav.writeframes(data)
    print(f"{name}: {len(samples) / RATE:.2f}s, mono PCM, {RATE} Hz")


def haircut():
    rng = random.Random(381)
    samples = [0.0] * round(RATE * 0.95)
    for index, start in enumerate((0.025, 0.19, 0.38, 0.56, 0.75)):
        brush(samples, rng, start, 0.065, 0.45, 6500.0, 45.0)
        contact(samples, rng, start + 0.054, 0.12, 2800.0 + index * 73, 155.0)
        contact(samples, rng, start + 0.085, 0.035, 4200.0, 220.0)
    write("haircut", samples, 0.55)


def clothing():
    rng = random.Random(547)
    samples = [0.0] * round(RATE * 0.62)
    for start, duration, gain, cutoff in (
        (0.01, 0.24, 0.65, 2400.0),
        (0.17, 0.25, 0.50, 3300.0),
        (0.36, 0.22, 0.38, 1800.0),
    ):
        brush(samples, rng, start, duration, gain, cutoff, 27.0)
    write("clothing_change", samples, 0.55)


def transport(boarding):
    rng = random.Random(719 if boarding else 823)
    samples = [0.0] * round(RATE * (0.85 if boarding else 1.0))
    contact(samples, rng, 0.025, 0.16, 1400.0, 100.0)  # Handle/latch.
    brush(samples, rng, 0.06, 0.28, 0.35, 1900.0, 13.0)  # Door movement.
    if boarding:
        brush(samples, rng, 0.28, 0.25, 0.28, 1400.0, 19.0)  # Seat fabric.
        contact(samples, rng, 0.38, 0.15, 95.0, 45.0)
        closing = 0.61
    else:
        contact(samples, rng, 0.38, 0.12, 170.0, 65.0)  # Two steps out.
        contact(samples, rng, 0.55, 0.10, 195.0, 65.0)
        closing = 0.75
    brush(samples, rng, closing - 0.13, 0.14, 0.25, 2400.0)
    contact(samples, rng, closing, 0.38, 82.0, 36.0)  # Muted door thump.
    contact(samples, rng, closing + 0.005, 0.09, 680.0, 95.0)
    write("transport_board" if boarding else "transport_exit", samples)


if __name__ == "__main__":
    haircut()
    clothing()
    transport(True)
    transport(False)
