#!/usr/bin/env python3
"""Bank vault job props (original, CC0), 32px cells, one sheet assets/sprites/bankjob.png. Deterministic.
Frames, left to right: desk with keycard (64px), desk empty (64px), fuse box on, fuse box off,
cash bag, filing cabinet. Reuses helpers/palettes from gen_interior.py."""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gen_interior import new, box, shadow, save, OUT, IRON, RED, GREEN, WOOD  # noqa: E402

STEEL = [(88, 96, 108), (122, 132, 146), (160, 170, 184), (200, 210, 222)]
CANVAS = [(150, 122, 80), (188, 160, 108), (218, 194, 140)]
GOLD = (240, 200, 70)


def desk(d, ox, card):
    shadow(d, ox + 3, 31, ox + 60)
    box(d, ox + 2, 6, ox + 61, 20, WOOD[2], hi=WOOD[3])          # top
    box(d, ox + 4, 21, ox + 59, 30, WOOD[1], lo=WOOD[0])         # front
    for x in (8, 40):
        box(d, ox + x, 23, ox + x + 15, 28, WOOD[2])
        d.point([ox + x + 8, 25], fill=GOLD)
    box(d, ox + 8, 2, ox + 21, 12, IRON[1])                       # monitor
    d.rectangle([ox + 10, 4, ox + 19, 10], fill=(110, 170, 150))
    box(d, ox + 48, 8, ox + 53, 14, (236, 232, 220))              # mug
    if card:
        box(d, ox + 29, 9, ox + 40, 16, GOLD, hi=(255, 232, 140))
        d.rectangle([ox + 31, 13, ox + 38, 14], fill=OUT)


def fuse(d, ox, on):
    box(d, ox + 6, 4, ox + 25, 28, STEEL[1], hi=STEEL[3], lo=STEEL[0])
    d.rectangle([ox + 9, 7, ox + 22, 12], fill=(240, 200, 60), outline=OUT)
    d.polygon([(ox + 16, 7), (ox + 13, 10), (ox + 15, 10), (ox + 14, 12), (ox + 18, 9), (ox + 16, 9)], fill=OUT)
    y = 15 if on else 21
    d.rectangle([ox + 14, 15, ox + 17, 25], fill=IRON[0], outline=OUT)
    box(d, ox + 11, y, ox + 20, y + 4, RED[1] if on else IRON[2])
    d.rectangle([ox + 21, 15, ox + 23, 17], fill=(240, 70, 60) if on else GREEN[2], outline=OUT)


def bag(d, ox):
    shadow(d, ox + 6, 29, ox + 26)
    d.ellipse([ox + 5, 11, ox + 26, 29], fill=CANVAS[1], outline=OUT)
    d.ellipse([ox + 8, 14, ox + 15, 21], fill=CANVAS[2])
    d.polygon([(ox + 11, 12), (ox + 9, 5), (ox + 22, 5), (ox + 20, 12)], fill=CANVAS[1], outline=OUT)
    d.rectangle([ox + 11, 10, ox + 20, 12], fill=RED[1], outline=OUT)
    for y, x0, x1 in ((17, 14, 19), (18, 13, 14), (20, 14, 18), (22, 18, 19), (23, 13, 18)):
        d.rectangle([ox + x0, y, ox + x1, y + 1], fill=(56, 96, 52))
    d.rectangle([ox + 16, 15, ox + 16, 26], fill=(56, 96, 52))


def cabinet(d, ox):
    shadow(d, ox + 2, 31, ox + 29)
    box(d, ox + 1, 1, ox + 30, 30, STEEL[1], hi=STEEL[3], lo=STEEL[0])
    for y in (4, 13, 22):
        box(d, ox + 4, y, ox + 27, y + 6, STEEL[2], hi=STEEL[3])
        d.rectangle([ox + 12, y + 2, ox + 19, y + 3], fill=IRON[0])


im, d = new(256, 32)
desk(d, 0, True)
desk(d, 64, False)
fuse(d, 128, True)
fuse(d, 160, False)
bag(d, 192)
cabinet(d, 224)
save(im, "bankjob.png")
