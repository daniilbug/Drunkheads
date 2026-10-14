#!/usr/bin/env python3
"""Generate a small hanging lightbulb; its light gradient belongs to the scene."""

import argparse
from pathlib import Path

from PIL import Image, ImageDraw


OUTPUT = Path(__file__).resolve().parents[1] / "assets/sprites/home/lightbulb.png"


def generate() -> Image.Image:
    image = Image.new("RGBA", (8, 14), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)

    # Short cable and a simple metal socket.
    draw.rectangle((3, 0, 4, 3), fill="#514e47")
    draw.rectangle((2, 4, 5, 6), fill="#69685e")
    draw.line((2, 4, 5, 4), fill="#89877a")
    draw.line((2, 6, 5, 6), fill="#55564f")

    # Symmetric glass silhouette with a thin, warm edge.
    outline = "#c1ac79"
    glass = "#ffe7ae"
    for y, left in ((7, 3), (8, 2), (9, 1), (10, 1), (11, 2), (12, 3)):
        draw.line((left, y, 7 - left, y), fill=outline)
        if 7 < y < 12:
            draw.line((left + 1, y, 6 - left, y), fill=glass)
    draw.rectangle((3, 9, 4, 10), fill="#fff4d4")
    return image


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--preview", type=Path)
    args = parser.parse_args()
    sprite = generate()
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    sprite.save(OUTPUT)
    print(OUTPUT)
    if args.preview:
        args.preview.parent.mkdir(parents=True, exist_ok=True)
        sprite.resize((sprite.width * 10, sprite.height * 10), Image.Resampling.NEAREST).save(args.preview)
        print(args.preview)


if __name__ == "__main__":
    main()
