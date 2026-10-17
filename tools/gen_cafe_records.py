#!/usr/bin/env python3
"""Generate only the Cafe music corner, using its existing furniture palette."""
from PIL import Image, ImageDraw
from gen_cafe_sprites import OUT, P, canvas, box, save

COLORS = ['#7f9477', '#b87554', '#536e89', '#e6d6b4']


def console():
    im, d = canvas(28, 24)
    for x in (2, 24):
        box(d, (x, 14, x+1, 23), 'wood_outline')
        box(d, (x, 15, x, 22), 'wood_dark')
    box(d, (1, 3, 26, 19), 'wood_outline')
    box(d, (2, 4, 25, 10), 'wood_dark')
    d.line((2, 4, 25, 4), fill=P['wood'])
    box(d, (4, 12, 23, 16), '#302a25')
    d.line((4, 16, 23, 16), fill=P['wood_dark'])
    d.line((2, 18, 25, 18), fill=P['wood_grain'])
    save(im, 'record_console')


def player():
    # A shallow deck sits flat on the console; the spindle has no raised rim.
    im, d = canvas(20, 10)
    box(d, (0, 1, 19, 8), 'wood_outline')
    box(d, (1, 2, 18, 7), '#343b3a')
    d.line((1, 1, 18, 1), fill=P['wood_dark'])
    d.ellipse((2, 3, 9, 6), fill='#202827')
    d.point((5, 4), fill=P['steel'])
    d.point((17, 6), fill=P['sage_hi'])
    d.line((1, 8, 18, 8), fill=P['wood_grain'])
    save(im, 'record_player')
    arm, a = canvas(40, 10)
    for frame in range(2):
        x=frame*20
        a.point((x+15, 2), fill=P['steel'])
        a.line((x+15, 3, x+(10 if frame else 15), 5 if frame else 6), fill=P['silver'])
        box(a, (x+(9 if frame else 14), 5 if frame else 6, x+(10 if frame else 16), 6 if frame else 7), 'steel')
    save(arm, 'record_tonearm')


def record_table():
    im, d = canvas(28, 24)
    for x in (3, 23):
        box(d, (x, 17, x+1, 23), 'wood_outline')
        d.line((x, 18, x, 22), fill=P['wood_dark'])
    box(d, (1, 0, 26, 18), 'wood_outline')
    box(d, (2, 1, 25, 15), 'wood_dark')
    d.line((2, 1, 25, 1), fill=P['wood'])
    d.line((2, 3, 2, 14), fill='#806044')
    d.line((5, 8, 22, 8), fill=P['wood_grain'])
    d.line((8, 14, 24, 14), fill=P['wood_grain'])
    d.line((2, 16, 25, 16), fill=P['wood_grain'])
    save(im, 'record_table')
    covers, c = canvas(40, 10)
    for i, color in enumerate(COLORS):
        x=i*10
        box(c, (x, 0, x+9, 9), color)
        c.line((x+1, 1, x+8, 1), fill=P['cream'])
        if i==0:
            c.line((x+3, 7, x+6, 3), fill=P['cream'])
            c.polygon([(x+3, 5), (x+3, 3), (x+5, 4)], fill=P['cream'])
            c.polygon([(x+5, 6), (x+7, 4), (x+7, 6)], fill=P['cream'])
        elif i==1:
            c.ellipse((x+3, 3, x+6, 6), fill=P['cream'])
            for point in [(x+4, 2), (x+4, 8), (x+1, 5), (x+8, 5)]:
                c.point(point, fill=P['cream'])
        elif i==2:
            c.ellipse((x+2, 3, x+6, 7), fill=P['cream'])
            c.ellipse((x+4, 2, x+7, 6), fill=color)
            c.point((x+8, 3), fill=P['cream'])
        else:
            c.polygon([(x+2, 7), (x+5, 3), (x+8, 7)], fill=P['wood_dark'])
            c.line((x+2, 3, x+4, 3), fill=P['wood_dark'])
    # Sleeves lie flat on the tabletop in the same perspective as the furniture.
    save(covers.resize((40, 6), Image.Resampling.NEAREST), 'record_covers')


def records():
    im, d = canvas(40, 10)
    for i, color in enumerate(COLORS):
        x=i*10
        d.ellipse((x, 0, x+9, 9), fill='#171e1f', outline='#434c4b')
        d.ellipse((x+2, 2, x+7, 7), outline='#303938')
        d.ellipse((x+3, 3, x+6, 6), fill=color)
        d.point((x+4, 4), fill=P['cream'])
    save(im, 'records')
    platter()


def platter():
    im, p = canvas(32, 16)
    for i, color in enumerate(COLORS):
        for phase in range(4):
            px=i*8; py=phase*4
            p.ellipse((px, py, px+7, py+3), fill='#171e1f')
            p.rectangle((px+2, py+1, px+5, py+2), fill=color)
            dx,dy=[(3,1), (5,1), (4,2), (2,2)][phase]
            p.point((px+dx,py+dy), fill=P['cream'])
    save(im, 'record_platter')


if __name__ == '__main__':
    OUT.mkdir(parents=True, exist_ok=True)
    console(); player(); record_table(); records()
