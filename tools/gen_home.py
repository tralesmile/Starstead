#!/usr/bin/env python3
"""Home furniture sprites (original, CC0). Deterministic (fixed seeds).
Reuses helpers/palettes from gen_interior.py. 3/4 top-down, light top-left,
1px dark outline, objects sit at the BOTTOM of their box."""
import os
import random
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gen_interior import (new, shade, box, shadow, save, OUT, WOOD, RED, BLUE,  # noqa: E402
                          GREEN, IRON, SKY, SPR)

GOLD = (222, 190, 90)


def sofa():
    im, d = new(64, 40)
    shadow(d, 3, 39, 60)
    c = RED
    box(d, 2, 5, 61, 20, c[1])                               # backrest
    d.line([4, 7, 59, 7], fill=c[2])
    for x in (21, 41):                                       # back cushion seams
        d.line([x, 9, x, 19], fill=c[0])
    box(d, 2, 18, 61, 33, c[1])                              # seat body
    for x0, x1 in ((10, 30), (33, 53)):                      # seat cushions
        d.rectangle([x0, 20, x1, 31], fill=c[2], outline=OUT)
        d.line([x0 + 1, 21, x1 - 1, 21], fill=shade(c[2], 1.2))
        d.line([x0 + 1, 30, x1 - 1, 30], fill=c[0])
    box(d, 1, 12, 9, 35, c[0], hi=c[1], lo=shade(c[0], 0.7))  # arms
    box(d, 54, 12, 62, 35, c[0], hi=c[1], lo=shade(c[0], 0.7))
    d.line([3, 14, 7, 14], fill=c[2])
    d.line([56, 14, 60, 14], fill=c[2])
    for x in (4, 54):                                        # feet
        box(d, x, 36, x + 5, 38, WOOD[0])
    save(im, "int_sofa.png")


def armchair():
    im, d = new(32, 40)
    shadow(d, 3, 39, 28)
    c = BLUE
    box(d, 5, 4, 26, 22, c[1])                               # back
    d.line([7, 6, 24, 6], fill=c[2])
    d.line([16, 9, 16, 21], fill=c[0])
    box(d, 5, 20, 26, 34, c[1])                              # seat
    d.rectangle([9, 22, 22, 32], fill=c[2], outline=OUT)
    d.line([10, 23, 21, 23], fill=shade(c[2], 1.2))
    d.line([10, 31, 21, 31], fill=c[0])
    box(d, 1, 13, 8, 35, c[0], hi=c[1], lo=shade(c[0], 0.7))
    box(d, 23, 13, 30, 35, c[0], hi=c[1], lo=shade(c[0], 0.7))
    for x in (3, 25):
        box(d, x, 36, x + 3, 38, WOOD[0])
    save(im, "int_armchair.png")


def plant():
    im, d = new(32, 40)
    rng = random.Random(21)
    shadow(d, 7, 39, 24)
    # leaves: back to front, dark to light
    leaves = [(16, 20, -9, -10), (16, 20, 9, -10), (16, 20, -12, -2), (16, 20, 12, -2),
              (16, 18, -4, -13), (16, 18, 5, -12), (16, 20, 0, -15), (16, 20, -7, -6), (16, 20, 7, -6)]
    for i, (x, y, dx, dy) in enumerate(leaves):
        cx, cy = x + dx, y + dy
        col = GREEN[i % 3]
        d.ellipse([cx - 4, cy - 3, cx + 4, cy + 3], fill=col, outline=OUT)
        d.line([cx - 2, cy - 1, cx + 1, cy - 2], fill=shade(col, 1.3))
        d.line([x, y, cx, cy + 2], fill=GREEN[0])
    for _ in range(4):                                       # lighter tips
        x = rng.randrange(7, 25)
        y = rng.randrange(3, 16)
        d.point([x, y], fill=GREEN[2])
    # pot
    d.polygon([(8, 22), (24, 22), (22, 37), (10, 37)], fill=(196, 110, 70), outline=OUT)
    d.rectangle([7, 21, 25, 25], fill=(214, 128, 84), outline=OUT)
    d.line([8, 22, 24, 22], fill=(236, 160, 112))
    d.line([11, 27, 11, 35], fill=(226, 150, 100))
    d.line([21, 27, 20, 35], fill=(150, 78, 48))
    d.line([9, 24, 23, 24], fill=(160, 84, 52))
    save(im, "int_plant.png")


def bookcase():
    im, d = new(32, 40)
    rng = random.Random(8)
    shadow(d, 2, 39, 29)
    box(d, 1, 1, 30, 38, WOOD[1])
    d.rectangle([4, 4, 27, 35], fill=WOOD[0], outline=OUT)
    cols = [RED[1], BLUE[1], GREEN[1], GOLD, RED[0], BLUE[0], (200, 140, 90), GREEN[2]]
    for sy in (4, 15, 26):                                   # three book rows
        x = 5
        while x < 26:
            w = rng.choice((2, 3, 3, 4))
            h = rng.randrange(6, 9)
            c = cols[rng.randrange(len(cols))]
            if x + w > 26:
                break
            d.rectangle([x, sy + 9 - h, x + w - 1, sy + 8], fill=c, outline=OUT)
            d.line([x, sy + 10 - h, x, sy + 7], fill=shade(c, 1.3))
            x += w
        d.rectangle([2, sy + 9, 29, sy + 11], fill=WOOD[3], outline=OUT)
        d.line([3, sy + 10, 28, sy + 10], fill=shade(WOOD[3], 1.15))
    save(im, "int_bookcase.png")


def fridge():
    im, d = new(32, 40)
    shadow(d, 4, 39, 27)
    W = [(168, 176, 184), (206, 214, 222), (240, 246, 250)]
    box(d, 4, 1, 27, 38, W[1], hi=W[2], lo=W[0])
    d.line([4, 15, 27, 15], fill=OUT)                        # door split
    d.line([5, 16, 26, 16], fill=W[2])
    d.rectangle([22, 5, 23, 11], fill=IRON[2], outline=OUT)  # handles
    d.rectangle([22, 19, 23, 28], fill=IRON[2], outline=OUT)
    d.point([6, 4], fill=(255, 255, 255))
    d.rectangle([8, 22, 12, 26], fill=RED[1], outline=OUT)   # magnets
    d.rectangle([9, 8, 12, 10], fill=GOLD, outline=OUT)
    d.line([6, 37, 25, 37], fill=W[0])
    box(d, 6, 38, 9, 39, IRON[0])
    box(d, 22, 38, 25, 39, IRON[0])
    save(im, "int_fridge.png")


def tv():
    im, d = new(32, 40)
    shadow(d, 2, 39, 29)
    # cabinet
    box(d, 2, 21, 29, 37, WOOD[2])
    d.rectangle([1, 20, 30, 23], fill=WOOD[3], outline=OUT)
    d.line([2, 21, 29, 21], fill=shade(WOOD[3], 1.15))
    d.rectangle([4, 26, 15, 35], fill=WOOD[1], outline=OUT)
    d.rectangle([17, 26, 27, 35], fill=WOOD[1], outline=OUT)
    for x in (9, 21):
        d.rectangle([x, 30, x + 1, 31], fill=GOLD, outline=OUT)
    box(d, 3, 37, 6, 39, WOOD[0])
    box(d, 25, 37, 28, 39, WOOD[0])
    # tv
    box(d, 5, 3, 26, 19, IRON[0])
    d.rectangle([7, 5, 24, 16], fill=(96, 150, 214), outline=OUT)
    d.rectangle([8, 6, 23, 10], fill=(140, 190, 236))
    d.line([9, 7, 13, 7], fill=(230, 244, 255))
    d.line([8, 15, 23, 15], fill=(70, 116, 176))
    d.point([22, 18], fill=GREEN[2])
    d.rectangle([13, 19, 18, 20], fill=IRON[1], outline=OUT)  # stand
    save(im, "int_tv.png")


def lamp():
    im, d = new(32, 40)
    shadow(d, 8, 39, 23)
    # shade (warm, glowing)
    d.polygon([(9, 3), (22, 3), (27, 18), (4, 18)], fill=(240, 196, 110), outline=OUT)
    d.polygon([(11, 5), (16, 5), (14, 16), (8, 16)], fill=(255, 226, 150))
    d.line([6, 17, 25, 17], fill=(200, 140, 70))
    d.line([10, 4, 21, 4], fill=(255, 240, 190))
    # pole
    d.rectangle([15, 19, 16, 35], fill=IRON[1], outline=OUT)
    d.line([15, 20, 15, 34], fill=IRON[3])
    # base
    d.ellipse([9, 33, 22, 38], fill=IRON[1], outline=OUT)
    d.line([12, 35, 17, 35], fill=IRON[3])
    save(im, "int_lamp.png")


def toys():
    im, d = new(32, 32)
    # flat on the floor, lower part of the box, only a faint contact line
    def block(x, y, c):
        d.rectangle([x, y, x + 7, y + 7], fill=c[1], outline=OUT)
        d.line([x + 1, y + 1, x + 6, y + 1], fill=c[2])
        d.line([x + 1, y + 1, x + 1, y + 6], fill=c[2])
        d.line([x + 2, y + 6, x + 6, y + 6], fill=c[0])
        d.point([x + 4, y + 4], fill=(250, 240, 220))
    block(4, 17, RED)
    block(13, 20, BLUE)
    block(9, 11, GREEN)
    # ball
    d.ellipse([20, 12, 29, 21], fill=(236, 200, 80), outline=OUT)
    d.arc([20, 12, 29, 21], 200, 340, fill=RED[1])
    d.line([21, 16, 28, 16], fill=RED[1])
    d.point([22, 14], fill=(255, 246, 200))
    d.line([20, 24, 28, 24], fill=(42, 26, 16, 40))
    # little duck-less brick
    d.rectangle([21, 25, 28, 28], fill=(232, 208, 150), outline=OUT)
    d.point([23, 26], fill=RED[1])
    save(im, "int_toys.png")


def deskpc():
    im, d = new(64, 40)
    for x in (4, 54):
        box(d, x, 22, x + 5, 38, WOOD[1])
    shadow(d, 4, 39, 60)
    box(d, 1, 6, 62, 24, WOOD[2])
    d.rectangle([2, 24, 61, 29], fill=WOOD[1], outline=OUT)
    d.line([3, 25, 60, 25], fill=WOOD[2])
    d.rectangle([38, 26, 54, 28], fill=WOOD[0], outline=OUT)  # drawer
    d.rectangle([44, 26, 48, 27], fill=GOLD)
    # monitor
    box(d, 8, 1, 26, 13, IRON[0])
    d.rectangle([10, 3, 24, 11], fill=(96, 150, 214), outline=OUT)
    d.line([11, 5, 18, 5], fill=(220, 240, 255))
    d.line([11, 7, 22, 7], fill=(140, 190, 236))
    d.line([11, 9, 16, 9], fill=(140, 190, 236))
    d.rectangle([15, 13, 19, 14], fill=IRON[1], outline=OUT)
    # keyboard
    d.rectangle([9, 17, 25, 21], fill=IRON[2], outline=OUT)
    for x in range(11, 24, 2):
        d.point([x, 19], fill=IRON[0])
    # papers
    d.rectangle([32, 9, 42, 19], fill=(240, 232, 212), outline=OUT)
    d.rectangle([35, 11, 45, 21], fill=(250, 244, 230), outline=OUT)
    for y in (14, 16, 18):
        d.line([37, y, 43, y], fill=IRON[3])
    # mug
    d.rectangle([52, 10, 57, 16], fill=BLUE[1], outline=OUT)
    d.line([53, 11, 53, 15], fill=BLUE[2])
    d.line([53, 11, 56, 11], fill=(96, 56, 36))
    save(im, "int_deskpc.png")


def piano():
    im, d = new(64, 40)
    shadow(d, 3, 39, 60)
    # upper case with music stand
    box(d, 1, 1, 62, 22, WOOD[0], hi=WOOD[1], lo=shade(WOOD[0], 0.7))
    d.rectangle([5, 4, 58, 17], fill=WOOD[1], outline=OUT)   # front panel
    d.line([6, 5, 57, 5], fill=WOOD[2])
    for x in (20, 36, 52):
        d.line([x, 6, x, 16], fill=WOOD[0])
    d.rectangle([24, 7, 34, 15], fill=(240, 232, 212), outline=OUT)  # sheet music
    for y in (9, 11, 13):
        d.line([26, y, 32, y], fill=IRON[3])
    d.ellipse([8, 8, 14, 14], outline=GOLD)                  # carved medallion
    d.point([11, 11], fill=GOLD)
    # key slip + keys
    box(d, 1, 21, 62, 26, WOOD[3])
    d.rectangle([3, 26, 60, 34], fill=(246, 240, 224), outline=OUT)
    for x in range(6, 60, 3):
        d.line([x, 27, x, 34], fill=(190, 182, 166))
    for x in range(8, 58, 3):
        if (x - 8) // 3 % 7 in (2, 6):
            continue
        d.rectangle([x, 26, x + 1, 30], fill=IRON[0])
    # legs + pedals
    box(d, 3, 34, 8, 39, WOOD[0])
    box(d, 55, 34, 60, 39, WOOD[0])
    d.rectangle([29, 36, 34, 38], fill=GOLD, outline=OUT)
    save(im, "int_piano.png")


def main():
    os.makedirs(SPR, exist_ok=True)
    for fn in (sofa, armchair, plant, bookcase, fridge, tv, lamp, toys, deskpc, piano):
        fn()


if __name__ == "__main__":
    main()
