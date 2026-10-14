#!/usr/bin/env python3
"""Generate a kitchen sink cabinet with six frames compatible with the WC sink."""

import argparse
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "assets/sprites/home/sink.png"
FRAME_SIZE = (16, 20)


def make_frame(cabinet: Image.Image, water_frame: int) -> Image.Image:
    image = Image.new("RGBA", FRAME_SIZE, (0, 0, 0, 0))
    image.alpha_composite(cabinet, (0, 4))
    draw = ImageDraw.Draw(image)

    # A uniform one-pixel rectangular rim makes all four basin edges explicit.
    draw.rectangle((3, 4, 12, 7), fill="#626970")
    draw.rectangle((4, 5, 11, 6), fill="#b4bcc1")
    draw.line((4, 5, 11, 5), fill="#929ca3")
    draw.point((8, 6), fill="#626970")

    # A one-pixel metal tap with a short downward-facing spout.
    draw.line((9, 1, 9, 3), fill="#828282")
    draw.line((6, 0, 9, 0), fill="#cdcdcd")
    draw.line((6, 1, 6, 2), fill="#cdcdcd")

    if water_frame:
        # Only the highlights move; every water pixel stays in the same column.
        water = ("#9eb1e4", "#92a7e1", "#b6c5ea", "#92a7e1", "#9eb1e4")
        for y in range(3, 7):
            draw.point((6, y), fill=water[(y + water_frame) % len(water)])

    return image


def preview_background() -> Image.Image:
    image = Image.new("RGBA", FRAME_SIZE, "#53585f")
    draw = ImageDraw.Draw(image)
    for y in range(0, FRAME_SIZE[1], 4):
        for x in range(0, FRAME_SIZE[0], 4):
            if (x // 4 + y // 4) % 2:
                draw.rectangle((x, y, x + 3, y + 3), fill="#5d6269")
    return image


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--preview", type=Path, help="Save a dry/wet comparison beside the existing cabinet and stove")
    parser.add_argument("--animation", type=Path, help="Save an enlarged preview of running water")
    args = parser.parse_args()

    cabinet = Image.open(ROOT / "assets/sprites/home/kitchen.png").convert("RGBA")
    if cabinet.size != (16, 16):
        raise ValueError("The kitchen cabinet reference must be 16x16 pixels")
    frames = [make_frame(cabinet, index) for index in range(6)]
    sheet = Image.new("RGBA", (FRAME_SIZE[0] * len(frames), FRAME_SIZE[1]))
    for index, frame in enumerate(frames):
        sheet.alpha_composite(frame, (index * FRAME_SIZE[0], 0))
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(OUTPUT)

    if args.preview:
        stove = Image.open(ROOT / "assets/sprites/home/stove.png").convert("RGBA")
        comparison = Image.new("RGBA", (88, 28), "#53585f")
        comparison.alpha_composite(cabinet, (4, 8))
        comparison.alpha_composite(frames[0], (25, 4))
        comparison.alpha_composite(frames[3], (46, 4))
        comparison.alpha_composite(stove, (67, 8))
        args.preview.parent.mkdir(parents=True, exist_ok=True)
        comparison.resize((704, 224), Image.Resampling.NEAREST).save(args.preview)

    if args.animation:
        # Match the existing Sink script's frame traversal and 0.15s interval.
        order = [0] + [2, 4, 1, 3, 5] * 3
        animation = []
        for index in order:
            frame = preview_background()
            frame.alpha_composite(frames[index])
            animation.append(frame.resize((192, 240), Image.Resampling.NEAREST).convert("RGB"))
        args.animation.parent.mkdir(parents=True, exist_ok=True)
        animation[0].save(
            args.animation,
            save_all=True,
            append_images=animation[1:],
            duration=[750] + [150] * (len(animation) - 1),
            loop=0,
            disposal=2,
        )

    print(OUTPUT)


if __name__ == "__main__":
    main()
