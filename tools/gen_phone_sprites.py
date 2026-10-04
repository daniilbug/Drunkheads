#!/usr/bin/env python3
"""Generate pixel-art phone app icons using the game's taxi palette."""

from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "assets" / "sprites" / "phone"

ICON_SIZE = 64
OUTLINE = "#3a2610"
TILE = "#d9af5b"
TILE_LIGHT = "#f1cf82"
TILE_DARK = "#ab7938"
CAR = "#ad884b"


def generate_taxi_icon() -> Path:
    icon = Image.new("RGBA", (ICON_SIZE, ICON_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(icon)

    # Stepped corners and a two-pixel border follow the game's sprite palette.
    draw.polygon(
        [(8, 1), (55, 1), (55, 3), (59, 3), (59, 5), (61, 5),
         (61, 58), (59, 58), (59, 60), (55, 60), (55, 62),
         (8, 62), (8, 60), (4, 60), (4, 58), (2, 58),
         (2, 5), (4, 5), (4, 3), (8, 3)],
        fill=OUTLINE,
    )
    draw.polygon(
        [(8, 4), (55, 4), (55, 6), (58, 6), (58, 8), (59, 8),
         (59, 55), (58, 55), (58, 57), (55, 57), (55, 59),
         (8, 59), (8, 57), (5, 57), (5, 55), (4, 55),
         (4, 8), (5, 8), (5, 6), (8, 6)],
        fill=TILE,
    )
    draw.line((8, 5, 55, 5), fill=TILE_LIGHT)
    draw.line((5, 8, 5, 54), fill=TILE_LIGHT)
    draw.line((8, 58, 55, 58), fill=TILE_DARK)
    draw.line((58, 8, 58, 54), fill=TILE_DARK)

    # One small car silhouette at the center: body and wheels, no trim or sign.
    draw.polygon(
        [(15, 31), (20, 30), (24, 24), (39, 24), (44, 30),
         (49, 31), (49, 38), (15, 38)],
        fill=OUTLINE,
    )
    draw.polygon(
        [(17, 33), (22, 31), (25, 26), (38, 26), (43, 31),
         (47, 33), (47, 36), (17, 36)],
        fill=CAR,
    )
    draw.rectangle((20, 37, 25, 40), fill=OUTLINE)
    draw.rectangle((39, 37, 44, 40), fill=OUTLINE)

    OUTPUT.mkdir(parents=True, exist_ok=True)
    path = OUTPUT / "taxi_icon.png"
    icon.save(path)
    return path


if __name__ == "__main__":
    print(generate_taxi_icon())
