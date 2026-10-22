#!/usr/bin/env python3
"""Generate a decorative closed window for the apartment wall."""

import argparse
from pathlib import Path

from PIL import Image, ImageDraw

from home_furniture_palette import EDGE, HANDLE, TOP, WOOD


SPRITES = Path(__file__).resolve().parents[1] / "assets/sprites/home"


def draw_glass(draw: ImageDraw.ImageDraw, rect: tuple[int, int, int, int]) -> None:
    """Warm translucent panes and soft reflections shared with the balcony door."""
    x, y, width, height = rect
    draw.rectangle((x, y, x + width - 1, y + height - 1), fill=(230, 194, 122, 58))
    if width >= 5 and height >= 6:
        draw.line((x + 1, y + 2, x + 1, y + height - 3), fill=(255, 238, 200, 90))
        draw.line((x + 2, y + 2, x + min(width - 2, 5), y + 2), fill=(255, 238, 200, 65))


def generate() -> Image.Image:
    image = Image.new("RGBA", (28, 20))
    draw = ImageDraw.Draw(image)
    draw.rectangle((1, 0, 26, 17), fill=WOOD)
    for x in (4, 16):
        draw_glass(draw, (x, 3, 8, 12))
    draw.rectangle((0, 17, 27, 18), fill=TOP)
    draw.line((0, 19, 27, 19), fill=EDGE)
    for x in (10, 17):
        draw.line((x, 10, x, 12), fill=HANDLE)
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
