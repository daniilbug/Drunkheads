#!/usr/bin/env python3
"""Generate a lighter porcelain-tile strip for the home bathroom's top wall."""

import argparse
from pathlib import Path

from PIL import Image


SPRITES = Path(__file__).resolve().parents[1] / "assets/sprites/home"
FLOOR = SPRITES / "toilet_floor.png"
TILE_SIZE = 8
TEXTURE_WIDTH = 64


def make_top_wall() -> Image.Image:
    """Reuse the floor's stone grain and grout spacing with a wall tint."""
    floor = Image.open(FLOOR).convert("RGB")
    if floor.size != (TEXTURE_WIDTH, TEXTURE_WIDTH):
        raise ValueError(f"Expected a 64×64 bathroom floor texture, got {floor.size}")

    wall = Image.new("RGB", (TEXTURE_WIDTH, TILE_SIZE))
    for y in range(TILE_SIZE):
        for x in range(TEXTURE_WIDTH):
            if x % TILE_SIZE == 0 or y == 0:
                # One-pixel grout joints, the same size as those on the floor.
                color = (170, 170, 163) if x % TILE_SIZE == 0 and y == 0 else (186, 186, 178)
            else:
                red, green, blue = floor.getpixel((x, y + TILE_SIZE))
                color = (min(red + 12, 255), min(green + 15, 255), min(blue + 18, 255))
                if y == 1:
                    color = tuple(min(channel + 2, 255) for channel in color)
            wall.putpixel((x, y), color)
    return wall


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--preview", type=Path, help="Save a wall-and-floor comparison preview")
    args = parser.parse_args()

    wall = make_top_wall()
    output = SPRITES / "toilet_top_wall.png"
    wall.save(output)
    print(output)

    if args.preview:
        floor = Image.open(FLOOR).convert("RGB")
        comparison = Image.new("RGB", (40, 24))
        comparison.paste(wall.crop((0, 0, 40, 8)), (0, 0))
        comparison.paste(floor.crop((0, 0, 40, 16)), (0, 8))
        args.preview.parent.mkdir(parents=True, exist_ok=True)
        comparison.resize((400, 240), Image.Resampling.NEAREST).save(args.preview)
        print(args.preview)


if __name__ == "__main__":
    main()
