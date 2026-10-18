#!/usr/bin/env python3
"""Generate only the five approved home entrance textures with Pillow.

The entrance door uses two 32x28 frames, with a centered 16-pixel
opening. Both leaves open outwards, preserving left/right symmetry.
Optional review images are saved outside the project sprite directory.
Use flat material colors and one-sided shading, without perimeter strokes.
"""

import argparse
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
SPRITES = ROOT / "assets/sprites"
OUTPUT = SPRITES / "home_entrance"
PALETTE = {
    "steel_frame": "#85938e",
    "steel_dark": "#718079",
    "steel": "#a8b4ae",
    "silver": "#c1cac2",
    "door": "#4b5750",
    "door_light": "#657266",
    "door_dark": "#435047",
    "cream": "#eee4ce",
    "brown": "#80614b",
    "brown_light": "#a18262",
    "brown_dark": "#644b36",
}
WALL_PALETTE = {
    "plaster": "#a29b90",
    "plaster_light": "#b7aea0",
    "plaster_dark": "#938d84",
    "paint": "#57534e",
    "paint_light": "#7c756a",
    "paint_mid": "#655f57",
    "paint_dark": "#4e4a44",
    "plinth": "#403d38",
    "plinth_shadow": "#343330",
}


def canvas(width: int, height: int) -> tuple[Image.Image, ImageDraw.ImageDraw]:
    image = Image.new("RGBA", (width, height))
    return image, ImageDraw.Draw(image)


def entrance_door() -> Image.Image:
    """Two flat mirrored steel leaves, with handles and no perimeter stroke."""
    leaf, draw = canvas(7, 26)
    draw.rectangle((0, 0, 6, 25), fill=PALETTE["door"])
    draw.line((6, 0, 6, 25), fill=PALETTE["door_dark"])
    draw.line((1, 1, 5, 1), fill=PALETTE["door_light"])
    draw.line((5, 12, 5, 15), fill=PALETTE["steel"])
    image = Image.new("RGBA", (64, 28))
    for index in range(2):
        half, draw = canvas(16, 28)
        # Draw the left half and mirror it, including frame and handles.
        draw.line((8, 0, 15, 0), fill=PALETTE["door_light"])
        draw.line((8, 1, 8, 26), fill=PALETTE["door_light"])
        draw.line((8, 27, 15, 27), fill=PALETTE["steel"])
        if index == 0:
            half.alpha_composite(leaf, (9, 1))
        else:
            half.alpha_composite(leaf.transpose(Image.Transpose.FLIP_LEFT_RIGHT), (1, 1))
        image.alpha_composite(half, (index * 32, 0))
        image.alpha_composite(half.transpose(Image.Transpose.FLIP_LEFT_RIGHT), (index * 32 + 16, 0))
    return image


def elevator() -> Image.Image:
    """32x30 flat metal elevator, a 6x3 indicator and one left call button."""
    half, draw = canvas(16, 30)
    draw.rectangle((4, 4, 15, 29), fill=PALETTE["steel_frame"])
    draw.line((5, 5, 15, 5), fill=PALETTE["silver"])
    draw.rectangle((7, 7, 14, 26), fill=PALETTE["steel"])
    draw.line((7, 7, 7, 25), fill=PALETTE["silver"])
    draw.line((7, 26, 14, 26), fill=PALETTE["steel_dark"])
    draw.line((15, 7, 15, 26), fill=PALETTE["steel_dark"])
    draw.line((5, 28, 15, 28), fill=PALETTE["silver"])
    draw.rectangle((13, 0, 15, 2), fill=PALETTE["steel_dark"])
    draw.point((15, 1), fill=PALETTE["silver"])
    image = Image.new("RGBA", (32, 30))
    image.alpha_composite(half)
    image.alpha_composite(half.transpose(Image.Transpose.FLIP_LEFT_RIGHT), (16, 0))
    # Keep the call button at its original height, only on the left wall.
    draw = ImageDraw.Draw(image)
    draw.rectangle((0, 15, 2, 20), fill=PALETTE["steel_frame"])
    draw.line((1, 16, 1, 19), fill=PALETTE["steel_dark"])
    draw.point((1, 18), fill=PALETTE["silver"])
    return image


def stair_door() -> Image.Image:
    """12x22 wooden door; a flat leaf, handle and stair sign, without a stroke."""
    image, draw = canvas(12, 22)
    draw.rectangle((0, 0, 11, 21), fill=PALETTE["brown"])
    draw.line((1, 1, 10, 1), fill=PALETTE["brown_light"])
    draw.rectangle((3, 3, 8, 8), fill=PALETTE["brown_dark"])
    draw.line((4, 7, 5, 7, 5, 5, 6, 5, 6, 4, 7, 4), fill=PALETTE["cream"])
    draw.rectangle((8, 11, 9, 15), fill=PALETTE["brown_dark"])
    draw.line((7, 12, 9, 12), fill=PALETTE["steel"])
    return image


def wall() -> Image.Image:
    """32x35 plaster strip with a thirteen-pixel washable lower band."""
    image, draw = canvas(32, 35)
    draw.rectangle((0, 0, 31, 34), fill=WALL_PALETTE["plaster"])
    draw.line((0, 0, 31, 0), fill=WALL_PALETTE["plaster_light"])
    for x, y in ((4, 8), (23, 7), (14, 14), (28, 18), (6, 19)):
        draw.point((x, y), fill=WALL_PALETTE["plaster_dark"])
    for x, y in ((10, 6), (20, 12), (2, 15), (26, 10)):
        draw.line((x, y, x + 1, y), fill=WALL_PALETTE["plaster_light"])
    draw.rectangle((0, 22, 31, 32), fill=WALL_PALETTE["paint"])
    draw.line((0, 22, 31, 22), fill=WALL_PALETTE["paint_light"])
    draw.line((0, 23, 31, 23), fill=WALL_PALETTE["paint_mid"])
    draw.point((9, 28), fill=WALL_PALETTE["paint_dark"])
    draw.line((25, 30, 26, 30), fill=WALL_PALETTE["paint_mid"])
    draw.line((0, 33, 31, 33), fill=WALL_PALETTE["plinth"])
    draw.line((0, 34, 31, 34), fill=WALL_PALETTE["plinth_shadow"])
    return image


def floor() -> Image.Image:
    """Seamless matte porcelain stoneware, with faint grain and no grout grid."""
    image, draw = canvas(16, 16)
    draw.rectangle((0, 0, 15, 15), fill="#aaa59c")
    for point in ((2, 3), (11, 2), (6, 10), (14, 13)):
        draw.point(point, fill="#a6a198")
    for point in ((8, 5), (3, 13), (13, 8), (9, 14)):
        draw.point(point, fill="#aeaaa0")
    return image


def tiled(tile: Image.Image, size: tuple[int, int]) -> Image.Image:
    image = Image.new("RGBA", size)
    for y in range(0, size[1], tile.height):
        for x in range(0, size[0], tile.width):
            image.alpha_composite(tile, (x, y))
    return image


def font(size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial.ttf", size)


def review_sheet(textures: dict[str, Image.Image]) -> Image.Image:
    image = Image.new("RGB", (1080, 750), "#f0ede4")
    draw = ImageDraw.Draw(image)
    draw.text((24, 20), "Подъезд · новые спрайты", font=font(30), fill="#343c37")
    draw.text((24, 58), "Увеличение ×6 без сглаживания · фон клеткой обозначает прозрачность",
              font=font(17), fill="#667064")
    door = textures["entrance_door"]
    entries = [
        ("1. Входная дверь — закрыта", "Кадр 32×28 · проём 16 пикселей", door.crop((0, 0, 32, 28))),
        ("2. Входная дверь — открыта", "Две створки · проём по центру", door.crop((32, 0, 64, 28))),
        ("3. Лифт", "32×30 · индикатор 6×3 · 4 цвета", textures["elevator"]),
        ("4. Дверь лестницы", "12×22 · постоянно закрыта", textures["stair_door"]),
        ("5. Отделка стен", "Фрагмент стены · тайл 32×35", tiled(textures["wall"], (48, 35))),
        ("6. Керамогранит пола", "Однородный фон · тайл 16×16", tiled(textures["floor"], (48, 32))),
    ]
    for index, (title, subtitle, sprite) in enumerate(entries):
        x = 24 + (index % 3) * 352
        y = 96 + (index // 3) * 320
        draw.rectangle((x, y, x + 327, y + 295), fill="#e3e2d8")
        for cy in range(y + 10, y + 238, 12):
            for cx in range(x + 8, x + 320, 12):
                fill = "#d8d9ce" if ((cx - x) // 12 + (cy - y) // 12) % 2 else "#e3e4da"
                draw.rectangle((cx, cy, cx + 11, min(cy + 11, y + 237)), fill=fill)
        enlarged = sprite.resize((sprite.width * 6, sprite.height * 6), Image.Resampling.NEAREST)
        image.paste(enlarged, (x + (328 - enlarged.width) // 2,
                               y + 12 + (216 - enlarged.height) // 2), enlarged)
        draw.text((x + 12, y + 247), title, font=font(19), fill="#343c37")
        draw.text((x + 12, y + 274), subtitle, font=font(15), fill="#667064")
    return image


def lobby_mockup(textures: dict[str, Image.Image]) -> Image.Image:
    """Flat art review only: no Godot scene, collision or lighting simulation."""
    room = Image.new("RGBA", (128, 126), "#d8d3c3")
    room.alpha_composite(tiled(textures["floor"], (80, 64)), (24, 44))
    wall_height = textures["wall"].height
    room.alpha_composite(tiled(textures["wall"], (80, wall_height)), (24, 44 - wall_height))
    draw = ImageDraw.Draw(room)
    wall_top = 44 - wall_height
    draw.rectangle((20, wall_top - 4, 107, wall_top - 1), fill=WALL_PALETTE["plinth"])
    for x in (20, 104):
        draw.rectangle((x, wall_top - 4, x + 3, 110), fill=WALL_PALETTE["plinth"])
        draw.line((x + 1, wall_top - 4, x + 1, 109), fill=WALL_PALETTE["paint"])
    lift = textures["elevator"]
    room.alpha_composite(lift, (46 - lift.width // 2, 44 - lift.height - 2))
    stairs = textures["stair_door"]
    room.alpha_composite(stairs, (90 - stairs.width // 2, 44 - stairs.height - 2))
    bulb = Image.open(SPRITES / "home/lightbulb.png").convert("RGBA")
    room.alpha_composite(bulb, (64, 32))
    # An existing 12x20 character frame establishes the actual world scale.
    player = Image.open(SPRITES / "player.png").convert("RGBA").crop((0, 20, 12, 40))
    for name in ("pants_0", "top_0", "hair_0"):
        layer = Image.open(SPRITES / f"characters/{name}.png").convert("RGBA")
        player.alpha_composite(layer.crop((0, 20, 12, 40)))
    room.alpha_composite(player, (55, 66))
    draw.line((24, 108, 55, 108), fill=WALL_PALETTE["plinth"], width=2)
    draw.line((72, 108, 103, 108), fill=WALL_PALETTE["plinth"], width=2)
    room.alpha_composite(textures["entrance_door"].crop((32, 0, 64, 28)), (48, 81))
    image = Image.new("RGB", (1080, 690), "#f0ede4")
    image.paste(room.resize((512, 504), Image.Resampling.NEAREST), (36, 108))
    draw = ImageDraw.Draw(image)
    draw.text((28, 22), "Подъезд · макет холла", font=font(30), fill="#343c37")
    draw.text((28, 62), "Пол 80×64 · игровой масштаб ×4 · существующий персонаж для сравнения",
              font=font(18), fill="#667064")
    labels = ["Лифт слева", "Дверь лестницы справа", "Тёплая лампочка по центру",
              "Вход снизу по центру"]
    for index, label in enumerate(labels):
        draw.text((594, 167 + index * 62), label, font=font(23), fill="#343c37")
    draw.text((594, 466), "Макет для согласования графики.", font=font(20), fill="#667064")
    draw.text((594, 497), "Свет и прозрачность — на этапе Godot.", font=font(19), fill="#667064")
    draw.text((28, 643), "Фасад скрыт, чтобы показать интерьер. Лампочка и персонаж — существующие ассеты.",
              font=font(18), fill="#667064")
    return image


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--preview-dir", type=Path, help="Directory outside assets/sprites for review images")
    args = parser.parse_args()
    if args.preview_dir and args.preview_dir.resolve().is_relative_to(SPRITES):
        parser.error("Keep review images outside assets/sprites")
    textures = {
        "entrance_door": entrance_door(), "elevator": elevator(),
        "stair_door": stair_door(), "wall": wall(), "floor": floor(),
    }
    OUTPUT.mkdir(parents=True, exist_ok=True)
    for name, image in textures.items():
        output = OUTPUT / f"{name}.png"
        image.save(output)
        print(f"{output}: {image.width}x{image.height} RGBA")
    if args.preview_dir:
        args.preview_dir.mkdir(parents=True, exist_ok=True)
        for name, image in (("sprites", review_sheet(textures)), ("lobby", lobby_mockup(textures))):
            output = args.preview_dir / f"{name}.png"
            image.save(output)
            print(output)


if __name__ == "__main__":
    main()
