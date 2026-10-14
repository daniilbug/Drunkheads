#!/usr/bin/env python3
"""Prepare the Mixkit 2930 stereo PCM WAV for a continuous balcony loop."""

import argparse
from array import array
from pathlib import Path
import sys
import wave


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    args = parser.parse_args()
    output = Path(__file__).resolve().parents[1] / "assets/audio/home/city_ambience.wav"
    with wave.open(str(args.source), "rb") as source:
        params = source.getparams()
        if params.sampwidth != 2 or params.comptype != "NONE":
            raise ValueError("Expected 16-bit PCM WAV")
        samples = array("h", source.readframes(params.nframes))
    if sys.byteorder != "little":
        samples.byteswap()

    # Overlap the tail with the head, then loop back into the untouched body.
    overlap = round(params.framerate * 0.75)
    if params.nframes <= 2 * overlap:
        raise ValueError("Recording is too short for this crossfade")
    channels = params.nchannels
    blend = array("h")
    for frame in range(overlap):
        weight = frame / (overlap - 1)
        for channel in range(channels):
            tail = samples[(params.nframes - overlap + frame) * channels + channel]
            head = samples[frame * channels + channel]
            blend.append(round(tail * (1 - weight) + head * weight))
    loop = samples[overlap * channels:-overlap * channels] + blend
    if sys.byteorder != "little":
        loop.byteswap()
    output.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(output), "wb") as destination:
        destination.setparams(params)
        destination.writeframes(loop.tobytes())
    print(output)


if __name__ == "__main__":
    main()
