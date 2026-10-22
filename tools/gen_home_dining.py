#!/usr/bin/env python3
"""Generate kitchen furniture compatible with the bar table and chair geometry."""

import argparse
from pathlib import Path

from PIL import Image, ImageDraw

from home_furniture_palette import EDGE, SURFACE, TOP, WOOD


SPRITES = Path(__file__).resolve().parents[1] / "assets/sprites/home"


def make_table() -> Image.Image:
    image = Image.new("RGBA", (40, 20))
    draw = ImageDraw.Draw(image)
    # Keep the original silhouette; separate top, edge and apron by tone.
    for x in (3, 35):
        draw.rectangle((x, 17, x + 1, 19), fill=EDGE)
    draw.rectangle((1, 14, 38, 17), fill=EDGE)
    draw.rectangle((0, 0, 39, 13), fill=SURFACE)
    draw.line((0, 14, 39, 14), fill=WOOD)
    draw.line((1, 15, 38, 15), fill=WOOD)
    return image


def make_chair(north: bool, occupied: bool) -> Image.Image:
    image = Image.new("RGBA", (14, 16))
    draw = ImageDraw.Draw(image)
    for x in (2, 10):
        draw.rectangle((x, 10, x + 1, 15), fill=EDGE)

    if north:
        # From behind, the solid backrest completely hides the seat.
        # Both occupancy frames share this silhouette.
        draw.rectangle((2, 3, 11, 11), fill=WOOD)
        draw.rectangle((2, 3, 11, 4), fill=SURFACE)
        draw.line((2, 11, 11, 11), fill=EDGE)
    else:
        draw.rectangle((2, 1, 11, 8), fill=WOOD)
        draw.rectangle((2, 1, 11, 2), fill=TOP)
        draw.line((2, 7, 11, 7), fill=EDGE)
        draw.rectangle((1, 8, 12, 9), fill=SURFACE)
        if occupied:
            draw.line((1, 8, 12, 8), fill=TOP)
        draw.line((1, 10, 12, 10), fill=WOOD)
        draw.line((1, 11, 12, 11), fill=EDGE)
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
