#!/usr/bin/env python3
"""Generate a south-facing, two-seat sofa sprite for the home."""

import argparse
from pathlib import Path

from PIL import Image, ImageDraw


OUTPUT = Path(__file__).resolve().parents[1] / "assets/sprites/home/sofa.png"


def generate() -> Image.Image:
    width = 44
    middle = width // 2
    image = Image.new("RGBA", (width, 18), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)

    outline = "#526a73"
    upholstery_dark = "#5b747d"
    upholstery = "#637c85"
    upholstery_light = "#6c858e"
    cushion = upholstery
    seam = outline
    feet = "#475f68"

    # Shadow and short feet sit below the front edge.
    draw.rectangle((3, 15, width - 4, 17), fill=(34, 26, 24, 48))
    draw.rectangle((4, 15, 7, 16), fill=feet)
    draw.rectangle((width - 8, 15, width - 5, 16), fill=feet)

    # Backrest is at the top, so seated characters face down.
    draw.rectangle((2, 1, width - 3, 7), fill=outline)
    draw.rectangle((3, 2, width - 4, 6), fill=upholstery_dark)
    draw.line((4, 2, width - 5, 2), fill=upholstery_light)
    draw.line((4, 5, width - 5, 5), fill=upholstery)

    # Two separate cushions, divided by a narrow central seam.
    draw.rectangle((1, 6, width - 2, 15), fill=outline)
    draw.rectangle((3, 8, middle - 2, 13), fill=cushion)
    draw.rectangle((middle + 1, 8, width - 4, 13), fill=cushion)
    draw.line((3, 8, middle - 2, 8), fill=upholstery_light)
    draw.line((middle + 1, 8, width - 4, 8), fill=upholstery_light)
    draw.line((3, 13, middle - 2, 13), fill=upholstery_dark)
    draw.line((middle + 1, 13, width - 4, 13), fill=upholstery_dark)
    draw.rectangle((middle - 1, 8, middle, 13), fill=seam)

    # A continuous front edge leaves the two seats unobstructed.
    draw.rectangle((2, 14, width - 3, 15), fill=upholstery_dark)
    draw.line((3, 14, width - 4, 14), fill=upholstery)
    return image


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--preview", type=Path, help="Save an 8x nearest-neighbor preview")
    args = parser.parse_args()

    image = generate()
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    image.save(OUTPUT)
    if args.preview:
        args.preview.parent.mkdir(parents=True, exist_ok=True)
        image.resize((image.width * 8, image.height * 8), Image.Resampling.NEAREST).save(args.preview)
    print(OUTPUT)


if __name__ == "__main__":
    main()
