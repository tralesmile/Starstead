#!/usr/bin/env python3
"""High-detail player sprite sheet for Starstead (original, CC0).

Run from repo root:  python3 tools/gen_player_hd.py
Writes assets/sprites/player_hd.png and a 4x preview to /tmp/player_hd_preview.png.

Layout: 672x192, frames 32 wide x 48 tall, 21 columns x 4 rows.
  rows:    0 = down (front), 1 = left, 2 = up (back), 3 = right
  columns: 0 = idle, 1-6 = walk (contact, down, passing, contact, down, passing),
           7 = tool swing (arms raised forward/overhead, leaning into the facing direction),
           8 = cast wind-up, 9 = cast follow-through, 10-11 = reeling (the rod itself is drawn
           in code, scripts/fishing_world_view.gd; its grip is 6px to the side, 13px above the feet),
           12-14 = heavy tool (wind-up overhead, strike bent forward, recover),
           15-17 = hoe (reach, chop down, drag back), 18-19 = watering can (held out, leaning pour),
           20 = drawn bow. The fist positions of 12-20 are mirrored in scripts/pose_math.gd (GRIPS).
Feet bottom on y = 46, body centred on x = 16 (the boundary between pixel columns 15 and 16).

Same design as player.png (tools/gen_sprites.py): chunky bearded man, brown hair and beard,
olive tunic, gold buckle, dark trousers, boots. Every part is a lit surface (ellipsoid or
cylinder) whose normal is dotted with a top-left light and quantised into a small ramp, so
shading is clustered. Parts are composited back to front; each part draws a 1px inner line
in its own darkest shade where it overlaps parts behind it, and a final pass adds the outer
1px outline in the darkest shade of the touching material. The left row is drawn as a
right-facing figure under a mirrored light and then flipped, so light stays top-left.
"""
import math, os
import numpy as np
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "sprites", "player_hd.png")
PREVIEW = "/tmp/player_hd_preview.png"
FW, FH = 32, 48
GROUND = 46
CX = 16.0


def hexc(s):
    s = s.lstrip("#"); return tuple(int(s[i:i + 2], 16) for i in (0, 2, 4))


def ramp(*h):
    return [hexc(c) for c in h]


# index 0 = outline (darkest), then dark -> light
PAL = {
    "skin": ramp("#7a4634", "#b87656", "#d4986e", "#e8b48c", "#f6cca4"),
    "hair": ramp("#2c180e", "#4e2e1a", "#6e4224", "#8e5a32", "#a8703e"),
    "tunic": ramp("#22301a", "#40592a", "#567a2e", "#6e9440", "#88ac52"),
    "pants": ramp("#18161e", "#2a2834", "#3a3746", "#4e4a5c"),
    "boots": ramp("#22140c", "#3e2616", "#5a3a22", "#74502e"),
    "belt": ramp("#22140c", "#4a2e1a", "#6a4428"),
    "gold": ramp("#5a3e10", "#a07a26", "#e0b84e", "#fae49a"),
    "eye": ramp("#2a1a16", "#2a1a16", "#fff4e0"),
}
MATS = list(PAL)
MI = {k: i for i, k in enumerate(MATS)}

YY, XX = np.mgrid[0:FH, 0:FW].astype(float)
PY, PX = YY + 0.5, XX + 0.5  # pixel centres


class Layer:
    def __init__(self):
        self.mask = np.zeros((FH, FW), bool)
        self.mat = np.full((FH, FW), -1, int)
        self.sh = np.zeros((FH, FW), int)

    def paint(self, mask, mat, shades):
        n = len(PAL[mat]) - 1
        s = np.full((FH, FW), shades) if np.isscalar(shades) else shades
        s = np.clip(np.asarray(s).astype(int), 1, n)
        self.mask |= mask
        self.mat[mask] = MI[mat]
        self.sh[mask] = s[mask]

    def put(self, x, y, mat, s):
        x, y = int(round(x)), int(round(y))
        if 0 <= x < FW and 0 <= y < FH:
            self.mask[y, x] = True; self.mat[y, x] = MI[mat]; self.sh[y, x] = s

    def erase(self, x, y):
        x, y = int(round(x)), int(round(y))
        if 0 <= x < FW and 0 <= y < FH:
            self.mask[y, x] = False; self.mat[y, x] = -1


class Canvas:
    def __init__(self):
        self.mat = np.full((FH, FW), -1, int)
        self.sh = np.zeros((FH, FW), int)

    def comp(self, L, inner=True):
        """Paste a layer; where its 4-neighbour ring lands on already-filled pixels,
        draw that ring in the layer's darkest shade (an inner contour line)."""
        if inner:
            ring_mat = np.full((FH, FW), -1, int)
            for dx, dy in ((0, -1), (-1, 0), (1, 0), (0, 1)):
                sm = np.roll(np.roll(L.mat, dy, 0), dx, 1)
                ok = np.roll(np.roll(L.mask, dy, 0), dx, 1)
                if dy == 1: ok[0, :] = False
                if dy == -1: ok[-1, :] = False
                if dx == 1: ok[:, 0] = False
                if dx == -1: ok[:, -1] = False
                sel = ok & (ring_mat < 0)
                ring_mat[sel] = sm[sel]
            ring = (ring_mat >= 0) & ~L.mask & (self.mat >= 0)
            self.mat[ring] = ring_mat[ring]; self.sh[ring] = 0
        self.mat[L.mask] = L.mat[L.mask]; self.sh[L.mask] = L.sh[L.mask]

    def outline(self):
        filled = self.mat >= 0
        add = np.full((FH, FW), -1, int)
        # priority: pixel below, then sides, then above (same order as gen_sprites.py)
        for dx, dy in ((0, 1), (1, 0), (-1, 0), (0, -1)):
            for y in range(FH):
                for x in range(FW):
                    if filled[y, x] or add[y, x] >= 0:
                        continue
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < FW and 0 <= ny < FH and filled[ny, nx]:
                        add[y, x] = self.mat[ny, nx]
        sel = add >= 0
        self.mat[sel] = add[sel]; self.sh[sel] = 0

    def image(self):
        rgba = np.zeros((FH, FW, 4), np.uint8)
        for y in range(FH):
            for x in range(FW):
                m = self.mat[y, x]
                if m >= 0:
                    rgba[y, x, :3] = PAL[MATS[m]][self.sh[y, x]]; rgba[y, x, 3] = 255
        return Image.fromarray(rgba, "RGBA")


# ---------------------------------------------------------------- shading helpers
class Light:
    def __init__(self, mirror=False):
        v = np.array([-0.55, -0.68, 0.48])
        if mirror:
            v[0] = -v[0]
        self.v = v / np.linalg.norm(v)
        self.m = mirror

    def dot(self, nx, ny, nz):
        return nx * self.v[0] + ny * self.v[1] + nz * self.v[2]


def quant(v, lo, hi, a=-0.25, b=0.95):
    """Map lighting value v into integer shades lo..hi."""
    t = np.clip((v - a) / (b - a), 0, 0.999)
    return lo + (t * (hi - lo + 1)).astype(int)


def ellipse(cx, cy, rx, ry):
    dx = (PX - cx) / rx; dy = (PY - cy) / ry
    r2 = dx * dx + dy * dy
    nz = np.sqrt(np.clip(1 - r2, 0, 1))
    return r2 < 1.0, dx, dy, nz


def segment(p0, p1, r):
    """Capsule mask around segment p0-p1 with radius r, plus cylinder normals."""
    (x0, y0), (x1, y1) = p0, p1
    vx, vy = x1 - x0, y1 - y0
    ll = max(vx * vx + vy * vy, 1e-6)
    t = np.clip(((PX - x0) * vx + (PY - y0) * vy) / ll, 0, 1)
    qx, qy = x0 + t * vx - PX, y0 + t * vy - PY
    dx, dy = -qx / r, -qy / r
    d2 = dx * dx + dy * dy
    return d2 < 1.0, dx, dy, np.sqrt(np.clip(1 - d2, 0, 1))


def rect(x0, y0, x1, y1):
    """Inclusive pixel rectangle."""
    return (XX >= x0) & (XX <= x1) & (YY >= y0) & (YY <= y1)


def hair_locks(lay, region, x0, x1, y_start, hy, dx=0, width=3):
    """Clustered vertical locks: each lock is `width` px wide, its right column a shade
    darker (light from the left) below y_start, its left column a shade lighter."""
    for y in range(y_start + hy, FH):
        for x in range(x0 + dx, x1 + dx + 1):
            if not (region[y, x] and lay.mat[y, x] == MI["hair"]):
                continue
            k = (x - dx - x0) % width
            if k == width - 1:
                lay.sh[y, x] = max(1, lay.sh[y, x] - 1)
            elif k == 0 and y > y_start + hy + 1:
                lay.sh[y, x] = min(4, lay.sh[y, x] + 1)


# ---------------------------------------------------------------- poses
# legs: (forward offset, lift) for leg A and B. A = screen-left leg (front/back views) or the
# near leg (side view). Arms: swing in -1..1 (+ = forward) for arm A and B. b = body bob.
POSES = [
    dict(b=0, A=(1, 0), B=(-1, 0), aA=0.0, aB=0.0),     # 0 idle
    dict(b=0, A=(4, 0), B=(-4, 0), aA=-1.0, aB=1.0),    # 1 contact (A forward)
    dict(b=1, A=(2, 0), B=(-3, 1), aA=-0.6, aB=0.6),    # 2 down
    dict(b=0, A=(-1, 0), B=(1, 3), aA=-0.1, aB=0.1),    # 3 passing (B swings through)
    dict(b=0, A=(-4, 0), B=(4, 0), aA=1.0, aB=-1.0),    # 4 contact (B forward)
    dict(b=1, A=(-3, 1), B=(2, 0), aA=0.6, aB=-0.6),    # 5 down
    dict(b=0, A=(1, 3), B=(-1, 0), aA=0.1, aB=-0.1),    # 6 passing (A swings through)
    dict(b=0, A=(3, 0), B=(-3, 0), aA=0, aB=0, tool=True),  # 7 tool swing
]

# columns 8..11, player sheet only (make_sheet() defaults to POSES, which gen_npcs.py shares)
FISH_POSES = [dict(fish="wind"), dict(fish="cast"), dict(fish="reel_a"), dict(fish="reel_b")]

# columns 12..20, per-tool body poses (see TOOL_FRONT / TOOL_SIDE below)
TOOL_POSES = [dict(work=k) for k in ("heavy_wind", "heavy_strike", "heavy_recover",
                                     "hoe_reach", "hoe_chop", "hoe_drag", "can_hold", "can_pour", "bow")]


# ================================================================ front / back views
def leg_front(cv, L, side, fwd, lift, b, back_view, wide=0):
    """side -1 = screen-left leg, +1 = screen-right. Pants then boot, lit as cylinders."""
    lay = Layer()
    hip_y = 36 + b
    # a leg striding toward the camera reads slightly lower/larger; away reads higher.
    toward = fwd if not back_view else -fwd
    foot = GROUND - lift - (1 if toward <= -3 else 0)
    inward = 1 if lift >= 2 else 0
    spread = 1 if toward >= 3 else 0  # striding leg swings slightly outward
    x0 = (11 if side < 0 else 17) + side * (spread + wide) + (inward if side < 0 else -inward)
    top_boot = foot - 3
    # a wide (braced) stance slants the leg from the usual hip out to the planted boot
    pm, pdx, pdy, pnz = segment((x0 + 2.0 - side * wide, hip_y), (x0 + 2.0, top_boot + 0.5), 2.0)
    pm &= (YY >= hip_y) & (YY < top_boot) & (XX >= x0 - (wide if side > 0 else 0)) & (XX <= x0 + 3 + (wide if side < 0 else 0))
    lay.paint(pm, "pants", quant(L.dot(pdx, -0.15, pnz), 1, 3))
    # boot: 5 wide at the bottom two rows (toe spreads), 4 wide above
    bx0 = x0 - (1 if side < 0 else 0)
    bm = rect(x0, top_boot, x0 + 3, foot) | rect(bx0, foot - 1, bx0 + 4, foot)
    bdx = (PX - (bx0 + 2.5)) / 2.6
    bdy = (PY - (top_boot + 1.5)) / 3.0
    bs = quant(L.dot(bdx, bdy, np.sqrt(np.clip(1 - bdx ** 2, 0, 1))), 1, 3)
    if back_view:
        bs = np.where(YY == foot, 1, bs)  # heel/sole darker from behind
    else:
        bs = np.where((YY == foot - 1) & (abs(PX - (bx0 + 2.5)) < 1.6), np.minimum(bs + 1, 3), bs)  # toe cap
    lay.paint(bm, "boots", bs)
    cv.comp(lay)


def torso_front(cv, L, b, back_view, dx=0):
    lay = Layer()
    y0, y1 = 25 + b, 35 + b
    m = rect(10 + dx, y0, 21 + dx, y1)
    m &= ~(rect(10 + dx, y0, 10 + dx, y0) | rect(21 + dx, y0, 21 + dx, y0))  # round shoulders
    nx = (PX - (CX + dx)) / 6.6
    ny = np.clip((PY - (y0 + 4.0)) / 9.0, -0.6, 0.4)
    nz = np.sqrt(np.clip(1 - nx * nx, 0.05, 1))
    s = quant(L.dot(nx, ny, nz), 1, 4, -0.2, 0.95)
    # skirt below the belt sits a little in shadow, with a centre fold
    s = np.where(YY >= 34 + b, np.maximum(1, s - 1), s)
    fold = rect(15 + dx, 34 + b, 15 + dx, y1)
    s = np.where(fold, 1, s)
    lay.paint(m, "tunic", s)
    # belt
    bm = rect(10 + dx, 32 + b, 21 + dx, 33 + b)
    lay.paint(bm, "belt", np.where(YY == 32 + b, 2, 1))
    if not back_view:
        bx = 15 + dx
        lay.put(bx, 32 + b, "gold", 3); lay.put(bx + 1, 32 + b, "gold", 2)
        lay.put(bx, 33 + b, "gold", 2); lay.put(bx + 1, 33 + b, "gold", 1)
    cv.comp(lay)


def arm_front(cv, L, side, swing, b, back_view, dx=0):
    lay = Layer()
    sx = (8.5 if side < 0 else 23.5) + dx
    toward = swing if not back_view else -swing
    # arm swinging toward the camera drops 1px and tucks in; swinging away it shortens.
    length = 6.3 + (1 if toward > 0.5 else 0) - (2 if toward < -0.5 else (1 if toward < -0.2 else 0))
    hx = sx - side * (0.6 if toward > 0.5 else 0)
    p0, p1 = (sx, 26.5 + b), (hx, 26.5 + b + length)
    m, ndx, ndy, nz = segment(p0, p1, 1.55)
    m &= YY >= 25 + b
    lay.paint(m, "tunic", quant(L.dot(ndx, ndy * 0.3 - 0.2, nz), 1, 4, -0.3, 0.9))
    hm, hdx, hdy, hnz = ellipse(hx, p1[1] + 1.6, 1.6, 1.7)
    hs = quant(L.dot(hdx, hdy, hnz), 1, 4, -0.3, 0.9)
    if toward < -0.5:
        hs = np.maximum(1, hs - 1)
    lay.paint(hm, "skin", hs)
    cv.comp(lay)


def arm_raised_front(cv, L, side, b, dx=0):
    """Tool swing, front/back view: arm goes up beside the head, hands meet overhead."""
    lay = Layer()
    sx = (8.5 if side < 0 else 23.5) + dx
    elbow = ((7.5 if side < 0 else 24.5) + dx, 17.5 + b)
    hand = ((14.2 if side < 0 else 17.8) + dx, 8.8 + b)
    for p0, p1 in (((sx, 27.0 + b), elbow), (elbow, hand)):
        m, ndx, ndy, nz = segment(p0, p1, 1.5)
        lay.paint(m, "tunic", quant(L.dot(ndx, ndy, nz), 1, 4, -0.3, 0.9))
    hm, hdx, hdy, hnz = ellipse(hand[0], hand[1] - 0.6, 1.6, 1.6)
    lay.paint(hm, "skin", quant(L.dot(hdx, hdy, hnz), 1, 4, -0.3, 0.9))
    cv.comp(lay)


def head_front(cv, L, b, dx=0):
    hy = b
    cx = CX + dx
    # ears (behind the hair mass)
    ears = Layer()
    for ex in (8 + dx, 23 + dx):
        for y in (18, 19, 20):
            ears.put(ex, y + hy, "skin", 2 if (y == 19) else (3 if y == 18 else 1))
    cv.comp(ears)

    lay = Layer()
    m, ndx, ndy, nz = ellipse(cx, 18.6 + hy, 7.05, 7.7)
    hair_s = quant(L.dot(ndx, ndy, nz), 1, 4, -0.15, 0.95)
    lay.paint(m, "hair", hair_s)
    # face: rounded rectangle inside the hair
    face = rect(10 + dx, 15 + hy, 21 + dx, 21 + hy) & m
    face &= ~(rect(10 + dx, 15 + hy, 10 + dx, 15 + hy) | rect(21 + dx, 15 + hy, 21 + dx, 15 + hy))
    fdx = (PX - cx) / 7.0; fdy = (PY - (18.5 + hy)) / 6.0
    fs = quant(L.dot(fdx, fdy, np.sqrt(np.clip(1 - fdx ** 2 - fdy ** 2 * 0.5, 0.05, 1))), 1, 4, -0.1, 0.9)
    lay.paint(face, "skin", fs)
    # fringe: hair hangs over the forehead with a parting (clustered locks)
    for x in range(10, 22):
        fy = 15 + hy + (1 if x in (12, 13, 14, 19, 20) else 0) + (1 if x in (13,) else 0)
        for y in range(15 + hy, fy + 1):
            lay.put(x + dx, y, "hair", 3 if x < 16 else 2)
    for x in (10, 21):  # sideburns hug the face
        for y in range(16, 21):
            lay.put(x + dx, y + hy, "hair", 2 if x == 10 else 1)
    # beard: chunky, rounded, covers the lower face and spills onto the chest
    bm, bdx, bdy, bnz = ellipse(cx, 22.4 + hy, 6.6, 5.7)
    bm &= (YY >= 21 + hy) | (abs(PX - cx) > 4.5) & (YY >= 19 + hy)
    bm &= YY >= 19 + hy
    bs = quant(L.dot(bdx, bdy, bnz), 1, 4, -0.2, 0.95)
    lay.paint(bm, "hair", bs)
    # beard locks: two darker clustered strands toward the bottom
    for (x, y) in ((13, 25), (13, 26), (18, 25), (18, 26), (16, 27), (15, 27)):
        if lay.mask[y + hy, x + dx]:
            lay.put(x + dx, y + hy, "hair", max(1, lay.sh[y + hy, x + dx] - 1))
    # moustache (lighter, sits on the beard)
    for x in range(12, 20):
        lay.put(x + dx, 21 + hy, "hair", 4 if x < 15 else 3)
    lay.put(12 + dx, 22 + hy, "hair", 3); lay.put(19 + dx, 22 + hy, "hair", 2)
    # mouth
    lay.put(15 + dx, 23 + hy, "skin", 1); lay.put(16 + dx, 23 + hy, "skin", 1)
    # eyes: 2x2, white highlight top-left
    for ex in (12, 18):
        lay.put(ex + dx, 18 + hy, "eye", 2); lay.put(ex + 1 + dx, 18 + hy, "eye", 1)
        lay.put(ex + dx, 19 + hy, "eye", 1); lay.put(ex + 1 + dx, 19 + hy, "eye", 1)
    # brows
    for x in (12, 13, 18, 19):
        lay.put(x + dx, 17 + hy, "hair", 1)
    # nose: lit left side, shadow on the right and beneath
    lay.put(15 + dx, 19 + hy, "skin", 4); lay.put(15 + dx, 20 + hy, "skin", 3)
    lay.put(16 + dx, 20 + hy, "skin", 1); lay.put(16 + dx, 19 + hy, "skin", 2)
    # cheek warmth
    lay.put(11 + dx, 20 + hy, "skin", 2); lay.put(20 + dx, 20 + hy, "skin", 2)
    # hair top highlight cluster
    for (x, y) in ((12, 12), (13, 12), (11, 13), (12, 13), (14, 13)):
        if lay.mat[y + hy, x + dx] == MI["hair"]:
            lay.put(x + dx, y + hy, "hair", 4)
    cv.comp(lay)


def head_back(cv, L, b, dx=0):
    hy = b
    cx = CX + dx
    ears = Layer()
    for ex in (8 + dx, 23 + dx):
        for y in (18, 19, 20):
            ears.put(ex, y + hy, "skin", 2 if (y != 20) else 1)
    cv.comp(ears)
    # beard edges poke out at the jaw on both sides
    bl = Layer()
    for x, ys in ((9, (22, 23, 24)), (10, (23, 24, 25, 26)), (21, (23, 24, 25, 26)), (22, (22, 23, 24))):
        for y in ys:
            bl.put(x + dx, y + hy, "hair", 2 if x < 16 else 1)
    cv.comp(bl)
    lay = Layer()
    m, ndx, ndy, nz = ellipse(cx, 18.4 + hy, 7.05, 7.5)
    s = quant(L.dot(ndx, ndy, nz), 1, 4, -0.2, 0.95)
    lay.paint(m, "hair", s)
    hair_locks(lay, m, 9, 22, 15, hy, dx, 3)
    # scalloped lock tips along the nape, then a sliver of neck
    for x in range(10, 22):
        if (x - 10) % 3 == 1:
            lay.put(x + dx, 25 + hy, "hair", 1)
    for x in range(13, 19):
        lay.put(x + dx, 26 + hy, "skin", 2 if x < 16 else 1)
    # crown: swirl highlight cluster top-left, parting line
    for (x, y) in ((12, 13), (13, 13), (14, 12), (11, 14), (12, 14), (15, 12), (13, 14)):
        lay.put(x + dx, y + hy, "hair", 4)
    for (x, y) in ((16, 13), (17, 14)):
        lay.put(x + dx, y + hy, "hair", 2)
    cv.comp(lay)


def draw_front(L, pose, back_view):
    cv = Canvas()
    b = pose["b"]
    tool = pose.get("tool", False)
    if tool:
        b = 0 if back_view else 1  # lean toward camera (front) / away (back)
        lean = -1 if back_view else 0
    else:
        lean = 0
    tb = b + lean
    for side, key in ((-1, "A"), (1, "B")):
        fwd, lift = pose[key]
        if tool:
            fwd, lift = 0, 0
        leg_front(cv, L, side, fwd, lift, b if not tool else 0, back_view)
    torso_front(cv, L, tb if not tool else max(tb, 0), back_view)
    if not tool:
        arm_front(cv, L, -1, pose["aA"], b, back_view)
        arm_front(cv, L, 1, pose["aB"], b, back_view)
    (head_back if back_view else head_front)(cv, L, tb)
    if tool:
        arm_raised_front(cv, L, -1, tb); arm_raised_front(cv, L, 1, tb)
    cv.outline()
    return cv


# ================================================================ side view (faces right)
def leg_side(cv, L, fwd, lift, b, far, planted=False):
    lay = Layer()
    d = -1 if far else 0
    hip = (CX + 0.2 + (-0.8 if far else 0.4), 36.0 + b)
    foot = GROUND - lift
    ankle = (CX + fwd + (-0.8 if far else 0.4), foot - 2.5)
    # knee bends forward when the foot is lifted
    knee = ((hip[0] + ankle[0]) / 2 + (1.2 if lift >= 2 else 0.3 if lift else 0), (hip[1] + ankle[1]) / 2)
    for p0, p1 in ((hip, knee), (knee, ankle)):
        m, ndx, ndy, nz = segment(p0, p1, 1.9)
        m &= YY >= 35 + b
        lay.paint(m, "pants", np.maximum(1, quant(L.dot(ndx, ndy, nz), 1, 3, -0.3, 0.8) + d))
    # boot: heel at ankle, toe 2px forward; back foot on contact rolls onto the toe
    ax = int(math.floor(ankle[0]))
    heel_up = fwd <= -3 and lift == 0 and not planted
    bm = rect(ax - 2, foot - 2, ax + 1, foot) | rect(ax + 2, foot - 1, ax + 3, foot)
    if heel_up:
        bm = rect(ax - 2, foot - 2, ax + 1, foot - 1) | rect(ax, foot, ax + 3, foot)
    lay.erase(0, 0)
    bdx = (PX - (ax + 0.5)) / 3.0; bdy = (PY - (foot - 2.0)) / 3.0
    bs = quant(L.dot(bdx, bdy, np.sqrt(np.clip(1 - bdx ** 2, 0.05, 1))), 1, 3, -0.3, 0.8)
    bs = np.where(YY == foot, 1, bs)  # sole
    lay.paint(bm, "boots", np.maximum(1, bs + d))
    cv.comp(lay)


def arm_side(cv, L, swing, b, far, lean=0):
    lay = Layer()
    d = -1 if far else 0
    sh = (CX + 0.5 + lean + (-1.0 if far else 0), 27.5 + b)
    a = swing * math.radians(38)
    ln = 6.8
    hand = (sh[0] + math.sin(a) * ln, sh[1] + math.cos(a) * ln)
    m, ndx, ndy, nz = segment(sh, hand, 1.6)
    m &= YY >= 25 + b
    lay.paint(m, "tunic", np.maximum(1, quant(L.dot(ndx, ndy, nz), 1, 4, -0.3, 0.9) + d))
    hm, hdx, hdy, hnz = ellipse(hand[0] + math.sin(a) * 1.4, hand[1] + math.cos(a) * 1.4, 1.6, 1.6)
    lay.paint(hm & ~m, "skin", np.maximum(1, quant(L.dot(hdx, hdy, hnz), 1, 4, -0.3, 0.9) + d))
    cv.comp(lay)


def arm_side_raised(cv, L, b, far, lean):
    lay = Layer()
    d = -1 if far else 0
    sh = (CX + 0.5 + lean + (-1.0 if far else 0), 27.5 + b)
    elbow = (sh[0] + 6.0, sh[1] - 4.0)
    hand = (sh[0] + 8.5 + (0.6 if far else 0), sh[1] - 11.0)
    for p0, p1 in ((sh, elbow), (elbow, hand)):
        m, ndx, ndy, nz = segment(p0, p1, 1.55)
        lay.paint(m, "tunic", np.maximum(1, quant(L.dot(ndx, ndy, nz), 1, 4, -0.3, 0.9) + d))
    hm, hdx, hdy, hnz = ellipse(hand[0] + 0.4, hand[1] - 1.3, 1.6, 1.6)
    lay.paint(hm, "skin", np.maximum(1, quant(L.dot(hdx, hdy, hnz), 1, 4, -0.3, 0.9) + d))
    cv.comp(lay)


def torso_side(cv, L, b, lean=0, shear=0):
    """lean shifts the whole torso; shear tips it (shoulders move `shear` px, the belt stays put)."""
    lay = Layer()
    y0, y1 = 25 + b, 35 + b
    # back edge straight-ish, belly bulges forward around the belt
    m = np.zeros((FH, FW), bool)
    for y in range(y0, y1 + 1):
        r = y - y0
        x0 = 11 + (1 if r == 0 else 0)
        x1 = 20 + (1 if 3 <= r <= 9 else 0) + (1 if 5 <= r <= 7 else 0) - (1 if r == 0 else 0)
        tip = int(round(shear * max(0, 7 - r) / 7.0))
        m |= rect(x0 + lean + tip, y, x1 + lean + tip, y)
    nx = (PX - (CX + lean)) / 5.5
    ny = np.clip((PY - (y0 + 4.0)) / 9.0, -0.6, 0.4)
    nz = np.sqrt(np.clip(1 - nx * nx, 0.05, 1))
    s = quant(L.dot(nx, ny, nz), 1, 4, -0.2, 0.95)
    s = np.where(YY >= 34 + b, np.maximum(1, s - 1), s)
    lay.paint(m, "tunic", s)
    bm = m & ((YY == 32 + b) | (YY == 33 + b))
    lay.paint(bm, "belt", np.where(YY == 32 + b, 2, 1))
    # buckle peeks out at the front edge
    fx = int(np.max(np.nonzero(m[32 + b])[0]))
    lay.put(fx, 32 + b, "gold", 3); lay.put(fx, 33 + b, "gold", 2)
    lay.put(fx - 1, 32 + b, "gold", 2); lay.put(fx - 1, 33 + b, "gold", 1)
    cv.comp(lay)


def head_side(cv, L, b, lean=0):
    hy = b
    ox = lean
    lay = Layer()
    m, ndx, ndy, nz = ellipse(CX - 0.3 + ox, 18.5 + hy, 6.9, 7.6)
    lay.paint(m, "hair", quant(L.dot(ndx, ndy, nz), 1, 4, -0.15, 0.95))
    # face block on the front of the head
    face = np.zeros((FH, FW), bool)
    rows = {15: (17, 21), 16: (16, 22), 17: (16, 22), 18: (16, 22), 19: (16, 22), 20: (16, 22), 21: (17, 22)}
    for y, (a, c) in rows.items():
        face |= rect(a + ox, y + hy, c + ox, y + hy)
    fdx = (PX - (CX + ox - 1)) / 7.0; fdy = (PY - (18.5 + hy)) / 6.0
    fs = quant(L.dot(fdx * 0.6, fdy, np.sqrt(np.clip(1 - fdx ** 2 * 0.3 - fdy ** 2 * 0.5, 0.05, 1))), 1, 4, -0.25, 0.8)
    lay.paint(face, "skin", fs)
    # nose juts out past the face
    lay.put(23 + ox, 19 + hy, "skin", 3); lay.put(23 + ox, 20 + hy, "skin", 2)
    lay.put(22 + ox, 19 + hy, "skin", 4)
    # fringe over brow
    for x in range(15, 22):
        lay.put(x + ox, 15 + hy, "hair", 3 if x < 19 else 2)
    lay.put(16 + ox, 16 + hy, "hair", 2); lay.put(17 + ox, 16 + hy, "hair", 3)
    # eye + brow
    lay.put(20 + ox, 18 + hy, "eye", 1); lay.put(20 + ox, 19 + hy, "eye", 1)
    lay.put(19 + ox, 17 + hy, "hair", 1); lay.put(20 + ox, 17 + hy, "hair", 1); lay.put(21 + ox, 17 + hy, "hair", 1)
    # ear in the hair, with sideburn in front of it
    lay.put(14 + ox, 18 + hy, "skin", 3); lay.put(14 + ox, 19 + hy, "skin", 2); lay.put(14 + ox, 20 + hy, "skin", 1)
    lay.put(13 + ox, 19 + hy, "skin", 2); lay.put(13 + ox, 18 + hy, "skin", 2)
    for y in range(16, 22):
        lay.put(15 + ox, y + hy, "hair", 2)
    # beard: from the sideburn down the jaw, jutting forward and down past the chin
    beard = np.zeros((FH, FW), bool)
    brows = {20: (15, 16), 21: (15, 17), 22: (14, 23), 23: (14, 24), 24: (14, 24), 25: (14, 24),
             26: (15, 23), 27: (16, 22), 28: (18, 21)}
    for y, (a, c) in brows.items():
        beard |= rect(a + ox, y + hy, c + ox, y + hy)
    bdx = (PX - (CX + 2.5 + ox)) / 6.0; bdy = (PY - (23.5 + hy)) / 5.0
    bs = quant(L.dot(bdx, bdy, np.sqrt(np.clip(1 - bdx ** 2 - bdy ** 2 * 0.6, 0.05, 1))), 1, 4, -0.2, 0.95)
    lay.paint(beard, "hair", bs)
    # moustache under the nose
    for x in (20, 21, 22, 23):
        lay.put(x + ox, 21 + hy, "hair", 4 if x < 22 else 3)
    lay.put(23 + ox, 22 + hy, "hair", 3)
    # mouth hint, beard strands
    lay.put(22 + ox, 23 + hy, "skin", 1)
    for (x, y) in ((17, 25), (17, 26), (20, 26), (20, 27), (22, 25)):
        if lay.mask[y + hy, x + ox]:
            lay.put(x + ox, y + hy, "hair", max(1, lay.sh[y + hy, x + ox] - 1))
    # hair: back locks + crown highlight
    hair_locks(lay, m & (XX <= 14 + ox), 9, 14, 15, hy, ox, 3)
    for (x, y) in ((12, 12), (13, 12), (14, 12), (11, 13), (12, 13)):
        lay.put(x + ox, y + hy, "hair", 4)
    cv.comp(lay)


def draw_side(L, pose):
    cv = Canvas()
    b = pose["b"]
    tool = pose.get("tool", False)
    lean = 1 if tool else 0
    # far leg/arm first (darker), then torso, then near leg, then head, near arm in front
    fA, lA = pose["A"]; fB, lB = pose["B"]
    if tool:
        arm_side_raised(cv, L, b, True, lean)
    else:
        arm_side(cv, L, pose["aB"], b, True)
    leg_side(cv, L, fB, lB, b, True)
    leg_side(cv, L, fA, lA, b, False)
    torso_side(cv, L, b, lean)
    head_side(cv, L, b, lean * 2)
    if tool:
        arm_side_raised(cv, L, b, False, lean)
    else:
        arm_side(cv, L, pose["aA"], b, False)
    cv.outline()
    return cv


# ================================================================ fishing poses
def bent_arm(cv, L, sh, elbow, hand, far=False, hand_r=1.6, r=1.55):
    """Two-bone arm (shoulder, elbow, hand); hand=None draws the sleeve only."""
    d = -1 if far else 0
    lay = Layer()
    sleeve = np.zeros((FH, FW), bool)
    pts = [sh, elbow] + ([hand] if hand else [])
    for p0, p1 in zip(pts, pts[1:]):
        m, ndx, ndy, nz = segment(p0, p1, r)
        lay.paint(m, "tunic", np.maximum(1, quant(L.dot(ndx, ndy, nz), 1, 4, -0.3, 0.9) + d))
        sleeve |= m
    cv.comp(lay)
    if hand:
        fist(cv, L, hand, far, hand_r)


def fist(cv, L, at, far=False, r=1.6):
    lay = Layer()
    hm, hdx, hdy, hnz = ellipse(at[0], at[1], r, r)
    lay.paint(hm, "skin", np.maximum(1, quant(L.dot(hdx, hdy, hnz), 1, 4, -0.3, 0.9) + (-1 if far else 0)))
    cv.comp(lay)


def draw_front_fish(L, kind, back_view):
    """Front (facing the camera) and back views. The rod side is screen-right in both.
    Leaning toward the camera moves head/shoulders down; leaning away moves them up."""
    cv = Canvas()
    reel = kind.startswith("reel")
    k = 1 if kind == "reel_b" else 0
    toward_cam = {"wind": -1, "cast": 1, "reel_a": -1, "reel_b": -1}[kind] * (-1 if back_view else 1)
    if kind == "wind":
        hb, tb = (2, 1) if back_view else (-1, 0)
    elif kind == "cast":
        hb, tb = (-1, 0) if back_view else (3, 1)
    else:  # leaning back, with a 1px bob on B
        hb, tb = ((1, 0) if back_view else (0, 0))
        hb, tb = hb + k, tb + k
    wide = 2 if reel else 1
    for side in (-1, 1):
        fwd = 0
        if not reel:  # one foot steps toward the cast
            fwd = (3 if side < 0 else -3) * (1 if toward_cam else 0)
            if back_view:
                fwd = -fwd
        leg_front(cv, L, side, fwd, 0, 0, back_view, wide)

    ls, rs = (9.0, 26.8 + tb), (23.0, 26.8 + tb)

    if kind == "cast" and back_view:
        # arms reach away from the camera: drawn behind body and head, fists past the shoulders
        bent_arm(cv, L, ls, (5.6, 28.0), (6.0, 22.6))
        bent_arm(cv, L, rs, (26.4, 28.0), (26.0, 22.6))
    if reel and back_view:
        # hands are in front of the body: elbows poke out, the rod fist peeks past the right hip
        bent_arm(cv, L, ls, (7.2 - k * 0.6, 31.6 + tb), (13.0, 33.0))
        bent_arm(cv, L, rs, (26.2 + k, 30.4 + tb - k), (23.2, 33.4 - k), hand_r=2.0)

    torso_front(cv, L, tb, back_view)

    if kind == "wind" and not back_view:
        # hands go back over the right shoulder, behind the head
        bent_arm(cv, L, ls, (7.0, 18.0), (21.0, 9.6), far=True)
        bent_arm(cv, L, rs, (27.4, 20.0), (25.6, 11.4))
        fist(cv, L, (23.6, 10.0))

    (head_back if back_view else head_front)(cv, L, hb)

    if kind == "wind" and back_view:
        # behind the character is toward the camera: arms cross over the right shoulder
        bent_arm(cv, L, ls, (11.0, 32.0), (22.6, 24.6))
        bent_arm(cv, L, rs, (28.0, 29.0), (26.0, 23.4), hand_r=2.0)
    elif kind == "cast" and not back_view:
        # thrust at the camera and down: fists low, together, drawn a little larger
        bent_arm(cv, L, (8.8, 28.0), (8.4, 33.0), (14.2, 36.6), hand_r=2.1, r=1.7)
        bent_arm(cv, L, (23.2, 28.0), (23.6, 33.0), (17.8, 36.6), hand_r=2.1, r=1.7)
    elif reel and not back_view:
        # both fists on the grip, right of centre; B cranks the right elbow out and up
        bent_arm(cv, L, ls, (8.0, 31.6 + tb), (17.4 + k, 32.6 + k * 0.6))
        bent_arm(cv, L, rs, (25.4 + k, 31.2 + tb - k * 1.6), (21.0, 32.6 - k), hand_r=1.8)
    cv.outline()
    return cv


# side view per pose: head offset, torso (shift, tip), bob, feet (near, far),
# near arm (elbow, hand), far arm (elbow, hand); arm points are absolute pixels, facing right
SIDE_FISH = {
    "wind": dict(head=-3, torso=(-1, -2), b=0, feet=(4, -3),
                 near=((8.0, 23.0), (4.8, 15.0)), far=((20.0, 20.0), (6.0, 12.4))),
    "cast": dict(head=3, torso=(0, 3), b=1, feet=(5, -4),
                 near=((20.5, 33.0), (27.0, 34.6)), far=((25.0, 29.0), (29.0, 32.0))),
    "reel_a": dict(head=-3, torso=(-1, -2), b=0, feet=(5, -5),
                   near=((11.0, 32.4), (21.6, 32.8)), far=((17.0, 33.0), (23.6, 31.6))),
    "reel_b": dict(head=-3, torso=(-1, -2), b=1, feet=(5, -5),
                   near=((9.4, 31.6), (20.6, 31.8)), far=((17.0, 33.0), (23.4, 33.0))),
}


def draw_side_fish(L, kind):
    cv = Canvas()
    p = SIDE_FISH[kind]
    b = p["b"]
    shift, tip = p["torso"]
    sx = CX + 0.5 + shift + tip
    near_sh, far_sh = (sx - 0.5, 27.8 + b), (sx + 0.5, 27.8 + b)
    bent_arm(cv, L, far_sh, *p["far"], far=True)
    planted = kind.startswith("reel")
    leg_side(cv, L, p["feet"][1], 0, 0, True, planted)
    leg_side(cv, L, p["feet"][0], 0, 0, False, planted)
    torso_side(cv, L, b, shift, tip)
    head_side(cv, L, b, p["head"])
    if kind == "wind":   # both hands on the grip behind the head
        fist(cv, L, p["far"][1], far=True)
    bent_arm(cv, L, near_sh, *p["near"], hand_r=1.8)
    cv.outline()
    return cv


# ================================================================ per-tool body poses
# front/back: hb = head offset, tb = torso offset, wide = braced stance, then left/right arm as
# (elbow, hand) in frame pixels (hand None = sleeve only, the fist is hidden). under = arms drawn
# behind the body (back view reaching away from the camera, or fists hidden in front of the chest).
def arms(le, lh, re, rh, hb=0, tb=0, wide=1, under=False):
    return dict(l=(le, lh), r=(re, rh), hb=hb, tb=tb, wide=wide, under=under)


TOOL_FRONT = {
    "heavy_wind": arms((5.4, 17.0), (13.8, 8.0), (26.6, 17.0), (18.2, 8.0), hb=-1),
    "heavy_strike": arms((6.6, 35.0), (13.8, 39.0), (25.4, 35.0), (18.2, 39.0), hb=4, tb=2, wide=2),
    "heavy_recover": arms((6.4, 33.0), (13.8, 33.6), (25.6, 33.0), (18.2, 33.6), hb=1, tb=1),
    "hoe_reach": arms((5.6, 29.0), (13.8, 30.6), (26.4, 29.0), (18.2, 30.6), hb=-1),
    "hoe_chop": arms((7.0, 34.6), (13.8, 38.0), (25.0, 34.6), (18.2, 38.0), hb=3, tb=1, wide=2),
    "hoe_drag": arms((4.8, 31.0), (13.8, 35.0), (27.2, 31.0), (18.2, 35.0), hb=2, tb=1),
    "can_hold": arms((8.0, 31.0), None, (26.4, 32.0), (22.0, 33.4), hb=0),
    "can_pour": arms((6.4, 33.0), (15.4, 36.0), (25.6, 33.6), (21.0, 35.4), hb=3, tb=1, wide=2),
    "bow": arms((8.0, 33.0), (15.0, 37.0), (28.0, 29.4), (20.0, 29.6), hb=0, wide=2),
}
TOOL_BACK = {
    "heavy_wind": arms((5.6, 18.4), (13.8, 9.0), (26.4, 18.4), (18.2, 9.0), hb=1),
    "heavy_strike": arms((4.8, 31.0), (9.0, 23.0), (27.6, 29.6), (26.4, 22.4), hb=3, tb=2, wide=2, under=True),
    "heavy_recover": arms((5.2, 31.6), (11.0, 32.0), (28.0, 30.0), (26.4, 28.4), hb=1, tb=1, under=True),
    "hoe_reach": arms((5.6, 28.0), (6.4, 21.4), (26.8, 27.0), (26.4, 19.6), hb=-1, under=True),
    "hoe_chop": arms((4.8, 31.0), (9.0, 23.0), (27.6, 30.0), (26.4, 23.6), hb=3, tb=1, wide=2, under=True),
    "hoe_drag": arms((4.8, 32.0), (11.0, 33.0), (28.0, 31.0), (26.4, 28.6), hb=2, tb=1, under=True),
    "can_hold": arms((7.0, 31.0), None, (28.2, 29.6), (26.6, 26.6), under=True),
    "can_pour": arms((4.8, 31.0), (11.0, 30.0), (28.2, 29.0), (26.6, 24.4), hb=2, tb=1, wide=2, under=True),
    "bow": arms((5.4, 27.0), (6.6, 20.0), (28.4, 29.0), (22.0, 28.6), wide=2, under=True),
}


def draw_front_work(L, kind, back_view):
    cv = Canvas()
    p = (TOOL_BACK if back_view else TOOL_FRONT)[kind]
    hb, tb = p["hb"], p["tb"]
    for side in (-1, 1):
        leg_front(cv, L, side, 0, 0, 0, back_view, p["wide"])
    shoulders = ((9.0, 26.8 + tb), (23.0, 26.8 + tb))

    def draw_arms():
        for sh, key, side in zip(shoulders, ("l", "r"), (-1, 1)):
            elbow, hand = p[key]
            if hand is None:  # idle arm hanging at the side
                arm_front(cv, L, side, 0.0, tb, back_view)
            else:
                bent_arm(cv, L, sh, elbow, hand, hand_r=1.8)

    if p["under"]:
        draw_arms()
    torso_front(cv, L, tb, back_view)
    (head_back if back_view else head_front)(cv, L, hb)
    if not p["under"]:
        draw_arms()
    cv.outline()
    return cv


# side view (faces right): same keys as SIDE_FISH, hb = head drop
TOOL_SIDE = {
    "heavy_wind": dict(head=-2, hb=0, torso=(-1, -2), b=0, feet=(4, -4),
                       near=((9.0, 20.0), (13.6, 8.6)), far=((22.4, 19.6), (15.6, 9.4))),
    "heavy_strike": dict(head=4, hb=4, torso=(0, 4), b=2, feet=(5, -4),
                         near=((20.6, 35.6), (26.8, 37.4)), far=((24.0, 34.0), (28.4, 36.4))),
    "heavy_recover": dict(head=2, hb=2, torso=(0, 2), b=1, feet=(5, -4),
                          near=((17.6, 33.8), (25.4, 32.6)), far=((23.0, 31.6), (27.2, 31.4))),
    "hoe_reach": dict(head=0, hb=0, torso=(0, 0), b=0, feet=(4, -3),
                      near=((20.4, 30.6), (27.0, 25.4)), far=((24.0, 28.6), (28.6, 24.6))),
    "hoe_chop": dict(head=3, hb=3, torso=(0, 3), b=1, feet=(5, -4),
                     near=((19.4, 34.4), (26.2, 35.4)), far=((23.6, 33.0), (27.8, 34.4))),
    "hoe_drag": dict(head=1, hb=2, torso=(-1, 2), b=1, feet=(5, -4),
                     near=((11.4, 32.6), (21.4, 34.0)), far=((19.0, 33.4), (23.4, 33.2))),
    "can_hold": dict(head=0, hb=0, torso=(0, 1), b=0, feet=(3, -3),
                     near=((19.0, 32.8), (26.0, 31.0)), far=None),
    "can_pour": dict(head=3, hb=2, torso=(0, 3), b=1, feet=(5, -4),
                     near=((20.4, 33.4), (27.0, 32.4)), far=((24.0, 32.0), (28.4, 31.4))),
    "bow": dict(head=0, hb=0, torso=(-1, 0), b=0, feet=(5, -4),
                near=((8.2, 26.8), (18.4, 27.6)), far=((23.0, 28.0), (28.8, 27.6))),
}


def draw_side_work(L, kind):
    cv = Canvas()
    p = TOOL_SIDE[kind]
    b = p["b"]
    shift, tip = p["torso"]
    sx = CX + 0.5 + shift + tip * 0.5
    near_sh, far_sh = (sx - 0.5, 27.8 + b), (sx + 0.5, 27.8 + b)
    if p["far"]:
        bent_arm(cv, L, far_sh, *p["far"], far=True)
    else:
        arm_side(cv, L, -0.3, b, True)
    leg_side(cv, L, p["feet"][1], 0, 0, True, True)
    leg_side(cv, L, p["feet"][0], 0, 0, False, True)
    torso_side(cv, L, b, shift, tip)
    head_side(cv, L, p["hb"], p["head"])
    bent_arm(cv, L, near_sh, *p["near"], hand_r=1.8)
    cv.outline()
    return cv


# ================================================================ sheet
def make_sheet(poses=POSES):
    sheet = Image.new("RGBA", (FW * len(poses), FH * 4), (0, 0, 0, 0))
    for row, direction in enumerate(("down", "left", "up", "right")):
        for col, pose in enumerate(poses):
            fish = pose.get("fish")
            work = pose.get("work")
            if direction in ("down", "up"):
                back = direction == "up"
                if work:
                    cv = draw_front_work(Light(), work, back)
                else:
                    cv = draw_front_fish(Light(), fish, back) if fish else draw_front(Light(), pose, back)
                im = cv.image()
            else:  # left: right-facing figure under mirrored light, then flipped
                L = Light(mirror=direction == "left")
                if work:
                    im = draw_side_work(L, work).image()
                else:
                    im = (draw_side_fish(L, fish) if fish else draw_side(L, pose)).image()
                if direction == "left":
                    im = im.transpose(Image.FLIP_LEFT_RIGHT)
            sheet.paste(im, (col * FW, row * FH))
    return sheet


def preview(sheet, path, s=4):
    bg = Image.new("RGBA", (sheet.width * s, sheet.height * s), (96, 150, 72, 255))
    bg.alpha_composite(sheet.resize((sheet.width * s, sheet.height * s), Image.NEAREST))
    bg.save(path)


def main():
    sheet = make_sheet(POSES + FISH_POSES + TOOL_POSES)
    sheet.save(OUT)
    print("wrote", os.path.relpath(OUT, ROOT), sheet.size)
    preview(sheet, PREVIEW)
    print("preview", PREVIEW)


if __name__ == "__main__":
    main()
