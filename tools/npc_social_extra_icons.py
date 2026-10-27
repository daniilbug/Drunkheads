"""Approved additional NPC interests, painted at their native 24×24 size."""
from math import cos, sin, radians
from PIL import Image, ImageDraw


def photography(d):
    # Mirror-symmetric silhouette with a raised central viewfinder.
    d.polygon([(3,7),(7,7),(7,4),(16,4),(16,7),(20,7),
               (21,8),(21,19),(20,20),(3,20),(2,19),(2,8)],fill='#777e87')
    d.rectangle((9,5,14,6),fill='#adb3ba')
    d.rectangle((3,8,20,9),fill='#929ba3')
    d.rectangle((4,10,5,11),fill='#e6dfcd')
    d.rectangle((18,10,19,11),fill='#aa624c')
    d.ellipse((6,8,17,19),fill='#adb3ba')
    d.ellipse((8,10,15,17),fill='#383d45')
    d.ellipse((9,11,14,16),fill='#86a9be')
    d.rectangle((10,11,11,12),fill='#d6d9c7')


def drawing(d):
    # Rounded wooden palette with a thumb opening and a cut-away lower edge.
    d.ellipse((2,4,20,21),fill='#c49865')
    d.ellipse((14,15,23,24),fill=(0,0,0,0))
    d.ellipse((10,11,12,13),fill=(0,0,0,0))
    for bounds,color in [((5,7,8,10),'#bd7669'),((11,6,14,9),'#86a9be'),
                         ((4,13,7,16),'#718455')]:
        d.ellipse(bounds,fill=color)
    # Slender handle, a short ferrule and a tapered bristle bundle on one diagonal.
    d.polygon([(7,19),(8,20),(18,10),(17,9)],fill='#aa624c')
    d.polygon([(16,9),(18,11),(20,9),(18,7)],fill='#adb3ba')
    d.polygon([(18,7),(20,9),(21,8),(22,6),(22,5),(21,5),(19,6)],fill='#51473e')
    d.line((19,7,21,5),fill='#88765e',width=1)
    d.point((22,5),fill='#51473e')


def fishing(d):
    # A curved rod, a small reel and a hanging line make this fishing, not food.
    d.line([(4,20),(16,8),(17,5),(19,3),(21,3),(22,4)],fill='#ab8054',width=1)
    d.polygon([(3,20),(4,21),(17,8),(16,7)],fill='#ab8054')
    d.polygon([(2,21),(3,22),(7,18),(6,17)],fill='#7f664a')
    d.ellipse((5,14,9,18),fill='#555964')
    d.rectangle((7,16,7,17),fill='#d5ab66')
    d.line((22,4,22,18),fill='#929ba3',width=1)
    # Compact fish silhouette, with the tail, fins and eye kept distinct.
    d.polygon([(13,18),(9,15),(9,21)],fill='#6f8f9f')
    d.polygon([(15,15),(16,13),(18,15)],fill='#6f8f9f')
    d.polygon([(15,20),(16,22),(18,20)],fill='#6f8f9f')
    d.ellipse((12,15,21,21),fill='#86a9be')
    d.line((15,20,18,20),fill='#b6c7c7',width=1)
    d.point((19,17),fill='#383d45')
    d.line([(22,18),(21,19),(20,19)],fill='#929ba3',width=1)


def cars(d):
    # Front view: mirror-symmetric body, wheels, windshield and headlights.
    d.rectangle((3,16,6,21),fill='#555964')
    d.rectangle((17,16,20,21),fill='#555964')
    d.polygon([(7,3),(16,3),(18,5),(20,10),(21,11),(21,18),
               (2,18),(2,11),(3,10),(5,5)],fill='#aa624c')
    d.line((7,4,16,4),fill='#d99a84',width=1)
    d.polygon([(7,5),(16,5),(18,10),(5,10)],fill='#86a9be')
    d.line((8,6,15,6),fill='#b6c7c7',width=1)
    d.rectangle((3,11,20,12),fill='#bd7669')
    d.rectangle((4,13,7,15),fill='#e6dfcd')
    d.rectangle((16,13,19,15),fill='#e6dfcd')
    d.rectangle((10,14,13,15),fill='#555964')
    d.rectangle((9,17,14,18),fill='#adb3ba')


def astronomy(d):
    # A true circular planet and a tilted elliptical ring, sampled on the native grid.
    angle=radians(-25)
    c,s=cos(angle),sin(angle)
    ring={}
    for y in range(24):
        for x in range(24):
            dx,dy=x-11.5,y-11.5
            u,v=dx*c+dy*s,-dx*s+dy*c
            if (u/11.5)**2+(v/3.6)**2<=1 and (u/9.4)**2+(v/1.5)**2>=1:
                ring[x,y]=v
                d.point((x,y),fill=(119,126,135,255))
    d.ellipse((4,4,19,19),fill='#d5ab66')
    mask=Image.new('L',(24,24))
    ImageDraw.Draw(mask).ellipse((4,4,19,19),fill=255)
    for y in (8,9,15,16):
        for x in range(24):
            if mask.getpixel((x,y)):
                d.point((x,y),fill=(196,152,101,255))
    # Only the near half crosses the face; the far half remains hidden behind it.
    for (x,y),v in ring.items():
        if v>=0:
            d.point((x,y),fill=(173,179,186,255))


def science(d):
    # Side view of a microscope: diagonal eyepiece, curved arm, stage and foot.
    d.polygon([(15,6),(18,7),(20,10),(20,15),(18,19),(14,21),
               (10,21),(10,18),(14,18),(17,15),(17,11),(15,9)],fill='#777e87')
    d.rectangle((4,20,20,22),fill='#777e87')
    d.rectangle((5,19,19,20),fill='#adb3ba')
    # Narrow optical tube and its darker eyepiece.
    d.polygon([(7,4),(10,2),(15,9),(12,11)],fill='#adb3ba')
    d.polygon([(5,4),(8,2),(10,4),(7,6)],fill='#555964')
    d.polygon([(12,10),(14,9),(16,12),(14,13)],fill='#555964')
    # The slide sits below the objective; a focusing knob is offset on the arm.
    d.rectangle((5,14,15,15),fill='#555964')
    d.rectangle((7,13,12,13),fill='#86a9be')
    d.ellipse((16,9,21,14),fill='#ab8054')
    d.rectangle((18,11,19,12),fill='#d5ab66')


def fashion(d):
    # Symmetric T-shirt: sleeves, a real neck opening, and a straight hem.
    d.polygon([(7,3),(9,3),(10,5),(13,5),(14,3),(16,3),
               (22,7),(19,12),(17,11),(17,21),(6,21),(6,11),(4,12),(1,7)],fill='#bd889c')
    d.polygon([(7,3),(9,3),(10,5),(13,5),(14,3),(16,3),
               (14,7),(9,7)],fill='#9d6e82')
    d.line((3,8,5,10),fill='#d3a6b5',width=1)
    d.line((20,8,18,10),fill='#d3a6b5',width=1)
    d.line((7,20,16,20),fill='#d3a6b5',width=1)


def board_games(d):
    # Two clean square dice, offset diagonally so both faces remain readable.
    d.rounded_rectangle((11,2,22,13),radius=1,fill='#d5ab66',outline='#ab8054',width=1)
    for x,y in [(14,5),(18,5),(14,9),(18,9)]:
        d.rectangle((x,y,x+1,y+1),fill='#51473e')
    # Front die: five centered pips and the same single-pixel frame.
    d.rounded_rectangle((2,10,13,21),radius=1,fill='#adb3ba',outline='#7b7b76',width=1)
    for x,y in [(4,12),(10,12),(7,15),(4,18),(10,18)]:
        d.rectangle((x,y,x+1,y+1),fill='#555964')


def coffee(d):
    # Soft steam, with matching wisps above the cup.
    for x in (9,14):
        d.line([(x,6),(x,5),(x-1,4),(x-1,2)],fill='#a3a69a',width=1)
    # A two-pixel handle behind the vessel, with a transparent opening.
    d.polygon([(18,10),(20,10),(22,12),(22,14),(20,16),(18,16)],fill='#869b9d')
    d.rectangle((19,12,20,14),fill=(0,0,0,0))
    # Ceramic body, centered over its saucer.
    d.polygon([(5,9),(18,9),(18,16),(17,18),(16,19),(7,19),(6,18),(5,16)],fill='#869b9d')
    d.polygon([(6,10),(17,10),(17,16),(16,18),(7,18),(6,16)],fill='#b5c9c5')
    # Coffee visible inside the upper rim.
    d.rectangle((6,9,17,10),fill='#725d49')
    d.rectangle((7,9,16,9),fill='#51473e')
    d.line((7,12,7,15),fill='#d3dfd3')
    # The saucer shares the ceramic body's center at x=11.5.
    d.line((2,20,21,20),fill='#b5c9c5')
    d.line((4,21,19,21),fill='#869b9d')


EXTRA_ICONS = {
    'photography': photography,
    'drawing': drawing,
    'fishing': fishing,
    'cars': cars,
    'astronomy': astronomy,
    'science': science,
    'fashion': fashion,
    'board_games': board_games,
    'coffee': coffee,
}
