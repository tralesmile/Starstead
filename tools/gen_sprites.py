#!/usr/bin/env python3
"""Procedural painterly pixel-art sprites for Starstead (original, CC0).

Run from repo root:  python3 tools/gen_sprites.py
Writes assets/sprites/*.png and a 3x preview sheet to /tmp/sprite_preview.png.

Technique: every shape is a lit surface (sphere / lobed blob / extruded slab) whose
normal is dotted with a top-left light, then quantised into a 4-6 colour ramp per
material. Bands come from smooth fields, so shading is clustered, never speckled.
A final pass adds a 1px outline using the darkest colour of the neighbouring material.
"""
import math, os, random
import numpy as np
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "sprites")
LIGHT = np.array([-0.55, -0.68, 0.48]); LIGHT = LIGHT / np.linalg.norm(LIGHT)


def hexc(s):
    s = s.lstrip("#"); return tuple(int(s[i:i + 2], 16) for i in (0, 2, 4))


def ramp(*h):
    return [hexc(c) for c in h]


# ---------------------------------------------------------------- palettes (index 0 = outline)
PINE = ramp("#10302a", "#1f4a3a", "#2b5f44", "#3e784d", "#5f9a5a", "#7aae66")
OAK = ramp("#173a22", "#2e6b2e", "#3d8233", "#55993a", "#78b442", "#9ccc4a", "#b8dc6a")
BARK = ramp("#2e1d14", "#4a2f1f", "#6b4429", "#8a5a34", "#a8743f")
STONE = ramp("#4f504c", "#8a8b86", "#a7a7a0", "#c4c3ba", "#d9d7cc", "#e8e6dc", "#f4f2ea")
MOSS = ramp("#26401f", "#3f6a2a", "#557f30", "#6f9a38", "#8fb648")
WOOD = ramp("#3a2214", "#6e4526", "#8a5a34", "#a26d3f", "#b67d48", "#c48a52", "#d6a066")
WOODF = ramp("#2a180e", "#4a2e1a", "#5e3b22", "#734a2a")
ROPE = ramp("#5a4426", "#a0844e", "#c8ab6c", "#e0c88a")
PAD = ramp("#3e4a18", "#5a6826", "#6f7f2e", "#86963c", "#9aa84a", "#b4c060")
PETAL = ramp("#8a3a5a", "#d86a96", "#f09ab8", "#ffd0e0", "#f4d24a")
REED = ramp("#183222", "#24472c", "#2f5a34", "#3d703c", "#548846", "#6e9e52")
CATTAIL = ramp("#2e1a10", "#5a3620", "#76482a", "#946038")


class Canvas:
    def __init__(self, w, h):
        self.w, self.h = w, h
        self.rgb = np.zeros((h, w, 3), np.uint8)
        self.a = np.zeros((h, w), np.uint8)
        self.mat = np.full((h, w), -1, int)
        self.sh = np.zeros((h, w), int)
        self.pals = []
        self.yy, self.xx = np.mgrid[0:h, 0:w].astype(float)

    def material(self, pal):
        self.pals.append(pal); return len(self.pals) - 1

    def put(self, x, y, m, s, alpha=255):
        x, y = int(x), int(y)
        if 0 <= x < self.w and 0 <= y < self.h:
            s = max(0, min(len(self.pals[m]) - 1, int(s)))
            self.rgb[y, x] = self.pals[m][s]; self.a[y, x] = alpha
            self.mat[y, x] = m; self.sh[y, x] = s

    def paint(self, mask, m, shades):
        pal = np.array(self.pals[m])
        if np.isscalar(shades):
            shades = np.full((self.h, self.w), shades)
        s = np.clip(shades.astype(int), 0, len(pal) - 1)
        self.rgb[mask] = pal[s[mask]]; self.a[mask] = 255
        self.mat[mask] = m; self.sh[mask] = s[mask]

    def shift_shade(self, mask, delta, only_mat=None):
        mask = mask & (self.a > 0)
        if only_mat is not None:
            mask &= self.mat == only_mat
        for y, x in zip(*np.nonzero(mask)):
            m = self.mat[y, x]
            self.put(x, y, m, max(1, self.sh[y, x] + delta))

    def outline(self):
        filled = self.a > 0
        adds = []
        for y in range(self.h):
            for x in range(self.w):
                if filled[y, x]:
                    continue
                for dx, dy in ((0, 1), (1, 0), (-1, 0), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < self.w and 0 <= ny < self.h and filled[ny, nx]:
                        adds.append((x, y, self.mat[ny, nx])); break
        for x, y, m in adds:
            self.put(x, y, m, 0)

    def image(self):
        return Image.fromarray(np.dstack([self.rgb, self.a]), "RGBA")


def quant(v, n, lo=1):
    """Map v in [0,1] to integer shades lo..lo+n-1."""
    return lo + np.clip((v * n).astype(int), 0, n - 1)


def blob_field(c, cx, cy, rx, ry, lobes=0, amp=0.0, phase=0.0):
    """Returns (mask, nx, ny, nz, r) for a (lobed) ellipsoid."""
    dx = (c.xx + 0.5 - cx) / rx; dy = (c.yy + 0.5 - cy) / ry
    ang = np.arctan2(dy, dx)
    k = 1.0 + amp * np.cos(lobes * ang + phase) if lobes else 1.0
    r = np.sqrt(dx * dx + dy * dy) / k
    mask = r < 1.0
    nz = np.sqrt(np.clip(1 - r * r, 0, 1))
    rr = np.maximum(np.sqrt(dx * dx + dy * dy), 1e-6)
    nx = dx / rr * r; ny = dy / rr * r
    return mask, nx, ny, nz, r


def lit(nx, ny, nz):
    return nx * LIGHT[0] + ny * LIGHT[1] + nz * LIGHT[2]


# ================================================================ trees / foliage
def leaf_clump(c, m, cx, cy, rad, rnd, bias=0.0, nsh=5):
    """One leafy clump: lobed blob, lit top-left, dark rim bottom-right, leaf flecks."""
    lobes = rnd.choice([5, 6, 7])
    mask, nx, ny, nz, r = blob_field(c, cx, cy, rad, rad * 0.88, lobes, 0.13, rnd.uniform(0, 6.28))
    d = lit(nx, ny, nz)  # -1..1
    v = np.clip((d + 0.15) / 1.05 + bias, 0, 0.999)
    s = quant(v, nsh)
    rim_dark = mask & (r > 0.78) & (d < 0.25)
    s[rim_dark] = np.minimum(s[rim_dark], 1 + (bias > 0.1))
    rim_hi = mask & (r > 0.62) & (r < 0.9) & (d > 0.72)
    s[rim_hi] = nsh + 1  # extra-bright rim pixel shade
    c.paint(mask, m, s)
    # leaf flecks: small 3-pixel chevrons, lighter in light, darker in shade
    for _ in range(int(rad * rad / 9)):
        a = rnd.uniform(0, 6.28); rr = rnd.uniform(0.15, 0.7) * rad
        fx, fy = int(cx + math.cos(a) * rr), int(cy + math.sin(a) * rr * 0.88)
        if not (0 <= fx < c.w and 0 <= fy < c.h) or not mask[fy, fx]:
            continue
        base = c.sh[fy, fx]
        delta = 1 if base >= 3 else -1
        for px, py in ((0, 0), (1, 0), (-1, 1)) if rnd.random() < 0.5 else ((0, 0), (-1, 0), (1, 1)):
            X, Y = fx + px, fy + py
            if 0 <= X < c.w and 0 <= Y < c.h and mask[Y, X]:
                c.put(X, Y, m, min(nsh, max(1, c.sh[Y, X] + delta)))
    return mask


def trunk(c, m, cx, top, bottom, w_top, w_bot, rnd, shadow_rows=4):
    for y in range(top, bottom + 1):
        t = (y - top) / max(1, bottom - top)
        hw = w_top / 2 + (w_bot - w_top) / 2 * (t ** 3)
        for x in range(int(cx - hw), int(math.ceil(cx + hw))):
            u = (x + 0.5 - (cx - hw)) / (2 * hw)  # 0 left .. 1 right
            s = 4 if u < 0.3 else 3 if u < 0.6 else 2 if u < 0.85 else 1
            c.put(x, y, m, s)
    # bark grooves: vertical clustered strokes
    for gx in (cx - w_top * 0.15, cx + w_top * 0.2):
        y = top + rnd.randint(1, 4)
        while y < bottom - 1:
            ln = rnd.randint(5, 10)
            for k in range(ln):
                if c.mat[y + k, int(gx)] == m:
                    c.put(int(gx), y + k, m, max(1, c.sh[y + k, int(gx)] - 1))
            y += ln + rnd.randint(1, 3)
    for y in range(top, top + shadow_rows):
        for x in range(c.w):
            if c.mat[y, x] == m:
                c.put(x, y, m, 1)


def make_oak():
    c = Canvas(80, 96); rnd = random.Random(7)
    lm = c.material(OAK); bm = c.material(BARK)
    trunk(c, bm, 40, 58, 92, 11, 19, rnd)
    # root flares
    for x, y in ((29, 92), (30, 91), (50, 92), (49, 91), (33, 92), (47, 92)):
        c.put(x, y, bm, 2 if x > 40 else 3)
    # dark backing mass (gaps between clumps read as depth)
    mask, nx, ny, nz, r = blob_field(c, 40, 38, 36, 30, 9, 0.07, 0.4)
    c.paint(mask, lm, np.where(lit(nx, ny, nz) > 0.4, 2, 1))
    # clumps, back (top) to front (bottom); front ones overlap and darken toward base
    clumps = []
    for ring, (rad_c, n, rr) in enumerate(((22, 9, 12), (11, 6, 10), (0, 1, 12))):
        for i in range(n):
            a = 2 * math.pi * i / n + ring * 0.6 + rnd.uniform(-0.15, 0.15)
            x = 40 + math.cos(a) * rad_c * 1.18 + rnd.uniform(-1.5, 1.5)
            y = 37 + math.sin(a) * rad_c * 0.95 + rnd.uniform(-1.5, 1.5)
            clumps.append((x, y, rr + rnd.uniform(-1.5, 1.5)))
    clumps.sort(key=lambda t: t[1])
    for x, y, rr in clumps:
        bias = 0.12 * (40 - x) / 30 + 0.16 * (37 - y) / 26
        leaf_clump(c, lm, x, y, rr, rnd, bias=bias)
    # under-canopy shadow on trunk top
    c.outline()
    return c


def make_bush():
    c = Canvas(32, 32); rnd = random.Random(21)
    lm = c.material(OAK)
    mask, nx, ny, nz, r = blob_field(c, 16, 19, 14, 11)
    c.paint(mask, lm, 1)
    for x, y, rr in sorted(((10, 19, 7.5), (22, 19, 7.5), (16, 14, 8), (11, 23, 6.5), (21, 23, 6.5), (16, 22, 7)), key=lambda t: t[1]):
        leaf_clump(c, lm, x, y, rr, rnd, bias=0.1 * (16 - x) / 8 + 0.12 * (19 - y) / 6)
    c.outline()
    return c


def make_pine():
    c = Canvas(64, 96); rnd = random.Random(3)
    pm = c.material(PINE); bm = c.material(BARK)
    trunk(c, bm, 32, 74, 92, 7, 11, rnd, shadow_rows=5)
    tiers = [(3, 22, 10), (12, 36, 16), (23, 51, 21), (35, 66, 26), (48, 82, 30)]  # apex y, bottom y, half width
    prev = None
    masks = []
    for apex, bot, W in reversed(tiers):  # draw bottom tier first
        m = np.zeros((c.h, c.w), bool); s = np.zeros((c.h, c.w), int)
        for x in range(c.w):
            dx = x + 0.5 - 32
            if abs(dx) > W:
                continue
            u = abs(dx) / W
            tx = (x + apex) % 6
            tuft = 2.4 * math.sqrt(max(0.0, 1 - ((tx - 2.5) / 3.0) ** 2))  # rounded hanging needle tufts
            yb = bot + 5.0 * u ** 2 + tuft - 1
            for y in range(apex, int(yb) + 1):
                hgt = y - apex
                t = min(1.0, hgt / (bot - apex))
                hw = max(1.0, W * t ** 1.75 + 0.5)
                if abs(dx) > hw:
                    continue
                m[y, x] = True
                ang = math.atan2(dx, hgt + 4)  # radiating branch direction
                streak = 0.12 * math.sin(ang * 7 + hgt * 0.2)
                v = 0.92 - 0.5 * (dx / W + 0.25) - 0.55 * t + streak
                if y >= yb - 2:
                    v = (0.55 if tx < 2.5 else 0.3) - 0.35 * (dx / W)  # tuft tips: lit left half
                if y >= yb - 0.5:
                    v -= 0.25
                s[y, x] = int(np.clip(v * 5, 0, 4.99)) + 1
        # top-left tier highlight strip along left slope
        for y in range(apex, bot):
            xs = np.nonzero(m[y])[0]
            if len(xs) and y - apex < (bot - apex) * 0.75:
                x0 = xs[0]
                for k in range(0, 2):
                    if x0 + k < 32:
                        s[y, x0 + k] = max(s[y, x0 + k], 5 if k == 0 else 4)
        s[apex:apex + 3, 31:33] = np.maximum(s[apex:apex + 3, 31:33], 5)
        # shadow cast by this tier onto the tier below (drawn earlier)
        sh = np.zeros_like(m)
        for k in range(1, 4):
            sh[k:] |= m[:-k]
        c.paint(sh & ~m & (c.mat == pm), pm, 1)
        c.paint(m, pm, s)
        masks.append(m)
    c.shift_shade(np.vstack([np.zeros((1, c.w), bool), masks[0][:-1]]) & (c.mat == bm), -1)
    c.outline()
    return c


# ================================================================ stones
def stone_lumps(c, sm, lumps, flat=0.0):
    """Union of ellipsoid lumps, shaded by max height field."""
    H = np.full((c.h, c.w), -1.0)
    for cx, cy, rx, ry, hz in lumps:
        dx = (c.xx + 0.5 - cx) / rx; dy = (c.yy + 0.5 - cy) / ry
        r2 = dx * dx + dy * dy
        h = np.where(r2 < 1, hz * np.sqrt(np.clip(1 - r2, 0, 1)) ** (1 - flat), -1)
        H = np.maximum(H, h)
    mask = H > 0
    Hc = np.where(mask, H, 0)
    gy, gx = np.gradient(Hc)
    n = np.dstack([-gx, -gy, np.ones_like(Hc)]); n /= np.linalg.norm(n, axis=2, keepdims=True)
    d = n @ LIGHT
    # ambient occlusion: lower part of each stone darker
    ys = np.where(mask)[0]
    y0, y1 = ys.min(), ys.max()
    ao = (c.yy - y0) / max(1, y1 - y0)
    v = np.clip((d - 0.05) / 0.9 - 0.25 * ao ** 2, 0, 0.999)
    shades = quant(v, len(STONE) - 2)
    c.paint(mask, sm, shades)
    return mask, Hc


def crack(c, sm, pts):
    for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
        n = max(abs(x1 - x0), abs(y1 - y0))
        for i in range(n + 1):
            x = round(x0 + (x1 - x0) * i / n); y = round(y0 + (y1 - y0) * i / n)
            if c.mat[y, x] == sm:
                c.put(x, y, sm, max(1, min(2, c.sh[y, x] - 2)))
                if c.mat[y, x + 1] == sm and c.sh[y, x + 1] >= 3:  # lit lip right of crack
                    c.put(x + 1, y, sm, min(6, c.sh[y, x + 1] + 1))


def moss_patch(c, mm, cx, cy, rx, ry, rnd, within):
    mask, nx, ny, nz, r = blob_field(c, cx, cy, rx, ry, rnd.choice([4, 5, 6]), 0.25, rnd.uniform(0, 6))
    mask &= within
    d = lit(nx, ny, nz)
    c.paint(mask, mm, quant(np.clip((d + 0.3) / 1.2, 0, 0.999), 4))


def make_rock():
    c = Canvas(32, 32); rnd = random.Random(11)
    sm = c.material(STONE); mm = c.material(MOSS)
    mask, H = stone_lumps(c, sm, [(14, 17, 10.5, 9, 9), (21, 20, 8, 7, 6.5), (9, 22, 6, 5, 4.5)])
    crack(c, sm, [(15, 10), (14, 13), (16, 16), (15, 18)])
    crack(c, sm, [(22, 16), (21, 19)])
    crack(c, sm, [(8, 20), (10, 22)])
    lower = mask & (c.yy > 23)
    for x, y, rx, ry in ((6, 26, 3, 1.6), (13, 27.5, 3.2, 1.5), (24, 26.5, 3, 1.6)):
        moss_patch(c, mm, x, y, rx, ry, rnd, lower)
    c.outline()
    return c


def shore_stone(seed, lumps, moss):
    c = Canvas(32, 32); rnd = random.Random(seed)
    sm = c.material(STONE); mm = c.material(MOSS)
    mask, H = stone_lumps(c, sm, lumps, flat=0.75)
    top = mask & (H > 0.55 * H.max())
    for cx, cy, rx, ry in moss:
        moss_patch(c, mm, cx, cy, rx, ry, rnd, top | (mask & (c.yy < cy + ry)))
    # moss drips over front edge: short vertical runs
    mossm = c.mat == mm
    for x in range(c.w):
        col = np.nonzero(mossm[:, x])[0]
        if len(col) and rnd.random() < 0.35:
            yb = col.max()
            for k in range(1, rnd.randint(2, 3)):
                if yb + k < c.h and c.mat[yb + k, x] == sm:
                    c.put(x, yb + k, mm, 1)
    # wet dark waterline at the base
    ys = np.nonzero(mask)[0]
    c.shift_shade(mask & (c.yy >= ys.max() - 1) & (c.mat == sm), -1)
    c.outline()
    return c


def make_shore():
    sets = [
        (31, [(16, 18, 13, 9, 7)], [(14, 14, 8, 4)]),
        (32, [(12, 19, 9, 8, 6), (21, 20, 8, 7, 5)], [(11, 15, 5, 3), (21, 16.5, 4.5, 2.5)]),
        (33, [(16, 20, 11, 7, 5), (11, 17, 6, 5, 5.5)], [(12, 15, 6, 3), (19, 16.5, 4, 2)]),
        (34, [(15, 21, 12, 6, 4), (22, 18, 6, 5, 5)], [(21, 15, 4, 2.4), (11, 18.5, 5, 2.2)]),
    ]
    sheet = Image.new("RGBA", (128, 32))
    for i, (seed, lumps, moss) in enumerate(sets):
        sheet.paste(shore_stone(seed, lumps, moss).image(), (i * 32, 0))
    return sheet


# ================================================================ water things
def lily_pad(seed, flower=False, notch_ang=0.6, rx=6.6, ry=5.6):
    c = Canvas(16, 16); rnd = random.Random(seed)
    pm = c.material(PAD); fm = c.material(PETAL)
    cx, cy = 8, 8.5
    dx = c.xx + 0.5 - cx; dy = (c.yy + 0.5 - cy) * rx / ry
    r = np.sqrt(dx * dx + dy * dy) / rx
    ang = np.arctan2(dy, dx)
    da = np.abs((ang - notch_ang + np.pi) % (2 * np.pi) - np.pi)
    mask = (r < 1) & ~((da < 0.32) & (r > 0.08))
    # flat pad: lighter upper-left, darker rim, radial veins
    v = 0.62 - 0.22 * (dx + dy) / rx
    s = quant(np.clip(v, 0, 0.999), 4, lo=2)
    s = np.where(r > 0.8, np.minimum(s, 2), s)
    vein = (np.abs(((ang - notch_ang) * 7 / np.pi) % 2 - 1) < 0.16) & (r > 0.25) & (r < 0.78)
    s = np.where(vein, s + 1, s)
    c.paint(mask, pm, s)
    c.put(cx - 3, cy - 3, pm, 5); c.put(cx - 2, cy - 3, pm, 5)
    if flower:
        fx, fy = 6, 7
        for px, py, sh in ((0, -2, 2), (-1, -1, 2), (1, -1, 3), (-2, 0, 1), (2, 0, 2), (-1, 0, 2), (1, 0, 2),
                           (0, -1, 3), (-1, 1, 1), (1, 1, 1), (0, 1, 1), (0, 0, 4)):
            c.put(fx + px, fy + py, fm, sh)
    c.outline()
    return c


def make_lily():
    sheet = Image.new("RGBA", (64, 16))
    pads = [lily_pad(1, False, 0.6), lily_pad(2, False, 2.6, 6.0, 5.2), lily_pad(3, True, -0.9),
            lily_pad(4, False, 4.2, 5.4, 4.6)]
    for i, p in enumerate(pads):
        sheet.paste(p.image(), (i * 16, 0))
    return sheet


def make_reeds():
    c = Canvas(32, 32); rnd = random.Random(5)
    rm = c.material(REED); cm = c.material(CATTAIL)
    blades = []
    for i in range(10):
        bx = 9.5 + i * 1.45 + rnd.uniform(-0.6, 0.6)
        h = rnd.uniform(14, 25)
        lean = (bx - 16) * 1.1 + rnd.uniform(-3, 3)
        blades.append((rnd.uniform(0, 1), bx, h, lean))
    blades.sort()
    for depth, bx, h, lean in blades:
        base_y = 29 + int(depth * 2)
        steps = int(h)
        shade_base = 2 + int(depth * 3)
        for k in range(steps):
            t = k / steps
            x = bx + lean * t * t
            y = base_y - k
            wid = 2 if t < 0.55 else 1
            for wx in range(wid):
                sh = shade_base + (1 if wx == 0 and lean < 0 else 0) - (1 if t < 0.15 else 0)
                c.put(x + wx, y, rm, min(5, sh))
    # cattails on three stems
    for sx, top, ln in ((13, 7, 5), (19, 5, 6), (16, 11, 4)):
        for k in range(top + ln, 29):
            c.put(sx, k, rm, 3)
        for k in range(ln):
            c.put(sx, top + k, cm, 3 if k < ln - 1 else 2)
            c.put(sx + 1, top + k, cm, 2 if k < ln - 1 else 1)
        c.put(sx, top - 1, rm, 3); c.put(sx, top - 2, rm, 4)
        c.put(sx, top + 1, cm, 3); c.put(sx, top, cm, 3)
    c.outline()
    return c


def make_fish():
    sheet = Image.new("RGBA", (64, 16))
    col = (18, 58, 62)
    for f, swing in enumerate((0.0, 0.55, 0.0, -0.55)):
        im = Image.new("RGBA", (16, 16))
        px = im.load()
        # spine along x (fish swims right), body bends toward tail
        for i in range(-60, 61):
            t = i / 60.0  # -1 tail .. 1 head
            bend = swing * max(0, -t) ** 1.6 * 3.0
            sx = 8 + t * 5.0; sy = 8 + bend
            half = 1.9 * math.sqrt(max(0, 1 - ((t - 0.25) / 1.05) ** 2))
            if t < -0.72:
                half = 2.2 * (-(t + 0.72) / 0.28) + 0.4  # tail fan
            for oy in np.arange(-half, half + 0.01, 0.5):
                X, Y = int(round(sx - 0.25)), int(round(sy + oy))
                if 0 <= X < 16 and 0 <= Y < 16:
                    px[X, Y] = col + (110,)
        sheet.paste(im, (f * 16, 0))
    return sheet


# ================================================================ dock
def make_dock():
    c = Canvas(96, 64); rnd = random.Random(9)
    wm = c.material(WOOD); fm = c.material(WOODF); rm = c.material(ROPE)
    top0, top1, front1 = 14, 50, 57
    ph = 6
    # deck planks (horizontal boards stacked toward the viewer)
    for pi, y0 in enumerate(range(top0, top1, ph)):
        joint = 20 + (pi * 29) % 52
        base = 4 if pi % 2 == 0 else 3
        for y in range(y0, min(y0 + ph, top1)):
            for x in range(2, 94):
                s = base
                if y == y0:
                    s = 1  # seam
                elif y == y0 + 1:
                    s = base + 1  # lit upper bevel
                elif y == y0 + ph - 1:
                    s = base - 1
                if x in (joint, joint + 52) or x in (joint - 52,):
                    s = 1
                c.put(x, y, wm, s)
        # wood grain: clustered horizontal streaks
        for _ in range(5):
            gx = rnd.randint(4, 80); gy = y0 + rnd.randint(2, ph - 2); ln = rnd.randint(4, 11)
            for k in range(ln):
                if c.sh[gy, gx + k] > 1:
                    c.put(gx + k, gy, wm, c.sh[gy, gx + k] - 1)
        # nails near each joint and ends
        for nx in (4, joint - 3, joint + 2, 91):
            if 2 < nx < 93:
                for ny in (y0 + 2, y0 + 4):
                    c.put(nx, ny, wm, 1)
                    c.put(nx - 1, ny - 1 if ny == y0 + 2 else ny, wm, base + 2)
    # front face of deck (darker, vertical end grain)
    for y in range(top1, front1):
        for x in range(2, 94):
            s = 3 if y == top1 else 2 if y < front1 - 2 else 1
            if (x - 2) % 12 == 0:
                s = 1
            c.put(x, y, fm, s)
    # support posts down into water at front
    for px in (6, 46, 86):
        for y in range(front1, 64):
            for k in range(5):
                s = 3 if k == 1 else 2 if k < 3 else 1
                if y >= 61:
                    s = max(1, s - 1)  # wet
                c.put(px + k, y, fm, s)
    # back posts with rope rail
    posts = (8, 84)
    for px in posts:
        for y in range(2, top0 + 4):
            for k in range(6):
                s = 5 if k == 1 else 4 if k < 3 else 3 if k < 5 else 2
                if y < 4:
                    s = 6 if k < 4 else 4  # cut top lit
                if y >= top0 + 1:
                    s = max(1, s - 2)  # base shadow on deck
                c.put(px + k, y, wm, s)
        c.put(px + 1, 6, wm, 2); c.put(px + 1, 7, wm, 2)
    # sagging rope (catenary-ish parabola) with twisted pattern
    xa, xb, ya = posts[0] + 5, posts[1], 6
    for x in range(xa, xb + 1):
        t = (x - xa) / (xb - xa)
        y = ya + 6 * 4 * t * (1 - t)
        yi = int(round(y))
        c.put(x, yi, rm, 3 if x % 3 else 2)
        c.put(x, yi + 1, rm, 1 if x % 3 == 1 else 2)
    # rope wraps on posts
    for px in posts:
        for k in range(6):
            c.put(px + k, ya, rm, 3 if k < 3 else 2)
            c.put(px + k, ya + 1, rm, 2 if k < 4 else 1)
    # soft shadow of the rope on the deck
    for x in range(xa, xb + 1):
        t = (x - xa) / (xb - xa)
        y = int(round(top0 + 2 + 3 * 4 * t * (1 - t)))
        if c.mat[y, x] == wm and c.sh[y, x] > 1:
            c.put(x, y, wm, c.sh[y, x] - 1)
    c.outline()
    return c


# ================================================================ player
PLAYER_MATS = {
    "skin": ramp("#7a4634", "#c98868", "#e8b48c", "#f6cca4"),
    "hair": ramp("#2c180e", "#4e2e1a", "#6e4224", "#8e5a32"),
    "tunic": ramp("#22301a", "#4a6428", "#668634", "#86a448"),
    "pants": ramp("#18161e", "#2e2c38", "#433f4e"),
    "boots": ramp("#22140c", "#4a2e1c", "#6a4428"),
    "belt": ramp("#22140c", "#5a3a22", "#e0b84e"),
    "eye": ramp("#2a1a16", "#2a1a16"),
}
CHARS = {
    "h": ("hair", 1), "H": ("hair", 2), "k": ("hair", 3),
    "S": ("skin", 2), "s": ("skin", 1), "q": ("skin", 3), "m": ("skin", 0),
    "e": ("eye", 1),
    "T": ("tunic", 2), "t": ("tunic", 1), "u": ("tunic", 3),
    "L": ("belt", 1), "l": ("belt", 2),
}
UP_DOWN = [  # rows y=7..24, 16 wide (x=8..23)
    ".....hHHHHh.....",
    "...hHkkkkkkHh...",
    "..hHkkkkHkkkHh..",
    "..hHHkHHHHHkHh..",
    "..hHSSSSSSSSHh..",
    "..hSqqSSSSSSSh..",
    "..hSSeSSSSeSSh..",
    "..sSSeSSSSeSSs..",
    "..hHSSSssSSSHh..",
    "..hHHkHHHHkHHh..",
    "..hHHHHmmHHHHh..",
    "...hHHHHHHHHh...",
    "..uThhHHHHhhTt..",
    ".uuTTThHHhTTTtt.",
    ".SuTTTThhTTTTtS.",
    ".SuTTTTTTTTTTtS.",
    ".ssLLLLllLLLLss.",
    "..tTTTTTTTTTTt..",
]
UP_BACK = [
    ".....hHHHHh.....",
    "...hHkkkkkkHh...",
    "..hHkkkkkkkkHh..",
    "..hHkkHkkHkkHh..",
    "..hHHkHHHHkHHh..",
    "..hHHHHHHHHHHh..",
    "..hHHHkHHkHHHh..",
    "..shHHHHHHHHhs..",
    "..hhHHHHHHHHhh..",
    "...hhHHHHHHhh...",
    "....hhhhhhhh....",
    "...hssSSSSssh...",
    "..uTTTTTTTTTTt..",
    ".uuTTTTTTTTTTtt.",
    ".SuTTTTTTTTTTtS.",
    ".SuTTTTttTTTTtS.",
    ".ssLLLLLLLLLLss.",
    "..tTTTTTTTTTTt..",
]
UP_RIGHT = [
    "....hHHHHh......",
    "...hHkkkkkHh....",
    "..hHkkkkkkkHh...",
    "..hHHkkkHHkHHh..",
    "..hHHHHHSSSSSS..",
    "..hHHHHSqqSSSS..",
    "..hHsHHSSSSeSS..",
    "..hHssHSSSSeSSs.",
    "..hHHHHHSSSSSs..",
    "...hHHHHHkHHHH..",
    "....hHHHHHHHmH..",
    "....hhHHHHHHH...",
    "....uTTTTThHh...",
    "....uTTutTTTt...",
    "....uTTutTTTt...",
    "....uTTSStTTt...",
    "....LLLssLLLL...",
    "....tTTTTTTTt...",
]


def draw_legs(c, mats, ox, direction, frame, by):
    P, B = mats["pants"], mats["boots"]
    if direction in ("down", "up"):
        legs = [(ox + 4, 0), (ox + 9, 1)]
        for i, (lx, side) in enumerate(legs):
            lift = 0
            if frame == 1 and i == 0 or frame == 2 and i == 1:
                lift = 1
            top, foot = 25 + by, 30 - lift
            for y in range(top, foot + 1):
                for k in range(3):
                    if y >= foot - 2:
                        c.put(lx + k, y, B, 2 if k == 0 and y < foot else 1)
                    else:
                        c.put(lx + k, y, P, 2 if k == 0 and side == 0 else 1)
    else:  # right-facing; left is mirrored later
        offs = {0: [(ox + 7, 0, 0)], 1: [(ox + 5, 1, 0), (ox + 9, 0, 0)], 2: [(ox + 9, 1, 1), (ox + 5, 0, 1)]}[frame]
        if frame == 0:
            offs = [(ox + 6, 0, 0)]
        for lx, back, lift in offs:
            w = 4 if frame == 0 else 3
            foot = 30 - (1 if back and frame else 0)
            for y in range(25 + by, foot + 1):
                for k in range(w):
                    dk = -1 if back else 0
                    if y >= foot - 2:
                        c.put(lx + k, y, B, max(1, (2 if k == 0 else 1) + dk))
                    else:
                        c.put(lx + k, y, P, max(1, (2 if k < 2 else 1) + dk))
            if y >= foot:
                c.put(lx + w, foot, B, 1 if not back else 1)  # toe points forward
                c.put(lx + w, foot - 1, B, 1 if not back else 1)


def make_player():
    sheet = Image.new("RGBA", (96, 128))
    for row, direction in enumerate(("down", "left", "up", "right")):
        for frame in range(3):
            c = Canvas(32, 32)
            mats = {k: c.material(v) for k, v in PLAYER_MATS.items()}
            by = -1 if frame else 0
            d = "right" if direction == "left" else direction
            tmpl = {"down": UP_DOWN, "up": UP_BACK, "right": UP_RIGHT}[d]
            ox = 8
            draw_legs(c, mats, ox, d, frame, by)
            for j, line in enumerate(tmpl):
                assert len(line) == 16, (d, j, line)
                for i, ch in enumerate(line):
                    if ch == ".":
                        continue
                    if d == "right" and frame and i in (7, 8) and j in (13, 14, 15):
                        # swing the arm on step frames
                        pass
                    mname, sh = CHARS[ch]
                    c.put(ox + i, 7 + j + by, mats[mname], sh)
            if d == "right" and frame:
                # arm swing: hand moves forward/back one pixel
                hx = ox + (8 if frame == 1 else 6)
                c.put(ox + 7, 22 + by, mats["tunic"], 2); c.put(ox + 8, 22 + by, mats["tunic"], 2)
                c.put(hx, 22 + by, mats["skin"], 2); c.put(hx + 1, 22 + by, mats["skin"], 2)
            if d in ("down", "up") and frame:
                # alternate arms: one hand drops a pixel
                hx = ox + (1 if frame == 1 else 14)
                c.put(hx, 24 + by, mats["skin"], 1)
            c.outline()
            im = c.image()
            if direction == "left":
                im = im.transpose(Image.FLIP_LEFT_RIGHT)
            sheet.paste(im, (frame * 32, row * 32))
    return sheet


# ================================================================ main
def as_img(x):
    return x.image() if isinstance(x, Canvas) else x


def preview(items, path):
    S = 3; pad = 8
    imgs = [(n, as_img(i)) for n, i in items]
    W = 0; rows = []; row = []; rw = 0
    for n, im in imgs:
        w = im.width * S + pad
        if rw + w > 1000 and row:
            rows.append(row); row = []; rw = 0
        row.append(im); rw += w
    rows.append(row)
    H = sum(max(i.height for i in r) * S + pad for r in rows) + pad
    W = max(sum(i.width * S + pad for i in r) for r in rows) + pad
    sheet = Image.new("RGBA", (W, H), (96, 150, 72, 255))
    y = pad
    for r in rows:
        x = pad
        for im in r:
            sheet.alpha_composite(im.resize((im.width * S, im.height * S), Image.NEAREST), (x, y))
            x += im.width * S + pad
        y += max(i.height for i in r) * S + pad
    sheet.save(path)


def main():
    os.makedirs(OUT, exist_ok=True)
    items = [
        ("tree_pine", make_pine()), ("tree_oak", make_oak()), ("bush", make_bush()), ("rock", make_rock()),
        ("shore_rocks", make_shore()), ("lily_pads", make_lily()), ("reeds", make_reeds()),
        ("fish", make_fish()), ("dock", make_dock()), ("player", make_player()),
    ]
    for name, it in items:
        as_img(it).save(os.path.join(OUT, name + ".png"))
        print("wrote", os.path.join("assets/sprites", name + ".png"), as_img(it).size)
    preview(items, "/tmp/sprite_preview.png")
    print("preview /tmp/sprite_preview.png")


if __name__ == "__main__":
    main()
