#!/usr/bin/env python3
"""Generate reusable masonry, roof, window, balcony and glass door textures.

Five-storey facade and cutaway compositions are review-only images, written
outside the asset tree. Godot scenes and approved lobby textures are unchanged.
Frames, glass and metal are flat material areas without added outer strokes.
"""

import argparse
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
SPRITES = ROOT / "assets/sprites"
OUTPUT = SPRITES / "home_entrance"
FLOORS = 5
FLOOR_HEIGHT = 40
SIDE_WINDOW_COLUMNS = 3
WINDOW_SPACING = 46
HALF_WIDTH = 80 + (SIDE_WINDOW_COLUMNS - 1) * WINDOW_SPACING
SIZE = (HALF_WIDTH * 2, 80 + FLOORS * FLOOR_HEIGHT + 17)
FOOT = (HALF_WIDTH, SIZE[1] - 1)
# Includes the four-pixel upper cap, side wall edges, back wall and floor.
INTERIOR_WINDOW = (HALF_WIDTH - 42, SIZE[1] - 104, HALF_WIDTH + 42, SIZE[1])
CORNICE_HIGHLIGHT = "#949780"
CORNICE_SHADOW = "#555d4f"


def brick() -> Image.Image:
    """Seamless 24x12 masonry with two staggered six-pixel courses."""
    image = Image.new("RGBA", (24, 12), "#333936")
    draw = ImageDraw.Draw(image)
    shades = ("#4b4a47", "#54514c", "#4e4c48", "#474743")
    for row in range(2):
        for column in range(-1, 3):
            x, y = column * 12 + row * 6, row * 6
            draw.rectangle((x + 1, y + 1, x + 11, y + 5), fill=shades[row * 2 + column % 2])
            draw.line((x + 2, y + 1, x + 10, y + 1), fill="#68645a")
    return image


def roof() -> Image.Image:
    """Seamless 32x16 roof tile, without baked outer edges or cornice."""
    image = Image.new("RGBA", (32, 16), "#343f39")
    draw = ImageDraw.Draw(image)
    shades = ("#46534a", "#4b584e", "#414e46", "#46534a")
    for row in range(2):
        for column in range(-1, 3):
            x, y = column * 16 + row * 8, row * 8
            draw.rectangle((x + 1, y + 1, x + 15, y + 7), fill=shades[row * 2 + column % 2])
            draw.line((x + 2, y + 1, x + 14, y + 1), fill="#5d685a")
    return image


def window() -> Image.Image:
    """15x18 flat panes and a light frame, without an extra outer stroke."""
    half = Image.new("RGBA", (8, 18), "#b5b7a4")
    draw = ImageDraw.Draw(half)
    draw.rectangle((1, 1, 6, 15), fill="#52645b")
    draw.rectangle((0, 16, 7, 17), fill="#d3d0b9")
    image = Image.new("RGBA", (15, 18))
    image.alpha_composite(half)
    # The central mullion occupies one column; mirror the seven side columns.
    image.alpha_composite(half.crop((0, 0, 7, 18)).transpose(Image.Transpose.FLIP_LEFT_RIGHT), (8, 0))
    return image


def balcony() -> Image.Image:
    """Frontal 40x18 balcony in warm facade grays; foot anchor (20, 17)."""
    half = Image.new("RGBA", (20, 18))
    draw = ImageDraw.Draw(half)
    metal = "#68645a"
    # Flat rectangular bands, without perspective corners or side returns.
    draw.rectangle((0, 9, 19, 17), fill="#54514c")
    draw.rectangle((0, 9, 19, 13), fill="#817a6e")
    draw.rectangle((0, 3, 2, 13), fill=metal)
    # Transparent spaces between bars retain the window and brick behind them.
    for x in (7, 13, 19):
        draw.rectangle((x, 5, x + 1, 12), fill=metal)
    draw.rectangle((1, 11, 19, 12), fill=metal)
    draw.rectangle((0, 3, 19, 5), fill=metal)
    image = Image.new("RGBA", (40, 18))
    image.alpha_composite(half)
    image.alpha_composite(half.transpose(Image.Transpose.FLIP_LEFT_RIGHT), (20, 0))
    return image


def balcony_door() -> Image.Image:
    """A compact 14x24 single-leaf glass door, with one handle on the right."""
    image = Image.new("RGBA", (14, 24), "#b5b7a4")
    draw = ImageDraw.Draw(image)
    draw.rectangle((1, 1, 12, 21), fill="#52645b")
    draw.line((10, 12, 10, 14), fill="#d3d0b9")
    draw.rectangle((0, 22, 13, 23), fill="#d3d0b9")
    return image


def assemble_facade(parts: dict[str, Image.Image]) -> Image.Image:
    """Review layout: thirty windows and four balconies with glazed doors."""
    image = Image.new("RGBA", SIZE)
    width = SIZE[0]
    image.alpha_composite(tiled(parts["brick"], (width, SIZE[1] - 80)), (0, 80))
    draw = ImageDraw.Draw(image)

    roof = tiled(parts["roof"], (width, 80))
    roof_draw = ImageDraw.Draw(roof)
    roof_draw.line((4, 0, width - 5, 0), fill="#87907a")
    roof_draw.line((1, 77, width - 2, 77), fill="#707b67")
    roof_draw.rectangle((0, 78, width - 1, 79), fill="#303b34")
    alpha = Image.new("L", roof.size)
    ImageDraw.Draw(alpha).polygon([(4, 0), (width - 5, 0), (width - 1, 4), (width - 1, 79), (0, 79), (0, 4)], fill=255)
    roof.putalpha(alpha)
    image.alpha_composite(roof)
    draw.line((0, 80, width - 1, 80), fill=CORNICE_HIGHLIGHT)
    draw.line((1, 81, width - 2, 81), fill=CORNICE_SHADOW)

    for floor in range(FLOORS):
        center_y = SIZE[1] - 17 - floor * FLOOR_HEIGHT
        for column in range(-SIDE_WINDOW_COLUMNS, SIDE_WINDOW_COLUMNS + 1):
            center_x = HALF_WIDTH + column * WINDOW_SPACING
            if floor == 0 and column == 0:
                continue
            if column == 0 and "balcony_door" in parts:
                door = parts["balcony_door"]
                image.alpha_composite(door, (center_x - door.width // 2, center_y + 12 - door.height))
            else:
                pane = parts["window"]
                image.alpha_composite(pane, (center_x - pane.width // 2, center_y - pane.height // 2))
    # Door and its opening retain the dimensions approved for the existing art.
    draw.rectangle((HALF_WIDTH - 10, SIZE[1] - 30, HALF_WIDTH + 9, SIZE[1] - 1), fill="#657266")
    draw.rectangle((HALF_WIDTH - 8, SIZE[1] - 28, HALF_WIDTH + 7, SIZE[1] - 1), fill=(0, 0, 0, 0))
    if "balcony" in parts:
        for floor in range(1, FLOORS):
            center_y = SIZE[1] - 17 - floor * FLOOR_HEIGHT
            image.alpha_composite(parts["balcony"], (HALF_WIDTH - 20, center_y + 3))
    return image


def cutaway_mockup(source: Image.Image) -> Image.Image:
    """Illustrate the proposed local dark silhouette; not a runtime mask asset."""
    image = Image.new("RGBA", source.size, "#282622")
    image.putalpha(source.getchannel("A"))
    draw = ImageDraw.Draw(image)
    left, top, right, bottom = INTERIOR_WINDOW
    # A restrained rim gives the hidden wings a solid thickness.
    draw.rectangle((left - 2, top - 2, right + 1, bottom - 1), fill="#45413b")
    draw.rectangle((left, top, right - 1, bottom - 1), fill=(0, 0, 0, 0))
    return image


def tiled(tile: Image.Image, size: tuple[int, int]) -> Image.Image:
    image = Image.new("RGBA", size)
    for y in range(0, size[1], tile.height):
        for x in range(0, size[0], tile.width):
            image.alpha_composite(tile, (x, y))
    return image


def sprite(relative: str) -> Image.Image:
    return Image.open(SPRITES / relative).convert("RGBA")


def preview_panel(exterior: Image.Image, inside: bool) -> Image.Image:
    image = tiled(sprite("street/asphalt.png"), (SIZE[0] + 32, SIZE[1] + 31))
    origin = (16, 8)
    room_origin = (origin[0] + HALF_WIDTH - 40, origin[1] + SIZE[1] - 65)
    door_origin = (origin[0] + HALF_WIDTH - 16, origin[1] + SIZE[1] - 28)
    if not inside:
        image.alpha_composite(exterior, origin)
        door = sprite("home_entrance/entrance_door.png").crop((0, 0, 32, 28))
        image.alpha_composite(door, door_origin)
        return image

    # The building volume is behind the room, so tall fixtures can extend
    # beyond the back wall without being clipped by the dark silhouette.
    image.alpha_composite(cutaway_mockup(exterior), origin)
    floor = tiled(sprite("home_entrance/floor.png"), (80, 64))
    wall_tile = sprite("home_entrance/wall.png")
    wall = tiled(wall_tile, (80, wall_tile.height))
    image.alpha_composite(floor, room_origin)
    image.alpha_composite(wall, (room_origin[0], room_origin[1] - wall.height))
    elevator = sprite("home_entrance/elevator.png")
    image.alpha_composite(elevator, (room_origin[0] + 22 - elevator.width // 2, room_origin[1] - elevator.height - 2))
    stairs = sprite("home_entrance/stair_door.png")
    image.alpha_composite(stairs, (room_origin[0] + 66 - stairs.width // 2, room_origin[1] - stairs.height - 2))
    draw = ImageDraw.Draw(image)
    wall_top = room_origin[1] - wall.height
    draw.rectangle((room_origin[0] - 2, wall_top - 4, room_origin[0] + 81, wall_top - 1), fill="#403d38")
    for x in (room_origin[0] - 2, room_origin[0] + 78):
        draw.rectangle((x, wall_top - 4, x + 3, room_origin[1] + 63), fill="#403d38")
    player = sprite("player.png").crop((0, 20, 12, 40))
    for layer in ("pants_0", "top_0", "hair_0"):
        player.alpha_composite(sprite(f"characters/{layer}.png").crop((0, 20, 12, 40)))
    image.alpha_composite(player, (room_origin[0] + 34, room_origin[1] + 12))
    image.alpha_composite(sprite("home/lightbulb.png"), (room_origin[0] + 36, room_origin[1] + 1))
    door = sprite("home_entrance/entrance_door.png").crop((32, 0, 64, 28))
    door.putalpha(door.getchannel("A").point(lambda value: value // 10))
    image.alpha_composite(door, door_origin)
    return image


def font(size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial.ttf", size)


def components_sheet(parts: dict[str, Image.Image]) -> Image.Image:
    image = Image.new("RGB", (1020, 268), "#f0ede4")
    draw = ImageDraw.Draw(image)
    draw.text((16, 14), "Отдельные переиспользуемые PNG фасада", font=font(24), fill="#343c37")
    for x, name, label in ((16, "brick", "Кирпич · 24×12"), (216, "roof", "Крыша · 32×16"), (416, "window", "Окно · 15×18"), (616, "balcony", "Балкон · 40×18"), (816, "balcony_door", "Дверь · 14×24")):
        draw.text((x, 54), label, font=font(19), fill="#343c37")
        part = parts[name]
        image.paste(part.resize((part.width * 4, part.height * 4), Image.Resampling.NEAREST), (x, 90))
        draw.text((x, 236), "повторяемый тайл" if name in ("brick", "roof") else "отдельный спрайт", font=font(17), fill="#667064")
    return image


def balcony_review_sheet(exterior: Image.Image, parts: dict[str, Image.Image]) -> Image.Image:
    panel_width = (SIZE[0] + 32) * 2
    right = panel_width + 48
    image = Image.new("RGB", (panel_width + 432, 804), "#f0ede4")
    draw = ImageDraw.Draw(image)
    draw.text((16, 16), "Широкий фасад · по три окна с каждой стороны", font=font(25), fill="#343c37")
    draw.text((16, 58), "Фасад целиком · ×2", font=font(20), fill="#343c37")
    panel = preview_panel(exterior, False)
    image.paste(panel.resize((panel_width, 656), Image.Resampling.NEAREST), (16, 94))
    draw.text((right, 58), "Одна створка и одна ручка · ×6", font=font(19), fill="#343c37")
    draw.rectangle((right, 94, right + 367, 339), fill="#dad9cd")
    section = Image.new("RGBA", (40, 41))
    door = parts["balcony_door"]
    section.alpha_composite(door, (20 - door.width // 2, 32 - door.height))
    section.alpha_composite(parts["balcony"], (0, 23))
    enlarged = section.resize((240, 246), Image.Resampling.NEAREST)
    image.paste(enlarged, (right + 64, 94), enlarged)
    draw.text((right, 356), "Два этажа крупнее · ×4", font=font(20), fill="#343c37")
    detail = exterior.crop((HALF_WIDTH - 30, 99, HALF_WIDTH + 30, 181))
    image.paste(detail.resize((240, 328), Image.Resampling.NEAREST), (right + 64, 398))
    draw.text((16, 770), "Макет графики. Освещение и прозрачность проверяются в Godot.", font=font(18), fill="#667064")
    return image


def review_sheet(exterior: Image.Image) -> Image.Image:
    panel_height = (SIZE[1] + 31) * 2
    panel_width = (SIZE[0] + 32) * 2
    right = panel_width + 32
    image = Image.new("RGB", (panel_width * 2 + 48, panel_height + 166), "#f0ede4")
    draw = ImageDraw.Draw(image)
    draw.text((16, 16), "Подъезд · пять этажей · фасад из отдельных спрайтов", font=font(24), fill="#343c37")
    draw.text((16, 60), "Снаружи", font=font(20), fill="#343c37")
    draw.text((right, 60), "Внутри: тёмный объём дома", font=font(20), fill="#343c37")
    for inside, x in ((False, 16), (True, right)):
        panel = preview_panel(exterior, inside)
        image.paste(panel.resize((panel_width, panel_height), Image.Resampling.NEAREST), (x, 94))
    draw.text((16, panel_height + 108), f"{SIZE[0]}×{SIZE[1]} пикселей · 5 рядов по 6 окон · увеличение ×2 без сглаживания", font=font(17), fill="#667064")
    draw.text((16, panel_height + 136), "Макет графики. Освещение и переход фасада проверяются в Godot.", font=font(17), fill="#667064")
    return image


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--preview-dir", type=Path)
    parser.add_argument("--preview-only", action="store_true", help="Generate review PNGs without overwriting project textures")
    parser.add_argument("--only", choices=("brick", "roof", "window", "balcony", "balcony_door"), help="Write only the selected PNG; read other review components from disk")
    args = parser.parse_args()
    if args.preview_only and args.preview_dir is None:
        parser.error("--preview-only requires --preview-dir")
    if args.preview_dir and args.preview_dir.resolve().is_relative_to(SPRITES):
        parser.error("Keep review images outside assets/sprites")
    generators = {"brick": brick, "roof": roof, "window": window, "balcony": balcony, "balcony_door": balcony_door}
    parts = {
        name: generate()
        for name, generate in generators.items()
        if args.only is None or args.only == name
    }
    if not args.preview_only:
        OUTPUT.mkdir(parents=True, exist_ok=True)
        for name, part in parts.items():
            path = OUTPUT / f"{name}.png"
            part.save(path)
            print(f"{path}: {part.width}x{part.height} RGBA")
    if args.preview_dir:
        args.preview_dir.mkdir(parents=True, exist_ok=True)
        if args.preview_only:
            for name, part in parts.items():
                part.save(args.preview_dir / f"{name}.png")
        for name in generators:
            if name not in parts:
                parts[name] = sprite(f"home_entrance/{name}.png")
        exterior = assemble_facade(parts)
        for name, source in (("facade", exterior), ("cutaway", cutaway_mockup(exterior))):
            source.resize((SIZE[0] * 4, SIZE[1] * 4), Image.Resampling.NEAREST).save(args.preview_dir / f"{name}-x4.png")
        components_sheet(parts).save(args.preview_dir / "components.png")
        balcony_review_sheet(exterior, parts).save(args.preview_dir / "balcony-review.png")
        review_sheet(exterior).save(args.preview_dir / "comparison.png")
        print(args.preview_dir / "components.png")
        print(args.preview_dir / "comparison.png")
        print(args.preview_dir / "balcony-review.png")


if __name__ == "__main__":
    main()
