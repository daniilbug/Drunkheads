#!/usr/bin/env python3
"""Recreate the home toilet pixel art in the shared porcelain palette."""

import argparse
from pathlib import Path

from PIL import Image

from home_plumbing_palette import (
    BRIGHT_GRAY,
    EDGE,
    GRAY,
    LIGHT_GRAY,
    MID_GRAY,
    PORCELAIN,
    WHITE,
)


OUTPUT = Path(__file__).resolve().parents[1] / "assets/sprites/home/toilet.png"

# The existing 20x24 side-view silhouette, including the cistern, bowl and base.
ART = (
    "0000AAAA000000000000",
    "00333223330000000000",
    "003FFFFFF30000000000",
    "003FFFFFF30000000000",
    "003DDDDDD30000000000",
    "003DDDDDD30000000000",
    "003DDDDDD30000000000",
    "003DDDDDD30000000000",
    "003DDDDDD30000000000",
    "003DDDDDD30000000000",
    "00399999930000000000",
    "00399998888000000000",
    "00399998EFFFFFFFF000",
    "00333338EEEEEEEEEF00",
    "00000008EEEEEEEEEEF4",
    "000000084E77777777E4",
    "000000004E77777777E4",
    "000000004EEE7777EEE4",
    "0000000004EEEEEEE440",
    "000000000046CCC64400",
    "000000000006CCC64000",
    "000000000006CCC60000",
    "0000000005BBBBBBB500",
    "00000000055555555500",
)

COLORS = {
    "0": (0, 0, 0, 0),
    "2": MID_GRAY,
    "3": EDGE,
    "4": EDGE,
    "5": MID_GRAY,
    "6": GRAY,
    "7": BRIGHT_GRAY,
    "8": GRAY,
    "9": BRIGHT_GRAY,
    "A": BRIGHT_GRAY,
    "B": LIGHT_GRAY,
    "C": LIGHT_GRAY,
    "D": PORCELAIN,
    "E": PORCELAIN,
    "F": WHITE,
}


def make_sprite() -> Image.Image:
    image = Image.new("RGBA", (20, 24), (0, 0, 0, 0))
    for y, row in enumerate(ART):
        if len(row) != image.width:
            raise ValueError(f"Toilet row {y} is not {image.width} pixels wide")
        for x, color in enumerate(row):
            image.putpixel((x, y), COLORS[color])
    return image


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--preview", type=Path, help="Save an enlarged nearest-neighbor preview")
    args = parser.parse_args()

    sprite = make_sprite()
    sprite.save(OUTPUT)
    print(OUTPUT)
    if args.preview:
        args.preview.parent.mkdir(parents=True, exist_ok=True)
        sprite.resize((sprite.width * 12, sprite.height * 12), Image.Resampling.NEAREST).save(args.preview)
        print(args.preview)


if __name__ == "__main__":
    main()
