#!/usr/bin/env python3
"""Bicycle racing art (original, CC0). Deterministic (fixed seeds). 1px dark outline, light from top-left.
bike_riders.png: rider on a road bike seen from above, facing right, frames of 28x20. One row per rider (5 jerseys);
  columns 0-3 upright pedal cycle, 4-7 leaning left (into an anticlockwise bend), 8-11 hard lean, 12 crashed.
bike_track.png: the 640x360 criterium course. The geometry constants MUST match BikeView (CENTER, PX, HALF).
bike_rack.png: the 48x34 rack of bikes that opens the race on the circuit infield."""
import math
import os
import random
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gen_interior import new, shade, save, OUT, WOOD  # noqa: E402

FW, FH = 28, 20
JERSEYS = [(244, 196, 48), (206, 62, 54), (62, 112, 206), (70, 160, 82), (156, 84, 178)]
HELMETS = [(250, 250, 240), (46, 42, 48), (240, 240, 244), (246, 238, 214), (252, 170, 60)]
SKIN = (226, 172, 136)
SHORTS = (40, 38, 52)
TYRE = (34, 30, 34)
RIM = (150, 152, 162)
SHOE = (232, 232, 236)

CENTER = (320.0, 195.0)
PX = (214.0, 131.0)      # centre line semi-axes on screen
HALF = 31.0              # half the asphalt width
LINE_THETA = 0.62        # BikeModel.LINE_THETA


def outline(im):
    """1px dark outline around everything opaque."""
    src = im.copy()
    s, d = src.load(), im.load()
    for y in range(im.height):
        for x in range(im.width):
            if s[x, y][3] > 200:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                u, v = x + dx, y + dy
                if 0 <= u < im.width and 0 <= v < im.height and s[u, v][3] > 200:
                    d[x, y] = OUT + (255,)
                    break
    return im


def rider_frame(row, lean, phase):
    im, d = new(FW, FH)
    j, h = JERSEYS[row], HELMETS[row]
    cy = 10
    shift = [0, -2, -3][lean]              # the body hangs towards the inside of the bend
    # wheels, from above (a fat dark tyre with the rim down the middle); leaning shows more of the rim
    for x0, x1 in ((2, 9), (18, 26)):
        d.rectangle([x0, cy - 1, x1, cy + 1 + (1 if lean == 2 else 0)], fill=TYRE)
        d.line([x0 + 1, cy, x1 - 1, cy], fill=RIM)
        if lean:
            d.line([x0 + 2, cy + 1, x1 - 2, cy + 1], fill=shade(RIM, 0.7))
    d.line([8, cy, 20, cy], fill=shade(j, 0.7))                        # frame
    d.line([20, cy - 4, 20, cy + 4], fill=(70, 66, 74))                 # handlebar
    d.point([(20, cy - 4), (20, cy + 4)], fill=TYRE)
    # legs: the two feet go round half a turn apart
    for side in (-1, 1):
        a = phase * math.pi / 2.0 + (0.0 if side < 0 else math.pi)
        fx = 13 + int(round(3.2 * math.cos(a)))
        kx = 14 + int(round(2.2 * math.cos(a)))
        high = math.sin(a) > 0.3
        ky = cy + shift + side * (4 if high else 3)
        fy = cy + side * 3
        d.line([(10, cy + shift + side * 2), (kx, ky)], fill=SHORTS, width=2)
        d.line([(kx, ky), (fx, fy)], fill=shade(SKIN, 1.0 if side < 0 else 0.85))
        d.point([(fx, fy), (fx + 1, fy)], fill=SHOE)
    # back and shoulders
    by = cy + shift
    d.ellipse([8, by - 3, 17, by + 3], fill=j)
    d.rectangle([14, by - 3, 17, by + 3], fill=j)
    d.line([10, by - 2, 16, by - 2], fill=shade(j, 1.25))
    d.line([10, by + 2, 16, by + 2], fill=shade(j, 0.72))
    d.line([9, by, 12, by], fill=(255, 250, 235))                       # race stripe
    d.rectangle([8, by - 1, 9, by + 1], fill=SHORTS)
    # arms reaching to the bars
    for side in (-1, 1):
        d.line([(16, by + side * 3), (18, by + side * 4)], fill=j)
        d.line([(18, by + side * 4), (20, cy + side * 4)], fill=shade(SKIN, 1.0 if side < 0 else 0.86))
    # helmet
    d.ellipse([17, by - 3, 23, by + 2], fill=h)
    d.line([18, by - 1, 22, by - 1], fill=shade(h, 0.7))
    d.line([19, by - 2, 20, by - 2], fill=shade(h, 1.2))
    d.point([(23, by), (23, by - 1)], fill=SKIN)
    return outline(im)


def crash_frame(row):
    im, d = new(FW, FH)
    j, h = JERSEYS[row], HELMETS[row]
    # bike flat on its side, wheels as rings
    for cx, cy in ((6, 6), (17, 5)):
        d.ellipse([cx - 4, cy - 4, cx + 4, cy + 4], outline=TYRE, width=2)
        d.point([cx, cy], fill=RIM)
    d.line([(6, 6), (12, 8), (17, 5)], fill=shade(j, 0.7), width=1)
    # rider sprawled beside it
    d.line([(8, 17), (12, 13)], fill=SHORTS, width=2)
    d.line([(6, 13), (12, 13)], fill=SKIN, width=1)
    d.ellipse([11, 10, 20, 16], fill=j)
    d.line([13, 11, 18, 11], fill=shade(j, 1.25))
    d.line([(18, 15), (23, 18)], fill=SKIN)
    d.ellipse([19, 9, 25, 15], fill=h)
    d.point([(21, 10), (22, 10)], fill=shade(h, 1.2))
    return outline(im)


def riders():
    sheet, _ = new(FW * 13, FH * 5)
    for row in range(5):
        for lean in range(3):
            for ph in range(4):
                sheet.paste(rider_frame(row, lean, ph), ((lean * 4 + ph) * FW, row * FH))
        sheet.paste(crash_frame(row), (12 * FW, row * FH))
    save(sheet, "bike_riders.png")


# ------------------------------------------------------------------ the course

def pt(theta, off=0.0):
    """Screen point `off` px outside the centre-line ellipse."""
    x, y = PX[0] * math.sin(theta), PX[1] * math.cos(theta)
    nx, ny = math.sin(theta) / PX[0], math.cos(theta) / PX[1]
    n = math.hypot(nx, ny)
    return (CENTER[0] + x + nx / n * off, CENTER[1] + y + ny / n * off)


def ring(off, n=360):
    return [pt(math.tau * i / n, off) for i in range(n)]


def inside(x, y, off):
    """Rough test: is (x, y) inside the oval grown by `off` px?"""
    return ((x - CENTER[0]) / (PX[0] + off)) ** 2 + ((y - CENTER[1]) / (PX[1] + off)) ** 2 < 1.0


def tree(d, rng, x, y, r):
    d.ellipse([x - r, y + r // 2, x + r + 3, y + r + 4], fill=(62, 106, 44))
    d.ellipse([x - r, y - r, x + r, y + r], fill=(52, 100, 46), outline=OUT)
    for _ in range(r * 3):
        a, q = rng.random() * math.tau, rng.random() ** 0.5 * (r - 3)
        u, v = x + math.cos(a) * q, y + math.sin(a) * q
        lit = (u - x) + (v - y) < 0
        c = (104, 156, 62) if lit else (40, 78, 38)
        d.ellipse([u - 2, v - 1, u + 2, v + 1], fill=c)


def person(d, rng, x, y):
    shirt = rng.choice([(206, 62, 54), (62, 112, 206), (238, 214, 120), (240, 238, 228), (70, 150, 90), (160, 90, 170), (220, 130, 60)])
    hair = rng.choice([(70, 44, 30), (36, 30, 30), (190, 150, 80), (130, 70, 40), (200, 196, 190)])
    d.rectangle([x - 3, y + 1, x + 3, y + 7], fill=shirt, outline=OUT)
    d.ellipse([x - 3, y - 4, x + 3, y + 2], fill=SKIN, outline=OUT)
    d.line([x - 2, y - 3, x + 2, y - 3], fill=hair)
    d.line([x - 2, y - 2, x + 1, y - 2], fill=hair)
    if rng.random() < 0.22:
        d.line([x + 3, y + 2, x + 5, y - 3], fill=SKIN)     # waving


def tent(d, x, y, w, col):
    d.ellipse([x - 2, y + 15, x + w + 6, y + 24], fill=(66, 110, 46))
    d.rectangle([x + 2, y + 9, x + w - 2, y + 19], fill=(214, 200, 170), outline=OUT)
    d.polygon([(x, y + 10), (x + w // 2, y - 2), (x + w, y + 10)], fill=col, outline=OUT)
    for k in range(0, w, 10):
        d.polygon([(x + k, y + 10), (x + k + 5, y + 10), (x + w // 2, y - 1)], fill=(244, 240, 226))
    d.line([(x, y + 10), (x + w // 2, y - 2), (x + w, y + 10)], fill=OUT)
    d.rectangle([x + w // 2 - 4, y + 12, x + w // 2 + 4, y + 19], fill=(70, 48, 34))


def tyres(d, x, y):
    for dx, dy in ((0, 0), (9, 0), (4, -5)):
        d.ellipse([x + dx, y + dy, x + dx + 8, y + dy + 7], fill=(40, 38, 42), outline=OUT)
        d.ellipse([x + dx + 3, y + dy + 2, x + dx + 5, y + dy + 4], fill=(96, 96, 104))


def track():
    rng = random.Random(77)
    im, d = new(640, 360)
    d.rectangle([0, 0, 640, 360], fill=(86, 142, 58))
    for _ in range(150):     # painterly patches
        x, y = rng.randrange(640), rng.randrange(360)
        rx, ry = rng.randrange(8, 34), rng.randrange(4, 14)
        c = rng.choice([(98, 154, 62), (76, 130, 52), (108, 160, 66), (122, 150, 64)])
        d.ellipse([x - rx, y - ry, x + rx, y + ry], fill=c)
    # run-off dust, kerb bed and asphalt
    d.polygon(ring(HALF + 9), fill=(150, 126, 82))
    d.polygon(ring(HALF + 5), fill=OUT)
    d.polygon(ring(HALF + 4), fill=(222, 218, 206))
    d.polygon(ring(HALF), fill=(98, 96, 104))
    d.polygon(ring(-HALF), fill=(222, 218, 206))
    d.polygon(ring(-HALF - 4), fill=OUT)
    # infield lawn with mown stripes
    lawn, _ld = new(640, 360)
    _ld.rectangle([0, 0, 640, 360], fill=(94, 154, 62))
    for i in range(0, 640, 36):
        _ld.rectangle([i, 0, i + 17, 360], fill=(104, 166, 66))
    mask, md = new(640, 360)
    md.polygon(ring(-HALF - 5), fill=(255, 255, 255, 255))
    im.paste(lawn, (0, 0), mask)
    # asphalt grain and the darker racing line
    for _ in range(5200):
        th, off = rng.random() * math.tau, rng.uniform(-HALF + 1, HALF - 1)
        x, y = pt(th, off)
        d.point([int(x), int(y)], fill=rng.choice([(110, 108, 116), (86, 84, 92), (120, 116, 118)]))
    for off in (-19, -16, -13):
        for i in range(0, 720, 1):
            if rng.random() < 0.45:
                x, y = pt(math.tau * i / 720, off + rng.uniform(-1.5, 1.5))
                d.point([int(x), int(y)], fill=(80, 78, 86))
    for off in (-8.5, 8.5):     # faint lane dashes
        for i in range(0, 120, 2):
            d.line([pt(math.tau * i / 120, off), pt(math.tau * (i + 0.7) / 120, off)], fill=(150, 148, 152))
    # red and white rumble strips round both ends (and the inside of the whole lap)
    n = 150
    for i in range(n):
        a, b = math.tau * i / n, math.tau * (i + 1) / n
        red = (204, 62, 50) if i % 2 == 0 else (238, 234, 222)
        d.polygon([pt(a, -HALF - 4), pt(b, -HALF - 4), pt(b, -HALF), pt(a, -HALF)], fill=red)
        if abs(math.sin((a + b) / 2)) > 0.72:
            d.polygon([pt(a, HALF), pt(b, HALF), pt(b, HALF + 4), pt(a, HALF + 4)], fill=red)
    # start / finish: chequers across the road
    step = 4.0 / math.hypot(PX[0] * math.cos(LINE_THETA), PX[1] * math.sin(LINE_THETA))
    for col in range(2):
        for k in range(int(2 * HALF // 4)):
            o0 = -HALF + 1 + k * 4
            o1 = min(o0 + 4, HALF)
            a, b = LINE_THETA + (col - 1) * step, LINE_THETA + col * step
            c = (248, 248, 244) if (k + col) % 2 == 0 else (22, 20, 22)
            d.polygon([pt(a, o0), pt(b, o0), pt(b, o1), pt(a, o1)], fill=c)
    for off in (-HALF - 8, HALF + 7):     # flag posts at the line
        x, y = pt(LINE_THETA, off)
        d.line([x, y, x, y - 14], fill=OUT, width=3)
        d.line([x, y, x, y - 13], fill=(226, 222, 210))
        d.polygon([(x + 1, y - 14), (x + 12, y - 11), (x + 1, y - 7)], fill=(244, 196, 48), outline=OUT)
    # --- outside: crowds behind barriers in the bottom corners, trees and tents elsewhere
    for side in (0, 1):
        for row, y in enumerate(range(305, 353, 10)):
            for x in range(6, 176, 9):
                u = x + (4 if row % 2 else 0) + rng.randrange(-1, 2)
                xx = u if side == 0 else 640 - u
                if not inside(xx, y - 4, HALF + 22) and rng.random() < 0.82:
                    person(d, rng, xx, y + rng.randrange(-1, 2))
    barrier = [pt(math.tau * i / 360, HALF + 14) for i in range(360)]
    for i, (x, y) in enumerate(barrier):
        if y > 250 and (x < 235 or x > 405):
            d.line([barrier[i - 1], (x, y)], fill=(214, 216, 224))
            if i % 4 == 0:
                d.line([x, y, x, y + 5], fill=OUT)
    for x, y, r in ((16, 104, 13), (38, 128, 10), (13, 152, 11), (625, 112, 12), (603, 134, 10), (628, 158, 12),
                    (22, 258, 12), (620, 262, 13), (122, 46, 11), (146, 38, 9), (505, 40, 10), (527, 48, 12), (14, 230, 9), (627, 232, 9)):
        if not inside(x, y, HALF + 14):
            tree(d, rng, x, y, r)
    tent(d, 34, 270, 34, (206, 62, 54))
    tent(d, 574, 270, 34, (62, 112, 206))
    # --- infield dressing, kept to the rim so the HUD stays clear
    tent(d, 190, 176, 30, (70, 160, 82))
    tent(d, 424, 176, 30, (244, 160, 52))
    tyres(d, 192, 226)
    tyres(d, 434, 226)
    for x, y in ((226, 144), (414, 144)):
        tree(d, rng, x, y, 9)
    for _ in range(260):     # tufts and daisies
        x, y = rng.randrange(640), rng.randrange(28, 360)
        if inside(x, y, -HALF - 10) or not inside(x, y, HALF + 16):
            d.line([x, y, x, y - 2], fill=(62, 112, 44))
            d.point([x + 2, y - 1], fill=(132, 182, 74))
            if rng.random() < 0.08:
                d.point([x + 1, y - 3], fill=(250, 246, 210))
    save(im, "bike_track.png")


def side_bike(d, x, y, col):
    """A little parked road bike seen from the side, wheels resting on row y."""
    for wx in (x + 6, x + 22):
        d.ellipse([wx - 6, y - 12, wx + 6, y], outline=OUT, width=3)
        d.ellipse([wx - 5, y - 11, wx + 5, y - 1], outline=(176, 178, 188))
        d.point([wx, y - 6], fill=(220, 220, 226))
    frame = [((x + 6, y - 6), (x + 13, y - 6)), ((x + 13, y - 6), (x + 11, y - 15)), ((x + 11, y - 14), (x + 19, y - 15)),
             ((x + 13, y - 6), (x + 19, y - 15)), ((x + 6, y - 6), (x + 11, y - 14)), ((x + 19, y - 15), (x + 22, y - 6))]
    for a, b in frame:
        d.line([a, b], fill=OUT, width=3)
    for a, b in frame:
        d.line([a, b], fill=col)
    d.line([x + 8, y - 17, x + 13, y - 17], fill=OUT, width=2)        # saddle
    d.line([(x + 19, y - 15), (x + 18, y - 19), (x + 22, y - 19)], fill=OUT, width=2)


def rack():
    im, d = new(48, 34)
    d.ellipse([2, 28, 46, 33], fill=(42, 26, 16, 70))
    for x in (2, 44):                                                  # posts and back rail
        d.rectangle([x, 15, x + 2, 29], fill=WOOD[1], outline=OUT)
    d.rectangle([2, 18, 46, 20], fill=WOOD[2], outline=OUT)
    side_bike(d, 18, 26, JERSEYS[2])
    side_bike(d, 2, 31, JERSEYS[1])
    d.rectangle([2, 30, 46, 31], fill=WOOD[3])                          # wheel trough
    d.rectangle([37, 3, 47, 11], fill=(244, 196, 48), outline=OUT)      # pennant sign
    d.line([42, 12, 42, 22], fill=OUT, width=2)
    d.ellipse([39, 5, 42, 8], outline=OUT)
    d.ellipse([42, 5, 45, 8], outline=OUT)
    save(im, "bike_rack.png")


def main():
    riders()
    track()
    rack()


if __name__ == "__main__":
    main()
