#!/usr/bin/env python3
"""Generate a symmetric rectangular six-frame shower sprite for the home WC."""

import argparse
from pathlib import Path

from PIL import Image, ImageDraw, ImageOps

from home_plumbing_palette import BRIGHT_GRAY, EDGE, GRAY, LIGHT_GRAY, PORCELAIN, WHITE, with_alpha


SPRITES = Path(__file__).resolve().parents[1] / "assets/sprites/home"
SINK_SPRITE = SPRITES.parent / "wc/sink.png"
FRAME_WIDTH = 16
FRAME_HEIGHT = 36
FRAME_COUNT = 6  # Dry frame, followed by five water animation frames.

FRAME = EDGE
RAIL = GRAY
GLASS = with_alpha(LIGHT_GRAY, 96)
GLASS_LIGHT = with_alpha(WHITE, 144)
GLASS_SHADE = with_alpha(BRIGHT_GRAY, 128)
BASE = PORCELAIN
TOP = WHITE
HEAD = GRAY
HEAD_SHADOW = EDGE
BASE_SHADE = BRIGHT_GRAY

def sink_water_colors() -> tuple[tuple[int, int, int, int], ...]:
    """Get the running-water palette from the WC sink's first wet frame."""
    sink = Image.open(SINK_SPRITE).convert("RGBA")
    if sink.width % 6:
        raise ValueError("WC sink sprite must have six equally sized frames")
    width = sink.width // 6
    colors = {
        sink.getpixel((x + width, y))
        for y in range(sink.height)
        for x in range(width)
        if sink.getpixel((x + width, y)) != sink.getpixel((x, y))
    }
    if len(colors) != 3:
        raise ValueError(f"Expected three WC sink water colors, got {len(colors)}")
    return tuple(sorted(colors, key=lambda color: sum(color[:3])))


WATER_DARK, WATER_MID, WATER_LIGHT = sink_water_colors()


def make_frame(phase: int) -> Image.Image:
    """Draw one half, then mirror it so every frame is pixel-exact symmetric."""
    half = Image.new("RGBA", (FRAME_WIDTH // 2, FRAME_HEIGHT), FRAME)
    draw = ImageDraw.Draw(half)

    # A closed rectangular outline, with equal-width left and right posts.
    draw.rectangle((1, 1, 7, 34), fill=GLASS_SHADE)
    draw.rectangle((1, 1, 7, 4), fill=TOP)
    draw.line((1, 5, 7, 5), fill=RAIL)
    draw.line((1, 6, 7, 6), fill=FRAME)
    draw.rectangle((2, 8, 7, 29), fill=GLASS)
    draw.line((1, 7, 1, 30), fill=RAIL)
    draw.line((2, 9, 2, 28), fill=GLASS_LIGHT)
    draw.line((2, 15, 6, 15), fill=GLASS_SHADE)
    draw.line((2, 23, 6, 23), fill=GLASS_SHADE)

    # Water stays behind the front seam and shifts between the five wet frames.
    if phase:
        for x in (3, 5, 6):
            offset = (phase + x) % 4
            for y in range(9 + offset, 29, 7):
                draw.line((x, y, x, min(y + 2, 28)), fill=WATER_DARK)
                if x == 5 and y + 3 <= 28:
                    draw.point((x, y + 3), fill=WATER_MID)
        draw.point((4 + phase % 2, 29), fill=WATER_LIGHT)

    # Center seam, fixed shower head, and an even rectangular base.
    draw.line((7, 8, 7, 29), fill=GLASS_SHADE)
    draw.rectangle((6, 2, 7, 7), fill=HEAD)
    draw.line((5, 7, 7, 7), fill=HEAD_SHADOW)
    draw.rectangle((1, 30, 7, 34), fill=BASE)
    draw.line((1, 30, 7, 30), fill=RAIL)
    draw.line((1, 34, 7, 34), fill=RAIL)
    draw.rectangle((6, 32, 7, 33), fill=BASE_SHADE)

    frame = Image.new("RGBA", (FRAME_WIDTH, FRAME_HEIGHT))
    frame.paste(half, (0, 0))
    frame.paste(ImageOps.mirror(half), (FRAME_WIDTH // 2, 0))
    return frame


def make_sheet() -> Image.Image:
    sheet = Image.new("RGBA", (FRAME_WIDTH * FRAME_COUNT, FRAME_HEIGHT))
    for phase in range(FRAME_COUNT):
        sheet.paste(make_frame(phase), (phase * FRAME_WIDTH, 0))
    return sheet


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--preview", type=Path, help="Save an enlarged nearest-neighbor preview")
    args = parser.parse_args()

    sheet = make_sheet()
    output = SPRITES / "shower.png"
    sheet.save(output)
    print(output)
    if args.preview:
        args.preview.parent.mkdir(parents=True, exist_ok=True)
        sheet.resize((sheet.width * 8, sheet.height * 8), Image.Resampling.NEAREST).save(args.preview)
        print(args.preview)


if __name__ == "__main__":
    main()
