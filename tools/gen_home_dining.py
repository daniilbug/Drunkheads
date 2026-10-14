#!/usr/bin/env python3
"""Generate kitchen furniture compatible with the bar table and chair geometry."""

import argparse
from pathlib import Path

from PIL import Image, ImageDraw


SPRITES = Path(__file__).resolve().parents[1] / "assets/sprites/home"
WOOD_DARK = "#70543e"
WOOD = "#a27d5e"
WOOD_LIGHT = "#bf9a73"
FABRIC_DARK = "#c7b18f"
FABRIC = "#d9c7a4"
FABRIC_LIGHT = "#e8d9ba"


def make_table() -> Image.Image:
    image = Image.new("RGBA", (40, 20))
    draw = ImageDraw.Draw(image)
    # 1.2 times smaller than the bar table, retaining crisp pixel borders.
    draw.rectangle((3, 17, 4, 19), fill=WOOD_DARK)
    draw.rectangle((35, 17, 36, 19), fill=WOOD_DARK)
    draw.rectangle((1, 14, 38, 17), fill=WOOD_DARK)
    draw.line((2, 15, 37, 15), fill=WOOD)
    draw.rectangle((0, 0, 39, 14), fill=WOOD_DARK)
    draw.rectangle((1, 1, 38, 13), fill=WOOD)
    draw.line((1, 1, 38, 1), fill=WOOD_LIGHT)
    draw.rectangle((2, 2, 37, 12), fill="#d9c7a4")
    draw.line((2, 2, 37, 2), fill="#e8d9ba")
    draw.line((2, 3, 2, 11), fill="#e8d9ba")
    draw.line((3, 12, 37, 12), fill="#c7b18f")
    return image


def make_chair(north: bool, occupied: bool) -> Image.Image:
    image = Image.new("RGBA", (14, 16))
    draw = ImageDraw.Draw(image)
    for x in (2, 10):
        draw.rectangle((x, 10, x + 1, 15), fill=WOOD_DARK)

    if north:
        # From behind, the solid backrest completely hides the seat cushion.
        # Both occupancy frames share this silhouette.
        draw.rectangle((2, 3, 11, 11), fill=WOOD_DARK)
        draw.rectangle((3, 4, 10, 10), fill=WOOD)
        draw.line((3, 4, 10, 4), fill=WOOD_LIGHT)
    else:
        draw.rectangle((2, 1, 11, 8), fill=WOOD_DARK)
        draw.rectangle((3, 2, 10, 7), fill=WOOD)
        draw.line((3, 2, 10, 2), fill=WOOD_LIGHT)
        draw.rectangle((1, 8, 12, 11), fill=WOOD_DARK)
        draw.rectangle((2, 8, 11, 10), fill=FABRIC)
        draw.line((2, 8, 11, 8), fill=FABRIC_DARK if occupied else FABRIC_LIGHT)
        draw.line((2, 11, 11, 11), fill=WOOD)
    return image


def make_preview(table: Image.Image, chairs: list[Image.Image]) -> Image.Image:
    # Sprite mockup: same offsets and Y order as scenes/room/home/table.tscn.
    layout = Image.new("RGBA", (80, 64))
    floor = Image.open(SPRITES / "kitchen_floor.png").convert("RGBA")
    for y in range(0, layout.height, floor.height):
        for x in range(0, layout.width, floor.width):
            layout.alpha_composite(floor, (x, y))
    for x in (23, 43):
        layout.alpha_composite(chairs[0], (x, 11))
    layout.alpha_composite(table, (20, 28))
    for x in (23, 43):
        layout.alpha_composite(chairs[2], (x, 36))

    preview = Image.new("RGB", (720, 710), "#333940")
    preview.paste(layout.resize((640, 512), Image.Resampling.NEAREST), (40, 16))
    draw = ImageDraw.Draw(preview)
    labels = ("SOUTH / FREE", "SOUTH / TAKEN", "NORTH / FREE", "NORTH / TAKEN")
    for index, chair in enumerate(chairs):
        x = 46 + index * 170
        draw.text((x, 550), labels[index], fill="#e1e4e6")
        enlarged = chair.resize((112, 128), Image.Resampling.NEAREST)
        preview.paste(enlarged, (x, 574), enlarged)
    return preview


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--preview", type=Path)
    args = parser.parse_args()
    table = make_table()
    chairs = [make_chair(north, occupied) for north in (False, True) for occupied in (False, True)]
    sheet = Image.new("RGBA", (56, 16))
    for index, chair in enumerate(chairs):
        sheet.alpha_composite(chair, (index * 14, 0))
    for name, sprite in (("table.png", table), ("chair.png", sheet)):
        path = SPRITES / name
        sprite.save(path)
        print(path)
    if args.preview:
        args.preview.parent.mkdir(parents=True, exist_ok=True)
        make_preview(table, chairs).save(args.preview)
        print(args.preview)


if __name__ == "__main__":
    main()
