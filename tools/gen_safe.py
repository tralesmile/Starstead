#!/usr/bin/env python3
"""Safe + alarm panel sprites (original, CC0). Deterministic (fixed seeds).
Reuses helpers/palettes from gen_interior.py. 3/4 top-down, light top-left,
1px dark outline, objects sit at the BOTTOM of their box."""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gen_interior import (new, shade, box, shadow, save, OUT, IRON, RED,  # noqa: E402
                          GREEN, SPR)

GOLD = (222, 190, 90)
STEEL = [(88, 96, 108), (122, 132, 146), (160, 170, 184), (200, 210, 222)]
BEIGE = [(184, 168, 134), (222, 208, 170), (244, 234, 202)]
CASH = [(70, 120, 66), (100, 156, 88), (140, 190, 112)]


def _safe_body(d):
    shadow(d, 3, 39, 28)
    for x in (4, 24):                                        # feet
        box(d, x, 36, x + 3, 38, IRON[0])
    box(d, 2, 2, 29, 36, STEEL[1], hi=STEEL[3], lo=STEEL[0])  # body


def safe():
    im, d = new(32, 40)
    _safe_body(d)
    d.rectangle([5, 5, 26, 33], fill=STEEL[2], outline=OUT)   # door
    d.line([6, 6, 25, 6], fill=STEEL[3])
    d.line([6, 6, 6, 32], fill=STEEL[3])
    d.line([7, 32, 25, 32], fill=STEEL[0])
    d.line([25, 7, 25, 32], fill=STEEL[0])
    for y in (8, 29):                                        # hinge bolts
        d.rectangle([3, y, 4, y + 1], fill=IRON[3], outline=OUT)
    # dial
    d.ellipse([9, 10, 21, 22], fill=IRON[0], outline=OUT)
    d.ellipse([11, 12, 19, 20], fill=STEEL[1], outline=IRON[0])
    d.line([12, 13, 16, 12], fill=STEEL[3])
    d.line([15, 14, 15, 16], fill=OUT)                       # pointer
    d.point([15, 12], fill=RED[2])
    for a in (9, 15, 21):                                    # tick marks
        d.point([a, 9], fill=OUT)
    d.point([15, 9], fill=GOLD)
    # handle
    d.rectangle([21, 25, 24, 27], fill=IRON[1], outline=OUT)
    d.line([21, 25, 23, 25], fill=STEEL[3])
    d.rectangle([11, 26, 18, 28], fill=IRON[1], outline=OUT)
    d.line([12, 26, 17, 26], fill=STEEL[3])
    d.point([6, 4], fill=(255, 255, 255))
    save(im, "int_safe.png")


def safe_open():
    im, d = new(32, 40)
    _safe_body(d)
    # dark interior
    d.rectangle([5, 5, 26, 33], fill=(26, 22, 28), outline=OUT)
    d.line([6, 6, 25, 6], fill=(10, 8, 12))
    d.line([6, 6, 6, 32], fill=(10, 8, 12))
    d.line([6, 20, 25, 20], fill=IRON[0])                     # shelf
    d.line([6, 21, 25, 21], fill=IRON[1])
    # cash bundles
    for x0, y0 in ((8, 25), (16, 25), (12, 22)):
        d.rectangle([x0, y0, x0 + 7, y0 + 4], fill=CASH[1], outline=OUT)
        d.line([x0 + 1, y0 + 1, x0 + 6, y0 + 1], fill=CASH[2])
        d.rectangle([x0 + 3, y0, x0 + 4, y0 + 4], fill=(230, 220, 170))
    d.rectangle([8, 29, 24, 32], fill=CASH[1], outline=OUT)
    d.line([9, 30, 23, 30], fill=CASH[2])
    d.rectangle([14, 29, 17, 32], fill=(230, 220, 170), outline=OUT)
    # gold bar on the shelf
    d.polygon([(9, 18), (21, 18), (23, 14), (11, 14)], fill=GOLD, outline=OUT)
    d.line([12, 15, 21, 15], fill=(255, 236, 150))
    d.rectangle([9, 18, 21, 19], fill=(180, 140, 50))
    # open door swung out on the left, seen edge-on with a sliver of face
    d.polygon([(0, 8), (5, 3), (5, 35), (0, 38)], fill=STEEL[2], outline=OUT)
    d.line([1, 10, 1, 36], fill=STEEL[3])
    d.line([4, 6, 4, 33], fill=STEEL[0])
    d.ellipse([1, 17, 3, 21], fill=IRON[0])                  # dial seen from the side
    d.point([1, 19], fill=STEEL[3])
    for y in (8, 29):
        d.rectangle([4, y, 5, y + 1], fill=IRON[3], outline=OUT)
    save(im, "int_safe_open.png")


def _alarm(lit):
    im, d = new(32, 32)
    # soft wall shadow under the box
    d.line([8, 30, 23, 30], fill=(42, 26, 16, 60))
    if lit:
        for r, a in ((14, 40), (11, 70)):                    # siren glow halo
            d.ellipse([16 - r, 6 - r + 2, 16 + r, 6 + r + 2], fill=(255, 60, 40, a // 2))
    # siren bell on top
    d.rectangle([13, 8, 18, 9], fill=IRON[1], outline=OUT)
    bell = (255, 70, 56) if lit else RED[1]
    d.pieslice([9, 1, 22, 14], 180, 360, fill=bell, outline=OUT)
    d.line([12, 4, 15, 3], fill=(255, 190, 170) if lit else RED[2])
    d.point([11, 6], fill=(255, 210, 190) if lit else RED[2])
    d.line([11, 8, 20, 8], fill=OUT)
    # panel box
    box(d, 6, 10, 25, 29, BEIGE[1], hi=BEIGE[2], lo=BEIGE[0])
    # LED
    d.rectangle([9, 13, 11, 15], fill=IRON[0], outline=OUT)
    d.point([10, 14], fill=(255, 70, 50) if lit else RED[0])
    if lit:
        d.point([10, 13], fill=(255, 190, 170))
        d.point([9, 14], fill=(255, 120, 100))
        d.point([11, 14], fill=(255, 120, 100))
    # small display
    d.rectangle([14, 13, 22, 16], fill=(40, 60, 50), outline=OUT)
    d.line([15, 14, 19, 14], fill=GREEN[2] if not lit else (255, 120, 100))
    # keypad 3x3
    for r in range(3):
        for c in range(3):
            x = 10 + c * 4
            y = 19 + r * 3
            d.rectangle([x, y, x + 2, y + 1], fill=BEIGE[0] if (r + c) % 2 else IRON[2], outline=OUT)
    d.line([8, 28, 23, 28], fill=BEIGE[0])
    return im


def alarm():
    save(_alarm(False), "int_alarm.png")


def alarm_ring():
    save(_alarm(True), "int_alarm_ring.png")


def main():
    os.makedirs(SPR, exist_ok=True)
    for fn in (safe, safe_open, alarm, alarm_ring):
        fn()


if __name__ == "__main__":
    main()
