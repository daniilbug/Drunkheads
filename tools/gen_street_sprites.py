#!/usr/bin/env python3
"""Generate pixel art used by the street scenes."""

from pathlib import Path

from PIL import Image, ImageDraw


OUT = Path(__file__).resolve().parents[1] / "assets" / "sprites" / "street"
SMOKE_FRAME_WIDTH = 10
SMOKE_FRAME_HEIGHT = 14


def generate_cigarette_smoke() -> Path:
    """Draw eight successive smoke puffs into one transparent sprite sheet."""
    trails = (
        ((5, 13), (5, 12)),
        ((5, 13), (5, 12), (6, 11), (6, 10)),
        ((5, 13), (5, 12), (6, 11), (6, 10), (5, 9), (4, 8)),
        ((5, 13), (5, 12), (6, 11), (5, 10), (4, 9), (4, 8)),
        ((5, 13), (5, 12), (5, 11), (4, 10), (4, 9), (5, 8)),
        ((5, 13), (5, 12), (4, 11), (4, 10), (5, 9)),
        ((5, 13), (4, 12), (4, 11), (5, 10)),
        ((5, 13), (4, 12), (5, 11)),
    )
    puffs = (
        (),
        ((6, 9, 1),),
        ((4, 7, 1), (6, 9, 1)),
        ((4, 5, 2), (6, 8, 1)),
        ((3, 4, 2), (6, 7, 2)),
        ((3, 3, 2), (5, 6, 2)),
        ((2, 2, 2), (5, 5, 1)),
        ((2, 2, 1), (4, 4, 1)),
    )

    sheet = Image.new(
        "RGBA", (SMOKE_FRAME_WIDTH * len(trails), SMOKE_FRAME_HEIGHT), (0, 0, 0, 0)
    )
    draw = ImageDraw.Draw(sheet)
    for frame, (trail, clouds) in enumerate(zip(trails, puffs)):
        x_offset = frame * SMOKE_FRAME_WIDTH
        fade = 1.0 if frame < 5 else (0.8, 0.6, 0.4)[frame - 5]
        for x, y in trail:
            draw.point(
                (x_offset + x, y), fill=(175, 190, 194, int(140 * fade))
            )
        for x, y, radius in clouds:
            draw.ellipse(
                (x_offset + x - radius, y - radius,
                 x_offset + x + radius, y + radius),
                fill=(225, 233, 233, int(115 * fade)),
                outline=(190, 205, 208, int(165 * fade)),
            )
            draw.point(
                (x_offset + x, y - radius),
                fill=(250, 252, 252, int(210 * fade)),
            )

    OUT.mkdir(parents=True, exist_ok=True)
    path = OUT / "cigarette_smoke.png"
    sheet.save(path)
    return path


def generate_horizontal_road() -> Path:
    """Draw a two-lane road tile that repeats seamlessly along the X axis."""
    asphalt = Image.open(OUT / "asphalt.png").convert("RGBA")
    width, height = 64, 100
    road = Image.new("RGBA", (width, height))
    pixels = road.load()
    for y in range(height):
        for x in range(width):
            base = asphalt.getpixel((x % asphalt.width, y % asphalt.height))
            color = tuple(round(channel * 0.62 - 1) for channel in base[:3])
            pixels[x, y] = (*color, 255)

    draw = ImageDraw.Draw(road)
    draw.rectangle((0, 0, width - 1, 2), fill="#424645")
    draw.line((0, 3, width - 1, 3), fill="#777872")
    draw.line((0, 7, width - 1, 7), fill="#acaea4")
    draw.line((0, 8, width - 1, 8), fill="#777b77")
    draw.rectangle((0, 96, width - 1, 99), fill="#424645")
    draw.line((0, 95, width - 1, 95), fill="#777872")
    draw.line((0, 91, width - 1, 91), fill="#acaea4")
    draw.line((0, 92, width - 1, 92), fill="#777b77")
    draw.line((0, 27, width - 1, 27), fill="#565958")
    draw.line((0, 72, width - 1, 72), fill="#565958")
    draw.rectangle((8, 49, 35, 50), fill="#c6c3ae")
    draw.line((8, 51, 35, 51), fill="#8d8d80")

    path = OUT / "road_horizontal.png"
    road.save(path)
    return path


if __name__ == "__main__":
    print(generate_cigarette_smoke())
    print(generate_horizontal_road())
