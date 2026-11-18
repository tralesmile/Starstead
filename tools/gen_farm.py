#!/usr/bin/env python3
"""Farm sprites for Starstead: tilled-soil autotiles, crops, weeds (original, CC0).

Run from repo root:  python3 tools/gen_farm.py
Writes assets/sprites/soil_dry.png, soil_wet.png (512x32, frame = N1|E2|S4|W8 mask),
crop_turnip.png, crop_generic.png (160x32, 5 stages), weed.png (32x32).
Deterministic (fixed seed). Soil interiors are periodic in x and y (period 32 / 8)
so neighbouring tiles join seamlessly; dark rounded edges only appear on sides
that have no soil neighbour.
"""
import math, os, random
import numpy as np
from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "sprites")
OUTLINE = (42, 26, 16)
SEED = 1337


def hx(s):
    s = s.lstrip("#"); return tuple(int(s[i:i + 2], 16) for i in (0, 2, 4))


# ------------------------------------------------------------------ soil
DRY = dict(base=hx("#6e4527"), crest=hx("#8f5d33"), crest2=hx("#7a4d2b"), furrow=hx("#4a2d19"),
           deep=hx("#35200f"), edge1=hx("#35200f"), edge2=hx("#553520"), clod=hx("#a67444"), speck=hx("#3f2614"))
WET = dict(base=hx("#46291a"), crest=hx("#5c3822"), crest2=hx("#4f2f1d"), furrow=hx("#2c190f"),
           deep=hx("#1f110a"), edge1=hx("#1f110a"), edge2=hx("#341e12"), clod=hx("#6a4429"), speck=hx("#2a170d"))


def tile_noise(seed):
    r = random.Random(seed)
    return [[r.random() for _ in range(32)] for _ in range(32)]


def soil_tile(mask, P, wet, noise, puddles):
    n, e, s, w = bool(mask & 1), bool(mask & 2), bool(mask & 4), bool(mask & 8)
    img = np.zeros((32, 32, 4), np.uint8)
    # rounded-rect bounds; sides with a soil neighbour extend far outside the tile
    x0 = -100 if w else 0.0
    x1 = 132 if e else 32.0
    y0 = -100 if n else 0.0
    y1 = 132 if s else 32.0
    R = 6.0
    for y in range(32):
        for x in range(32):
            px, py = x + 0.5, y + 0.5
            # signed distance to rounded rect (negative inside)
            cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
            hw, hh = (x1 - x0) / 2, (y1 - y0) / 2
            qx, qy = abs(px - cx) - (hw - R), abs(py - cy) - (hh - R)
            d = math.hypot(max(qx, 0), max(qy, 0)) + min(max(qx, qy), 0) - R
            if d > 0:
                continue
            depth = -d  # distance inside the edge
            # furrow row profile (period 8), with a gentle x-periodic wobble
            wob = 0.7 * math.sin(2 * math.pi * x / 32.0 + 0.7)
            ry = (y + int(round(wob))) % 8
            col = [P["crest"], P["crest"], P["crest2"], P["base"], P["furrow"], P["deep"], P["furrow"], P["base"]][ry]
            if ry == 0 and not wet and noise[y][x] > 0.55:
                col = tuple(min(255, int(c * 1.14)) for c in col)  # sunlit top of each ridge
            if ry in (3, 7) and noise[y][x] > 0.82:
                col = P["clod"]
            if ry in (0, 1) and noise[y][x] < 0.12:
                col = P["crest2"]
            if ry in (4, 5, 6) and noise[y][x] > 0.9:
                col = P["speck"]
            if wet:
                # cool sheen on ridge crests, wet shine on the top row
                if ry == 0:
                    col = tuple(int(c * 0.7 + b * 0.3) for c, b in zip(col, (110, 140, 175)))
                if (x, y) in puddles:
                    col = (120, 160, 190) if ry != 5 else (78, 108, 140)
            # dark rounded edge band
            if depth < 1.0:
                col = OUTLINE
            elif depth < 2.2:
                col = P["edge1"]
            elif depth < 3.4:
                col = tuple((a + b) // 2 for a, b in zip(col, P["edge2"]))
            img[y, x] = (*col, 255)
    return img


def make_soil(P, wet, name):
    noise = tile_noise(SEED + (7 if wet else 0))
    r = random.Random(SEED + 99)
    puddles = set()
    if wet:
        # tiny puddle highlights inside furrow rows (periodic positions, wrap-safe)
        for row in (5, 13, 21, 29):
            for _ in range(1):
                px = r.randrange(0, 30)
                for k in range(r.choice((2, 3))):
                    puddles.add(((px + k) % 32, row))
    strip = Image.new("RGBA", (512, 32))
    for m in range(16):
        strip.paste(Image.fromarray(soil_tile(m, P, wet, noise, puddles), "RGBA"), (m * 32, 0))
    strip.save(os.path.join(OUT, name))
    return strip


# ------------------------------------------------------------------ crops
def outline(img):
    a = np.array(img)
    al = a[:, :, 3] > 0
    out = a.copy()
    h, w = al.shape
    for y in range(h):
        for x in range(w):
            if not al[y, x]:
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < w and 0 <= ny < h and al[ny, nx]:
                        out[y, x] = (*OUTLINE, 255); break
    return Image.fromarray(out, "RGBA")


def leaf(d, cx, cy, ang, ln, wd, mid, lite, dark):
    """Leaf pointing from (cx,cy) at angle ang (deg, 0=right, -90=up)."""
    a = math.radians(ang)
    ux, uy = math.cos(a), math.sin(a)
    vx, vy = -uy, ux
    pts, pts_l = [], []
    steps = 8
    for i in range(steps + 1):
        t = i / steps
        wv = wd * math.sin(math.pi * min(1, t * 0.95 + 0.05)) * (1 - 0.15 * t)
        pts.append((cx + ux * ln * t + vx * wv, cy + uy * ln * t + vy * wv))
    for i in range(steps, -1, -1):
        t = i / steps
        wv = wd * math.sin(math.pi * min(1, t * 0.95 + 0.05)) * (1 - 0.15 * t)
        pts.append((cx + ux * ln * t - vx * wv, cy + uy * ln * t - vy * wv))
    d.polygon(pts, fill=mid)
    # lit upper half + midrib
    up = [(cx + ux * ln * t + (vx if vy < 0 else -vx) * wd * math.sin(math.pi * t) * 0.55 * (1 if vy < 0 else 1),
           cy + uy * ln * t + (vy if vy < 0 else -vy) * wd * math.sin(math.pi * t) * 0.55) for t in
          [i / steps for i in range(1, steps)]]
    for (x, y) in up:
        d.point((int(round(x)), int(round(y))), fill=lite)
    d.line([(cx, cy), (cx + ux * ln * 0.85, cy + uy * ln * 0.85)], fill=dark if wd > 3 else mid, width=1)


def ellipse_shaded(d, box, mid, lite, dark):
    x0, y0, x1, y1 = box
    d.ellipse(box, fill=mid)
    d.arc((x0, y0, x1, y1), 200, 300, fill=lite)
    d.arc((x0, y0, x1, y1), 20, 120, fill=dark)


def mound(d, w=9, h=3, cy=28):
    d.ellipse((16 - w, cy - h, 16 + w, cy + 2), fill=hx("#6e4528"))
    d.ellipse((16 - w + 2, cy - h, 16 + w - 2, cy), fill=hx("#8a5a34"))
    d.arc((16 - w + 2, cy - h, 16 + w - 2, cy), 200, 330, fill=hx("#b07c47"))


GREENS = dict(mid=hx("#4f9a3c"), lite=hx("#86c850"), dark=hx("#2f6e30"))
GGREENS = dict(mid=hx("#5aa83e"), lite=hx("#98d655"), dark=hx("#357a32"))


def crop_stage(kind, st):
    im = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    G = GREENS if kind == "turnip" else GGREENS
    mid, lite, dark = G["mid"], G["lite"], G["dark"]
    mound(d)
    if st == 0:
        for (x, y) in ((13, 26), (17, 25), (19, 27), (15, 27)):
            d.point((x, y), fill=hx("#e8d29a"))
            d.point((x, y + 1), fill=hx("#9c7a44"))
    elif st == 1:
        d.line([(16, 27), (16, 21)], fill=lite)
        leaf(d, 16, 22, -140, 7, 2.2, mid, lite, dark)
        leaf(d, 16, 22, -40, 7, 2.2, mid, lite, dark)
    elif st == 2:
        d.line([(16, 27), (16, 20)], fill=dark)
        for a, l in ((-160, 8), (-20, 8), (-115, 8), (-65, 8)):
            leaf(d, 16, 24, a, l, 3, mid, lite, dark)
    elif st == 3:
        for a, l in ((-170, 11), (-10, 11), (-130, 13), (-50, 13), (-90, 14)):
            leaf(d, 16, 26, a, l, 3.5, mid, lite, dark)
        if kind == "turnip":
            d.ellipse((13, 25, 19, 28), fill=hx("#efe6f0"))
            d.arc((13, 25, 19, 28), 0, 180, fill=hx("#9a66b0"))
    else:
        if kind == "turnip":
            for a, l in ((-175, 14), (-5, 14), (-145, 17), (-35, 17), (-115, 19), (-65, 19), (-90, 20)):
                leaf(d, 16, 24, a, l, 4, mid, lite, dark)
            # bulb: white bottom, purple crown, peeking out of the soil
            d.ellipse((10, 19, 22, 29), fill=hx("#f2e9f2"))
            d.pieslice((10, 19, 22, 29), 180, 360, fill=hx("#b277c4"))
            d.arc((10, 19, 22, 29), 200, 290, fill=hx("#d9b0e6"))
            d.arc((10, 19, 22, 29), 20, 110, fill=hx("#b9a8c0"))
            d.point((14, 21), fill=hx("#e8cdf2"))
            mound_front = [(8, 28), (12, 26), (20, 26), (24, 28)]
            d.polygon(mound_front + [(24, 30), (8, 30)], fill=hx("#7c4e2e"))
            d.line([(10, 28), (13, 27)], fill=hx("#b07c47"))
        else:
            for a, l in ((-175, 14), (-5, 14), (-145, 17), (-35, 17), (-115, 19), (-65, 19), (-90, 21)):
                leaf(d, 16, 25, a, l, 4.5, mid, lite, dark)
            for (x, y) in ((16, 10), (10, 13), (22, 13)):
                d.ellipse((x - 1, y - 1, x + 1, y + 1), fill=hx("#f4d24a"))
    return outline(im)


def make_crop(kind, name):
    strip = Image.new("RGBA", (160, 32))
    for i in range(5):
        strip.paste(crop_stage(kind, i), (i * 32, 0))
    strip.save(os.path.join(OUT, name))
    return strip


def make_weed():
    im = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    mid, lite, dark = hx("#6a9a2e"), hx("#a6c84a"), hx("#3e6a22")
    for a, l, wd in ((-160, 9, 2), (-20, 9, 2), (-125, 12, 2.5), (-55, 12, 2.5), (-92, 14, 2.5), (-108, 10, 2), (-72, 10, 2)):
        leaf(d, 16, 28, a, l, wd, mid, lite, dark)
    d.ellipse((12, 27, 20, 30), fill=hx("#6e4528"))
    d.arc((12, 27, 20, 30), 200, 330, fill=hx("#8a5a34"))
    im = outline(im)
    im.save(os.path.join(OUT, "weed.png"))
    return im


def preview(dry, wet, turnip, generic, weed):
    S = 6
    grass = (98, 156, 72, 255)
    W, H = 32 * 4 * S + 2 * 32 * S * 0, 0
    # 4x3 soil patch: dry left, wet right (same layout), then stages row
    cols, rows = 4, 3
    pw = cols * 32
    sheet = Image.new("RGBA", (pw * 2 + 16, rows * 32 + 16 + 32 * 3 + 8), grass)
    layout = [[1, 1, 1, 0], [1, 1, 1, 1], [0, 1, 1, 0]]
    for k, strip in enumerate((dry, wet)):
        ox = k * (pw + 16)
        for r in range(rows):
            for c in range(cols):
                if not layout[r][c]: continue
                m = 0
                if r > 0 and layout[r - 1][c]: m |= 1
                if c < cols - 1 and layout[r][c + 1]: m |= 2
                if r < rows - 1 and layout[r + 1][c]: m |= 4
                if c > 0 and layout[r][c - 1]: m |= 8
                t = strip.crop((m * 32, 0, m * 32 + 32, 32))
                sheet.alpha_composite(t, (ox + c * 32, r * 32))
    y0 = rows * 32 + 8
    for row, st in enumerate((turnip, generic)):
        sheet.alpha_composite(st, (0, y0 + row * 32))
    sheet.alpha_composite(weed, (160, y0))
    # all 16 dry frames along bottom
    sheet.alpha_composite(dry.crop((0, 0, 512, 32)).crop((0, 0, 256, 32)), (0, y0 + 64))
    sheet = sheet.resize((sheet.width * S, sheet.height * S), Image.NEAREST)
    sheet.save("/tmp/farm_preview.png")


if __name__ == "__main__":
    random.seed(SEED)
    os.makedirs(OUT, exist_ok=True)
    dry = make_soil(DRY, False, "soil_dry.png")
    wet = make_soil(WET, True, "soil_wet.png")
    t = make_crop("turnip", "crop_turnip.png")
    g = make_crop("generic", "crop_generic.png")
    w = make_weed()
    preview(dry, wet, t, g, w)
    print("ok")
