"""Generate the skin layer for all 40 shower animation frames."""

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
CHARACTERS = ROOT / "assets/sprites/characters"
SKIN = (236, 194, 149, 255)
SHOE = (55, 40, 28, 255)


def main() -> None:
    base = Image.open(ROOT / "assets/sprites/player.png").convert("RGBA")
    top = Image.open(CHARACTERS / "top_0.png").convert("RGBA")
    pants = Image.open(CHARACTERS / "pants_0.png").convert("RGBA")
    assert base.size == top.size == pants.size == (48, 200)
    skin = Image.new("RGBA", base.size)

    for frame in range(40):
        frame_x = (frame % 4) * 12
        frame_y = (frame // 4) * 20
        for y in range(20):
            for x in range(12):
                point = (frame_x + x, frame_y + y)
                if (top.getpixel(point)[3] or pants.getpixel(point)[3]
                        or (y >= 14 and base.getpixel(point) == SHOE)):
                    skin.putpixel(point, SKIN)

    skin.save(CHARACTERS / "naked_overlay.png")


if __name__ == "__main__":
    main()
