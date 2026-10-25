#!/usr/bin/env python3
"""Generate only the decorative grocery sprites; never overwrite shared assets.

Walls deliberately reuse home_entrance/brick.png in the Godot scenes. Furniture
has flat material colours, without baked cast shadows. Glass retains RGBA alpha.
The 12x20 character is the scale reference: counters are 14 px, two-tier
shelving 20 px, and the two-tier commercial fridge 26 px tall.
"""

from pathlib import Path

from PIL import Image, ImageDraw

from gen_clothing_store_sprites import clerk, entrance_door as clothing_entrance_door


OUTPUT = Path(__file__).resolve().parents[1] / "assets/sprites/grocery"
CREAM = "#dedbc6"
METAL = "#adb3a2"


def shelf(width: int, height: int, rows: tuple[int, ...]) -> Image.Image:
    image = Image.new("RGBA", (width, height))
    draw = ImageDraw.Draw(image)
    draw.rectangle((1, 0, width - 2, height - 1), fill=CREAM)
    draw.rectangle((3, 2, width - 4, height - 3), fill="#b7bea3")
    draw.rectangle((2, 0, width - 3, 1), fill="#ece7d2")
    for y in rows:
        draw.line((3, y, width - 4, y), fill="#eae4ce")
    draw.rectangle((1, 2, 2, height - 1), fill=METAL)
    draw.rectangle((width - 3, 2, width - 2, height - 1), fill=METAL)
    draw.rectangle((3, height - 1, width - 4, height - 1), fill="#c4c5b1")
    return image


def floor() -> Image.Image:
    image = Image.new("RGBA", (12, 12), "#d0c9b2")
    draw = ImageDraw.Draw(image)
    draw.line((0, 0, 11, 0), fill="#bdb9a5")
    draw.line((0, 0, 0, 11), fill="#bdb9a5")
    return image


def wall() -> Image.Image:
    image = Image.new("RGBA", (24, 32), "#e1ddc8")
    draw = ImageDraw.Draw(image)
    draw.rectangle((0, 29, 23, 31), fill="#bdbda7")
    return image


def storefront_glass(width: int, height: int) -> Image.Image:
    """Translucent tint and stepped reflections, without opaque backing."""
    image = Image.new("RGBA", (width, height), (139, 181, 186, 68))
    reflections = Image.new("RGBA", image.size)
    draw = ImageDraw.Draw(reflections)
    slant = 12 if width > 30 else 7
    starts = (width // 3, width * 3 // 4) if width > 30 else (width - 4,)
    for x in starts:
        band = 4 if width > 30 else 2
        draw.polygon([(x, 0), (x + band, 0),
                      (x + band - slant, height - 1), (x - slant, height - 1)],
                     fill=(228, 241, 231, 50))
        if width > 30:
            draw.line((x + band + 4, 0, x + band + 4 - slant, height - 1),
                      fill=(228, 241, 231, 35))
    image.alpha_composite(reflections)
    return image


def window() -> Image.Image:
    image = Image.new("RGBA", (92, 28), METAL)
    # Uniform 2px frame: no extra sill stripe under the glass.
    image.paste(storefront_glass(88, 24), (2, 2))
    return image


def door() -> Image.Image:
    """Keep the clothing shop's single leaf, frame, handle and open pose."""
    image = clothing_entrance_door()
    source = image.copy()
    image.paste(storefront_glass(14, 24), (1, 1))
    for x, end_y in ((12, 20), (13, 19)):
        for y in range(14, end_y + 1):
            image.putpixel((x, y), source.getpixel((x, y)))
    leaf = image.crop((0, 0, 16, 28)).transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    image.paste(leaf, (48, 0))
    return image


def fridge() -> Image.Image:
    image = Image.new("RGBA", (44, 26))
    draw = ImageDraw.Draw(image)
    draw.rectangle((0, 0, 43, 25), fill="#7e9586")
    draw.rectangle((2, 1, 41, 4), fill="#a0b5a0")
    draw.rectangle((2, 5, 41, 23), fill="#d3debd")
    for y in (14, 23):
        draw.line((2, y, 41, y), fill="#eff0d6")
    return image


def fridge_glass() -> Image.Image:
    image = Image.new("RGBA", (44, 26))
    draw = ImageDraw.Draw(image)
    draw.rectangle((2, 5, 41, 23), fill=(177, 214, 203, 40))
    draw.rectangle((21, 5, 22, 24), fill="#879c8c")
    draw.line((19, 13, 19, 17), fill="#eff0d6")
    draw.line((24, 13, 24, 17), fill="#eff0d6")
    return image


def counter() -> Image.Image:
    image = Image.new("RGBA", (40, 14))
    draw = ImageDraw.Draw(image)
    draw.rectangle((1, 0, 38, 13), fill="#b8bba4")
    draw.rectangle((2, 6, 37, 12), fill="#7e8b64")
    draw.rectangle((1, 0, 38, 5), fill="#e6dfc3")
    draw.line((2, 0, 37, 0), fill="#f0e9d2")
    draw.line((2, 13, 37, 13), fill="#ced0b8")
    return image


def cash_register() -> Image.Image:
    image = Image.new("RGBA", (8, 7))
    draw = ImageDraw.Draw(image)
    draw.rectangle((0, 5, 7, 6), fill="#858f89")
    draw.rectangle((1, 0, 5, 4), fill="#a2aca5")
    draw.line((2, 1, 4, 1), fill="#476d55")
    draw.rectangle((1, 3, 5, 4), fill="#8b9990")
    draw.line((7, 1, 7, 3), fill="#eee9d9")
    return image


def shopping_baskets() -> Image.Image:
    """Four nested baskets with equal-width rims and folded handles."""
    image = Image.new("RGBA", (12, 10))
    draw = ImageDraw.Draw(image)
    draw.rectangle((1, 1, 10, 8), fill="#879c7c")
    draw.line((2, 9, 9, 9), fill="#879c7c")
    # Each basket has a full-width projecting lip, separated from the next.
    # Only the lowest basket tapers: a continuous taper reads as one basket.
    for y in (2, 4, 6, 8):
        draw.line((0, y, 11, y), fill="#b0bca0")
        draw.line((2, y + 1, 9, y + 1), fill="#6c846f")
        draw.line((4, y + 1, 7, y + 1), fill="#879c7c")
    # Open top and a handle folded against its back rim, with no upright arch.
    draw.line((1, 0, 10, 0), fill="#b0bca0")
    draw.line((3, 0, 8, 0), fill="#71866f")
    draw.line((2, 1, 9, 1), fill="#6c846f")
    return image


def produce_crate() -> Image.Image:
    """Low wooden 18x14 crate; the front slat is a separate overlay."""
    image = Image.new("RGBA", (18, 14))
    draw = ImageDraw.Draw(image)
    draw.rectangle((1, 2, 16, 13), fill="#b2926c")
    draw.rectangle((2, 3, 15, 10), fill="#927c59")
    draw.line((1, 2, 16, 2), fill="#d0b38a")
    draw.rectangle((0, 3, 1, 12), fill="#c2a47c")
    draw.rectangle((16, 3, 17, 12), fill="#b2926c")
    return image


def produce_crate_front() -> Image.Image:
    image = Image.new("RGBA", (18, 14))
    draw = ImageDraw.Draw(image)
    draw.rectangle((1, 10, 16, 13), fill="#b2926c")
    draw.line((1, 10, 16, 10), fill="#d0b38a")
    draw.line((2, 12, 15, 12), fill="#9d815e")
    draw.line((2, 10, 2, 13), fill="#c2a47c")
    draw.line((15, 10, 15, 13), fill="#c2a47c")
    return image


def seller() -> Image.Image:
    image = clerk()
    draw = ImageDraw.Draw(image)
    for x in (0, 12):
        # Short chestnut hair, parted on the left and swept to the right.
        # Restore the forehead before replacing the shared clerk's hairstyle.
        draw.rectangle((x + 3, 0, x + 8, 1), fill=(0, 0, 0, 0))
        draw.rectangle((x + 3, 2, x + 8, 4), fill="#ecc295")
        draw.line((x + 4, 0, x + 7, 0), fill="#96764f")
        draw.line((x + 3, 1, x + 8, 1), fill="#96764f")
        draw.point((x + 4, 1), fill="#c1a47c")
        draw.line((x + 5, 2, x + 8, 2), fill="#96764f")
        draw.line((x + 6, 1, x + 7, 1), fill="#b49368")
        draw.line((x + 7, 3, x + 8, 3), fill="#795d42")
        draw.line((x + 3, 2, x + 3, 3), fill="#795d42")
        draw.rectangle((x + 4, 9, x + 7, 15), fill="#708768")
        draw.point((x + 4, 8), fill="#708768")
        draw.point((x + 7, 8), fill="#708768")
        # Mirror the left leg and shoe around the centre of each 12px frame.
        draw.line((x + 5, 16, x + 5, 19), fill=(0, 0, 0, 0))
        for y in range(16, 20):
            for left_x in range(6):
                image.putpixel((x + 11 - left_x, y), image.getpixel((x + left_x, y)))
    return image


def apple_sign() -> Image.Image:
    image = Image.new("RGBA", (10, 10))
    draw = ImageDraw.Draw(image)
    # Integer steps define the round backing, with no antialiasing or shadow.
    draw.polygon([(3, 0), (6, 0), (6, 1), (8, 1), (8, 3), (9, 3),
                  (9, 6), (8, 6), (8, 8), (6, 8), (6, 9), (3, 9),
                  (3, 8), (1, 8), (1, 6), (0, 6), (0, 3), (1, 3),
                  (1, 1), (3, 1)], fill="#e9e3bf")
    # Rounded green fruit with a small brown twig above the top notch.
    draw.point((5, 1), fill="#8a704b")
    draw.line((4, 2, 4, 3), fill="#8a704b")
    draw.line((2, 3, 3, 3), fill="#7eaa36")
    draw.line((6, 3, 7, 3), fill="#7eaa36")
    draw.rectangle((1, 4, 8, 6), fill="#7eaa36")
    draw.line((2, 7, 7, 7), fill="#7eaa36")
    draw.line((3, 8, 6, 8), fill="#719a32")
    draw.line((2, 4, 2, 5), fill="#b5cc60")
    draw.point((7, 7), fill="#719a32")
    return image


def main() -> None:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    generators = {
        "floor": floor, "wall": wall, "window": window, "entrance_door": door,
        "gondola": lambda: shelf(30, 20, (9, 18)),
        "fridge": fridge, "fridge_glass": fridge_glass,
        "counter": counter, "seller": seller,
        "cash_register": cash_register,
        "shopping_baskets": shopping_baskets,
        "produce_crate": produce_crate,
        "produce_crate_front": produce_crate_front,
        "apple_sign": apple_sign,
    }
    for name, generate in generators.items():
        image = generate()
        image.save(OUTPUT / f"{name}.png")
        print(f"{name}: {image.width}x{image.height} RGBA")


if __name__ == "__main__":
    main()
