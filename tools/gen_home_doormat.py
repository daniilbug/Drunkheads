#!/usr/bin/env python3
"""Generate a small woven entrance mat for the apartment."""

import argparse
from pathlib import Path

from PIL import Image, ImageDraw


SPRITES = Path(__file__).resolve().parents[1] / "assets/sprites/home"


def generate() -> Image.Image:
    image = Image.new("RGBA", (28, 14))
    draw = ImageDraw.Draw(image)
    # Flat rectangular weave with a dark bound edge and a simple inset border.
    draw.rectangle((0, 0, 27, 13), fill="#584638")
    draw.rectangle((1, 1, 26, 12), fill="#80634a")
    draw.rectangle((2, 2, 25, 11), outline="#b19165")
    draw.rectangle((3, 3, 24, 10), fill="#96764f")
    for y in (4, 6, 8):
        for x in (5, 9, 13, 17, 21):
            draw.line((x, y, x + 1, y), fill="#a38258")
    return image


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--preview", type=Path)
    args = parser.parse_args()
    sprite = generate()
    output = SPRITES / "doormat.png"
    sprite.save(output)
    print(output)
    if args.preview:
        preview = Image.new("RGBA", (64, 40))
        floor = Image.open(SPRITES / "floor.png").convert("RGBA")
        for y in range(0, preview.height, floor.height):
            for x in range(0, preview.width, floor.width):
                preview.alpha_composite(floor, (x, y))
        preview.alpha_composite(sprite, (18, 13))
        args.preview.parent.mkdir(parents=True, exist_ok=True)
        preview.resize((512, 320), Image.Resampling.NEAREST).save(args.preview)
        print(args.preview)


if __name__ == "__main__":
    main()
