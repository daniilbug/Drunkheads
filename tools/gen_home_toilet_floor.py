#!/usr/bin/env python3
"""Generate 8px porcelain-stoneware tiles for the home bathroom."""

import argparse
from pathlib import Path
import random

from PIL import Image, ImageDraw


SPRITES = Path(__file__).resolve().parents[1] / "assets/sprites/home"
SLAB_SIZE = 8  # Match the 8×8 squares of kitchen_floor.png.
TEXTURE_SIZE = 64


def make_slab(seed: int) -> Image.Image:
    """A warm-grey tile with one-pixel grout and restrained mineral grain."""
    image = Image.new("RGB", (SLAB_SIZE, SLAB_SIZE), "#d3cfc3")
    pixels = image.load()
    rng = random.Random(seed)

    # Small color shifts suggest stone without turning the 8px tile into noise.
    patches = [[rng.randrange(-5, 6) for _ in range(3)] for _ in range(3)]
    for y in range(1, SLAB_SIZE):
        for x in range(1, SLAB_SIZE):
            gx, gy = x / 4, y / 4
            ix, iy = min(int(gx), 1), min(int(gy), 1)
            fx, fy = gx - ix, gy - iy
            shade = (
                patches[iy][ix] * (1 - fx) * (1 - fy)
                + patches[iy][ix + 1] * fx * (1 - fy)
                + patches[iy + 1][ix] * (1 - fx) * fy
                + patches[iy + 1][ix + 1] * fx * fy
            )
            grain = rng.choice((-2, -1, 0, 0, 0, 1, 2))
            tint = round(shade + grain)
            pixels[x, y] = (211 + tint, 207 + tint, 195 + tint)

    draw = ImageDraw.Draw(image)
    # Occasional two-pixel mineral marks distinguish tiles without a repeated motif.
    if rng.randrange(3) == 0:
        x, y = rng.randrange(2, 6), rng.randrange(2, 7)
        draw.line((x, y, x + 1, y), fill="#c6c2b7")
    if rng.randrange(2) == 0:
        draw.point((rng.randrange(2, 7), rng.randrange(2, 7)), fill="#dedacd")

    # Adjacent slabs share a single narrow grout line.
    draw.line((0, 0, SLAB_SIZE - 1, 0), fill="#b8b3a8")
    draw.line((0, 0, 0, SLAB_SIZE - 1), fill="#b8b3a8")
    draw.point((0, 0), fill="#a9a49a")
    return image


def make_floor() -> Image.Image:
    """An 8×8 set of varied tiles in a seamless repeating 64px texture."""
    image = Image.new("RGB", (TEXTURE_SIZE, TEXTURE_SIZE))
    for row in range(TEXTURE_SIZE // SLAB_SIZE):
        for column in range(TEXTURE_SIZE // SLAB_SIZE):
            image.paste(make_slab(41027 + row * 17 + column * 53),
                        (column * SLAB_SIZE, row * SLAB_SIZE))
    return image


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--preview", type=Path, help="Save a tiled bathroom-size preview")
    args = parser.parse_args()

    floor = make_floor()
    output = SPRITES / "toilet_floor.png"
    floor.save(output)
    print(output)

    if args.preview:
        preview = Image.new("RGB", (40, 80))
        for y in range(0, preview.height, TEXTURE_SIZE):
            for x in range(0, preview.width, TEXTURE_SIZE):
                preview.paste(floor, (x, y))
        args.preview.parent.mkdir(parents=True, exist_ok=True)
        preview.resize((400, 800), Image.Resampling.NEAREST).save(args.preview)
        print(args.preview)


if __name__ == "__main__":
    main()
