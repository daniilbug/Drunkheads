#!/usr/bin/env python3
"""Generate separate floor, upper and side railing, and door sprites for the balcony."""

import argparse
from pathlib import Path

from PIL import Image, ImageDraw

from gen_home_window import draw_glass
from home_furniture_palette import HANDLE, WOOD


OUTPUT_DIR = Path(__file__).resolve().parents[1] / "assets/sprites/home"


def make_floor() -> Image.Image:
    """A repeating 32x32 outdoor wood floor, matching the home's warm floor."""
    image = Image.new("RGBA", (32, 32), "#c6a27a")
    draw = ImageDraw.Draw(image)
    colors = ("#c6a27a", "#c9a67e", "#c3a078", "#c8a47c")
    for row, y in enumerate(range(0, 32, 8)):
        draw.rectangle((0, y, 31, y + 7), fill=colors[row])
        draw.line((0, y, 31, y), fill="#d1b08b")
        draw.line((0, y + 7, 31, y + 7), fill="#ae8965")
        seams = (16,) if row % 2 == 0 else (8, 24)
        for x in seams:
            draw.line((x, y + 1, x, y + 6), fill="#ae8965")
            draw.line((x + 1, y + 1, x + 1, y + 6), fill="#cfac86")
    for x, y in ((3, 3), (22, 5), (12, 11), (28, 13), (5, 20), (19, 21), (27, 29)):
        draw.line((x, y, x + 2, y), fill="#b8936e")
    return image


def make_railing() -> Image.Image:
    """A repeating 16x16 horizontal rail section."""
    image = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    dark = "#405760"
    metal = "#5a727a"
    light = "#8ba0a2"
    draw.rectangle((0, 1, 15, 4), fill=dark)
    draw.line((0, 1, 15, 1), fill=light)
    draw.line((0, 3, 15, 3), fill=metal)
    for x in (3, 11):
        draw.rectangle((x, 4, x + 2, 12), fill=dark)
        draw.line((x + 1, 4, x + 1, 11), fill=light)
        draw.rectangle((x - 1, 11, x + 3, 13), fill=metal)
        draw.point((x, 11), fill=light)
    draw.rectangle((0, 13, 15, 14), fill=dark)
    draw.line((0, 13, 15, 13), fill=metal)
    return image


def make_side_railing() -> Image.Image:
    """A narrow 4x32 vertical rail that joins the horizontal rail."""
    image = Image.new("RGBA", (4, 32), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    draw.line((0, 0, 0, 31), fill="#405760")
    draw.line((1, 0, 1, 31), fill="#5a727a")
    draw.line((2, 0, 2, 31), fill="#8ba0a2")
    draw.line((3, 0, 3, 31), fill="#405760")
    return image


def draw_door_panel(draw: ImageDraw.ImageDraw, x: int) -> None:
    draw.rectangle((x, 0, x + 14, 27), fill=WOOD)
    draw_glass(draw, (x + 3, 4, 9, 12))
    draw_glass(draw, (x + 3, 19, 9, 5))
    draw.point((x + 12, 18), fill=HANDLE)


def make_door() -> Image.Image:
    """Two 32x28 frames, as used by scenes/core/door.tscn."""
    image = Image.new("RGBA", (64, 28), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    draw_door_panel(draw, 8)   # Closed: covers the 14-pixel passage.
    draw_door_panel(draw, 48)  # Open: panel moves to the right.
    return image


def save_preview(image: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    image.resize((image.width * 8, image.height * 8), Image.Resampling.NEAREST).save(path)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--preview-dir", type=Path, help="Save 8x previews of each sprite")
    args = parser.parse_args()

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    sprites = {
        "balcony_floor.png": make_floor(),
        "balcony_railing.png": make_railing(),
        "balcony_side_railing.png": make_side_railing(),
        "balcony_door.png": make_door(),
    }
    for name, image in sprites.items():
        output = OUTPUT_DIR / name
        image.save(output)
        print(output)
        if args.preview_dir:
            save_preview(image, args.preview_dir / name)


if __name__ == "__main__":
    main()
