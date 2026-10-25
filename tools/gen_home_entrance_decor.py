#!/usr/bin/env python3
"""Reproduce the four approved courtyard sprites at their native pixel sizes.

Only swing.png, sandbox.png, fence.png and earth.png are written. Existing
cafe greenery, benches and street lanterns are reused directly by scenes.
Draw material surfaces and structural bars without a separate perimeter stroke.
"""

import argparse
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageColor


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / 'assets/sprites/home_entrance'
METAL = '#925d4c'
METAL_HI = '#ba8164'
WOOD = '#ae9158'
WOOD_HI = '#ccb07a'
STEEL = '#9ca591'


def frontal_swing() -> Image.Image:
    """48x36 frontal swing, with straight posts and two ten-pixel seats."""
    half = Image.new('RGBA', (24, 36))
    draw = ImageDraw.Draw(half)
    draw.rectangle((2, 4, 5, 35), fill=METAL)
    draw.line((3, 5, 3, 34), fill=METAL_HI)
    for y in [14, 26]:
        draw.point((3, y), fill=WOOD_HI)
    draw.rectangle((1, 2, 23, 4), fill=METAL)
    draw.line((2, 2, 23, 2), fill=METAL_HI)
    for x in [13, 20]:
        draw.line((x, 5, x, 25), fill='#77796e')
        for y in range(6, 25, 3):
            draw.point((x, y), fill=STEEL)
    draw.rectangle((12, 26, 21, 28), fill=WOOD)
    draw.line((12, 26, 21, 26), fill=WOOD_HI)
    image = Image.new('RGBA', (48, 36))
    image.alpha_composite(half)
    image.alpha_composite(half.transpose(Image.Transpose.FLIP_LEFT_RIGHT), (24, 0))
    return image


def side_sandbox() -> Image.Image:
    """35x18 native side-view sandbox, with a small castle and spade."""
    image = Image.new('RGBA', (35, 18))
    draw = ImageDraw.Draw(image)
    # Shallow top and broad front board retain the side view.
    draw.rectangle((1, 10, 33, 13), fill=WOOD)
    draw.line((2, 10, 32, 10), fill=WOOD_HI)
    draw.rectangle((3, 11, 31, 12), fill='#c4b482')
    for x, y in [(5, 11), (8, 12), (15, 11), (17, 12), (28, 11), (30, 12)]:
        draw.point((x, y), fill='#dbc798')
    # Single-pixel crenellations and doorway.
    dark = '#a38b57'
    sand = '#cbb37c'
    light = '#e0cb91'
    draw.rectangle((19, 9, 21, 12), fill=dark)
    draw.rectangle((23, 9, 25, 12), fill=dark)
    draw.rectangle((21, 10, 23, 12), fill=dark)
    draw.line((20, 9, 20, 11), fill=sand)
    draw.line((24, 9, 24, 11), fill=sand)
    draw.line((21, 11, 23, 11), fill=sand)
    for x in [19, 21, 23, 25]:
        draw.point((x, 8), fill=light)
    draw.line((21, 10, 23, 10), fill=light)
    draw.line((18, 12, 26, 12), fill='#b39d6a')
    draw.point((22, 12), fill='#897548')
    draw.line((9, 11, 11, 11), fill='#8b7047')
    draw.rectangle((12, 11, 13, 12), fill=STEEL)
    draw.rectangle((0, 13, 34, 16), fill='#9b7b48')
    draw.line((0, 13, 34, 13), fill=WOOD_HI)
    draw.line((0, 16, 34, 16), fill='#856b43')
    for x in [11, 24]:
        draw.line((x, 14, x, 15), fill='#8c7145')
    return image


def fence() -> Image.Image:
    """38x20 section with identical posts; three copies share posts at 35px steps."""
    image = Image.new('RGBA', (38, 20))
    draw = ImageDraw.Draw(image)
    steel, shadow = '#54514c', '#4c4944'
    for x in (9, 18, 27):
        draw.rectangle((x, 4, x + 1, 16), fill=steel)
    for y in (3, 15):
        draw.rectangle((3, y, 34, y + 1), fill=steel)
    for x in (0, 35):
        draw.rectangle((x, 0, x + 2, 19), fill=steel)
        draw.line((x + 2, 0, x + 2, 19), fill=shadow)
    return image


def earth_tile() -> Image.Image:
    """32x32 fully grass-covered tile; all clusters wrap at edges."""
    tile = Image.new('RGBA', (32, 32), '#856347')
    rng = random.Random(281)
    colors = ['#76583f', '#926f51', '#a17e5c']
    shapes = [[(0, 0)], [(0, 0), (1, 0)], [(0, 0), (1, 0), (1, 1)], [(0, 0), (1, 0), (2, 0)]]
    for _ in range(44):
        x, y = (rng.randrange(32), rng.randrange(32))
        color = colors[rng.randrange(len(colors))]
        for dx, dy in shapes[rng.randrange(len(shapes))]:
            tile.putpixel(((x + dx) % 32, (y + dy) % 32), (*ImageColor.getrgb(color), 255))

    # Small olive tufts echo the courtyard shrubs and cover the whole tile.
    grass_colors = ['#667e42', '#82974c']
    tufts = [[(0, 0), (1, 0)], [(0, -1), (0, 0), (1, 0)],
             [(0, -1), (0, 0), (1, 0), (2, -1)],
             [(0, 0), (1, -1), (1, 0), (2, 0)]]
    grass_pixels = set()
    target_coverage = tile.width * tile.height
    origins = [(x, y) for y in range(tile.height) for x in range(tile.width)]
    rng.shuffle(origins)
    for x, y in origins:
        color = (*ImageColor.getrgb(rng.choice(grass_colors)), 255)
        for dx, dy in rng.choice(tufts):
            pixel = ((x + dx) % tile.width, (y + dy) % tile.height)
            tile.putpixel(pixel, color)
            grass_pixels.add(pixel)
        if len(grass_pixels) >= target_coverage:
            break
    return tile


GENERATORS = {
    'swing': frontal_swing,
    'sandbox': side_sandbox,
    'fence': fence,
    'earth': earth_tile,
}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--only', choices=GENERATORS)
    parser.add_argument('--preview-dir', type=Path)
    parser.add_argument('--preview-only', action='store_true')
    args = parser.parse_args()
    if args.preview_only and args.preview_dir is None:
        parser.error('--preview-only requires --preview-dir')
    output = args.preview_dir if args.preview_only else OUTPUT
    output.mkdir(parents=True, exist_ok=True)
    for name, generate in GENERATORS.items():
        if args.only and args.only != name:
            continue
        sprite = generate()
        sprite.save(output / f'{name}.png')
        print(f'{name}: {sprite.width}x{sprite.height}')
        if args.preview_dir:
            args.preview_dir.mkdir(parents=True, exist_ok=True)
            sprite.resize((sprite.width * 4, sprite.height * 4), Image.Resampling.NEAREST).save(
                args.preview_dir / f'{name}-4x.png'
            )


if __name__ == '__main__':
    main()
