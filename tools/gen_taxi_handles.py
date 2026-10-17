#!/usr/bin/env python3
"""Match the existing taxi's door handles to its ochre trim palette."""

from pathlib import Path

from PIL import Image, ImageDraw


TEXTURE = Path(__file__).resolve().parents[1] / "assets/sprites/street/taxi_body.png"
TRIM = (133, 100, 46, 255)


def main() -> None:
    # Retouch only the two handles; preserve the hand-authored taxi body.
    with Image.open(TEXTURE) as source:
        image = source.convert("RGBA")
    if image.size != (60, 28):
        raise ValueError("Expected the taxi's 60x28 body sprite")
    draw = ImageDraw.Draw(image)
    draw.line((23, 16, 25, 16), fill=TRIM)
    draw.line((34, 16, 36, 16), fill=TRIM)
    image.save(TEXTURE)


if __name__ == "__main__":
    main()
