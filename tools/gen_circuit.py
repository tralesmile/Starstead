#!/usr/bin/env python3
"""Circuit + sports props and interiors (original, CC0): grandstand, start gantry, tyre stack, pit
building, sports hall, football pitch, goal, pit flag, kerb tile, plus int_hoop/ring/punchbag/locker/
bench/scoreboard/pitdesk. Dark outline, 3-4 tones, light from top-left. Deterministic."""
import os
import random
from PIL import Image, ImageDraw
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SPR = os.path.join(ROOT, "assets", "sprites")
OUT = (42, 26, 16, 255)
W1, W2, W3, W4 = (206, 160, 100, 255), (168, 118, 68, 255), (122, 80, 46, 255), (86, 54, 32, 255)
RED, RED_L, RED_D = (200, 56, 52, 255), (236, 104, 88, 255), (140, 34, 40, 255)
WHITE, WHITE_D, WHITE_DD = (244, 244, 240, 255), (206, 214, 222, 255), (160, 172, 190, 255)
BLUE, BLUE_L, BLUE_D = (58, 112, 170, 255), (96, 156, 208, 255), (36, 70, 124, 255)
IRON, IRON_L, IRON_D = (92, 96, 108, 255), (140, 146, 160, 255), (58, 60, 72, 255)
CON, CON_L, CON_D = (148, 148, 142, 255), (190, 190, 182, 255), (108, 108, 106, 255)
ASPH, ASPH_L, ASPH_D = (84, 84, 92, 255), (112, 112, 122, 255), (56, 56, 64, 255)
ORANGE, ORANGE_L, ORANGE_D = (226, 128, 48, 255), (250, 176, 88, 255), (164, 80, 32, 255)
GOLD, GOLD_L, GOLD_D = (240, 196, 64, 255), (255, 232, 140, 255), (176, 128, 36, 255)
GLASS, GLASS_L = (150, 204, 232, 255), (220, 244, 255, 255)
BLACK = (30, 30, 36, 255)
SHADOW = (30, 24, 22, 110)


def canvas(w, h):
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    return im, ImageDraw.Draw(im)


def box(d, x0, y0, x1, y1, base, hi, lo, outline=OUT):
    d.rectangle([x0, y0, x1, y1], fill=base, outline=outline)
    d.line([(x0 + 1, y0 + 1), (x1 - 1, y0 + 1)], fill=hi)
    d.line([(x0 + 1, y0 + 1), (x0 + 1, y1 - 1)], fill=hi)
    d.line([(x0 + 1, y1 - 1), (x1 - 1, y1 - 1)], fill=lo)
    d.line([(x1 - 1, y0 + 2), (x1 - 1, y1 - 1)], fill=lo)


def save(im, name):
    im.save(os.path.join(SPR, name))
    print("wrote", name, im.size)


FONT = {"S": "111100111001111", "T": "111010010010010", "A": "010101111101101", "R": "110101110101101"}


def text(d, x, y, s, c, sc=2, gap=2):
    for ch in s:
        bits = FONT[ch]
        for i, b in enumerate(bits):
            if b == "1":
                px, py = x + (i % 3) * sc, y + (i // 3) * sc
                d.rectangle([px, py, px + sc - 1, py + sc - 1], fill=c)
        x += 3 * sc + gap


def checker(d, x0, y0, x1, y1, s=4, a=BLACK, b=WHITE):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            d.point((x, y), fill=a if (((x - x0) // s) + ((y - y0) // s)) % 2 == 0 else b)


# ---------------------------------------------------------------- grandstand 160x72
def grandstand():
    rng = random.Random(71)
    im, d = canvas(160, 72)
    # back wall
    d.rectangle([2, 12, 157, 67], fill=(70, 66, 84, 255), outline=OUT)
    cols = [RED, BLUE, GOLD, (90, 170, 90, 255), (230, 120, 170, 255), WHITE, ORANGE, (150, 100, 200, 255)]
    skin = [(240, 200, 160, 255), (214, 160, 116, 255), (160, 108, 72, 255), (250, 218, 184, 255)]
    # four tiers (benches), back to front; each tier 12px
    for t in range(4):
        y = 16 + t * 12
        d.rectangle([3, y + 8, 156, y + 11], fill=CON, outline=OUT)
        d.line([(4, y + 9), (155, y + 9)], fill=CON_L)
        d.line([(4, y + 11), (155, y + 11)], fill=CON_D)
        # bench plank
        d.rectangle([4, y + 6, 155, y + 8], fill=W2)
        d.line([(4, y + 6), (155, y + 6)], fill=W1)
        d.line([(4, y + 8), (155, y + 8)], fill=W3)
        x = 6 + rng.randint(0, 2)
        while x < 150:
            if rng.random() < 0.82:
                c = rng.choice(cols)
                sk = rng.choice(skin)
                d.rectangle([x, y + 1, x + 4, y + 5], fill=c, outline=OUT)
                d.point((x + 1, y + 2), fill=tuple(min(255, v + 36) for v in c[:3]) + (255,))
                d.rectangle([x, y - 3, x + 4, y], fill=sk, outline=OUT)
                d.point((x + 1, y - 2), fill=OUT); d.point((x + 3, y - 2), fill=OUT)
                if rng.random() < 0.3:
                    d.line([(x + 1, y - 3), (x + 3, y - 3)], fill=rng.choice([BLACK, W3, GOLD_D]))
                if rng.random() < 0.12:
                    d.line([(x + 4, y - 4), (x + 4, y + 1)], fill=OUT)  # raised flag
                    d.point((x + 5, y - 4), fill=rng.choice(cols))
            x += 7 + rng.randint(0, 2)
    # stair rail at front and base
    d.rectangle([0, 64, 159, 71], fill=CON, outline=OUT)
    d.line([(1, 65), (158, 65)], fill=CON_L)
    d.line([(1, 70), (158, 70)], fill=CON_D)
    for x in range(8, 156, 24):
        d.line([(x, 66), (x, 69)], fill=CON_D)
    # canopy roof (red/white stripes) with supports
    for px in (2, 78, 154):
        d.rectangle([px, 12, px + 3, 64], fill=IRON, outline=OUT)
        d.line([(px + 1, 13), (px + 1, 63)], fill=IRON_L)
    d.polygon([(0, 14), (6, 1), (153, 1), (159, 14)], fill=WHITE, outline=OUT)
    for x in range(8, 152, 12):
        d.polygon([(x, 2), (x + 6, 2), (x + 6 - 1, 13), (x - 1, 13)], fill=RED)
    d.line([(8, 2), (151, 2)], fill=WHITE)
    d.rectangle([0, 11, 159, 14], fill=RED, outline=OUT)
    d.line([(1, 12), (158, 12)], fill=RED_L)
    d.line([(1, 14), (158, 14)], fill=RED_D)
    for x in range(4, 156, 20):
        d.rectangle([x, 12, x + 9, 13], fill=WHITE)
    save(im, "grandstand.png")


# ---------------------------------------------------------------- start gantry 128x56
def start_gantry():
    im, d = canvas(128, 56)
    # posts (bottom at image bottom)
    for px in (4, 116):
        d.rectangle([px, 20, px + 7, 55], fill=IRON, outline=OUT)
        d.line([(px + 1, 21), (px + 1, 54)], fill=IRON_L)
        d.line([(px + 6, 21), (px + 6, 54)], fill=IRON_D)
        for y in range(26, 52, 8):
            d.line([(px + 2, y), (px + 5, y + 4)], fill=IRON_D)
        d.rectangle([px - 2, 50, px + 9, 55], fill=CON, outline=OUT)
        d.line([(px - 1, 51), (px + 8, 51)], fill=CON_L)
    # top truss
    d.rectangle([0, 0, 127, 4], fill=IRON, outline=OUT)
    d.line([(1, 1), (126, 1)], fill=IRON_L)
    for x in range(4, 124, 6):
        d.line([(x, 2), (x + 3, 3)], fill=IRON_D)
    # hanging banner
    d.rectangle([8, 5, 119, 30], fill=WHITE, outline=OUT)
    checker(d, 9, 6, 118, 13, 4, BLACK, WHITE)
    d.line([(9, 14), (118, 14)], fill=OUT)
    d.rectangle([9, 15, 118, 29], fill=RED)
    d.line([(9, 15), (118, 15)], fill=RED_L)
    d.line([(9, 29), (118, 29)], fill=RED_D)
    d.rectangle([40, 17, 87, 28], fill=WHITE, outline=OUT)
    text(d, 45, 19, "START", BLACK, 2, 2)
    # fold shading
    for x in (24, 104):
        d.line([(x, 15), (x, 29)], fill=RED_D)
    for x in (9, 118):
        d.line([(x, 15), (x, 29)], fill=RED_D)
    # lights (red) under truss
    for x in (22, 106):
        d.ellipse([x - 2, 31, x + 2, 35], fill=RED_L, outline=OUT)
    save(im, "start_gantry.png")


# ---------------------------------------------------------------- tyre stack 24x24
def tyre(d, y, c, cl, cd):
    d.rounded_rectangle([2, y, 21, y + 7], radius=3, fill=c, outline=OUT)
    d.line([(4, y + 1), (18, y + 1)], fill=cl)
    d.line([(4, y + 6), (19, y + 6)], fill=cd)
    for x in range(5, 20, 4):
        d.line([(x, y + 3), (x, y + 4)], fill=cd)


def tyre_stack():
    im, d = canvas(24, 24)
    d.ellipse([1, 20, 22, 23], fill=SHADOW)
    tyre(d, 15, RED, RED_L, RED_D)
    tyre(d, 9, WHITE, WHITE, WHITE_DD)
    tyre(d, 3, RED, RED_L, RED_D)
    # top tyre opening
    d.ellipse([7, 3, 16, 7], fill=BLACK, outline=OUT)
    d.line([(9, 4), (12, 4)], fill=(70, 70, 80, 255))
    # rim highlight
    d.line([(3, 11), (3, 14)], fill=WHITE)
    d.line([(3, 5), (3, 8)], fill=RED_L)
    save(im, "tyre_stack.png")


# ---------------------------------------------------------------- pit building 128x104
def roll_door(d, x0, x1, y0, y1, open_to=None, num=None):
    d.rectangle([x0 - 2, y0 - 2, x1 + 2, y1], fill=IRON_D, outline=OUT)
    d.rectangle([x0, y0, x1, y1], fill=(120, 126, 140, 255))
    top = open_to if open_to else y0
    if open_to:
        d.rectangle([x0, y0, x1, open_to - 1], fill=(30, 26, 34, 255))
        d.rectangle([x0, y0, x1, y0 + 1], fill=(58, 52, 62, 255))
    for y in range(top, y1, 3):
        d.line([(x0, y), (x1, y)], fill=IRON_L)
        d.line([(x0, y + 1), (x1, y + 1)], fill=(120, 126, 140, 255))
        d.line([(x0, y + 2), (x1, y + 2)], fill=IRON)
    d.line([(x0, top), (x0, y1)], fill=(170, 176, 190, 255))
    d.rectangle([x0, top, x1, top + 1], fill=IRON_D)
    d.rectangle([(x0 + x1) // 2 - 2, y1 - 3, (x0 + x1) // 2 + 2, y1 - 1], fill=IRON_D, outline=OUT)
    if num:
        px = (x0 + x1) // 2 - 4
        d.rectangle([px, y0 - 10, px + 8, y0 - 4], fill=WHITE, outline=OUT)
        for k in range(int(num)):
            d.line([(px + 2 + k * 2, y0 - 9), (px + 2 + k * 2, y0 - 5)], fill=RED_D)


def pit_building():
    rng = random.Random(81)
    im, d = canvas(128, 104)
    # roof (dark slate, flat)
    d.rectangle([3, 0, 124, 16], fill=(74, 78, 92, 255), outline=OUT)
    for y in range(3, 16, 3):
        d.line([(4, y), (123, y)], fill=(90, 94, 110, 255))
    d.line([(4, 1), (123, 1)], fill=(120, 126, 142, 255))
    # red/white stripe band
    d.rectangle([4, 17, 123, 31], fill=WHITE, outline=OUT)
    for x in range(4, 124, 16):
        d.rectangle([x, 18, min(x + 7, 122), 30], fill=RED)
    d.line([(5, 18), (122, 18)], fill=RED_L)
    d.line([(5, 30), (122, 30)], fill=RED_D)
    d.rectangle([44, 20, 83, 28], fill=BLACK, outline=OUT)
    checker(d, 45, 21, 82, 22, 2, BLACK, WHITE)
    for x in range(48, 80, 6):
        d.rectangle([x, 24, x + 3, 27], fill=WHITE)
    # wall (concrete blocks)
    d.rectangle([4, 32, 123, 103], fill=CON, outline=OUT)
    for y in range(37, 103, 5):
        d.line([(5, y), (122, y)], fill=CON_D)
        off = 5 if (y // 5) % 2 else 0
        for x in range(10 + off, 122, 10):
            d.line([(x, y), (x, y + 4)], fill=CON_D)
    for x in range(5, 123, 7):
        if rng.random() < 0.3:
            d.point((x, 33 + rng.randint(0, 60)), fill=CON_L)
    d.rectangle([5, 33, 122, 36], fill=CON_D)
    # three roll-up doors
    roll_door(d, 8, 26, 46, 99, None, "1")
    roll_door(d, 70, 92, 46, 99, 64, "2")
    roll_door(d, 98, 118, 46, 99, None, "3")
    # open entrance bay (door gap x 32..63)
    d.rectangle([29, 58, 66, 62], fill=RED, outline=OUT)
    d.line([(30, 59), (65, 59)], fill=RED_L)
    d.rectangle([32, 63, 63, 103], fill=(34, 30, 40, 255), outline=OUT)
    d.rectangle([34, 65, 61, 80], fill=(52, 48, 60, 255))
    d.line([(36, 70), (59, 70)], fill=(70, 66, 80, 255))
    d.rectangle([40, 76, 46, 80], fill=RED_D, outline=OUT)      # tool trolley hint
    d.rectangle([52, 72, 58, 80], fill=BLUE_D, outline=OUT)
    # base
    d.rectangle([4, 100, 123, 103], fill=CON_D, outline=OUT)
    d.line([(5, 100), (122, 100)], fill=CON)
    d.rectangle([32, 100, 63, 103], fill=(34, 30, 40, 255))
    # lamp
    d.rectangle([60, 38, 64, 41], fill=GOLD, outline=OUT)
    save(im, "pit_building.png")


# ---------------------------------------------------------------- sports hall 160x112
def sports_hall():
    im, d = canvas(160, 112)
    # barrel roof: rounded top
    d.rounded_rectangle([4, 0, 155, 44], radius=18, fill=BLUE, outline=OUT)
    d.rectangle([4, 24, 155, 44], fill=BLUE, outline=OUT)
    # ribs/panels (vertical white seams)
    for x in range(14, 152, 12):
        d.line([(x, 6 if 20 < x < 140 else 14), (x, 43)], fill=BLUE_D)
        d.line([(x + 1, 6 if 20 < x < 140 else 14), (x + 1, 43)], fill=BLUE_L)
    # top-left light and white ridge
    d.line([(20, 2), (140, 2)], fill=WHITE_D)
    d.line([(14, 4), (146, 4)], fill=BLUE_L)
    d.line([(6, 12), (10, 6)], fill=BLUE_L)
    d.line([(7, 20), (7, 40)], fill=BLUE_L)
    d.line([(8, 42), (152, 42)], fill=BLUE_D)
    # white eave stripe
    d.rectangle([4, 38, 155, 44], fill=WHITE, outline=OUT)
    d.line([(5, 39), (154, 39)], fill=(255, 255, 255, 255))
    d.line([(5, 43), (154, 43)], fill=WHITE_D)
    # wall
    d.rectangle([8, 45, 151, 111], fill=WHITE, outline=OUT)
    d.rectangle([9, 46, 150, 49], fill=WHITE_DD)
    for x in range(8, 152, 16):
        d.line([(x, 50), (x, 111)], fill=WHITE_D)
    # blue lower wainscot
    d.rectangle([9, 92, 150, 110], fill=BLUE)
    d.line([(9, 92), (150, 92)], fill=BLUE_L)
    for x in range(16, 150, 16):
        d.line([(x, 93), (x, 110)], fill=BLUE_D)
    # clerestory windows left/right
    for x0 in (16, 36, 108, 128):
        d.rectangle([x0, 56, x0 + 15, 72], fill=BLUE_D, outline=OUT)
        d.rectangle([x0 + 1, 57, x0 + 14, 71], fill=GLASS)
        d.rectangle([x0 + 1, 57, x0 + 6, 62], fill=GLASS_L)
        d.line([(x0 + 8, 57), (x0 + 8, 71)], fill=BLUE_D)
        d.line([(x0 + 1, 64), (x0 + 14, 64)], fill=BLUE_D)
    # emblem plaque with ball, centred above door
    d.rectangle([60, 48, 99, 72], fill=BLUE_D, outline=OUT)
    d.line([(61, 49), (98, 49)], fill=BLUE)
    d.ellipse([70, 50, 89, 70], fill=ORANGE, outline=OUT)
    d.arc([70, 50, 89, 70], 215, 290, fill=ORANGE_L)
    d.line([(70, 60), (89, 60)], fill=OUT)
    d.line([(79, 50), (79, 70)], fill=OUT)
    d.arc([66, 52, 80, 68], 300, 60, fill=OUT)
    d.arc([79, 52, 93, 68], 120, 240, fill=OUT)
    # letter blocks on plaque flanks
    for x in (63, 91):
        d.rectangle([x, 56, x + 5, 62], fill=WHITE)
    # double door x 64..95
    d.rectangle([62, 76, 97, 80], fill=BLUE_D, outline=OUT)
    d.rectangle([64, 81, 95, 111], fill=BLUE_D, outline=OUT)
    for x0, x1 in ((65, 79), (80, 94)):
        d.rectangle([x0, 82, x1, 111], fill=BLUE, outline=OUT)
        d.rectangle([x0 + 2, 85, x1 - 2, 98], fill=GLASS, outline=OUT)
        d.rectangle([x0 + 2, 85, x0 + 5, 88], fill=GLASS_L)
        d.line([(x0 + 1, 83), (x1 - 1, 83)], fill=BLUE_L)
    d.rectangle([77, 98, 78, 104], fill=IRON_L, outline=OUT)
    d.rectangle([81, 98, 82, 104], fill=IRON_L, outline=OUT)
    # stone base
    d.rectangle([8, 108, 151, 111], fill=CON, outline=OUT)
    d.line([(9, 108), (150, 108)], fill=CON_L)
    d.rectangle([64, 108, 95, 111], fill=BLUE_D)
    d.rectangle([64, 81, 95, 111], outline=OUT)
    save(im, "sports_hall.png")


# ---------------------------------------------------------------- football pitch 192x128
def football_pitch():
    rng = random.Random(91)
    W, H = 192, 128
    im = Image.new("RGBA", (W, H), (0, 0, 0, 255))
    d = ImageDraw.Draw(im)
    G1, G2 = (78, 150, 66, 255), (92, 168, 76, 255)
    for x in range(W):
        d.line([(x, 0), (x, H - 1)], fill=G1 if (x // 16) % 2 == 0 else G2)
    for _ in range(420):
        x, y = rng.randint(0, W - 1), rng.randint(0, H - 1)
        base = G1 if (x // 16) % 2 == 0 else G2
        k = rng.choice([-14, -8, 8, 14])
        d.point((x, y), fill=tuple(max(0, min(255, v + k)) for v in base[:3]) + (255,))
    L = (240, 244, 236, 255)
    d.rectangle([4, 4, W - 5, H - 5], outline=L)
    d.line([(W // 2, 4), (W // 2, H - 5)], fill=L)
    d.ellipse([W // 2 - 15, H // 2 - 15, W // 2 + 15, H // 2 + 15], outline=L)
    d.rectangle([W // 2 - 1, H // 2 - 1, W // 2 + 1, H // 2 + 1], fill=L)
    # penalty + goal boxes
    d.rectangle([4, 32, 33, 95], outline=L)
    d.rectangle([W - 34, 32, W - 5, 95], outline=L)
    d.rectangle([4, 49, 13, 78], outline=L)
    d.rectangle([W - 14, 49, W - 5, 78], outline=L)
    d.rectangle([23, 63, 24, 64], fill=L)
    d.rectangle([W - 25, 63, W - 24, 64], fill=L)
    d.arc([14, 50, 44, 78], 300, 60, fill=L)
    d.arc([W - 45, 50, W - 15, 78], 120, 240, fill=L)
    for (cx, cy, a0, a1) in ((4, 4, 0, 90), (W - 5, 4, 90, 180), (4, H - 5, 270, 360), (W - 5, H - 5, 180, 270)):
        d.arc([cx - 4, cy - 4, cx + 4, cy + 4], a0, a1, fill=L)
    save(im, "football_pitch.png")


# ---------------------------------------------------------------- goal post 40x40
def goal_post():
    im, d = canvas(40, 40)
    # net (back, slightly inset), drawn first
    d.polygon([(5, 9), (34, 9), (37, 37), (2, 37)], fill=(220, 226, 232, 60))
    NET = (196, 204, 214, 255)
    for x in range(5, 36, 3):
        d.line([(x, 9), (x + (x - 20) // 8, 37)], fill=NET)
    for y in range(11, 37, 3):
        d.line([(4 - (y - 9) // 10, y), (35 + (y - 9) // 10, y)], fill=NET)
    d.line([(5, 9), (2, 37)], fill=WHITE_DD)
    d.line([(34, 9), (37, 37)], fill=WHITE_DD)
    d.line([(2, 37), (37, 37)], fill=WHITE_DD)
    # posts and crossbar
    for px in (1, 36):
        d.rectangle([px, 4, px + 2, 39], fill=WHITE, outline=OUT)
        d.line([(px + 1, 5), (px + 1, 38)], fill=(255, 255, 255, 255))
        d.point((px + 2, 20), fill=WHITE_D)
    d.rectangle([1, 4, 38, 7], fill=WHITE, outline=OUT)
    d.line([(2, 5), (37, 5)], fill=(255, 255, 255, 255))
    d.line([(2, 7), (37, 7)], fill=WHITE_D)
    for x in range(8, 36, 8):  # painted red bands
        pass
    save(im, "goal_post.png")


# ---------------------------------------------------------------- pit flag 16x40
def pit_flag():
    im, d = canvas(16, 40)
    d.ellipse([0, 36, 9, 39], fill=SHADOW)
    d.rectangle([1, 33, 6, 39], fill=IRON, outline=OUT)
    d.line([(2, 34), (5, 34)], fill=IRON_L)
    d.rectangle([2, 2, 4, 35], fill=W2, outline=OUT)
    d.line([(3, 3), (3, 34)], fill=W1)
    d.ellipse([1, 0, 5, 3], fill=GOLD, outline=OUT)
    # waving checkered flag: 4px squares, columns shifted
    ox = 5
    for cx in range(3):
        for cy in range(2):
            x0 = ox + cx * 4
            y0 = 4 + cy * 4 + (1 if cx == 1 else 2 if cx == 2 else 0) - (0 if cx < 2 else 1)
            c = BLACK if (cx + cy) % 2 == 0 else WHITE
            d.rectangle([x0, y0, x0 + 3, y0 + 3], fill=c)
    d.line([(5, 4), (8, 4)], fill=OUT)
    d.line([(9, 5), (12, 5)], fill=OUT)
    d.line([(13, 5), (14, 5)], fill=OUT)
    d.line([(5, 12), (8, 13)], fill=OUT)
    d.line([(9, 13), (12, 14)], fill=OUT)
    d.line([(13, 13), (14, 13)], fill=OUT)
    d.line([(14, 6), (14, 13)], fill=OUT)
    save(im, "pit_flag.png")


# ---------------------------------------------------------------- track kerb 32x32 (tileable in x)
def track_kerb():
    im, d = canvas(32, 32)
    d.rectangle([0, 0, 31, 5], fill=ASPH)
    d.line([(0, 1), (31, 1)], fill=ASPH_L)
    d.line([(0, 5), (31, 5)], fill=ASPH_D)
    d.rectangle([0, 26, 31, 31], fill=(96, 120, 70, 255))
    for x in range(0, 32, 5):
        d.point((x + 1, 28 + (x // 5) % 3), fill=(120, 148, 88, 255))
    for i in range(4):
        x0 = i * 8
        c, cl, cd = (RED, RED_L, RED_D) if i % 2 == 0 else (WHITE, (255, 255, 255, 255), WHITE_DD)
        d.rectangle([x0, 6, x0 + 7, 25], fill=c)
        d.line([(x0, 7), (x0 + 7, 7)], fill=cl)
        d.line([(x0, 8), (x0 + 7, 8)], fill=cl)
        d.line([(x0, 24), (x0 + 7, 24)], fill=cd)
        d.line([(x0, 23), (x0 + 7, 23)], fill=cd)
        d.line([(x0 + 7, 9), (x0 + 7, 22)], fill=cd if i % 2 else RED_D)
    d.line([(0, 6), (31, 6)], fill=OUT)
    d.line([(0, 25), (31, 25)], fill=OUT)
    save(im, "track_kerb.png")


# ================================================================ INTERIORS
def int_hoop():
    im, d = canvas(32, 64)
    d.ellipse([3, 58, 29, 63], fill=SHADOW)
    # base
    d.rectangle([6, 54, 25, 62], fill=IRON, outline=OUT)
    d.line([(7, 55), (24, 55)], fill=IRON_L)
    d.line([(7, 61), (24, 61)], fill=IRON_D)
    # pole
    d.rectangle([14, 26, 17, 54], fill=IRON, outline=OUT)
    d.line([(15, 27), (15, 53)], fill=IRON_L)
    # backboard
    d.rectangle([3, 1, 28, 25], fill=BLUE_D, outline=OUT)
    d.rectangle([5, 3, 26, 23], fill=WHITE)
    d.line([(5, 3), (26, 3)], fill=(255, 255, 255, 255))
    d.line([(5, 23), (26, 23)], fill=WHITE_D)
    d.line([(26, 4), (26, 23)], fill=WHITE_D)
    d.rectangle([11, 11, 20, 20], outline=RED)
    # rim and net
    d.rectangle([10, 21, 21, 23], fill=ORANGE, outline=OUT)
    d.line([(11, 21), (20, 21)], fill=ORANGE_L)
    for x in (11, 14, 17, 20):
        d.line([(x, 24), (x + (1 if x < 16 else -1), 33)], fill=WHITE)
    d.line([(12, 29), (19, 29)], fill=WHITE_D)
    d.line([(13, 33), (18, 33)], fill=WHITE_D)
    # small ball on floor
    d.ellipse([20, 52, 29, 61], fill=ORANGE, outline=OUT)
    d.line([(20, 56), (29, 56)], fill=OUT)
    d.line([(24, 52), (24, 61)], fill=OUT)
    d.point((22, 54), fill=ORANGE_L)
    save(im, "int_hoop.png")


def int_ring():
    im, d = canvas(96, 96)
    d.rectangle([2, 18, 93, 94], fill=BLUE_D, outline=OUT)          # platform apron
    d.rectangle([3, 86, 92, 93], fill=BLUE_D)
    d.line([(3, 87), (92, 87)], fill=BLUE)
    d.rectangle([6, 22, 89, 84], fill=(226, 212, 176, 255), outline=OUT)   # canvas
    d.rectangle([7, 23, 88, 83], fill=(232, 220, 186, 255))
    for y in range(26, 83, 6):
        d.line([(8, y), (87, y)], fill=(220, 206, 170, 255))
    d.line([(7, 23), (88, 23)], fill=(250, 244, 220, 255))
    d.line([(7, 23), (7, 83)], fill=(250, 244, 220, 255))
    d.ellipse([34, 40, 61, 66], outline=RED)                         # centre circle
    d.ellipse([44, 49, 51, 57], fill=RED)
    d.rectangle([7, 62, 20, 83], fill=BLUE)                          # corner pads
    d.rectangle([75, 23, 88, 40], fill=RED)
    d.line([(7, 62), (20, 62)], fill=BLUE_L)
    d.line([(75, 23), (88, 23)], fill=RED_L)

    def rope(x0, y0, x1, y1):
        for k, c in enumerate((RED, WHITE, BLUE)):
            off = k * 6
            d.line([(x0, y0 + off), (x1, y1 + off)], fill=OUT, width=3)
            d.line([(x0, y0 + off), (x1, y1 + off)], fill=c)

    # right rope (back-right to front-right): drawn first, posts on top
    for k, c in enumerate((RED, WHITE, BLUE)):
        x = 90
        d.line([(x, 28 + k * 6), (x, 84)], fill=OUT, width=3)
        d.line([(x, 28 + k * 6), (x, 84)], fill=c)
    # back rope (back-left to back-right)
    rope(8, 12, 90, 12)
    # posts: back-left, back-right, front-right (front-left corner open)
    for (px, py, h) in ((3, 18, 22), (86, 18, 22), (86, 78, 22)):
        pass
    for (px, top, bot) in ((3, 4, 30), (85, 4, 30), (85, 62, 90)):
        d.rectangle([px, top, px + 6, bot], fill=IRON, outline=OUT)
        d.line([(px + 1, top + 1), (px + 1, bot - 1)], fill=IRON_L)
        d.rectangle([px, top, px + 6, top + 3], fill=RED, outline=OUT)
    # redraw ropes where they touch posts
    save(im, "int_ring.png")


def int_punchbag():
    im, d = canvas(32, 64)
    d.ellipse([6, 59, 25, 63], fill=SHADOW)
    d.rectangle([11, 0, 20, 3], fill=IRON, outline=OUT)
    d.line([(12, 1), (19, 1)], fill=IRON_L)
    d.line([(14, 4), (14, 12)], fill=IRON_D)
    d.line([(17, 4), (17, 12)], fill=IRON_D)
    d.line([(15, 4), (15, 12)], fill=IRON_L)
    d.line([(16, 4), (16, 12)], fill=OUT)
    d.rectangle([9, 12, 22, 56], fill=RED, outline=OUT)
    d.line([(10, 13), (21, 13)], fill=RED_L)
    d.line([(11, 14), (11, 54)], fill=RED_L)
    d.line([(12, 14), (12, 54)], fill=(220, 84, 72, 255))
    d.line([(20, 14), (20, 54)], fill=RED_D)
    d.line([(21, 14), (21, 54)], fill=RED_D)
    for y in (22, 34, 46):
        d.line([(10, y), (21, y)], fill=OUT)
        d.line([(10, y + 1), (21, y + 1)], fill=BLACK)
    d.line([(10, 55), (21, 55)], fill=RED_D)
    d.rectangle([13, 28, 18, 31], fill=WHITE, outline=OUT)
    save(im, "int_punchbag.png")


def int_locker():
    im, d = canvas(32, 32)
    for i, x0 in enumerate((1, 16)):
        c, cl, cd = (BLUE, BLUE_L, BLUE_D) if i == 0 else (IRON_L, (190, 196, 210, 255), IRON)
        d.rectangle([x0, 2, x0 + 14, 30], fill=c, outline=OUT)
        d.line([(x0 + 1, 3), (x0 + 13, 3)], fill=cl)
        d.line([(x0 + 1, 3), (x0 + 1, 29)], fill=cl)
        d.line([(x0 + 13, 4), (x0 + 13, 29)], fill=cd)
        d.line([(x0 + 1, 29), (x0 + 13, 29)], fill=cd)
        for y in (6, 8, 10):
            d.line([(x0 + 4, y), (x0 + 10, y)], fill=cd)
        d.line([(x0 + 3, 14), (x0 + 11, 14)], fill=cd)
        d.rectangle([x0 + 9, 17, x0 + 11, 21], fill=IRON_D, outline=OUT)
        d.point((x0 + 10, 18), fill=IRON_L)
        d.rectangle([x0 + 4, 24, x0 + 6, 26], fill=WHITE, outline=OUT)   # name tag
    d.line([(15, 3), (15, 29)], fill=OUT)
    d.rectangle([0, 30, 31, 31], fill=IRON_D)
    save(im, "int_locker.png")


def int_bench():
    im, d = canvas(64, 32)
    d.ellipse([3, 27, 60, 31], fill=SHADOW)
    # rack uprights + barbell
    for x in (8, 52):
        d.rectangle([x, 4, x + 3, 28], fill=IRON, outline=OUT)
        d.line([(x + 1, 5), (x + 1, 27)], fill=IRON_L)
        d.rectangle([x - 2, 26, x + 5, 29], fill=IRON_D, outline=OUT)
    d.line([(2, 6), (61, 6)], fill=OUT)
    d.line([(2, 5), (61, 5)], fill=IRON_L)
    for x in (3, 56):
        d.rectangle([x, 1, x + 4, 11], fill=BLACK, outline=OUT)
        d.line([(x + 1, 2), (x + 1, 10)], fill=IRON)
    # padded bench
    d.rectangle([14, 15, 49, 21], fill=BLUE_D, outline=OUT)
    d.line([(15, 16), (48, 16)], fill=BLUE_L)
    d.line([(15, 20), (48, 20)], fill=(30, 56, 100, 255))
    d.line([(14, 18), (49, 18)], fill=BLUE)
    for x in (18, 44):
        d.rectangle([x, 22, x + 2, 29], fill=IRON, outline=OUT)
        d.line([(x + 1, 23), (x + 1, 28)], fill=IRON_L)
    d.line([(20, 22), (44, 22)], fill=IRON_D)
    save(im, "int_bench.png")


SEG = {0: "abcdef", 1: "bc", 2: "abdeg", 3: "abcdg", 4: "bcfg", 5: "acdfg", 6: "acdefg", 7: "abc", 8: "abcdefg", 9: "abcdfg"}


def digit(d, x, y, n, on, off):
    w, h = 6, 10
    segs = {"a": (x + 1, y, x + w - 1, y), "b": (x + w, y + 1, x + w, y + h // 2 - 1),
            "c": (x + w, y + h // 2 + 1, x + w, y + h - 1), "d": (x + 1, y + h, x + w - 1, y + h),
            "e": (x, y + h // 2 + 1, x, y + h - 1), "f": (x, y + 1, x, y + h // 2 - 1),
            "g": (x + 1, y + h // 2, x + w - 1, y + h // 2)}
    for k, (a, b, c, e) in segs.items():
        d.line([(a, b), (c, e)], fill=on if k in SEG[n] else off)


def int_scoreboard():
    im, d = canvas(64, 32)
    d.rectangle([1, 2, 62, 30], fill=IRON_D, outline=OUT)
    d.line([(2, 3), (61, 3)], fill=IRON)
    d.rectangle([4, 5, 59, 27], fill=(14, 18, 28, 255), outline=OUT)
    d.rectangle([6, 6, 28, 9], fill=RED_D)
    d.rectangle([35, 6, 57, 9], fill=BLUE_D)
    d.text((9, 4), "", fill=WHITE)
    for x in range(8, 27, 4):
        d.point((x, 8), fill=RED_L)
    for x in range(37, 56, 4):
        d.point((x, 8), fill=BLUE_L)
    on, off = (255, 190, 60, 255), (60, 40, 26, 255)
    digit(d, 8, 13, 0, on, off)
    digit(d, 17, 13, 8, on, off)
    digit(d, 38, 13, 1, on, off)
    digit(d, 47, 13, 2, on, off)
    d.rectangle([31, 16, 32, 17], fill=on)
    d.rectangle([31, 21, 32, 22], fill=on)
    d.line([(2, 2), (61, 2)], fill=OUT)
    d.rectangle([0, 28, 63, 31], fill=IRON, outline=OUT)
    d.line([(1, 29), (62, 29)], fill=IRON_L)
    save(im, "int_scoreboard.png")


def int_pitdesk():
    im, d = canvas(64, 32)
    d.rectangle([2, 12, 61, 30], fill=W2, outline=OUT)
    d.rectangle([2, 12, 61, 17], fill=W1, outline=OUT)
    d.line([(3, 13), (60, 13)], fill=(236, 200, 140, 255))
    d.line([(3, 17), (60, 17)], fill=W3)
    # drawers
    for x0 in (6, 36):
        d.rectangle([x0, 20, x0 + 20, 28], fill=W3, outline=OUT)
        d.line([(x0 + 1, 21), (x0 + 19, 21)], fill=W2)
        d.rectangle([x0 + 8, 23, x0 + 12, 24], fill=GOLD)
    d.line([(3, 29), (60, 29)], fill=W4)
    # trophy (left)
    d.rectangle([9, 11, 15, 12], fill=GOLD_D, outline=OUT)
    d.rectangle([11, 7, 13, 10], fill=GOLD, outline=OUT)
    d.polygon([(7, 1), (17, 1), (16, 4), (13, 7), (11, 7), (8, 4)], fill=GOLD, outline=OUT)
    d.line([(8, 2), (10, 2)], fill=GOLD_L)
    d.point((6, 3), fill=OUT); d.point((18, 3), fill=OUT)
    # paperwork
    d.rectangle([24, 8, 33, 12], fill=(240, 232, 204, 255), outline=OUT)
    d.line([(26, 10), (31, 10)], fill=(150, 120, 90, 255))
    # checkered flag in a stand (right)
    d.rectangle([47, 10, 53, 12], fill=IRON, outline=OUT)
    d.line([(50, 0), (50, 10)], fill=OUT)
    d.line([(51, 1), (51, 9)], fill=W1)
    for cx in range(3):
        for cy in range(2):
            c = BLACK if (cx + cy) % 2 == 0 else WHITE
            d.rectangle([52 + cx * 3, 1 + cy * 3, 54 + cx * 3, 3 + cy * 3], fill=c)
    d.rectangle([52, 0, 60, 0], fill=OUT)
    d.rectangle([52, 7, 60, 7], fill=OUT)
    d.line([(61, 1), (61, 6)], fill=OUT)
    save(im, "int_pitdesk.png")


if __name__ == "__main__":
    grandstand(); start_gantry(); tyre_stack(); pit_building(); sports_hall(); football_pitch()
    goal_post(); pit_flag(); track_kerb()
    int_hoop(); int_ring(); int_punchbag(); int_locker(); int_bench(); int_scoreboard(); int_pitdesk()
