#!/usr/bin/env python3
"""Interior furniture/tile sprites (original, CC0). Deterministic (fixed seeds).
3/4 top-down view, light from top-left, 1px dark outline (42,26,16), warm palette.
Objects sit at the BOTTOM of their box; the rest is transparent."""
import os
import random
from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SPR = os.path.join(ROOT, "assets", "sprites")
OUT = (42, 26, 16)
WOOD = [(110, 70, 38), (138, 90, 52), (166, 112, 63), (190, 132, 76)]
PLASTER = [(196, 170, 128), (222, 198, 154), (238, 218, 176)]
IRON = [(52, 48, 52), (84, 80, 86), (122, 118, 124), (160, 156, 160)]
RED = [(122, 40, 40), (160, 62, 56), (196, 90, 76)]
BLUE = [(52, 78, 118), (76, 108, 150), (110, 144, 184)]
GREEN = [(60, 90, 52), (90, 128, 70), (130, 164, 96)]
HAY = [(176, 136, 52), (212, 172, 74), (238, 206, 110)]
SKY = [(150, 200, 232), (190, 226, 244), (240, 248, 252)]


def shade(c, k):
    return tuple(max(0, min(255, int(v * k))) for v in c)


def new(w, h):
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    return im, ImageDraw.Draw(im)


def save(im, name):
    im.save(os.path.join(SPR, name))
    print("wrote", name)


def box(d, x0, y0, x1, y1, fill, hi=None, lo=None, outline=OUT):
    """Filled rect with outline, lit top/left edge, shaded bottom/right edge."""
    d.rectangle([x0, y0, x1, y1], fill=fill, outline=outline)
    if x1 - x0 > 2 and y1 - y0 > 2:
        d.line([x0 + 1, y0 + 1, x1 - 1, y0 + 1], fill=hi or shade(fill, 1.18))
        d.line([x0 + 1, y0 + 1, x0 + 1, y1 - 1], fill=hi or shade(fill, 1.18))
        d.line([x0 + 1, y1 - 1, x1 - 1, y1 - 1], fill=lo or shade(fill, 0.8))
        d.line([x1 - 1, y0 + 2, x1 - 1, y1 - 1], fill=lo or shade(fill, 0.8))


def shadow(d, x0, y, x1):
    """Soft contact shadow row under an object (semi-transparent)."""
    d.line([x0, y, x1, y], fill=(42, 26, 16, 70))


def planks_h(d, x0, y0, x1, y1, pal, rng, ph=6):
    y = y0
    while y <= y1:
        h = min(ph, y1 - y + 1)
        base = shade(pal[2], rng.uniform(0.94, 1.06))
        d.rectangle([x0, y, x1, y + h - 1], fill=base)
        d.line([x0, y, x1, y], fill=shade(base, 1.14))
        d.line([x0, y + h - 1, x1, y + h - 1], fill=shade(pal[0], 0.9))
        for _ in range(max(1, (x1 - x0) // 10)):
            gx = rng.randrange(x0, max(x0 + 1, x1 - 4))
            d.line([gx, y + 2, min(x1, gx + rng.randrange(3, 7)), y + 2],
                   fill=shade(base, rng.choice((0.9, 1.08))))
        y += h


# ---------------------------------------------------------------- tiles
def floor():
    rng = random.Random(101)
    im, d = new(32, 32)
    for p in range(4):
        y0 = p * 8
        base = shade(WOOD[2], rng.uniform(0.94, 1.06))
        d.rectangle([0, y0, 31, y0 + 7], fill=base)
        d.line([0, y0, 31, y0], fill=shade(base, 1.12))
        d.line([0, y0 + 7, 31, y0 + 7], fill=shade(WOOD[0], 0.85))
        for _ in range(5):
            gx = rng.randrange(0, 27)
            gy = y0 + rng.randrange(2, 6)
            d.line([gx, gy, gx + rng.randrange(4, 9), gy], fill=shade(base, rng.choice((0.92, 1.07))))
        jx = (p * 11 + 5) % 28 + 2
        d.line([jx, y0 + 1, jx, y0 + 6], fill=shade(WOOD[0], 0.85))
        d.point([jx + 1, y0 + 1], fill=shade(base, 1.15))
    save(im, "int_floor.png")


def wall_base(d):
    """Back wall 32x48: ceiling cap, plaster, wood wainscot, baseboard. Tiles horizontally."""
    # top cap (dark beam)
    d.rectangle([0, 0, 31, 3], fill=WOOD[0])
    d.line([0, 0, 31, 0], fill=OUT)
    d.line([0, 1, 31, 1], fill=WOOD[2])
    d.line([0, 3, 31, 3], fill=OUT)
    # plaster
    d.rectangle([0, 4, 31, 29], fill=PLASTER[1])
    for x in (0, 16):  # subtle vertical panel seams (period 16 -> seamless)
        d.line([x, 4, x, 29], fill=PLASTER[0])
        d.line([x + 1, 4, x + 1, 29], fill=PLASTER[2])
    for x, y in ((6, 10), (22, 17), (11, 24), (27, 8)):
        d.point([x, y], fill=PLASTER[0])
    d.line([0, 4, 31, 4], fill=shade(PLASTER[0], 0.8))  # shadow under beam
    # chair rail
    d.line([0, 30, 31, 30], fill=OUT)
    d.line([0, 31, 31, 31], fill=WOOD[3])
    d.line([0, 32, 31, 32], fill=WOOD[1])
    # wainscot vertical boards
    d.rectangle([0, 33, 31, 43], fill=WOOD[1])
    for x in range(0, 32, 8):
        d.line([x, 33, x, 43], fill=WOOD[0])
        d.line([x + 1, 33, x + 1, 43], fill=WOOD[2])
        d.point([x + 4, 37], fill=WOOD[0])
    # baseboard
    d.rectangle([0, 44, 31, 47], fill=WOOD[0])
    d.line([0, 44, 31, 44], fill=WOOD[2])
    d.line([0, 47, 31, 47], fill=OUT)
    d.line([0, 33, 31, 33], fill=shade(WOOD[0], 0.85))


def wall():
    im, d = new(32, 48)
    wall_base(d)
    save(im, "int_wall.png")


def window():
    im, d = new(32, 48)
    wall_base(d)
    # frame
    d.rectangle([7, 7, 24, 31], fill=WOOD[2], outline=OUT)
    d.rectangle([9, 9, 22, 29], fill=SKY[0], outline=OUT)
    # sky glow gradient + sun glint
    for y in range(10, 29):
        t = (y - 10) / 18
        c = tuple(int(SKY[1][i] * (1 - t) + SKY[0][i] * t) for i in range(3))
        d.line([10, y, 21, y], fill=c)
    d.line([10, 10, 21, 10], fill=SKY[2])
    d.rectangle([11, 12, 13, 14], fill=SKY[2])
    # distant green hill
    d.line([10, 27, 21, 27], fill=GREEN[1])
    d.line([10, 28, 21, 28], fill=GREEN[0])
    d.line([14, 26, 18, 26], fill=GREEN[1])
    # mullions
    d.line([15, 10, 15, 28], fill=WOOD[1])
    d.line([16, 10, 16, 28], fill=WOOD[0])
    d.line([10, 19, 21, 19], fill=WOOD[1])
    # sill
    d.rectangle([5, 31, 26, 33], fill=WOOD[3], outline=OUT)
    d.line([6, 32, 25, 32], fill=WOOD[2])
    # curtains (red) with tie-backs
    for x0, x1 in ((7, 11), (20, 24)):
        d.rectangle([x0, 7, x1, 26], fill=RED[1], outline=OUT)
        for x in range(x0 + 1, x1, 2):
            d.line([x, 8, x, 25], fill=RED[2])
        d.line([x1 - 1 if x0 < 10 else x0 + 1, 9, x1 - 1 if x0 < 10 else x0 + 1, 25], fill=RED[0])
        d.line([x0, 18, x1, 18], fill=(222, 190, 90))
    # curtain rod
    d.line([5, 6, 26, 6], fill=OUT)
    d.point([5, 5], fill=(222, 190, 90))
    d.point([26, 5], fill=(222, 190, 90))
    save(im, "int_window.png")


# ---------------------------------------------------------------- furniture
def bed():
    im, d = new(32, 64)
    # headboard at top (back), frame body, blanket, pillow
    box(d, 1, 2, 30, 14, WOOD[1])                         # headboard
    d.rectangle([3, 4, 28, 6], fill=WOOD[2])
    d.line([3, 7, 28, 7], fill=WOOD[0])
    box(d, 1, 12, 30, 61, WOOD[2])                        # frame
    d.rectangle([3, 14, 28, 58], fill=(236, 226, 204), outline=OUT)  # sheet
    # pillow
    d.rounded_rectangle([6, 15, 25, 25], radius=3, fill=(250, 244, 230), outline=OUT)
    d.line([8, 17, 22, 17], fill=(255, 255, 252))
    d.line([8, 24, 23, 24], fill=(214, 204, 184))
    # blanket
    d.rectangle([3, 29, 28, 58], fill=BLUE[1], outline=OUT)
    d.rectangle([3, 29, 28, 33], fill=(240, 232, 214))   # folded top
    d.line([3, 33, 28, 33], fill=OUT)
    for y in range(36, 58, 6):                             # quilt stripes
        d.line([4, y, 27, y], fill=BLUE[2])
        d.line([4, y + 1, 27, y + 1], fill=BLUE[0])
    for x in range(8, 28, 8):
        d.line([x, 34, x, 57], fill=BLUE[0])
    d.line([4, 34, 4, 57], fill=BLUE[2])
    # footboard + shadow
    box(d, 1, 56, 30, 62, WOOD[1])
    d.line([3, 58, 28, 58], fill=WOOD[3])
    box(d, 0, 10, 3, 16, WOOD[3])
    box(d, 28, 10, 31, 16, WOOD[3])
    box(d, 0, 57, 3, 63, WOOD[3])
    box(d, 28, 57, 31, 63, WOOD[3])
    save(im, "int_bed.png")


def table():
    im, d = new(64, 40)
    # legs
    for x in (4, 54):
        box(d, x, 22, x + 5, 38, WOOD[1])
    # top surface + front apron
    box(d, 1, 6, 62, 24, WOOD[2])
    d.rectangle([2, 24, 61, 29], fill=WOOD[1], outline=OUT)
    d.line([3, 25, 60, 25], fill=WOOD[2])
    for x in range(6, 60, 11):
        d.line([x, 9, x + 6, 9], fill=WOOD[3])
        d.line([x + 2, 15, x + 9, 15], fill=WOOD[1])
        d.line([x, 20, x + 5, 20], fill=WOOD[3])
    shadow(d, 6, 39, 58)
    # bowl with stew
    d.ellipse([12, 9, 27, 19], fill=(206, 190, 160), outline=OUT)
    d.ellipse([14, 10, 25, 16], fill=(176, 92, 52))
    d.point([17, 12], fill=(220, 150, 80))
    d.point([21, 13], fill=GREEN[2])
    d.line([14, 11, 17, 10], fill=(236, 214, 180))
    # cup
    d.rectangle([40, 8, 46, 16], fill=(188, 98, 78), outline=OUT)
    d.line([41, 9, 41, 15], fill=(222, 130, 104))
    d.line([42, 10, 45, 10], fill=(96, 56, 36))
    d.arc([45, 10, 50, 15], 270, 90, fill=OUT)
    # bread loaf
    d.ellipse([48, 15, 58, 21], fill=(206, 148, 70), outline=OUT)
    d.line([51, 17, 53, 17], fill=(236, 190, 110))
    save(im, "int_table.png")


def chest():
    im, d = new(32, 32)
    shadow(d, 3, 30, 29)
    box(d, 2, 10, 29, 28, WOOD[2])                  # body
    d.rectangle([2, 4, 29, 13], fill=WOOD[3], outline=OUT)  # lid
    d.line([3, 5, 28, 5], fill=shade(WOOD[3], 1.15))
    d.line([3, 13, 28, 13], fill=OUT)
    for x in range(5, 28, 7):                       # grain
        d.line([x, 17, x + 4, 17], fill=WOOD[1])
        d.line([x + 1, 23, x + 5, 23], fill=WOOD[1])
    for x in (6, 22):                               # iron bands
        d.rectangle([x, 4, x + 3, 28], fill=IRON[1], outline=OUT)
        d.line([x + 1, 5, x + 1, 27], fill=IRON[2])
        d.point([x + 2, 8], fill=IRON[3])
        d.point([x + 2, 22], fill=IRON[3])
    d.rectangle([13, 11, 18, 18], fill=(222, 190, 90), outline=OUT)  # lock
    d.point([15, 14], fill=OUT)
    d.line([15, 15, 15, 16], fill=OUT)
    save(im, "int_chest.png")


def stove():
    im, d = new(32, 48)
    # pipe
    box(d, 20, 0, 25, 20, IRON[1])
    d.line([21, 2, 21, 19], fill=IRON[3])
    d.rectangle([19, 15, 26, 17], fill=IRON[2], outline=OUT)
    shadow(d, 3, 47, 29)
    # body
    box(d, 3, 18, 28, 44, IRON[1])
    d.rectangle([3, 18, 28, 23], fill=IRON[2], outline=OUT)   # top plate
    d.line([4, 19, 27, 19], fill=IRON[3])
    for cx in (10, 21):
        d.ellipse([cx - 3, 19, cx + 3, 22], fill=IRON[0], outline=OUT)
    # door with fire glow
    d.rectangle([8, 27, 23, 40], fill=IRON[0], outline=OUT)
    d.rectangle([10, 29, 21, 38], fill=(226, 120, 40), outline=OUT)
    d.rectangle([12, 32, 19, 37], fill=(250, 190, 70))
    d.rectangle([14, 34, 17, 37], fill=(255, 238, 150))
    d.line([10, 29, 21, 29], fill=(150, 60, 30))
    d.point([22, 33], fill=IRON[3])  # handle
    # legs
    box(d, 4, 44, 8, 47, IRON[0])
    box(d, 23, 44, 27, 47, IRON[0])
    save(im, "int_stove.png")


def shelf():
    im, d = new(32, 56)
    shadow(d, 2, 55, 30)
    box(d, 1, 2, 30, 54, WOOD[1])
    d.rectangle([4, 5, 27, 51], fill=WOOD[0], outline=OUT)   # dark back
    rng = random.Random(7)
    for sy in (19, 35, 51):                                   # shelf boards
        d.rectangle([2, sy, 29, sy + 3], fill=WOOD[3], outline=OUT)
        d.line([3, sy + 1, 28, sy + 1], fill=shade(WOOD[3], 1.15))
    # row 1: jars
    for x, c in ((6, RED[1]), (12, GREEN[1]), (18, (222, 180, 70)), (24, BLUE[1])):
        d.rectangle([x, 9, x + 3, 18], fill=c, outline=OUT)
        d.rectangle([x, 7, x + 3, 8], fill=WOOD[3], outline=OUT)
        d.point([x + 1, 11], fill=shade(c, 1.4))
    # row 2: books
    x = 5
    for c in (RED[1], BLUE[1], GREEN[1], (222, 180, 70), RED[0]):
        h = rng.randrange(10, 14)
        d.rectangle([x, 34 - h, x + 3, 34], fill=c, outline=OUT)
        d.line([x + 1, 34 - h + 1, x + 1, 33], fill=shade(c, 1.3))
        x += 4
    d.rectangle([25, 28, 27, 34], fill=(236, 226, 204), outline=OUT)   # leaning page stack
    # row 3: pots
    d.ellipse([6, 41, 15, 50], fill=(196, 110, 70), outline=OUT)
    d.line([8, 43, 12, 43], fill=(226, 150, 100))
    d.rectangle([19, 42, 27, 50], fill=(160, 150, 140), outline=OUT)
    d.line([20, 43, 26, 43], fill=(200, 192, 184))
    save(im, "int_shelf.png")


def rug():
    im, d = new(96, 64)
    cols = [RED[1], (232, 208, 150), BLUE[1], (232, 208, 150), GREEN[1], (232, 208, 150), RED[0]]
    # concentric braided ovals
    for i, c in enumerate(cols):
        m = i * 4 + 2
        d.ellipse([m, m, 95 - m, 63 - m], fill=c, outline=shade(c, 0.6) if i else OUT)
    # braid texture: dashes around each ring
    import math
    for i in range(len(cols) - 1):
        m = i * 4 + 2
        rx = (95 - 2 * m) / 2 - 2
        ry = (63 - 2 * m) / 2 - 2
        cx, cy = 47.5, 31.5
        for k in range(0, 360, 9):
            a = math.radians(k)
            x = cx + rx * math.cos(a)
            y = cy + ry * math.sin(a)
            d.point([int(x), int(y)], fill=shade(cols[i], 0.78 if (k // 9) % 2 else 1.18))
    m = len(cols) * 4 + 1
    d.ellipse([m, m, 95 - m, 63 - m], fill=(232, 208, 150), outline=shade(RED[0], 0.8))
    save(im, "int_rug.png")


def workbench():
    im, d = new(64, 40)
    for x in (4, 54):
        box(d, x, 22, x + 5, 38, WOOD[0])
    shadow(d, 4, 39, 60)
    box(d, 1, 8, 62, 24, WOOD[3])                    # thick top
    d.rectangle([2, 24, 61, 30], fill=WOOD[1], outline=OUT)
    d.line([3, 25, 60, 25], fill=WOOD[2])
    box(d, 8, 31, 55, 34, WOOD[0])                   # lower stretcher
    for x in range(5, 58, 12):
        d.line([x, 12, x + 7, 12], fill=WOOD[2])
        d.line([x + 3, 18, x + 9, 18], fill=WOOD[2])
    # vice (left)
    box(d, 4, 4, 14, 14, IRON[1])
    d.rectangle([6, 2, 12, 5], fill=IRON[2], outline=OUT)
    d.line([15, 9, 19, 9], fill=OUT)
    d.rectangle([19, 7, 21, 11], fill=IRON[2], outline=OUT)
    # hammer
    d.line([28, 16, 38, 12], fill=WOOD[0], width=2)
    d.rectangle([36, 8, 41, 13], fill=IRON[2], outline=OUT)
    # saw
    d.polygon([(44, 18), (59, 14), (59, 19), (44, 20)], fill=IRON[3], outline=OUT)
    d.rectangle([42, 17, 45, 21], fill=RED[1], outline=OUT)
    # nails / wood block
    d.rectangle([24, 17, 30, 21], fill=WOOD[2], outline=OUT)
    for x in (31, 33, 35):
        d.point([x, 20], fill=IRON[0])
    save(im, "int_workbench.png")


def hay():
    im, d = new(32, 32)
    rng = random.Random(33)
    shadow(d, 2, 30, 29)
    box(d, 2, 8, 29, 29, HAY[1], hi=HAY[2], lo=HAY[0])
    d.rectangle([2, 4, 29, 11], fill=HAY[2], outline=OUT)   # top face
    for _ in range(46):
        x = rng.randrange(4, 27)
        y = rng.randrange(5, 28)
        d.line([x, y, x + rng.randrange(2, 5), y + rng.choice((-1, 0, 0, 1))],
               fill=rng.choice((HAY[0], HAY[2], (250, 226, 140))))
    for x in (10, 21):                                       # twine
        d.line([x, 12, x, 28], fill=(122, 82, 40))
        d.line([x + 1, 12, x + 1, 28], fill=(150, 104, 52))
    save(im, "int_hay.png")


def crate():
    im, d = new(32, 32)
    shadow(d, 2, 30, 29)
    box(d, 2, 4, 29, 29, WOOD[2])
    d.rectangle([2, 4, 29, 11], fill=WOOD[3], outline=OUT)   # lid/top face
    d.line([3, 5, 28, 5], fill=shade(WOOD[3], 1.15))
    d.line([3, 11, 28, 11], fill=OUT)
    d.rectangle([4, 13, 27, 27], fill=WOOD[1], outline=WOOD[0])
    d.line([5, 14, 26, 14], fill=WOOD[2])
    d.line([5, 20, 26, 20], fill=WOOD[0])                    # plank seam
    for a, b in (((5, 14), (26, 26)), ((5, 26), (26, 14))):  # X brace
        d.line([a, b], fill=WOOD[3], width=2)
    d.line([4, 13, 4, 27], fill=OUT)
    for x, y in ((5, 15), (26, 15), (5, 26), (26, 26)):
        d.point([x, y], fill=IRON[1])
    for x in (4, 26):
        d.point([x, 6], fill=IRON[1])
    save(im, "int_crate.png")


def mat():
    im, d = new(32, 16)
    d.rounded_rectangle([2, 2, 29, 13], radius=2, fill=(150, 98, 60), outline=OUT)
    d.rectangle([5, 4, 26, 11], fill=(196, 148, 80), outline=(110, 70, 38))
    for x in range(6, 26, 2):                                # woven stripes
        d.line([x, 5, x, 10], fill=(176, 128, 66))
    d.line([7, 7, 24, 7], fill=(222, 182, 106))
    d.line([7, 8, 24, 8], fill=(150, 98, 60))
    for x in range(3, 29, 3):                                # fringe
        d.point([x, 1], fill=(150, 98, 60))
        d.point([x, 14], fill=(150, 98, 60))
    save(im, "int_mat.png")


def sack():
    im, d = new(32, 32)
    shadow(d, 5, 30, 26)
    # bulging body
    d.ellipse([4, 9, 27, 30], fill=(204, 176, 120), outline=OUT)
    d.ellipse([6, 11, 18, 22], fill=(224, 198, 142))
    d.arc([6, 13, 25, 29], 20, 160, fill=(168, 138, 86))
    d.line([9, 24, 22, 27], fill=(176, 146, 92))
    # tied neck with ruffle
    d.polygon([(11, 11), (21, 11), (19, 5), (13, 5)], fill=(204, 176, 120), outline=OUT)
    d.line([14, 6, 14, 10], fill=(168, 138, 86))
    d.rectangle([12, 9, 20, 10], fill=RED[1], outline=OUT)   # tie
    d.polygon([(12, 5), (10, 2), (14, 4)], fill=(204, 176, 120), outline=OUT)
    d.polygon([(20, 5), (22, 2), (18, 4)], fill=(204, 176, 120), outline=OUT)
    # stencil mark
    d.ellipse([12, 16, 18, 22], outline=GREEN[0])
    d.point([15, 19], fill=GREEN[0])
    save(im, "int_sack.png")


def toolrack():
    im, d = new(32, 48)
    # wall-hung board
    box(d, 2, 12, 29, 44, WOOD[1])
    d.rectangle([2, 12, 29, 15], fill=WOOD[3], outline=OUT)
    d.line([3, 13, 28, 13], fill=shade(WOOD[3], 1.15))
    d.line([3, 31, 28, 31], fill=WOOD[0])
    for x, y in ((5, 22), (26, 22), (5, 38), (26, 38)):
        d.point([x, y], fill=IRON[0])
    # pegs
    for x in (7, 15, 23):
        d.rectangle([x, 17, x + 1, 19], fill=IRON[2], outline=OUT)
    # shovel
    d.line([8, 20, 8, 40], fill=WOOD[3], width=2)
    d.polygon([(5, 36), (11, 36), (11, 42), (8, 44), (5, 42)], fill=IRON[2], outline=OUT)
    # rake
    d.line([16, 20, 16, 38], fill=WOOD[3], width=2)
    d.rectangle([12, 37, 20, 39], fill=IRON[1], outline=OUT)
    for x in (12, 15, 18, 20):
        d.line([x, 40, x, 42], fill=IRON[2])
    # axe
    d.line([24, 20, 24, 38], fill=WOOD[3], width=2)
    d.polygon([(25, 22), (30, 20), (30, 29), (25, 27)], fill=IRON[2], outline=OUT)
    d.line([26, 23, 29, 22], fill=IRON[3])
    # hanging small hammer
    d.rectangle([20, 32, 23, 35], fill=IRON[1], outline=OUT)
    save(im, "int_toolrack.png")


def dresser():
    im, d = new(32, 40)
    shadow(d, 2, 39, 29)
    # mirror
    d.rounded_rectangle([9, 1, 22, 14], radius=3, fill=WOOD[3], outline=OUT)
    d.rounded_rectangle([11, 3, 20, 12], radius=2, fill=SKY[1], outline=WOOD[0])
    d.line([12, 5, 14, 4], fill=(255, 255, 255))
    d.point([12, 7], fill=(255, 255, 255))
    d.line([18, 10, 19, 9], fill=SKY[0])
    d.rectangle([14, 14, 17, 17], fill=WOOD[1], outline=OUT)
    # body
    box(d, 2, 16, 29, 37, WOOD[2])
    d.rectangle([1, 16, 30, 19], fill=WOOD[3], outline=OUT)  # top
    d.line([2, 17, 29, 17], fill=shade(WOOD[3], 1.15))
    for y0 in (21, 30):                                      # drawers
        d.rectangle([4, y0, 27, y0 + 7], fill=WOOD[1], outline=OUT)
        d.line([5, y0 + 1, 26, y0 + 1], fill=WOOD[2])
        d.rectangle([14, y0 + 3, 17, y0 + 4], fill=(222, 190, 90), outline=OUT)
    # trinket on top
    d.rectangle([5, 14, 8, 17], fill=BLUE[1], outline=OUT)
    d.rectangle([24, 15, 27, 17], fill=RED[1], outline=OUT)
    box(d, 3, 37, 7, 39, WOOD[0])
    box(d, 24, 37, 28, 39, WOOD[0])
    save(im, "int_dresser.png")


def main():
    os.makedirs(SPR, exist_ok=True)
    for fn in (floor, wall, window, bed, table, chest, stove, shelf, rug, workbench,
               hay, crate, mat, sack, toolrack, dresser):
        fn()


if __name__ == "__main__":
    main()
