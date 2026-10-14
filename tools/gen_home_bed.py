#!/usr/bin/env python3
"""Generate the home's 36x44 pixel-art double bed sprite."""

import argparse
from pathlib import Path

from PIL import Image, ImageDraw


OUTPUT = Path(__file__).resolve().parents[1] / "assets/sprites/home/bed.png"


def generate() -> Image.Image:
    width = 36
    image = Image.new("RGBA", (width, 44), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)

    wood_dark = "#674a35"
    wood = "#76533a"
    wood_light = "#805c41"
    mattress_shadow = "#c7bda9"
    sheet = "#d7cdb8"
    pillow = "#e0d7c4"
    blanket_dark = "#58727d"
    blanket = "#607b86"

    # A small floor shadow keeps the bed grounded when placed on the wood floor.
    draw.rectangle((4, 40, width - 5, 42), fill=(34, 26, 24, 55))

    # Slim frame: one-pixel sides and a two-pixel headboard.
    draw.rectangle((2, 4, width - 3, 39), fill=wood)
    draw.line((3, 5, width - 4, 5), fill=wood_light)
    draw.rectangle((3, 6, width - 4, 37), fill=sheet)

    # Two matching pillows and one shared tucked duvet.
    pillow_width = (width - 11) // 2
    for x in (5, width - 5 - pillow_width):
        draw.rectangle((x, 9, x + pillow_width - 1, 16), fill=mattress_shadow)
        draw.rectangle((x + 1, 10, x + pillow_width - 2, 15), fill=pillow)
    draw.rectangle((3, 18, width - 4, 37), fill=blanket_dark)
    draw.rectangle((4, 19, width - 5, 36), fill=blanket)

    # Visible footboard and two short feet.
    draw.line((3, 38, width - 4, 38), fill=wood_light)
    draw.rectangle((4, 40, 7, 41), fill=wood_dark)
    draw.rectangle((width - 8, 40, width - 5, 41), fill=wood_dark)
    return image


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--preview", type=Path, help="Save an 8x nearest-neighbor preview")
    args = parser.parse_args()

    image = generate()
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    image.save(OUTPUT)
    if args.preview:
        args.preview.parent.mkdir(parents=True, exist_ok=True)
        image.resize((image.width * 8, image.height * 8), Image.Resampling.NEAREST).save(args.preview)
    print(OUTPUT)


if __name__ == "__main__":
    main()
