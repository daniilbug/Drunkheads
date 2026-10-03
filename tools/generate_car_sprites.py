"""Regenerate the approved pixel-art car bodies and wheel sprites."""

from pathlib import Path
from PIL import Image, ImageDraw

OUTPUT_DIR = Path(__file__).resolve().parents[1] / "assets/sprites/street"


W, H = 60, 28
image = Image.new('RGBA', (W, H), (0, 0, 0, 0))
d = ImageDraw.Draw(image)
outline = '#17272e'
body_dark = '#2c626a'
body = '#46878c'
body_light = '#75adb0'
roof = '#5a969b'
glass_dark = '#354e61'
glass = '#7191a0'
glass_light = '#abc0c3'

# Draw one half and mirror it so the body, windows, doors, and arches
# are symmetric around the center between pixels 29 and 30.
d.polygon([(3, 17), (7, 14), (12, 14), (17, 7), (19, 5),
           (29, 5), (29, 24), (6, 24), (3, 22)], fill=body)
d.rectangle((5, 16, 29, 21), fill=body)
d.rectangle((6, 22, 29, 23), fill=body_dark)
d.polygon([(14, 14), (18, 7), (20, 6), (29, 6), (29, 14)], fill=roof)
d.rectangle((8, 15, 29, 16), fill=body_light)
d.line([(12, 14), (17, 7), (19, 6), (29, 6)], fill=body_light)
d.polygon([(17, 13), (20, 8), (28, 8), (28, 13)], fill=glass_dark)
d.line([(20, 8), (27, 8)], fill=glass_light)
d.rectangle((21, 10, 27, 11), fill=glass)
d.line([(29, 8), (29, 21)], fill=outline)
d.rectangle((22, 16, 25, 16), fill=outline)
d.rectangle((5, 20, 9, 21), fill=body_dark)
d.line([(8, 22), (29, 22)], fill='#22474e')

# Wheel cutouts are mirrored too. The animated wheels render in front.
cx = 15
d.rectangle((cx - 5, 20, cx + 5, 24), fill=outline)
d.rectangle((cx - 4, 19, cx + 4, 24), fill=outline)
d.rectangle((cx - 3, 20, cx + 3, 27), fill=(0, 0, 0, 0))
d.rectangle((cx - 4, 21, cx + 4, 27), fill=(0, 0, 0, 0))

left_half = image.crop((0, 0, W // 2, H))
image.paste(left_half.transpose(Image.Transpose.FLIP_LEFT_RIGHT), (W // 2, 0))

# The existing rear and front lights intentionally break the symmetry.
d = ImageDraw.Draw(image)
d.rectangle((6, 18, 8, 19), fill='#c36555')
d.rectangle((53, 17, 56, 18), fill='#f1d294')

image.save(OUTPUT_DIR / "car_body.png")

# The estate body shares the doors, wheels, lights and front end with the
# compact body. Only its rear cabin extends to a near-vertical tailgate.
estate = image.copy()
d = ImageDraw.Draw(estate)
d.rectangle((0, 0, 19, 16), fill=(0, 0, 0, 0))
d.polygon([(3, 17), (4, 9), (7, 6), (9, 5), (20, 5),
           (20, 16), (7, 16)], fill=body)
d.polygon([(5, 14), (6, 8), (9, 6), (20, 6), (20, 14)], fill=roof)
d.line([(5, 14), (6, 8), (9, 6), (19, 6)], fill=body_light)
d.rectangle((8, 15, 19, 16), fill=body_light)
d.polygon([(8, 8), (18, 8), (18, 13), (7, 13), (7, 10)], fill=glass_dark)
d.line((9, 8, 17, 8), fill=glass_light)
d.rectangle((9, 10, 16, 11), fill=glass)
d.line((19, 7, 19, 14), fill=outline)
estate.save(OUTPUT_DIR / "car_body_estate.png")

FRAME = 11
COLORS = {
    'tire': '#17272e',
    'tire_highlight': '#38464b',
    'rim_edge': '#a0a8a3',
    'rim': '#6b787d',
    'hub': '#384b53',
    'spoke': '#d5d4be',
}


def make_frame(direction: tuple[int, int]) -> Image.Image:
    im = Image.new('RGBA', (FRAME, FRAME), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    tire_rows = [(4, 6), (3, 7), (2, 8), (1, 9), (0, 10),
                 (0, 10), (0, 10), (1, 9), (2, 8), (3, 7), (4, 6)]
    for y, (left, right) in enumerate(tire_rows):
        d.line((left, y, right, y), fill=COLORS['tire'])
    # The lit upper arc makes the whole tire visible against the wheel arch.
    d.line((4, 0, 6, 0), fill=COLORS['tire_highlight'])
    d.line((3, 1, 7, 1), fill=COLORS['tire_highlight'])
    rim_rows = [(4, 6), (3, 7), (2, 8), (2, 8), (2, 8),
                (3, 7), (4, 6)]
    for y, (left, right) in enumerate(rim_rows, start=2):
        d.line((left, y, right, y), fill=COLORS['rim_edge'])
    for y, left, right in [(3, 4, 6), (4, 3, 7), (5, 3, 7),
                           (6, 3, 7), (7, 4, 6)]:
        d.line((left, y, right, y), fill=COLORS['rim'])
    dx, dy = direction
    d.point((5 + dx, 5 + dy), fill=COLORS['spoke'])
    if dx != 0:
        d.point((5 + dx // 2, 5), fill=COLORS['spoke'])
    else:
        d.point((5, 5 + dy // 2), fill=COLORS['spoke'])
    d.point((5, 5), fill=COLORS['hub'])
    return im

frames = [make_frame(v) for v in [(0, -3), (3, 0), (0, 3), (-3, 0)]]
sheet = Image.new('RGBA', (FRAME * len(frames), FRAME), (0, 0, 0, 0))
for i, frame in enumerate(frames):
    sheet.alpha_composite(frame, (i * FRAME, 0))
sheet.save(OUTPUT_DIR / "car_wheel.png")
