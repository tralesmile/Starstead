#!/usr/bin/env python3
"""Furniture for player-built rooms and the little signs over their doors (original, CC0). Deterministic.
Furniture is 32x48, standing on the bottom edge of its tile. Light from top-left, 1px dark outlines."""
import os
from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SPR = os.path.join(ROOT, "assets", "sprites")
OUT = (42, 26, 16)
WOOD_DD, WOOD_D, WOOD, WOOD_L, WOOD_LL = (84, 50, 28), (112, 70, 38), (150, 100, 56), (188, 132, 76), (218, 166, 102)
STEEL_D, STEEL, STEEL_L = (88, 96, 108), (140, 150, 162), (206, 214, 222)
RED_D, RED, RED_L = (130, 38, 34), (180, 58, 46), (214, 94, 70)
CREAM_D, CREAM, CREAM_L = (196, 180, 142), (234, 222, 186), (252, 246, 224)


def canvas(w=32, h=48):
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    return im


def shadow(im, box):
    sh = Image.new("RGBA", im.size, (0, 0, 0, 0))
    ImageDraw.Draw(sh).ellipse(box, fill=(30, 20, 12, 80))
    im.alpha_composite(sh)


def block(d, box, base, lit, dark):
    """Outlined slab with a lit top/left edge and a shaded bottom/right edge."""
    x0, y0, x1, y1 = box
    d.rectangle(box, fill=base, outline=OUT)
    d.line([x0 + 1, y0 + 1, x1 - 1, y0 + 1], fill=lit)
    d.line([x0 + 1, y0 + 1, x0 + 1, y1 - 1], fill=lit)
    d.line([x0 + 2, y1 - 1, x1 - 1, y1 - 1], fill=dark)
    d.line([x1 - 1, y0 + 2, x1 - 1, y1 - 1], fill=dark)


def save(im, name):
    im.save(os.path.join(SPR, name + ".png"))
    print("wrote", name)


def bed():
    im = canvas(); shadow(im, [2, 38, 31, 47]); d = ImageDraw.Draw(im)
    block(d, (4, 7, 27, 18), WOOD, WOOD_LL, WOOD_D)              # headboard
    for x in (3, 25):                                            # posts with knobs
        block(d, (x, 5, x + 3, 22), WOOD_L, WOOD_LL, WOOD_D)
        block(d, (x, 3, x + 3, 6), WOOD_LL, (240, 196, 130), WOOD)
    d.line([8, 11, 23, 11], fill=WOOD_D); d.line([8, 12, 23, 12], fill=WOOD_L)
    block(d, (4, 17, 27, 42), CREAM, CREAM_L, CREAM_D)           # sheet
    d.rounded_rectangle([8, 19, 23, 26], radius=2, fill=CREAM_L, outline=OUT)   # pillow
    d.line([10, 25, 21, 25], fill=CREAM_D); d.point([15, 22], fill=CREAM_D)
    block(d, (4, 28, 27, 42), RED, RED_L, RED_D)                 # quilt
    d.rectangle([5, 29, 26, 31], fill=CREAM); d.line([5, 32, 26, 32], fill=RED_D)
    for x in range(8, 26, 6):                                    # patchwork diamonds
        for y, c in ((35, (232, 178, 70)), (39, RED_L)):
            d.polygon([(x, y - 2), (x + 2, y), (x, y + 2), (x - 2, y)], fill=c)
    block(d, (3, 41, 28, 45), WOOD, WOOD_LL, WOOD_D)             # footboard
    for x in (4, 25):
        d.rectangle([x, 45, x + 2, 47], fill=WOOD_DD, outline=OUT)
    save(im, "room_bed")


def counter():
    im = canvas(); shadow(im, [0, 40, 31, 47]); d = ImageDraw.Draw(im)
    block(d, (1, 28, 30, 45), WOOD, WOOD_L, WOOD_D)              # front
    for x in (8, 16, 23):
        d.line([x, 30, x, 43], fill=WOOD_DD); d.line([x + 1, 30, x + 1, 43], fill=WOOD_L)
    for i in range(6):                                           # gingham valance
        c = RED if i % 2 == 0 else CREAM
        d.rectangle([1 + i * 5, 29, min(30, 5 + i * 5), 32], fill=c)
        d.polygon([(1 + i * 5, 33), (min(30, 5 + i * 5), 33), (min(30, 3 + i * 5), 35)], fill=c)
    block(d, (0, 22, 31, 28), WOOD_L, WOOD_LL, WOOD)             # top
    block(d, (3, 14, 13, 23), STEEL, STEEL_L, STEEL_D)           # till
    d.rectangle([5, 10, 11, 14], fill=(52, 66, 58), outline=OUT); d.line([6, 12, 9, 12], fill=(150, 232, 150))
    for y in (17, 20):
        for x in (5, 8, 11):
            d.point([x, y], fill=OUT); d.point([x, y - 1], fill=CREAM_L)
    block(d, (17, 18, 29, 24), WOOD_D, WOOD, WOOD_DD)            # produce basket
    for x, y, c, l in ((20, 17, (214, 70, 50), (248, 140, 100)), (25, 17, (230, 150, 40), (250, 200, 90)), (23, 14, (220, 214, 200), (250, 250, 240))):
        d.ellipse([x - 3, y - 3, x + 2, y + 2], fill=c, outline=OUT); d.point([x - 1, y - 2], fill=l)
    d.line([22, 10, 24, 12], fill=(90, 150, 60)); d.point([21, 11], fill=(120, 180, 70))
    save(im, "room_counter")


def shelf():
    im = canvas(); shadow(im, [1, 41, 30, 47]); d = ImageDraw.Draw(im)
    block(d, (2, 6, 29, 45), WOOD_D, WOOD, WOOD_DD)
    d.rectangle([5, 10, 26, 42], fill=(66, 40, 24))
    for y in (19, 30, 41):
        block(d, (3, y, 28, y + 3), WOOD_L, WOOD_LL, WOOD)
    for x, c, l in ((6, (196, 60, 52), (238, 128, 108)), (13, (222, 160, 48), (250, 208, 110)), (20, (110, 150, 62), (170, 206, 110))):   # jars
        d.rectangle([x, 12, x + 5, 18], fill=c, outline=OUT); d.line([x + 1, 13, x + 1, 17], fill=l)
        d.rectangle([x + 1, 10, x + 4, 12], fill=CREAM, outline=OUT)
    d.rounded_rectangle([6, 22, 15, 29], radius=3, fill=(190, 156, 102), outline=OUT)        # sack
    d.line([8, 24, 8, 27], fill=(222, 192, 138)); d.line([9, 22, 12, 22], fill=OUT)
    for x in (18, 23):                                                                         # cheese and a box
        d.ellipse([x, 24, x + 5, 29], fill=(238, 194, 74), outline=OUT); d.point([x + 2, 26], fill=(170, 124, 40))
    for x in (6, 12, 18):                                                                      # crates of veg
        d.ellipse([x + 1, 32, x + 6, 37], fill=(200, 110, 160) if x == 12 else (226, 126, 44), outline=OUT)
    block(d, (6, 35, 24, 40), WOOD, WOOD_L, WOOD_D)
    block(d, (1, 4, 30, 8), WOOD_L, WOOD_LL, WOOD)
    save(im, "room_shelf")


def workbench():
    im = canvas(); shadow(im, [0, 40, 31, 47]); d = ImageDraw.Draw(im)
    for x in (2, 25):                                            # legs
        block(d, (x, 30, x + 4, 46), WOOD_D, WOOD, WOOD_DD)
    block(d, (5, 37, 26, 40), WOOD_D, WOOD, WOOD_DD)             # stretcher
    d.rectangle([9, 32, 20, 37], fill=(176, 44, 36), outline=OUT)   # red toolbox underneath
    d.line([10, 33, 19, 33], fill=(222, 92, 70)); d.line([13, 35, 16, 35], fill=STEEL_L)
    block(d, (0, 22, 31, 31), WOOD_L, WOOD_LL, WOOD)             # thick top
    d.line([2, 27, 29, 27], fill=WOOD); d.line([2, 28, 29, 28], fill=WOOD_D)
    block(d, (22, 15, 29, 23), (62, 98, 150), (112, 156, 208), (40, 64, 104))   # vice
    d.rectangle([20, 16, 22, 21], fill=STEEL, outline=OUT); d.line([25, 19, 31, 19], fill=STEEL_L)
    d.line([4, 24, 14, 19], fill=OUT, width=4); d.line([4, 24, 14, 19], fill=STEEL_L, width=2)   # spanner
    d.ellipse([12, 15, 18, 21], fill=STEEL, outline=OUT); d.polygon([(15, 15), (18, 15), (18, 17)], fill=(0, 0, 0, 0))
    d.ellipse([2, 22, 6, 26], fill=STEEL, outline=OUT); d.point([4, 24], fill=OUT)
    d.ellipse([6, 12, 13, 19], fill=(60, 62, 70), outline=OUT); d.ellipse([8, 14, 11, 17], fill=STEEL_L, outline=OUT)   # spare part
    save(im, "room_workbench")


def toolrack():
    im = canvas(); shadow(im, [2, 41, 29, 47]); d = ImageDraw.Draw(im)
    for x in (4, 25):
        block(d, (x, 8, x + 3, 46), WOOD_D, WOOD, WOOD_DD)
    block(d, (2, 7, 29, 34), (176, 140, 94), (208, 176, 128), (136, 102, 64))   # pegboard
    for y in range(11, 32, 4):
        for x in range(5, 28, 4):
            d.point([x, y], fill=(112, 82, 52))
    d.rectangle([7, 13, 9, 29], fill=WOOD_L, outline=OUT)                          # hammer
    block(d, (4, 10, 13, 15), STEEL, STEEL_L, STEEL_D)
    d.rectangle([15, 14, 18, 29], fill=STEEL, outline=OUT); d.line([16, 15, 16, 28], fill=STEEL_L)   # spanner
    d.ellipse([13, 9, 20, 16], fill=STEEL, outline=OUT); d.rectangle([16, 9, 17, 12], fill=(176, 140, 94))
    d.polygon([(22, 17), (27, 19), (27, 31), (23, 29)], fill=STEEL_L, outline=OUT)  # saw
    for y in range(20, 31, 3):
        d.point([22, y], fill=OUT)
    d.rounded_rectangle([21, 10, 28, 18], radius=2, fill=RED, outline=OUT); d.rectangle([23, 12, 26, 15], fill=(176, 140, 94), outline=OUT)
    d.ellipse([7, 33, 21, 45], fill=(40, 40, 46), outline=OUT)                      # spare tyre
    d.arc([9, 35, 19, 43], 180, 300, fill=(96, 96, 108)); d.ellipse([11, 36, 17, 42], fill=STEEL, outline=OUT); d.point([13, 38], fill=STEEL_L)
    save(im, "room_toolrack")


def signs():
    """3 hanging door signs, 20x14 each, in data/rooms.json order: shop, garage, bedroom."""
    sheet = canvas(60, 14)
    for i in range(3):
        im = canvas(20, 14); d = ImageDraw.Draw(im)
        d.line([4, 0, 4, 3], fill=OUT); d.line([15, 0, 15, 3], fill=OUT)
        block(d, (0, 2, 19, 13), CREAM, CREAM_L, CREAM_D)
        if i == 0:      # apple
            d.ellipse([6, 5, 12, 11], fill=RED, outline=OUT); d.point([8, 7], fill=(255, 170, 140))
            d.line([9, 3, 9, 5], fill=OUT); d.line([10, 4, 12, 3], fill=(80, 140, 50))
        elif i == 1:    # spanner
            d.line([6, 10, 12, 6], fill=OUT, width=4); d.line([6, 10, 12, 6], fill=STEEL, width=2)
            d.ellipse([10, 3, 16, 9], fill=STEEL, outline=OUT); d.line([14, 3, 14, 5], fill=CREAM, width=2)
        else:           # crescent moon
            d.ellipse([6, 4, 13, 11], fill=(70, 96, 170), outline=OUT); d.ellipse([9, 3, 15, 9], fill=CREAM)
            d.point([14, 10], fill=(70, 96, 170))
        sheet.alpha_composite(im, (i * 20, 0))
    save(sheet, "room_signs")


if __name__ == "__main__":
    bed(); counter(); shelf(); workbench(); toolrack(); signs()
