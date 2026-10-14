#!/usr/bin/env python3
"""Generate a small open metal bin for the home kitchen."""

import argparse
from pathlib import Path

from PIL import Image, ImageDraw


SPRITES = Path(__file__).resolve().parents[1] / "assets/sprites/home"


def make_trash() -> Image.Image:
    image = Image.new("RGBA", (7, 9))
    draw = ImageDraw.Draw(image)
    outline = "#405760"
    metal = "#5a727a"
    light = "#8ba0a2"

    # Slightly tapered body, with a restrained highlight on the left face.
    draw.rectangle((1, 2, 5, 7), fill=outline)
    draw.rectangle((2, 3, 4, 7), fill=metal)
    draw.line((2, 4, 2, 6), fill=light)
    draw.line((2, 8, 4, 8), fill=outline)

    # Visible open mouth viewed from above; the front lip overlaps the body.
    draw.line((1, 0, 5, 0), fill=outline)
    draw.line((1, 1, 5, 1), fill=light)
    draw.line((0, 2, 6, 2), fill=outline)
    draw.line((2, 2, 4, 2), fill="#293b43")
    draw.line((1, 3, 5, 3), fill=light)
    return image


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--preview", type=Path)
    args = parser.parse_args()
    sprite = make_trash()
    output = SPRITES / "trash.png"
    sprite.save(output)
    print(output)

    if args.preview:
        # Show transparent silhouette and the same sprite on the home floor.
        preview = Image.new("RGBA", (44, 24), "#53585f")
        draw = ImageDraw.Draw(preview)
        for y in range(0, 24, 4):
            for x in range(0, 20, 4):
                if (x // 4 + y // 4) % 2:
                    draw.rectangle((x, y, x + 3, y + 3), fill="#5d6269")
        floor = Image.open(SPRITES / "floor.png").convert("RGBA")
        preview.alpha_composite(floor.crop((0, 0, 20, 24)), (24, 0))
        preview.alpha_composite(sprite, (6, 7))
        preview.alpha_composite(sprite, (30, 7))
        args.preview.parent.mkdir(parents=True, exist_ok=True)
        preview.resize((440, 240), Image.Resampling.NEAREST).save(args.preview)
        print(args.preview)


if __name__ == "__main__":
    main()
