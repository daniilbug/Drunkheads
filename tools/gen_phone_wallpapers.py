#!/usr/bin/env python3
"""Draw four subdued, pixel-art phone wallpapers as standalone PNGs."""

from pathlib import Path
from random import Random

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "assets" / "sprites" / "phone"
SIZE = (300, 500)
SCALE = 2
W, H = SIZE[0] // SCALE, SIZE[1] // SCALE


def backdrop(top: tuple[int, int, int], bottom: tuple[int, int, int], seed: int) -> Image.Image:
    image = Image.new("RGB", (W, H))
    pixels = image.load()
    rng = Random(seed)
    for y in range(H):
        t = y / (H - 1)
        for x in range(W):
            grain = rng.choice((-2, -1, 0, 0, 0, 1, 2))
            pixels[x, y] = tuple(
                max(0, min(255, round(a * (1 - t) + b * t) + grain))
                for a, b in zip(top, bottom)
            )
    return image


def overlay(image: Image.Image, draw_scene) -> Image.Image:
    layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw_scene(ImageDraw.Draw(layer))
    return Image.alpha_composite(image.convert("RGBA"), layer).resize(SIZE, Image.Resampling.NEAREST)


def midnight() -> Image.Image:
    """The bar at night, seen as a quiet street silhouette."""
    image = backdrop((25, 42, 57), (37, 52, 61), 11)

    def scene(d: ImageDraw.ImageDraw) -> None:
        d.ellipse((-42, 134, 48, 224), fill=(91, 111, 116, 18))
        d.ellipse((75, 152, 173, 250), fill=(91, 111, 116, 12))
        d.rectangle((0, 177, 150, 250), fill=(14, 31, 43, 47))
        d.polygon([(0, 187), (37, 178), (69, 181), (106, 172), (150, 179), (150, 250), (0, 250)], fill=(15, 29, 38, 83))
        d.rectangle((9, 194, 41, 245), fill=(20, 35, 43, 97))
        d.rectangle((44, 187, 91, 245), fill=(20, 35, 43, 102))
        d.rectangle((95, 195, 139, 245), fill=(20, 35, 43, 90))
        for x, y in [(16, 201), (31, 211), (54, 194), (75, 204), (101, 207), (124, 200), (134, 218)]:
            d.rectangle((x, y, x + 2, y + 3), fill=(199, 158, 99, 50))
        d.line((0, 231, 150, 231), fill=(126, 135, 124, 32), width=1)

    return overlay(image, scene)


def amber() -> Image.Image:
    """Warm, low-contrast concentric light from the bar."""
    image = backdrop((67, 49, 52), (77, 61, 57), 23)

    def scene(d: ImageDraw.ImageDraw) -> None:
        for radius, alpha in [(113, 18), (91, 24), (69, 29), (47, 33)]:
            x, y = 137, 200
            d.arc((x - radius, y - radius, x + radius, y + radius), 175, 355, fill=(214, 157, 107, alpha), width=2)
        d.polygon([(0, 211), (31, 197), (67, 209), (105, 189), (150, 205), (150, 250), (0, 250)], fill=(38, 28, 37, 35))
        for x, y in [(13, 181), (39, 151), (116, 145), (52, 223), (125, 228)]:
            d.rectangle((x, y, x + 1, y + 1), fill=(226, 182, 132, 55))

    return overlay(image, scene)


def sage() -> Image.Image:
    """Muted green bar shelves with quiet bottle silhouettes."""
    image = backdrop((35, 64, 65), (43, 73, 69), 37)

    def scene(d: ImageDraw.ImageDraw) -> None:
        d.rectangle((0, 164, 150, 230), fill=(103, 133, 115, 8))
        d.line((0, 229, 150, 229), fill=(169, 184, 152, 40), width=2)
        d.rectangle((0, 232, 150, 250), fill=(17, 43, 44, 38))
        bottles = [
            (15, 187, 16, 38),
            (45, 179, 21, 46),
            (85, 193, 15, 32),
            (116, 173, 19, 52),
        ]
        for x, top, width, height in bottles:
            neck = max(5, width // 3)
            cx = x + width // 2
            d.polygon(
                [(cx - neck // 2, top), (cx + neck // 2, top),
                 (cx + neck // 2, top + 11), (x + width, top + 17),
                 (x + width, top + height), (x, top + height),
                 (x, top + 17), (cx - neck // 2, top + 11)],
                fill=(17, 48, 48, 78),
            )
            d.line((x + 2, top + 20, x + 2, top + height - 3), fill=(148, 180, 157, 35))
            d.rectangle((x + 3, top + height - 18, x + width - 4, top + height - 13), fill=(157, 168, 128, 20))
        d.line((0, 163, 150, 163), fill=(174, 199, 175, 17))

    return overlay(image, scene)


def plum() -> Image.Image:
    """A restrained Art Deco diamond grid in the game's night palette."""
    image = backdrop((52, 42, 62), (66, 48, 66), 49)

    def scene(d: ImageDraw.ImageDraw) -> None:
        for row, y in enumerate(range(118, 280, 37)):
            for x in range(-40 + (row % 2) * 28, 190, 56):
                d.line([(x, y), (x + 28, y + 18), (x, y + 36), (x - 28, y + 18), (x, y)], fill=(185, 142, 129, 20), width=1)
        d.rectangle((0, 237, 150, 250), fill=(25, 25, 37, 27))
        d.line((0, 236, 150, 236), fill=(188, 145, 129, 23), width=1)

    return overlay(image, scene)


def main() -> None:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    for name, make_image in (
        ("midnight", midnight),
        ("amber", amber),
        ("sage", sage),
        ("plum", plum),
    ):
        path = OUTPUT / f"wallpaper_{name}.png"
        make_image().convert("RGB").save(path)
        print(path)


if __name__ == "__main__":
    main()
