#!/usr/bin/env python3
"""Generate the approved bar materials and walnut/sage furniture textures."""

import argparse
from pathlib import Path

from PIL import Image, ImageColor, ImageDraw


SPRITES = Path(__file__).resolve().parents[1] / "assets/sprites"
OUTPUT = SPRITES / "bar"
P = {
    "mortar": "#705a4f",
    "brick": ("#925f4e", "#986654", "#895b4c", "#93614f"),
    "brick_highlight": "#a67760",
    "roof_outline": "#222728",
    "roof_plane": "#343a3c",
    "roof_seam": "#2d3335",
    "roof_top": "#5b6262",
    "cornice_highlight": "#50585a",
    "cornice_face": "#303638",
    "cornice_shadow": "#22282a",
    "cornice_edge": "#485154",
    "floor": ("#79553d", "#805a40"),
    "floor_joint": "#644832",
    "floor_grain": "#956e4e",
    "frame": "#78817a",
    "sill": "#93998c",
    "glass_dark": "#46535a",
    "glass_lit": "#d2b078",
    "door_side": "#68736c",
    "handle": "#c3aa7a",
    "table_top": "#655343",
    "table_highlight": "#927b63",
    "table_grain": "#705c49",
    "table_edge": "#5b4b3e",
    "furniture_frame": "#51453a",
    "chair_side": "#626e66",
    "felt": "#405b4d",
    "felt_seam": "#617a67",
    "interior_door": "#d0c8c8",
    "menu_paper": "#dfd6c4",
    "menu_ink": "#414b48",
}
# Same translucent glass and reflection colors as gen_cafe_sprites.window().
GLASS = (230, 194, 122, 58)
REFLECTION = (255, 238, 200, 90)
REFLECTION_TOP = (255, 238, 200, 65)


def original(name: str, size: tuple[int, int]) -> Image.Image:
    """Legacy sprites supply stable aperture masks and door frame footprints."""
    image = Image.open(SPRITES / name).convert("RGBA")
    if image.size != size:
        raise ValueError(f"{name}: expected {size}, got {image.size}")
    return image


def brick() -> Image.Image:
    image = Image.new("RGBA", (16, 12), P["mortar"])
    draw = ImageDraw.Draw(image)
    for row in range(2):
        for column in range(-1, 3):
            x, y = column * 8 + row * 4, row * 6
            draw.rectangle((x + 1, y + 1, x + 7, y + 5), fill=P["brick"][row * 2 + column % 2])
            draw.line((x + 2, y + 1, x + 6, y + 1), fill=P["brick_highlight"])
    return image


def floor() -> Image.Image:
    image = Image.new("RGBA", (32, 16))
    draw = ImageDraw.Draw(image)
    for row in range(2):
        y = row * 8
        draw.rectangle((0, y, 31, y + 7), fill=P["floor"][row])
        draw.line((0, y + 7, 31, y + 7), fill=P["floor_joint"])
        draw.line((row * 16, y, row * 16, y + 6), fill=P["floor_joint"])
    draw.line((8, 3, 12, 3), fill=P["floor_grain"])
    draw.line((23, 11, 26, 11), fill=P["floor_grain"])
    return image


def roof(size: tuple[int, int]) -> Image.Image:
    """Complete sprite, including the cornice and all four perimeter edges."""
    width, height = size
    image = Image.new("RGBA", size, P["roof_plane"])
    draw = ImageDraw.Draw(image)
    if height >= 16:
        face = height - 10
        for x in range(24, width - 2, 40):
            draw.line((x, 3, x, face - 1), fill=P["roof_seam"])
        if height > 40:
            for y in range(24, face, 24):
                draw.line((2, y, width - 3, y), fill=P["roof_seam"])
        draw.line((1, 1, width - 2, 1), fill=P["roof_top"])
        draw.line((1, 2, width - 2, 2), fill=P["cornice_edge"])
        draw.line((1, face, width - 2, face), fill=P["cornice_highlight"])
        draw.line((1, face + 1, width - 2, face + 1), fill=P["cornice_shadow"])
        draw.rectangle((1, face + 2, width - 2, height - 3), fill=P["cornice_face"])
        for x in range(7, width - 7, 20):
            draw.rectangle((x, face + 3, x + 3, height - 3), fill=P["cornice_shadow"])
            draw.line((x, face + 3, x + 2, face + 3), fill=P["cornice_edge"])
        draw.line((1, height - 2, width - 2, height - 2), fill=P["cornice_edge"])
    else:
        draw.rectangle((1, 1, width - 2, 3), fill=P["roof_plane"])
        draw.line((1, 1, width - 2, 1), fill=P["roof_top"])
        draw.line((1, 4, width - 2, 4), fill=P["cornice_highlight"])
        draw.line((1, 5, width - 2, 5), fill=P["cornice_shadow"])
        draw.line((1, 6, width - 2, 6), fill=P["cornice_edge"])
    draw.rectangle((0, 0, width - 1, height - 1), outline=P["roof_outline"])
    return image


def window_frame(transparent: bool) -> Image.Image:
    size = (16, 24) if transparent else (32, 24)
    source = original("window_transparent.png" if transparent else "window.png", size)
    image = Image.new("RGBA", size, P["frame"])
    draw = ImageDraw.Draw(image)
    for offset in range(0, size[0], 16):
        if not transparent:
            glass = P["glass_lit"] if offset else P["glass_dark"]
            draw.rectangle((offset + 2, 2, offset + 6, 21), fill=glass)
            draw.rectangle((offset + 9, 2, offset + 13, 21), fill=glass)
        draw.rectangle((offset, 22, offset + 15, 23), fill=P["sill"])
    image.putalpha(source.getchannel("A"))
    return image


def glass_layer() -> Image.Image:
    mask = original("window_transparent.png", (16, 24)).getchannel("A")
    image = Image.new("RGBA", (16, 24), GLASS)
    draw = ImageDraw.Draw(image)
    for x in (2, 9):
        draw.line((x + 1, 4, x + 1, 17), fill=REFLECTION)
        draw.line((x + 2, 4, x + 3, 4), fill=REFLECTION_TOP)
    for y in range(24):
        for x in range(16):
            if mask.getpixel((x, y)):
                r, g, b, _ = image.getpixel((x, y))
                image.putpixel((x, y), (r, g, b, 0))
    return image


def window(transparent: bool) -> Image.Image:
    image = window_frame(transparent)
    glass = glass_layer()
    for offset in range(0, image.width, 16):
        image.alpha_composite(glass, (offset, 0))
    return image


def door() -> Image.Image:
    """Two 32x28 frames; flat leaf and jamb match the window frame color."""
    source = original("bar_door.png", (64, 28))
    image = Image.new("RGBA", source.size)
    draw = ImageDraw.Draw(image)
    draw.rectangle((0, 0, 15, 27), fill=P["frame"])
    draw.rectangle((32, 0, 63, 27), fill=P["frame"])
    draw.line((32, 27, 47, 27), fill=P["sill"])
    for x, handle_x in ((0, 2), (48, 61)):
        draw.line((x + 1, 1, x + 14, 1), fill=P["sill"])
        draw.line((x + 15, 1, x + 15, 26), fill=P["door_side"])
        draw.line((handle_x, 13, handle_x, 16), fill=P["handle"])
    image.putalpha(source.getchannel("A"))
    return image


def table() -> Image.Image:
    """48x24 tabletop with a two-pixel edge and no baked shadow band."""
    image = Image.new("RGBA", (48, 24))
    draw = ImageDraw.Draw(image)
    draw.rectangle((1, 0, 46, 17), fill=P["table_top"])
    draw.line((3, 1, 44, 1), fill=P["table_highlight"])
    draw.line((8, 6, 18, 6), fill=P["table_grain"])
    draw.line((29, 12, 39, 12), fill=P["table_grain"])
    draw.rectangle((1, 18, 46, 19), fill=P["table_edge"])
    for x in (3, 42):
        draw.rectangle((x, 20, x + 2, 23), fill=P["furniture_frame"])
    return image


def chair() -> Image.Image:
    """Four symmetric 14x16 frames: south empty/occupied, north empty/occupied."""
    image = Image.new("RGBA", (56, 16))
    draw = ImageDraw.Draw(image)
    for frame in range(4):
        x = frame * 14
        north, occupied = frame >= 2, frame % 2 == 1
        for leg in (2, 10):
            draw.rectangle((x + leg, 10, x + leg + 1, 15), fill=P["furniture_frame"])
        if north:
            draw.rectangle((x + 2, 3, x + 11, 11), fill=P["frame"])
            draw.line((x + 3, 4, x + 10, 4), fill=P["sill"])
            draw.line((x + 2, 11, x + 11, 11), fill=P["chair_side"])
        else:
            draw.rectangle((x + 2, 1, x + 11, 7), fill=P["frame"])
            draw.line((x + 3, 2, x + 10, 2), fill=P["sill"])
            draw.rectangle((x + 1, 8, x + 12, 10), fill=P["frame"])
            draw.line((x + 2, 8, x + 11, 8), fill=P["frame"] if occupied else P["sill"])
            draw.line((x + 1, 11, x + 12, 11), fill=P["chair_side"])
    return image


def interior_door(kind: str) -> Image.Image:
    """Keep both original door masks, handles and WC lettering; flatten the frame."""
    image = original(f"{kind}/door.png", (64, 28))
    body = ImageColor.getcolor(P["interior_door"], "RGBA")
    borders = {(43, 41, 41, 255), (59, 55, 55, 255), (194, 184, 184, 255), (215, 208, 208, 255)}
    for y in range(image.height):
        for x in range(image.width):
            if image.getpixel((x, y)) in borders:
                image.putpixel((x, y), body)
    return image


def table_football() -> Image.Image:
    """Change only the wood body and supports; retain every original playing pixel."""
    source = original("table_football.png", (36, 48))
    image = source.copy()
    wood = {
        (165, 118, 70, 255): P["table_top"],
        (90, 62, 28, 255): P["table_edge"],
        (72, 47, 22, 255): P["table_edge"],
        (60, 40, 18, 255): P["furniture_frame"],
    }
    for y in range(image.height):
        for x in range(image.width):
            color = image.getpixel((x, y))
            if color in wood:
                image.putpixel((x, y), ImageColor.getcolor(wood[color], "RGBA"))
    draw = ImageDraw.Draw(image)
    draw.rectangle((6, 39, 29, 47), fill=(0, 0, 0, 0))
    draw.rectangle((6, 39, 29, 40), fill=P["table_edge"])
    for x in (7, 26):
        draw.rectangle((x, 41, x + 2, 47), fill=P["furniture_frame"])
    assert image.crop((7, 1, 29, 38)).tobytes() == source.crop((7, 1, 29, 38)).tobytes()
    return image


def poker_table() -> Image.Image:
    image = Image.new("RGBA", (48, 24))
    draw = ImageDraw.Draw(image)
    draw.rectangle((1, 0, 46, 17), fill=P["table_top"])
    draw.rectangle((3, 2, 44, 16), fill=P["felt"])
    draw.rectangle((5, 4, 42, 14), outline=P["felt_seam"])
    draw.rectangle((1, 18, 46, 19), fill=P["table_edge"])
    for x in (3, 42):
        draw.rectangle((x, 20, x + 2, 23), fill=P["furniture_frame"])
    return image


def counter_background() -> Image.Image:
    """Walnut shelf with the original bottles; transparency reveals the brick wall."""
    source = original("bar_bg.png", (320, 32))
    image = Image.new("RGBA", source.size)
    draw = ImageDraw.Draw(image)
    draw.rectangle((0, 20, 319, 21), fill=P["table_top"])
    draw.rectangle((0, 22, 319, 23), fill=P["table_edge"])
    bottle_colors = {
        (46, 115, 56, 255), (72, 160, 82, 255), (140, 56, 26, 255), (180, 80, 42, 255),
        (160, 120, 40, 255), (210, 175, 65, 255), (180, 140, 40, 255), (220, 175, 60, 255),
        (65, 42, 18, 255),
    }
    for y in range(20):
        for x in range(image.width):
            color = source.getpixel((x, y))
            if color in bottle_colors:
                image.putpixel((x, y), color)
    return image


def bartender() -> Image.Image:
    """Recolor the baked counter patch in both frames, preserving the character."""
    image = original("bartender.png", (24, 20))
    wood = ImageColor.getcolor(P["table_top"], "RGBA")
    for y in range(15, 20):
        for x in range(image.width):
            if image.getpixel((x, y))[3]:
                image.putpixel((x, y), wood)
    return image


def menu() -> Image.Image:
    """Three-pixel source blocks render as a crisp 16x12 placard at scale 1/3."""
    image = Image.new("RGBA", (16, 12), P["menu_paper"])
    draw = ImageDraw.Draw(image)
    draw.line((2, 1, 8, 1), fill=P["menu_ink"])
    for y, end, price in ((3, 7, 12), (5, 8, 13), (7, 6, 12), (9, 8, 13)):
        draw.line((2, y, end, y), fill=P["menu_ink"])
        draw.line((11, y, price, y), fill=P["table_highlight"])
    return image.resize((48, 36), Image.Resampling.NEAREST)


def main() -> None:
    generators = {
        "brick": brick,
        "floor": floor,
        "roof": lambda: roof((340, 32)),
        "house_roof": lambda: roof((160, 80)),
        "door_canopy": lambda: roof((28, 8)),
        "window": lambda: window(False),
        "window_glass": lambda: window(True),
        "door": door,
        "table": table,
        "chair": chair,
        "wc_door": lambda: interior_door("wc"),
        "poker_door": lambda: interior_door("poker"),
        "table_football": table_football,
        "poker_table": poker_table,
        "counter_background": counter_background,
        "bartender": bartender,
        "menu": menu,
    }
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--only", choices=generators, help="Generate just one bar texture")
    args = parser.parse_args()
    OUTPUT.mkdir(parents=True, exist_ok=True)
    for name, generate in generators.items():
        if args.only is None or args.only == name:
            path = OUTPUT / f"{name}.png"
            generate().save(path)
            print(path)


if __name__ == "__main__":
    main()
