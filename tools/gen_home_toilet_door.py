#!/usr/bin/env python3
"""Make the home toilet door from the balcony door, replacing glass with wood."""

import argparse
from pathlib import Path

from PIL import Image, ImageColor

from home_furniture_palette import WOOD


SPRITES = Path(__file__).resolve().parents[1] / "assets/sprites/home"
SOURCE = SPRITES / "balcony_door.png"


def make_door() -> Image.Image:
    """Keep the balcony door's two 32×28 frames and all non-glass pixels."""
    door = Image.open(SOURCE).convert("RGBA")
    if door.size != (64, 28):
        raise ValueError(f"Expected a 64×28 balcony door sprite, got {door.size}")

    pixels = door.load()
    wood = ImageColor.getcolor(WOOD, "RGBA")
    replaced = 0
    for y in range(door.height):
        for x in range(door.width):
            if 0 < pixels[x, y][3] < 255:
                pixels[x, y] = wood
                replaced += 1
    if replaced == 0:
        raise ValueError("Balcony door has no glass pixels to replace")
    return door


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--preview", type=Path, help="Save an enlarged nearest-neighbor preview")
    args = parser.parse_args()

    door = make_door()
    output = SPRITES / "toilet_door.png"
    door.save(output)
    print(output)
    if args.preview:
        args.preview.parent.mkdir(parents=True, exist_ok=True)
        door.resize((door.width * 8, door.height * 8), Image.Resampling.NEAREST).save(args.preview)
        print(args.preview)


if __name__ == "__main__":
    main()
