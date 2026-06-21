#!/usr/bin/env python3
"""Generate pixel-art sprite sheets for Drunkards."""

from PIL import Image, ImageDraw
import os

OUT = "/Users/daniilbug/drunkards/assets/sprites"
os.makedirs(OUT, exist_ok=True)

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
# Sheet: 4 cols × 8 rows, frame 12×20
# Row 0: walk_s   Row 1: walk_n   Row 2: walk_w   Row 3: walk_e
# Row 4: idle     Row 5: sit_s    Row 6: drink     Row 7: sit_n

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
        rect(draw, ox + 9, by, 2, 3, C["shirt_blue"])
        rect(draw, ox + 9, by + 3, 2, 2, C["skin"])
        rect(draw, ox + 10, by - 4, 2, 5, C["drink_yel"])
        px(img, draw, ox + 10, by - 4, C["drink_hi"])
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


def gen_player():
    ROWS = 7
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

    sheet.save(f"{OUT}/player.png")
    print(f"Saved player.png ({sheet.width}×{sheet.height})")


# ─── BARTENDER ──────────────────────────────────────────────────────────────
BTW, BTH = 16, 24


def draw_bartender_frame(img, draw, ox, oy, phase=0):
    # Counter-back panel fills the gap between apron bottom and counter top
    rect(draw, ox + 0, oy + 18, 16, 2, C["counter"])
    rect(draw, ox + 0, oy + 18, 16, 1, C["counter_hi"])
    rect(draw, ox + 0, oy + 20, 16, 4, C["wood_mid"])
    rect(draw, ox + 0, oy + 23, 16, 1, C["wood_dark"])

    rect(draw, ox + 4, oy + 10, 8, 8, C["apron"])
    rect(draw, ox + 4, oy + 10, 8, 1, C["apron_dark"])
    rect(draw, ox + 4, oy + 11, 1, 6, C["apron_dark"])
    rect(draw, ox + 11, oy + 11, 1, 6, C["apron_dark"])
    rect(draw, ox + 3, oy + 11, 1, 5, C["shirt_teal"])
    rect(draw, ox + 12, oy + 11, 1, 5, C["shirt_teal"])

    if phase == 0:
        rect(draw, ox + 2, oy + 15, 2, 3, C["skin"])
        rect(draw, ox + 12, oy + 15, 2, 3, C["skin"])
    else:
        rect(draw, ox + 2, oy + 15, 2, 3, C["skin"])
        rect(draw, ox + 11, oy + 11, 2, 3, C["skin"])
        rect(draw, ox + 12, oy + 8, 2, 4, C["drink_yel"])
        px(img, draw, ox + 12, oy + 8, C["drink_hi"])

    rect(draw, ox + 4, oy + 3, 8, 6, C["skin"])
    rect(draw, ox + 4, oy + 3, 1, 6, C["skin_dark"])
    rect(draw, ox + 4, oy + 1, 8, 3, C["hair"])
    rect(draw, ox + 3, oy + 3, 10, 1, C["hair"])
    px(img, draw, ox + 5, oy + 1, C["hair_hi"])
    px(img, draw, ox + 6, oy + 6, C["hair"])
    px(img, draw, ox + 9, oy + 6, C["hair"])
    rect(draw, ox + 6, oy + 8, 4, 1, C["hair"])
    rect(draw, ox + 6, oy + 10, 1, 8, C["wood_dark"])
    rect(draw, ox + 9, oy + 10, 1, 8, C["wood_dark"])


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


# ─── DRINKS (sprite sheet, 5 frames × 8×10) ─────────────────────────────────
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


def draw_drink_frame(img, draw, ox, oy, liquid, highlight, shadow, foam):
    # Glass body
    rect(draw, ox + 1, oy + 2, 6, 6, liquid)
    # Left highlight edge
    rect(draw, ox + 1, oy + 2, 1, 5, highlight)
    # Right shadow edge
    rect(draw, ox + 6, oy + 3, 1, 5, shadow)
    # Foam head (top 2 rows)
    rect(draw, ox + 1, oy + 0, 6, 2, foam)
    rect(draw, ox + 1, oy + 0, 1, 1, (255, 255, 255, 200))
    # Mug base
    rect(draw, ox + 2, oy + 8, 4, 2, (80, 55, 25, 255))
    rect(draw, ox + 2, oy + 8, 4, 1, (110, 80, 40, 255))


def gen_drink():
    img = Image.new("RGBA", (DW * 5, DH), TRANSPARENT)
    draw = ImageDraw.Draw(img)
    for i, (liq, hi, sh, foam) in enumerate(DRINK_TYPES):
        draw_drink_frame(img, draw, i * DW, 0, liq, hi, sh, foam)
    img.save(f"{OUT}/drink.png")
    print(f"Saved drink.png ({img.width}×{img.height})")


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


def gen_drink_glass():
    img = Image.new("RGBA", (DW, DH), TRANSPARENT)
    draw = ImageDraw.Draw(img)
    draw_empty_glass_frame(img, draw, 0, 0)
    img.save(f"{OUT}/drink_glass.png")
    print(f"Saved drink_glass.png ({img.width}×{img.height})")


if __name__ == "__main__":
    gen_player()
    gen_bartender()
    gen_chair()
    gen_table()
    gen_bar_bg()
    gen_bar_floor()
    gen_lamp()
    gen_drink()
    gen_drink_glass()
    print("All sprites generated.")
