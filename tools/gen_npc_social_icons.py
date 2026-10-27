"""Reproduce NPC conversation icons and the two-frame speech indicator."""
from pathlib import Path
from PIL import Image, ImageDraw
from npc_social_extra_icons import EXTRA_ICONS

OUT = Path(__file__).resolve().parents[1] / 'assets/sprites/social'
OUT.mkdir(parents=True, exist_ok=True)
CREAM, DARK, GOLD = '#e6dfcd', '#51473e', '#d5ab66'

def icon(name, paint, size=(24, 24)):
    image = Image.new('RGBA', size)
    paint(ImageDraw.Draw(image))
    image.save(OUT / f'{name}.png')

def guitar(d):
    d.ellipse((3,11,14,22), fill='#aa624c')
    d.ellipse((8,8,17,17), fill='#bd8054')
    d.polygon([(11,12),(13,14),(22,5),(20,3)], fill='#d5ab66')
    d.rectangle((18,3,22,7), fill='#ab8054')
    d.ellipse((10,12,13,15), fill='#51473e')
    d.line((8,17,20,5), fill='#e6dfcd', width=1)
    d.polygon([(5,17),(8,20),(9,19),(6,16)], fill='#51473e')

def book(d):
    d.rectangle((1,3,22,21),fill='#88765e')
    d.rectangle((2,4,10,20),fill='#e6dfcd')
    d.rectangle((13,4,21,20),fill='#d8ceb7')
    d.rectangle((11,4,12,20),fill='#a38d70')
    d.line((3,5,9,5),fill='#f0e9d7')
    d.line((14,5,20,5),fill='#e6dfcd')
    for y in (8,11,14,17):
        d.line((4,y,8,y),fill='#b2a48b')
        d.line((15,y,19,y),fill='#b2a48b')

def ball(d):
    SIZE = 24
    patches = Image.new('L',(SIZE,SIZE))
    p = ImageDraw.Draw(patches)

    # One front pentagon, one top panel, two side panels and two lower panels.
    # The peripheral panels are intentionally foreshortened, as on the reference.
    p.polygon([(12,8),(16,11),(14,15),(10,15),(8,11)],fill=255)
    p.polygon([(8,2),(16,2),(16,3),(12,5),(8,3)],fill=255)
    p.polygon([(4,6),(5,6),(5,9),(3,12),(1,11),(1,8)],fill=255)
    p.polygon([(4,16),(7,18),(9,22),(5,21),(2,18)],fill=255)

    # Mirroring the left half retains balance without imposing a cross-shaped map.
    for y in range(SIZE):
        for x in range(12):
            if 24-x < SIZE and patches.getpixel((x,y)):
                patches.putpixel((24-x,y),255)

    seams = Image.new('L',(SIZE,SIZE))
    s = ImageDraw.Draw(seams)
    for segment in [(12,5,12,8),(5,10,8,11),(16,11,19,10),
                    (7,18,10,15),(14,15,17,18)]:
        s.line(segment,fill=255)

    for y in range(SIZE):
        for x in range(SIZE):
            radius2 = (x-12)**2+(y-12)**2
            if radius2 > 106:
                continue
            color = '#b6bdaf'
            if radius2 <= 87:
                color = '#efebde'
                if y >= 18:
                    color = '#dce0d2'
                if seams.getpixel((x,y)):
                    color = '#c2c8b9'
                if patches.getpixel((x,y)):
                    color = '#555964'
            d.point((x,y),fill=tuple(bytes.fromhex(color[1:]))+(255,))

def pan(d):
    d.polygon([(12,10),(14,12),(23,3),(21,1)],fill='#7b7b76')
    d.ellipse((2,6,18,22),fill='#555964')
    d.ellipse((4,8,16,20),fill='#383d45')
    d.ellipse((6,10,14,18),fill='#e6dfcd')
    d.rectangle((8,12,12,16),fill='#d5ab66')

def gamepad(d):
    body=[(4,7),(8,7),(10,8),(13,8),(15,7),(19,7),
          (20,9),(21,13),(22,17),(22,18),(21,19),(19,19),
          (17,18),(14,15),(9,15),(6,18),(4,19),(2,19),
          (1,18),(1,17),(2,13),(3,9)]
    d.polygon(body,fill='#adb3ba')
    # Compact 5x5 cross and two 2x2 buttons, all inset from the silhouette.
    d.rectangle((5,11,9,11),fill='#555964')
    d.rectangle((7,9,7,13),fill='#555964')
    d.rectangle((16,9,17,10),fill='#aa624c')
    d.rectangle((18,12,19,13),fill='#47644d')
    d.rectangle((11,11,12,11),fill='#777e87')

def suitcase(d):
    # Body ends at row 20; feet begin on row 21, with no overlap.
    d.rectangle((8,3,16,8),fill='#ab8054')
    d.rectangle((10,5,14,8),fill=(0,0,0,0))
    d.rectangle((2,7,22,20),fill='#ab8054')
    d.rectangle((3,8,21,10),fill='#c49865')
    d.rectangle((6,7,7,20),fill='#7f664a')
    d.rectangle((17,7,18,20),fill='#7f664a')
    d.rectangle((10,12,14,15),fill='#86a9be')
    d.rectangle((4,21,6,23),fill='#555964')
    d.rectangle((18,21,20,23),fill='#555964')

def cat(d):
    d.polygon([(3,3),(9,7),(15,7),(21,3),(21,17),(17,21),(7,21),(3,17)],fill='#c49865')
    d.polygon([(5,6),(8,9),(5,10)],fill='#bd889c')
    d.polygon([(19,6),(16,9),(19,10)],fill='#bd889c')
    d.rectangle((7,11,8,13),fill='#41403e')
    d.rectangle((16,11,17,13),fill='#41403e')
    d.polygon([(9,16),(12,14),(15,16),(15,19),(9,19)],fill=CREAM)
    d.rectangle((11,15,13,16),fill='#aa624c')

def flower(d):
    d.rectangle((11,7,12,18),fill='#47644d')
    d.polygon([(11,13),(5,9),(5,13),(11,16)],fill='#718455')
    d.polygon([(13,11),(19,7),(19,11),(13,14)],fill='#718455')
    for box in [(9,2,14,7),(7,4,16,6)]:
        d.rectangle(box,fill='#bd889c')
    d.rectangle((10,4,13,5),fill='#d5ab66')
    d.polygon([(5,17),(19,17),(17,23),(7,23)],fill='#aa624c')
    d.rectangle((4,16,20,18),fill='#bd8054')

def film(d):
    d.rectangle((3,11,22,22),fill='#555964')
    d.rectangle((5,15,20,15),fill='#adb3ba')
    d.rectangle((5,18,15,18),fill='#7b7b76')
    mask=Image.new('L',(24,24))
    ImageDraw.Draw(mask).polygon([(2,7),(20,2),(22,6),(4,11)],fill=255)
    for y in range(24):
        for x in range(24):
            if mask.getpixel((x,y)):
                color='#383d45' if (x+y)%8<4 else '#adb3ba'
                d.point((x,y),fill=color)

def heart(d):
    # A compact 16px silhouette centered on the 24px canvas, with 4px margins.
    # Both lower edges descend at 45 degrees: one pixel in, one pixel down.
    d.polygon([(4,6),(6,4),(9,4),(11,6),(12,6),(14,4),(17,4),(19,6),
               (19,12),(12,19),(11,19),(4,12)],fill='#bd7669')
    d.rectangle((6,6,8,7),fill='#d99a84')

def neutral(d):
    d.rectangle((4,4,19,19),fill=CREAM)
    d.rectangle((7,8,8,10),fill=DARK)
    d.rectangle((15,8,16,10),fill=DARK)
    d.rectangle((8,15,15,16),fill=DARK)

def voice(d):
    # Two 6×6 frames, displayed at ×2; only the taller stroke moves.
    for frame in range(2):
        x = frame * 6
        d.rectangle((x,frame,x+1,frame+4),fill=CREAM)
        d.rectangle((x+4,3,x+5,5),fill=CREAM)

if __name__ == '__main__':
    for name, painter in zip(
        ('music', 'reading', 'sport', 'cooking', 'games', 'travel',
         'animals', 'gardening', 'cinema', 'heart', 'neutral'),
        (guitar, book, ball, pan, gamepad, suitcase, cat, flower, film, heart, neutral),
    ):
        icon(name, painter)
    for name, painter in EXTRA_ICONS.items():
        icon(name, painter)
    icon('voice', voice, (12, 6))
    print(OUT)
