#!/usr/bin/env python3
"""Harbour props (original, CC0): contest board, smuggle crate, moored boat, bollard, barrel,
fish crate, net pile, lighthouse. Dark outline, 3-4 tones, light from top-left. Deterministic."""
import os
from PIL import Image, ImageDraw
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SPR = os.path.join(ROOT, "assets", "sprites")
OUT = (42, 26, 16, 255)
# wood tones: light, mid, dark, darkest
W1, W2, W3, W4 = (206, 160, 100, 255), (168, 118, 68, 255), (122, 80, 46, 255), (86, 54, 32, 255)
RED, RED_L, RED_D = (200, 56, 52, 255), (236, 104, 88, 255), (140, 34, 40, 255)
WHITE, WHITE_D, WHITE_DD = (244, 244, 240, 255), (206, 214, 222, 255), (160, 172, 190, 255)
BLUE, BLUE_L, BLUE_D = (58, 112, 170, 255), (96, 156, 208, 255), (36, 70, 124, 255)
IRON, IRON_L, IRON_D = (92, 96, 108, 255), (140, 146, 160, 255), (58, 60, 72, 255)
ROPE, ROPE_D = (214, 186, 120, 255), (160, 130, 78, 255)
TAR = (34, 28, 30, 255)
SILVER, SILVER_L, SILVER_D = (176, 196, 214, 255), (236, 244, 250, 255), (120, 142, 168, 255)

def canvas(w, h):
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    return im, ImageDraw.Draw(im)

def box(d, x0, y0, x1, y1, base, hi, lo, outline=OUT):
    """Outlined rect with highlight on top/left and shadow on bottom/right."""
    d.rectangle([x0, y0, x1, y1], fill=base, outline=outline)
    d.line([(x0 + 1, y0 + 1), (x1 - 1, y0 + 1)], fill=hi)
    d.line([(x0 + 1, y0 + 1), (x0 + 1, y1 - 1)], fill=hi)
    d.line([(x0 + 1, y1 - 1), (x1 - 1, y1 - 1)], fill=lo)
    d.line([(x1 - 1, y0 + 2), (x1 - 1, y1 - 1)], fill=lo)

def planks(d, x0, y0, x1, y1, step=4, c=W3):
    for y in range(y0 + step, y1, step):
        d.line([(x0 + 1, y), (x1 - 1, y)], fill=c)

def save(im, name):
    im.save(os.path.join(SPR, name))
    print("wrote", name, im.size)

def fish_shape(d, x, y, body, belly, tail, flip=False):
    """Tiny 9x4 fish silhouette with outline at (x,y) top-left."""
    pts = [(x + 1, y), (x + 2, y), (x + 3, y), (x + 4, y), (x + 5, y)]
    d.ellipse([x, y, x + 6, y + 4], fill=body, outline=OUT)
    d.line([(x + 2, y + 3), (x + 4, y + 3)], fill=belly)
    d.polygon([(x + 6, y + 2), (x + 9, y), (x + 9, y + 4)], fill=tail, outline=OUT)
    d.point((x + 1, y + 1), fill=(255, 255, 255, 255))

# ---------------------------------------------------------------- contest board 32x48
def contest_board():
    im, d = canvas(32, 48)
    # posts
    for px in (4, 24):
        box(d, px, 12, px + 3, 46, W2, W1, W3)
        d.line([(px + 1, 40), (px + 2, 40)], fill=W4)
    # foot shadows
    d.rectangle([2, 45, 8, 47], fill=W3, outline=OUT)
    d.rectangle([23, 45, 29, 47], fill=W3, outline=OUT)
    # board
    box(d, 1, 12, 30, 34, W1, (236, 200, 140, 255), W3)
    d.rectangle([3, 14, 28, 32], fill=W2)
    d.line([(4, 15), (27, 15)], fill=W1)
    d.line([(4, 15), (4, 31)], fill=W1)
    d.line([(4, 31), (27, 31)], fill=W3)
    d.line([(27, 16), (27, 31)], fill=W3)
    # parchment notes
    d.rectangle([5, 17, 12, 24], fill=(240, 228, 196, 255), outline=OUT)
    d.line([(6, 19), (11, 19)], fill=(150, 120, 90, 255))
    d.line([(6, 21), (10, 21)], fill=(150, 120, 90, 255))
    d.point((8, 17), fill=RED)  # pin
    d.rectangle([5, 26, 11, 30], fill=(228, 214, 180, 255), outline=OUT)
    d.line([(6, 28), (10, 28)], fill=(150, 120, 90, 255))
    d.rectangle([22, 18, 26, 23], fill=(240, 228, 196, 255), outline=OUT)
    d.line([(23, 20), (25, 20)], fill=(150, 120, 90, 255))
    # fish banner pinned in the middle
    d.polygon([(13, 21), (14, 20), (18, 20), (21, 23), (22, 20), (23, 20), (23, 28), (22, 28), (21, 25), (18, 28), (14, 28), (13, 27)],
              fill=BLUE, outline=OUT)
    d.line([(14, 21), (18, 21)], fill=BLUE_L)
    d.line([(14, 26), (18, 26)], fill=SILVER_L)
    d.point((15, 23), fill=(255, 255, 255, 255)); d.point((15, 24), fill=OUT)
    d.line([(17, 22), (17, 25)], fill=BLUE_D)
    d.point((16, 19), fill=RED); d.point((20, 19), fill=RED)
    # roof cap
    box(d, 0, 9, 31, 12, W3, W2, W4)
    # pole + red flag on right post
    d.line([(26, 0), (26, 8)], fill=OUT)
    d.line([(25, 1), (25, 8)], fill=W2)
    d.polygon([(27, 1), (31, 3), (27, 5)], fill=RED, outline=OUT)
    d.point((28, 3), fill=RED_L)
    save(im, "contest_board.png")

# ---------------------------------------------------------------- smuggle crate 32x32
def smuggle_crate():
    im, d = canvas(32, 32)
    d.ellipse([3, 27, 29, 31], fill=(30, 24, 22, 110))  # ground shadow
    box(d, 3, 9, 27, 28, W3, W2, W4)
    planks(d, 3, 9, 27, 28, 5, W4)
    # slats on front
    d.line([(4, 12), (26, 12)], fill=W2)
    # dark corner bracing
    for x in (3, 25):
        d.rectangle([x, 9, x + 2, 28], fill=W4, outline=OUT)
    # tarry seals
    for (sx, sy) in ((9, 14), (16, 22), (20, 13)):
        d.ellipse([sx, sy, sx + 4, sy + 3], fill=TAR, outline=OUT)
        d.point((sx + 1, sy + 1), fill=(86, 76, 78, 255))
    # rope round the crate
    d.line([(12, 9), (12, 28)], fill=ROPE)
    d.line([(13, 9), (13, 28)], fill=ROPE_D)
    d.line([(3, 20), (27, 20)], fill=ROPE)
    d.line([(3, 21), (27, 21)], fill=ROPE_D)
    d.rectangle([11, 19, 14, 22], fill=ROPE, outline=ROPE_D)  # knot
    d.line([(14, 22), (16, 26)], fill=ROPE_D)
    # tarpaulin corner draped on top right
    d.polygon([(14, 8), (24, 4), (30, 8), (31, 15), (27, 17), (26, 12), (20, 11)], fill=(60, 78, 92, 255), outline=OUT)
    d.line([(16, 8), (23, 5)], fill=(96, 118, 132, 255))
    d.line([(24, 6), (29, 9)], fill=(96, 118, 132, 255))
    d.line([(21, 11), (26, 13)], fill=(38, 50, 62, 255))
    d.line([(27, 13), (29, 14)], fill=(38, 50, 62, 255))
    # red stripe (matches the crate icon) on front-left
    d.rectangle([6, 10, 7, 27], fill=RED)
    d.point((6, 11), fill=RED_L)
    # top edge of lid
    d.line([(4, 9), (13, 9)], fill=W1)
    save(im, "smuggle_crate.png")

# ---------------------------------------------------------------- moored boat 96x64
def moored_boat():
    im, d = canvas(96, 64)
    # waterline ripple shadow at the bottom
    d.ellipse([6, 56, 90, 63], fill=(20, 50, 90, 90))
    # hull (seen slightly from above): polygon deck outline, then side
    hull = [(6, 30), (84, 30), (92, 36), (82, 56), (16, 56), (8, 40)]
    d.polygon(hull, fill=BLUE, outline=OUT)
    # white upper strake
    d.polygon([(6, 30), (84, 30), (88, 34), (9, 34)], fill=WHITE, outline=OUT)
    d.line([(10, 33), (86, 33)], fill=WHITE_D)
    # blue hull shading
    d.line([(12, 36), (87, 36)], fill=BLUE_L)
    d.line([(15, 54), (82, 54)], fill=BLUE_D)
    d.line([(14, 50), (84, 50)], fill=BLUE_D)
    # plank lines
    for y in (41, 46):
        d.line([(10 + (y - 36) // 2, y), (89 - (y - 36) // 2, y)], fill=BLUE_D)
    # white waterline band
    d.line([(17, 55), (81, 55)], fill=WHITE_D)
    # deck interior (wood) seen from above
    d.polygon([(10, 22), (82, 22), (90, 30), (8, 30)], fill=W2, outline=OUT)
    d.line([(12, 24), (81, 24)], fill=W1)
    for x in range(14, 84, 8):
        d.line([(x, 25), (x - 1, 29)], fill=W3)
    # gunwale
    d.line([(6, 30), (84, 30)], fill=OUT)
    # cabin (left-centre)
    box(d, 20, 6, 48, 26, WHITE, WHITE, WHITE_D)
    d.rectangle([20, 6, 48, 26], outline=OUT)
    d.rectangle([21, 7, 47, 25], fill=WHITE)
    d.line([(22, 8), (46, 8)], fill=(255, 255, 255, 255))
    d.line([(22, 24), (46, 24)], fill=WHITE_D)
    d.line([(46, 9), (46, 24)], fill=WHITE_D)
    # cabin roof (red)
    d.polygon([(17, 8), (23, 2), (46, 2), (52, 8)], fill=RED, outline=OUT)
    d.line([(24, 3), (45, 3)], fill=RED_L)
    d.line([(19, 7), (50, 7)], fill=RED_D)
    # windows
    for wx in (24, 37):
        d.rectangle([wx, 12, wx + 7, 19], fill=(150, 204, 232, 255), outline=OUT)
        d.line([(wx + 1, 13), (wx + 3, 13)], fill=(220, 244, 255, 255))
        d.line([(wx + 4, 12), (wx + 4, 19)], fill=OUT)
    # door-less base line
    d.line([(21, 25), (47, 25)], fill=OUT)
    # mast + flag
    d.line([(64, 4), (64, 24)], fill=OUT)
    d.line([(65, 5), (65, 24)], fill=W2)
    d.polygon([(66, 4), (74, 7), (66, 10)], fill=RED, outline=OUT)
    # crates / nets on deck
    box(d, 54, 17, 62, 25, W3, W2, W4)
    d.line([(55, 21), (61, 21)], fill=W4)
    # life ring on cabin side
    d.ellipse([68, 14, 78, 24], fill=WHITE, outline=OUT)
    d.ellipse([71, 17, 75, 21], fill=W2, outline=OUT)
    d.line([(69, 19), (70, 19)], fill=RED); d.line([(76, 19), (77, 19)], fill=RED)
    # bow ropes: cleat + rope dropping into the water
    d.rectangle([84, 27, 87, 29], fill=IRON, outline=OUT)
    d.line([(88, 29), (92, 38), (94, 50), (93, 58)], fill=ROPE_D, width=2)
    d.line([(87, 29), (91, 38), (93, 50), (92, 58)], fill=ROPE)
    # stern rope
    d.rectangle([8, 27, 11, 29], fill=IRON, outline=OUT)
    d.line([(7, 29), (3, 38), (2, 50), (3, 58)], fill=ROPE_D, width=2)
    d.line([(8, 29), (4, 38), (3, 50), (4, 58)], fill=ROPE)
    # fenders (hanging rope floats) along hull
    for fx in (30, 58):
        d.ellipse([fx, 38, fx + 5, 47], fill=(236, 196, 80, 255), outline=OUT)
        d.line([(fx + 1, 39), (fx + 1, 44)], fill=(255, 232, 150, 255))
    save(im, "moored_boat.png")

# ---------------------------------------------------------------- bollard 16x24
def bollard():
    im, d = canvas(16, 24)
    d.ellipse([1, 19, 14, 23], fill=(30, 24, 22, 110))
    # base plate
    d.rectangle([2, 18, 13, 21], fill=IRON, outline=OUT)
    d.line([(3, 19), (12, 19)], fill=IRON_L)
    d.line([(3, 21), (12, 21)], fill=IRON_D)
    # body (slightly narrower in the middle)
    d.polygon([(4, 18), (4, 9), (3, 8), (3, 5), (12, 5), (12, 8), (11, 9), (11, 18)], fill=IRON, outline=OUT)
    d.line([(5, 9), (5, 17)], fill=IRON_L)
    d.line([(10, 10), (10, 17)], fill=IRON_D)
    # head
    d.ellipse([2, 1, 13, 7], fill=IRON, outline=OUT)
    d.ellipse([4, 2, 11, 5], fill=IRON_L)
    d.line([(5, 3), (7, 3)], fill=(220, 226, 238, 255))
    # rope loop
    d.line([(3, 12), (12, 12)], fill=ROPE)
    d.line([(3, 13), (12, 13)], fill=ROPE_D)
    save(im, "bollard.png")

# ---------------------------------------------------------------- barrel 24x32
def barrel():
    im, d = canvas(24, 32)
    d.ellipse([1, 27, 22, 31], fill=(30, 24, 22, 110))
    body = [(4, 8), (19, 8), (22, 16), (19, 28), (4, 28), (1, 16)]
    d.polygon(body, fill=W2, outline=OUT)
    # staves
    for x in (7, 11, 15):
        d.line([(x, 9), (x - (1 if x < 11 else -1 if x > 11 else 0), 27)], fill=W3)
    d.line([(4, 9), (3, 16)], fill=W1)
    d.line([(5, 9), (4, 16)], fill=W1)
    d.line([(3, 16), (4, 27)], fill=W1)
    d.line([(19, 12), (21, 16)], fill=W3)
    d.line([(21, 17), (19, 27)], fill=W4)
    # iron hoops
    for y in (11, 24):
        d.line([(4 if y == 11 else 3, y), (19 if y == 11 else 20, y)], fill=IRON)
        d.line([(4 if y == 11 else 3, y + 1), (19 if y == 11 else 20, y + 1)], fill=IRON_D)
    d.line([(2, 17), (21, 17)], fill=IRON)
    d.line([(2, 18), (21, 18)], fill=IRON_D)
    # lid
    d.ellipse([3, 3, 20, 12], fill=W1, outline=OUT)
    d.ellipse([5, 4, 18, 10], fill=W2)
    d.line([(7, 6), (11, 5)], fill=(236, 200, 140, 255))
    d.line([(8, 8), (16, 8)], fill=W3)
    save(im, "barrel.png")

# ---------------------------------------------------------------- fish crate 32x32
def fish_crate():
    im, d = canvas(32, 32)
    d.ellipse([2, 27, 30, 31], fill=(30, 24, 22, 110))
    # back wall interior
    d.rectangle([3, 10, 28, 15], fill=W4, outline=OUT)
    # fish heaped in the crate
    fish_shape(d, 5, 7, SILVER, SILVER_L, SILVER_D)
    fish_shape(d, 14, 6, (150, 176, 206, 255), SILVER_L, SILVER_D)
    fish_shape(d, 19, 9, SILVER, SILVER_L, SILVER_D)
    fish_shape(d, 9, 10, (196, 212, 228, 255), SILVER_L, SILVER_D)
    d.point((13, 8), fill=RED)
    # ice speckles
    for p in ((8, 9), (18, 8), (26, 11), (13, 12)):
        d.point(p, fill=(255, 255, 255, 255))
    # front of crate
    box(d, 2, 14, 29, 28, W2, W1, W3)
    planks(d, 2, 14, 29, 28, 5, W3)
    d.rectangle([2, 14, 5, 28], fill=W3, outline=OUT)
    d.rectangle([26, 14, 29, 28], fill=W3, outline=OUT)
    d.line([(3, 15), (3, 27)], fill=W2)
    d.line([(4, 15), (28, 15)], fill=W1)
    d.point((4, 17), fill=W4); d.point((27, 24), fill=W4)
    # handle slot
    d.rectangle([11, 17, 20, 18], fill=W4)
    save(im, "fish_crate.png")

# ---------------------------------------------------------------- net pile 32x24
def net_pile():
    im, d = canvas(32, 24)
    d.ellipse([1, 19, 30, 23], fill=(30, 24, 22, 110))
    NET, NET_L, NET_D = (176, 146, 92, 255), (214, 186, 124, 255), (122, 94, 56, 255)
    d.ellipse([2, 5, 29, 21], fill=NET, outline=OUT)
    d.ellipse([5, 6, 22, 14], fill=NET_L)
    # mesh lines
    for x in range(4, 28, 4):
        d.line([(x, 7), (x + 4, 20)], fill=NET_D)
        d.line([(x + 4, 7), (x, 20)], fill=NET_D)
    for y in (10, 14, 18):
        d.line([(5 if y < 18 else 8, y), (26 if y < 18 else 23, y)], fill=NET_D)
    d.arc([2, 5, 29, 21], 200, 300, fill=NET_L)
    # loose net edge
    d.line([(25, 20), (29, 22)], fill=NET_D)
    # floats
    for (fx, fy, c, cl) in ((5, 4, RED, RED_L), (13, 2, (240, 240, 232, 255), WHITE), (22, 4, RED, RED_L), (27, 12, (240, 240, 232, 255), WHITE)):
        d.ellipse([fx, fy, fx + 4, fy + 4], fill=c, outline=OUT)
        d.point((fx + 1, fy + 1), fill=cl)
    # rope draped
    d.line([(7, 8), (15, 6), (24, 8)], fill=ROPE)
    save(im, "net_pile.png")

# ---------------------------------------------------------------- lighthouse 48x112
def lighthouse():
    im, d = canvas(48, 112)
    d.ellipse([2, 104, 46, 111], fill=(30, 24, 22, 110))
    # rocky base
    d.polygon([(4, 108), (8, 100), (40, 100), (44, 108), (36, 111), (12, 111)], fill=(124, 120, 132, 255), outline=OUT)
    d.polygon([(8, 100), (12, 98), (36, 98), (40, 100)], fill=(156, 152, 164, 255), outline=OUT)
    d.line([(8, 106), (14, 108)], fill=(90, 86, 100, 255))
    d.line([(30, 104), (38, 106)], fill=(90, 86, 100, 255))
    # tower: tapered, stripes. y from 98 up to 36; half-width shrinks 12 -> 8
    cx = 24
    def hw(y):
        return 8 + (y - 36) * 4 // 62
    bands = [(36, 50, RED), (50, 64, WHITE), (64, 78, RED), (78, 98, WHITE)]
    for y0, y1, c in bands:
        for y in range(y0, y1):
            w = hw(y)
            lo = tuple(max(0, v - 36) for v in c[:3]) + (255,)
            hi = tuple(min(255, v + 12) for v in c[:3]) + (255,)
            mid = tuple(max(0, v - 14) for v in c[:3]) + (255,)
            d.line([(cx - w, y), (cx + w, y)], fill=c)
            d.line([(cx - w + 1, y), (cx - w + 2, y)], fill=hi)           # light from the left
            d.line([(cx + w - 4, y), (cx + w - 2, y)], fill=mid)
            d.line([(cx + w - 1, y), (cx + w - 1, y)], fill=lo)
    # outline
    for y in range(36, 98):
        w = hw(y)
        d.point((cx - w - 1, y), fill=OUT)
        d.point((cx + w + 1, y), fill=OUT)
    for y in (50, 64, 78):
        d.line([(cx - hw(y) - 1, y), (cx + hw(y) + 1, y)], fill=OUT)
    # door
    d.rectangle([20, 86, 27, 98], fill=W3, outline=OUT)
    d.rectangle([21, 84, 26, 86], fill=W3, outline=OUT)
    d.line([(22, 88), (22, 97)], fill=W2)
    d.point((26, 92), fill=(240, 210, 90, 255))
    # windows
    for (wy) in (56, 70):
        d.rectangle([22, wy, 26, wy + 5], fill=(40, 52, 84, 255), outline=OUT)
        d.point((23, wy + 1), fill=(150, 190, 230, 255))
    # gallery (balcony)
    d.rectangle([10, 32, 38, 36], fill=IRON, outline=OUT)
    d.line([(11, 33), (37, 33)], fill=IRON_L)
    for x in range(12, 38, 4):
        d.line([(x, 25), (x, 32)], fill=OUT)
    d.line([(10, 25), (38, 25)], fill=OUT)
    d.line([(10, 26), (38, 26)], fill=IRON_L)
    # lantern room (glass, glowing)
    d.rectangle([15, 14, 33, 31], fill=(250, 226, 120, 255), outline=OUT)
    d.rectangle([17, 16, 31, 29], fill=(255, 244, 170, 255))
    d.rectangle([20, 19, 28, 26], fill=(255, 255, 224, 255))
    d.line([(24, 14), (24, 31)], fill=OUT)
    d.line([(19, 14), (19, 31)], fill=IRON_D)
    d.line([(29, 14), (29, 31)], fill=IRON_D)
    d.line([(16, 15), (16, 29)], fill=(255, 252, 214, 255))
    # roof (red cone) and finial
    d.polygon([(11, 14), (37, 14), (30, 5), (18, 5)], fill=RED, outline=OUT)
    d.line([(14, 13), (19, 7)], fill=RED_L)
    d.line([(30, 7), (34, 13)], fill=RED_D)
    d.rectangle([21, 2, 27, 5], fill=IRON, outline=OUT)
    d.line([(24, 0), (24, 2)], fill=OUT)
    save(im, "lighthouse.png")

if __name__ == "__main__":
    contest_board(); smuggle_crate(); moored_boat(); bollard(); barrel(); fish_crate(); net_pile(); lighthouse()
