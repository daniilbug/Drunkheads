#!/usr/bin/env python3
"""Generate the bus body and stop sign; leave all existing artwork untouched.

The right-facing bus uses the existing 11x11 car wheel frames, placed at
(20, 41) and (75, 41). Its scene origin is (56, 46) in this 112x48 canvas.
Destination icons are separate Sprite2D nodes using the taxi app textures;
their transform is configured in scenes/street/bus_destination_icon.tscn.
The stop sign's foot is (7, 31) in its 14x32 canvas.
"""

import argparse
from pathlib import Path

from PIL import Image, ImageDraw


OUTPUT = Path(__file__).resolve().parents[1] / "assets/sprites/street"
BUS_SIZE = (112, 48)
STOP_SIZE = (14, 32)
WHEEL_CENTERS = ((20, 41), (75, 41))

# One body paint color; the remaining colors belong to glass and hardware.
OUTLINE = "#3f3939"
BODY_PAINT = "#9aa785"
BODY_SHADE = "#798360"
GLASS_DARK = "#354e61"
GLASS = "#7191a0"
METAL = "#6b787d"
TIRE = "#17272e"


def generate_bus_body() -> Image.Image:
    image = Image.new("RGBA", BUS_SIZE, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)

    # Keep the old, squared silhouette with a single flat coat of paint.
    draw.polygon(
        [(4, 9), (7, 6), (103, 6), (107, 9), (108, 13),
         (108, 38), (106, 41), (6, 41), (3, 38), (3, 13)],
        fill=BODY_PAINT,
    )
    # The only body shading is a thin lower edge above the chassis.
    draw.line((6, 38, 106, 38), fill=BODY_SHADE)
    draw.rectangle((6, 39, 106, 41), fill=TIRE)

    # Flat glass rectangles: no vents, reflections, highlights or extra frames.
    for left in (25, 43, 61):
        draw.rectangle((left, 13, left + 14, 27), fill=GLASS)

    # A separate sprite draws the taxi app's original glyph on the body paint.

    # Folding doors retain just their glass and seams in the same body color.
    for x in (81, 89, 97):
        draw.line((x, 13, x, 37), fill=BODY_SHADE)
    for left, right in ((82, 88), (90, 96)):
        draw.rectangle((left, 13, right, 27), fill=GLASS)
    draw.rectangle((100, 13, 105, 27), fill=GLASS)

    # Cutouts expose the existing wheels, which remain independent animations.
    for center, _ in WHEEL_CENTERS:
        draw.rectangle((center - 5, 35, center + 5, 41), fill=TIRE)
        draw.rectangle((center - 3, 35, center + 3, 47), fill=(0, 0, 0, 0))
        draw.rectangle((center - 4, 36, center + 4, 47), fill=(0, 0, 0, 0))

    # Front and rear lights deliberately distinguish the travel direction.
    draw.rectangle((4, 30, 6, 32), fill="#c36555")
    draw.rectangle((104, 30, 107, 32), fill="#f1d294")
    draw.rectangle((3, 36, 6, 37), fill=METAL)
    draw.rectangle((105, 36, 109, 37), fill=METAL)
    return image


def generate_stop_sign() -> Image.Image:
    image = Image.new("RGBA", STOP_SIZE, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)

    # Every horizontal span is centered on the 14px canvas, including the post.
    # Flat fills preserve exact left/right symmetry, also in the metalwork.
    draw.rectangle((6, 16, 7, 29), fill=METAL)
    draw.rectangle((4, 30, 9, 31), fill=OUTLINE)

    # Blue roadside sign with an inset cream field and a front-view bus glyph.
    draw.rectangle((1, 1, 12, 16), fill=OUTLINE)
    draw.rectangle((2, 2, 11, 15), fill="#42758e")
    draw.rectangle((3, 3, 10, 14), fill="#ede0b9")
    draw.rectangle((4, 4, 9, 12), fill=GLASS_DARK)
    draw.rectangle((5, 5, 8, 8), fill="#ede0b9")
    draw.point((5, 10), fill="#ede0b9")
    draw.point((8, 10), fill="#ede0b9")
    draw.point((4, 13), fill=GLASS_DARK)
    draw.point((9, 13), fill=GLASS_DARK)
    return image


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output-dir", type=Path, default=OUTPUT)
    args = parser.parse_args()
    args.output_dir.mkdir(parents=True, exist_ok=True)
    for filename, image in (
        ("bus_body.png", generate_bus_body()),
        ("bus_stop_sign.png", generate_stop_sign()),
    ):
        path = args.output_dir / filename
        image.save(path)
        print(f"{path}: {image.width}x{image.height}, RGBA")


if __name__ == "__main__":
    main()
