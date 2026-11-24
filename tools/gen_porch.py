#!/usr/bin/env python3
"""Porch overlay (96x26), carpenter workbench (48x40), goal arrow (16x16). Original, CC0."""
import os
from PIL import Image, ImageDraw
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SP = os.path.join(ROOT, "assets", "sprites")
OUT = (42, 26, 16)
WOOD = [(110, 70, 38), (138, 90, 52), (166, 112, 63), (190, 132, 76)]
STONE = [(96, 96, 104), (140, 140, 148), (178, 178, 184)]

def new(w, h):
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0)); return im, ImageDraw.Draw(im)

def porch():
    im, d = new(96, 26)
    # steps (lower wide, upper narrow)
    d.rectangle([34, 22, 62, 25], fill=STONE[0], outline=OUT)
    d.rectangle([35, 22, 61, 23], fill=STONE[2]); d.line([35, 24, 61, 24], fill=STONE[0])
    d.line([48, 24, 48, 24], fill=OUT)
    d.rectangle([38, 17, 58, 21], fill=STONE[0], outline=OUT)
    d.rectangle([39, 17, 57, 19], fill=STONE[2]); d.line([39, 20, 57, 20], fill=STONE[0])
    d.line([39, 17, 57, 17], fill=(206, 206, 210))
    d.line([36, 23, 36, 23], fill=(206, 206, 210))
    # doormat
    d.rectangle([40, 13, 56, 16], fill=(120, 58, 44), outline=OUT)
    d.rectangle([41, 14, 55, 15], fill=(160, 84, 56))
    for x in range(42, 55, 3): d.point((x, 14), fill=(196, 130, 80))
    # railings
    for x0, x1 in ((20, 33), (63, 76)):
        d.rectangle([x0, 11, x1, 13], fill=WOOD[2], outline=OUT); d.line([x0 + 1, 12, x1 - 1, 12], fill=WOOD[3])
        d.rectangle([x0, 18, x1, 19], fill=WOOD[1], outline=OUT)
        for x in range(x0 + 4, x1 - 2, 4):
            d.rectangle([x, 14, x + 1, 17], fill=WOOD[2]); d.point((x, 15), fill=WOOD[3])
        for x in (x0, x1 - 2):
            d.rectangle([x, 7, x + 2, 21], fill=WOOD[2], outline=OUT); d.line([x + 1, 8, x + 1, 20], fill=WOOD[3])
            d.rectangle([x - 1, 6, x + 3, 7], fill=WOOD[3], outline=OUT)
    # flower pots
    for cx in (14, 80):
        d.polygon([(cx - 4, 18), (cx + 4, 18), (cx + 3, 24), (cx - 3, 24)], fill=(184, 92, 56), outline=OUT)
        d.line([cx - 3, 19, cx - 3, 22], fill=(220, 130, 84)); d.line([cx + 2, 20, cx + 2, 23], fill=(140, 64, 40))
        d.rectangle([cx - 4, 17, cx + 4, 18], fill=(210, 112, 70), outline=OUT)
        d.ellipse([cx - 5, 10, cx + 5, 17], fill=(60, 130, 56), outline=OUT)
        d.line([cx - 3, 12, cx - 1, 11], fill=(100, 170, 70))
        for fx, fy, c in ((-3, 12, (214, 48, 44)), (1, 11, (244, 204, 60)), (3, 14, (214, 48, 44)), (-1, 14, (244, 204, 60)), (0, 12, (250, 236, 150))):
            d.point((cx + fx, fy), fill=c); d.point((cx + fx + 1, fy), fill=c)
    # wall lantern at x62
    d.line([62, 0, 62, 1], fill=OUT); d.rectangle([60, 2, 64, 3], fill=(60, 50, 44), outline=OUT)
    d.rectangle([60, 4, 64, 9], fill=(244, 200, 80), outline=OUT)
    d.rectangle([61, 5, 62, 7], fill=(255, 238, 150)); d.point((63, 8), fill=(214, 150, 44))
    d.line([62, 4, 62, 9], fill=(150, 110, 40))
    d.rectangle([60, 10, 64, 10], fill=(60, 50, 44), outline=OUT)
    im.save(os.path.join(SP, "porch_house.png"))

def bench():
    im, d = new(48, 40)
    # trestle legs (A-frames)
    for x in (5, 36):
        d.polygon([(x, 18), (x + 5, 18), (x + 7, 38), (x + 4, 38), (x + 2, 26), (x - 1, 38), (x - 3, 38)], fill=WOOD[1], outline=OUT)
        d.line([x + 1, 20, x + 1, 24], fill=WOOD[3])
    d.rectangle([5, 28, 42, 30], fill=WOOD[0], outline=OUT)  # stretcher
    d.line([6, 29, 41, 29], fill=WOOD[1])
    # thick top
    d.rectangle([2, 12, 45, 19], fill=WOOD[2], outline=OUT)
    d.line([3, 13, 44, 13], fill=WOOD[3]); d.line([3, 18, 44, 18], fill=WOOD[1])
    for x in (12, 27, 38): d.line([x, 15, x + 3, 15], fill=WOOD[1])
    # vise on left corner
    d.rectangle([0, 14, 4, 22], fill=(110, 112, 120), outline=OUT); d.line([1, 15, 1, 21], fill=(170, 172, 180))
    d.rectangle([0, 10, 4, 13], fill=(140, 142, 150), outline=OUT)
    d.line([0, 24, 4, 24], fill=OUT); d.rectangle([-1, 23, 0, 25], fill=WOOD[0], outline=OUT) if False else None
    # planks stacked beside (right, on the ground)
    for i, y in enumerate((36, 33, 30)):
        c = (WOOD[2], WOOD[3], WOOD[2])[i]
        d.rectangle([40 - i, y, 47, y + 2], fill=c, outline=OUT); d.line([41 - i, y + 1, 46, y + 1], fill=WOOD[1])
    # saw leaning on bench
    d.polygon([(14, 38), (16, 38), (24, 13), (21, 13)], fill=(176, 180, 190), outline=OUT)
    d.line([15, 36, 22, 15], fill=(220, 224, 230))
    d.rectangle([20, 8, 25, 13], fill=WOOD[0], outline=OUT); d.point((22, 10), fill=WOOD[1])
    # hammer on top
    d.rectangle([28, 9, 35, 11], fill=WOOD[3], outline=OUT)
    d.rectangle([34, 6, 38, 11], fill=(120, 124, 134), outline=OUT); d.line([35, 7, 35, 10], fill=(190, 194, 204))
    # jar of nails
    d.rectangle([7, 6, 12, 11], fill=(150, 200, 210), outline=OUT); d.rectangle([7, 4, 12, 5], fill=(150, 150, 156), outline=OUT)
    d.line([8, 7, 8, 10], fill=(220, 244, 248))
    for p in ((9, 9), (10, 10), (11, 9), (9, 11)): d.point(p, fill=(90, 86, 84))
    im.save(os.path.join(SP, "workbench.png"))

def arrow():
    im, d = new(16, 16)
    pts = [(1, 5), (8, 5), (8, 1), (15, 8), (8, 14), (8, 10), (1, 10)]
    d.polygon(pts, fill=(226, 160, 36), outline=OUT)
    d.polygon([(2, 6), (9, 6), (9, 4), (12, 7), (9, 7), (2, 7)], fill=(255, 220, 100))
    d.line([2, 6, 8, 6], fill=(255, 236, 150))
    d.line([2, 9, 8, 9], fill=(176, 108, 24)); d.line([9, 11, 9, 12], fill=(176, 108, 24))
    d.line([10, 10, 12, 8], fill=(176, 108, 24))
    im.save(os.path.join(SP, "goal_arrow.png"))

porch(); bench(); arrow()
print("wrote porch_house.png workbench.png goal_arrow.png")
