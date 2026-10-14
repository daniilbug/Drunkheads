#!/usr/bin/env python3
"""Generate a small wooden bedside cabinet matching the home's bed."""

import argparse
from pathlib import Path

from PIL import Image, ImageDraw


SPRITES = Path(__file__).resolve().parents[1] / "assets/sprites/home"


def generate() -> Image.Image:
    image = Image.new("RGBA", (14, 16))
    draw = ImageDraw.Draw(image)
    dark, wood, light = "#4d3428", "#76533a", "#9a7250"

    # Two short, solid-color feet and a compact cabinet body.
    draw.rectangle((2, 13, 3, 15), fill=dark)
    draw.rectangle((10, 13, 11, 15), fill=dark)
    draw.rectangle((0, 5, 13, 13), fill=dark)
    draw.rectangle((1, 6, 12, 12), fill=wood)

    # Identical drawer fronts, with centered handles and an even separator.
    for top in (6, 10):
        draw.rectangle((2, top, 11, top + 2), fill="#896344")
        draw.line((2, top, 11, top), fill=light)
        draw.line((6, top + 1, 7, top + 1), fill="#d6bb8d")
    draw.line((1, 9, 12, 9), fill=dark)

    # The top is seen from above, using the same wood palette as the bed frame.
    draw.rectangle((0, 0, 13, 5), fill=dark)
    draw.rectangle((1, 1, 12, 4), fill=wood)
    draw.line((1, 1, 12, 1), fill=light)
    draw.line((1, 2, 1, 3), fill=light)
    draw.line((12, 2, 12, 3), fill=light)
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
