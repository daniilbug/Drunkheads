#!/usr/bin/env python3
"""Generate twenty aligned, neutral-palette hair atlases for the hair-color shader.

IDs 0–9 are masculine cuts; 10–19 are feminine cuts. Each cut is authored
from the front, back and right. Profiles mirror around the same scalp as the
body, while every pose uses Player's existing 12×20 frame and head motion.
Only hair PNGs are written; the shared character/body generator calls this too.
"""
from pathlib import Path

from PIL import Image

from character_pose import head_y

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / 'assets/sprites/characters'
FW, FH = 12, 20
# Neutral four-tone ramp. Warm eye pixels are deliberately excluded by the shader.
PALETTE = {
    'd': (64, 64, 64, 255),
    's': (112, 112, 112, 255),
    'm': (176, 176, 176, 255),
    'h': (224, 224, 224, 255),
}
EYE = (60, 41, 36, 255)
# Each slash starts a new row. Dots are transparent. All geometry starts at
# head_y, never above it, so walking/dancing cannot clip the top of a haircut.
#                         FRONT / BACK / RIGHT PROFILE
STYLES = (
    # Masculine cuts: IDs 0–9.
    ('Buzz cut',
     '....ssss/...smmhms/...s....s/...s....s',
     '....ssss/...smmhms/...ssssss/...ssssss/....ssss',
     '....ssss/...smmhms/...ss/...s'),
    ('Textured crop',
     '....mhm/...mmhmhm/...smsmms/...s....s',
     '....mmm/...smmhmm/...smmmmm/...ssssss/....ssss',
     '....mhm/...mmhmhm/...smmm/...ss/...s'),
    ('Side part',
     '....mmhm/...mhhmdm/...mmmdmm/...s....m',
     '....mmhm/...smmhdm/...smmmdm/...smmmmm/...ssssss/....ssss',
     '....mmhm/...smhhmm/...smmm/...smm/...ss/...s'),
    ('Soft quiff',
     '.....mhm/....mhhmm/...mmmmmms/...sm..ms/...s',
     '....mhhm/...smmmmm/...smmmmm/...smmmmm/...ssssss/....ssss',
     '.....mhm/...mmhhmm/...smmmmm/...smm/...ss/...s'),
    ('Undercut',
     '.....mmm/....mhhmm/...smmmmm/...s...ms',
     '....mhhm/...smmmmm/...smmmmms/...ssssss/....ssss',
     '.....mmm/...smhhmm/...ssmmm/...ss/...s'),
    ('Short curls',
     '....m.hm/...mhmhmm/..smmsmhm/...sm..ms/...s....m',
     '....m.mm/...mhmhmm/..smmsmmhm/...smmmms/..smmsmms/...sssss/....sss',
     '....m.hm/...mhmhmm/..smmmmm/...smsm/...sm/...s'),
    ('Curtains',
     '....mddm/...mhddhm/..smh..hms/..sm....ms/...s....m',
     '....mmmm/...smhhmm/..smmmmmms/..smmmmmms/...smmmms/...sssss',
     '....mmhm/..smmhhmm/..smm..mm/..smm/...sm/...s'),
    ('Swept back',
     '....mhhm/...smhmmm/...ssmmms/...s....s',
     '....mhhm/...smhmmm/..smmhmmmm/..smmhmmms/...smmmms/...sssss',
     '....mhhm/..smmhhmm/..smmmmm/..smmm/...smm/...ss'),
    ('Short twists',
     '...m.m.m/...hmhmhm/...msmsms/..sm....ms/...m....s',
     '...m.m.m/..smhmhmms/...msmsms/..smmsmmms/...smsms/....sss',
     '...m.m.m/..smhmhmm/...msmmm/..smms/...sms/...s'),
    ('Modern mullet',
     '....mhm/...mmhmhm/...smsmmm/...s....m/...s....s/...s....s',
     '....mmmm/...smhhmm/...smmmmm/...smmmmm/...smmmmm/..ssmmmms/..smmhmms/...smhms/....sms',
     '....mhm/..smmhhmm/..smmmmm/..smm/..smm/..smm/..smm/..sms/...s'),
    # Feminine cuts: IDs 10–19.
    ('Pixie',
     '....mmhm/...mhhmmm/..smmm.mm/...sm...m/...s',
     '....mmhm/...smhhmm/..smmmmmmm/...smmmms/...sssss/....sss',
     '....mmhm/..smmhhmm/..smmmmm/...smm/...sm/...s'),
    ('French bob',
     '....mmmm/...mmhhmm/..smmmmmmm/..sm....mm/..sm....mm/..sm....mm/...m....m',
     '....mmmm/...smhhmm/..smmmmmms/..smmmmmms/..smmmmmms/..smmmmmms/...smmmms/....ssss',
     '....mmmm/..smmhhmm/..smmmmm/..smm/..smm/..smm/...mm/....m'),
    ('Long bob',
     '....mdmm/...mhdhmm/..smh..mmm/..sm....mm/..sm....mm/..sm....mm/..sm....mm/...m....mm/........m',
     '....mmmm/...smhhmm/..smmmmmms/..smhmmmms/..smhmmmms/..smmmmmms/..smmmmmms/...smmmms/....ssss',
     '....mmmm/..smmhhmm/..smmmmm/..smm/..smm/..smm/..smm/...mm/...m'),
    ('Long straight',
     '....mddm/...mhddhm/..smh..hmm/..sm....mm/..sm....mm/..sm....mm/..sm....mm/..sm....mm/..sm....mm/..sm....mm/..sm....mm/...m....m',
     '....mmmm/...smhhmm/..smmmmmms/..smhmmmms/..smhmmmms/..smhmmmms/..smhmmmms/..smhmmmms/..smmmmmms/..smmmmmms/...smmmms/....ssss',
     '....mmmm/..smmhhmm/..smmmmm/..smm/..smh/..smh/..smh/..smm/..smm/..smm/...mm/...m'),
    ('Long waves',
     '....mdmm/...mhdhmm/..smh..mmm/..sm....mm/..sm....mm/...sm..mm/..sm....mm/..sm....mm/...sm..mm/..sm....mm/..sm....mm/...m....m',
     '....mmmm/...smhhmm/..smmmmmms/..smhmmmms/..smhmmmms/...smhmmms/..smmhmmms/..smhmmmms/...smhmmms/..smmhmmms/...smmmms/....ssss',
     '....mmmm/..smmhhmm/..smmmmm/..smm/..smh/...sm/..smm/..smh/...sm/..smm/...mm/....m'),
    ('Layered shag',
     '....mhm/...mmhmhm/..smmm.mmm/..sm....mm/...sm..mm/..sm....mm/...sm..mm/..sm....mm/...m....m',
     '....mmmm/...smhhmm/..smmmmmms/...smmmms/..smhmmmms/...smmmms/..smmmmmms/...smmmms/....sms',
     '....mhm/..smmhhmm/..smmmmm/..smm/...sm/..smm/...sm/..smm/...m'),
    ('High ponytail',
     '....mhhm/...smhmmm/...smmmms/...s....s/........m/........sm/.........m/.........m/.........s',
     '....mhhm/...smhmmm/...smmmmm/...smdmms/...smhmms/...smhms/....mhmm/....smhm/.....mhmm/.....sms/......s',
     '....mhhm/..smhhmmm/.msmmmmm/mm.sm/mm.ss/sm.s/mh/mm/mm/.s'),
    ('Low bun',
     '....mhhm/...smhmmm/...smmmms/...s....s/...s....s',
     '....mhhm/...smhmmm/...smmmmm/...smmmmm/...smhmms/...mhhmm/...smhms/....sms',
     '....mhhm/..smmhhmm/..smmmmm/..smm/..smm/.smhm/.mhmm/..sms'),
    ('Curly bob',
     '....m.mm/...mhmhmm/..smmsmmhm/..sm....mm/..sm....mm/...sm..mm/..sm....mm/...m....m',
     '....m.mm/...mhmhmm/..smmsmmhm/..smmmmmms/...smmsmm/..smmmmmms/...smmmms/....sms',
     '....m.mm/..smhmhmm/..smmmmm/..smm/..smh/...sm/..smm/...m'),
    ('Loose braid',
     '....mddm/...mhddhm/...mh..mm/...s....m/...s....s',
     '....mmmm/...smhhmm/...smmmmm/...smmmmm/...smmmms/....smhms/.....mh/.....sms/......mh/.....sms/......m/......s',
     '....mmmm/..smmhhmm/..smmmmm/..smm/..smm/..sm/..mh/..sms/...mh/..sms/...m/...s'),
)


def draw_frame(style: int, row: int, frame: int) -> Image.Image:
    image = Image.new('RGBA', (FW, FH))
    view = 2 if row in (2, 3) else 1 if row in (1, 7, 9) else 0
    pattern = STYLES[style][view + 1].split('/')
    origin_y = head_y(row, frame)
    for y, line in enumerate(pattern):
        assert len(line) <= FW, (style, view, line)
        assert origin_y + y < FH, (style, row, frame, y)
        for x, symbol in enumerate(line):
            if symbol != '.':
                image.putpixel((x, origin_y + y), PALETTE[symbol])
    # Eyes are part of the existing hair-layer contract, not the dye ramp.
    if view != 1:
        for x in ((7,) if view == 2 else (4, 7)):
            image.putpixel((x, origin_y + 3), EYE)
    if row == 2:
        image = image.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    return image


def generate_hair_atlases() -> None:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    for style in range(len(STYLES)):
        sheet = Image.new('RGBA', (FW * 4, FH * 10))
        for row in range(10):
            for frame in range(4):
                sheet.paste(draw_frame(style, row, frame), (frame * FW, row * FH))
        sheet.save(OUTPUT / f'hair_{style}.png')
    print(f'Saved {len(STYLES)} neutral hair atlases ({FW * 4}×{FH * 10})')


if __name__ == '__main__':
    generate_hair_atlases()
