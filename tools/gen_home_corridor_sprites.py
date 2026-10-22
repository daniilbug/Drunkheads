#!/usr/bin/env python3
"""Generate the apartment doors' shared atlas and solid wall edge tile.

Two 48x28 RGBA frames retain the approved 16-pixel wooden leaf. The open
leaf moves right, like the existing balcony door, while a thin doorway
frame stays at the opening. Wood matches the home furniture; metal details
come from the existing entrance. Review sheets must be saved outside the source sprite directory.
"""

import argparse
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

from gen_home_entrance_sprites import PALETTE, tiled
from home_furniture_palette import WOOD


ROOT = Path(__file__).resolve().parents[1]
SPRITES = ROOT / "assets/sprites"
OUTPUT = SPRITES / "home"
FRAME_SIZE = (48, 28)


def door_panel() -> Image.Image:
    """Unnumbered, unoutlined leaf with a raised handle."""
    image = Image.new("RGBA", (20, 28))
    draw = ImageDraw.Draw(image)
    draw.rectangle((2, 0, 17, 27), fill=WOOD)
    draw.point((9, 12), fill=PALETTE["steel_dark"])
    draw.rectangle((15, 14, 16, 18), fill=PALETTE["steel_frame"])
    draw.line((13, 15, 16, 15), fill=PALETTE["silver"])
    return image


def apartment_door() -> Image.Image:
    """The same closed frame is used for the player and neighbour apartments."""
    panel = door_panel()
    image = Image.new("RGBA", (FRAME_SIZE[0] * 2, FRAME_SIZE[1]))
    image.alpha_composite(panel, (6, 0))
    opened = Image.new("RGBA", FRAME_SIZE)
    opened.alpha_composite(panel.crop((2, 0, 18, 28)), (24, 0))
    draw = ImageDraw.Draw(opened)
    draw.rectangle((8, 0, 23, 27), outline=WOOD)
    image.alpha_composite(opened, (FRAME_SIZE[0], 0))
    return image


def wall_edge() -> Image.Image:
    """Match the corridor polygons' tint after vertex-colour quantization.

    Sprite edges stay out of the apartment navigation mesh.
    """
    return Image.new("RGBA", (4, 4), "#403d37")


def font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont:
    name = "Arial Bold.ttf" if bold else "Arial.ttf"
    return ImageFont.truetype(f"/System/Library/Fonts/Supplemental/{name}", size)


def review_sheet(atlas: Image.Image) -> Image.Image:
    sheet = Image.new("RGB", (1120, 704), "#f0ede4")
    draw = ImageDraw.Draw(sheet)
    draw.text((32, 24), "Спрайт 2 / открытая дверь — контур проёма",
              font=font(30, True), fill="#343c37")
    draw.text((32, 70), "Тонкий контур остаётся в проёме · полотно без обводки",
              font=font(20), fill="#72776d")

    draw.rounded_rectangle((32, 126, 400, 602), radius=14, fill="#faf8f2")
    draw.text((56, 145), "ОТКРЫТАЯ ДВЕРЬ / ×6", font=font(18, True), fill="#343c37")
    for y in range(188, 548, 16):
        for x in range(56, 376, 16):
            color = "#d8d9ce" if ((x-56)//16 + (y-188)//16) % 2 else "#e3e4da"
            draw.rectangle((x, y, x+15, y+15), fill=color)
    opened = atlas.crop((48, 0, 96, 28))
    enlarged = opened.resize((288, 168), Image.Resampling.NEAREST)
    sheet.paste(enlarged, (72, 278), enlarged)
    draw.text((56, 565), "Клетка — прозрачный фон", font=font(18), fill="#72776d")

    draw.rounded_rectangle((424, 126, 1088, 602), radius=14, fill="#faf8f2")
    draw.text((448, 145), "НА СТЕНЕ ПОДЪЕЗДА / МАСШТАБ ×4",
              font=font(18, True), fill="#343c37")
    context = Image.new("RGBA", (144, 86))
    wall = Image.open(SPRITES / "home_entrance/wall.png").convert("RGBA")
    floor = Image.open(SPRITES / "home_entrance/floor.png").convert("RGBA")
    context.alpha_composite(tiled(wall, (144, 35)))
    context.alpha_composite(tiled(floor, (144, 51)), (0, 35))
    apartment_floor = Image.open(SPRITES / "home/floor.png").convert("RGBA")
    context.alpha_composite(tiled(apartment_floor, (16, 27)), (64, 7))
    context.alpha_composite(opened, (56, 7))
    player = Image.open(SPRITES / "player.png").convert("RGBA").crop((0, 20, 12, 40))
    for name in ("pants_0", "top_0", "hair_0"):
        layer = Image.open(SPRITES / f"characters/{name}.png").convert("RGBA")
        player.alpha_composite(layer.crop((0, 20, 12, 40)))
    context.alpha_composite(player, (91, 45))
    sheet.paste(context.resize((576, 344), Image.Resampling.NEAREST), (468, 192))
    draw.text((448, 565), "Стена, пол и персонаж — существующие ассеты.",
              font=font(18), fill="#72776d")

    draw.text((32, 634), "Закрытый вид у всех квартир одинаковый; открывается дверь нашей квартиры.",
              font=font(21), fill="#343c37")
    draw.text((32, 670), "Соседские двери остаются закрытыми. Показан новый открытый кадр на согласование.",
              font=font(18), fill="#72776d")
    return sheet


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--preview-dir", type=Path)
    args = parser.parse_args()
    if args.preview_dir and args.preview_dir.resolve().is_relative_to(SPRITES):
        parser.error("Keep review images outside assets/sprites")

    door = apartment_door()
    OUTPUT.mkdir(parents=True, exist_ok=True)
    output = OUTPUT / "apartment_door.png"
    door.save(output)
    print(f"{output}: {door.width}x{door.height} {door.mode}")
    edge = wall_edge()
    edge_output = OUTPUT / "wall_edge.png"
    edge.save(edge_output)
    print(f"{edge_output}: {edge.width}x{edge.height} {edge.mode}")
    if args.preview_dir:
        args.preview_dir.mkdir(parents=True, exist_ok=True)
        preview = args.preview_dir / "apartment_door_open_review_v2.png"
        review_sheet(door).save(preview)
        print(preview)


if __name__ == "__main__":
    main()
