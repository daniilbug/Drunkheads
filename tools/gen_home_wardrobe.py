#!/usr/bin/env python3
"""Generate a closed, symmetrical wooden wardrobe for the home bedroom."""

import argparse
from pathlib import Path

from PIL import Image, ImageDraw


SPRITES = Path(__file__).resolve().parents[1] / "assets/sprites/home"


def generate() -> Image.Image:
    image = Image.new("RGBA", (24, 32))
    draw = ImageDraw.Draw(image)
    dark, wood, light = "#4d3428", "#76533a", "#9a7250"

    # Solid feet, inset equally from the outer edges.
    for left in (3, 18):
        draw.rectangle((left, 28, left + 2, 31), fill=dark)

    draw.rectangle((0, 0, 23, 29), fill=dark)
    draw.rectangle((1, 1, 22, 28), fill=wood)

    # Shallow top plane above the front, matching the bedside cabinet.
    draw.line((1, 1, 22, 1), fill=light)
    draw.line((1, 2, 1, 3), fill=light)
    draw.line((22, 2, 22, 3), fill=light)
    draw.line((0, 4, 23, 4), fill=dark)

    # A continuous front with one straight, centered seam between equal doors.
    draw.rectangle((2, 6, 21, 26), fill=dark)
    draw.rectangle((3, 7, 20, 25), fill="#896344")
    for left in (4, 15):
        draw.line((left, 7, left + 4, 7), fill=light)
    draw.rectangle((11, 6, 12, 26), fill=dark)

    # Matching brass pulls placed symmetrically beside the seam.
    for x in (8, 15):
        draw.line((x, 16, x, 19), fill="#d6bb8d")
    draw.line((1, 28, 22, 28), fill=light)
    return image


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--preview", type=Path)
    args = parser.parse_args()
    wardrobe = generate()
    output = SPRITES / "wardrobe.png"
    wardrobe.save(output)
    print(output)

    if args.preview:
        # A size comparison with the approved bedroom furniture, not room placement.
        preview = Image.new("RGBA", (104, 56))
        floor = Image.open(SPRITES / "floor.png").convert("RGBA")
        for y in range(0, preview.height, floor.height):
            for x in range(0, preview.width, floor.width):
                preview.alpha_composite(floor, (x, y))
        preview.alpha_composite(Image.open(SPRITES / "bed.png").convert("RGBA"), (6, 6))
        preview.alpha_composite(Image.open(SPRITES / "nightstand.png").convert("RGBA"), (38, 12))
        preview.alpha_composite(wardrobe, (68, 12))
        args.preview.parent.mkdir(parents=True, exist_ok=True)
        preview.resize((728, 392), Image.Resampling.NEAREST).save(args.preview)
        print(args.preview)


if __name__ == "__main__":
    main()
