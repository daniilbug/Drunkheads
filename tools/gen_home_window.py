#!/usr/bin/env python3
"""Generate a decorative closed window for the apartment wall."""

import argparse
from pathlib import Path

from PIL import Image, ImageDraw


SPRITES = Path(__file__).resolve().parents[1] / "assets/sprites/home"


def generate() -> Image.Image:
    image = Image.new("RGBA", (28, 20))
    draw = ImageDraw.Draw(image)
    dark, wood, light = "#604738", "#916e53", "#b38c68"

    # Wooden frame with two equal glazed leaves.
    draw.rectangle((1, 0, 26, 17), fill=dark)
    draw.rectangle((2, 1, 25, 16), fill=wood)
    draw.line((2, 1, 25, 1), fill=light)
    for left in (3, 15):
        draw.rectangle((left, 2, left + 9, 15), fill=dark)
        draw.rectangle((left + 1, 3, left + 8, 14), fill=(141, 210, 227, 140))

    # Paired handles sit on the uniform glass, inset from the central frame.
    draw.line((13, 2, 13, 15), fill=light)
    for x in (10, 17):
        draw.line((x, 10, x, 12), fill="#d6bb8d")

    # A shallow sill provides a clear lower edge without a cast shadow.
    draw.rectangle((0, 17, 27, 19), fill=dark)
    draw.line((1, 17, 26, 17), fill=light)
    draw.line((1, 18, 26, 18), fill=wood)
    return image


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--preview", type=Path)
    args = parser.parse_args()
    window = generate()
    output = SPRITES / "window.png"
    window.save(output)
    print(output)
    if args.preview:
        preview = Image.new("RGBA", (64, 48))
        wall = Image.open(SPRITES / "wall.png").convert("RGBA")
        for y in range(0, preview.height, wall.height):
            for x in range(0, preview.width, wall.width):
                preview.alpha_composite(wall, (x, y))
        preview.alpha_composite(window, (18, 14))
        args.preview.parent.mkdir(parents=True, exist_ok=True)
        preview.resize((512, 384), Image.Resampling.NEAREST).save(args.preview)
        print(args.preview)


if __name__ == "__main__":
    main()
