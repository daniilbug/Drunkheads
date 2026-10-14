#!/usr/bin/env python3
"""Generate the home toilet mirror glass and porcelain-colored frame."""

from pathlib import Path

from PIL import Image

from home_plumbing_palette import EDGE, GRAY, LIGHT_GRAY, MID_GRAY, WHITE


OUTPUT = Path(__file__).resolve().parents[1] / "assets/sprites/home"
SIZE = (13, 15)
TRANSPARENT = (0, 0, 0, 0)


def main() -> None:
    glass = Image.new("RGBA", SIZE, GRAY)
    frame = Image.new("RGBA", SIZE, TRANSPARENT)

    for x in range(SIZE[0]):
        frame.putpixel((x, 0), LIGHT_GRAY)
        frame.putpixel((x, SIZE[1] - 1), MID_GRAY)
    for y in range(1, SIZE[1] - 1):
        frame.putpixel((0, y), WHITE)
        frame.putpixel((SIZE[0] - 1, y), EDGE)
    frame.putpixel((0, 0), WHITE)
    frame.putpixel((SIZE[0] - 1, SIZE[1] - 1), EDGE)

    glass.save(OUTPUT / "toilet_mirror_glass.png")
    frame.save(OUTPUT / "toilet_mirror_frame.png")


if __name__ == "__main__":
    main()
