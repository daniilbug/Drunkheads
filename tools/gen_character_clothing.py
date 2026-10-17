#!/usr/bin/env python3
"""Generate 20 tops and 20 bottoms, using the body's original animated poses.

IDs 0–9 are masculine; 10–19 are feminine in both slots. Fabric uses one
neutral ramp; exposed skin, undershirts, metal and belts keep fixed colors.
Only top_*.png and pants_*.png are written by this scoped generator.
"""
from pathlib import Path

from PIL import Image, ImageDraw

from character_pose import arm_is_visible, head_y, walk_arms

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / 'assets/sprites/characters'
FW, FH = 12, 20
DARK = (64, 64, 64, 255)
SHADE = (112, 112, 112, 255)
MAIN = (176, 176, 176, 255)
LIGHT = (224, 224, 224, 255)
SKIN = (236, 194, 149, 255)
SKIN_SHADE = (200, 155, 110, 255)
IVORY = (232, 226, 209, 255)
METAL = (144, 154, 166, 255)
BRASS = (172, 133, 72, 255)
BELT = (74, 52, 43, 255)
SHOE = (55, 40, 28, 255)
# The original pose generator shades the far leg before the near leg occludes it.
POSE_FAR_PANTS = (45, 58, 82, 255)
TOP_STYLES = (
    'Crew tee', 'Polo', 'Oxford shirt', 'Overshirt', 'Henley',
    'Hoodie', 'Crewneck knit', 'Bomber', 'Denim jacket', 'Blazer',
    'Fitted tee', 'V-neck tee', 'Camisole', 'Blouse', 'Crop tee',
    'Cardigan', 'Turtleneck', 'Cropped hoodie', 'Biker jacket', 'Tailored blazer',
)
PANTS_STYLES = (
    'Straight jeans', 'Slim jeans', 'Chinos', 'Pleated trousers', 'Cargo trousers',
    'Joggers', 'Wide jeans', 'Bermuda shorts', 'Sport shorts', 'Cuffed trousers',
    'Straight jeans', 'Wide trousers', 'High-waist trousers', 'Leggings', 'Denim shorts',
    'Tailored shorts', 'Mini skirt', 'A-line skirt', 'Pleated skirt', 'Slit skirt',
)


def arm_paths(row: int, frame: int, by: int) -> tuple[list, list]:
    """Shoulder-to-wrist order, including the existing lifted-arm poses."""
    left = [(2, by + y) for y in range(1, 5)]
    right = [(9, by + y) for y in range(1, 5)]
    if row in (0, 1, 2, 3):
        return walk_arms(row, frame, by)
    elif row in (6, 7) and frame >= 1:
        right = [(9, by + y) for y in (2, 1, 0, -1)]
    elif row in (8, 9):
        if frame == 0:
            left = [(2, by + y) for y in (2, 1, 0, -1)]
            right = [(9, by + y) for y in (2, 1, 0, -1)]
        elif frame == 1:
            left = [(2, by - y) for y in range(4)]
        elif frame == 2:
            left = [(2, by + 2), (1, by + 2)]
            right = [(9, by + 2), (10, by + 2)]
        else:
            right = [(9, by - y) for y in range(4)]
    return left, right


def paint_top(source: Image.Image, style: int, row: int, frame: int) -> Image.Image:
    by = head_y(row, frame) + 8
    back = row in (1, 7, 9)
    side = row in (2, 3)
    front_x = 7 if row == 3 else 4
    image = Image.new('RGBA', (FW, FH))
    # Fill the original torso holes before adding necklines or a cropped hem.
    # Skin pixels stay warm, so the dye shader never colors exposed anatomy.
    for y in range(FH):
        for x in range(FW):
            if source.getpixel((x, y))[3]:
                image.putpixel((x, y), SKIN if x < 3 or x > 8 else MAIN)
    draw = ImageDraw.Draw(image)
    draw.rectangle((3, by, 8, by + 4), fill=MAIN)
    draw.line((3, by + 1, 3, by + 4), fill=SHADE)
    draw.line((8, by + 1, 8, by + 4), fill=SHADE)
    draw.line((4, by + 4, 7, by + 4), fill=SHADE)
    paths = arm_paths(row, frame, by)
    sleeve = 0 if style == 12 else 1 if style == 10 else 2 if style in (0, 1, 11, 14) else 4
    for arm, path in enumerate(paths):
        for i, (x, y) in enumerate(path):
            if 0 <= x < FW and 0 <= y < FH:
                if row in (0, 1, 2, 3) and not arm_is_visible(row, arm, x, y, by):
                    continue
                # Keep real hands out of the fabric mask, including T-pose ends.
                covered = (len(path) - int(not source.getpixel(path[-1])[3]) if sleeve == 4 else
                           len(path) // 2 if sleeve == 2 else 1 if sleeve else 0)
                fabric = i < covered
                skin = SKIN_SHADE if side and arm == 0 else SKIN
                image.putpixel((x, y), SHADE if fabric else skin)
    if style in (5, 7, 8, 9, 15, 19):
        draw.line((3, by + 5, 8, by + 5), fill=SHADE)
    if style in (14, 17):
        draw.line((3, by + 4, 8, by + 4), fill=SKIN)
        draw.line((3, by + 3, 8, by + 3), fill=SHADE)
    # Necklines follow the view; front-only openings never appear on the back.
    if not back:
        neck_x = ((7, 8) if row == 3 else (3, 4)) if side else (5, 6)
        for x in neck_x:
            image.putpixel((x, by), SKIN)
        if style in (11, 12, 13):
            image.putpixel((front_x if side else 6, by + 1), SKIN)
    else:
        draw.line((4, by, 7, by), fill=SHADE)
    if style == 12:  # Thin straps and a low neckline.
        draw.line((4, by, 7, by), fill=SKIN)
        if not back:
            draw.line((5, by + 1, 6, by + 1), fill=SKIN)
        draw.point((3, by), fill=SHADE)
        draw.point((8, by), fill=SHADE)
    if style in (6, 16):
        draw.line((4, by, 7, by), fill=SHADE)
        if not back:
            draw.line((5, by, 6, by), fill=LIGHT)
        draw.line((4, by + 3, 7, by + 3), fill=LIGHT if style == 6 else MAIN)
    if style in (5, 17):
        if back:
            draw.line((4, by, 4, by + 1), fill=SHADE)
            draw.line((7, by, 7, by + 1), fill=SHADE)
            draw.line((5, by + 2, 6, by + 2), fill=SHADE)
        elif not side:
            draw.point((4, by + 1), fill=IVORY)
            draw.point((7, by + 1), fill=IVORY)
            if style == 5:
                draw.line((4, by + 3, 7, by + 3), fill=SHADE)
    if style in (1, 2, 4, 13):
        if not back:
            if side:
                draw.point((front_x, by + 1), fill=LIGHT)
            else:
                if style != 4:
                    draw.point((4, by), fill=LIGHT)
                    draw.point((7, by), fill=LIGHT)
                draw.line((6, by + 1, 6, by + (4 if style in (2, 13) else 2)), fill=SHADE)
                draw.point((6, by + 2), fill=METAL)
                if style in (2, 13):
                    draw.point((6, by + 4), fill=METAL)
        if back and style in (2, 13):
            draw.line((4, by + 1, 7, by + 1), fill=LIGHT)
    if style in (3, 8, 9, 15, 18, 19):
        if not back and not side:
            draw.rectangle((5, by, 6, by + 4), fill=IVORY)
            draw.point((4, by + 1), fill=LIGHT)
            draw.point((front_x, by + 1), fill=LIGHT)
            if style in (9, 19):
                draw.point((5, by + 2), fill=SHADE)
                draw.point((6, by + 3), fill=SHADE)
                draw.point((6, by + 4), fill=BRASS)
            elif style == 18:
                draw.line((7, by + 1, 5, by + 4), fill=METAL)
            elif style == 15:
                draw.point((7, by + 3), fill=BRASS)
            else:
                draw.point((4, by + 2), fill=SHADE)
                draw.point((7, by + 2), fill=SHADE)
                if style == 8:
                    draw.line((3, by + 3, 4, by + 3), fill=LIGHT)
                    draw.line((7, by + 3, 8, by + 3), fill=LIGHT)
        elif back:
            if style in (3, 8, 18):
                draw.line((4, by + 1, 7, by + 1), fill=SHADE)
            if style in (9, 19):
                draw.line((6, by + 3, 6, by + 5), fill=SHADE)
        else:
            draw.line((8 if row == 3 else 3, by + 1, 8 if row == 3 else 3, by + 4), fill=LIGHT)
    if style == 7:
        if not back:
            draw.line((front_x if side else 6, by + 1, front_x if side else 6, by + 4), fill=METAL)
        draw.line((3, by + 5, 8, by + 5), fill=DARK)
    if style == 10:
        if not back and not side:
            draw.line((4, by, 7, by), fill=SKIN)
    if style == 13:
        # Soft gathered shoulders and a small tie distinguish the blouse
        # from the straighter Oxford shirt in every view.
        draw.point((2, by), fill=LIGHT)
        draw.point((9, by), fill=LIGHT)
        if not back and not side:
            draw.point((5, by + 1), fill=IVORY)
            draw.point((6, by + 1), fill=IVORY)
        if back:
            draw.point((5, by + 2), fill=SHADE)
    if style == 19:
        draw.line((4, by + 6, 7, by + 6), fill=SHADE)
        if not back and not side:
            draw.point((5, by + 3), fill=BRASS)
            draw.point((7, by + 3), fill=BRASS)
    # The body supplies exposed anatomy. Transparent necklines and crop hems
    # let a high-waisted bottom overlap correctly underneath this layer.
    for y in range(by, by + 5):
        for x in range(3, 9):
            if image.getpixel((x, y)) == SKIN:
                image.putpixel((x, y), (0, 0, 0, 0))
    return image


def leg_groups(points: list, source: Image.Image, row: int, waist: int) -> list:
    if row in (2, 3):
        return [[(x, y) for x, y in points if y > waist and
                 (source.getpixel((x, y)) == POSE_FAR_PANTS) == far]
                for far in (True, False)]
    return [[(x, y) for x, y in points if y > waist and (x >= 6) == bool(half)]
            for half in (0, 1)]


def paint_bottom(source: Image.Image, base: Image.Image, style: int, row: int, frame: int) -> Image.Image:
    by = head_y(row, frame) + 8
    waist = by + 5
    back = row in (1, 7, 9)
    side = row in (2, 3)
    front_x = 7 if row == 3 else 4
    image = Image.new('RGBA', (FW, FH))
    points = [(x, y) for y in range(FH) for x in range(FW) if source.getpixel((x, y))[3]]
    legs = leg_groups(points, source, row, waist)
    for x, y in points:
        shadow = source.getpixel((x, y)) == POSE_FAR_PANTS if side else x in (3, 7)
        image.putpixel((x, y), SHADE if shadow else MAIN)
    draw = ImageDraw.Draw(image)
    draw.line((3, waist, 8, waist), fill=SHADE)
    if style in (7, 8, 14, 15) or style >= 16:
        for index, leg in enumerate(legs):
            if not leg:
                continue
            end = max(y for _, y in leg) - (1 if style == 7 else 2)
            for x, y in leg:
                if y > end or style >= 16:
                    shadow = index == 0 if side else x in (3, 7)
                    image.putpixel((x, y), SKIN_SHADE if shadow else SKIN)
    if style in (6, 11):
        # Widen each leg along its actual pose, preserving the existing shoe tips.
        for x, y in points:
            if y > waist:
                if side:
                    far = source.getpixel((x, y)) == POSE_FAR_PANTS
                    direction = -1 if row == 2 else 1
                    outward = x + (-direction if far else direction)
                else:
                    far = x < 6
                    outward = x - 1 if far else x + 1
                if (0 <= outward < FW and base.getpixel((outward, y)) != SHOE and
                        (not side or not source.getpixel((outward, y))[3])):
                    image.putpixel((outward, y), SHADE if far else MAIN)
    if style in (10, 12):
        draw.line((3, waist - 1, 8, waist - 1), fill=MAIN)
        draw.line((3, waist, 8, waist), fill=DARK)
    if style >= 16:
        length = 2 if style == 16 else 3
        end = min(17, waist + length)
        if row == 5:
            end = min(end, 16)
        for y in range(waist, end + 1):
            flare = y > waist and style in (17, 18)
            left, right = (3, 8) if side or not flare else (2, 9)
            for x in range(left, right + 1):
                if base.getpixel((x, y)) == SHOE:
                    continue
                if style == 19 and y == end and x >= 7:
                    continue
                color = SHADE if x == left else MAIN
                if style == 18 and x in (3, 5, 7, 9):
                    color = SHADE
                if y == end:
                    color = DARK if style == 16 else SHADE
                image.putpixel((x, y), color)
        return image
    if style in (2, 3, 9, 12, 15):
        draw.line((3, waist, 8, waist), fill=BELT)
        if not back:
            draw.point((front_x if side else 6, waist), fill=BRASS)
    elif style in (5, 8, 13):
        draw.line((3, waist, 8, waist), fill=DARK)
        if not back and not side and style != 13:
            draw.point((5, waist + 1), fill=IVORY)
            draw.point((6, waist + 1), fill=IVORY)
    # Keep seams, pockets and cuffs clipped to fabric, never painted onto bare legs.
    for x, y in points:
        if image.getpixel((x, y)) in (SKIN, SKIN_SHADE, BELT, BRASS, IVORY):
            continue
        if side:
            # Profile legs cross the center line. Stitching and pockets must
            # follow each actual leg rather than a fixed left/right x range.
            for index, leg in enumerate(legs):
                if (x, y) not in leg:
                    continue
                xs = [px for px, py in leg if py == y]
                edge = min(xs) if row == 2 else max(xs)
                if x != edge:
                    continue
                accent = MAIN if index == 0 else LIGHT
                if style in (0, 1, 6, 10, 14):
                    if y == waist + 1 or (y > waist + 1 and style in (0, 6, 10)):
                        image.putpixel((x, y), accent)
                elif style in (3, 12):
                    image.putpixel((x, y), accent)
                elif style == 4 and y == waist + 1:
                    image.putpixel((x, y), DARK)
            continue
        if style in (0, 1, 6, 10, 14):
            if (back and x in (4, 7) and y == waist + 1) or (not back and x in (3, 8) and y == waist + 1):
                image.putpixel((x, y), LIGHT)
            elif x in (4, 8) and y > waist + 1:
                image.putpixel((x, y), LIGHT if style in (0, 6, 10) else MAIN)
        elif style in (3, 12) and x in (4, 7) and y > waist:
            image.putpixel((x, y), LIGHT)
        elif style == 4 and x in (3, 8) and y == waist + 1:
            image.putpixel((x, y), DARK)
        elif style == 13:
            image.putpixel((x, y), SHADE if x < 6 else MAIN)
    if style in (5, 9):
        for leg in legs:
            if leg:
                end = max(y for _, y in leg)
                for x, y in leg:
                    if y == end:
                        image.putpixel((x, y), DARK if style == 5 else LIGHT)
    return image


def generate_clothing_atlases(layers: dict[str, Image.Image]) -> None:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    for slot, names in (('top', TOP_STYLES), ('pants', PANTS_STYLES)):
        for style in range(len(names)):
            sheet = Image.new('RGBA', (FW * 4, FH * 10))
            for row in range(10):
                for frame in range(4):
                    box = (frame * FW, row * FH, (frame + 1) * FW, (row + 1) * FH)
                    source = layers[slot].crop(box)
                    image = (paint_top(source, style, row, frame) if slot == 'top' else
                             paint_bottom(source, layers['base'].crop(box), style, row, frame))
                    sheet.paste(image, (frame * FW, row * FH))
            sheet.save(OUTPUT / f'{slot}_{style}.png')
    print('Saved 20 neutral tops and 20 neutral bottoms (48×200)')


if __name__ == '__main__':
    from gen_sprites import build_player_layers
    generate_clothing_atlases(build_player_layers())
