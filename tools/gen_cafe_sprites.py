#!/usr/bin/env python3
"""Reproduce only Cafe textures. Run from any working directory with Pillow."""
from pathlib import Path
from PIL import Image, ImageDraw

OUT = Path(__file__).resolve().parents[1] / 'assets/sprites/cafe'
P = dict(ink='#3f463d', cream='#eee4ce', white='#fff9e9', sage='#7f9477',
         sage_hi='#a8b89a', sage_dark='#50664f', wood='#9c7149', wood_hi='#c39b67',
         wood_dark='#644b36', wood_outline='#3d3027', wood_grain='#715239',
         grout='#b7ab94', steel='#9baaa6', silver='#d9e1d8',
         coffee='#563526', shadow='#6c5d4d', skin='#d4a67b', hair='#47392f')

def canvas(w,h):
    im=Image.new('RGBA',(w,h));return im,ImageDraw.Draw(im)

def box(d,xy,c): d.rectangle(xy,fill=P.get(c,c))
def save(im,name): im.save(OUT / (name+'.png'))

def tiles(name,base,accent):
    im,d=canvas(32,32);box(d,(0,0,31,31),base)
    for x in (0,16):
        for y in (0,16):
            box(d,(x+1,y+1,x+15,y+15),accent if (x+y)%32==0 else base)
            d.line((x,y,x+15,y),fill=P['grout']);d.line((x,y,x,y+15),fill=P['grout'])
            d.point((x+2,y+2),fill=P['white'])
    save(im,name)

def wall(name,w,h):
    im,d=canvas(w,h);box(d,(0,0,w-1,h-1),'cream')
    for y in range(3,h-8,7):
        d.line((0,y,w-1,y), fill='#e5dac3')
        for x in range((y//7%2)*8,w,16): d.point((x,y-2),fill='#d9ccb3')
    box(d,(0,h-9,w-1,h-1),'wood');box(d,(0,h-9,w-1,h-8),'wood_hi')
    for x in range(0,w,8): d.line((x,h-7,x,h-2),fill=P['wood_dark'])
    box(d,(0,h-2,w-1,h-1),'wood_dark')
    save(im,name)

def facade_brick():
    """Seamless 64x32 exterior tile shared by Cafe and its neighbouring houses."""
    im,d=canvas(64,32)
    box(d,(0,0,63,31),'#9e9b92')
    shades=('#b6b1a5','#b9b4a8','#b2aea3','#b7b3a8','#b4afa3')
    for row in range(4):
        y=row*8
        offset=(row%2)*8
        for column in range(-1,5):
            x=column*16+offset
            color=shades[(row*3+(column%4)*2)%len(shades)]
            box(d,(x+1,y+1,x+15,y+7),color)
            d.line((x+2,y+1,x+14,y+1),fill='#c0bbaf')
            d.point((x+5,y+4),fill='#aba79d')
            d.point((x+11,y+6),fill='#bdb8ac')
    save(im,'facade_brick')

def roof_tiles():
    """Seamless graphite shingles, with staggered plates and soft upper edges."""
    im,d=canvas(32,24)
    box(d,(0,0,31,23),'#303941')
    shades=('#59636c','#56616a','#5e6871','#5b666f')
    for row in range(4):
        y=row*6
        offset=(row%2)*4
        for column in range(-1,5):
            x=column*8+offset
            box(d,(x+1,y,x+7,y+4),shades[(row+column%4)%4])
            d.line((x+1,y+1,x+6,y+1),fill='#77818a')
            d.line((x+1,y+4,x+7,y+4),fill='#434e57')
            d.point((x+7,y+3),fill='#4c5760')
    save(im,'roof_tiles')

def table():
    """Square dark-wood cafe table in perspective, preserving its 24x16 anchor."""
    im,d=canvas(24,16)
    outline=P['wood_outline']
    # Straight legs remain visible below the thin front edge.
    box(d,(3,10,5,15),outline);box(d,(18,10,20,15),outline)
    d.line((4,11,4,14),fill=P['wood_dark'])
    d.line((19,11,19,14),fill=P['wood_dark'])
    box(d,(1,0,22,11),outline)
    box(d,(2,1,21,9),'wood_dark')
    d.line((2,1,21,1),fill=P['wood'])
    d.line((2,2,2,8),fill='#806044')
    d.line((4,4,18,4),fill=P['wood_grain'])
    d.line((7,7,20,7),fill=P['wood_grain'])
    d.line((2,10,21,10),fill='#4e392b')
    save(im,'table')

def chair():
    """14x16 frames: south free/taken, then north free/taken, as Chair expects."""
    im,d=canvas(56,16)
    for frame in range(4):
        x=frame*14
        north=frame>=2
        occupied=frame%2==1
        for leg in (2,10):
            box(d,(x+leg,10,x+leg+1,15),'wood_outline')
            d.line((x+leg,12,x+leg,14),fill=P['wood_dark'])
        if north:
            # The backrest hides the seat in both occupancy frames.
            box(d,(x+2,3,x+11,11),'wood_outline')
            box(d,(x+3,4,x+10,10),'wood_dark')
            d.line((x+3,4,x+10,4),fill=P['wood'])
            d.line((x+4,7,x+9,7),fill=P['wood_grain'])
        else:
            box(d,(x+2,1,x+11,8),'wood_outline')
            box(d,(x+3,2,x+10,7),'wood_dark')
            d.line((x+3,2,x+10,2),fill=P['wood'])
            d.line((x+4,5,x+9,5),fill=P['wood_grain'])
            box(d,(x+1,8,x+12,11),'wood_outline')
            box(d,(x+2,8,x+11,10),'wood_dark')
            d.line((x+2,8,x+11,8),fill=P['wood_grain' if occupied else 'wood'])
    save(im,'chair')

def bench():
    """Dark wooden slats on a graphite frame, retaining the street bench anchor."""
    im,d=canvas(42,16)
    metal='#414b54'
    for x in (4,36):
        box(d,(x,3,x+1,15),metal)
        d.line((x,11,x,14),fill='#657078')
    for y in (0,4):
        box(d,(2,y,39,y+2),'wood_outline')
        d.line((3,y,38,y),fill=P['wood'])
        d.line((3,y+1,38,y+1),fill=P['wood_dark'])
    box(d,(1,8,40,11),'wood_outline')
    d.line((2,8,39,8),fill=P['wood'])
    d.line((2,9,39,9),fill=P['wood_dark'])
    for x in (0,39):
        box(d,(x,6,x+2,11),metal)
        d.line((x,6,x+2,6),fill='#657078')
    save(im,'bench')

def window():
    """Flat sage frame with the existing warm translucent glass and reflections."""
    im,d=canvas(24,24)
    box(d,(0,0,23,23),'sage')
    for x in (2,13):
        box(d,(x,2,x+8,21),(230,194,122,58))
        d.line((x+1,4,x+1,17),fill=(255,238,200,90))
        d.line((x+2,4,x+5,4),fill=(255,238,200,65))
    save(im,'window')

def house_windows():
    """Two 16x24 glass frames, with separate interiors for non-enterable houses."""
    im,d=canvas(32,24)
    interior,backing=canvas(32,24)
    for frame in range(2):
        x=frame*16
        box(d,(x,0,x+15,23),'sage')
        for left,right in ((2,6),(9,13)):
            box(d,(x+left,2,x+right,21),(230,194,122,58))
            d.line((x+left+1,4,x+left+1,17),fill=(255,238,200,90))
            d.line((x+left+2,4,x+right,4),fill=(255,238,200,65))
            box(backing,(x+left,2,x+right,21),'#424a43' if frame==0 else '#bda77f')
            box(backing,(x+left,18,x+right,21),'#3d453e' if frame==0 else '#a6916d')
    save(im,'house_window')
    save(interior,'house_window_backing')

def barista():
    im,d=canvas(24,20)
    for f in range(2):
        x=f*12
        box(d,(x+3,8,x+8,16),'sage_dark');box(d,(x+4,9,x+7,15),'sage')
        box(d,(x+2,8,x+2,12),'cream');box(d,(x+9,8,x+9,12),'cream')
        box(d,(x+2,12,x+2,14),'skin');box(d,(x+9,12,x+9,14),'skin')
        box(d,(x+3,2,x+8,7),'skin');box(d,(x+3,1,x+8,2),'hair')
        d.point((x+4,4),fill=P['ink']);d.point((x+7,4),fill=P['ink'])
        d.line((x+5,7,x+6,7),fill='#925e48')
        d.line((x+4,9,x+4,11),fill=P['sage_hi']);d.line((x+7,9,x+7,11),fill=P['sage_hi'])
        box(d,(x+5,12,x+7,13),'sage_dark')
        if f:
            box(d,(x+9,8,x+10,10),'white');d.point((x+10,7),fill=P['coffee'])
        box(d,(x,17,x+11,19),'wood_dark');box(d,(x,16,x+11,17),'wood_hi')
    save(im,'barista')

def machine():
    """Compact machine at rest: empty drip tray, no cup, liquid or steam."""
    im,d=canvas(20,18)
    box(d,(1,1,18,16),'ink')
    box(d,(2,2,17,8),'steel');d.line((2,2,17,2),fill=P['silver'])
    d.point((13,5),fill=P['sage_hi']);d.point((16,5),fill=P['cream'])
    box(d,(6,7,9,9),'silver');box(d,(9,9,14,10),'wood_outline')
    d.line((16,10,16,14),fill=P['silver'])
    d.point((15,14),fill=P['silver'])
    d.line((2,16,17,16),fill=P['steel'])
    save(im,'coffee_machine')

def coffee():
    # Reduce both layers on the same pixel grid; no per-drink runtime scaling.
    frame_size=(7,8)
    cup,d=canvas(10,12)
    box(d,(2,3,6,9),'silver');box(d,(1,2,7,7),'white')
    d.line((1,3,1,7),fill=P['silver']);d.line((2,9,6,9),fill='#afb9ab')
    d.line((7,3,9,3),fill=P['white']);d.line((9,3,9,6),fill=P['white']);d.line((7,6,9,6),fill=P['white'])
    d.line((1,10,8,10),fill=P['silver']);d.line((2,11,7,11),fill=P['shadow'])
    save(cup.resize(frame_size,Image.Resampling.NEAREST),'coffee_cup')
    im,d=canvas(30,60)
    for f,color in enumerate(['#643d27','#382d25','#d8b78a']):
        for part in range(5):
            x=f*10;y=part*12
            if part<4:
                box(d,(x+2,y+2+part//2,x+6,y+4),color)
                d.line((x+3,y+2+part//2,x+5,y+2+part//2),fill='#ad8150' if f<2 else '#fff2d3')
            else: box(d,(x+2,y+3,x+6,y+4),'silver')
    save(im.resize((frame_size[0]*3,frame_size[1]*5),Image.Resampling.NEAREST),'coffee')

def sink():
    im,d=canvas(120,24)
    for f in range(6):
        x=f*20
        box(d,(x+3,15,x+16,23),'wood_dark');box(d,(x+4,16,x+15,22),'wood')
        box(d,(x+9,16,x+10,22),'wood_dark');d.point((x+8,18),fill=P['silver']);d.point((x+11,18),fill=P['silver'])
        box(d,(x+1,8,x+18,15),'silver');box(d,(x+2,7,x+17,13),'white')
        box(d,(x+4,9,x+15,11),'steel');box(d,(x+5,9,x+14,10),'cream')
        # Symmetric front view: the spout, stream and drain share the centre axis.
        box(d,(x+9,2,x+10,7),'steel');box(d,(x+8,2,x+11,3),'silver')
        box(d,(x+9,5,x+10,6),'silver');box(d,(x+9,11,x+10,11),'steel')
        d.point((x+5,6),fill=P['silver']);d.point((x+14,6),fill=P['silver'])
        if f:
            box(d,(x+9,7,x+10,10),'#a3d5d4')
            for a in range(2):
                y=10+((f+a)%2)
                d.point((x+6+a*2,y),fill='#d7f3ec')
                d.point((x+13-a*2,y),fill='#d7f3ec')
    save(im,'wc_sink')

def trash():
    im,d=canvas(12,17)
    box(d,(2,4,9,15),'sage_dark');box(d,(3,5,8,14),'sage');d.line((3,6,3,13),fill=P['sage_hi'])
    box(d,(1,2,10,4),'ink');box(d,(2,1,9,2),'sage_dark');box(d,(4,14,7,15),'steel')
    d.line((3,16,8,16),fill=P['ink']);save(im,'wc_trash')

def cabin():
    im,d=canvas(28,30)
    # Side partition, running from the left wall to the open entrance on the right.
    box(d,(0,2,27,26),'sage_dark');box(d,(1,3,25,25),'sage')
    box(d,(1,3,25,4),'sage_hi')
    for x in (9,18):
        d.line((x,5,x,25),fill=P['sage_dark'])
        d.line((x+1,5,x+1,25),fill=P['sage_hi'])
    # Thin metal coping and end profile, without a door frame or handle.
    box(d,(0,0,27,1),'steel');d.line((1,0,26,0),fill=P['silver'])
    box(d,(26,2,27,26),'steel');d.line((26,3,26,25),fill=P['silver'])
    d.line((0,26,27,26),fill=P['steel'])
    for x in (2,24):
        box(d,(x,27,x+1,29),'ink');d.point((x,27),fill=P['steel'])
    save(im,'wc_cabin')

def open_door_frame(im,d):
    """A 16x28 opening with a one-pixel sage frame on all four sides."""
    box(d,(32,0,47,27),'sage')
    box(d,(33,1,46,26),(0,0,0,0))
    leaf=im.crop((0,0,16,28)).transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    im.paste(leaf,(48,0))

def door():
    """Flat solid WC leaf; two 32x28 frames, with real transparent passage."""
    im,d=canvas(64,28)
    box(d,(0,0,15,27),'sage')
    d.point((12,18),fill=P['silver'])
    open_door_frame(im,d)
    save(im,'wc_door')

def entrance_door():
    """Glazed sage entrance; preserve the closed leaf and use a 1px open frame."""
    im,d=canvas(64,28)
    box(d,(0,0,15,27),'sage')
    box(d,(3,3,12,22),(230,194,122,58))
    d.line((4,5,4,18),fill=(255,238,200,90))
    d.line((5,5,8,5),fill=(255,238,200,65))
    box(d,(12,15,13,18),'steel')
    d.line((12,15,12,17),fill=P['silver'])
    open_door_frame(im,d)
    save(im,'entrance_door')

def sign():
    im,d=canvas(48,22);box(d,(0,0,47,21),'wood_dark');box(d,(1,1,46,20),'wood_hi');box(d,(2,2,45,19),'sage_dark')
    letters={'C':['111','100','100','100','111'],'A':['010','101','111','101','101'],'F':['111','100','110','100','100'],'E':['111','100','110','100','111']}
    x=9
    for char in 'CAFE':
        for y,row in enumerate(letters[char]):
            for i,b in enumerate(row):
                if b=='1':box(d,(x+i*2,6+y*2,x+i*2+1,7+y*2),'cream')
        x+=8
    d.line((36,3,38,2),fill=P['cream']);save(im,'cafe_sign')

def menu():
    """Native 14x11 chalkboard, displayed at unit scale in the Cafe."""
    im,d=canvas(14,11)
    box(d,(0,0,13,10),'wood_outline')
    d.line((0,0,13,0),fill=P['wood'])
    d.line((0,1,0,9),fill=P['wood_dark'])
    box(d,(1,1,12,9),'#29332f')
    # Short chalk marks suggest a heading, a cup and three menu rows.
    d.line((2,2,5,2),fill='#e3e0cb')
    d.point((7,2),fill='#b9c3af')
    d.line((9,2,11,2,11,3,9,3,9,2),fill='#cdd1bd')
    d.line((2,4,11,4),fill='#829681')
    for y,end in [(5,6),(7,7),(9,5)]:
        d.line((2,y,end,y),fill='#d5d8c4')
        d.point((4,y),fill='#9ba994')
        d.line((10,y,11,y),fill='#ddd3b3')
    save(im,'menu')

def main():
    OUT.mkdir(parents=True,exist_ok=True)
    tiles('floor','#d7c8ad','#e1d5be');tiles('wc_floor','#dfd8c4','#eae4d4')
    wall('wall',32,32);wall('wc_wall',32,42)
    facade_brick();roof_tiles();table();chair();bench();window();house_windows();barista();machine();coffee();sink();trash();cabin();door();entrance_door();sign();menu()
    print('Generated 23 Cafe textures in',OUT)

if __name__=='__main__':main()
