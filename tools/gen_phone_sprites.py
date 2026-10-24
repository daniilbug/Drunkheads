#!/usr/bin/env python3
"""Generate phone app glyphs, their shared tile, and native-size status icons."""

from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "assets" / "sprites" / "phone"

ICON_SIZE = 64
OUTPUT_ICON_SIZE = 32
GLYPH_SIZE = 20
OUTLINE = "#3a2610"
TILE = "#d9af5b"
TILE_LIGHT = "#f1cf82"
TILE_DARK = "#ab7938"


def _save(icon: Image.Image, filename: str) -> Path:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    path = OUTPUT / filename
    # Only the legacy background uses the larger drawing canvas.
    if icon.size != (OUTPUT_ICON_SIZE, OUTPUT_ICON_SIZE):
        icon = icon.resize((OUTPUT_ICON_SIZE, OUTPUT_ICON_SIZE), Image.Resampling.NEAREST)
    icon.save(path)
    return path


def _save_glyph(icon: Image.Image, filename: str) -> Path:
    """Center native-resolution artwork without resampling its pixels."""
    bounds = icon.getbbox()
    if bounds is None:
        raise ValueError(f"Empty phone glyph: {filename}")
    mark = icon.crop(bounds)
    if max(mark.size) != GLYPH_SIZE:
        raise ValueError(f"Phone glyph must fit the {GLYPH_SIZE}px grid: {filename}")
    centered = Image.new("RGBA", (OUTPUT_ICON_SIZE, OUTPUT_ICON_SIZE), (0, 0, 0, 0))
    centered.alpha_composite(mark, ((OUTPUT_ICON_SIZE - mark.width) // 2,
                                    (OUTPUT_ICON_SIZE - mark.height) // 2))
    return _save(centered, filename)


def generate_app_icon_background() -> Path:
    icon = Image.new("RGBA", (ICON_SIZE, ICON_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(icon)

    # All launcher buttons use this exact tile, including its stepped outline.
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
    icon = Image.new("RGBA", (OUTPUT_ICON_SIZE, OUTPUT_ICON_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(icon)

    # Front-facing cab with a roof sign, broad windshield and two headlights.
    # Draw directly on the final pixel grid, keeping the cab wider than tall.
    draw.polygon(
        [(11, 11), (20, 11), (23, 16), (24, 17),
         (24, 22), (7, 22), (7, 17), (8, 16)],
        fill=OUTLINE,
    )
    draw.polygon([(12, 13), (19, 13), (21, 16), (10, 16)], fill=(0, 0, 0, 0))
    draw.rectangle((13, 8, 18, 10), fill=OUTLINE)
    draw.point((14, 9), fill=(0, 0, 0, 0))
    draw.point((17, 9), fill=(0, 0, 0, 0))
    for x in (7, 21):
        draw.rectangle((x, 22, x + 3, 24), fill=OUTLINE)
    for x in (10, 20):
        draw.rectangle((x, 19, x + 1, 20), fill=(0, 0, 0, 0))
    draw.rectangle((12, 22, 19, 22), fill=(0, 0, 0, 0))
    draw.rectangle((6, 16, 7, 18), fill=OUTLINE)
    draw.rectangle((24, 16, 25, 18), fill=OUTLINE)
    return _save_glyph(icon, "taxi_icon.png")


def generate_wallpaper_icon() -> Path:
    icon = Image.new("RGBA", (OUTPUT_ICON_SIZE, OUTPUT_ICON_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(icon)

    # A compact photo with a moon and two clean mountain silhouettes.
    draw.rectangle((6, 8, 25, 23), fill=OUTLINE)
    draw.rectangle((8, 10, 23, 21), fill=(0, 0, 0, 0))
    draw.rectangle((19, 11, 21, 13), fill=OUTLINE)
    draw.polygon([(8, 21), (13, 14), (18, 21)], fill=OUTLINE)
    draw.polygon([(15, 21), (20, 16), (23, 21)], fill=OUTLINE)
    return _save_glyph(icon, "wallpapers_icon.png")


def generate_music_icon() -> Path:
    icon = Image.new("RGBA", (OUTPUT_ICON_SIZE, OUTPUT_ICON_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(icon)
    # Headphones: one stepped arch and two solid ear pads, no tiny details.
    draw.rectangle((12, 7, 19, 8), fill=OUTLINE)
    for left, right in ((9, 11), (20, 22)):
        draw.rectangle((left, 8, right, 9), fill=OUTLINE)
    for left in (8, 22):
        draw.rectangle((left, 10, left + 1, 12), fill=OUTLINE)
    for left in (6, 24):
        draw.rectangle((left, 12, left + 1, 23), fill=OUTLINE)
    draw.rectangle((6, 16, 10, 23), fill=OUTLINE)
    draw.rectangle((21, 16, 25, 23), fill=OUTLINE)
    return _save_glyph(icon, "music_icon.png")


def generate_shopping_icon() -> Path:
    icon = Image.new("RGBA", (OUTPUT_ICON_SIZE, OUTPUT_ICON_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(icon)
    # A solid handbag with an open arched handle and soft corners.
    draw.ellipse((10, 6, 21, 19), fill=OUTLINE)
    draw.ellipse((12, 8, 19, 17), fill=(0, 0, 0, 0))
    draw.polygon([(8, 13), (23, 13), (25, 22), (25, 24),
                  (24, 25), (7, 25), (6, 24), (6, 22)], fill=OUTLINE)
    return _save_glyph(icon, "shopping_icon.png")


def generate_home_icon() -> Path:
    icon = Image.new("RGBA", (OUTPUT_ICON_SIZE, OUTPUT_ICON_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(icon)
    draw.polygon([(6, 15), (15, 6), (16, 6), (25, 15),
                  (23, 17), (16, 10), (15, 10), (8, 17)], fill=OUTLINE)
    draw.rectangle((9, 15, 22, 24), fill=OUTLINE)
    draw.rectangle((14, 18, 17, 24), fill=(0, 0, 0, 0))
    draw.rectangle((11, 16, 12, 18), fill=(0, 0, 0, 0))
    draw.rectangle((19, 16, 20, 18), fill=(0, 0, 0, 0))
    return _save_glyph(icon, "home_icon.png")


def generate_cafe_icon() -> Path:
    icon = Image.new("RGBA", (OUTPUT_ICON_SIZE, OUTPUT_ICON_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(icon)
    # Each continuous wave bends in both directions, rather than forming a hook.
    for x in (10, 16):
        for y, offset in enumerate((1, 0, 0, 1, 2, 2, 1, 0), start=6):
            draw.rectangle((x + offset, y, x + offset + 1, y), fill=OUTLINE)
    # Draw a rounded handle behind the cup, with the same two-pixel stroke.
    draw.ellipse((17, 16, 24, 21), fill=OUTLINE)
    draw.ellipse((19, 18, 22, 19), fill=(0, 0, 0, 0))
    draw.polygon([(7, 15), (20, 15), (20, 19), (19, 21),
                  (17, 22), (10, 22), (8, 21), (7, 19)], fill=OUTLINE)
    draw.polygon([(9, 17), (18, 17), (18, 19), (17, 20),
                  (10, 20), (9, 19)], fill=(0, 0, 0, 0))
    draw.line((6, 24, 25, 24), fill=OUTLINE, width=2)
    return _save_glyph(icon, "cafe_icon.png")


def generate_bar_icon() -> Path:
    icon = Image.new("RGBA", (OUTPUT_ICON_SIZE, OUTPUT_ICON_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(icon)
    # Match the two-pixel rim with mirrored diagonal strokes; even-width Pillow
    # lines otherwise put their extra pixels on different sides of each edge.
    draw.line((6, 8, 25, 8), fill=OUTLINE, width=2)
    draw.line((6, 8, 15, 17), fill=OUTLINE, width=2)
    icon.paste(icon.crop((0, 0, 16, OUTPUT_ICON_SIZE)).transpose(Image.Transpose.FLIP_LEFT_RIGHT),
               (16, 0))
    draw.rectangle((15, 17, 16, 23), fill=OUTLINE)
    draw.rectangle((11, 24, 20, 25), fill=OUTLINE)
    return _save_glyph(icon, "bar_icon.png")


def generate_control_icon(name: str) -> Path:
    icon = Image.new("RGBA", (OUTPUT_ICON_SIZE, OUTPUT_ICON_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(icon)
    if name == "play":
        draw.polygon([(8, 6), (23, 15), (23, 16), (8, 25)], fill=OUTLINE)
    elif name == "pause":
        for x in (7, 19):
            draw.rectangle((x, 6, x + 4, 25), fill=OUTLINE)
    elif name in ("previous", "next"):
        draw.rectangle((6, 7, 9, 24), fill=OUTLINE)
        draw.polygon([(25, 6), (11, 15), (11, 16), (25, 25)], fill=OUTLINE)
        if name == "next":
            icon = icon.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    else:
        raise ValueError(name)
    return _save_glyph(icon, f"{name}_icon.png")


def generate_status_icons() -> list[Path]:
    """Draw native-size status marks without the app icons' 32px padding."""
    ink = "#f5e6c2"
    signal = Image.new("RGBA", (14, 10), (0, 0, 0, 0))
    draw = ImageDraw.Draw(signal)
    for x, top in ((0, 7), (4, 5), (8, 2), (12, 0)):
        draw.rectangle((x, top, x + 1, 9), fill=ink)

    battery = Image.new("RGBA", (19, 10), (0, 0, 0, 0))
    draw = ImageDraw.Draw(battery)
    draw.rectangle((0, 0, 16, 9), outline=ink)
    draw.rectangle((17, 3, 18, 6), fill=ink)
    draw.rectangle((2, 2, 12, 7), fill=ink)

    OUTPUT.mkdir(parents=True, exist_ok=True)
    paths = []
    for name, icon in (("signal", signal), ("battery", battery)):
        path = OUTPUT / f"status_{name}.png"
        icon.save(path)
        paths.append(path)
    return paths


if __name__ == "__main__":
    print(generate_app_icon_background())
    print(generate_taxi_icon())
    print(generate_wallpaper_icon())
    print(generate_music_icon())
    print(generate_shopping_icon())
    print(generate_home_icon())
    print(generate_cafe_icon())
    print(generate_bar_icon())
    for control in ("play", "pause", "previous", "next"):
        print(generate_control_icon(control))
    for path in generate_status_icons():
        print(path)
