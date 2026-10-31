#!/usr/bin/env python3
"""Reproduce the approved barber fixtures and seamless interior surfaces."""
from PIL import Image, ImageDraw
from gen_clothing_store_sprites import SPRITES, WHITE, FRAME, GLASS

OUT = SPRITES / 'barber'


def floor() -> Image.Image:
    image = Image.new('RGBA', (32, 32))
    d = ImageDraw.Draw(image)
    for row in range(2):
        for column in range(2):
            x, y = column * 16, row * 16
            d.rectangle((x, y, x + 15, y + 15), fill=('#b7bcb5', '#c4c8bf')[(row + column) % 2])
            d.line((x, y + 15, x + 15, y + 15), fill='#a9afa6')
            d.line((x + 15, y, x + 15, y + 15), fill='#a9afa6')
    return image


def wall() -> Image.Image:
    image = Image.new('RGBA', (32, 32), '#dedfd1')
    d = ImageDraw.Draw(image)
    d.rectangle((0, 23, 31, 29), fill='#9ca99b')
    d.line((0, 22, 31, 22), fill='#b6c1ac')
    d.rectangle((0, 30, 31, 31), fill='#6f7f73')
    return image


def chair() -> Image.Image:
    image = Image.new('RGBA', (18, 24))
    d = ImageDraw.Draw(image)
    d.rectangle((7, 14, 10, 21), fill='#6d7874')
    d.ellipse((3, 20, 14, 23), fill='#87928b')
    d.rectangle((3, 7, 14, 15), fill='#929b86')
    d.rectangle((2, 1, 15, 8), fill='#7f8976')
    d.line((3, 1, 14, 1), fill='#a1a994')
    for x in (0, 15):
        d.rectangle((x, 8, x + 2, 15), fill='#6d7874')
    d.line((4, 17, 13, 17), fill='#a0aaa3')
    return image


def barber() -> Image.Image:
    image = Image.open(SPRITES / 'clothing_store/clerk.png').convert('RGBA')
    d = ImageDraw.Draw(image)
    for x in (0, 12):
        d.rectangle((x, 0, x + 11, 7), fill=(0, 0, 0, 0))
        d.rectangle((x + 3, 2, x + 8, 7), fill='#ecc295')
        d.polygon([(x + dx, y) for dx, y in [(2, 2), (3, 2), (3, 1), (5, 1),
                  (5, 0), (8, 0), (8, 1), (9, 1), (9, 3), (8, 3), (8, 2),
                  (6, 2), (6, 3), (3, 3), (3, 4), (2, 4)]], fill='#bd753c')
        d.line((x + 2, 3, x + 2, 4), fill='#955c40')
        d.line((x + 5, 1, x + 7, 1), fill='#c7a368')
        if x == 0:
            d.point((x + 4, 5), fill='#584638')
            d.point((x + 7, 5), fill='#584638')
        d.rectangle((x + 3, 8, x + 8, 15), fill='#e2dfce')
        for strap in (3, 8):
            d.line((x + strap, 8, x + strap, 12), fill='#494c4a')
        d.rectangle((x + 3, 11, x + 8, 16), fill='#494c4a')
        d.line((x + 4, 14, x + 7, 14), fill='#70756f')
        d.point((x + 2, 13), fill='#bcc4b9')
        right_leg = image.crop((x + 6, 17, x + 12, 20))
        image.paste(right_leg.transpose(Image.Transpose.FLIP_LEFT_RIGHT), (x, 17))
    return image


def scissors() -> Image.Image:
    image = Image.new('RGBA', (16, 16))
    d = ImageDraw.Draw(image)
    for x in (0, 9):
        d.ellipse((x, 9, x + 6, 15), outline=WHITE, width=2)
    d.line((4, 10, 13, 0), fill=WHITE, width=2)
    d.line((11, 10, 2, 0), fill=WHITE, width=2)
    d.point((8, 7), fill='#6d7874')
    return image


def window() -> Image.Image:
    image = Image.new('RGBA', (32, 24), FRAME)
    d = ImageDraw.Draw(image)
    d.rectangle((1, 1, 30, 22), fill=GLASS)
    d.line((3, 4, 3, 19), fill=(255, 249, 231, 42))
    d.polygon(((4, 3), (10, 3), (4, 10)), fill=(255, 249, 231, 38))
    return image


def hairstyle_photo() -> Image.Image:
    image = Image.new('RGBA', (14, 14), FRAME)
    d = ImageDraw.Draw(image)
    d.rectangle((1, 1, 12, 12), fill=WHITE)
    d.rectangle((2, 2, 11, 11), fill='#bcc4b9')
    head = Image.open(SPRITES / 'characters/player.png').convert('RGBA').crop((0, 80, 12, 88))
    hair = Image.open(SPRITES / 'characters/hair_3.png').convert('RGBA').crop((0, 80, 12, 88))
    palette = {
        (64, 64, 64, 255): (38, 27, 21, 255),
        (112, 112, 112, 255): (57, 41, 31, 255),
        (176, 176, 176, 255): (73, 52, 40, 255),
        (224, 224, 224, 255): (106, 88, 79, 255),
    }
    pixels = (hair.getpixel((x, y)) for y in range(hair.height) for x in range(hair.width))
    hair.putdata([palette.get(pixel, pixel) for pixel in pixels])
    image.alpha_composite(head, (1, 3))
    image.alpha_composite(hair, (1, 3))
    return image


def generate() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    for name, draw in {'floor': floor, 'wall': wall, 'chair': chair, 'barber': barber, 'scissors': scissors, 'window': window, 'hairstyle_photo': hairstyle_photo}.items():
        draw().save(OUT / (name + '.png'))


if __name__ == '__main__':
    generate()
