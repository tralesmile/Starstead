#!/usr/bin/env python3
"""Cave sprites (original, CC0): floor/wall tiles, ore chunks, torch, bat, cave mouth, furnace.
Painterly pixel art, 1px dark outline (42,26,16), light from top-left. Deterministic."""
import os
import math
import random
from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SPR = os.path.join(ROOT, "assets", "sprites")
OUT = (30, 22, 22)
ROCK = [(46, 42, 44), (66, 60, 60), (92, 84, 80), (122, 112, 104), (150, 138, 126)]
IRON = [(52, 48, 52), (84, 80, 86), (122, 118, 124), (160, 156, 160)]
WOOD = [(86, 54, 30), (116, 74, 42), (150, 100, 56), (180, 128, 74)]


def shade(c, k):
    return tuple(max(0, min(255, int(v * k))) for v in c[:3]) + tuple(c[3:])


def mix(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def new(w, h):
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    return im, ImageDraw.Draw(im)


def save(im, name):
    im.save(os.path.join(SPR, name))
    print("wrote", name, im.size)


class Noise:
    """Value noise on a wrapping grid (tileable in x and y by default)."""
    def __init__(self, seed, cell, w=32, h=32, wrap_y=True):
        r = random.Random(seed)
        self.cell, self.w, self.h = cell, w, h
        self.gw, self.gh = w // cell, (h // cell) if wrap_y else h // cell + 2
        self.g = [[r.random() for _ in range(self.gw)] for _ in range(self.gh)]

    def at(self, x, y):
        fx, fy = x / self.cell, y / self.cell
        x0, y0 = int(math.floor(fx)), int(math.floor(fy))
        tx, ty = fx - x0, fy - y0
        tx, ty = tx * tx * (3 - 2 * tx), ty * ty * (3 - 2 * ty)
        g = self.g
        def v(i, j):
            return g[j % self.gh][i % self.gw]
        a = v(x0, y0) * (1 - tx) + v(x0 + 1, y0) * tx
        b = v(x0, y0 + 1) * (1 - tx) + v(x0 + 1, y0 + 1) * tx
        return a * (1 - ty) + b * ty


def rock_pixels(im, box, seed, base, hi_k=1.25, lo_k=0.75, sp=0.05, light=True):
    """Fill a rect with tileable mottled stone."""
    x0, y0, x1, y1 = box
    n1, n2 = Noise(seed, 16), Noise(seed + 1, 8)
    r = random.Random(seed + 2)
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            v = n1.at(x, y) * 0.6 + n2.at(x, y) * 0.4
            k = lo_k + (hi_k - lo_k) * v
            c = shade(base, k)
            if r.random() < sp:
                c = shade(c, r.choice((0.78, 1.22)))
            im.putpixel((x, y), c + (255,))


# ---------------------------------------------------------------- tiles
def cave_floor():
    im = Image.new("RGBA", (32, 32))
    rock_pixels(im, (0, 0, 31, 31), 11, (84, 76, 70), 1.18, 0.82, 0.07)
    r = random.Random(12)
    for _ in range(14):  # pebbles/speckles (wrap so tile stays seamless)
        x, y = r.randrange(32), r.randrange(32)
        c = r.choice(((124, 114, 104), (52, 46, 46), (104, 94, 86)))
        im.putpixel((x, y), c + (255,))
        if r.random() < 0.4:
            im.putpixel(((x + 1) % 32, y), shade(c, 0.85) + (255,))
    for _ in range(3):  # faint hairline cracks
        x, y = r.randrange(4, 24), r.randrange(4, 28)
        for i in range(r.randrange(4, 8)):
            im.putpixel(((x + i) % 32, (y + (i // 3)) % 32), (58, 52, 50, 255))
    save(im, "cave_floor.png")


def cave_wall_top():
    im = Image.new("RGBA", (32, 32))
    rock_pixels(im, (0, 0, 31, 31), 21, (50, 46, 50), 1.25, 0.7, 0.08)
    r = random.Random(22)
    for _ in range(10):
        x, y = r.randrange(32), r.randrange(32)
        im.putpixel((x, y), (74, 68, 70, 255))
        im.putpixel(((x + 1) % 32, y), (36, 32, 36, 255))
    save(im, "cave_wall_top.png")


def cave_wall():
    im = Image.new("RGBA", (32, 32))
    # top face (lighter), rows 0..12
    rock_pixels(im, (0, 0, 31, 12), 31, (112, 102, 94), 1.2, 0.8, 0.06)
    # front face (darker), rows 13..31
    rock_pixels(im, (0, 13, 31, 31), 33, (84, 76, 74), 1.2, 0.72, 0.06)
    d = ImageDraw.Draw(im)
    d.line([0, 12, 31, 12], fill=(36, 30, 32, 255))       # lip edge
    d.line([0, 13, 31, 13], fill=(40, 34, 36, 255))
    d.line([0, 11, 31, 11], fill=(150, 138, 126, 255))     # bevel highlight
    r = random.Random(34)
    # highlights on front face under lip fade
    for x in range(32):
        if r.random() < 0.5:
            im.putpixel((x, 14), (84, 76, 74, 255))
    # vertical cracks on the front face (kept away from the tile edges)
    for cx, cy, ln in ((7, 15, 11), (19, 16, 9), (27, 14, 6)):
        x = cx
        for i in range(ln):
            y = cy + i
            im.putpixel((x, y), (28, 22, 26, 255))
            if i % 3 == 2:
                x += r.choice((-1, 1))
            if i % 2 == 0:
                im.putpixel((x + 1, y), (84, 76, 76, 255))
    # base shade
    d.line([0, 31, 31, 31], fill=(34, 28, 30, 255))
    d.line([0, 30, 31, 30], fill=(46, 40, 42, 255))
    # small cracks on top face
    for cx, cy in ((12, 5), (25, 8)):
        for i in range(4):
            im.putpixel((cx + i, cy + (i % 2)), (84, 76, 70, 255))
    save(im, "cave_wall.png")


# ---------------------------------------------------------------- ores
def outline_pass(im):
    px = im.load()
    w, h = im.size
    marks = []
    for y in range(h):
        for x in range(w):
            if px[x, y][3] == 0:
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < w and 0 <= ny < h and px[nx, ny][3] == 255:
                        marks.append((x, y))
                        break
    for p in marks:
        px[p] = OUT + (255,)


def chunk(name, seed, rock, specks, glint):
    im = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.ellipse([4, 23, 28, 30], fill=(20, 14, 16, 90))          # contact shadow on floor
    body = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    bp = body.load()
    n = Noise(seed, 8)
    r = random.Random(seed)
    cx, cy = 16, 19
    for y in range(32):
        for x in range(32):
            # lumpy rounded rock: ellipse with noisy radius
            dx, dy = (x - cx) / 11.0, (y - cy) / 9.0
            rad = math.sqrt(dx * dx + dy * dy)
            if rad <= 0.85 + (n.at(x, y) - 0.5) * 0.35 and y <= 27:
                lx = (x - cx) + (y - cy)   # light from top-left
                k = 1.18 - 0.014 * lx - (0.25 if y > 23 else 0)
                c = shade(rock, k * (0.92 + 0.16 * n.at(x * 2 % 32, y * 2 % 32)))
                bp[x, y] = c + (255,)
    im.alpha_composite(body)
    px = im.load()
    for _ in range(18):  # grain
        x, y = r.randrange(6, 27), r.randrange(11, 27)
        if px[x, y][3] == 255:
            px[x, y] = shade(px[x, y][:3], r.choice((0.8, 1.15))) + (255,)
    # ore veins / clusters
    for (x, y) in specks:
        for (ox, oy, k) in ((0, 0, 1.0), (1, 0, 0.9), (0, 1, 0.78), (-1, 0, 1.12), (0, -1, 1.2)):
            xx, yy = x + ox, y + oy
            if 0 <= xx < 32 and 0 <= yy < 32 and px[xx, yy][3] == 255:
                px[xx, yy] = specks[(x, y)][0 if (ox, oy) in ((0, 0), (1, 0), (-1, 0), (0, -1)) else 1] + (255,)
    for (x, y) in glint:
        if px[x, y][3] == 255:
            px[x, y] = (255, 255, 240, 255)
    outline_pass(im)
    save(im, name)


def cave_ores():
    cu = (150, 100, 70)
    cu_a, cu_b = (226, 124, 56), (166, 78, 36)
    gr_a, gr_b = (96, 188, 142), (52, 120, 96)
    sp = {}
    for (x, y), t in (((10, 15), 0), ((14, 19), 0), ((19, 14), 1), ((21, 20), 0), ((12, 23), 1),
                      ((17, 24), 0), ((7, 20), 1), ((23, 17), 0)):
        sp[(x, y)] = (cu_a, cu_b) if t == 0 else (gr_a, gr_b)
    chunk("cave_ore_copper.png", 41, (112, 98, 90), sp, [(10, 14), (19, 13), (21, 19)])
    fe_a, fe_b = (214, 172, 140), (150, 108, 84)
    sp = {}
    for (x, y) in ((9, 16), (13, 20), (18, 15), (22, 21), (16, 24), (11, 24), (20, 18)):
        sp[(x, y)] = (fe_a, fe_b)
    chunk("cave_ore_iron.png", 43, (108, 100, 98), sp, [(9, 15), (18, 14)])
    co_a, co_b = (40, 38, 46), (18, 16, 22)
    sp = {}
    for (x, y) in ((10, 15), (14, 19), (19, 14), (22, 20), (12, 23), (18, 24), (8, 20), (16, 16)):
        sp[(x, y)] = (co_a, co_b)
    chunk("cave_ore_coal.png", 47, (104, 96, 92), sp, [])
    # coal sheen
    im = Image.open(os.path.join(SPR, "cave_ore_coal.png"))
    for (x, y) in ((10, 14), (14, 18), (19, 13), (22, 19)):
        if im.getpixel((x, y))[3] == 255:
            im.putpixel((x, y), (96, 100, 128, 255))
    im.save(os.path.join(SPR, "cave_ore_coal.png"))


# ---------------------------------------------------------------- torch
def cave_torch():
    sheet = Image.new("RGBA", (128, 48), (0, 0, 0, 0))
    flames = [
        (0, 0, 0), (1, 1, -1), (-1, 0, 1), (0, 1, 0),
    ]
    for f in range(4):
        im, d = new(32, 48)
        ox, h, tw = flames[f]
        # warm glow halo
        halo = Image.new("RGBA", (32, 48), (0, 0, 0, 0))
        hd = ImageDraw.Draw(halo)
        hd.ellipse([2, 4, 29, 31], fill=(255, 150, 50, 30))
        hd.ellipse([7, 9, 24, 26], fill=(255, 170, 60, 44))
        im.alpha_composite(halo)
        d = ImageDraw.Draw(im)
        # iron bracket + wall plate
        d.rectangle([12, 38, 19, 43], fill=IRON[1], outline=OUT)
        d.line([13, 39, 18, 39], fill=IRON[3])
        d.rectangle([13, 44, 18, 46], fill=IRON[0], outline=OUT)
        # wooden stick
        d.rectangle([14, 22, 17, 41], fill=WOOD[1], outline=OUT)
        d.line([15, 23, 15, 40], fill=WOOD[3])
        d.line([16, 24, 16, 40], fill=WOOD[1])
        # iron cup + wrapped head
        d.rectangle([12, 19, 19, 23], fill=IRON[1], outline=OUT)
        d.line([13, 20, 18, 20], fill=IRON[3])
        d.rectangle([13, 17, 18, 19], fill=(60, 40, 28), outline=OUT)
        # flame (layers, wobble per frame)
        cx = 16 + ox
        top = 5 - h
        d.polygon([(cx - 5, 18), (cx - 4, 12), (cx + tw, top + 2), (cx + 4, 12), (cx + 5, 18)],
                  fill=(230, 90, 30), outline=OUT)
        d.polygon([(cx - 4, 18), (cx - 3, 13), (cx + tw, top + 4), (cx + 3, 13), (cx + 4, 18)],
                  fill=(250, 140, 40))
        d.polygon([(cx - 3, 18), (cx - 2, 14), (cx + tw // 2, top + 7), (cx + 2, 14), (cx + 3, 18)],
                  fill=(255, 200, 70))
        d.polygon([(cx - 1, 18), (cx - 1, 15), (cx + tw // 2, top + 11), (cx + 1, 15), (cx + 1, 18)],
                  fill=(255, 244, 170))
        # sparks
        for (sx, sy) in (((cx + 5, 7 - h), (cx - 6, 9)), ((cx - 5, 5), (cx + 6, 10)),
                         ((cx + 4, 3), (cx - 5, 8)), ((cx - 4, 6), (cx + 5, 5)))[f]:
            d.point([sx, sy], fill=(255, 210, 90, 255))
        sheet.paste(im, (f * 32, 0))
    save(sheet, "cave_torch.png")


# ---------------------------------------------------------------- bat
def cave_bat():
    sheet = Image.new("RGBA", (128, 32), (0, 0, 0, 0))
    BODY = [(34, 28, 44), (58, 48, 72), (88, 74, 104)]
    # wing tip offset per frame: up, mid, down, mid
    tips = [(-9, -11), (-12, -3), (-9, 7), (-12, -2)]
    for f in range(4):
        im, d = new(32, 32)
        cx, cy = 16, 16
        ty = tips[f][1]
        for side in (-1, 1):
            tx = cx + side * (abs(tips[f][0]) + 3)
            mx = cx + side * 8
            my = cy + ty // 2 - 2
            pts = [(cx + side * 3, cy - 2), (mx, my - 3), (tx, cy + ty),
                   (tx - side * 4, cy + ty + 5), (cx + side * 11, cy + ty // 2 + 4),
                   (cx + side * 7, cy + 4 + max(0, ty // 3)), (cx + side * 3, cy + 4)]
            d.polygon(pts, fill=BODY[1], outline=OUT)
            # wing membrane shading and finger bones
            d.line([cx + side * 3, cy - 1, tx, cy + ty], fill=BODY[2])
            d.line([cx + side * 4, cy + 1, tx - side * 4, cy + ty + 4], fill=BODY[0])
        # body
        d.ellipse([cx - 5, cy - 5, cx + 5, cy + 7], fill=BODY[0], outline=OUT)
        d.ellipse([cx - 3, cy - 3, cx + 2, cy + 3], fill=BODY[1])
        d.point([cx - 2, cy - 3], fill=BODY[2])
        # ears
        d.polygon([(cx - 5, cy - 4), (cx - 5, cy - 9), (cx - 2, cy - 5)], fill=BODY[0], outline=OUT)
        d.polygon([(cx + 5, cy - 4), (cx + 5, cy - 9), (cx + 2, cy - 5)], fill=BODY[0], outline=OUT)
        d.point([cx - 4, cy - 6], fill=(150, 90, 110))
        d.point([cx + 4, cy - 6], fill=(150, 90, 110))
        # eyes + fangs
        for ex in (cx - 3, cx + 1):
            d.rectangle([ex, cy - 2, ex + 1, cy], fill=(255, 250, 230))
            d.point([ex + (1 if ex < cx else 0), cy - 1], fill=(20, 10, 20))
            d.point([ex, cy - 2], fill=(255, 255, 255))
        d.point([cx - 1, cy + 3], fill=(255, 255, 255))
        d.point([cx + 1, cy + 3], fill=(255, 255, 255))
        d.line([cx - 1, cy + 2, cx + 1, cy + 2], fill=(150, 60, 80))
        sheet.paste(im, (f * 32, 0))
    save(sheet, "cave_bat.png")


# ---------------------------------------------------------------- mouth
def cave_mouth():
    W, H = 96, 80
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    # contact shadow
    d.ellipse([2, 70, 93, 79], fill=(20, 14, 16, 80))
    # hillside mound: noisy dome silhouette
    n = Noise(51, 8, 96, 80, wrap_y=False)
    mound = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    mp = mound.load()
    for y in range(H - 3):
        for x in range(W):
            dx, dy = (x - 48) / 47.0, (y - 78) / 76.0
            edge = math.sqrt(dx * dx + dy * dy)
            if edge <= 1.0 + (n.at(x, y) - 0.5) * 0.14 and y >= 3:
                lx = (x - 20) * 0.5 + y * 0.6
                k = 1.25 - 0.011 * lx
                v = n.at(x * 2 % 96, y * 2 % 80)
                c = shade(ROCK[2], k * (0.82 + 0.3 * v))
                # moss/grass cap on the very top
                if y < 12 + int((n.at(x, 3) - 0.5) * 8):
                    c = shade((96, 128, 62), 0.85 + 0.35 * v)
                mp[x, y] = c + (255,)
    im.alpha_composite(mound)
    d = ImageDraw.Draw(im)
    r = random.Random(52)
    # rock strata and stones
    for _ in range(26):
        x, y = r.randrange(6, 90), r.randrange(18, 70)
        w = r.randrange(4, 9)
        if im.getpixel((x, y))[3] == 255 and im.getpixel((min(95, x + w), y))[3] == 255:
            d.line([x, y, x + w, y], fill=shade(ROCK[1], 0.9))
            d.line([x, y - 1, x + w - 2, y - 1], fill=shade(ROCK[3], 1.05))
    # cave opening (arched)
    ax0, ax1, ay0, ay1 = 26, 69, 26, 75
    arch = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ad = ImageDraw.Draw(arch)
    ad.rectangle([ax0, 44, ax1, ay1], fill=(255, 255, 255, 255))
    ad.ellipse([ax0, ay0, ax1, 62], fill=(255, 255, 255, 255))
    mask = arch.split()[3]
    dark = Image.new("RGBA", (W, H), (10, 8, 14, 255))
    # depth gradient inside the opening
    dp = dark.load()
    for y in range(H):
        for x in range(W):
            t = max(0.0, 1 - abs(x - 48) / 24.0) * 0.5 + max(0.0, (y - 30) / 45.0) * 0.5
            dp[x, y] = mix((8, 6, 12), (34, 28, 36), t * 0.45) + (255,)
    im.paste(dark, (0, 0), mask)
    d = ImageDraw.Draw(im)
    # stone arch voussoirs
    for i in range(11):
        a0 = math.pi + i * math.pi / 11
        a1 = a0 + math.pi / 11
        cxa, cya, rx, ry = 48, 55, 22, 29
        p0 = (cxa + (rx + 1) * math.cos(a0), cya + (ry + 1) * math.sin(a0))
        p1 = (cxa + (rx + 1) * math.cos(a1), cya + (ry + 1) * math.sin(a1))
        q1 = (cxa + (rx + 6) * math.cos(a1), cya + (ry + 6) * math.sin(a1))
        q0 = (cxa + (rx + 6) * math.cos(a0), cya + (ry + 6) * math.sin(a0))
        col = shade(ROCK[3], 0.88 + 0.12 * (i % 3) - 0.015 * i)
        d.polygon([p0, p1, q1, q0], fill=col, outline=OUT)
        d.line([q0, p0], fill=shade(col, 1.2))
    # jamb stones (left/right)
    for side, x0 in ((-1, ax0 - 6), (1, ax1 + 1)):
        for j, y in enumerate(range(54, ay1 - 2, 8)):
            col = shade(ROCK[3], 0.9 + 0.1 * (j % 2))
            d.rectangle([x0, y, x0 + 5, y + 7], fill=col, outline=OUT)
            d.line([x0 + 1, y + 1, x0 + 4, y + 1], fill=shade(col, 1.2))
    # threshold step
    d.rectangle([ax0 - 8, 74, ax1 + 8, 77], fill=ROCK[3], outline=OUT)
    d.line([ax0 - 7, 75, ax1 + 7, 75], fill=ROCK[4])
    # wooden support beams (frame inside opening)
    for bx in (ax0 + 2, ax1 - 5):
        d.rectangle([bx, 42, bx + 3, 74], fill=WOOD[1], outline=OUT)
        d.line([bx + 1, 43, bx + 1, 73], fill=WOOD[3])
        d.line([bx + 3, 43, bx + 3, 73], fill=WOOD[0])
    d.rectangle([ax0 + 1, 38, ax1 - 1, 43], fill=WOOD[2], outline=OUT)   # lintel
    d.line([ax0 + 2, 39, ax1 - 2, 39], fill=WOOD[3])
    d.line([ax0 + 2, 42, ax1 - 2, 42], fill=WOOD[0])
    for nx in (ax0 + 5, 48, ax1 - 6):
        d.point([nx, 40], fill=IRON[3])
    # braces
    d.line([ax0 + 6, 44, ax0 + 12, 38], fill=OUT)
    d.line([ax1 - 6, 44, ax1 - 12, 38], fill=OUT)
    # darker interior shadow beneath lintel
    for y in range(44, 48):
        for x in range(ax0 + 6, ax1 - 5):
            c = im.getpixel((x, y))
            if c[3] == 255 and c[0] < 60:
                im.putpixel((x, y), (6, 4, 10, 255))
    # outline whole silhouette
    outline_pass(im)
    # lantern glow hint deeper inside + a couple of eyes-in-the-dark
    d = ImageDraw.Draw(im)
    d.point([40, 62], fill=(210, 200, 120, 255))
    d.point([41, 62], fill=(210, 200, 120, 255))
    d.point([54, 64], fill=(210, 200, 120, 255))
    d.point([55, 64], fill=(210, 200, 120, 255))
    # grass tufts at base
    for x in (4, 12, 80, 88, 20, 74):
        d.line([x, 76, x, 73], fill=(76, 120, 52, 255))
        d.line([x + 1, 76, x + 2, 74], fill=(104, 150, 66, 255))
    save(im, "cave_mouth.png")


# ---------------------------------------------------------------- furnace
def int_furnace():
    im, d = new(32, 48)
    ST = [(70, 64, 66), (104, 96, 92), (140, 130, 120), (176, 164, 148)]
    # chimney
    d.rectangle([20, 0, 26, 22], fill=ST[1], outline=OUT)
    d.line([21, 1, 21, 21], fill=ST[3])
    d.line([25, 1, 25, 21], fill=ST[0])
    d.rectangle([19, 0, 27, 3], fill=ST[2], outline=OUT)
    for y in (7, 13, 19):
        d.line([21, y, 25, y], fill=ST[0])
    d.ellipse([3, 45, 29, 47], fill=(42, 26, 16, 70))
    # body: stacked stone blocks
    d.rectangle([2, 16, 29, 45], fill=ST[1], outline=OUT)
    r = random.Random(61)
    for row, y in enumerate(range(17, 45, 6)):
        off = 5 if row % 2 else 0
        for x in range(2 - off, 30, 10):
            a, b = max(3, x + 1), min(28, x + 9)
            if a >= b:
                continue
            c = shade(ST[2], r.uniform(0.88, 1.08))
            e = min(44, y + 4)
            d.rectangle([a, y, b, e], fill=c)
            d.line([a, y, b, y], fill=shade(c, 1.15))
            d.line([a, e, b, e], fill=shade(c, 0.78))
    # domed top ledge
    d.rectangle([1, 14, 30, 19], fill=ST[2], outline=OUT)
    d.line([2, 15, 29, 15], fill=ST[3])
    d.line([2, 18, 29, 18], fill=ST[0])
    # fire opening (arched) with glow
    d.rectangle([7, 29, 24, 43], fill=(14, 10, 12), outline=OUT)
    d.ellipse([7, 24, 24, 34], fill=(14, 10, 12), outline=OUT)
    d.rectangle([8, 31, 23, 43], fill=(14, 10, 12))
    d.rectangle([9, 33, 22, 42], fill=(190, 70, 24))
    d.ellipse([9, 29, 22, 36], fill=(190, 70, 24))
    d.rectangle([10, 36, 21, 42], fill=(236, 120, 36))
    d.polygon([(11, 42), (12, 36), (14, 33), (15, 37), (17, 31), (19, 36), (21, 42)], fill=(255, 176, 56))
    d.polygon([(13, 42), (14, 38), (16, 35), (18, 38), (19, 42)], fill=(255, 230, 120))
    d.line([15, 42, 17, 40], fill=(255, 250, 200))
    # embers + logs
    d.line([9, 43, 22, 43], fill=(86, 46, 28))
    d.line([11, 42, 20, 42], fill=(120, 64, 34))
    # iron grate bar and door lip
    d.line([7, 28, 24, 28], fill=IRON[1])
    d.point([8, 28], fill=IRON[3])
    # soot above opening
    for x in range(10, 22):
        if r.random() < 0.6:
            d.point([x, 23], fill=(46, 40, 42))
    # glow spill on stone
    for (x, y) in ((5, 41), (26, 41), (6, 38), (25, 38)):
        d.point([x, y], fill=(176, 112, 70))
    save(im, "int_furnace.png")


def main():
    os.makedirs(SPR, exist_ok=True)
    for fn in (cave_floor, cave_wall, cave_wall_top, cave_ores, cave_torch, cave_bat,
               cave_mouth, int_furnace):
        fn()


if __name__ == "__main__":
    main()
