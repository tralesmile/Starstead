#!/usr/bin/env python3
"""Artisan machines as interior furniture (original, CC0): cheese press and preserves jar (32x40),
loom (64x48). Same conventions as gen_interior.py: bottom-anchored, top-left light, 1px outline.
Deterministic."""
from PIL import ImageDraw
from gen_interior import OUT, WOOD, IRON, RED, box, new, save, shadow

CHEESE = [(188, 128, 36), (232, 180, 56), (250, 214, 96), (255, 238, 160)]
CLOTH = [(46, 106, 108), (78, 156, 152), (132, 200, 190)]
CREAM = [(196, 176, 132), (236, 222, 184), (252, 244, 220)]


def press():
    im, d = new(32, 40)
    shadow(d, 2, 39, 30)
    for x in (3, 25):                                   # uprights
        box(d, x, 6, x + 3, 38, WOOD[1], hi=WOOD[3], lo=WOOD[0])
    box(d, 1, 6, 30, 11, WOOD[2], hi=WOOD[3], lo=WOOD[0])   # head beam
    for x in (4, 27):                                   # pegs
        d.rectangle([x, 8, x + 1, 9], fill=IRON[1])
    # screw with a turning bar
    d.rectangle([14, 2, 17, 5], fill=IRON[2], outline=OUT)
    d.rectangle([8, 1, 23, 3], fill=WOOD[2], outline=OUT)
    d.line([9, 2, 22, 2], fill=WOOD[3])
    for x in (7, 23):
        d.rectangle([x, 0, x + 1, 4], fill=WOOD[1], outline=OUT)
    d.rectangle([13, 12, 18, 19], fill=IRON[2], outline=OUT)
    for y in (13, 15, 17):                              # thread
        d.line([14, y + 1, 17, y], fill=IRON[0])
    d.line([14, 12, 14, 19], fill=IRON[3])
    box(d, 8, 19, 23, 22, WOOD[2], hi=WOOD[3], lo=WOOD[0])  # pressing plate
    # cheese wheel in cheesecloth
    d.polygon([(9, 23), (22, 23), (24, 25), (24, 27), (22, 29), (9, 29), (7, 27), (7, 25)], fill=CHEESE[1], outline=OUT)
    d.line([9, 24, 22, 24], fill=CHEESE[3])
    d.line([8, 25, 8, 27], fill=CHEESE[2]); d.line([9, 25, 9, 28], fill=CHEESE[2])
    d.line([22, 25, 22, 28], fill=CHEESE[0]); d.line([23, 25, 23, 27], fill=CHEESE[0])
    d.line([8, 26, 23, 26], fill=CHEESE[0])
    for x, y in ((12, 24), (18, 28), (15, 25)):
        d.point([x, y], fill=CHEESE[0])
    # bed with a drip groove and spout, then the lower rail
    box(d, 1, 30, 30, 34, WOOD[3], lo=WOOD[1])
    d.line([6, 31, 25, 31], fill=WOOD[0])
    d.point([16, 35], fill=CREAM[2]); d.point([16, 37], fill=CREAM[2])
    box(d, 7, 35, 12, 36, WOOD[0]); box(d, 19, 35, 24, 36, WOOD[0])
    save(im, "int_press.png")


def jar():
    im, d = new(32, 40)
    shadow(d, 4, 39, 28)
    # stand: splayed legs, stretcher, top board
    for pts in ([(7, 30), (11, 30), (9, 38), (5, 38)], [(21, 30), (25, 30), (27, 38), (23, 38)]):
        d.polygon(pts, fill=WOOD[1], outline=OUT)
    d.line([8, 31, 6, 37], fill=WOOD[3])
    box(d, 8, 33, 24, 35, WOOD[0])
    box(d, 3, 27, 28, 31, WOOD[3], lo=WOOD[1])
    # big glass jar
    d.polygon([(11, 7), (21, 7), (25, 11), (25, 25), (23, 27), (9, 27), (7, 25), (7, 11)],
              fill=(178, 214, 208), outline=OUT)
    d.rectangle([8, 13, 24, 25], fill=(174, 182, 76))              # brine
    d.line([9, 26, 23, 26], fill=(128, 134, 50))
    d.line([8, 13, 24, 13], fill=(222, 228, 140))
    d.line([23, 14, 23, 25], fill=(128, 134, 50)); d.line([24, 14, 24, 25], fill=(128, 134, 50))
    for x, y0 in ((10, 16), (15, 14), (20, 17)):                   # gherkins
        d.rectangle([x, y0, x + 2, 25], fill=(66, 112, 40))
        d.line([x, y0 + 1, x, 24], fill=(112, 160, 60))
        for y in range(y0 + 2, 25, 3):
            d.point([x + 1, y], fill=(170, 200, 96))
    for x, y in ((13, 18), (18, 23), (14, 24)):                    # peppers
        d.rectangle([x, y, x + 1, y + 1], fill=(212, 76, 44))
    d.line([9, 10, 9, 22], fill=(236, 250, 248)); d.line([10, 9, 11, 9], fill=(236, 250, 248))
    d.point([9, 24], fill=(236, 250, 248))
    # checked cloth lid tied with twine
    d.polygon([(11, 1), (21, 1), (23, 5), (24, 7), (8, 7), (9, 5)], fill=CREAM[2], outline=OUT)
    for y in range(2, 7):
        for x in range(9, 24):
            if im.getpixel((x, y))[:3] == CREAM[2] and (x // 2 + y // 2) % 2:
                d.point([x, y], fill=RED[2])
    d.line([10, 7, 22, 7], fill=(186, 140, 80))
    d.line([10, 8, 22, 8], fill=OUT)
    d.line([22, 8, 23, 10], fill=(186, 140, 80))
    # paper label
    d.rectangle([12, 19, 20, 23], fill=CREAM[1], outline=OUT)
    d.line([14, 21, 18, 21], fill=WOOD[0])
    save(im, "int_jar.png")


def loom():
    im, d = new(64, 48)
    shadow(d, 3, 47, 61)
    # warp threads stretched between the beams
    d.rectangle([10, 8, 53, 36], fill=(88, 56, 34))
    for x in range(11, 53, 2):
        d.line([x, 8, x, 36], fill=CREAM[1] if (x // 2) % 2 else CREAM[0])
    # finished cloth in the lower half, with stripes and a stepped working edge
    d.rectangle([10, 25, 53, 36], fill=CLOTH[1])
    d.rectangle([10, 23, 33, 24], fill=CLOTH[1])
    d.line([10, 22, 33, 22], fill=OUT); d.line([34, 23, 34, 24], fill=OUT); d.line([34, 24, 53, 24], fill=OUT)
    for y in range(24, 37, 2):
        for x in range(10 + (y // 2) % 2, 54, 2):
            d.point([x, y], fill=CLOTH[2])
    d.rectangle([10, 28, 53, 29], fill=CREAM[1])
    d.rectangle([10, 32, 53, 32], fill=RED[2])
    d.line([10, 36, 53, 36], fill=CLOTH[0])
    # heddle bar with strings
    box(d, 9, 13, 54, 15, WOOD[2], hi=WOOD[3], lo=WOOD[0])
    for x in range(16, 52, 12):
        d.line([x, 8, x, 12], fill=OUT)
    # shuttle resting on the weft, trailing yarn
    d.line([34, 23, 41, 22], fill=RED[2])
    d.polygon([(40, 21), (44, 19), (49, 19), (52, 21), (49, 23), (44, 23)], fill=WOOD[3], outline=OUT)
    d.line([44, 21, 48, 21], fill=RED[1])
    # frame: uprights, top and cloth beams
    for x in (5, 54):
        box(d, x, 2, x + 4, 45, WOOD[1], hi=WOOD[3], lo=WOOD[0])
        box(d, x - 2, 44, x + 6, 46, WOOD[0])
    box(d, 2, 4, 61, 8, WOOD[2], hi=WOOD[3], lo=WOOD[0])
    box(d, 3, 36, 60, 40, WOOD[2], hi=WOOD[3], lo=WOOD[0])
    for x in (2, 60):                                   # beam knobs
        for y in (5, 37):
            d.rectangle([x - 1, y, x + 2, y + 2], fill=WOOD[3], outline=OUT)
    # yarn basket under the loom
    for x, c in ((20, RED), (27, ((176, 136, 52), (212, 172, 74), (238, 206, 110))), (34, CLOTH)):
        d.ellipse([x, 40, x + 6, 45], fill=c[1], outline=OUT)
        d.line([x + 2, 42, x + 4, 44], fill=c[0]); d.point([x + 2, 41], fill=c[2])
    box(d, 18, 43, 42, 46, WOOD[0], hi=WOOD[2])
    save(im, "int_loom.png")


def main():
    press()
    jar()
    loom()


if __name__ == "__main__":
    main()
