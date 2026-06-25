#!/usr/bin/env python3
"""Generate pixel-art sprite sheets for Drunkards."""

from PIL import Image, ImageDraw
import os

OUT = "/Users/daniilbug/drunkards/assets/sprites"
OUT_DRINKS = "/Users/daniilbug/drunkards/assets/sprites/drinks"
os.makedirs(OUT, exist_ok=True)
os.makedirs(OUT_DRINKS, exist_ok=True)

TRANSPARENT = (0, 0, 0, 0)

C = {
    "skin":        (236, 194, 149, 255),
    "skin_dark":   (200, 155, 110, 255),
    "hair":        ( 89,  53,  31, 255),
    "hair_hi":     (120,  76,  48, 255),
    "shirt_blue":  ( 75, 125, 200, 255),
    "shirt_dark":  ( 52,  90, 150, 255),
    "pants":       ( 65,  80, 110, 255),
    "pants_dark":  ( 45,  58,  82, 255),
    "shoe":        ( 55,  40,  28, 255),
    "apron":       (220, 210, 190, 255),
    "apron_dark":  (180, 168, 145, 255),
    "shirt_teal":  ( 46, 140, 120, 255),
    "wood_light":  (140,  97,  55, 255),
    "wood_mid":    (107,  72,  38, 255),
    "wood_dark":   ( 72,  47,  22, 255),
    "wood_hi":     (165, 118,  70, 255),
    "floor_a":     ( 88,  60,  33, 255),
    "floor_b":     ( 78,  53,  28, 255),
    "floor_line":  ( 55,  36,  16, 255),
    "floor_hi":    (102,  72,  42, 255),
    "wall":        ( 75,  51,  26, 255),
    "wall_hi":     ( 90,  62,  30, 255),
    "wall_dark":   ( 58,  38,  16, 255),
    "shelf":       (140,  97,  55, 255),
    "shelf_hi":    (180, 130,  75, 255),
    "shelf_dark":  ( 80,  52,  25, 255),
    "counter":     (140,  97,  55, 255),
    "counter_hi":  (170, 125,  75, 255),
    "chair_back":  (107,  72,  38, 255),
    "chair_seat":  (140,  97,  55, 255),
    "chair_hi":    (165, 118,  70, 255),
    "shadow":      (  0,   0,   0,  40),
    "drink_yel":   (240, 215,  75, 255),
    "drink_hi":    (255, 240, 140, 255),
    "drink_dark":  (180, 155,  40, 255),
    "candle":      (200, 190, 160, 255),
    "flame":       (255, 200,  80, 255),
    "lamp_shade":  (100,  70,  30, 255),
    "lamp_glow":   (255, 230, 140, 200),
    "frame_gold":  (180, 145,  60, 255),
    "frame_wood":  ( 60,  40,  18, 255),
    "sky":         ( 80, 140, 190, 255),
    "grass":       ( 46, 120,  50, 255),
    "mountain":    (200, 200, 210, 255),
}


def new(w, h):
    img = Image.new("RGBA", (w, h), TRANSPARENT)
    return img, ImageDraw.Draw(img)


def px(img, draw, x, y, color):
    if 0 <= x < img.width and 0 <= y < img.height:
        draw.point((x, y), fill=color)


def rect(draw, x, y, w, h, color):
    if w > 0 and h > 0:
        draw.rectangle([x, y, x + w - 1, y + h - 1], fill=color)


# ─── PLAYER ─────────────────────────────────────────────────────────────────
# Sheet: 4 cols × 10 rows, frame 12×20
# Row 0: walk_s   Row 1: walk_n   Row 2: walk_w   Row 3: walk_e
# Row 4: idle     Row 5: sit_s    Row 6: drink     Row 7: sit_n
# Row 8: dance_s  Row 9: dance_n

FW, FH = 12, 20


def draw_player_frame(img, draw, ox, oy, direction="s", walk_phase=0,
                      sitting=False, drinking=False):
    facing_away = direction == "n"

    leg_bob = [0, -1, 0, 1][walk_phase % 4]
    body_bob = -abs(leg_bob)

    px(img, draw, ox + 5, oy + 19, C["shadow"])
    px(img, draw, ox + 6, oy + 19, C["shadow"])

    if sitting:
        rect(draw, ox + 3, oy + 14, 2, 4, C["pants"])
        rect(draw, ox + 7, oy + 14, 2, 4, C["pants"])
        rect(draw, ox + 3, oy + 17, 2, 2, C["shoe"])
        rect(draw, ox + 7, oy + 17, 2, 2, C["shoe"])
    else:
        lly = oy + 15 + (leg_bob if not facing_away else 0)
        rect(draw, ox + 3, lly, 2, 4, C["pants"])
        rect(draw, ox + 3, lly + 3, 2, 1, C["shoe"])
        rly = oy + 15 - (leg_bob if not facing_away else 0)
        rect(draw, ox + 7, rly, 2, 4, C["pants"])
        rect(draw, ox + 7, rly + 3, 2, 1, C["shoe"])

    by = oy + 9 + body_bob
    rect(draw, ox + 3, by, 6, 6, C["shirt_blue"])
    rect(draw, ox + 3, by, 6, 1, C["shirt_dark"])
    rect(draw, ox + 3, by + 1, 1, 4, C["shirt_dark"])
    rect(draw, ox + 8, by + 1, 1, 4, C["shirt_dark"])
    rect(draw, ox + 3, by + 5, 6, 1, C["pants"])

    if drinking:
        rect(draw, ox + 2, by + 1, 1, 4, C["skin"])        # left arm
        rect(draw, ox + 9, by - 1, 2, 4, C["shirt_blue"])  # right sleeve raised
        rect(draw, ox + 9, by - 3, 2, 3, C["skin"])         # right hand near mouth
    else:
        rect(draw, ox + 2, by + 1, 1, 4, C["skin"])
        rect(draw, ox + 9, by + 1, 1, 4, C["skin"])

    hy = by - 8
    if facing_away:
        rect(draw, ox + 3, hy, 6, 7, C["hair"])
        rect(draw, ox + 4, hy + 1, 4, 3, C["hair_hi"])
    else:
        rect(draw, ox + 3, hy + 1, 6, 6, C["skin"])
        rect(draw, ox + 3, hy + 1, 1, 5, C["skin_dark"])
        rect(draw, ox + 3, hy, 6, 2, C["hair"])
        px(img, draw, ox + 3, hy + 1, C["hair"])
        px(img, draw, ox + 8, hy + 1, C["hair"])
        px(img, draw, ox + 4, hy, C["hair_hi"])
        if direction == "s":
            px(img, draw, ox + 4, hy + 3, C["hair"])
            px(img, draw, ox + 7, hy + 3, C["hair"])
        elif direction == "e":
            px(img, draw, ox + 7, hy + 3, C["hair"])
        elif direction == "w":
            px(img, draw, ox + 4, hy + 3, C["hair"])


def draw_dance_frame(img, draw, ox, oy, phase=0, direction="s"):
    """4-phase dance: 0=groove V-arms, 1=left raise + right kick, 2=T-arms + jump, 3=right raise + left kick."""
    facing_away = direction == "n"
    body_dy = [0, -1, -1, 1][phase]
    by = oy + 9 + body_dy
    hy = by - 8

    px(img, draw, ox + 5, oy + 19, C["shadow"])
    px(img, draw, ox + 6, oy + 19, C["shadow"])

    # Legs
    if phase == 0:  # wide groove stance
        rect(draw, ox + 2, oy + 15, 2, 4, C["pants"])
        rect(draw, ox + 2, oy + 18, 2, 1, C["shoe"])
        rect(draw, ox + 8, oy + 15, 2, 4, C["pants"])
        rect(draw, ox + 8, oy + 18, 2, 1, C["shoe"])
    elif phase == 1:  # left planted, right kick out
        rect(draw, ox + 3, oy + 15, 2, 4, C["pants"])
        rect(draw, ox + 3, oy + 18, 2, 1, C["shoe"])
        rect(draw, ox + 7, oy + 15, 2, 3, C["pants"])
        rect(draw, ox + 8, oy + 17, 3, 1, C["pants"])
        rect(draw, ox + 9, oy + 17, 2, 1, C["shoe"])
    elif phase == 2:  # both legs bent wide (slight jump)
        rect(draw, ox + 2, oy + 16, 2, 3, C["pants"])
        rect(draw, ox + 2, oy + 18, 2, 1, C["shoe"])
        rect(draw, ox + 8, oy + 16, 2, 3, C["pants"])
        rect(draw, ox + 8, oy + 18, 2, 1, C["shoe"])
    else:  # phase 3: left kick out, right planted
        rect(draw, ox + 3, oy + 15, 2, 3, C["pants"])
        rect(draw, ox + 1, oy + 17, 3, 1, C["pants"])
        rect(draw, ox + 1, oy + 17, 2, 1, C["shoe"])
        rect(draw, ox + 7, oy + 15, 2, 4, C["pants"])
        rect(draw, ox + 7, oy + 18, 2, 1, C["shoe"])

    # Body
    rect(draw, ox + 3, by, 6, 6, C["shirt_blue"])
    rect(draw, ox + 3, by, 6, 1, C["shirt_dark"])
    rect(draw, ox + 3, by + 1, 1, 4, C["shirt_dark"])
    rect(draw, ox + 8, by + 1, 1, 4, C["shirt_dark"])
    rect(draw, ox + 3, by + 5, 6, 1, C["pants"])

    # Arms
    if phase == 0:  # both arms raised in a V
        rect(draw, ox + 2, by + 1, 1, 2, C["shirt_blue"])
        px(img, draw, ox + 2, by - 1, C["shirt_blue"])
        px(img, draw, ox + 1, by - 2, C["skin"])
        px(img, draw, ox + 1, by - 3, C["skin"])
        rect(draw, ox + 9, by + 1, 1, 2, C["shirt_blue"])
        px(img, draw, ox + 9, by - 1, C["shirt_blue"])
        px(img, draw, ox + 10, by - 2, C["skin"])
        px(img, draw, ox + 10, by - 3, C["skin"])
    elif phase == 1:  # left arm punches up, right arm swings low
        rect(draw, ox + 2, by - 3, 1, 4, C["shirt_blue"])
        px(img, draw, ox + 1, by - 4, C["skin"])
        px(img, draw, ox + 1, by - 5, C["skin"])
        rect(draw, ox + 9, by + 2, 1, 3, C["skin"])
    elif phase == 2:  # full T: both arms wide horizontal
        rect(draw, ox + 0, by + 2, 3, 1, C["shirt_blue"])
        px(img, draw, ox + 0, by + 2, C["skin"])
        rect(draw, ox + 9, by + 2, 3, 1, C["shirt_blue"])
        px(img, draw, ox + 11, by + 2, C["skin"])
    else:  # phase 3: right arm punches up, left arm swings low
        rect(draw, ox + 2, by + 2, 1, 3, C["skin"])
        rect(draw, ox + 9, by - 3, 1, 4, C["shirt_blue"])
        px(img, draw, ox + 10, by - 4, C["skin"])
        px(img, draw, ox + 10, by - 5, C["skin"])

    # Head
    if facing_away:
        rect(draw, ox + 3, hy, 6, 7, C["hair"])
        rect(draw, ox + 4, hy + 1, 4, 3, C["hair_hi"])
    else:
        rect(draw, ox + 3, hy + 1, 6, 6, C["skin"])
        rect(draw, ox + 3, hy + 1, 1, 5, C["skin_dark"])
        rect(draw, ox + 3, hy, 6, 2, C["hair"])
        px(img, draw, ox + 3, hy + 1, C["hair"])
        px(img, draw, ox + 8, hy + 1, C["hair"])
        px(img, draw, ox + 4, hy, C["hair_hi"])
        if direction == "s":
            px(img, draw, ox + 4, hy + 3, C["hair"])
            px(img, draw, ox + 7, hy + 3, C["hair"])


def gen_player():
    ROWS = 10
    sheet = Image.new("RGBA", (FW * 4, FH * ROWS), TRANSPARENT)
    sdraw = ImageDraw.Draw(sheet)

    dirs = ["s", "n", "w", "e"]
    for row, direction in enumerate(dirs):
        for frame in range(4):
            draw_player_frame(sheet, sdraw, frame * FW, row * FH,
                              direction=direction, walk_phase=frame)

    # Row 4: idle (south)
    for frame in range(4):
        draw_player_frame(sheet, sdraw, frame * FW, 4 * FH, direction="s")

    # Row 5: sit (sitting facing south)
    for frame in range(4):
        draw_player_frame(sheet, sdraw, frame * FW, 5 * FH,
                          direction="s", sitting=True)

    # Row 6: drink (south, holding glass)
    for frame in range(4):
        draw_player_frame(sheet, sdraw, frame * FW, 6 * FH,
                          direction="s", drinking=(frame >= 1))

    # Row 7: drink (north/away)
    for frame in range(4):
        draw_player_frame(sheet, sdraw, frame * FW, 7 * FH,
                          direction="n", drinking=(frame >= 1))

    # Row 8: dance_s (facing south, 4 dance phases loop)
    for frame in range(4):
        draw_dance_frame(sheet, sdraw, frame * FW, 8 * FH,
                         phase=frame, direction="s")

    # Row 9: dance_n (facing north/away, 4 dance phases loop)
    for frame in range(4):
        draw_dance_frame(sheet, sdraw, frame * FW, 9 * FH,
                         phase=frame, direction="n")

    sheet.save(f"{OUT}/player.png")
    print(f"Saved player.png ({sheet.width}×{sheet.height})")


# ─── BARTENDER ──────────────────────────────────────────────────────────────
BTW, BTH = 12, 20


def draw_bartender_frame(img, draw, ox, oy, phase=0):
    # Counter back-panel (fills visual gap above physical counter geometry)
    rect(draw, ox + 0, oy + 15, 12, 2, C["counter"])
    rect(draw, ox + 0, oy + 15, 12, 1, C["counter_hi"])
    rect(draw, ox + 0, oy + 17, 12, 2, C["wood_mid"])
    rect(draw, ox + 0, oy + 19, 12, 1, C["wood_dark"])

    # Body with apron (y=8..14)
    rect(draw, ox + 3, oy + 8, 6, 7, C["apron"])
    rect(draw, ox + 3, oy + 8, 6, 1, C["apron_dark"])
    rect(draw, ox + 3, oy + 9, 1, 5, C["apron_dark"])
    rect(draw, ox + 8, oy + 9, 1, 5, C["apron_dark"])
    rect(draw, ox + 2, oy + 8, 1, 6, C["shirt_teal"])
    rect(draw, ox + 9, oy + 8, 1, 6, C["shirt_teal"])
    rect(draw, ox + 5, oy + 8, 1, 7, C["wood_dark"])
    rect(draw, ox + 7, oy + 8, 1, 7, C["wood_dark"])

    if phase == 0:
        rect(draw, ox + 2, oy + 11, 1, 3, C["skin"])
        rect(draw, ox + 9, oy + 11, 1, 3, C["skin"])
    else:
        rect(draw, ox + 2, oy + 11, 1, 3, C["skin"])
        rect(draw, ox + 9, oy + 8,  1, 3, C["skin"])
        rect(draw, ox + 9, oy + 5,  2, 4, C["drink_yel"])
        px(img, draw, ox + 9, oy + 5, C["drink_hi"])

    # Head (y=1..7)
    rect(draw, ox + 3, oy + 2, 6, 6, C["skin"])
    rect(draw, ox + 3, oy + 2, 1, 5, C["skin_dark"])
    rect(draw, ox + 3, oy + 1, 6, 2, C["hair"])
    px(img, draw, ox + 4, oy + 1, C["hair_hi"])
    px(img, draw, ox + 3, oy + 3, C["hair"])
    px(img, draw, ox + 8, oy + 3, C["hair"])
    px(img, draw, ox + 5, oy + 7, C["hair"])
    px(img, draw, ox + 6, oy + 7, C["hair"])
    px(img, draw, ox + 4, oy + 4, (50, 30, 12, 255))
    px(img, draw, ox + 7, oy + 4, (50, 30, 12, 255))


def gen_bartender():
    sheet = Image.new("RGBA", (BTW * 2, BTH), TRANSPARENT)
    sdraw = ImageDraw.Draw(sheet)
    for frame in range(2):
        draw_bartender_frame(sheet, sdraw, frame * BTW, 0, phase=frame)
    sheet.save(f"{OUT}/bartender.png")
    print(f"Saved bartender.png ({sheet.width}×{sheet.height})")


# ─── CHAIR ──────────────────────────────────────────────────────────────────
# 4 frames: [front-empty, front-occ, back-empty, back-occ]
# front = north-of-table (viewer sees seat), back = south-of-table (back rail only)
CHW, CHH = 14, 16


def draw_chair_front(img, draw, ox, oy, occupied=False):
    """Seen from south: seat and back rail visible."""
    for lx in [ox + 1, ox + 10]:
        rect(draw, lx, oy + 12, 2, 4, C["wood_dark"])
    rect(draw, ox + 1, oy + 8, 12, 4, C["chair_seat"])
    rect(draw, ox + 1, oy + 8, 12, 1, C["chair_hi"])
    rect(draw, ox + 1, oy + 11, 12, 1, C["wood_dark"])
    rect(draw, ox + 2, oy + 1, 10, 7, C["chair_back"])
    rect(draw, ox + 2, oy + 1, 10, 1, C["chair_hi"])
    rect(draw, ox + 2, oy + 2, 1, 5, C["chair_hi"])
    rect(draw, ox + 5, oy + 3, 4, 4, C["chair_seat"])
    rect(draw, ox + 5, oy + 3, 4, 1, C["chair_hi"])


def draw_chair_back(img, draw, ox, oy, occupied=False):
    """Seen from south: person faces north, viewer sees the back face of the backrest."""
    # Rear legs at bottom — same position as front-view legs, natural orientation
    for lx in [ox + 1, ox + 10]:
        rect(draw, lx, oy + 12, 2, 4, C["wood_dark"])
    # Front legs barely peeking above backrest (near table, partially obscured)
    for lx in [ox + 2, ox + 9]:
        rect(draw, lx, oy + 3, 1, 3, C["wood_dark"])
    # Back face of backrest — dominates the middle of the sprite
    rect(draw, ox + 1, oy + 5, 12, 7, C["chair_back"])
    rect(draw, ox + 1, oy + 5, 12, 1, C["chair_hi"])   # top highlight
    rect(draw, ox + 1, oy + 6,  1, 5, C["chair_hi"])   # left highlight
    # Centre opening/panel of the backrest
    rect(draw, ox + 4, oy + 7,  6, 4, (58, 36, 13, 255))
    rect(draw, ox + 4, oy + 7,  6, 1, (80, 52, 20, 255))
    # Bottom edge of backrest
    rect(draw, ox + 1, oy + 11, 12, 1, C["wood_dark"])


def gen_chair():
    sheet = Image.new("RGBA", (CHW * 4, CHH), TRANSPARENT)
    sdraw = ImageDraw.Draw(sheet)
    draw_chair_front(sheet, sdraw, 0,        0, occupied=False)
    draw_chair_front(sheet, sdraw, CHW,      0, occupied=True)
    draw_chair_back(sheet, sdraw,  CHW * 2,  0, occupied=False)
    draw_chair_back(sheet, sdraw,  CHW * 3,  0, occupied=True)
    sheet.save(f"{OUT}/chair.png")
    print(f"Saved chair.png ({sheet.width}×{sheet.height})")


# ─── TABLE ──────────────────────────────────────────────────────────────────
# 48×24 — matches the polygon in bar.tscn

def gen_table():
    W, H = 48, 24
    img = Image.new("RGBA", (W, H), TRANSPARENT)
    draw = ImageDraw.Draw(img)
    rect(draw, 1, 0, W - 2, H - 5, C["wood_mid"])
    rect(draw, 1, 0, W - 2, 1, C["wood_hi"])
    rect(draw, 1, 0, 1, H - 6, C["wood_hi"])
    rect(draw, W - 2, 1, 1, H - 6, C["wood_dark"])
    rect(draw, 1, H - 6, W - 2, 1, C["wood_dark"])
    for gx in range(12, W - 2, 12):
        for gy in range(1, H - 6):
            if gy % 3 != 0:
                px(img, draw, gx, gy, C["wood_dark"])
    # Front face (3D illusion)
    rect(draw, 1, H - 5, W - 2, 5, C["wood_dark"])
    rect(draw, 1, H - 5, W - 2, 1, (90, 62, 28, 255))
    rect(draw, 1, H - 5, 2, 5, C["frame_wood"])
    rect(draw, W - 3, H - 5, 2, 5, C["frame_wood"])
    img.save(f"{OUT}/table.png")
    print(f"Saved table.png ({img.width}×{img.height})")


# ─── BAR BACKGROUND ─────────────────────────────────────────────────────────
# 320×32: back wall (y=0-20) + shelf strip (y=20-30) + shadow row (y=30-31)

def gen_bar_bg():
    W, H = 320, 32
    img = Image.new("RGBA", (W, H), TRANSPARENT)
    draw = ImageDraw.Draw(img)

    # Back wall with subtle paneling
    for y in range(20):
        t = y / 19
        r = int(C["wall"][0] * (1 - t) + C["wall_hi"][0] * t)
        g = int(C["wall"][1] * (1 - t) + C["wall_hi"][1] * t)
        b = int(C["wall"][2] * (1 - t) + C["wall_hi"][2] * t)
        rect(draw, 0, y, W, 1, (r, g, b, 255))
    # Vertical planking lines
    for x in range(0, W, 24):
        for y in range(1, 19):
            px(img, draw, x, y, C["wall_dark"])
    # Top edge
    rect(draw, 0, 0, W, 1, C["wall_dark"])

    # Shelf
    shelf_y = 20
    rect(draw, 0, shelf_y, W, 1, C["shelf_hi"])   # highlight edge
    rect(draw, 0, shelf_y + 1, W, 4, C["shelf"])       # surface
    rect(draw, 0, shelf_y + 1, W, 1, (165, 118, 70, 255))  # surface highlight
    rect(draw, 0, shelf_y + 5, W, 1, C["wood_mid"])   # front face top
    rect(draw, 0, shelf_y + 6, W, 2, C["shelf_dark"]) # front face
    rect(draw, 0, shelf_y + 8, W, 1, C["frame_wood"]) # shadow
    rect(draw, 0, shelf_y + 9, W, 3, (45, 28, 10, 255))  # deep shadow

    # Bottles on shelf
    bottle_specs = [
        (40,  [(46,115,56,255),(72,160,82,255)],  11),
        (72,  [(140,56,26,255),(180,80,42,255)],   9),
        (104, [(46,115,56,255),(72,160,82,255)],  11),
        (148, [(160,120,40,255),(210,175,65,255)], 10),
        (200, [(180,140,40,255),(220,175,60,255)],  9),
        (240, [(140,56,26,255),(180,80,42,255)],  11),
        (280, [(46,115,56,255),(72,160,82,255)],   9),
    ]
    for bx, (dark, light), h in bottle_specs:
        top = shelf_y + 1 - h  # sit on shelf surface
        # Cap
        rect(draw, bx, top, 3, 1, (65, 42, 18, 255))
        # Neck
        rect(draw, bx, top + 1, 3, 3, dark)
        px(img, draw, bx + 1, top + 1, light)
        # Shoulder
        rect(draw, bx - 1, top + 4, 5, 1, dark)
        # Body
        rect(draw, bx - 1, top + 5, 5, h - 6, dark)
        # Label highlight
        rect(draw, bx, top + 6, 2, 3, light)

    # Wall frame (painting decoration) — kept away from bartender area (x=152-168)
    fx, fy = 12, 90
    rect(draw, fx, fy, 24, 15, C["frame_wood"])
    rect(draw, fx + 2, fy + 2, 20, 11, C["sky"])
    rect(draw, fx + 2, fy + 9, 20, 4, C["grass"])
    px(img, draw, fx + 6,  fy + 6, C["mountain"])
    px(img, draw, fx + 7,  fy + 5, C["mountain"])
    px(img, draw, fx + 8,  fy + 6, C["mountain"])
    px(img, draw, fx + 13, fy + 4, C["mountain"])
    px(img, draw, fx + 14, fy + 5, C["mountain"])
    px(img, draw, fx + 15, fy + 6, C["mountain"])
    px(img, draw, fx + 19, fy + 6, C["mountain"])
    for edge_x, edge_y, ew, eh in [
        (fx, fy, 24, 1), (fx, fy+14, 24, 1),
        (fx, fy, 1, 15), (fx+23, fy, 1, 15)
    ]:
        rect(draw, edge_x, edge_y, ew, eh, C["frame_gold"])

    img.save(f"{OUT}/bar_bg.png")
    print(f"Saved bar_bg.png ({img.width}×{img.height})")


# ─── BAR FLOOR ──────────────────────────────────────────────────────────────
# 320×152: wood plank floor (placed at y=28 in the scene)

def gen_bar_floor():
    W, H = 320, 300
    img = Image.new("RGBA", (W, H), TRANSPARENT)
    draw = ImageDraw.Draw(img)

    pw, ph = 64, 8  # plank dimensions
    for row in range(H // ph + 1):
        y = row * ph
        offset = (row % 2) * (pw // 2)
        base = C["floor_a"] if row % 2 == 0 else C["floor_b"]
        rect(draw, 0, y, W, min(ph, H - y), base)
        # Horizontal joint
        if y < H:
            rect(draw, 0, y, W, 1, C["floor_hi"])
        if y + ph - 1 < H:
            rect(draw, 0, y + ph - 1, W, 1, C["floor_line"])
        # Vertical joints
        for col in range(-1, W // pw + 2):
            x = col * pw - offset
            if 0 <= x < W:
                rect(draw, x, y, 1, min(ph, H - y), C["floor_line"])
            # Grain line
            gx = x + pw // 3
            if 0 <= gx < W:
                rect(draw, gx, y + 1, 1, max(0, min(ph - 2, H - y - 1)), C["floor_b"])

    img.save(f"{OUT}/bar_floor.png")
    print(f"Saved bar_floor.png ({img.width}×{img.height})")


# ─── BOOMBOX (16×10 per frame, 4 animation frames) ─────────────────────────
# Frame 0: idle   Frame 1: beat low   Frame 2: beat high   Frame 3: beat mid
# Animation: display bar + speaker centre dot pulse.

BBW, BBH = 16, 10
BB_BODY   = ( 32,  27,  23, 255)
BB_HI     = ( 58,  50,  42, 255)
BB_SH     = ( 14,  11,   9, 255)
BB_RING   = ( 50,  43,  36, 255)
BB_CONE   = ( 18,  15,  12, 255)
BB_DISP   = ( 30, 190, 118, 255)
BB_DISP_D = (  8,  62,  38, 255)
BB_BTN_R  = (195,  48,  36, 255)
BB_BTN    = ( 44,  38,  33, 255)
BB_ANT    = ( 75,  65,  55, 255)


def gen_boombox():
    img = Image.new("RGBA", (BBW * 4, BBH), TRANSPARENT)
    draw = ImageDraw.Draw(img)

    # display bar widths and speaker dot brightness per frame
    bar_w  = [0, 2, 5, 3]
    dot_c  = [BB_CONE, BB_HI, (110, 95, 78, 255), BB_HI]

    for frame in range(4):
        ox = frame * BBW

        # Antenna (top-right, diagonal 2px)
        px(img, draw, ox + 12, 0, BB_ANT)
        px(img, draw, ox + 13, 1, BB_ANT)

        # Body fill
        rect(draw, ox + 0, 1, 16, 9, BB_BODY)
        # Highlights / shadows
        rect(draw, ox + 1, 1, 14, 1, BB_HI)         # top edge
        rect(draw, ox + 0, 1,  1, 8, BB_HI)         # left edge
        rect(draw, ox + 15, 2,  1, 8, BB_SH)        # right edge shadow
        rect(draw, ox + 1, 9, 14, 1, BB_SH)         # bottom shadow

        # Left speaker: x=1..4, y=2..7
        rect(draw, ox + 1, 2, 4, 6, BB_RING)
        rect(draw, ox + 2, 3, 2, 4, BB_CONE)
        px(img, draw, ox + 3, 5, dot_c[frame])      # centre dot

        # Right speaker: x=11..14, y=2..7
        rect(draw, ox + 11, 2, 4, 6, BB_RING)
        rect(draw, ox + 12, 3, 2, 4, BB_CONE)
        px(img, draw, ox + 13, 5, dot_c[frame])

        # Centre panel background: x=5..10, y=2..8
        rect(draw, ox + 5, 2, 6, 7, BB_BODY)

        # Display bar: x=5..10, y=2..3
        rect(draw, ox + 5, 2, 6, 2, BB_DISP_D)
        if bar_w[frame] > 0:
            rect(draw, ox + 5, 2, bar_w[frame], 2, BB_DISP)

        # Cassette window: x=6..9, y=4..6
        rect(draw, ox + 6, 4, 4, 3, BB_SH)
        px(img, draw, ox + 7, 5, BB_HI)             # left reel dot
        px(img, draw, ox + 9, 5, BB_HI)             # right reel dot

        # Bottom button strip: y=8
        px(img, draw, ox + 5, 8, BB_BTN_R)          # red play button
        px(img, draw, ox + 7, 8, BB_BTN)
        px(img, draw, ox + 9, 8, BB_BTN)

    img.save(f"{OUT}/boombox.png")
    print(f"Saved boombox.png ({img.width}×{img.height})")


# ─── LAMP ───────────────────────────────────────────────────────────────────

def gen_lamp():
    W, H = 12, 22
    img = Image.new("RGBA", (W, H), TRANSPARENT)
    draw = ImageDraw.Draw(img)
    # Cord
    rect(draw, 5, 0, 2, 7, (55, 36, 16, 255))
    # Shade (widens downward)
    for i in range(9):
        w = 4 + i
        x = W // 2 - w // 2
        if i == 0:
            c = C["lamp_shade"]
        elif i < 6:
            c = (130, 95, 42, 255)
        else:
            c = (160, 120, 55, 255)
        rect(draw, x, 7 + i, w, 1, c)
    rect(draw, 1, 15, 10, 1, C["lamp_shade"])  # bottom rim
    # Warm glow below shade
    rect(draw, 2, 16, 8, 2, (255, 225, 130, 180))
    rect(draw, 3, 18, 6, 2, (255, 210, 110, 110))
    rect(draw, 4, 20, 4, 2, (255, 195,  90,  60))
    img.save(f"{OUT}/lamp.png")
    print(f"Saved lamp.png ({W}×{H})")


# ─── BEERS (sprite sheet, 5 frames × 8×10) ──────────────────────────────────
# Frame 0: Light Lager  — pale straw yellow
# Frame 1: Pale Ale     — golden amber
# Frame 2: Dark Stout   — near-black, cream foam
# Frame 3: Strong IPA   — deep orange
# Frame 4: Barleywine   — dark mahogany red

DRINK_TYPES = [
    # (liquid,                  highlight,              shadow,                 foam)
    ((235, 225, 130, 255), (255, 248, 180, 255), (170, 148,  40, 255), (245, 245, 235, 255)),  # Light Lager
    ((210, 145,  30, 255), (240, 185,  70, 255), (150,  95,  10, 255), (240, 238, 228, 255)),  # Pale Ale
    (( 22,  12,   6, 255), ( 55,  30,  10, 255), (  8,   4,   2, 255), (215, 205, 185, 255)),  # Dark Stout
    ((200,  95,  20, 255), (235, 140,  55, 255), (135,  55,   5, 255), (238, 235, 220, 255)),  # Strong IPA
    ((110,  28,  15, 255), (160,  55,  30, 255), ( 65,  10,   5, 255), (225, 215, 200, 255)),  # Barleywine
]

DW, DH = 8, 10


BEER_PARTS = 4  # number of sips per beer


def draw_drink_frame(img, draw, ox, oy, liquid, highlight, shadow, foam, fill_level):
    # Interior liquid area: y=2..7 (6px tall), bottom-aligned
    interior_h = 6
    liquid_h = max(1, round(interior_h * fill_level / BEER_PARTS))
    liquid_y = oy + 2 + (interior_h - liquid_h)

    rect(draw, ox + 2, liquid_y, 4, liquid_h, liquid)
    rect(draw, ox + 2, liquid_y, 1, liquid_h, highlight)
    rect(draw, ox + 5, liquid_y + 1, 1, max(0, liquid_h - 1), shadow)

    # Foam only when full
    if fill_level == BEER_PARTS:
        rect(draw, ox + 2, oy + 0, 4, 2, foam)
        rect(draw, ox + 2, oy + 0, 1, 1, (255, 255, 255, 200))


def gen_beer():
    img = Image.new("RGBA", (DW * 5, DH * BEER_PARTS), TRANSPARENT)
    draw = ImageDraw.Draw(img)
    for col, (liq, hi, sh, foam) in enumerate(DRINK_TYPES):
        for row in range(BEER_PARTS):
            fill = BEER_PARTS - row  # row 0 = full, row 3 = last sip
            draw_drink_frame(img, draw, col * DW, row * DH, liq, hi, sh, foam, fill)
    img.save(f"{OUT_DRINKS}/beer.png")
    print(f"Saved beer.png ({img.width}×{img.height})")


# ─── EMPTY GLASS (single frame, 8×10) ────────────────────────────────────────
# Transparent interior — liquid sprite shows through from behind.

GLASS    = (210, 230, 238, 220)
GLASS_HI = (235, 248, 252, 190)
GLASS_SH = (145, 175, 190, 200)


def draw_empty_glass_frame(img, draw, ox, oy):
    BASE_HI = (110,  80,  40, 255)
    BASE_DK = ( 80,  55,  25, 255)
    # Top rim (1 row)
    rect(draw, ox + 1, oy + 0, 6, 1, GLASS)
    # Left and right walls (rows 1–7); interior is transparent
    rect(draw, ox + 1, oy + 1, 1, 7, GLASS_HI)
    rect(draw, ox + 6, oy + 1, 1, 7, GLASS_SH)
    # Bottom edge of glass body
    rect(draw, ox + 2, oy + 7, 4, 1, GLASS)
    # Mug base — matches drink.png
    rect(draw, ox + 2, oy + 8, 4, 2, BASE_DK)
    rect(draw, ox + 2, oy + 8, 4, 1, BASE_HI)


def gen_beer_glass():
    img = Image.new("RGBA", (DW, DH), TRANSPARENT)
    draw = ImageDraw.Draw(img)
    draw_empty_glass_frame(img, draw, 0, 0)
    img.save(f"{OUT_DRINKS}/beer_glass.png")
    print(f"Saved beer_glass.png ({img.width}×{img.height})")


# ─── SHOTS (4 types × 1 part, 8×10 canvas) ──────────────────────────────────
# Canvas is 8×10 (same as beer). The glass itself is 5px tall, drawn in the
# bottom half (y=5..9), centered horizontally (4px wide, 2px pad each side).
# Types: Vodka, Tequila, Whiskey, Dark Rum

SHOT_TYPES = [
    # (liquid,                  highlight,              shadow)
    ((225, 238, 248, 255), (245, 252, 255, 255), (160, 195, 220, 255)),  # Vodka — nearly clear
    ((228, 192,  65, 255), (252, 228, 120, 255), (165, 128,  25, 255)),  # Tequila — pale gold
    ((172,  88,  22, 255), (215, 138,  65, 255), (110,  48,   8, 255)),  # Whiskey — amber
    (( 68,  18,   8, 255), (115,  40,  20, 255), ( 35,   6,   2, 255)),  # Dark Rum — near black
    (( 95,  38, 130, 255), (155,  80, 195, 255), ( 55,  15,  80, 255)),  # Sambuca — deep violet
]

SSW, SSH = 8, 10
# Glass is 4px wide × 5px tall, placed in the bottom half of the 8×10 canvas.
# rim y=5, interior y=6..7, bottom y=8, base y=9. Centered: x=2..5.
_SX = 2
_SY = 5


def draw_shot_frame(img, draw, ox, oy, liquid, highlight, shadow):
    gx, gy = ox + _SX, oy + _SY
    # Liquid fills the interior: x=3..4, y=6..7
    rect(draw, gx + 1, gy + 1, 2, 2, liquid)
    rect(draw, gx + 1, gy + 1, 1, 1, highlight)
    rect(draw, gx + 2, gy + 2, 1, 1, shadow)


def gen_shot():
    img = Image.new("RGBA", (SSW * len(SHOT_TYPES), SSH), TRANSPARENT)
    draw = ImageDraw.Draw(img)
    for i, (liq, hi, sh) in enumerate(SHOT_TYPES):
        draw_shot_frame(img, draw, i * SSW, 0, liq, hi, sh)
    img.save(f"{OUT_DRINKS}/shot.png")
    print(f"Saved shot.png ({img.width}×{img.height})")


def gen_shot_glass():
    img = Image.new("RGBA", (SSW, SSH), TRANSPARENT)
    draw = ImageDraw.Draw(img)
    gx, gy = _SX, _SY
    rect(draw, gx + 0, gy + 0, 4, 1, GLASS)      # rim      y=5
    rect(draw, gx + 0, gy + 1, 1, 2, GLASS_HI)  # left wall y=6..7
    rect(draw, gx + 3, gy + 1, 1, 2, GLASS_SH)  # right wall y=6..7
    rect(draw, gx + 1, gy + 3, 2, 1, GLASS)      # bottom    y=8
    rect(draw, gx + 0, gy + 4, 4, 1, (80, 55, 25, 255))  # base y=9
    img.save(f"{OUT_DRINKS}/shot_glass.png")
    print(f"Saved shot_glass.png ({SSW}×{SSH})")


# ─── COCKTAILS (4 types × 5 parts, 8×10 canvas each) ────────────────────────
# Canvas matches beer (8×10). The actual glass is 6×8 drawn with 1px padding
# on each side — visually slimmer than a beer mug.
# Types: Mojito, Margarita, Cosmopolitan, Blue Lagoon
# Row 0 = full glass, row 4 = last sip.

COCKTAIL_TYPES = [
    # (liquid,                  highlight,              shadow,                 garnish)
    (( 55, 160,  75, 255), ( 95, 210, 110, 255), ( 20,  90,  35, 255), (175, 230, 175, 255)),  # Mojito
    ((205, 190,  55, 255), (245, 235, 115, 255), (145, 128,  15, 255), (255, 245, 160, 255)),  # Margarita
    ((215,  60,  85, 255), (245, 120, 140, 255), (145,  20,  40, 255), (255, 190, 205, 255)),  # Cosmopolitan
    (( 40, 130, 215, 255), ( 85, 185, 255, 255), ( 10,  75, 148, 255), (170, 220, 255, 255)),  # Blue Lagoon
    ((185,  90, 160, 255), (230, 145, 210, 255), (120,  40, 100, 255), (240, 195, 230, 255)),  # Tequila Sunrise
]

CCW, CCH = 8, 10
COCKTAIL_PARTS = 5
# Glass drawn as 6×8 inside 8×10: 1px pad left/right, 1px pad top, 1px base.
# Interior: x=gx+1..gx+4 (4 wide), y=gy+1..gy+6 (6 tall); bottom gy+7; base gy+8..gy+9
_CCX = 1   # left pad → glass spans x=1..6
_CCY = 0   # no top pad — cocktail glass fills height naturally


def draw_cocktail_frame(img, draw, ox, oy, liquid, highlight, shadow, garnish, fill_level):
    gx, gy = ox + _CCX, oy + _CCY
    interior_h = 6
    liquid_h = max(1, round(interior_h * fill_level / COCKTAIL_PARTS))
    liquid_y = gy + 1 + (interior_h - liquid_h)  # bottom-aligned

    # Liquid only — glass overlay comes from cocktail_glass.png
    rect(draw, gx + 1, liquid_y, 4, liquid_h, liquid)
    rect(draw, gx + 1, liquid_y, 1, liquid_h, highlight)
    rect(draw, gx + 4, liquid_y + 1, 1, max(0, liquid_h - 1), shadow)

    # Garnish on full glass
    if fill_level == COCKTAIL_PARTS:
        rect(draw, gx + 1, liquid_y, 4, 2, garnish)
        px(img, draw, gx + 2, liquid_y, highlight)


def gen_cocktail():
    img = Image.new("RGBA", (CCW * len(COCKTAIL_TYPES), CCH * COCKTAIL_PARTS), TRANSPARENT)
    draw = ImageDraw.Draw(img)
    for col, (liq, hi, sh, garnish) in enumerate(COCKTAIL_TYPES):
        for row in range(COCKTAIL_PARTS):
            fill = COCKTAIL_PARTS - row  # row 0 = full, row 4 = 1 sip left
            draw_cocktail_frame(img, draw, col * CCW, row * CCH, liq, hi, sh, garnish, fill)
    img.save(f"{OUT_DRINKS}/cocktail.png")
    print(f"Saved cocktail.png ({img.width}×{img.height})")


def gen_cocktail_glass():
    img = Image.new("RGBA", (CCW, CCH), TRANSPARENT)
    draw = ImageDraw.Draw(img)
    gx, gy = _CCX, _CCY
    rect(draw, gx + 0, gy + 0, 6, 1, GLASS)       # rim
    rect(draw, gx + 0, gy + 1, 1, 6, GLASS_HI)   # left wall
    rect(draw, gx + 5, gy + 1, 1, 6, GLASS_SH)   # right wall
    rect(draw, gx + 1, gy + 7, 4, 1, GLASS)       # bottom edge
    rect(draw, gx + 0, gy + 8, 6, 1, (110, 80, 40, 255))
    rect(draw, gx + 0, gy + 9, 6, 1, ( 80, 55, 25, 255))
    img.save(f"{OUT_DRINKS}/cocktail_glass.png")
    print(f"Saved cocktail_glass.png ({CCW}×{CCH})")


# ─── ENTRANCE CARPET (single frame, 32×10) ───────────────────────────────────
# Seen top-down: deep red field, gold border, fringe on left/right short edges.

CARP_RED  = (120,  22,  22, 255)
CARP_DARK = ( 85,  12,  12, 255)
CARP_MID  = (155,  35,  35, 255)
CARP_GOLD = (175, 138,  48, 255)
CARP_GOLDD= (120,  92,  28, 255)
CARP_FRINGE = (200, 165,  58, 255)

CW, CH = 32, 10


def gen_carpet():
    img, draw = new(CW, CH)

    # ── body (full fill) ──────────────────────────────────────────────────────
    rect(draw, 0, 0, CW, CH, CARP_RED)

    # ── gold outer border (1 px, all four sides) ─────────────────────────────
    rect(draw, 0,      0,      CW, 1,  CARP_GOLD)   # top
    rect(draw, 0,      CH - 1, CW, 1,  CARP_GOLD)   # bottom
    rect(draw, 0,      0,      1,  CH, CARP_GOLD)   # left
    rect(draw, CW - 1, 0,      1,  CH, CARP_GOLD)   # right

    # ── gold inner border (1 px inset, skipping corners) ─────────────────────
    rect(draw, 2,      2,      CW - 4, 1,  CARP_GOLDD)   # top inner
    rect(draw, 2,      CH - 3, CW - 4, 1,  CARP_GOLDD)   # bottom inner
    rect(draw, 2,      2,      1,  CH - 4, CARP_GOLDD)   # left inner
    rect(draw, CW - 3, 2,      1,  CH - 4, CARP_GOLDD)   # right inner

    # ── subtle diamond centre accent ──────────────────────────────────────────
    cx, cy = CW // 2, CH // 2
    for dx, dy in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
        px(img, draw, cx + dx, cy + dy, CARP_GOLDD)
    px(img, draw, cx, cy, CARP_GOLD)

    # ── top/bottom row highlight (gives slight depth) ────────────────────────
    rect(draw, 1, 1, CW - 2, 1, CARP_MID)

    # ── fringe: short vertical lines on left and right edges ─────────────────
    for fy in range(2, CH - 2, 2):
        px(img, draw, 0, fy, CARP_FRINGE)
        px(img, draw, CW - 1, fy, CARP_FRINGE)

    img.save(f"{OUT}/carpet.png")
    print(f"Saved carpet.png ({CW}×{CH})")


if __name__ == "__main__":
    gen_player()
    gen_bartender()
    gen_chair()
    gen_table()
    gen_bar_bg()
    gen_bar_floor()
    gen_lamp()
    gen_boombox()
    gen_beer()
    gen_beer_glass()
    gen_shot()
    gen_shot_glass()
    gen_cocktail()
    gen_cocktail_glass()
    gen_carpet()
    print("All sprites generated.")
