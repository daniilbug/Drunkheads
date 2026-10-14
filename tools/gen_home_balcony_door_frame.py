#!/usr/bin/env python3
"""Generate a balcony door outline, visible only while the door is open."""

import argparse
from pathlib import Path

from PIL import Image, ImageDraw


SPRITES = Path(__file__).resolve().parents[1] / "assets/sprites/home"
# Relative to BalconyDoor; the existing panel occupies (-7, -30)..(7, -3).
FRAME_POSITION = (-7, -30)


def make_frame() -> Image.Image:
    """One-pixel frame matching the closed panel's exact 15x28 outline."""
    image = Image.new("RGBA", (15, 28))
    draw = ImageDraw.Draw(image)
    draw.rectangle((0, 0, 14, 27), outline="#604738")
    return image


def make_mockup(frame: Image.Image, opened: bool) -> Image.Image:
    """Unlit sprite composition at existing scene coordinates, not a game capture."""
    size = (64, 56)
    world_origin = (40, -40)
    floor = Image.open(SPRITES / "floor.png").convert("RGBA")
    wall = Image.open(SPRITES / "wall.png").convert("RGBA")
    image = Image.new("RGBA", size)
    for y in range(size[1]):
        for x in range(size[0]):
            wx, wy = x + world_origin[0], y + world_origin[1]
            # Match the wall shader's 14x27 opening at house (63, -27).
            in_wall = wy < 0 and not (63 <= wx < 77 and -27 <= wy < 0)
            tile = wall if in_wall else floor
            ty = wy + 60 if in_wall else wy
            image.putpixel((x, y), tile.getpixel((wx % tile.width, ty % tile.height)))

    door_origin = (70 - world_origin[0], 2 - world_origin[1])
    if opened:
        image.alpha_composite(frame, (door_origin[0] + FRAME_POSITION[0],
                                      door_origin[1] + FRAME_POSITION[1]))
    sheet = Image.open(SPRITES / "balcony_door.png").convert("RGBA")
    panel = sheet.crop((32, 0, 64, 28) if opened else (0, 0, 32, 28))
    image.alpha_composite(panel, (door_origin[0] + (-9 if opened else -15),
                                  door_origin[1] - 30))
    return image


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--preview-dir", type=Path)
    args = parser.parse_args()
    frame = make_frame()
    output = SPRITES / "balcony_door_frame.png"
    frame.save(output)
    print(output)
    if args.preview_dir:
        args.preview_dir.mkdir(parents=True, exist_ok=True)
        preview = Image.new("RGB", (804, 380), "#25272c")
        draw = ImageDraw.Draw(preview)
        for index, opened in enumerate((False, True)):
            x = 12 + index * 396
            draw.text((x, 10), "OPEN" if opened else "CLOSED", fill="#eeeeee")
            mockup = make_mockup(frame, opened).resize((384, 336), Image.Resampling.NEAREST)
            preview.paste(mockup, (x, 30))
        path = args.preview_dir / "balcony_door_frame_preview.png"
        preview.save(path)
        print(path)


if __name__ == "__main__":
    main()
