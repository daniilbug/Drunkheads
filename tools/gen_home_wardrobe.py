#!/usr/bin/env python3
"""Generate a closed, symmetrical wooden wardrobe for the home bedroom."""

import argparse
from pathlib import Path

from PIL import Image, ImageDraw

from home_furniture_palette import EDGE, HANDLE, SEAM, TOP, WOOD


SPRITES = Path(__file__).resolve().parents[1] / "assets/sprites/home"


def generate() -> Image.Image:
    image = Image.new("RGBA", (24, 32))
    draw = ImageDraw.Draw(image)
    # Preserve the symmetrical silhouette, using broad planes without a border.
    for left in (3, 18):
        draw.rectangle((left, 28, left + 2, 31), fill=EDGE)
    draw.rectangle((0, 0, 23, 29), fill=WOOD)
    draw.rectangle((0, 0, 23, 3), fill=TOP)
    draw.rectangle((11, 5, 12, 27), fill=SEAM)
    draw.rectangle((0, 28, 23, 29), fill=EDGE)
    for x in (8, 15):
        draw.line((x, 16, x, 19), fill=HANDLE)
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
