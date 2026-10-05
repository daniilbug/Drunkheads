#!/usr/bin/env python3
"""Generate a shared launcher tile and transparent phone app glyphs."""

from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "assets" / "sprites" / "phone"

ICON_SIZE = 64
OUTPUT_ICON_SIZE = 32
OUTLINE = "#3a2610"
TILE = "#d9af5b"
TILE_LIGHT = "#f1cf82"
TILE_DARK = "#ab7938"
CAR = "#ad884b"


def _save(icon: Image.Image, filename: str) -> Path:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    path = OUTPUT / filename
    # Keep the shared drawing coordinates; export crisp, lower-resolution pixels.
    icon.resize((OUTPUT_ICON_SIZE, OUTPUT_ICON_SIZE), Image.Resampling.NEAREST).save(path)
    return path


def generate_app_icon_background() -> Path:
    icon = Image.new("RGBA", (ICON_SIZE, ICON_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(icon)

    # Both launcher buttons use this exact tile, including its stepped outline.
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
    return _save(icon, "app_icon_background.png")


def generate_taxi_icon() -> Path:
    icon = Image.new("RGBA", (ICON_SIZE, ICON_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(icon)

    # Transparent car glyph, layered over the shared tile in the Godot scene.
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
    return _save(icon, "taxi_icon.png")


def generate_wallpaper_icon() -> Path:
    icon = Image.new("RGBA", (ICON_SIZE, ICON_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(icon)

    # Only the landscape mark is opaque; the shared tile supplies all background.
    draw.ellipse((39, 17, 49, 27), fill=OUTLINE)
    draw.ellipse((41, 19, 47, 25), fill=TILE_LIGHT)
    draw.polygon([(10, 48), (27, 25), (38, 39), (44, 31), (55, 48)], fill=OUTLINE)
    draw.polygon([(15, 46), (27, 30), (39, 46)], fill="#3e6465")
    draw.polygon([(35, 46), (44, 35), (50, 46)], fill="#789278")
    return _save(icon, "wallpapers_icon.png")


def generate_music_icon() -> Path:
    icon = Image.new("RGBA", (ICON_SIZE, ICON_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(icon)
    draw.polygon([(30, 21), (48, 17), (48, 42), (43, 42),
                  (43, 24), (35, 26), (35, 46), (30, 46)], fill=OUTLINE)
    draw.ellipse((20, 41, 35, 50), fill=OUTLINE)
    draw.ellipse((38, 37, 49, 46), fill=OUTLINE)
    draw.rectangle((34, 25, 44, 27), fill=TILE_LIGHT)
    return _save(icon, "music_icon.png")


def generate_control_icon(name: str) -> Path:
    icon = Image.new("RGBA", (ICON_SIZE, ICON_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(icon)
    if name == "play":
        draw.polygon([(24, 17), (48, 32), (24, 47)], fill=OUTLINE)
        draw.polygon([(28, 23), (41, 32), (28, 41)], fill=TILE_LIGHT)
    elif name == "pause":
        for x in (21, 38):
            draw.rectangle((x, 18, x + 7, 46), fill=OUTLINE)
            draw.rectangle((x + 2, 21, x + 4, 43), fill=TILE_LIGHT)
    elif name in ("previous", "next"):
        if name == "previous":
            draw.rectangle((16, 20, 21, 44), fill=OUTLINE)
            draw.polygon([(43, 19), (23, 32), (43, 45)], fill=OUTLINE)
        else:
            draw.rectangle((43, 20, 48, 44), fill=OUTLINE)
            draw.polygon([(21, 19), (41, 32), (21, 45)], fill=OUTLINE)
    else:
        raise ValueError(name)
    return _save(icon, f"{name}_icon.png")


if __name__ == "__main__":
    print(generate_app_icon_background())
    print(generate_taxi_icon())
    print(generate_wallpaper_icon())
    print(generate_music_icon())
    for control in ("play", "pause", "previous", "next"):
        print(generate_control_icon(control))
