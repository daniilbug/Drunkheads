#!/usr/bin/env python3
"""Generate the two-frame heart sign matching the poker room's neon palette."""

from pathlib import Path

from PIL import Image, ImageDraw


OUTPUT = Path(__file__).resolve().parents[1] / "assets/sprites/poker"
FRAME_SIZE = 10
NEON = (255, 62, 190, 255)
HIGHLIGHT = (255, 197, 235, 255)
DIM = (227, 0, 150, 255)
OUTLINE = ((0, 2), (2, 0), (3, 0), (4, 1), (5, 1), (6, 0), (7, 0), (9, 2), (9, 4), (5, 9), (4, 9), (0, 4), (0, 2))


def make_hearts_sign() -> Image.Image:
    sheet = Image.new("RGBA", (FRAME_SIZE * 2, FRAME_SIZE))
    for frame_index in range(2):
        frame = Image.new("RGBA", (FRAME_SIZE, FRAME_SIZE))
        draw = ImageDraw.Draw(frame)
        draw.line(OUTLINE, fill=NEON)
        draw.point((2 + frame_index * 4, 0), fill=HIGHLIGHT)
        draw.point((9 if frame_index else 0, 3), fill=DIM)
        sheet.alpha_composite(frame, (frame_index * FRAME_SIZE, 0))
    return sheet


def main() -> None:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    path = OUTPUT / "hearts_sign.png"
    make_hearts_sign().save(path)
    print(path)


if __name__ == "__main__":
    main()
