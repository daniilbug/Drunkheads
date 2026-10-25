#!/usr/bin/env python3
"""Reproduce packaged groceries and loose produce at native resolution."""

from pathlib import Path
from PIL import Image, ImageDraw

OUTPUT = Path(__file__).resolve().parents[1] / "assets/sprites/grocery/products"


def bread() -> Image.Image:
    sprite = Image.new('RGBA', (8, 5))
    d = ImageDraw.Draw(sprite)
    d.rectangle((1, 0, 6, 0), fill='#bd925f')
    d.rectangle((0, 1, 7, 2), fill='#a4774c')
    d.rectangle((0, 3, 7, 3), fill='#815d3f')
    d.rectangle((1, 4, 6, 4), fill='#815d3f')
    d.rectangle((3, 0, 4, 4), fill='#dfd0a5')
    d.line((3, 0, 4, 0), fill='#ebe0bf')
    d.point((1, 1), fill='#d0a671')
    d.point((6, 1), fill='#c89a62')
    return sprite


def baton() -> Image.Image:
    sprite = Image.new('RGBA', (10, 4))
    d = ImageDraw.Draw(sprite)
    d.rectangle((2, 0, 7, 0), fill='#e5c993')
    d.rectangle((1, 1, 8, 1), fill='#dfbf82')
    d.rectangle((0, 2, 9, 2), fill='#d2ab6d')
    d.rectangle((1, 3, 8, 3), fill='#bd955e')
    for x in (2, 4, 6):
        d.line((x, 1, x + 1, 0), fill='#a7804e')
    return sprite


def bun() -> Image.Image:
    sprite = Image.new('RGBA', (6, 5))
    d = ImageDraw.Draw(sprite)
    d.rectangle((2, 0, 3, 0), fill='#e0ba78')
    d.rectangle((1, 1, 4, 1), fill='#d8ad69')
    d.rectangle((0, 2, 5, 2), fill='#d3a15e')
    d.rectangle((0, 3, 5, 3), fill='#bc8b50')
    d.rectangle((1, 4, 4, 4), fill='#b3824b')
    d.point((2, 1), fill='#eee0b3')
    d.point((4, 2), fill='#eee0b3')
    return sprite


def pasta() -> Image.Image:
    sprite = Image.new('RGBA', (5, 7))
    d = ImageDraw.Draw(sprite)
    d.rectangle((0, 0, 4, 0), fill='#ac7251')
    d.rectangle((0, 1, 4, 5), fill='#bd885a')
    d.rectangle((0, 6, 4, 6), fill='#ac7251')
    d.rectangle((1, 1, 3, 2), fill='#e4d8af')
    d.rectangle((1, 3, 3, 5), fill='#d9be73')
    d.line((1, 3, 1, 5), fill='#ecd18a')
    d.line((3, 3, 3, 5), fill='#ecd18a')
    d.point((2, 4), fill='#c49b51')
    return sprite


def rice() -> Image.Image:
    sprite = Image.new('RGBA', (5, 6))
    d = ImageDraw.Draw(sprite)
    d.rectangle((1, 0, 3, 0), fill='#97a68b')
    d.rectangle((0, 1, 4, 4), fill='#e5dfc3')
    d.rectangle((0, 5, 4, 5), fill='#7f987c')
    d.rectangle((1, 1, 3, 1), fill='#7f987c')
    d.rectangle((1, 3, 3, 4), fill='#b9c2a5')
    d.point((1, 3), fill='#f2ecd6')
    d.point((3, 3), fill='#f2ecd6')
    d.point((2, 4), fill='#f2ecd6')
    return sprite


def buckwheat() -> Image.Image:
    sprite = Image.new('RGBA', (5, 6))
    d = ImageDraw.Draw(sprite)
    d.rectangle((1, 0, 3, 0), fill='#a17b70')
    d.rectangle((0, 1, 4, 4), fill='#d8c9a7')
    d.rectangle((0, 5, 4, 5), fill='#98665c')
    d.rectangle((1, 1, 3, 1), fill='#98665c')
    d.rectangle((1, 3, 3, 4), fill='#9d8159')
    d.point((1, 3), fill='#b49a70')
    d.point((3, 3), fill='#7e6448')
    d.point((2, 4), fill='#c0a47b')
    return sprite


def oats() -> Image.Image:
    sprite = Image.new('RGBA', (6, 7))
    d = ImageDraw.Draw(sprite)
    d.rectangle((0, 0, 5, 6), fill='#91a4aa')
    d.line((0, 0, 5, 0), fill='#afbec0')
    d.rectangle((1, 1, 4, 5), fill='#e7dfbf')
    d.line((1, 1, 4, 1), fill='#c6d0c5')
    d.point((1, 3), fill='#c3a46e')
    d.point((3, 3), fill='#c3a46e')
    d.point((2, 4), fill='#d6bd87')
    d.point((4, 4), fill='#c3a46e')
    d.line((1, 6, 4, 6), fill='#7f969f')
    return sprite


def flour() -> Image.Image:
    sprite = Image.new('RGBA', (6, 7))
    d = ImageDraw.Draw(sprite)
    d.rectangle((1, 0, 4, 0), fill='#c5b58e')
    d.rectangle((0, 1, 5, 5), fill='#e9e0c5')
    d.rectangle((0, 6, 5, 6), fill='#c5ad80')
    d.line((1, 1, 4, 1), fill='#d6c6a1')
    d.line((3, 2, 3, 5), fill='#af945c')
    d.point((2, 2), fill='#c2a166')
    d.point((4, 3), fill='#c2a166')
    d.point((2, 4), fill='#c2a166')
    return sprite


def sugar() -> Image.Image:
    sprite = Image.new('RGBA', (5, 6))
    d = ImageDraw.Draw(sprite)
    d.rectangle((1, 0, 3, 0), fill='#a4bac0')
    d.rectangle((0, 1, 4, 4), fill='#ece9d9')
    d.rectangle((0, 5, 4, 5), fill='#88a9b6')
    d.line((1, 1, 3, 1), fill='#88a9b6')
    d.rectangle((1, 3, 2, 4), fill='#bcced0')
    d.point((1, 3), fill='#faf5e6')
    d.point((3, 2), fill='#b2c7cc')
    d.point((3, 3), fill='#faf5e6')
    return sprite


def salt() -> Image.Image:
    sprite = Image.new('RGBA', (4, 5))
    d = ImageDraw.Draw(sprite)
    d.rectangle((0, 0, 3, 4), fill='#e3e3d1')
    d.line((0, 0, 3, 0), fill='#647f98')
    d.line((0, 4, 3, 4), fill='#647f98')
    d.rectangle((1, 1, 2, 2), fill='#9bafb9')
    d.point((1, 1), fill='#f6f1df')
    d.point((2, 3), fill='#f6f1df')
    return sprite


def sunflower_oil() -> Image.Image:
    sprite = Image.new('RGBA', (4, 7))
    d = ImageDraw.Draw(sprite)
    d.rectangle((1, 0, 2, 0), fill='#70865f')
    d.rectangle((1, 1, 2, 1), fill='#cbb166')
    d.rectangle((0, 2, 3, 5), fill=(207, 174, 86, 220))
    d.rectangle((1, 2, 2, 3), fill=(230, 200, 113, 235))
    d.rectangle((1, 4, 2, 5), fill='#e8dfba')
    d.rectangle((1, 6, 2, 6), fill='#c4a159')
    return sprite


def canned_fish() -> Image.Image:
    sprite = Image.new('RGBA', (6, 4))
    d = ImageDraw.Draw(sprite)
    d.rectangle((1, 0, 4, 0), fill='#c0c9bd')
    d.rectangle((0, 1, 5, 2), fill='#809da6')
    d.rectangle((1, 3, 4, 3), fill='#a4b2a9')
    d.point((2, 0), fill='#8d9e98')
    d.line((1, 1, 2, 1), fill='#e8e1bf')
    d.point((3, 2), fill='#e8e1bf')
    d.point((4, 1), fill='#e8e1bf')
    return sprite


def stew() -> Image.Image:
    sprite = Image.new('RGBA', (6, 5))
    d = ImageDraw.Draw(sprite)
    d.rectangle((1, 0, 4, 0), fill='#c0c9bd')
    d.point((2, 0), fill='#8d9e98')
    d.rectangle((0, 1, 5, 3), fill='#a16c63')
    d.rectangle((1, 2, 4, 2), fill='#e8dfbc')
    d.rectangle((2, 3, 3, 3), fill='#d5cda9')
    d.rectangle((1, 4, 4, 4), fill='#a4b2a9')
    return sprite


def canned_peas() -> Image.Image:
    sprite = Image.new('RGBA', (6, 5))
    d = ImageDraw.Draw(sprite)
    d.rectangle((1, 0, 4, 0), fill='#c0c9bd')
    d.point((2, 0), fill='#8d9e98')
    d.rectangle((0, 1, 5, 3), fill='#809775')
    d.rectangle((1, 1, 4, 3), fill='#d9dfb9')
    d.point((2, 1), fill='#95ad77')
    d.point((3, 2), fill='#95ad77')
    d.point((1, 3), fill='#95ad77')
    d.rectangle((1, 4, 4, 4), fill='#a4b2a9')
    return sprite


def cookies() -> Image.Image:
    sprite = Image.new('RGBA', (7, 5))
    d = ImageDraw.Draw(sprite)
    d.rectangle((1, 0, 5, 4), fill='#c6a46a')
    d.rectangle((0, 1, 6, 3), fill='#d7b77c')
    d.line((1, 1, 1, 3), fill='#bd985e')
    d.line((5, 1, 5, 3), fill='#c6a46a')
    d.rectangle((2, 1, 4, 1), fill='#ede1bb')
    d.rectangle((2, 2, 4, 3), fill='#e4c890')
    d.point((2, 2), fill='#a98559')
    d.point((4, 3), fill='#a98559')
    return sprite


def chocolate() -> Image.Image:
    sprite = Image.new('RGBA', (5, 7))
    d = ImageDraw.Draw(sprite)
    d.rectangle((0, 0, 4, 6), fill='#996b71')
    d.line((0, 0, 4, 0), fill='#b18a88')
    d.line((0, 6, 4, 6), fill='#875d65')
    d.rectangle((1, 1, 3, 3), fill='#e8dfbc')
    d.point((2, 2), fill='#a27b60')
    d.rectangle((1, 4, 3, 5), fill='#76594d')
    d.point((1, 4), fill='#9b7962')
    d.point((3, 4), fill='#9b7962')
    return sprite


def chips() -> Image.Image:
    sprite = Image.new('RGBA', (6, 7))
    d = ImageDraw.Draw(sprite)
    d.rectangle((1, 0, 4, 6), fill='#b47964')
    d.rectangle((0, 1, 5, 5), fill='#c38a70')
    d.line((1, 0, 4, 0), fill='#d2a183')
    d.line((1, 6, 4, 6), fill='#a96d5c')
    d.rectangle((1, 1, 4, 2), fill='#e8dfbc')
    d.rectangle((1, 3, 2, 4), fill='#e0c17f')
    d.rectangle((3, 4, 4, 5), fill='#e7cb8c')
    d.point((1, 3), fill='#edda9e')
    d.point((3, 4), fill='#f0dca0')
    return sprite


def tea() -> Image.Image:
    sprite = Image.new('RGBA', (6, 6))
    d = ImageDraw.Draw(sprite)
    d.rectangle((0, 0, 5, 5), fill='#819776')
    d.line((0, 0, 5, 0), fill='#a3b18c')
    d.line((5, 1, 5, 5), fill='#72866b')
    d.rectangle((1, 1, 4, 4), fill='#e4dfbd')
    d.line((2, 3, 3, 2), fill='#8d9f74')
    d.point((2, 2), fill='#a7b587')
    d.line((1, 5, 4, 5), fill='#b5ba91')
    return sprite


def milk() -> Image.Image:
    sprite = Image.new('RGBA', (5, 8))
    d = ImageDraw.Draw(sprite)
    d.rectangle((1, 0, 3, 0), fill='#cad9d5')
    d.rectangle((0, 1, 4, 1), fill='#dce4d6')
    d.line((3, 0, 4, 1), fill='#a6bfbc')
    d.rectangle((0, 2, 4, 7), fill='#e8e9d9')
    d.line((4, 2, 4, 7), fill='#cad9d5')
    d.rectangle((0, 3, 3, 4), fill='#8eafb8')
    d.rectangle((1, 5, 2, 6), fill='#adc6c7')
    d.line((0, 7, 3, 7), fill='#9bb9c0')
    return sprite


def kefir() -> Image.Image:
    sprite = Image.new('RGBA', (5, 8))
    d = ImageDraw.Draw(sprite)
    d.rectangle((1, 0, 3, 0), fill='#819776')
    d.rectangle((1, 1, 3, 1), fill='#dce4d6')
    d.rectangle((0, 2, 4, 6), fill='#e8e9d9')
    d.rectangle((1, 7, 3, 7), fill='#d5dfce')
    d.line((4, 3, 4, 6), fill='#cad5c3')
    d.rectangle((0, 3, 3, 5), fill='#a3b68c')
    d.rectangle((1, 4, 2, 4), fill='#e8e9d9')
    return sprite


def yogurt() -> Image.Image:
    sprite = Image.new('RGBA', (5, 5))
    d = ImageDraw.Draw(sprite)
    d.line((0, 0, 4, 0), fill='#bd8e94')
    d.rectangle((0, 1, 4, 2), fill='#e8e4d7')
    d.rectangle((1, 3, 3, 4), fill='#dedecd')
    d.point((4, 2), fill='#cbd1c2')
    d.point((3, 4), fill='#cbd1c2')
    d.rectangle((1, 2, 3, 3), fill='#d6afb0')
    d.point((2, 2), fill='#a96f7b')
    d.point((2, 1), fill='#a2ad87')
    return sprite


def sour_cream() -> Image.Image:
    sprite = Image.new('RGBA', (6, 5))
    d = ImageDraw.Draw(sprite)
    d.line((0, 0, 5, 0), fill='#8eafb8')
    d.rectangle((0, 1, 5, 2), fill='#e8e9d9')
    d.rectangle((1, 3, 4, 4), fill='#dedfcf')
    d.point((5, 2), fill='#cad9d5')
    d.point((4, 4), fill='#cad5cd')
    d.rectangle((1, 2, 4, 3), fill='#afc8cb')
    d.line((2, 2, 3, 2), fill='#eef0df')
    return sprite


def cottage_cheese() -> Image.Image:
    sprite = Image.new('RGBA', (7, 4))
    d = ImageDraw.Draw(sprite)
    d.rectangle((1, 0, 5, 3), fill='#e8e9d9')
    d.rectangle((0, 1, 6, 2), fill='#d7ddd1')
    d.rectangle((2, 0, 4, 3), fill='#aaa0b2')
    d.rectangle((2, 1, 4, 2), fill='#e8e4d7')
    d.point((3, 1), fill='#c9bed0')
    d.line((1, 3, 5, 3), fill='#c9d1c4')
    d.point((3, 3), fill='#948a9e')
    return sprite


def cheese() -> Image.Image:
    sprite = Image.new('RGBA', (7, 5))
    d = ImageDraw.Draw(sprite)
    d.rectangle((2, 0, 5, 0), fill='#ead394')
    d.rectangle((1, 1, 6, 1), fill='#ead394')
    d.rectangle((0, 2, 6, 4), fill='#dfbf7c')
    d.line((0, 4, 6, 4), fill='#cdaa68')
    d.point((1, 2), fill='#bfa068')
    d.point((4, 1), fill='#c7a96f')
    d.point((3, 3), fill='#bfa068')
    d.rectangle((5, 2, 6, 3), fill='#d4dfc9')
    d.point((5, 2), fill='#8fa181')
    return sprite


def butter() -> Image.Image:
    sprite = Image.new('RGBA', (6, 4))
    d = ImageDraw.Draw(sprite)
    d.rectangle((0, 0, 5, 3), fill='#e4d7ad')
    d.line((0, 0, 5, 0), fill='#eee3c4')
    d.line((5, 1, 5, 3), fill='#cbbb90')
    d.rectangle((1, 1, 4, 2), fill='#d3b775')
    d.line((2, 1, 3, 1), fill='#f0e5c4')
    d.line((0, 3, 4, 3), fill='#d6c79e')
    return sprite


def eggs() -> Image.Image:
    sprite = Image.new('RGBA', (9, 6))
    d = ImageDraw.Draw(sprite)
    d.rectangle((1, 1, 7, 5), fill='#b8ad90')
    d.rectangle((0, 3, 8, 4), fill='#c8bea2')
    for x in (1, 4, 7):
        d.point((x, 0), fill='#ece1c7')
        d.point((x, 1), fill='#e1d4b8')
        d.point((x, 3), fill='#f0e6ce')
        d.point((x, 4), fill='#e4d7bd')
    d.line((1, 5, 7, 5), fill='#a69c80')
    return sprite


def boiled_sausage() -> Image.Image:
    sprite = Image.new('RGBA', (7, 4))
    d = ImageDraw.Draw(sprite)
    d.rectangle((1, 0, 5, 3), fill='#c5948c')
    d.rectangle((0, 1, 6, 2), fill='#c5948c')
    d.line((1, 0, 5, 0), fill='#d8aca0')
    d.line((1, 3, 5, 3), fill='#af7e78')
    d.rectangle((2, 0, 4, 3), fill='#e6ddbd')
    d.line((2, 1, 4, 1), fill='#a2ab89')
    d.point((3, 2), fill='#c1b18d')
    return sprite


def frankfurters() -> Image.Image:
    sprite = Image.new('RGBA', (7, 6))
    d = ImageDraw.Draw(sprite)
    d.rectangle((0, 0, 6, 5), fill='#d4d9c6')
    d.rectangle((1, 0, 5, 4), fill='#e4dfcd')
    for x in (1, 3, 5):
        d.line((x, 1, x, 4), fill='#c5917d')
        d.point((x, 1), fill='#d8aa91')
    d.rectangle((1, 2, 5, 3), fill='#e8dfbc')
    d.line((2, 2, 4, 2), fill='#98a481')
    d.line((1, 5, 5, 5), fill='#bec8b2')
    return sprite


def ham() -> Image.Image:
    sprite = Image.new('RGBA', (7, 5))
    d = ImageDraw.Draw(sprite)
    d.rectangle((1, 0, 5, 4), fill='#d6dbc9')
    d.rectangle((0, 1, 6, 3), fill='#d6dbc9')
    d.rectangle((2, 0, 4, 0), fill='#c39a91')
    d.rectangle((1, 1, 5, 3), fill='#c9958e')
    d.line((1, 1, 4, 1), fill='#dfb3a7')
    d.line((2, 3, 5, 3), fill='#b7837e')
    d.rectangle((3, 2, 5, 3), fill='#e8dfbc')
    d.point((4, 2), fill='#9aa783')
    return sprite


def chilled_juice() -> Image.Image:
    sprite = Image.new('RGBA', (5, 8))
    d = ImageDraw.Draw(sprite)
    d.rectangle((1, 0, 3, 0), fill='#819776')
    d.rectangle((1, 1, 3, 1), fill='#d1d9be')
    d.rectangle((0, 2, 4, 6), fill='#d7ac70')
    d.rectangle((1, 7, 3, 7), fill='#bf965e')
    d.line((0, 2, 0, 5), fill='#e6c68b')
    d.line((4, 3, 4, 6), fill='#c49b64')
    d.rectangle((0, 3, 3, 5), fill='#e8dfbc')
    d.point((2, 3), fill='#91a07a')
    d.line((1, 4, 2, 4), fill='#d4a265')
    return sprite


def potato() -> Image.Image:
    sprite = Image.new('RGBA', (4, 3))
    d = ImageDraw.Draw(sprite)
    d.rectangle((1, 0, 2, 2), fill='#c5a575')
    d.line((0, 1, 3, 1), fill='#c5a575')
    d.point((1, 0), fill='#debf8c')
    d.point((2, 2), fill='#a88a60')
    return sprite


def carrot() -> Image.Image:
    sprite = Image.new('RGBA', (3, 5))
    d = ImageDraw.Draw(sprite)
    d.point((0, 0), fill='#80985d')
    d.point((2, 0), fill='#6c8756')
    d.rectangle((0, 1, 2, 2), fill='#cd8c4c')
    d.line((1, 3, 1, 4), fill='#cd8c4c')
    d.point((0, 1), fill='#e3aa62')
    d.point((2, 2), fill='#b57840')
    return sprite


def apple() -> Image.Image:
    sprite = Image.new('RGBA', (4, 5))
    d = ImageDraw.Draw(sprite)
    d.point((1, 0), fill='#8e7951')
    d.point((2, 0), fill='#839c5d')
    d.rectangle((0, 1, 3, 3), fill='#b9705e')
    d.line((1, 4, 2, 4), fill='#a96051')
    d.point((1, 1), fill='#db9a77')
    return sprite


GENERATORS = {
    "potato": potato,
    "carrot": carrot,
    "apple": apple,
    "bread": bread,
    "baton": baton,
    "bun": bun,
    "pasta": pasta,
    "rice": rice,
    "buckwheat": buckwheat,
    "oats": oats,
    "flour": flour,
    "sugar": sugar,
    "salt": salt,
    "sunflower-oil": sunflower_oil,
    "canned-fish": canned_fish,
    "stew": stew,
    "canned-peas": canned_peas,
    "cookies": cookies,
    "chocolate": chocolate,
    "chips": chips,
    "tea": tea,
    "milk": milk,
    "kefir": kefir,
    "yogurt": yogurt,
    "sour-cream": sour_cream,
    "cottage-cheese": cottage_cheese,
    "cheese": cheese,
    "butter": butter,
    "eggs": eggs,
    "boiled-sausage": boiled_sausage,
    "frankfurters": frankfurters,
    "ham": ham,
    "chilled-juice": chilled_juice,
}


def main() -> None:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    for name, generate in GENERATORS.items():
        image = generate()
        image.save(OUTPUT / f"{name}.png")
        print(f"{name}: {image.width}x{image.height} RGBA")


if __name__ == "__main__":
    main()
