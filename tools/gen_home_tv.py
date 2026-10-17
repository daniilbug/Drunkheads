#!/usr/bin/env python3
"""Generate the north-facing home TV on a wide wooden cabinet and its light mask."""

import argparse
from pathlib import Path

from PIL import Image, ImageDraw


OUTPUT = Path(__file__).resolve().parents[1] / "assets/sprites/home"


def generate_tv() -> Image.Image:
    image = Image.new("RGBA", (48, 34), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    outline = "#252c32"
    dark = "#343e46"
    casing = "#424e56"
    highlight = "#65737a"

    # The cabinet faces the sofa too: the viewer sees a plain wooden back.
    wood_outline, wood = "#4d3428", "#76533a"
    draw.rectangle((3, 31, 44, 33), fill=(34, 26, 24, 48))
    draw.rectangle((5, 30, 8, 33), fill=wood_outline)
    draw.rectangle((39, 30, 42, 33), fill=wood_outline)
    draw.rectangle((2, 20, 45, 31), fill=wood_outline)
    draw.rectangle((3, 21, 44, 30), fill=wood)

    # The smaller set keeps the original casing and rear-panel details.
    draw.rectangle((16, 16, 17, 21), fill=outline)
    draw.rectangle((30, 16, 31, 21), fill=outline)
    draw.line((14, 22, 18, 22), fill=dark)
    draw.line((29, 22, 33, 22), fill=dark)
    draw.rectangle((10, 1, 37, 16), fill=outline)
    draw.rectangle((11, 2, 36, 14), fill=casing)
    draw.line((12, 2, 35, 2), fill=highlight)
    draw.line((11, 3, 11, 13), fill="#536068")
    draw.rectangle((13, 5, 34, 13), fill=dark)
    draw.line((14, 5, 33, 5), fill="#4d5961")
    # Ventilation slots, screws, an inset label and rear connectors.
    for x in range(16, 33, 3):
        draw.line((x, 6, x, 8), fill=outline)
    for point in ((12, 4), (35, 4), (12, 13), (35, 13)):
        draw.point(point, fill=outline)
    draw.rectangle((19, 10, 24, 12), fill="#788180")
    draw.line((20, 11, 23, 11), fill="#4d5961")
    draw.rectangle((28, 10, 32, 12), fill=outline)
    draw.point((29, 11), fill="#a3907a")
    draw.point((31, 11), fill="#637c85")
    draw.line((34, 14, 34, 18, 39, 19, 39, 21), fill=outline)
    return image


def generate_light() -> Image.Image:
    # Wide at the far end (top), narrow at the screen (bottom).
    # No pixels behind the screen: this is a finite forward beam.
    image = Image.new("RGBA", (80, 48), (0, 0, 0, 0))
    for y in range(image.height):
        distance = (image.height - 1 - y) / (image.height - 1)
        half_width = 14.0 + distance * 25.0
        fade = (1.0 - distance) ** 0.7
        for x in range(image.width):
            edge = min(1.0, max(0.0, (half_width - abs(x - 39.5)) / 5.0))
            intensity = round(255 * fade * edge)
            image.putpixel((x, y), (intensity, intensity, intensity, 255))
    return image


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--preview", type=Path, help="Save an 8x nearest-neighbor TV preview")
    args = parser.parse_args()
    tv = generate_tv()
    OUTPUT.mkdir(parents=True, exist_ok=True)
    tv.save(OUTPUT / "tv.png")
    generate_light().save(OUTPUT / "tv_light.png")
    if args.preview:
        args.preview.parent.mkdir(parents=True, exist_ok=True)
        tv.resize((tv.width * 8, tv.height * 8), Image.Resampling.NEAREST).save(args.preview)


if __name__ == "__main__":
    main()
