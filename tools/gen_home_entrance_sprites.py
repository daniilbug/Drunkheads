#!/usr/bin/env python3
"""Generate the approved home entrance textures with Pillow.

The entrance door uses two 48x28 frames, with a centered 24-pixel
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
ENTRANCE_DOOR_OPENING_WIDTH = 24
ENTRANCE_DOOR_FRAME_SIZE = (ENTRANCE_DOOR_OPENING_WIDTH * 2, 28)
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
    half_width = ENTRANCE_DOOR_FRAME_SIZE[0] // 2
    leaf_width = ENTRANCE_DOOR_OPENING_WIDTH // 2 - 1
    opening_left = half_width - leaf_width - 1
    leaf, draw = canvas(leaf_width, 26)
    draw.rectangle((0, 0, leaf_width - 1, 25), fill=PALETTE["door"])
    draw.line((leaf_width - 1, 0, leaf_width - 1, 25), fill=PALETTE["door_dark"])
    draw.line((1, 1, leaf_width - 2, 1), fill=PALETTE["door_light"])
    draw.line((leaf_width - 2, 12, leaf_width - 2, 15), fill=PALETTE["steel"])
    image = Image.new("RGBA", (ENTRANCE_DOOR_FRAME_SIZE[0] * 2, 28))
    for index in range(2):
        half, draw = canvas(half_width, 28)
        # Draw the left half and mirror it, including frame and handles.
        draw.line((opening_left, 0, half_width - 1, 0), fill=PALETTE["door_light"])
        draw.line((opening_left, 1, opening_left, 26), fill=PALETTE["door_light"])
        draw.line((opening_left, 27, half_width - 1, 27), fill=PALETTE["steel"])
        if index == 0:
            half.alpha_composite(leaf, (opening_left + 1, 1))
        else:
            half.alpha_composite(leaf.transpose(Image.Transpose.FLIP_LEFT_RIGHT), (1, 1))
        frame_x = index * ENTRANCE_DOOR_FRAME_SIZE[0]
        image.alpha_composite(half, (frame_x, 0))
        image.alpha_composite(half.transpose(Image.Transpose.FLIP_LEFT_RIGHT), (frame_x + half_width, 0))
    return image


def entrance_step() -> Image.Image:
    """Widen the existing concrete step by extending only its flat middle."""
    source = Image.open(SPRITES / "porch.png").convert("RGBA")
    width = ENTRANCE_DOOR_OPENING_WIDTH + 6
    middle = source.width // 2
    extra = width - source.width
    image = Image.new("RGBA", (width, source.height))
    image.alpha_composite(source.crop((0, 0, middle, source.height)))
    column = source.crop((middle, 0, middle + 1, source.height))
    for x in range(middle, middle + extra):
        image.alpha_composite(column, (x, 0))
    image.alpha_composite(source.crop((middle, 0, source.width, source.height)), (middle + extra, 0))
    return image


def elevator() -> Image.Image:
    """32x32 flat metal elevator, a 6x3 indicator and one left call button."""
    half, draw = canvas(16, 32)
    draw.rectangle((4, 4, 15, 31), fill=PALETTE["steel_frame"])
    draw.line((5, 5, 15, 5), fill=PALETTE["silver"])
    draw.rectangle((7, 7, 14, 28), fill=PALETTE["steel"])
    draw.line((7, 7, 7, 27), fill=PALETTE["silver"])
    draw.line((7, 28, 14, 28), fill=PALETTE["steel_dark"])
    draw.line((15, 7, 15, 28), fill=PALETTE["steel_dark"])
    draw.line((5, 30, 15, 30), fill=PALETTE["silver"])
    draw.rectangle((13, 0, 15, 2), fill=PALETTE["steel_dark"])
    draw.point((15, 1), fill=PALETTE["silver"])
    image = Image.new("RGBA", (32, 32))
    image.alpha_composite(half)
    image.alpha_composite(half.transpose(Image.Transpose.FLIP_LEFT_RIGHT), (16, 0))
    # Keep the call button at its original height, only on the left wall.
    draw = ImageDraw.Draw(image)
    draw.rectangle((0, 17, 2, 22), fill=PALETTE["steel_frame"])
    draw.line((1, 18, 1, 21), fill=PALETTE["steel_dark"])
    draw.point((1, 20), fill=PALETTE["silver"])
    return image


def elevator_frame() -> Image.Image:
    """Preserve the approved housing, with a clear opening for sliding doors."""
    image = elevator()
    ImageDraw.Draw(image).rectangle((7, 7, 24, 28), fill=(0, 0, 0, 0))
    return image


def elevator_doors() -> Image.Image:
    """Two 9x22 leaves cropped from the approved closed elevator."""
    return elevator().crop((7, 7, 25, 29))


def elevator_cabin() -> Image.Image:
    """Flat cabin wall and floor, with a single line between them."""
    image, draw = canvas(32, 32)
    draw.rectangle((7, 7, 24, 17), fill=PALETTE["door"])
    draw.rectangle((7, 19, 24, 28), fill=PALETTE["door_light"])
    draw.line((7, 18, 24, 18), fill=PALETTE["steel_dark"])
    return image


def stair_door() -> Image.Image:
    """16x28 wooden door; a flat leaf, handle and stair sign, without a stroke."""
    image, draw = canvas(16, 28)
    draw.rectangle((0, 0, 15, 27), fill=PALETTE["brown"])
    draw.line((1, 1, 14, 1), fill=PALETTE["brown_light"])
    draw.rectangle((5, 4, 10, 9), fill=PALETTE["brown_dark"])
    draw.line((6, 8, 7, 8, 7, 6, 8, 6, 8, 5, 9, 5), fill=PALETTE["cream"])
    draw.rectangle((12, 14, 13, 18), fill=PALETTE["brown_dark"])
    draw.line((11, 15, 13, 15), fill=PALETTE["steel"])
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
        ("1. Входная дверь — закрыта", "Кадр 48×28 · проём 24 пикселя", door.crop((0, 0, 48, 28))),
        ("2. Входная дверь — открыта", "Две створки · проём по центру", door.crop((48, 0, 96, 28))),
        ("3. Лифт", "32×32 · индикатор 6×3 · 4 цвета", textures["elevator"]),
        ("4. Дверь лестницы", "16×28 · постоянно закрыта", textures["stair_door"]),
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
    draw.line((24, 108, 51, 108), fill=WALL_PALETTE["plinth"], width=2)
    draw.line((76, 108, 103, 108), fill=WALL_PALETTE["plinth"], width=2)
    room.alpha_composite(textures["entrance_door"].crop((48, 0, 96, 28)), (40, 81))
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
    generators = {
        "entrance_door": entrance_door, "elevator": elevator,
        "stair_door": stair_door, "wall": wall, "floor": floor,
        "entrance_step": entrance_step, "elevator_frame": elevator_frame,
        "elevator_doors": elevator_doors, "elevator_cabin": elevator_cabin,
    }
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--preview-dir", type=Path, help="Directory outside assets/sprites for review images")
    parser.add_argument("--only", nargs="+", choices=generators, help="Write only the selected textures")
    args = parser.parse_args()
    if args.preview_dir and args.preview_dir.resolve().is_relative_to(SPRITES):
        parser.error("Keep review images outside assets/sprites")
    textures = {name: generate() for name, generate in generators.items()
                if args.only is None or name in args.only}
    OUTPUT.mkdir(parents=True, exist_ok=True)
    for name, image in textures.items():
        output = OUTPUT / f"{name}.png"
        image.save(output)
        print(f"{output}: {image.width}x{image.height} RGBA")
    if args.preview_dir:
        args.preview_dir.mkdir(parents=True, exist_ok=True)
        for name in generators:
            if name not in textures:
                textures[name] = Image.open(OUTPUT / f"{name}.png").convert("RGBA")
        for name, image in (("sprites", review_sheet(textures)), ("lobby", lobby_mockup(textures))):
            output = args.preview_dir / f"{name}.png"
            image.save(output)
            print(output)


if __name__ == "__main__":
    main()
