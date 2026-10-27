"""Reproduce the PNG parts of the NPC conversation interface."""
from pathlib import Path
from PIL import Image, ImageDraw

OUT = Path(__file__).resolve().parents[1] / 'assets/sprites/social/ui'


def save(name, image):
    image.save(OUT / f'{name}.png')


def generate():
    OUT.mkdir(parents=True, exist_ok=True)
    body = Image.new('RGBA', (12, 12))
    d = ImageDraw.Draw(body)
    d.rectangle((4, 0, 7, 11), fill='white')
    d.rectangle((0, 4, 11, 7), fill='white')
    save('bubble', body)

    # Preserve the overlapping translucent strips of the original shadow.
    shadow = Image.new('RGBA', (12, 12))
    for bounds in [(4, 0, 7, 11), (0, 4, 11, 7)]:
        strip = Image.new('RGBA', (12, 12))
        ImageDraw.Draw(strip).rectangle(bounds, fill=(255, 255, 255, 51))
        shadow = Image.alpha_composite(shadow, strip)
    save('bubble_shadow', shadow)

    tail = Image.new('RGBA', (8, 6))
    d = ImageDraw.Draw(tail)
    for row in range(3):
        d.rectangle((row, row * 2, 7 - row, row * 2 + 1), fill='white')
    save('tail_down', tail)

    save('dot', Image.new('RGBA', (3, 3), '#6e7366'))
    spark = Image.new('RGBA', (6, 6))
    d = ImageDraw.Draw(spark)
    d.rectangle((2, 0, 3, 5), fill='#d5ab66')
    d.rectangle((0, 2, 5, 3), fill='#d5ab66')
    save('spark', spark)

    for name, color in [('affinity_plus', '#d5ab66'), ('affinity_minus', '#aa624c')]:
        mark = Image.new('RGBA', (8, 8))
        d = ImageDraw.Draw(mark)
        d.rectangle((0, 3, 7, 4), fill=color)
        if name == 'affinity_plus':
            d.rectangle((3, 0, 4, 7), fill=color)
        save(name, mark)

    focus = Image.new('RGBA', (8, 8), (209, 181, 130, 92))
    ImageDraw.Draw(focus).rectangle((0, 5, 7, 7), fill=(171, 117, 61, 255))
    save('choice_focus', focus)


if __name__ == '__main__':
    generate()
    print(OUT)
