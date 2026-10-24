#!/usr/bin/env python3
"""Reproduce the clothing store fixtures only, at their native pixel size."""
from pathlib import Path

from PIL import Image, ImageColor, ImageDraw

from gen_character_clothing import DARK, SHADE, MAIN, LIGHT, SKIN, SKIN_SHADE
from gen_phone_sprites import OUTLINE as PHONE_GLYPH_COLOR


SPRITES = Path(__file__).resolve().parents[1] / "assets/sprites"
OUT = SPRITES / "clothing_store"
METAL = "#6d7874"
METAL_LIGHT = "#a0aaa3"
WHITE = "#eee9dc"
WHITE_LIGHT = "#faf5e9"
FRAME = "#889388"
WOOD = "#caa674"
WOOD_LIGHT = "#dfbd8a"
WOOD_GRAIN = "#d4b17e"
WOOD_EDGE = "#be9968"
WOOD_FRONT = "#aa8053"
GLASS = (221, 232, 221, 28)


def floor() -> Image.Image:
    """Seamless staggered oak planks, with subdued joints and grain."""
    image = Image.new("RGBA", (96, 32))
    d = ImageDraw.Draw(image)
    for row, color in enumerate(("#ceb082", "#d1b386", "#cbae80", "#d0b184")):
        y = row * 8
        d.rectangle((0, y, 95, y + 7), fill=color)
        d.line((0, y + 7, 95, y + 7), fill="#c2a477")
        for x in range((row % 2) * 24, 96, 48):
            d.line((x, y, x, y + 6), fill="#c2a477")
        x = (row * 23 + 9) % 76
        d.line((x, y + 3, x + 12, y + 3), fill="#d6b98b")
    return image


def entrance_mat() -> Image.Image:
    """Approved 28x14 woven mat, with three colors and sparse stitches."""
    image = Image.new("RGBA", (28, 14), "#b39b76")
    d = ImageDraw.Draw(image)
    d.rectangle((0, 0, 27, 13), outline="#a48c67")
    for row, y in enumerate((3, 7, 11)):
        for x in range(3 + (row % 2) * 2, 25, 4):
            d.line((x, y, x + 1, y), fill="#c4ad85")
            d.point((x + 1, y + 1), fill="#a48c67")
    return image


def wall_clock() -> Image.Image:
    """Approved 12x12 dial; the scene draws hands from WorldTime."""
    image = Image.new("RGBA", (12, 12))
    d = ImageDraw.Draw(image)
    d.ellipse((0, 0, 11, 11), fill=FRAME)
    d.ellipse((1, 1, 10, 10), fill=WHITE)
    for position in ((5, 2), (9, 5), (6, 9), (2, 6)):
        d.point(position, fill=METAL_LIGHT)
    return image


def mannequin() -> Image.Image:
    """Decorative ivory mannequin wearing real garment frames on an oak plinth."""
    pose = Image.open(SPRITES / "player.png").convert("RGBA").crop((0, 80, 12, 100))
    body = Image.new("RGBA", pose.size, WHITE)
    body.putalpha(pose.getchannel("A").point(lambda alpha: 255 if alpha else 0))
    d = ImageDraw.Draw(body)
    d.rectangle((3, 3, 8, 8), fill=WHITE)
    d.line((8, 4, 8, 8), fill="#d9d3c5")
    for kind, color in (("pants", (51, 67, 95)), ("top", (79, 136, 134))):
        garment = Image.open(SPRITES / "characters" / f"{kind}_0.png").convert("RGBA").crop((0, 80, 12, 100))
        palette = dict.fromkeys((SKIN, SKIN_SHADE), ImageColor.getcolor(WHITE, "RGBA"))
        for shade, factor in ((DARK, 0.6), (SHADE, 0.8), (MAIN, 1.0)):
            palette[shade] = (*[round(v * factor) for v in color], 255)
        palette[LIGHT] = (*[round(v * 0.82 + 255 * 0.18) for v in color], 255)
        pixels = garment.load()
        garment.putdata([palette.get(pixels[x, y], pixels[x, y]) for y in range(20) for x in range(12)])
        body.alpha_composite(garment)
    image = Image.new("RGBA", (16, 24))
    image.alpha_composite(body, (2, 0))
    d = ImageDraw.Draw(image)
    d.rectangle((2, 21, 13, 23), fill=WOOD_EDGE)
    d.line((2, 21, 13, 21), fill=WOOD_LIGHT)
    return image


def wall() -> Image.Image:
    image = Image.new("RGBA", (64, 32), WHITE)
    d = ImageDraw.Draw(image)
    d.line((0, 0, 63, 0), fill=WHITE_LIGHT)
    d.line((0, 24, 63, 24), fill=WOOD_LIGHT)
    d.rectangle((0, 25, 63, 28), fill=WOOD)
    d.rectangle((0, 29, 63, 31), fill=WOOD_FRONT)
    return image


def brick() -> Image.Image:
    """Square seamless surface; retain the existing 16x12 brick pattern."""
    image = Image.new("RGBA", (48, 48), "#987864")
    d = ImageDraw.Draw(image)
    shades = ("#a7765e", "#a47159", "#aa7961", "#a16f58")
    for row in range(8):
        for column in range(-1, 7):
            x, y = column * 8 + (row % 2) * 4, row * 6
            d.rectangle((x + 1, y + 1, x + 7, y + 5), fill=shades[(row % 2) * 2 + column % 2])
            d.line((x + 2, y + 1, x + 6, y + 1), fill="#b78b72")
    return image


def cladding() -> Image.Image:
    """Tintable square surface; dimensions and apertures belong to the scene."""
    return Image.new("RGBA", (16, 16), "white")


def storefront_window() -> Image.Image:
    image = Image.new("RGBA", (80, 24), FRAME)
    d = ImageDraw.Draw(image)
    d.rectangle((1, 1, 78, 22), fill=GLASS)
    d.polygon(((5, 3), (12, 3), (5, 12)), fill=(255, 249, 231, 38))
    d.line((4, 4, 4, 20), fill=(255, 249, 231, 42))
    return image


def upper_window() -> Image.Image:
    image = Image.new("RGBA", (16, 18), FRAME)
    d = ImageDraw.Draw(image)
    d.rectangle((1, 1, 14, 16), fill="#65756c")
    d.line((2, 3, 2, 14), fill="#7d8d7f")
    d.line((1, 9, 14, 9), fill=FRAME)
    return image


def shirt_sign() -> Image.Image:
    """Ivory shirt-shaped facade emblem, with no backing plate or lettering."""
    image = Image.new("RGBA", (14, 12))
    d = ImageDraw.Draw(image)
    d.polygon([(4, 0), (2, 1), (0, 4), (2, 6), (4, 4), (4, 11),
               (9, 11), (9, 4), (11, 6), (13, 4), (11, 1), (9, 0),
               (8, 2), (5, 2)], fill=WHITE)
    d.line([(4, 0), (2, 1), (0, 4)], fill=WHITE_LIGHT)
    d.line((4, 11, 9, 11), fill="#d9d3c5")
    return image


def entrance_door() -> Image.Image:
    """Keep two 32px frames and the existing 14px physical passage."""
    image = Image.new("RGBA", (64, 28))
    d = ImageDraw.Draw(image)
    d.rectangle((0, 0, 15, 27), fill=FRAME)
    d.rectangle((1, 1, 14, 24), fill=GLASS)
    d.line((3, 4, 3, 20), fill=(255, 249, 231, 42))
    d.line((0, 27, 15, 27), fill=FRAME)
    d.line((12, 14, 12, 20), fill="#b49b67")
    d.line((13, 14, 13, 19), fill="#d6be8a")
    d.rectangle((32, 0, 47, 27), fill=FRAME)
    d.rectangle((33, 1, 46, 26), fill=(0, 0, 0, 0))
    leaf = image.crop((0, 0, 16, 28)).transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    image.paste(leaf, (48, 0))
    return image


def pavement() -> Image.Image:
    image = Image.new("RGBA", (64, 32), "#a6a59d")
    d = ImageDraw.Draw(image)
    for row in range(2):
        y = row * 16
        d.line((0, y + 15, 63, y + 15), fill="#95958e")
        for x in range(row * 16, 64, 32):
            d.line((x, y, x, y + 14), fill="#95958e")
            d.line((x + 1, y, min(x + 31, 63), y), fill="#b2b1a8")
    return image


def rack() -> Image.Image:
    """Empty frame; the scene displays the actual character garments."""
    image = Image.new("RGBA", (48, 20))
    d = ImageDraw.Draw(image)
    for post in (2, 44):
        d.rectangle((post, 1, post + 1, 18), fill=METAL)
        d.point((post, 1), fill=METAL_LIGHT)
        d.line((post - 1, 19, post + 2, 19), fill=METAL)
    d.line((3, 3, 44, 3), fill=METAL_LIGHT)
    d.line((3, 4, 44, 4), fill=METAL)
    d.line((4, 3, 43, 3), fill=WOOD_LIGHT)
    for x in (9, 19, 29, 39):
        d.line((x, 4, x, 7), fill=METAL)
    return image


def fitting_cabin() -> Image.Image:
    """Open 24x36 cabin: 1.5 times wider, with an unobstructed front."""
    back = Image.new("RGBA", (24, 36))
    d = ImageDraw.Draw(back)
    d.rectangle((1, 1, 22, 12), fill=WHITE)
    d.line((2, 12, 21, 12), fill=WOOD_EDGE)
    for x in (0, 22):
        d.rectangle((x, 0, x + 1, 35), fill=WHITE)
        d.line((x, 0, x, 35), fill=WOOD_EDGE)
    return back


def display_table() -> Image.Image:
    """Low wooden block with a single top surface for laid-out garments."""
    return wood_block(48)


def fitting_table() -> Image.Image:
    """Narrow front-to-back oak surface with two garment positions."""
    image = Image.new("RGBA", (12, 36), WOOD)
    d = ImageDraw.Draw(image)
    d.line((0, 0, 11, 0), fill=WOOD_LIGHT)
    d.line((1, 1, 1, 30), fill=WOOD_GRAIN)
    d.line((10, 2, 10, 30), fill=WOOD_EDGE)
    d.rectangle((0, 32, 11, 35), fill=WOOD_FRONT)
    d.line((1, 31, 10, 31), fill=WOOD_EDGE)
    return image


def sale_table() -> Image.Image:
    """Square oak top for four garments, with a low front face."""
    image = Image.new("RGBA", (32, 36), WOOD)
    d = ImageDraw.Draw(image)
    d.line((1, 0, 30, 0), fill=WOOD_LIGHT)
    d.line((1, 31, 30, 31), fill=WOOD_EDGE)
    d.rectangle((1, 32, 30, 35), fill=WOOD_FRONT)
    d.line((4, 9, 14, 9), fill=WOOD_GRAIN)
    d.line((18, 23, 27, 23), fill=WOOD_EDGE)
    return image


def sale_sign() -> Image.Image:
    """Small freestanding SALE -50% sign with hand-pixelled lettering."""
    image = Image.new("RGBA", (22, 26))
    d = ImageDraw.Draw(image)
    d.rectangle((10, 13, 11, 23), fill=WOOD_EDGE)
    d.rectangle((7, 24, 14, 25), fill=WOOD_FRONT)
    d.rectangle((0, 0, 21, 14), fill="#ad5d51")
    d.line((1, 0, 20, 0), fill="#c07967")
    glyphs = {
        "S": ("111", "100", "111", "001", "111"),
        "A": ("010", "101", "111", "101", "101"),
        "L": ("100", "100", "100", "100", "111"),
        "E": ("111", "100", "110", "100", "111"),
        "-": ("000", "000", "111", "000", "000"),
        "5": ("111", "100", "111", "001", "111"),
        "0": ("111", "101", "101", "101", "111"),
        "%": ("101", "001", "010", "100", "101"),
    }
    for word, y in (("SALE", 2), ("-50%", 8)):
        for index, letter in enumerate(word):
            for row, line in enumerate(glyphs[letter]):
                for column, pixel in enumerate(line):
                    if pixel == "1":
                        d.point((3 + index * 4 + column, y + row), fill=WHITE_LIGHT)
    return image


def pouf() -> Image.Image:
    """Small sage upholstered seat on a low oak plinth."""
    image = Image.new("RGBA", (16, 14))
    d = ImageDraw.Draw(image)
    d.rectangle((2, 10, 13, 13), fill=WOOD_EDGE)
    d.line((2, 12, 13, 12), fill=WOOD)
    d.polygon([(0, 3), (15, 3), (15, 10), (13, 12), (2, 12), (0, 10)],
              fill="#7f8976")
    d.polygon([(2, 0), (13, 0), (15, 2), (15, 7), (13, 9), (2, 9),
               (0, 7), (0, 2)], fill="#929b86")
    d.line((2, 0, 13, 0), fill="#a1a994")
    return image


def wood_block(width: int) -> Image.Image:
    image = Image.new("RGBA", (width, 16))
    d = ImageDraw.Draw(image)
    d.rectangle((0, 0, width - 1, 11), fill=WOOD)
    d.line((1, 0, width - 2, 0), fill=WOOD_LIGHT)
    d.line((1, 11, width - 2, 11), fill=WOOD_EDGE)
    d.rectangle((1, 12, width - 2, 15), fill=WOOD_FRONT)
    d.line((3, 5, 19, 5), fill=WOOD_GRAIN)
    d.line((width - 19, 8, width - 5, 8), fill=WOOD_EDGE)
    return image


def cash_register() -> Image.Image:
    """Controls face north toward the clerk; the customer sees the rear casing."""
    image = Image.new("RGBA", (14, 12))
    d = ImageDraw.Draw(image)
    d.rectangle((1, 2, 12, 8), fill="#b5bcb7")
    # The keypad is on the far side of the raised display, beside the receipt.
    d.rectangle((1, 1, 7, 4), fill="#a2aca5")
    for y in (1, 3):
        for x in (2, 4, 6):
            d.point((x, y), fill="#737f77")
    d.rectangle((9, 0, 11, 4), fill="#eee9d9")
    d.line((10, 1, 11, 1), fill="#b9b9a8")
    # Only the upper edge of the north-facing screen is visible from this view.
    d.line((2, 4, 7, 4), fill="#476d55")
    d.rectangle((1, 5, 8, 8), fill="#8b9990")
    d.line((2, 5, 7, 5), fill="#a2aca5")
    d.line((3, 7, 6, 7), fill="#737f77")
    d.rectangle((0, 9, 13, 11), fill="#858f89")
    d.line((1, 9, 12, 9), fill="#a2aca5")
    return image


def clerk() -> Image.Image:
    clerk = Image.new("RGBA", (24, 20))
    d = ImageDraw.Draw(clerk)
    for frame in range(2):
        x = frame * 12
        d.rectangle((x + 3, 8, x + 8, 15), fill="#eee4ce")
        d.rectangle((x + 2, 9, x + 2, 12), fill="#cdbf9f")
        d.rectangle((x + 9, 9, x + 9, 12), fill="#cdbf9f")
        d.rectangle((x + 2, 13, x + 2, 15), fill="#ecc295")
        d.rectangle((x + 9, 13, x + 9, 15), fill="#ecc295")
        d.rectangle((x + 3, 9, x + 4, 15), fill="#526d83")
        d.rectangle((x + 7, 9, x + 8, 15), fill="#526d83")
        d.line((x + 4, 9, x + 4, 13), fill="#7e94a4")
        d.point((x + 7, 10), fill="#f1e8d1")
        d.rectangle((x + 3, 2, x + 8, 7), fill="#ecc295")
        d.rectangle((x + 3, 0, x + 8, 2), fill="#3b3030")
        d.line((x + 3, 3, x + 5, 3), fill="#3b3030")
        d.point((x + 3, 4), fill="#3b3030")
        if not frame:
            d.point((x + 4, 5), fill="#584638")
            d.point((x + 7, 5), fill="#584638")
        d.rectangle((x + 3, 16, x + 5, 18), fill="#404b50")
        d.rectangle((x + 7, 16, x + 8, 18), fill="#404b50")
        d.line((x + 3, 19, x + 5, 19), fill="#494035")
        d.line((x + 7, 19, x + 8, 19), fill="#494035")
    return clerk


def destination_icon() -> Image.Image:
    icon = Image.new("RGBA", (32, 32))
    d = ImageDraw.Draw(icon)
    d.polygon([(12, 7), (8, 9), (6, 14), (10, 16), (11, 13), (11, 25),
               (21, 25), (21, 13), (22, 16), (26, 14), (24, 9), (20, 7),
               (18, 10), (14, 10)], fill=PHONE_GLYPH_COLOR)
    return icon


def generate() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    for name, draw in {
        "floor": floor, "wall": wall, "brick": brick, "cladding": cladding,
        "window": storefront_window, "upper_window": upper_window,
        "shirt_sign": shirt_sign,
        "entrance_mat": entrance_mat,
        "wall_clock": wall_clock,
        "mannequin": mannequin,
        "entrance_door": entrance_door,
        "pavement": pavement,
        "rack": rack, "display_table": display_table, "fitting_table": fitting_table,
        "sale_table": sale_table, "sale_sign": sale_sign,
        "pouf": pouf, "cash_register": cash_register, "fitting_cabin": fitting_cabin,
        "counter": lambda: wood_block(52), "clerk": clerk, "destination_icon": destination_icon,
    }.items():
        draw().save(OUT / (name + ".png"))


if __name__ == "__main__":
    generate()
