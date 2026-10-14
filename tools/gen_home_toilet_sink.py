#!/usr/bin/env python3
"""Recolor the WC sink silhouette for the home's white-and-gray toilet."""

import argparse
from pathlib import Path

from PIL import Image

from home_plumbing_palette import BRIGHT_GRAY, EDGE, GRAY, LIGHT_GRAY, MID_GRAY, WHITE


SPRITES = Path(__file__).resolve().parents[1] / "assets/sprites"
SOURCE = SPRITES / "wc/sink.png"
OUTPUT = SPRITES / "home/toilet_sink.png"

# Keep the six-frame animation and water intact; recolor only the fixture.
FIXTURE_COLORS = {
    (130, 130, 130, 255): EDGE,
    (253, 253, 253, 255): WHITE,
    (205, 205, 205, 255): GRAY,
    (237, 237, 237, 255): LIGHT_GRAY,
    (138, 138, 138, 255): MID_GRAY,
    (188, 80, 80, 255): MID_GRAY,
    (134, 148, 187, 255): BRIGHT_GRAY,
}
WATER_COLORS = {
    (146, 167, 225, 255),
    (158, 177, 228, 255),
    (182, 197, 234, 255),
}


def make_sheet() -> Image.Image:
    source = Image.open(SOURCE).convert("RGBA")
    if source.size != (78, 13):
        raise ValueError("The WC sink must have six 13x13 frames")
    result = Image.new("RGBA", source.size)
    for y in range(source.height):
        for x in range(source.width):
            color = source.getpixel((x, y))
            if color[3] == 0 or color in WATER_COLORS:
                result.putpixel((x, y), color)
            elif color in FIXTURE_COLORS:
                result.putpixel((x, y), FIXTURE_COLORS[color])
            else:
                raise ValueError(f"Unexpected WC sink color: {color}")
    return result


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--preview", type=Path, help="Save an enlarged six-frame preview")
    args = parser.parse_args()

    sheet = make_sheet()
    sheet.save(OUTPUT)
    print(OUTPUT)
    if args.preview:
        args.preview.parent.mkdir(parents=True, exist_ok=True)
        sheet.resize((sheet.width * 12, sheet.height * 12), Image.Resampling.NEAREST).save(args.preview)
        print(args.preview)


if __name__ == "__main__":
    main()
