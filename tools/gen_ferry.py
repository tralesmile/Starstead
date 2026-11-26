#!/usr/bin/env python3
"""Ferry and Isle props (original, CC0): ferry.png 96x80 (bow right) and isle_props.png, 8 frames of 32x32:
shells, sea glass, kelp pile, pearl oyster rock, ferry ticket post, star cairn, upturned rowboat, tide pool.
Dark outline, 3-4 tones, light from top-left. Deterministic."""
import os, math
from PIL import Image, ImageDraw
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SPR = os.path.join(ROOT, "assets", "sprites")
OUT = (42, 26, 16, 255)
# wood tones: light, mid, dark, darkest
W0 = (234, 196, 136, 255)
W1, W2, W3, W4 = (206, 160, 100, 255), (168, 118, 68, 255), (122, 80, 46, 255), (86, 54, 32, 255)
RED, RED_L, RED_D = (200, 56, 52, 255), (236, 104, 88, 255), (140, 34, 40, 255)
WHITE, WHITE_D, WHITE_DD = (244, 244, 236, 255), (210, 214, 214, 255), (160, 172, 184, 255)
TEAL, TEAL_L, TEAL_D, TEAL_DD = (42, 150, 142, 255), (96, 198, 180, 255), (28, 108, 108, 255), (20, 76, 82, 255)
IRON, IRON_L, IRON_D = (92, 96, 108, 255), (140, 146, 160, 255), (58, 60, 72, 255)
ROPE, ROPE_L, ROPE_D = (206, 176, 110, 255), (238, 214, 150, 255), (140, 110, 66, 255)
GLASS, GLASS_L = (118, 180, 212, 255), (220, 244, 255, 255)
GOLD, GOLD_L, GOLD_D = (230, 180, 60, 255), (255, 228, 130, 255), (164, 118, 36, 255)
SAND, SAND_L, SAND_D = (226, 200, 142, 255), (244, 224, 170, 255), (190, 160, 108, 255)
STONE, STONE_L, STONE_D, STONE_DD = (138, 136, 140, 255), (180, 178, 174, 255), (104, 100, 112, 255), (76, 72, 86, 255)
MOSS, MOSS_L = (92, 128, 54, 255), (136, 168, 70, 255)
SHADOW = (30, 24, 22, 90)

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

def shadow(im, bbox, c=SHADOW):
    """Soft ground shadow composited UNDER nothing yet drawn (call first)."""
    ImageDraw.Draw(im).ellipse(bbox, fill=c)

def blob(d, pts, base, outline=OUT):
    d.polygon(pts, fill=base, outline=outline)

def save(im, name):
    im.save(os.path.join(SPR, name))
    print("wrote", name, im.size)

# ---------------------------------------------------------------- ferry 96x80
def ferry():
    im, d = canvas(96, 80)
    d.ellipse([3, 67, 93, 78], fill=(20, 50, 90, 90))                     # water shadow
    # hull: gunwale (deck edge) outline, then the near side dropping to the waterline
    side = [(2, 41), (4, 56), (10, 69), (16, 73), (70, 73), (82, 67), (90, 57), (95, 45), (70, 56), (8, 56)]
    d.polygon(side, fill=W3, outline=OUT)
    deck = [(7, 31), (68, 31), (80, 35), (89, 40), (95, 45), (87, 52), (76, 57), (66, 59), (8, 59), (2, 52), (2, 38)]
    d.polygon(deck, fill=W1, outline=OUT)
    # side planking below the near gunwale
    d.polygon([(3, 53), (8, 60), (66, 60), (76, 58), (87, 53), (94, 46), (90, 57), (82, 67), (70, 73), (16, 73), (10, 69), (4, 58)],
              fill=W2, outline=OUT)
    d.line([(9, 61), (66, 61), (76, 59), (87, 54), (92, 49)], fill=WHITE)  # painted strake
    d.line([(9, 62), (66, 62), (76, 60), (87, 55), (91, 51)], fill=WHITE)
    d.line([(9, 63), (66, 63), (76, 61), (86, 57), (90, 53)], fill=TEAL)
    d.line([(9, 64), (66, 64), (76, 62), (85, 58), (89, 55)], fill=TEAL_D)
    d.line([(10, 67), (70, 67), (80, 63), (86, 59)], fill=W4)
    d.line([(10, 66), (69, 66), (79, 62)], fill=W1)
    d.polygon([(10, 69), (70, 69), (82, 64), (82, 67), (70, 73), (16, 73)], fill=TEAL_DD, outline=OUT)
    d.line([(14, 70), (70, 70)], fill=TEAL_D)
    for x, y in ((24, 65), (47, 68), (63, 65)):                            # plank butt joints
        d.line([(x, y), (x, y + 1)], fill=W4)
    # deck planks (inside the rim)
    inner = [(8, 34), (68, 34), (79, 38), (90, 45), (85, 50), (75, 54), (66, 56), (9, 56), (5, 51), (5, 39)]
    mask = Image.new("1", im.size, 0)
    ImageDraw.Draw(mask).polygon(inner, fill=1)
    d.polygon(inner, fill=W1)
    for y in range(34, 57):
        for x in range(4, 92):
            if not mask.getpixel((x, y)):
                continue
            row = (y - 34) // 4
            c = W1
            if (y - 34) % 4 == 3:
                c = W3
            elif (y - 34) % 4 == 0:
                c = W0
            elif (x + row * 13) % 23 == 0:
                c = W3
            elif (x + row * 13) % 23 == 1:
                c = W0
            if y < 36:
                c = W3                                                     # shade under far rim
            im.putpixel((x, y), c)
    d.line(inner + [inner[0]], fill=W4)
    d.line([(3, 38), (8, 32), (68, 32), (79, 36), (93, 44)], fill=W0)       # lit far rim
    d.line([(3, 52), (8, 57), (66, 57), (76, 55), (86, 51), (93, 45)], fill=W0)  # near rim cap
    d.line([(3, 53), (8, 58), (66, 58), (76, 56), (86, 52), (93, 46)], fill=W2)
    # far railing (behind the cabin)
    for x in (46, 56, 66):
        d.line([(x, 25), (x, 33)], fill=OUT)
        d.point((x, 24), fill=GOLD_L)
    d.line([(46, 26), (66, 26), (78, 30)], fill=OUT)
    d.line([(46, 27), (66, 27), (78, 31)], fill=WHITE_D)
    d.line([(78, 30), (78, 35)], fill=OUT)
    # cabin shadow on the deck (cast to the lower right)
    d.polygon([(46, 38), (52, 41), (52, 53), (46, 53)], fill=W3)
    # funnel stands on the roof: drawn after the roof. cabin front wall
    box(d, 12, 28, 46, 52, WHITE, (255, 255, 250, 255), WHITE_D)
    d.rectangle([42, 30, 45, 50], fill=WHITE_D)                            # shaded right end
    d.rectangle([13, 46, 45, 50], fill=TEAL)                               # teal skirt
    d.line([(13, 46), (45, 46)], fill=TEAL_L)
    d.line([(13, 51), (45, 51)], fill=TEAL_DD)
    d.rectangle([42, 47, 45, 50], fill=TEAL_D)
    # door
    d.rectangle([15, 34, 22, 51], fill=W2, outline=OUT)
    d.line([(16, 35), (16, 50)], fill=W1)
    d.line([(19, 42), (19, 50)], fill=W3)
    d.rectangle([17, 36, 20, 40], fill=GLASS, outline=OUT)
    d.point((20, 44), fill=GOLD_L)
    # windows
    for wx in (25, 35):
        d.rectangle([wx, 34, wx + 7, 42], fill=GLASS, outline=OUT)
        d.line([(wx + 1, 35), (wx + 4, 35)], fill=GLASS_L)
        d.line([(wx + 1, 36), (wx + 1, 38)], fill=GLASS_L)
        d.line([(wx + 4, 35), (wx + 4, 41)], fill=WHITE)
        d.line([(wx, 43), (wx + 7, 43)], fill=TEAL_D)
    # roof seen from above (teal), overhanging
    d.polygon([(11, 17), (45, 17), (49, 28), (49, 31), (9, 31), (9, 28)], fill=TEAL, outline=OUT)
    d.line([(12, 18), (44, 18)], fill=TEAL_L)
    d.line([(12, 19), (10, 27)], fill=TEAL_L)
    for y in (22, 25):
        d.line([(12, y), (45, y)], fill=TEAL_D)
    d.line([(10, 28), (48, 28)], fill=TEAL_L)
    d.line([(10, 29), (48, 29)], fill=WHITE)
    d.line([(10, 30), (48, 30)], fill=WHITE_DD)
    d.line([(12, 32), (45, 32)], fill=WHITE_DD)                            # eave shadow
    # funnel
    d.ellipse([18, 21, 32, 26], fill=TEAL_DD)                              # shadow on roof
    d.rectangle([19, 6, 29, 22], fill=WHITE, outline=OUT)
    d.ellipse([19, 19, 29, 24], fill=WHITE, outline=OUT)
    d.rectangle([20, 18, 28, 21], fill=WHITE)
    d.line([(21, 8), (21, 22)], fill=(255, 255, 255, 255))
    d.rectangle([26, 8, 28, 22], fill=WHITE_D)
    d.rectangle([20, 11, 28, 15], fill=TEAL)
    d.line([(21, 11), (21, 15)], fill=TEAL_L)
    d.rectangle([26, 11, 28, 15], fill=TEAL_D)
    d.rectangle([18, 4, 30, 8], fill=IRON_D, outline=OUT)
    d.line([(19, 5), (24, 5)], fill=IRON_L)
    d.ellipse([20, 2, 28, 5], fill=(34, 28, 30, 255), outline=OUT)
    # life ring hung on the bow side of the cabin wall / deck rail
    def ring(cx, cy):
        d.ellipse([cx - 6, cy - 6, cx + 6, cy + 6], fill=WHITE, outline=OUT)
        for a0 in (20, 110, 200, 290):
            d.pieslice([cx - 5, cy - 5, cx + 5, cy + 5], a0, a0 + 44, fill=RED)
        d.ellipse([cx - 2, cy - 2, cx + 2, cy + 2], fill=W3, outline=OUT)
        d.point((cx - 3, cy - 4), fill=(255, 255, 255, 255))
    ring(55, 45)
    # post the ring hangs on is hidden behind it; bow mast with pennant
    d.line([(74, 14), (74, 46)], fill=OUT)
    d.line([(73, 15), (73, 45)], fill=W1)
    d.line([(72, 15), (72, 45)], fill=OUT)
    d.polygon([(75, 15), (87, 19), (75, 23)], fill=TEAL, outline=OUT)
    d.line([(76, 17), (80, 18)], fill=TEAL_L)
    d.rectangle([72, 12, 74, 14], fill=GOLD, outline=OUT)
    d.ellipse([69, 44, 77, 48], outline=W4)
    # luggage crate + coiled rope on deck
    box(d, 62, 38, 69, 47, W2, W1, W4)
    d.line([(63, 42), (68, 42)], fill=W4)
    d.ellipse([78, 43, 86, 49], fill=ROPE, outline=OUT)
    d.ellipse([80, 44, 84, 47], fill=ROPE_D)
    d.point((82, 45), fill=ROPE_L)
    # near posts at stern and bow with a sagging rope rail
    posts = ((49, 51), (63, 51), (76, 49), (87, 44))
    for (ax, ay), (bx, by) in zip(posts, posts[1:]):
        mx, my = (ax + bx) // 2, (ay + by) // 2 + 3
        d.line([(ax, ay), (mx, my), (bx, by)], fill=ROPE_D)
        d.line([(ax, ay - 1), (mx, my - 1), (bx, by - 1)], fill=ROPE_L)
    for x, y in posts:
        d.rectangle([x - 1, y - 3, x + 1, y + 5], fill=W3, outline=OUT)
        d.point((x, y - 2), fill=W0)
    # rope fenders hanging over the near side
    for fx, fy in ((17, 60), (36, 60), (56, 60)):
        d.line([(fx + 3, fy - 4), (fx + 3, fy)], fill=ROPE_D)
        d.ellipse([fx, fy, fx + 6, fy + 10], fill=ROPE, outline=OUT)
        for yy in (fy + 3, fy + 6, fy + 8):
            d.line([(fx + 1, yy), (fx + 5, yy - 1)], fill=ROPE_D)
        d.line([(fx + 2, fy + 2), (fx + 2, fy + 4)], fill=ROPE_L)
    # waterline foam
    for x0, x1, y in ((9, 18, 74), (24, 37, 75), (45, 52, 74), (60, 71, 75), (79, 85, 70), (88, 93, 61)):
        d.line([(x0, y), (x1, y)], fill=(214, 244, 244, 220))
    save(im, "ferry.png")

# ---------------------------------------------------------------- isle props, 32x32 each
def sand_patch(d, y0=17, y1=29):
    d.ellipse([2, y0, 29, y1], fill=SAND)
    d.ellipse([5, y0 + 1, 22, y1 - 4], fill=SAND_L)
    for x, y in ((6, y1 - 3), (12, y1 - 1), (21, y1 - 2), (26, y0 + 5), (9, y0 + 3)):
        d.point((x, y), fill=SAND_D)

def scallop(d, cx, cy, r, base, hi, lo):
    d.pieslice([cx - r, cy - r, cx + r, cy + r], 170, 370, fill=base, outline=OUT)
    for a in (205, 238, 270, 302, 335):
        d.line([(cx, cy), (cx + round((r - 1) * math.cos(math.radians(a))), cy + round((r - 1) * math.sin(math.radians(a))))], fill=lo)
    d.line([(cx - r + 2, cy - 2), (cx - 2, cy - r + 2)], fill=hi)
    d.rectangle([cx - 2, cy, cx + 2, cy + 2], fill=lo, outline=OUT)

def p_shells():
    im, d = canvas(32, 32)
    sand_patch(d, 14, 30)
    scallop(d, 12, 21, 8, (238, 170, 146, 255), (255, 226, 204, 255), (196, 112, 100, 255))
    scallop(d, 23, 18, 5, (240, 224, 196, 255), (255, 250, 232, 255), (190, 160, 130, 255))
    # spiral snail shell
    d.polygon([(18, 27), (20, 22), (24, 21), (27, 24), (29, 28), (22, 28)], fill=(214, 150, 84, 255), outline=OUT)
    d.arc([20, 22, 26, 28], 160, 380, fill=(140, 90, 50, 255))
    d.point((23, 25), fill=(140, 90, 50, 255)); d.line([(21, 23), (23, 22)], fill=(248, 206, 140, 255))
    # tiny cowrie
    d.ellipse([4, 25, 10, 29], fill=(226, 208, 224, 255), outline=OUT)
    d.line([(6, 27), (8, 27)], fill=(146, 112, 140, 255))
    return im

def p_sea_glass():
    im, d = canvas(32, 32)
    sand_patch(d, 14, 30)
    pieces = [
        ([(6, 20), (10, 16), (14, 19), (12, 24), (7, 24)], (76, 196, 164, 255), (190, 246, 222, 255)),
        ([(16, 23), (21, 21), (26, 24), (22, 28), (17, 27)], (90, 158, 224, 255), (196, 228, 255, 255)),
        ([(19, 16), (23, 14), (25, 18), (21, 19)], (150, 204, 90, 255), (224, 248, 170, 255)),
        ([(9, 27), (12, 25), (15, 28), (11, 29)], (206, 232, 232, 255), (255, 255, 255, 255)),
    ]
    for pts, c, h in pieces:
        d.polygon(pts, fill=c, outline=OUT)
        d.line([(pts[0][0] + 1, pts[0][1]), (pts[1][0], pts[1][1] + 1)], fill=h)
    for x, y, r in ((12, 12, 3), (27, 19, 2), (17, 19, 1)):                 # glints
        d.line([(x - r, y), (x + r, y)], fill=(255, 255, 255, 255))
        d.line([(x, y - r), (x, y + r)], fill=(255, 255, 255, 255))
    return im

def p_kelp():
    im, d = canvas(32, 32)
    shadow(im, [1, 22, 31, 31])
    K, KL, KD, KDD = (86, 120, 42, 255), (146, 170, 62, 255), (58, 88, 38, 255), (38, 62, 32, 255)
    mound = [(3, 25), (5, 19), (10, 17), (14, 12), (20, 13), (23, 18), (28, 20), (29, 26), (22, 29), (9, 29)]
    d.polygon(mound, fill=KD, outline=OUT)
    def strap(pts, c, h):
        d.line(pts, fill=OUT, width=5, joint="curve")
        d.line(pts, fill=c, width=3, joint="curve")
        d.line([(x, y - 1) for x, y in pts], fill=h)
    strap([(15, 15), (9, 20), (11, 24), (3, 27)], K, KL)
    strap([(17, 15), (23, 21), (20, 25), (28, 27)], K, KL)
    strap([(16, 17), (13, 22), (17, 25), (13, 28)], (108, 132, 44, 255), (176, 190, 76, 255))
    strap([(18, 14), (14, 10), (8, 12)], K, KL)
    strap([(19, 17), (26, 16), (29, 20)], (108, 132, 44, 255), (176, 190, 76, 255))
    for x, y in ((10, 17), (21, 17), (19, 26)):                             # air bladders
        d.ellipse([x, y, x + 3, y + 3], fill=(188, 156, 60, 255), outline=OUT)
        d.point((x + 1, y + 1), fill=(244, 220, 120, 255))
    d.line([(6, 28), (24, 29)], fill=KDD)
    return im

def p_oyster_rock():
    im, d = canvas(32, 32)
    shadow(im, [1, 23, 31, 31])
    rock = [(2, 25), (4, 17), (9, 12), (17, 10), (25, 14), (29, 21), (29, 27), (21, 29), (7, 29)]
    d.polygon(rock, fill=STONE, outline=OUT)
    d.polygon([(5, 18), (10, 13), (17, 11), (22, 14), (14, 16), (8, 20)], fill=STONE_L)
    d.polygon([(24, 17), (28, 22), (28, 26), (21, 28), (23, 22)], fill=STONE_D)
    d.line([(5, 26), (10, 28)], fill=STONE_DD); d.line([(17, 11), (20, 15)], fill=STONE_D)
    for x, y in ((7, 22), (25, 24), (15, 13)):                              # barnacles
        d.ellipse([x, y, x + 2, y + 2], fill=(214, 208, 190, 255), outline=STONE_DD)
    # open pearl oyster on the front: raised upper shell, lower shell, pearl
    SH, SHL, SHD = (112, 104, 124, 255), (168, 158, 176, 255), (74, 66, 90, 255)
    d.pieslice([8, 13, 24, 29], 180, 360, fill=SH, outline=OUT)
    d.pieslice([10, 15, 22, 27], 180, 360, fill=(226, 210, 232, 255))
    for x in (11, 14, 18, 21):
        d.line([(16, 21), (x, 15 if x in (14, 18) else 17)], fill=(190, 170, 208, 255))
    d.arc([9, 14, 23, 28], 190, 270, fill=SHL)
    d.polygon([(8, 22), (24, 22), (21, 27), (11, 27)], fill=SH, outline=OUT)
    d.line([(10, 23), (22, 23)], fill=(240, 226, 240, 255))
    d.line([(12, 26), (20, 26)], fill=SHD)
    d.ellipse([13, 18, 19, 24], fill=(246, 240, 244, 255), outline=(110, 94, 130, 255))
    d.rectangle([14, 19, 15, 20], fill=(255, 255, 255, 255))
    d.point((17, 22), fill=(236, 190, 210, 255)); d.point((18, 21), fill=(196, 220, 236, 255))
    d.line([(23, 10), (23, 14)], fill=(255, 255, 255, 255)); d.line([(21, 12), (25, 12)], fill=(255, 255, 255, 255))
    d.line([(3, 25), (6, 21)], fill=MOSS); d.line([(4, 26), (7, 25)], fill=MOSS_L)
    return im

def p_ticket_post():
    im, d = canvas(32, 32)
    shadow(im, [3, 26, 29, 31])
    box(d, 7, 3, 10, 29, W2, W1, W3)                                        # post
    d.rectangle([6, 1, 11, 3], fill=TEAL, outline=OUT)
    # bell on a bracket to the right
    d.rectangle([10, 5, 25, 6], fill=W3, outline=OUT)
    d.line([(23, 7), (23, 8)], fill=OUT)
    d.polygon([(21, 9), (25, 9), (26, 13), (28, 15), (18, 15), (20, 13)], fill=GOLD, outline=OUT)
    d.line([(21, 10), (21, 13)], fill=GOLD_L); d.line([(25, 12), (26, 14)], fill=GOLD_D)
    d.rectangle([22, 16, 24, 17], fill=GOLD_D, outline=OUT)
    # timetable board
    box(d, 2, 17, 21, 27, TEAL, TEAL_L, TEAL_D)
    d.rectangle([4, 19, 19, 25], fill=(244, 232, 200, 255))
    d.line([(5, 19), (18, 19)], fill=RED)
    for y in (21, 23, 25):
        d.line([(5, y), (7, y)], fill=OUT)
        d.line([(10, y), (17 if y != 23 else 15, y)], fill=(130, 104, 80, 255))
    d.line([(4, 30), (13, 30)], fill=STONE_D)
    for x in (3, 11):
        d.ellipse([x, 27, x + 4, 30], fill=STONE, outline=OUT)
        d.point((x + 1, 28), fill=STONE_L)
    return im

def p_star_cairn():
    im, d = canvas(32, 32)
    shadow(im, [2, 24, 30, 31])
    def stone(x0, y0, x1, y1):
        d.rounded_rectangle([x0, y0, x1, y1], radius=3, fill=STONE, outline=OUT)
        d.line([(x0 + 2, y0 + 1), (x1 - 3, y0 + 1)], fill=STONE_L)
        d.line([(x0 + 1, y0 + 2), (x0 + 1, y1 - 3)], fill=STONE_L)
        d.line([(x0 + 3, y1 - 1), (x1 - 2, y1 - 1)], fill=STONE_D)
        d.line([(x1 - 1, y0 + 3), (x1 - 1, y1 - 2)], fill=STONE_D)
    stone(2, 23, 14, 29); stone(15, 22, 29, 29)
    stone(5, 18, 26, 24)
    stone(9, 3, 23, 19)                                                     # standing top stone with the star
    stone(12, 1, 20, 4)
    # faded carved star: dim groove, pale lower lip
    pts = []
    for k in range(10):
        a = -math.pi / 2 + k * math.pi / 5
        r = 6 if k % 2 == 0 else 2.6
        pts.append((round(16 + r * math.cos(a)), round(11 + r * math.sin(a))))
    d.polygon(pts, fill=(160, 154, 134, 255), outline=STONE_DD)
    d.point((16, 10), fill=(206, 194, 148, 255)); d.point((15, 11), fill=(206, 194, 148, 255))
    for x, y in ((19, 9), (13, 14)):                                        # weathered gaps
        d.point((x, y), fill=STONE)
    d.line([(5, 18), (10, 18)], fill=MOSS_L); d.line([(5, 19), (7, 19)], fill=MOSS)
    d.line([(22, 22), (27, 22)], fill=MOSS); d.point((24, 23), fill=MOSS)
    for x in (2, 29):
        d.line([(x, 29), (x - 1, 26)], fill=MOSS_L); d.line([(x, 29), (x + 1, 27)], fill=MOSS)
    return im

def p_rowboat():
    im, d = canvas(32, 32)
    sand_patch(d, 20, 31)
    d.polygon([(2, 24), (12, 27), (30, 26), (31, 23), (20, 22)], fill=(120, 92, 60, 130))
    # keel-up hull: pointed bow on the left, flat transom on the right
    hull = [(0, 23), (4, 18), (10, 14), (18, 12), (27, 13), (29, 15), (31, 24), (24, 26), (10, 26), (4, 25)]
    d.polygon(hull, fill=W2, outline=OUT)
    d.polygon([(4, 19), (10, 15), (18, 13), (26, 14), (26, 16), (12, 17)], fill=W1)
    for pts in ([(3, 21), (11, 19), (28, 18)], [(3, 23), (11, 22), (29, 21)]):   # strakes
        d.line(pts, fill=W4)
        d.line([(x, y + 1) for x, y in pts], fill=W1)
    d.polygon([(2, 23), (10, 24), (30, 23), (30, 24), (24, 25), (10, 25), (4, 24)], fill=TEAL)
    d.line([(3, 23), (10, 24), (29, 23)], fill=TEAL_L)
    d.polygon([(27, 13), (29, 15), (31, 24), (28, 25), (26, 16)], fill=W3, outline=OUT)  # transom
    d.line([(28, 17), (29, 22)], fill=W2)
    # raised keel beam along the top, with the curved stem at the bow
    d.line([(2, 21), (5, 16), (11, 12), (18, 10), (27, 11)], fill=OUT, width=1)
    d.line([(3, 21), (6, 17), (11, 13), (18, 11), (27, 12)], fill=W0)
    d.line([(4, 21), (7, 18), (12, 14), (18, 12), (27, 13)], fill=W4)
    d.polygon([(19, 18), (22, 17), (23, 20), (20, 21)], fill=(52, 32, 22, 255), outline=OUT)  # stove-in plank
    for x in (8, 14, 25):
        d.point((x, 17), fill=OUT)
    # oar lying in the sand in front
    d.line([(4, 29), (21, 29)], fill=OUT, width=3)
    d.line([(4, 29), (21, 29)], fill=W0)
    d.ellipse([20, 27, 28, 31], fill=W1, outline=OUT)
    d.line([(22, 29), (26, 29)], fill=W3)
    return im

def p_tide_pool():
    im, d = canvas(32, 32)
    d.ellipse([1, 9, 30, 30], fill=SAND_D)
    d.ellipse([4, 11, 27, 27], fill=(64, 158, 168, 255), outline=OUT)
    d.ellipse([7, 14, 25, 26], fill=(46, 126, 150, 255))
    d.line([(8, 14), (15, 13)], fill=(170, 232, 226, 255)); d.line([(20, 24), (23, 23)], fill=(170, 232, 226, 255))
    # rim stones
    for x, y, w, h in ((1, 12, 7, 6), (5, 8, 8, 6), (13, 7, 7, 5), (20, 9, 7, 6), (25, 14, 6, 7), (24, 22, 7, 6),
                       (16, 25, 8, 5), (7, 24, 8, 6), (1, 19, 6, 7)):
        d.ellipse([x, y, x + w, y + h], fill=STONE, outline=OUT)
        d.line([(x + 2, y + 1), (x + w - 3, y + 1)], fill=STONE_L)
        d.line([(x + 2, y + h - 1), (x + w - 2, y + h - 1)], fill=STONE_D)
    # starfish
    pts = []
    for k in range(10):
        a = -math.pi / 2 + 0.25 + k * math.pi / 5
        r = 6.5 if k % 2 == 0 else 2.6
        pts.append((round(15 + r * math.cos(a)), round(19 + r * math.sin(a))))
    d.polygon(pts, fill=(238, 124, 58, 255), outline=OUT)
    for k in (0, 2, 4, 6, 8):
        d.point(((pts[k][0] + 15 * 2) // 3, (pts[k][1] + 19 * 2) // 3), fill=(255, 204, 120, 255))
    d.point((15, 19), fill=(255, 204, 120, 255))
    # weed and tiny anemone
    d.line([(23, 21), (21, 18), (22, 16)], fill=MOSS_L); d.line([(24, 21), (24, 17)], fill=MOSS)
    d.ellipse([9, 16, 11, 18], fill=(216, 90, 150, 255)); d.point((10, 15), fill=(246, 150, 196, 255))
    return im

def isle_props():
    frames = [p_shells, p_sea_glass, p_kelp, p_oyster_rock, p_ticket_post, p_star_cairn, p_rowboat, p_tide_pool]
    strip, _ = canvas(32 * len(frames), 32)
    for n, f in enumerate(frames):
        strip.paste(f(), (n * 32, 0))
    save(strip, "isle_props.png")

if __name__ == "__main__":
    ferry(); isle_props()
