#!/usr/bin/env python3
"""Draw a 4 x 10 transparent headphone overlay for the player atlas."""

from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "assets" / "sprites" / "characters" / "headphones.png"


def main() -> None:
    atlas = Image.new("RGBA", (48, 200), (0, 0, 0, 0))
    draw = ImageDraw.Draw(atlas)
    white = (244, 243, 231, 255)
    shadow = (155, 165, 169, 255)
    for row in range(10):
        for col in range(4):
            x, y = col * 12, row * 20
            if row == 2:  # Facing left: the ear is behind the face, on the right.
                ears = (9,)
            elif row == 3:
                ears = (2,)
            else:
                ears = (2, 9)
            for ear in ears:
                draw.line((x + ear, y + 2, x + ear, y + 4), fill=shadow)
                draw.point((x + ear, y + 2), fill=white)
                draw.point((x + ear, y + 3), fill=white)
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    atlas.save(OUTPUT)
    print(OUTPUT)


if __name__ == "__main__":
    main()
