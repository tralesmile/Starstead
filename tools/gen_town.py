#!/usr/bin/env python3
"""Town sprites (original, CC0): house, barn, workshop, car, skid. Deterministic.
Same palette/style as gen_stall.py / gen_build.py: 1px dark outline, top-left light.
Building bottom row = ground line (door base on the last row)."""
import os
import random
from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SPR = os.path.join(ROOT, "assets", "sprites")
OUT = (42, 26, 16)
WOOD = [(110, 70, 38), (138, 90, 52), (166, 112, 63), (190, 132, 76)]
DOOR = [(88, 48, 32), (118, 64, 40), (148, 86, 52), (176, 112, 70)]
GLOW = [(214, 150, 50), (248, 206, 96), (255, 238, 160)]
STONE = [(96, 94, 88), (128, 126, 118), (160, 156, 146)]


def shade(c, k):
    return tuple(max(0, min(255, int(v * k))) for v in c)


def new(w, h):
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    return im, ImageDraw.Draw(im)


def save(im, name):
    im.save(os.path.join(SPR, name))
    print("wrote", name, im.size)


def planks(d, x0, y0, x1, y1, pal, rng, pw=8):
    d.rectangle([x0, y0, x1, y1], fill=pal[1])
    for px in range(x0, x1 + 1, pw):
        e = min(px + pw - 1, x1)
        base = shade(pal[1], rng.uniform(0.93, 1.07))
        d.rectangle([px, y0, e, y1], fill=base)
        d.line([px, y0, px, y1], fill=shade(base, 1.15))
        d.line([e, y0, e, y1], fill=shade(pal[0], 0.95))
        for _ in range(3):
            gx = px + rng.randrange(2, max(3, pw - 2)); gy = rng.randrange(y0 + 2, max(y0 + 3, y1 - 8))
            d.line([gx, gy, gx, gy + rng.randrange(3, 8)], fill=shade(base, rng.choice((0.88, 1.1))))


def shingle_roof(d, poly_top, x0, x1, y0, y1, pal, rng, row_h=6, sw=7):
    """Fill rect with staggered shingle rows (3/4 view: lit upper rows, darker lower edge)."""
    d.rectangle([x0, y0, x1, y1], fill=pal[1])
    r = 0
    for y in range(y0, y1, row_h):
        off = (r % 2) * (sw // 2)
        for x in range(x0 - off, x1 + 1, sw):
            a, b = max(x0, x), min(x1, x + sw - 1)
            if a > b:
                continue
            c = shade(pal[1], rng.uniform(0.9, 1.1))
            d.rectangle([a, y, b, min(y1, y + row_h - 1)], fill=c)
            d.line([a, y, b, y], fill=shade(c, 1.2))
            d.line([b, y, b, min(y1, y + row_h - 1)], fill=shade(pal[0], 0.9))
            d.line([a, min(y1, y + row_h - 1), b, min(y1, y + row_h - 1)], fill=shade(pal[0], 0.85))
        r += 1


def window(d, x, y, w, h, glow=True):
    d.rectangle([x - 2, y - 2, x + w + 1, y + h + 1], fill=WOOD[3], outline=OUT)   # frame
    d.rectangle([x, y, x + w - 1, y + h - 1], fill=GLOW[1] if glow else (90, 120, 150))
    d.rectangle([x, y, x + w // 2 - 1, y + h // 2 - 1], fill=GLOW[2])              # bright corner
    d.line([x + w // 2, y, x + w // 2, y + h - 1], fill=WOOD[1])                   # mullions
    d.line([x, y + h // 2, x + w - 1, y + h // 2], fill=WOOD[1])
    d.line([x - 3, y + h + 2, x + w + 2, y + h + 2], fill=OUT)                     # sill shadow
    d.rectangle([x - 3, y + h + 2, x + w + 2, y + h + 3], fill=WOOD[2], outline=OUT)


def ground_shadow(im, x0, x1, y):
    """soft contact shadow hugging the base, drawn first so it sits under the walls"""
    sh = Image.new("RGBA", im.size, (0, 0, 0, 0)); sd = ImageDraw.Draw(sh)
    sd.rectangle([x0, y - 2, x1, y], fill=(0, 0, 0, 60))
    im.alpha_composite(sh)


def stone_base(d, x0, x1, y0, y1, rng):
    d.rectangle([x0, y0, x1, y1], fill=STONE[1], outline=OUT)
    x = x0 + 1
    while x < x1:
        w = rng.randrange(6, 11); e = min(x + w, x1 - 1)
        c = shade(STONE[1], rng.uniform(0.92, 1.08))
        d.rectangle([x, y0 + 1, e, y1 - 1], fill=c)
        d.line([x, y0 + 1, e, y0 + 1], fill=STONE[2])
        d.line([e, y0 + 1, e, y1 - 1], fill=STONE[0])
        x = e + 1


def house():
    rng = random.Random(21)
    W, H = 96, 96
    im, d = new(W, H)
    RED = [(112, 52, 44), (150, 72, 56), (184, 98, 70)]   # warm clay shingles
    # roof (seen 3/4 from above): big sloped mass
    top = 2
    shingle_roof(d, None, 4, 91, top + 8, 50, RED, rng)
    # ridge cap + trapezoid silhouette via corner cuts
    d.rectangle([4, top + 8, 91, 50], outline=OUT)
    d.polygon([(4, top + 8), (20, top), (75, top), (91, top + 8)], fill=RED[2], outline=OUT)
    d.line([21, top + 1, 74, top + 1], fill=shade(RED[2], 1.15))
    for x in range(22, 75, 5):
        d.line([x, top + 2, x, top + 6], fill=RED[1])
    d.line([5, 50, 90, 50], fill=OUT)
    # eave shadow on wall
    # front wall
    wy0, wy1 = 51, 95
    planks(d, 7, wy0, 88, wy1, WOOD, rng)
    d.rectangle([7, wy0, 88, wy1], outline=OUT)
    d.rectangle([8, wy0 + 1, 87, wy0 + 4], fill=shade(WOOD[0], 0.7))     # eave shadow
    # stone footing
    stone_base(d, 5, 90, 90, 95, rng)
    # windows with warm glow
    window(d, 18, 64, 12, 12)
    window(d, 66, 64, 12, 12)
    # door, bottom centre (x 41..54)
    d.rectangle([40, 66, 55, 95], fill=DOOR[1], outline=OUT)
    for x in (42, 47, 52):
        d.line([x, 67, x, 94], fill=DOOR[2])
        d.line([x + 2, 67, x + 2, 94], fill=DOOR[0])
    d.rectangle([40, 64, 55, 66], fill=WOOD[3], outline=OUT)             # lintel
    d.rectangle([44, 70, 51, 76], fill=GLOW[1], outline=OUT)             # door window
    d.rectangle([44, 70, 47, 72], fill=GLOW[2])
    d.point([52, 84], fill=(232, 190, 60)); d.point([52, 85], fill=(232, 190, 60))  # knob
    d.rectangle([38, 93, 57, 95], fill=STONE[2], outline=OUT)            # step
    # chimney
    d.rectangle([68, 0, 80, 14], fill=STONE[1], outline=OUT)
    d.line([69, 1, 69, 13], fill=STONE[2]); d.line([79, 1, 79, 13], fill=STONE[0])
    d.rectangle([67, 0, 81, 2], fill=STONE[2], outline=OUT)
    save(im, "house.png")


def barn():
    rng = random.Random(33)
    W, H = 128, 96
    im, d = new(W, H)
    BARN = [(92, 36, 30), (124, 52, 40), (152, 70, 50), (176, 90, 62)]
    TRIM = (226, 214, 184)
    # gambrel roof: dark shingles, two slopes
    roof = [(86, 62, 56), (112, 80, 70), (140, 102, 88)]
    d.polygon([(2, 36), (22, 6), (106, 6), (126, 36)], fill=roof[1], outline=OUT)
    # shingle rows clipped to the roof polygon
    mask = Image.new("L", (W, H), 0); ImageDraw.Draw(mask).polygon([(3, 35), (23, 7), (105, 7), (125, 35)], fill=255)
    tex, td = new(W, H)
    shingle_roof(td, None, 2, 126, 6, 36, roof, rng, row_h=5, sw=8)
    im.paste(tex, (0, 0), mask)
    d.polygon([(2, 36), (22, 6), (106, 6), (126, 36)], outline=OUT)
    d.line([23, 7, 105, 7], fill=roof[2])
    d.rectangle([20, 3, 108, 6], fill=roof[2], outline=OUT)               # ridge cap
    d.line([2, 36, 126, 36], fill=OUT)
    # front wall, vertical red-brown boards
    planks(d, 6, 37, 121, 95, BARN, rng, pw=7)
    d.rectangle([6, 37, 121, 95], outline=OUT)
    d.rectangle([7, 38, 120, 41], fill=shade(BARN[0], 0.75))               # eave shadow
    # corner trim
    for x in (6, 118):
        d.rectangle([x, 37, x + 3, 95], fill=TRIM, outline=OUT)
    # hayloft door + window
    d.rectangle([52, 46, 75, 62], fill=BARN[0], outline=OUT)
    d.rectangle([54, 48, 73, 60], fill=(40, 28, 22), outline=TRIM)
    d.line([54, 48, 73, 60], fill=TRIM); d.line([73, 48, 54, 60], fill=TRIM)
    d.rectangle([58, 49, 69, 52], fill=(190, 160, 70))                       # hay glimpse
    # big double door, bottom centre x 48..79
    d.rectangle([46, 64, 81, 95], fill=TRIM, outline=OUT)                    # frame
    for x0 in (48, 65):
        d.rectangle([x0, 66, x0 + 14, 95], fill=BARN[2], outline=OUT)
        for yy in range(67, 95, 4):
            d.line([x0 + 1, yy, x0 + 13, yy], fill=BARN[1])
        d.line([x0 + 1, 67, x0 + 13, 94], fill=TRIM); d.line([x0 + 13, 67, x0 + 1, 94], fill=TRIM)  # X brace
        d.rectangle([x0, 66, x0 + 14, 68], outline=OUT, fill=TRIM)
    d.line([64, 66, 64, 95], fill=OUT)
    d.rectangle([61, 80, 62, 84], fill=(60, 56, 54), outline=OUT); d.rectangle([66, 80, 67, 84], fill=(60, 56, 54), outline=OUT)
    # side windows
    for x in (18, 98):
        d.rectangle([x, 62, x + 9, 74], fill=TRIM, outline=OUT)
        d.rectangle([x + 2, 64, x + 7, 72], fill=GLOW[0]); d.rectangle([x + 2, 64, x + 4, 66], fill=GLOW[1])
        d.line([x + 5, 64, x + 5, 72], fill=BARN[0])
    # stone footing
    d.rectangle([4, 91, 123, 95], fill=STONE[1], outline=OUT); d.line([5, 91, 122, 91], fill=STONE[2])
    d.rectangle([46, 91, 81, 95], fill=DOOR[0], outline=OUT); d.line([48, 94, 79, 94], fill=OUT)  # threshold
    save(im, "barn.png")


def workshop():
    rng = random.Random(45)
    W, H = 112, 88
    im, d = new(W, H)
    TIN = [(88, 98, 108), (122, 134, 146), (158, 170, 182), (196, 206, 214)]
    WALL = [(108, 100, 86), (140, 130, 110), (168, 156, 132)]
    # corrugated roof: vertical ribs
    d.polygon([(2, 34), (12, 6), (100, 6), (110, 34)], fill=TIN[1], outline=OUT)
    mask = Image.new("L", (W, H), 0); ImageDraw.Draw(mask).polygon([(3, 33), (13, 7), (99, 7), (109, 33)], fill=255)
    tex, td = new(W, H)
    for x in range(2, 111, 4):
        td.rectangle([x, 6, x + 3, 34], fill=TIN[1])
        td.line([x, 6, x, 34], fill=TIN[3]); td.line([x + 1, 6, x + 1, 34], fill=TIN[2])
        td.line([x + 3, 6, x + 3, 34], fill=TIN[0])
    for y in (13, 24):                                                       # panel overlaps
        td.line([2, y, 110, y], fill=TIN[0]); td.line([2, y + 1, 110, y + 1], fill=TIN[3])
    for _ in range(10):                                                      # rust flecks
        rx, ry = rng.randrange(6, 106), rng.randrange(8, 32)
        td.point([rx, ry], fill=(150, 90, 60)); td.point([rx + 1, ry], fill=(130, 76, 52))
    im.paste(tex, (0, 0), mask)
    d.polygon([(2, 34), (12, 6), (100, 6), (110, 34)], outline=OUT)
    d.rectangle([10, 3, 102, 6], fill=TIN[3], outline=OUT)                   # ridge
    d.line([2, 34, 110, 34], fill=OUT)
    # wall: grey-tan boards
    planks(d, 5, 35, 106, 87, WALL, rng, pw=6)
    d.rectangle([5, 35, 106, 87], outline=OUT)
    d.rectangle([6, 36, 105, 39], fill=shade(WALL[0], 0.75))
    for x in (5, 103):
        d.rectangle([x, 35, x + 3, 87], fill=WOOD[2], outline=OUT)
    # open garage door, bottom centre x 34..77 (centre ~56)
    d.rectangle([32, 48, 79, 87], fill=WOOD[3], outline=OUT)                 # frame
    d.rectangle([34, 50, 77, 87], fill=(34, 26, 24))                         # dark interior
    d.rectangle([34, 50, 77, 56], fill=(52, 42, 38))
    # interior: workbench + tools, tyre
    d.rectangle([40, 70, 62, 74], fill=WOOD[1], outline=OUT); d.rectangle([41, 74, 43, 86], fill=WOOD[0]); d.rectangle([59, 74, 61, 86], fill=WOOD[0])
    d.rectangle([44, 66, 50, 70], fill=(170, 60, 50), outline=OUT)           # toolbox
    d.line([54, 66, 58, 70], fill=TIN[2]); d.line([54, 70, 58, 66], fill=TIN[2])
    d.ellipse([66, 74, 76, 86], fill=(24, 22, 22), outline=(70, 66, 64)); d.ellipse([69, 77, 73, 83], fill=TIN[0])
    d.rectangle([36, 52, 75, 53], fill=GLOW[0])                              # lamp glow on lintel
    # rolled-up door at the top of the opening
    d.rectangle([32, 46, 79, 52], fill=TIN[2], outline=OUT)
    for x in range(33, 79, 3):
        d.line([x, 47, x, 51], fill=TIN[1])
    # windows
    for x in (14, 86):
        window(d, x, 52, 10, 10)
    # chimney (brick) on roof, right
    BR = [(110, 52, 44), (146, 76, 60), (176, 100, 80)]
    d.rectangle([78, 0, 90, 20], fill=BR[1], outline=OUT)
    for y in range(3, 20, 4):
        d.line([79, y, 89, y], fill=BR[0])
    d.line([79, 1, 79, 19], fill=BR[2]); d.line([89, 1, 89, 19], fill=BR[0])
    d.rectangle([77, 0, 91, 2], fill=BR[2], outline=OUT)
    # concrete apron
    d.rectangle([3, 85, 108, 87], fill=STONE[1], outline=OUT); d.line([4, 85, 107, 85], fill=STONE[2])
    save(im, "workshop.png")


def car():
    W, H = 28, 16
    im, d = new(W, H)
    BODY = [(120, 34, 38), (176, 52, 52), (214, 84, 72)]
    # wheels peeking out
    for x in (5, 19):
        for y in (0, 12):
            d.rectangle([x, y, x + 5, y + 3], fill=(26, 24, 26), outline=OUT)
            d.line([x + 1, y + 1, x + 4, y + 1], fill=(70, 68, 70))
    # body: rounded
    d.rounded_rectangle([1, 2, 26, 13], radius=4, fill=BODY[1], outline=OUT)
    d.line([4, 3, 22, 3], fill=BODY[2])                                       # top-left highlight
    d.line([3, 12, 23, 12], fill=BODY[0])
    # hood line & bonnet
    d.line([19, 4, 19, 11], fill=BODY[0])
    # cabin roof (lighter), windshield front, rear window back
    d.rounded_rectangle([8, 4, 19, 11], radius=2, fill=BODY[2], outline=OUT)
    d.rectangle([17, 5, 19, 10], fill=(120, 190, 220), outline=OUT)           # windshield
    d.point([18, 6], fill=(220, 244, 250))
    d.rectangle([7, 5, 8, 10], fill=(86, 130, 160), outline=OUT)             # rear window
    # lights
    d.rectangle([25, 3, 26, 4], fill=GLOW[2]); d.rectangle([25, 11, 26, 12], fill=GLOW[2])
    d.rectangle([1, 3, 1, 4], fill=(230, 50, 40)); d.rectangle([1, 11, 1, 12], fill=(230, 50, 40))
    save(im, "car.png")


def skid():
    im, d = new(12, 12)
    cx = cy = 5.5
    for y in range(12):
        for x in range(12):
            r = ((x - cx) ** 2 + (y - cy) ** 2) ** 0.5 / 6.0
            a = max(0.0, 1.0 - r)
            if a > 0:
                im.putpixel((x, y), (20, 16, 14, int(150 * a * a ** 0.5)))
    save(im, "skid.png")


if __name__ == "__main__":
    os.makedirs(SPR, exist_ok=True)
    house(); barn(); workshop(); car(); skid()
