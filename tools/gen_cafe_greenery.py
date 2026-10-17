#!/usr/bin/env python3
"""Reproduce only Cafe street greenery at its native world-pixel dimensions."""
from pathlib import Path
from random import Random

from PIL import Image, ImageChops, ImageDraw, ImageFilter

OUT = Path(__file__).resolve().parents[1] / 'assets/sprites/cafe'
LEAVES = ['#50643b', '#667e42', '#82974c', '#a0b35d', '#bec975']


def foliage(size, lobes, seed):
    rng = Random(seed)
    mask = Image.new('L', size)
    draw = ImageDraw.Draw(mask)
    for bounds in lobes:
        draw.ellipse(bounds, fill=255)
    im = Image.new('RGBA', size, LEAVES[0])
    d = ImageDraw.Draw(im)
    for x0,y0,x1,y1 in lobes:
        d.ellipse((x0+1,y0+1,x1-1,y1-2), fill=LEAVES[1])
        d.ellipse((x0+2,y0+1,x1-3,(y0+y1)//2+1), fill=LEAVES[2])
    for _ in range(size[0]*size[1]//35):
        x,y = rng.randrange(size[0]),rng.randrange(size[1])
        w,h = rng.randrange(2,5),rng.randrange(1,4)
        # Short, stepped leaf clusters follow the shared pixel grid.
        color = rng.choice(LEAVES[1:4] if y>size[1]*0.65 else LEAVES[2:])
        d.rectangle((x,y,x+w,y+h),fill=color)
        d.point((x+w+1,y+1),fill=color)
    inner = mask.filter(ImageFilter.MinFilter(3))
    edge = ImageChops.subtract(mask,inner)
    im.paste(LEAVES[0],mask=edge)
    im.putalpha(mask)
    return im


def tree():
    im = Image.new('RGBA',(64,84))
    d = ImageDraw.Draw(im)
    d.polygon([(29,47),(34,47),(35,76),(39,82),(34,82),(32,80),
               (29,83),(25,83),(29,76)],fill='#705737')
    d.line((31,53,31,77,28,81),fill='#b18a51',width=2)
    d.line((33,59,33,76,35,80),fill='#8b6840')
    d.line((31,66,20,54),fill='#705737',width=3)
    d.line((33,62,44,48),fill='#705737',width=3)
    canopy = foliage((64,68),[(17,1,43,29),(6,12,34,41),(31,10,54,37),
                             (1,28,27,53),(20,24,49,54),(40,27,62,51),
                             (8,43,36,65),(31,42,55,63)],41)
    im.alpha_composite(canopy)
    im.save(OUT/'street_tree.png')


def tree_bed():
    im = Image.new('RGBA',(24,10))
    d = ImageDraw.Draw(im)
    # Low stone surround, with a one-pixel top edge and shallow front face.
    d.rectangle((0,0,23,9),fill='#6c7362')
    d.rectangle((1,1,22,7),fill='#9d9d89')
    d.rectangle((2,2,21,6),fill='#756043')
    d.line((1,0,22,0),fill='#c0b99e')
    d.line((1,8,22,8),fill='#8a8d76')
    for x in (7,16):
        d.point((x,0),fill='#8a8d76')
        d.point((x,8),fill='#6c7362')
    # Exposed soil remains visible around the central trunk; grass hugs the rim.
    for x,y in [(3,3),(5,5),(8,2),(17,3),(20,5),(16,6),(4,6)]:
        d.line((x,y,x+1,y),fill='#8c9d52')
        d.point((x,y-1),fill='#a9b564')
    d.point((10,5),fill='#99805a')
    d.point((14,3),fill='#99805a')
    im.save(OUT/'street_tree_bed.png')


def shrub():
    im = Image.new('RGBA',(26,15))
    d = ImageDraw.Draw(im)
    d.rectangle((0,10,25,14),fill='#343c35')
    d.line((1,11,24,11),fill='#717663')
    d.rectangle((1,12,24,13),fill='#4a5145')
    leaves = foliage((26,11),[(1,3,9,10),(6,0,15,10),(13,2,23,10),
                              (19,5,25,10)],17)
    im.alpha_composite(leaves)
    im.save(OUT/'street_shrub.png')


if __name__=='__main__':
    OUT.mkdir(parents=True,exist_ok=True)
    tree(); tree_bed(); shrub()
    print('Generated 3 Cafe greenery textures in',OUT)
