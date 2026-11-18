#!/usr/bin/env python3
"""City sprites (original, CC0): civic buildings, apartments, street furniture and
interior furniture for shops/bank/police/hospital/garage. Deterministic (fixed seeds).
Same palette/style as gen_town.py / gen_interior.py: 1px dark outline (42,26,16),
light from top-left. Building bottom row = ground line (door base on the last row).
Doors are 32px wide; door x ranges are noted per building."""
import os
import random
from PIL import Image, ImageDraw

from gen_town import (OUT, WOOD, DOOR, GLOW, STONE, shade, new, save, window,
                      planks, shingle_roof, SPR)
from gen_interior import box, shadow, IRON, RED, BLUE, GREEN

GLASS = [(96, 140, 170), (140, 190, 214), (200, 232, 244)]
BRASS = [(150, 106, 34), (206, 158, 52), (244, 206, 96)]
CREAM = [(200, 188, 160), (232, 222, 196), (250, 244, 224)]
TEAL = [(40, 104, 112), (62, 142, 148), (110, 190, 190)]
SLATE = [(58, 62, 78), (84, 90, 108), (116, 124, 144)]
AWRED = [(150, 40, 40), (196, 58, 52), (226, 96, 80)]


def brick(d, x0, y0, x1, y1, pal, rng, bw=8, bh=4):
    d.rectangle([x0, y0, x1, y1], fill=pal[0])           # mortar
    r = 0
    for y in range(y0, y1 + 1, bh):
        off = (r % 2) * (bw // 2)
        for x in range(x0 - off, x1 + 1, bw):
            a, b = max(x0, x + 1), min(x1, x + bw - 1)
            if a > b:
                continue
            c = shade(pal[1], rng.uniform(0.92, 1.08))
            e = min(y1, y + bh - 2)
            d.rectangle([a, y + 1 if y + 1 <= y1 else y, b, e], fill=c)
            d.line([a, y + 1, b, y + 1], fill=shade(c, 1.15))
        r += 1


def blocks(d, x0, y0, x1, y1, pal, rng, bw=12, bh=7):
    brick(d, x0, y0, x1, y1, [shade(pal[1], 0.78), pal[1], pal[2]], rng, bw, bh)


def door(d, x0, yt, yb, pal, glass=False, brass=False):
    """32px wide double door; x0..x0+31, base on row yb."""
    d.rectangle([x0, yt, x0 + 31, yb], fill=WOOD[3] if not brass else BRASS[0], outline=OUT)
    for lx in (x0 + 3, x0 + 16):
        d.rectangle([lx, yt + 3, lx + 12, yb], fill=pal[1], outline=OUT)
        d.line([lx + 1, yt + 4, lx + 1, yb - 1], fill=pal[2])
        d.line([lx + 12, yt + 4, lx + 12, yb - 1], fill=pal[0])
        if glass:
            d.rectangle([lx + 2, yt + 5, lx + 10, yt + 5 + (yb - yt) // 2 - 4], fill=GLASS[1], outline=OUT)
            d.line([lx + 3, yt + 6, lx + 6, yt + 6], fill=GLASS[2])
        else:
            h = (yb - yt) // 2
            d.rectangle([lx + 3, yt + 6, lx + 9, yt + 6 + h - 6], outline=shade(pal[1], 0.7))
            d.rectangle([lx + 3, yt + 8 + h - 4, lx + 9, yb - 4], outline=shade(pal[1], 0.7))
    k = BRASS[2]
    d.point([x0 + 14, (yt + yb) // 2], fill=k); d.point([x0 + 17, (yt + yb) // 2], fill=k)
    d.point([x0 + 14, (yt + yb) // 2 + 1], fill=BRASS[0]); d.point([x0 + 17, (yt + yb) // 2 + 1], fill=BRASS[0])
    d.rectangle([x0 - 2, yb - 1, x0 + 33, yb], fill=STONE[2], outline=OUT)      # step on last rows


def awning(d, x0, x1, y0, y1, c1, c2, sw=8):
    n = 0
    for x in range(x0, x1, sw):
        c = c1 if n % 2 == 0 else c2
        e = min(x + sw - 1, x1)
        d.polygon([(x, y0), (e, y0), (e, y1 - 2), (e - 2, y1), (x + 2, y1), (x, y1 - 2)], fill=c, outline=OUT)
        d.line([x + 1, y0 + 1, e - 1, y0 + 1], fill=shade(c, 1.15))
        d.line([x + 1, y1 - 3, e - 1, y1 - 3], fill=shade(c, 0.82))
        n += 1
    sh = Image.new("RGBA", (x1 + 3, y1 + 7), (0, 0, 0, 0))                       # drop shadow on wall
    ImageDraw.Draw(sh).rectangle([x0 + 2, y1 + 1, x1 - 2, y1 + 5], fill=(0, 0, 0, 55))
    return sh


def flat_roof(d, x0, x1, y0, y1, pal, rng):
    d.rectangle([x0, y0, x1, y1], fill=pal[1], outline=OUT)
    for y in range(y0 + 3, y1, 4):
        d.line([x0 + 1, y, x1 - 1, y], fill=pal[0])
    d.line([x0 + 1, y0 + 1, x1 - 1, y0 + 1], fill=pal[2])
    d.rectangle([x0 - 2, y1 - 2, x1 + 2, y1], fill=pal[2], outline=OUT)         # cornice
    d.line([x0 - 1, y1 - 1, x1 + 1, y1 - 1], fill=shade(pal[2], 1.12))


def sign_board(d, x0, y0, x1, y1, fill=WOOD[1]):
    d.rectangle([x0, y0, x1, y1], fill=fill, outline=OUT)
    d.line([x0 + 1, y0 + 1, x1 - 1, y0 + 1], fill=shade(fill, 1.2))
    d.rectangle([x0 + 3, y0 + 3, x1 - 3, y1 - 3], outline=shade(fill, 0.7))
    for x in (x0 + 1, x1 - 1):
        d.point([x, y0 + 1], fill=IRON[3])


def cross(d, cx, cy, r, c=(214, 50, 46), t=2):
    d.rectangle([cx - t, cy - r, cx + t - 1, cy + r], fill=c)
    d.rectangle([cx - r, cy - t, cx + r, cy + t - 1], fill=c)
    d.line([cx - t, cy - r, cx - t, cy + r], fill=shade(c, 1.2))


def shop_win(d, x0, y0, x1, y1, frame, lit=True):
    d.rectangle([x0 - 2, y0 - 2, x1 + 2, y1 + 2], fill=frame, outline=OUT)
    d.rectangle([x0, y0, x1, y1], fill=GLOW[0] if lit else GLASS[0], outline=OUT)
    for y in range(y0 + 1, y1):
        t = (y - y0) / max(1, y1 - y0)
        c = tuple(int(GLOW[2][i] * (1 - t) + GLOW[0][i] * t) for i in range(3)) if lit else \
            tuple(int(GLASS[2][i] * (1 - t) + GLASS[0][i] * t) for i in range(3))
        d.line([x0 + 1, y, x1 - 1, y], fill=c)


# ------------------------------------------------------------------ buildings
def shop_building():
    rng = random.Random(61)
    W, H = 128, 112
    im, d = new(W, H)
    BR = [(104, 52, 44), (146, 76, 58), (176, 100, 76)]
    flat_roof(d, 6, 121, 0, 22, BR, rng)
    # wall
    planks(d, 8, 23, 119, 111, [CREAM[0], CREAM[1], CREAM[2]], rng, pw=8)
    d.rectangle([7, 23, 120, 111], outline=OUT)
    d.rectangle([8, 24, 119, 27], fill=shade(CREAM[0], 0.75))
    # sign board
    sign_board(d, 22, 28, 105, 43, WOOD[1])
    d.ellipse([57, 31, 69, 41], fill=BRASS[1], outline=OUT)                      # coin emblem
    d.ellipse([60, 33, 66, 39], outline=BRASS[0])
    d.line([59, 33, 62, 32], fill=BRASS[2])
    for x in (30, 40, 85, 95):                                                   # painted letter blocks
        d.rectangle([x, 33, x + 6, 38], fill=CREAM[1])
        d.line([x, 33, x + 6, 33], fill=CREAM[2])
    shade_im = awning(d, 8, 119, 46, 60, AWRED[1], CREAM[2])
    im.alpha_composite(shade_im)
    d = ImageDraw.Draw(im)
    # big window left, small right
    shop_win(d, 14, 68, 56, 98, WOOD[3])
    d.line([35, 68, 35, 98], fill=WOOD[3]); d.line([14, 82, 56, 82], fill=WOOD[3])
    d.rectangle([14, 94, 56, 98], fill=WOOD[2], outline=OUT)
    for i, c in enumerate(((196, 70, 60), (90, 150, 80), (222, 180, 70), (90, 120, 180))):
        d.rectangle([18 + i * 9, 88, 23 + i * 9, 93], fill=c, outline=OUT)       # goods on the sill
    d.line([16, 70, 22, 70], fill=(255, 255, 240))
    shop_win(d, 102, 70, 114, 90, WOOD[3])
    d.line([108, 70, 108, 90], fill=WOOD[3])
    # door x 64..95
    door(d, 64, 66, 111, DOOR, glass=True)
    d.rectangle([68, 62, 91, 65], fill=BRASS[1], outline=OUT)                    # open sign plate
    d.rectangle([7, 108, 120, 111], fill=STONE[1], outline=OUT)
    d.line([8, 108, 119, 108], fill=STONE[2])
    door(d, 64, 66, 111, DOOR, glass=True)
    save(im, "shop_building.png")


def bank_building():
    rng = random.Random(62)
    W, H = 160, 128
    im, d = new(W, H)
    ST = [(138, 134, 124), (176, 172, 160), (210, 206, 192)]
    # pediment
    d.polygon([(6, 28), (80, 2), (153, 28)], fill=ST[1], outline=OUT)
    d.polygon([(22, 26), (80, 8), (137, 26)], fill=ST[0], outline=OUT)
    d.line([8, 27, 80, 3], fill=ST[2])
    d.ellipse([71, 12, 89, 25], fill=BRASS[1], outline=OUT)                      # coin in tympanum
    d.ellipse([75, 15, 85, 22], outline=BRASS[0]); d.line([73, 14, 77, 13], fill=BRASS[2])
    # entablature
    d.rectangle([4, 28, 155, 37], fill=ST[2], outline=OUT)
    d.line([5, 29, 154, 29], fill=(236, 232, 218))
    for x in range(8, 152, 6):
        d.line([x, 32, x, 36], fill=ST[1])
    # wall
    blocks(d, 8, 38, 151, 127, ST, rng)
    d.rectangle([8, 38, 151, 127], outline=OUT)
    d.rectangle([9, 39, 150, 42], fill=ST[0])
    # windows between columns
    for x in (28, 118):
        d.rectangle([x, 54, x + 13, 90], fill=BRASS[0], outline=OUT)
        d.rectangle([x + 2, 56, x + 11, 88], fill=GLASS[1], outline=OUT)
        d.rectangle([x + 2, 56, x + 5, 60], fill=GLASS[2])
        for y in range(62, 88, 6):
            d.line([x + 2, y, x + 11, y], fill=BRASS[1])
        d.line([x + 6, 56, x + 6, 88], fill=BRASS[1])
    # columns
    for x in (13, 49, 103, 139):
        d.rectangle([x - 1, 40, x + 10, 44], fill=ST[2], outline=OUT)            # capital
        d.rectangle([x, 44, x + 9, 118], fill=ST[2], outline=OUT)
        d.line([x + 2, 45, x + 2, 117], fill=(238, 234, 222))
        d.line([x + 7, 45, x + 7, 117], fill=ST[0])
        d.line([x + 5, 45, x + 5, 117], fill=ST[1])
        d.rectangle([x - 1, 116, x + 10, 121], fill=ST[2], outline=OUT)          # plinth
    # door x 64..95: brass
    door(d, 64, 62, 127, BRASS, glass=False, brass=True)
    d.rectangle([62, 56, 97, 61], fill=BRASS[1], outline=OUT)                    # brass lintel
    d.line([63, 57, 96, 57], fill=BRASS[2])
    for x in (68, 76, 84, 92):
        d.point([x, 59], fill=BRASS[0])
    # steps (last rows)
    d.rectangle([4, 119, 155, 123], fill=ST[2], outline=OUT)
    d.rectangle([2, 123, 157, 127], fill=ST[1], outline=OUT)
    d.line([3, 124, 156, 124], fill=ST[2])
    door(d, 64, 62, 127, BRASS, glass=False, brass=True)
    save(im, "bank_building.png")


def police_building():
    rng = random.Random(63)
    W, H = 128, 112
    im, d = new(W, H)
    BB = [(60, 76, 102), (86, 106, 138), (116, 138, 170)]
    flat_roof(d, 4, 123, 0, 14, SLATE, rng)
    # sign band
    d.rectangle([5, 15, 122, 29], fill=BLUE[0], outline=OUT)
    d.line([6, 16, 121, 16], fill=BLUE[2])
    for x in (16, 26, 36, 46, 78, 88, 98, 108):                                  # lettering blocks
        d.rectangle([x, 20, x + 6, 25], fill=(232, 236, 244))
    d.polygon([(64, 17), (67, 22), (72, 22), (68, 25), (70, 29), (64, 26), (58, 29), (60, 25), (56, 22), (61, 22)],
              fill=BRASS[1], outline=OUT)
    brick(d, 5, 30, 122, 111, BB, rng, bw=9, bh=4)
    d.rectangle([5, 30, 122, 111], outline=OUT)
    d.rectangle([6, 31, 121, 34], fill=shade(BB[0], 0.8))
    d.rectangle([5, 100, 122, 111], fill=SLATE[1], outline=OUT)                  # grey plinth
    d.line([6, 101, 121, 101], fill=SLATE[2])
    # barred windows (left of the door only; door hood spans x 60..99)
    for x in (10, 36):
        w = 20
        d.rectangle([x - 2, 52, x + w + 1, 82], fill=SLATE[2], outline=OUT)
        d.rectangle([x, 54, x + w - 1, 80], fill=GLASS[0], outline=OUT)
        d.rectangle([x, 54, x + w // 2 - 1, 62], fill=GLASS[1])
        for bx in range(x + 3, x + w - 1, 4):
            d.line([bx, 54, bx, 80], fill=IRON[1])
        d.rectangle([x - 3, 82, x + w + 2, 84], fill=SLATE[2], outline=OUT)
    d.rectangle([104, 54, 118, 80], fill=SLATE[2], outline=OUT)
    d.rectangle([106, 56, 116, 78], fill=GLOW[1], outline=OUT)
    d.rectangle([106, 56, 110, 62], fill=GLOW[2])
    d.line([111, 56, 111, 78], fill=IRON[1])
    for bx in (108, 114):
        d.line([bx, 56, bx, 78], fill=IRON[1])
    d.rectangle([103, 80, 119, 82], fill=SLATE[2], outline=OUT)
    # lamp bracket over the door (door x 64..95, top y 68)
    d.line([79, 48, 79, 56], fill=OUT)
    d.rectangle([73, 40, 86, 42], fill=IRON[1], outline=OUT)
    d.rectangle([75, 43, 84, 52], fill=(120, 190, 240), outline=OUT)             # blue police lamp
    d.rectangle([76, 44, 79, 47], fill=(220, 244, 255))
    d.rectangle([77, 52, 82, 53], fill=IRON[1], outline=OUT)
    glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(glow).ellipse([64, 38, 95, 60], fill=(120, 190, 240, 40))
    im.alpha_composite(glow); d = ImageDraw.Draw(im)
    d.rectangle([75, 43, 84, 52], outline=OUT)
    d.rectangle([76, 44, 79, 47], fill=(220, 244, 255))
    # door x 64..95
    d.rectangle([60, 62, 99, 67], fill=SLATE[2], outline=OUT)
    door(d, 64, 68, 111, [(52, 60, 84), (76, 88, 120), (104, 118, 152)], glass=True)
    save(im, "police_building.png")


def hospital_building():
    rng = random.Random(64)
    W, H = 160, 128
    im, d = new(W, H)
    WH = [(190, 200, 204), (226, 234, 236), (250, 252, 252)]
    # teal roof band
    d.rectangle([4, 0, 155, 18], fill=TEAL[1], outline=OUT)
    d.line([5, 1, 154, 1], fill=TEAL[2])
    for x in range(10, 150, 8):
        d.line([x, 4, x, 16], fill=TEAL[0])
    d.rectangle([2, 16, 157, 20], fill=WH[2], outline=OUT)
    # wall
    planks(d, 5, 21, 154, 127, [WH[0], WH[1], WH[2]], rng, pw=10)
    d.rectangle([5, 21, 154, 127], outline=OUT)
    d.rectangle([6, 22, 153, 25], fill=WH[0])
    # red-cross sign
    d.rectangle([66, 26, 93, 53], fill=WH[2], outline=OUT)
    d.rectangle([68, 28, 91, 51], outline=TEAL[1])
    cross(d, 80, 40, 9, t=3)
    d.line([68, 28, 91, 28], fill=(255, 255, 255))
    # windows (teal frames) two rows each side
    for x0 in (14, 40, 108, 134):
        for y0 in (34, 66):
            d.rectangle([x0 - 2, y0 - 2, x0 + 13, y0 + 17], fill=TEAL[1], outline=OUT)
            lit = (x0 + y0) % 3 == 0
            d.rectangle([x0, y0, x0 + 11, y0 + 15], fill=GLOW[1] if lit else GLASS[1], outline=OUT)
            d.rectangle([x0, y0, x0 + 4, y0 + 5], fill=GLOW[2] if lit else GLASS[2])
            d.line([x0 + 6, y0, x0 + 6, y0 + 15], fill=TEAL[1]); d.line([x0, y0 + 8, x0 + 11, y0 + 8], fill=TEAL[1])
    # teal canopy over door (door x 64..95)
    d.rectangle([54, 70, 105, 78], fill=TEAL[1], outline=OUT)
    d.line([55, 71, 104, 71], fill=TEAL[2]); d.line([55, 77, 104, 77], fill=TEAL[0])
    for x in (56, 102):
        d.rectangle([x, 78, x + 1, 120], fill=IRON[2], outline=OUT)
    d.rectangle([5, 118, 154, 127], fill=STONE[2], outline=OUT)
    d.line([6, 119, 153, 119], fill=(236, 234, 226))
    door(d, 64, 80, 127, [TEAL[0], TEAL[1], TEAL[2]], glass=True)
    save(im, "hospital_building.png")


def garage_building():
    rng = random.Random(65)
    W, H = 128, 104
    im, d = new(W, H)
    CON = [(112, 112, 108), (148, 148, 142), (180, 180, 172)]
    RED_ = [(150, 40, 40), (196, 58, 52), (226, 96, 80)]
    flat_roof(d, 3, 124, 0, 16, SLATE, rng)
    # sign band
    d.rectangle([4, 17, 123, 31], fill=RED_[1], outline=OUT)
    d.line([5, 18, 122, 18], fill=RED_[2])
    d.rectangle([14, 21, 36, 27], fill=CREAM[2], outline=OUT)
    d.line([45, 24, 110, 24], fill=CREAM[1]); d.line([45, 27, 96, 27], fill=CREAM[0])
    d.ellipse([100, 20, 112, 29], outline=IRON[3])                               # wheel emblem
    d.point([106, 24], fill=IRON[3])
    # wall
    brick(d, 4, 32, 123, 103, CON, rng, bw=10, bh=5)
    d.rectangle([4, 32, 123, 103], outline=OUT)
    d.rectangle([5, 33, 122, 36], fill=shade(CON[0], 0.8))
    # roller door x 72..118
    d.rectangle([69, 42, 121, 103], fill=IRON[2], outline=OUT)
    d.rectangle([71, 44, 119, 103], fill=IRON[1])
    for y in range(45, 103, 4):                                                  # corrugation
        d.line([72, y, 118, y], fill=IRON[3]); d.line([72, y + 1, 118, y + 1], fill=IRON[2])
        d.line([72, y + 3, 118, y + 3], fill=IRON[0])
    d.rectangle([92, 98, 98, 101], fill=IRON[0], outline=OUT)                    # handle
    d.rectangle([69, 42, 121, 46], fill=IRON[0], outline=OUT)                    # roller housing
    d.line([70, 43, 120, 43], fill=IRON[3])
    for y in (70, 78):
        d.line([72, y, 76, y], fill=(200, 160, 60))
    # window
    d.rectangle([8, 52, 24, 68], fill=IRON[2], outline=OUT)
    d.rectangle([10, 54, 22, 66], fill=GLASS[0], outline=OUT)
    d.rectangle([10, 54, 15, 59], fill=GLASS[1])
    d.line([16, 54, 16, 66], fill=IRON[2]); d.line([10, 60, 22, 60], fill=IRON[2])
    # side door x 32..64, top y 62
    d.rectangle([29, 58, 66, 62], fill=IRON[2], outline=OUT)
    d.rectangle([32, 63, 63, 103], fill=CON[2], outline=OUT)
    door(d, 32, 63, 103, [(70, 76, 80), (100, 108, 112), (132, 140, 144)], glass=False)
    d.rectangle([4, 100, 123, 103], fill=STONE[1], outline=OUT)
    d.line([5, 100, 122, 100], fill=STONE[2])
    door(d, 32, 63, 103, [(70, 76, 80), (100, 108, 112), (132, 140, 144)], glass=False)
    save(im, "garage_building.png")


def apartment(name, seed, wall_pal, trim, lit_pattern, balcony=False):
    rng = random.Random(seed)
    W, H = 96, 144
    im, d = new(W, H)
    # roof cap with parapet, tank/chimney
    d.rectangle([3, 6, 92, 14], fill=trim[1], outline=OUT)
    d.line([4, 7, 91, 7], fill=trim[2]); d.line([4, 13, 91, 13], fill=trim[0])
    d.rectangle([60, 0, 76, 7], fill=SLATE[1], outline=OUT)                      # roof box
    d.line([61, 1, 75, 1], fill=SLATE[2])
    d.rectangle([14, 1, 20, 7], fill=wall_pal[1], outline=OUT)                   # chimney
    d.rectangle([13, 0, 21, 2], fill=trim[2], outline=OUT)
    brick(d, 4, 15, 91, 143, wall_pal, rng, bw=8, bh=4)
    d.rectangle([4, 15, 91, 143], outline=OUT)
    # floor ledges
    rows = [20, 46, 72, 98]
    for y in rows[1:]:
        d.rectangle([4, y - 6, 91, y - 4], fill=trim[1], outline=OUT)
        d.line([5, y - 5, 90, y - 5], fill=trim[2])
    for ri, y in enumerate(rows):
        for ci, x in enumerate((10, 42, 74)):
            if ci == 1 and ri == 3:
                continue                                                     # door hood sits here
            lit = lit_pattern[ri][ci]
            d.rectangle([x - 2, y - 2, x + 13, y + 17], fill=trim[1], outline=OUT)
            d.rectangle([x, y, x + 11, y + 15], fill=GLOW[1] if lit else GLASS[0], outline=OUT)
            if lit:
                d.rectangle([x, y, x + 5, y + 6], fill=GLOW[2])
                if (ri + ci) % 2:
                    d.rectangle([x + 3, y + 8, x + 8, y + 15], fill=GLOW[0])      # curtain/figure blob
            else:
                d.rectangle([x, y, x + 5, y + 6], fill=GLASS[1])
                d.line([x + 1, y + 1, x + 3, y + 1], fill=GLASS[2])
            d.line([x + 6, y, x + 6, y + 15], fill=trim[1]); d.line([x, y + 8, x + 11, y + 8], fill=trim[1])
            d.rectangle([x - 3, y + 18, x + 14, y + 19], fill=trim[2], outline=OUT)
            if balcony and ri in (1, 3) and ci != 1:
                d.rectangle([x - 4, y + 12, x + 15, y + 19], fill=IRON[1], outline=OUT)
                for bx in range(x - 2, x + 15, 3):
                    d.line([bx, y + 13, bx, y + 18], fill=IRON[3])
    # ground floor: windows + door x 32..64
    for x in (8, 72):
        d.rectangle([x - 2, 118, x + 17, 134], fill=trim[1], outline=OUT)
        d.rectangle([x, 120, x + 15, 132], fill=GLOW[1] if x == 8 else GLASS[0], outline=OUT)
        d.line([x + 8, 120, x + 8, 132], fill=trim[1])
        d.rectangle([x, 120, x + 6, 124], fill=GLOW[2] if x == 8 else GLASS[1])
    d.rectangle([4, 138, 91, 143], fill=STONE[1], outline=OUT)
    d.line([5, 139, 90, 139], fill=STONE[2])
    d.rectangle([28, 108, 67, 113], fill=trim[2], outline=OUT)                   # door hood
    d.line([29, 109, 66, 109], fill=shade(trim[2], 1.15))
    door(d, 32, 114, 143, [(70, 56, 48), (100, 78, 62), (132, 104, 82)], glass=True)
    save(im, name)


def apartment_a():
    wp = [(104, 52, 44), (150, 80, 62), (178, 104, 80)]
    trim = [(150, 140, 120), (206, 196, 172), (240, 232, 208)]
    pat = [[1, 0, 1], [0, 1, 1], [1, 1, 0], [0, 1, 0]]
    apartment("apartment_a.png", 71, wp, trim, pat)


def apartment_b():
    wp = [(74, 92, 106), (108, 130, 144), (140, 162, 174)]
    trim = [(184, 170, 130), (226, 214, 170), (248, 240, 204)]
    pat = [[0, 1, 0], [1, 0, 1], [0, 0, 1], [1, 1, 0]]
    apartment("apartment_b.png", 72, wp, trim, pat, balcony=True)


def town_hall():
    rng = random.Random(66)
    W, H = 160, 128
    im, d = new(W, H)
    ST = [(150, 138, 118), (196, 184, 158), (226, 216, 190)]
    # clock tower (x 62..97)
    d.polygon([(62, 18), (80, 0), (97, 18)], fill=SLATE[1], outline=OUT)         # spire roof
    d.line([66, 15, 80, 2], fill=SLATE[2])
    d.line([80, 0, 80, -0], fill=BRASS[2])
    d.rectangle([62, 18, 97, 24], fill=ST[2], outline=OUT)
    blocks(d, 64, 24, 95, 66, ST, rng, bw=10, bh=6)
    d.rectangle([64, 24, 95, 66], outline=OUT)
    d.ellipse([67, 27, 92, 52], fill=ST[2], outline=OUT)                         # clock rim
    d.ellipse([69, 29, 90, 50], fill=(246, 242, 226), outline=BRASS[0])
    for a in range(12):
        import math
        t = a * math.pi / 6
        d.point([int(79.5 + 9 * math.sin(t)), int(39.5 - 9 * math.cos(t))], fill=OUT)
    d.line([79, 39, 79, 32], fill=OUT); d.line([80, 39, 84, 42], fill=OUT)       # hands
    d.point([79, 39], fill=RED[1])
    d.line([71, 31, 74, 30], fill=(255, 255, 255))
    for x in (62, 94):                                                           # corner trim
        d.rectangle([x, 24, x + 3, 66], fill=ST[2], outline=OUT)
    # main body roof band
    d.polygon([(4, 66), (20, 52), (140, 52), (156, 66)], fill=SLATE[1], outline=OUT)
    for y in range(55, 66, 4):
        d.line([max(6, 20 - (y - 52) * 1), y, min(154, 140 + (y - 52)), y], fill=SLATE[0])
    d.line([21, 53, 139, 53], fill=SLATE[2])
    d.rectangle([2, 66, 157, 70], fill=ST[2], outline=OUT)                       # cornice
    blocks(d, 4, 71, 155, 127, ST, rng)
    d.rectangle([4, 71, 155, 127], outline=OUT)
    d.rectangle([5, 72, 154, 75], fill=ST[0])
    # tall arched windows
    for x in (14, 38, 110, 134):
        d.rectangle([x - 2, 80, x + 15, 112], fill=ST[2], outline=OUT)
        d.rectangle([x, 82, x + 13, 112], fill=GLASS[1], outline=OUT)
        d.ellipse([x, 80, x + 13, 90], fill=GLASS[1], outline=OUT)
        d.rectangle([x, 86, x + 13, 112], fill=GLASS[1])
        d.line([x, 86, x, 112], fill=OUT); d.line([x + 13, 86, x + 13, 112], fill=OUT)
        d.rectangle([x, 83, x + 5, 90], fill=GLASS[2])
        d.line([x + 7, 81, x + 7, 112], fill=ST[2]); d.line([x, 98, x + 13, 98], fill=ST[2])
        d.rectangle([x - 3, 112, x + 16, 114], fill=ST[2], outline=OUT)
    # pilasters
    for x in (4, 56, 99, 150):
        d.rectangle([x, 71, x + 5, 127], fill=ST[2], outline=OUT)
    # door x 64..95 with arch
    d.rectangle([60, 82, 99, 127], fill=ST[2], outline=OUT)
    d.ellipse([60, 74, 99, 94], fill=ST[2], outline=OUT)
    d.rectangle([60, 85, 99, 127], fill=ST[2])
    d.line([60, 85, 60, 127], fill=OUT); d.line([99, 85, 99, 127], fill=OUT)
    d.pieslice([63, 78, 96, 96], 180, 360, fill=GLASS[1], outline=OUT)           # fanlight
    d.line([79, 78, 79, 87], fill=ST[2])
    d.rectangle([64, 87, 95, 118], fill=OUT)
    # flag
    d.line([80, -0, 80, 0], fill=OUT)
    # steps
    d.rectangle([54, 119, 105, 122], fill=ST[2], outline=OUT)
    d.rectangle([50, 123, 109, 127], fill=ST[1], outline=OUT)
    d.line([55, 120, 104, 120], fill=(244, 238, 218))
    door(d, 64, 88, 127, [DOOR[0], DOOR[1], DOOR[2]], glass=False)
    d.rectangle([46, 123, 113, 127], fill=ST[1], outline=OUT)
    d.line([47, 124, 112, 124], fill=ST[2])
    door(d, 64, 88, 127, [DOOR[0], DOOR[1], DOOR[2]], glass=False)
    save(im, "town_hall.png")


def cafe_building():
    rng = random.Random(67)
    W, H = 96, 96
    im, d = new(W, H)
    GR = [(52, 98, 64), (76, 138, 88), (116, 176, 118)]
    BRN = [(96, 60, 46), (126, 82, 62), (156, 106, 80)]
    # roof
    d.polygon([(2, 30), (14, 4), (82, 4), (94, 30)], fill=BRN[1], outline=OUT)
    mask = Image.new("L", (W, H), 0); ImageDraw.Draw(mask).polygon([(3, 29), (15, 5), (81, 5), (93, 29)], fill=255)
    tex, td = new(W, H)
    shingle_roof(td, None, 2, 94, 4, 30, BRN, rng, row_h=5, sw=7)
    im.paste(tex, (0, 0), mask)
    d = ImageDraw.Draw(im)
    d.polygon([(2, 30), (14, 4), (82, 4), (94, 30)], outline=OUT)
    d.line([16, 5, 80, 5], fill=BRN[2])
    d.line([2, 30, 94, 30], fill=OUT)
    # wall
    planks(d, 4, 31, 91, 95, [CREAM[0], CREAM[1], CREAM[2]], rng, pw=8)
    d.rectangle([4, 31, 91, 95], outline=OUT)
    d.rectangle([5, 32, 90, 35], fill=shade(CREAM[0], 0.75))
    # hanging sign
    d.line([78, 38, 78, 42], fill=OUT)
    d.rectangle([68, 42, 88, 52], fill=WOOD[1], outline=OUT)
    d.rectangle([75, 44, 80, 49], fill=CREAM[2]); d.rectangle([80, 45, 81, 47], outline=CREAM[2])  # cup icon
    im.alpha_composite(awning(d, 5, 90, 38, 50, GR[1], CREAM[2]))
    d = ImageDraw.Draw(im)
    # windows
    shop_win(d, 10, 58, 24, 76, WOOD[3])
    shop_win(d, 72, 58, 86, 76, WOOD[3])
    d.rectangle([8, 76, 26, 79], fill=WOOD[2], outline=OUT); d.rectangle([70, 76, 88, 79], fill=WOOD[2], outline=OUT)
    # door x 32..64
    door(d, 32, 56, 95, DOOR, glass=True)
    d.rectangle([4, 92, 91, 95], fill=STONE[1], outline=OUT)
    d.line([5, 92, 90, 92], fill=STONE[2])
    door(d, 32, 56, 95, DOOR, glass=True)
    # outdoor table and chairs (in front, bottom row = ground)
    for tx in (66,):
        d.ellipse([tx, 84, tx + 15, 90], fill=WOOD[3], outline=OUT)
        d.line([tx + 3, 86, tx + 8, 86], fill=WOOD[2])
        d.rectangle([tx + 7, 90, tx + 8, 94], fill=WOOD[0], outline=OUT)
        d.rectangle([tx - 5, 87, tx - 2, 94], fill=WOOD[2], outline=OUT)
        d.rectangle([tx + 17, 87, tx + 20, 94], fill=WOOD[2], outline=OUT)
        d.rectangle([tx + 3, 80, tx + 6, 84], fill=CREAM[2], outline=OUT)        # cup
    save(im, "cafe_building.png")


# ------------------------------------------------------------------ street furniture
def streetlamp():
    im, d = new(16, 48)
    glow = Image.new("RGBA", (16, 48), (0, 0, 0, 0))
    ImageDraw.Draw(glow).ellipse([0, 0, 15, 14], fill=(255, 220, 130, 50))
    im.alpha_composite(glow); d = ImageDraw.Draw(im)
    d.rectangle([5, 45, 10, 47], fill=IRON[1], outline=OUT)                      # base
    d.rectangle([4, 43, 11, 45], fill=IRON[2], outline=OUT)
    d.rectangle([7, 16, 8, 43], fill=IRON[1], outline=OUT)                       # post
    d.line([7, 17, 7, 42], fill=IRON[3])
    d.rectangle([6, 14, 9, 17], fill=IRON[2], outline=OUT)
    d.polygon([(3, 12), (12, 12), (11, 5), (4, 5)], fill=GLOW[1], outline=OUT)   # lamp head
    d.rectangle([5, 6, 7, 9], fill=GLOW[2])
    d.line([8, 6, 8, 11], fill=GLOW[0])
    d.polygon([(2, 5), (13, 5), (10, 1), (5, 1)], fill=IRON[1], outline=OUT)     # cap
    d.line([5, 2, 9, 2], fill=IRON[3])
    save(im, "streetlamp.png")


def bench():
    im, d = new(32, 20)
    shadow(d, 3, 19, 29)
    for x in (4, 25):                                                            # iron legs
        d.rectangle([x, 11, x + 2, 18], fill=IRON[1], outline=OUT)
        d.line([x + 1, 12, x + 1, 17], fill=IRON[3])
    box(d, 1, 1, 30, 5, WOOD[3]); d.line([3, 3, 28, 3], fill=WOOD[2])            # backrest top
    box(d, 1, 6, 30, 9, WOOD[2])                                                 # backrest low
    for x in (4, 25):
        d.rectangle([x, 1, x + 2, 12], fill=IRON[2], outline=OUT)
    box(d, 0, 11, 31, 15, WOOD[3]); d.line([2, 12, 29, 12], fill=shade(WOOD[3], 1.15))
    d.line([2, 14, 29, 14], fill=WOOD[1])
    save(im, "bench.png")


def planter():
    im, d = new(28, 22)
    shadow(d, 2, 21, 25)
    d.ellipse([3, 1, 24, 12], fill=(46, 96, 52), outline=OUT)                     # shrub
    d.ellipse([6, 0, 18, 8], fill=(66, 124, 64))
    for (x, y, c) in ((8, 3, (236, 120, 140)), (15, 5, (250, 220, 90)), (20, 4, (236, 120, 140)), (11, 8, (250, 220, 90))):
        d.rectangle([x, y, x + 1, y + 1], fill=c)                                 # blossoms
    d.rectangle([2, 11, 25, 19], fill=(150, 146, 138), outline=OUT)               # stone box
    d.line([3, 12, 24, 12], fill=(190, 186, 176))
    d.line([3, 18, 24, 18], fill=(110, 106, 100))
    save(im, "planter.png")


def fountain():
    rng = random.Random(68)
    im, d = new(64, 48)
    ST = [(120, 118, 112), (160, 158, 148), (200, 198, 186)]
    WA = [(70, 130, 176), (112, 176, 214), (190, 230, 246)]
    d.ellipse([2, 22, 61, 47], fill=ST[1], outline=OUT)                          # basin outer
    d.arc([3, 24, 60, 46], 20, 160, fill=ST[0])
    d.ellipse([5, 24, 58, 42], fill=ST[2], outline=OUT)                          # rim top
    d.ellipse([8, 26, 55, 40], fill=WA[0], outline=OUT)                          # water
    d.ellipse([10, 27, 53, 38], fill=WA[1])
    for _ in range(18):
        x = rng.randrange(14, 50); y = rng.randrange(29, 37)
        d.line([x, y, x + rng.randrange(2, 5), y], fill=WA[2])
    d.rectangle([30, 15, 33, 33], fill=ST[1], outline=OUT)                       # pedestal
    d.line([31, 16, 31, 32], fill=ST[2])
    d.ellipse([22, 20, 41, 28], fill=ST[2], outline=OUT)                         # upper bowl
    d.ellipse([24, 21, 39, 26], fill=WA[1])
    d.rectangle([30, 6, 33, 22], fill=ST[1], outline=OUT)
    d.ellipse([27, 3, 36, 9], fill=ST[2], outline=OUT)
    for x, y in ((31, 1), (31, 3), (28, 8), (35, 8), (25, 14), (38, 14), (22, 20), (41, 20)):  # spray
        d.point([x, y], fill=WA[2])
    d.line([31, 0, 31, 2], fill=WA[2]); d.line([32, 1, 32, 3], fill=WA[1])
    d.arc([22, 8, 31, 20], 200, 290, fill=WA[2]); d.arc([32, 8, 42, 20], 250, 340, fill=WA[2])
    for x in (12, 20, 31, 43, 51):                                               # stone seams on base
        d.line([x, 40, x, 45], fill=ST[0])
    save(im, "fountain.png")


# ------------------------------------------------------------------ interior furniture
def int_counter():
    im, d = new(64, 32)
    shadow(d, 2, 31, 61)
    box(d, 1, 14, 62, 30, WOOD[1])                                               # front panel
    for x in range(5, 60, 14):
        d.rectangle([x, 18, x + 9, 27], fill=WOOD[0], outline=OUT)
        d.line([x + 1, 19, x + 8, 19], fill=WOOD[2])
    box(d, 0, 8, 63, 15, WOOD[3])                                                # top surface
    d.line([2, 10, 61, 10], fill=shade(WOOD[3], 1.15))
    # till
    d.rectangle([40, 1, 55, 9], fill=IRON[1], outline=OUT)
    d.rectangle([42, 2, 53, 5], fill=(150, 210, 150), outline=OUT)               # display
    d.line([43, 3, 47, 3], fill=(220, 250, 220))
    d.rectangle([39, 8, 56, 12], fill=IRON[2], outline=OUT)
    for x in range(41, 55, 3):
        d.point([x, 10], fill=IRON[0])
    # goods + coins
    d.rectangle([6, 3, 12, 9], fill=RED[1], outline=OUT); d.line([7, 4, 7, 8], fill=RED[2])
    d.rectangle([14, 5, 19, 9], fill=GREEN[1], outline=OUT)
    d.ellipse([24, 6, 28, 9], fill=BRASS[1], outline=OUT); d.ellipse([27, 7, 31, 10], fill=BRASS[2], outline=OUT)
    save(im, "int_counter.png")


def int_teller():
    im, d = new(64, 32)
    shadow(d, 2, 31, 61)
    box(d, 1, 18, 62, 30, WOOD[0])                                               # lower counter
    d.rectangle([3, 21, 60, 28], fill=WOOD[1], outline=OUT)
    box(d, 0, 14, 63, 20, WOOD[3])                                               # ledge
    d.line([2, 16, 61, 16], fill=shade(WOOD[3], 1.15))
    # glass partition with brass frame
    d.rectangle([1, 1, 62, 14], fill=GLASS[1], outline=OUT)
    for x in (1, 21, 42, 61):
        d.rectangle([x, 1, x + 1, 14], fill=BRASS[1], outline=OUT)
    d.rectangle([1, 1, 62, 3], fill=BRASS[1], outline=OUT)
    d.line([3, 2, 60, 2], fill=BRASS[2])
    for x0 in (5, 25, 46):
        d.line([x0, 6, x0 + 4, 5], fill=GLASS[2]); d.line([x0, 8, x0 + 2, 7], fill=GLASS[2])
        d.rectangle([x0 + 3, 11, x0 + 12, 13], fill=OUT)                         # teller slot
        d.rectangle([x0 + 4, 11, x0 + 11, 12], fill=(30, 22, 18))
        for bx in range(x0 + 3, x0 + 13, 3):                                     # bars
            d.line([bx, 5, bx, 10], fill=BRASS[0])
    d.rectangle([29, 10, 34, 13], fill=CREAM[2], outline=OUT)                    # paper tray
    save(im, "int_teller.png")


def int_vault():
    import math
    im, d = new(32, 32)
    d.rectangle([0, 0, 31, 31], fill=IRON[0], outline=OUT)
    d.rectangle([2, 2, 29, 29], outline=IRON[2])
    d.ellipse([2, 2, 29, 29], fill=IRON[1], outline=OUT)                         # door
    d.ellipse([4, 4, 27, 27], fill=IRON[2], outline=OUT)
    d.arc([5, 5, 26, 26], 180, 270, fill=IRON[3])
    for k in range(10):                                                          # bolts
        t = k * math.pi / 5
        x = int(15.5 + 10 * math.cos(t)); y = int(15.5 + 10 * math.sin(t))
        d.rectangle([x - 1, y - 1, x, y], fill=IRON[0], outline=None)
        d.point([x - 1, y - 1], fill=IRON[3])
    d.ellipse([8, 8, 23, 23], fill=IRON[1], outline=OUT)
    d.ellipse([12, 12, 19, 19], fill=BRASS[1], outline=OUT)                      # hub
    d.point([13, 13], fill=BRASS[2])
    for k in range(3):                                                           # wheel spokes
        t = k * math.pi / 3
        dx, dy = 9 * math.cos(t), 9 * math.sin(t)
        d.line([15.5 - dx, 15.5 - dy, 15.5 + dx, 15.5 + dy], fill=BRASS[2], width=1)
    d.ellipse([12, 12, 19, 19], outline=OUT); d.rectangle([14, 14, 17, 17], fill=BRASS[2], outline=OUT)
    d.rectangle([27, 13, 30, 19], fill=IRON[0], outline=OUT)                     # hinge
    save(im, "int_vault.png")


def int_desk():
    im, d = new(64, 32)
    D = [(62, 70, 86), (84, 96, 118), (112, 126, 150)]
    shadow(d, 2, 31, 61)
    box(d, 1, 14, 62, 30, D[1], hi=D[2], lo=D[0])                                # front
    for x0 in (4, 40):
        d.rectangle([x0, 17, x0 + 19, 28], fill=D[0], outline=OUT)
        for y in (20, 24):
            d.rectangle([x0 + 2, y, x0 + 17, y + 2], fill=D[1], outline=OUT)
            d.rectangle([x0 + 8, y + 1, x0 + 11, y + 1], fill=BRASS[2])
    box(d, 0, 7, 63, 15, D[2], hi=shade(D[2], 1.15), lo=D[1])
    # computer monitor + keyboard
    d.rectangle([6, 0, 22, 9], fill=IRON[1], outline=OUT)
    d.rectangle([8, 1, 20, 7], fill=(70, 170, 130), outline=OUT)
    d.line([9, 3, 14, 3], fill=(170, 240, 200)); d.line([9, 5, 17, 5], fill=(110, 200, 160))
    d.rectangle([12, 9, 15, 10], fill=IRON[0])
    d.rectangle([25, 9, 40, 12], fill=IRON[3], outline=OUT)                      # keyboard
    # papers, lamp, name plate, phone
    d.rectangle([44, 5, 53, 11], fill=CREAM[2], outline=OUT); d.line([46, 7, 51, 7], fill=CREAM[0])
    d.rectangle([48, 3, 57, 9], fill=CREAM[1], outline=OUT)
    d.rectangle([58, 8, 62, 11], fill=BRASS[1], outline=OUT)                     # name plate
    d.rectangle([28, 3, 36, 6], fill=IRON[0], outline=OUT)                       # phone
    d.rectangle([29, 2, 35, 3], fill=IRON[2])
    save(im, "int_desk.png")


def int_cell():
    im, d = new(32, 64)
    d.rectangle([0, 0, 31, 63], fill=STONE[0], outline=OUT)
    d.rectangle([2, 4, 29, 59], fill=(52, 48, 54), outline=OUT)                  # dim interior
    d.rectangle([3, 40, 28, 58], fill=(70, 66, 72))                              # floor
    # bunk
    d.rectangle([4, 24, 17, 28], fill=IRON[1], outline=OUT)
    d.rectangle([4, 28, 17, 40], fill=(140, 150, 170), outline=OUT)
    d.rectangle([5, 29, 9, 33], fill=(210, 214, 222), outline=OUT)
    d.line([5, 36, 16, 36], fill=(110, 120, 140))
    d.rectangle([20, 44, 25, 50], fill=IRON[2], outline=OUT)                     # toilet bucket
    d.line([21, 45, 24, 45], fill=IRON[3])
    # top beam + bars
    d.rectangle([0, 0, 31, 5], fill=IRON[1], outline=OUT)
    d.line([1, 1, 30, 1], fill=IRON[3])
    for x in range(4, 30, 5):
        d.rectangle([x, 5, x + 1, 60], fill=IRON[2], outline=OUT)
        d.line([x, 6, x, 59], fill=IRON[3])
    for y in (22, 46):
        d.rectangle([2, y, 29, y + 1], fill=IRON[1], outline=OUT)
    d.rectangle([0, 59, 31, 63], fill=IRON[1], outline=OUT)
    d.line([1, 60, 30, 60], fill=IRON[3])
    d.rectangle([24, 36, 28, 40], fill=BRASS[1], outline=OUT)                    # lock
    d.point([26, 38], fill=OUT)
    save(im, "int_cell.png")


def int_hosp_bed():
    im, d = new(32, 64)
    WH = (240, 244, 246)
    shadow(d, 3, 63, 29)
    box(d, 1, 2, 30, 12, IRON[2])                                                # headboard rail
    d.rectangle([3, 4, 28, 6], fill=IRON[3])
    box(d, 1, 12, 30, 59, IRON[3])                                               # frame
    d.rectangle([3, 14, 28, 57], fill=WH, outline=OUT)                           # sheet
    d.rounded_rectangle([6, 15, 25, 25], radius=3, fill=(252, 253, 255), outline=OUT)
    d.line([8, 17, 22, 17], fill=(255, 255, 255)); d.line([8, 24, 23, 24], fill=(206, 214, 220))
    d.rectangle([3, 29, 28, 57], fill=TEAL[1], outline=OUT)                      # teal blanket
    d.rectangle([3, 29, 28, 33], fill=WH); d.line([3, 33, 28, 33], fill=OUT)
    for y in range(37, 57, 5):
        d.line([4, y, 27, y], fill=TEAL[2]); d.line([4, y + 1, 27, y + 1], fill=TEAL[0])
    d.line([4, 34, 4, 56], fill=TEAL[2])
    cross(d, 22, 43, 3, t=1)
    box(d, 1, 56, 30, 60, IRON[2])
    for x in (0, 28):                                                            # wheels
        d.rectangle([x, 58, x + 3, 63], fill=(30, 28, 32), outline=OUT)
        d.point([x + 1, 59], fill=IRON[2])
    for x in (0, 28):
        d.rectangle([x, 9, x + 3, 15], fill=IRON[2], outline=OUT)
    save(im, "int_hosp_bed.png")


def int_lift():
    im, d = new(64, 32)
    shadow(d, 2, 31, 61)
    # two ramp rails (hazard striped) on a base plate
    d.rectangle([1, 18, 62, 29], fill=IRON[1], outline=OUT)
    d.line([2, 19, 61, 19], fill=IRON[3])
    for y0 in (6, 17):
        pass
    for x0 in (3, 36):
        d.rectangle([x0, 8, x0 + 24, 20], fill=(222, 182, 56), outline=OUT)
        for k in range(x0 + 1, x0 + 24, 6):                                      # hazard stripes
            d.polygon([(k, 19), (k + 3, 19), (k + 6, 9), (k + 3, 9)], fill=(40, 36, 36))
        d.rectangle([x0, 8, x0 + 24, 20], outline=OUT)
        d.line([x0 + 1, 9, x0 + 23, 9], fill=(248, 220, 110))
        d.rectangle([x0 + 2, 20, x0 + 22, 24], fill=IRON[0], outline=OUT)
    # posts + hydraulic arm
    for x in (1, 58):
        d.rectangle([x, 0, x + 4, 24], fill=IRON[2], outline=OUT)
        d.line([x + 1, 1, x + 1, 23], fill=IRON[3])
        d.rectangle([x, 22, x + 4, 28], fill=IRON[1], outline=OUT)
    d.rectangle([5, 3, 57, 6], fill=IRON[1], outline=OUT)                        # crossbar
    d.line([6, 4, 56, 4], fill=IRON[3])
    d.rectangle([29, 6, 34, 18], fill=IRON[2], outline=OUT)                      # piston
    d.line([30, 7, 30, 17], fill=IRON[3])
    d.rectangle([27, 17, 36, 20], fill=RED[1], outline=OUT)
    save(im, "int_lift.png")


def int_tyres():
    im, d = new(32, 32)
    shadow(d, 3, 31, 28)
    for i, (x, y) in enumerate(((3, 21), (3, 15), (4, 9))):
        d.ellipse([x, y, x + 23, y + 9], fill=(30, 28, 30), outline=OUT)
        d.arc([x + 1, y + 1, x + 22, y + 8], 190, 350, fill=(86, 84, 88))
        d.ellipse([x + 7, y + 3, x + 16, y + 6], fill=(14, 12, 14), outline=(60, 58, 60))
    d.ellipse([3, 21, 26, 30], fill=(26, 24, 26), outline=OUT)                   # front tyre drawn last
    d.arc([4, 22, 25, 29], 190, 350, fill=(96, 94, 98))
    d.ellipse([10, 24, 19, 28], fill=IRON[2], outline=OUT)
    d.line([12, 25, 16, 25], fill=IRON[3])
    for k in range(5, 24, 4):
        d.point([k, 29], fill=(60, 58, 60))
    d.ellipse([4, 4, 28, 14], fill=(34, 32, 34), outline=OUT)                    # top tyre
    d.arc([5, 5, 27, 13], 190, 350, fill=(100, 98, 102))
    d.ellipse([11, 7, 21, 11], fill=(16, 14, 16), outline=(70, 68, 70))
    save(im, "int_tyres.png")


def int_medcab():
    im, d = new(32, 32)
    WH = (232, 238, 240)
    shadow(d, 2, 31, 29)
    box(d, 2, 1, 29, 30, WH, hi=(252, 254, 254), lo=(172, 184, 190))
    d.rectangle([2, 1, 29, 4], fill=TEAL[1], outline=OUT)                        # teal top
    d.line([3, 2, 28, 2], fill=TEAL[2])
    cross(d, 8, 9, 2, t=1)
    d.rectangle([5, 12, 26, 28], fill=GLASS[1], outline=OUT)                     # glass door
    d.line([6, 13, 9, 13], fill=GLASS[2]); d.line([6, 14, 7, 14], fill=GLASS[2])
    for y in (19, 25):                                                           # shelves
        d.line([5, y, 26, y], fill=WH)
        d.line([5, y + 1, 26, y + 1], fill=(150, 170, 176))
    for x, c in ((7, RED[1]), (11, GREEN[1]), (15, (222, 180, 70)), (19, BLUE[1]), (23, RED[2])):
        d.rectangle([x, 15, x + 2, 18], fill=c, outline=OUT)
        d.rectangle([x, 21, x + 2, 24], fill=shade(c, 1.1), outline=OUT)
    d.point([26, 20], fill=IRON[2]); d.rectangle([25, 8, 27, 11], fill=BRASS[1], outline=OUT)   # lock
    save(im, "int_medcab.png")


def int_register():
    im, d = new(32, 32)
    shadow(d, 3, 31, 28)
    box(d, 3, 18, 28, 30, WOOD[1])                                               # small stand
    d.rectangle([3, 18, 28, 21], fill=WOOD[3], outline=OUT)
    d.line([4, 19, 27, 19], fill=shade(WOOD[3], 1.15))
    d.rectangle([5, 23, 26, 28], fill=WOOD[0], outline=OUT)
    # register body
    d.polygon([(6, 18), (9, 8), (23, 8), (26, 18)], fill=IRON[1], outline=OUT)
    d.line([9, 9, 22, 9], fill=IRON[3])
    d.rectangle([7, 14, 25, 19], fill=IRON[2], outline=OUT)
    for y in (15, 17):                                                           # keys
        for x in range(9, 24, 3):
            d.rectangle([x, y, x + 1, y], fill=CREAM[2] if (x + y) % 2 else BRASS[2])
    d.rectangle([9, 2, 22, 8], fill=IRON[0], outline=OUT)                        # display
    d.rectangle([11, 3, 20, 6], fill=(150, 210, 150), outline=OUT)
    d.line([12, 4, 15, 4], fill=(224, 250, 224))
    d.rectangle([22, 19, 27, 20], fill=BRASS[1], outline=OUT)                    # drawer handle
    save(im, "int_register.png")


def main():
    os.makedirs(SPR, exist_ok=True)
    for fn in (shop_building, bank_building, police_building, hospital_building, garage_building,
               apartment_a, apartment_b, town_hall, cafe_building,
               streetlamp, bench, planter, fountain,
               int_counter, int_teller, int_vault, int_desk, int_cell, int_hosp_bed, int_lift,
               int_tyres, int_medcab, int_register):
        fn()


if __name__ == "__main__":
    main()
