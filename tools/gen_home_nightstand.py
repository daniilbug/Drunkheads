#!/usr/bin/env python3
"""Generate a small wooden bedside cabinet matching the home's bed."""

import argparse
from pathlib import Path

from PIL import Image, ImageDraw

from home_furniture_palette import EDGE, HANDLE, SEAM, TOP, WOOD


SPRITES = Path(__file__).resolve().parents[1] / "assets/sprites/home"


def generate() -> Image.Image:
    image = Image.new("RGBA", (14, 16))
    draw = ImageDraw.Draw(image)
    # Keep both drawer handles and the original feet; separate planes by tone.
    for left in (2, 10):
        draw.rectangle((left, 13, left + 1, 15), fill=EDGE)
    draw.rectangle((0, 0, 13, 13), fill=WOOD)
    draw.rectangle((0, 0, 13, 4), fill=TOP)
    draw.line((0, 5, 13, 5), fill=SEAM)
    draw.line((0, 9, 13, 9), fill=SEAM)
    for y in (7, 11):
        draw.line((6, y, 7, y), fill=HANDLE)
    return image


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--preview", type=Path)
    args = parser.parse_args()
    sprite = generate()
    output = SPRITES / "nightstand.png"
    sprite.save(output)
    print(output)

    if args.preview:
        floor = Image.open(SPRITES / "floor.png").convert("RGBA")
        preview = Image.new("RGBA", (64, 56))
        for y in range(0, preview.height, floor.height):
            for x in range(0, preview.width, floor.width):
                preview.alpha_composite(floor, (x, y))
        bed = Image.open(SPRITES / "bed.png").convert("RGBA")
        preview.alpha_composite(bed, (8, 6))
        preview.alpha_composite(sprite, (40, 12))
        args.preview.parent.mkdir(parents=True, exist_ok=True)
        preview.resize((512, 448), Image.Resampling.NEAREST).save(args.preview)
        print(args.preview)


if __name__ == "__main__":
    main()
