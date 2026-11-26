#!/usr/bin/env python3
"""Deep mine sprites (original, CC0): silver/gold ore, Stone Warden boss, rails, mine cart, falling rock.
Same style as gen_cave.py (painterly pixel art, dark 1px outline, light from top-left). Deterministic."""
import math
import random
from PIL import Image, ImageDraw

from gen_cave import OUT, WOOD, IRON, shade, mix, Noise, outline_pass, chunk, save, SPR
import os


# ---------------------------------------------------------------- ores
def _paste_shape(im, pts, fill):
    """Small crystal polygon with its own 1px outline (sits on top of the rock)."""
    layer = Image.new("RGBA", im.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    d.polygon(pts, fill=fill + (255,))
    outline_pass(layer)
    im.alpha_composite(layer)


def _sparkle(im, x, y, core, arm):
    for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        im.putpixel((x + dx, y + dy), arm + (255,))
    im.putpixel((x, y), core + (255,))


def ore_silver():
    sp = {}
    for p in ((9, 21), (14, 24), (22, 22), (18, 18), (12, 17)):
        sp[p] = ((196, 220, 244), (112, 140, 186))
    chunk("cave_ore_silver.png", 53, (92, 96, 116), sp, [])
    path = os.path.join(SPR, "cave_ore_silver.png")
    im = Image.open(path).convert("RGBA")
    light, mid, dark = (238, 248, 255), (176, 206, 240), (104, 134, 188)
    # upright pale crystal shards: (tip x, tip y, base y, half width)
    for tx, ty, by, w in ((11, 10, 17, 1), (17, 7, 18, 2), (23, 13, 19, 1)):
        _paste_shape(im, [(tx, ty), (tx + w, ty + 3), (tx + w, by), (tx - w, by), (tx - w, ty + 3)], mid)
        for y in range(ty + 1, by + 1):
            for x in range(tx - w, tx + w + 1):
                if im.getpixel((x, y))[:3] == mid:
                    if x < tx:
                        im.putpixel((x, y), light + (255,))
                    elif x > tx:
                        im.putpixel((x, y), dark + (255,))
    _sparkle(im, 10, 11, (255, 255, 255), (208, 236, 255))
    _sparkle(im, 21, 24, (255, 255, 255), (186, 218, 252))
    im.putpixel((16, 9), (255, 255, 255, 255))
    save(im, "cave_ore_silver.png")


def ore_gold():
    sp = {}
    for p in ((8, 19), (21, 17), (13, 25), (23, 23), (15, 14)):
        sp[p] = ((246, 196, 50), (176, 118, 24))
    chunk("cave_ore_gold.png", 59, (106, 86, 72), sp, [])
    path = os.path.join(SPR, "cave_ore_gold.png")
    im = Image.open(path).convert("RGBA")
    # round nuggets bulging out of the rock
    for x, y, rx, ry in ((11, 15, 3, 2), (19, 13, 3, 3), (17, 22, 3, 2), (23, 19, 2, 1)):
        layer = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
        d = ImageDraw.Draw(layer)
        d.ellipse([x - rx, y - ry, x + rx, y + ry], fill=(240, 184, 40, 255))
        for yy in range(y - ry, y + ry + 1):
            for xx in range(x - rx, x + rx + 1):
                if layer.getpixel((xx, yy))[3]:
                    t = (xx - x) / rx + (yy - y) / ry
                    if t < -0.55:
                        layer.putpixel((xx, yy), (255, 232, 110, 255))
                    elif t > 0.6:
                        layer.putpixel((xx, yy), (190, 122, 22, 255))
        outline_pass(layer)
        im.alpha_composite(layer)
        im.putpixel((x - 1, y - 1), (255, 252, 200, 255))
    _sparkle(im, 20, 8, (255, 255, 240), (255, 226, 110))
    save(im, "cave_ore_gold.png")


# ---------------------------------------------------------------- Stone Warden
STONE = (112, 102, 100)
STONE_D = (86, 76, 80)
MOSS = [(50, 82, 40), (78, 116, 50), (114, 150, 62)]
AMBER = [(150, 62, 18), (224, 112, 24), (255, 176, 44), (255, 226, 110), (255, 250, 214)]
CRYSTAL = [(42, 106, 124), (78, 172, 184), (170, 238, 232)]
FW, FH = 64, 72


def boulder(im, cx, cy, rx, ry, seed, base=STONE, moss=0):
    """Faceted rock lump with its own outline, lit from top-left."""
    r = random.Random(seed)
    n = 9
    pts = []
    for i in range(n):
        a = 2 * math.pi * i / n + r.uniform(-0.18, 0.18)
        k = r.uniform(0.94, 1.1)
        pts.append((cx + math.cos(a) * rx * k, cy + math.sin(a) * ry * k))
    mask = Image.new("L", im.size, 0)
    ImageDraw.Draw(mask).polygon(pts, fill=255)
    mp = mask.load()
    layer = Image.new("RGBA", im.size, (0, 0, 0, 0))
    lp = layer.load()
    # facet centres give flat tonal planes
    facets = [(cx + r.uniform(-0.8, 0.8) * rx, cy + r.uniform(-0.8, 0.8) * ry, r.uniform(0.93, 1.07))
              for _ in range(7)]
    for y in range(im.height):
        for x in range(im.width):
            if not mp[x, y]:
                continue
            nx, ny = (x - cx) / rx, (y - cy) / ry
            light = -(nx * 0.55 + ny * 0.83)
            fk = min(facets, key=lambda f: (f[0] - x) ** 2 + (f[1] - y) ** 2)[2]
            k = 1.38 if light > 0.55 else 1.17 if light > 0.2 else 0.98 if light > -0.25 else 0.8 if light > -0.65 else 0.66
            c = shade(base, k * fk)
            if r.random() < 0.05:
                c = shade(c, r.choice((0.8, 1.18)))
            lp[x, y] = c + (255,)
    if moss:
        for x in range(im.width):
            top = next((y for y in range(im.height) if mp[x, y]), None)
            if top is None or (x - cx) > rx * 0.55:
                continue
            depth = moss + r.choice((-1, 0, 0, 1, 2 if x % 5 == 0 else 0))
            for i in range(max(0, depth)):
                if top + i < im.height and mp[x, top + i]:
                    col = MOSS[2] if i == 0 else MOSS[1] if i < depth - 1 else MOSS[0]
                    if r.random() < 0.18:
                        col = MOSS[r.randrange(3)]
                    lp[x, top + i] = col + (255,)
    outline_pass(layer)
    im.alpha_composite(layer)


def crack(im, pts, col=(42, 32, 34)):
    ImageDraw.Draw(im).line(pts, fill=col + (255,))


def shard(im, bx, by, tx, ty, w):
    """Crystal spike from base (bx,by) to tip (tx,ty)."""
    layer = Image.new("RGBA", im.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    ang = math.atan2(ty - by, tx - bx) + math.pi / 2
    ox, oy = math.cos(ang) * w, math.sin(ang) * w
    a, b = (bx + ox, by + oy), (bx - ox, by - oy)
    left, right = (a, b) if a[0] < b[0] else (b, a)
    d.polygon([left, (tx, ty), (bx, by)], fill=CRYSTAL[1] + (255,))
    d.polygon([right, (tx, ty), (bx, by)], fill=CRYSTAL[0] + (255,))
    d.line([left, (tx, ty)], fill=CRYSTAL[2] + (255,))
    outline_pass(layer)
    im.alpha_composite(layer)


def glow(im, cx, cy, rad, alpha):
    """Soft amber light: tints the sprite and leaves a faint halo around it."""
    px = im.load()
    for y in range(max(0, cy - rad), min(im.height, cy + rad + 1)):
        for x in range(max(0, cx - rad), min(im.width, cx + rad + 1)):
            t = 1 - math.hypot(x - cx, y - cy) / rad
            if t <= 0:
                continue
            t = (int(t * 4) + 1) / 4.0   # banded, pixel-art friendly
            r, g, b, a = px[x, y]
            if a == 255:
                if (r, g, b) != OUT:
                    px[x, y] = mix((r, g, b), (255, 150, 36), min(0.75, t * alpha / 150.0)) + (255,)
            elif a == 0:
                px[x, y] = (255, 156, 40, int(alpha * t * 0.5))


def core(im, cx, cy, level):
    """level 0 normal, 1 bright (windup/slam), 2 exposed and blazing."""
    d = ImageDraw.Draw(im)
    rx, ry = ((4, 5), (5, 6), (7, 8))[level]
    # jagged socket
    sock = [(cx, cy - ry - 2), (cx + rx, cy - ry + 1), (cx + rx + 2, cy), (cx + rx - 1, cy + ry),
            (cx, cy + ry + 2), (cx - rx, cy + ry - 1), (cx - rx - 2, cy), (cx - rx + 1, cy - ry)]
    d.polygon(sock, fill=(48, 26, 22, 255), outline=OUT)
    cols = (AMBER[0:4], AMBER[1:5], (AMBER[2], AMBER[3], AMBER[4], (255, 255, 244)))[level]
    for i, k in enumerate((1.0, 0.76, 0.5, 0.24)):
        a, b = max(1, round(rx * k)), max(1, round(ry * k))
        ox, oy = -(i // 2), -(i // 2)
        d.polygon([(cx + ox, cy - b + oy), (cx + a + ox, cy + oy), (cx + ox, cy + b + oy),
                   (cx - a + ox, cy + oy)], fill=cols[i] + (255,))
    # glowing fissures running out of the socket
    reach = (3, 5, 7)[level]
    for sx, sy, dx, dy in ((-rx - 2, -1, -1, -1), (rx + 2, 0, 1, -1), (-rx + 1, ry, -1, 1), (rx - 1, ry, 1, 1)):
        x, y = cx + sx, cy + sy
        for i in range(reach):
            xx, yy = x + dx * i, y + dy * ((i + 1) // 2)
            if 0 <= xx < im.width and 0 <= yy < im.height and im.getpixel((xx, yy))[3] == 255:
                im.putpixel((xx, yy), AMBER[2 if i < reach // 2 else 1] + (255,))


def limb(im, p0, p1, rad, seed, base=STONE_D):
    """Upper arm: a stone lump between shoulder and fist."""
    mx, my = (p0[0] + p1[0]) / 2, (p0[1] + p1[1]) / 2
    boulder(im, mx, my, rad, rad + 1, seed, base)


def fist(im, x, y, seed):
    boulder(im, x, y, 9, 8, seed, STONE, moss=0)
    for dx in (-3, 2):                       # knuckle seams
        crack(im, [(x + dx, y + 2), (x + dx, y + 6)])
    im.putpixel((x - 4, y - 4), (178, 168, 150, 255))
    im.putpixel((x - 3, y - 5), (178, 168, 150, 255))


def warden_frame(f):
    im = Image.new("RGBA", (FW, FH), (0, 0, 0, 0))
    # per frame: torso y, head (x,y), fists L/R, elbows L/R, feet lift L/R, core level, eyes
    P = [
        # torso, head,    fistL,    fistR,    elbL,     elbR,     liftL, liftR, core, shoulder dy
        (38, (32, 20), (11, 54), (53, 54), (11, 42), (53, 42), 0, 0, 0, 0),       # idle
        (37, (31, 19), (12, 49), (53, 56), (11, 39), (53, 43), 4, 0, 0, 0),       # walk A
        (37, (33, 19), (11, 56), (52, 49), (11, 43), (53, 39), 0, 4, 0, 0),       # walk B
        (39, (32, 25), (13, 12), (51, 12), (10, 25), (54, 25), 0, 0, 1, -3),      # windup
        (47, (32, 32), (21, 58), (43, 58), (11, 49), (53, 49), 0, 0, 1, 0),       # slam
        (44, (35, 29), (11, 59), (53, 59), (11, 49), (53, 50), 0, 0, 2, 4),       # tired
    ]
    ty, (hx, hy), fl, fr, el, er, ll, lr, lvl, sdy = P[f]
    # contact shadow
    ImageDraw.Draw(im).ellipse([6, 63, 57, 71], fill=(20, 14, 16, 90))
    # back crystals (drawn first so the shoulders overlap their bases)
    sy = ty - 11 + sdy
    shard(im, 18, sy, 9, sy - 14, 3)
    shard(im, 22, sy - 2, 19, sy - 17, 2.5)
    shard(im, 46, sy - 1, 56, sy - 12, 3)
    # legs: short thick stumps, feet bottom at y = 68 (outline row)
    for side, lift, seed in ((-1, ll, 101), (1, lr, 102)):
        x = 32 + side * 11
        top = min(ty + 13, 58)
        boulder(im, x, (top + 62 - lift) / 2, 6, max(4, (62 - lift - top) / 2 + 2), seed, STONE_D)
        boulder(im, x + side * 2, 63 - lift, 8, 4, seed + 5, STONE)
    # square up the soles so the planted feet sit exactly on row 67 with outline on 68
    px = im.load()
    for y in range(68, FH):
        for x in range(FW):
            if px[x, y][3] == 255:
                px[x, y] = (20, 14, 16, 90)
    for side, lift in ((-1, ll), (1, lr)):
        if not lift:
            cx = 32 + side * 13
            d = ImageDraw.Draw(im)
            d.rectangle([cx - 5, 65, cx + 5, 67], fill=shade(STONE, 0.72) + (255,))
            d.line([cx - 5, 68, cx + 5, 68], fill=OUT + (255,))
            d.line([cx - 6, 65, cx - 6, 67], fill=OUT + (255,))
            d.line([cx + 6, 65, cx + 6, 67], fill=OUT + (255,))
    # torso: pelvis + massive chest
    boulder(im, 32, min(ty + 14, 58), 13, 7, 111, STONE_D)
    boulder(im, 32, ty, 19, 17, 112, STONE)
    crack(im, [(19, ty + 3), (22, ty + 6), (21, ty + 10)])
    crack(im, [(45, ty - 2), (43, ty + 3), (46, ty + 8)])
    if f == 5:
        # chest plates cracked open and hanging to the sides
        boulder(im, 21, ty + 6, 5, 8, 113, STONE_D)
        boulder(im, 45, ty + 6, 5, 8, 114, STONE_D)
    core_y = ty + (5 if f == 5 else 2)
    core_x = 33 if f == 5 else 32
    core(im, core_x, core_y, lvl)
    # upper arms behind shoulders
    shoulder_y = ty - 9 + sdy
    limb(im, (14, shoulder_y), el, 6, 121)
    limb(im, (50, shoulder_y), er, 6, 122)
    limb(im, el, fl, 5.5, 123)
    limb(im, er, fr, 5.5, 124)
    # shoulder boulders with moss
    boulder(im, 15, shoulder_y, 10, 9, 131, STONE, moss=4)
    boulder(im, 49, shoulder_y + (1 if f == 5 else 0), 10, 9, 132, STONE, moss=3)
    shard(im, 51, shoulder_y - 4, 54, shoulder_y - 14, 2)
    # head: small, sunk between the shoulders
    boulder(im, hx, hy, 10, 8, 141, STONE, moss=3)
    d = ImageDraw.Draw(im)
    d.line([hx - 7, hy, hx + 7, hy], fill=OUT + (255,))                       # heavy brow
    d.line([hx - 6, hy - 1, hx + 5, hy - 1], fill=(166, 154, 138, 255))
    for ex in (hx - 5, hx + 3):
        if f == 5:                                                            # half shut
            d.line([ex, hy + 2, ex + 2, hy + 2], fill=AMBER[1] + (255,))
        else:
            d.rectangle([ex, hy + 1, ex + 2, hy + 2], fill=AMBER[2] + (255,))
            d.point([ex + 1, hy + 1], fill=AMBER[4] + (255,))
    d.line([hx - 3, hy + 5, hx + 3, hy + 5], fill=(42, 32, 34, 255))
    # fists in front of everything
    fist(im, fl[0], fl[1], 151)
    fist(im, fr[0], fr[1], 152)
    # light from the core
    glow(im, core_x, core_y, (13, 18, 21)[lvl], (60, 90, 80)[lvl])
    d = ImageDraw.Draw(im)
    if f == 3:                                                                # charge motes
        for x, y in ((24, 6), (40, 7), (32, 3), (28, 12), (37, 13)):
            d.point([x, y], fill=AMBER[3] + (255,))
            d.point([x, y + 1], fill=AMBER[1] + (200,))
    if f == 4:                                                                # impact dust + chips
        for x, y, s in ((4, 65, 2), (8, 59, 1), (59, 65, 2), (56, 58, 1), (3, 52, 1), (61, 51, 1)):
            d.rectangle([x - s, y - s, x + s - 1, y + s - 1], fill=(170, 150, 128, 255), outline=OUT + (255,))
        for a, b in (((1, 69), (11, 67)), ((52, 67), (62, 69)), ((3, 61), (10, 64)), ((60, 61), (53, 64))):
            d.line([a, b], fill=(214, 190, 150, 255))
    if f == 5:                                                                # tired puffs
        for x, y in ((11, 20), (13, 17), (53, 24), (51, 21)):
            d.point([x, y], fill=(220, 226, 232, 255))
            d.point([x + 1, y], fill=(180, 190, 200, 255))
    return im


def cave_warden():
    sheet = Image.new("RGBA", (FW * 6, FH), (0, 0, 0, 0))
    for f in range(6):
        sheet.paste(warden_frame(f), (f * FW, 0))
    save(sheet, "cave_warden.png")


# ---------------------------------------------------------------- rails
RAIL_HI, RAIL_LO, RAIL_EDGE = (190, 196, 208), (112, 114, 130), (40, 34, 40)
TIE = [(78, 48, 28), (112, 72, 40), (146, 98, 54)]


def rail_tile(kind):
    """0 E-W, 1 N-S, 2 N+E, 3 N+W, 4 S+E, 5 S+W. Geometry is evaluated one pixel past the tile so edges join."""
    corner = {2: (32, 0), 3: (0, 0), 4: (32, 32), 5: (0, 32)}.get(kind)

    def track(x, y):
        """-> (distance along the track, signed offset across it; negative = north/west on straights)."""
        px, py = x + 0.5, y + 0.5
        if kind == 0:
            return px, py - 16
        if kind == 1:
            return py, px - 16
        dx, dy = abs(px - corner[0]), abs(py - corner[1])
        return math.atan2(dy, dx), math.hypot(dx, dy) - 16

    def tie_at(x, y):
        s, o = track(x, y)
        if corner is not None and min(x, y, 31 - x, 31 - y) < 2:
            return None                          # keep the joint rows clear, like the straights
        if abs(o) >= 12:
            return None
        if corner is None:
            u = (s % 8) - 4                      # centres at 4, 12, 20, 28
        else:
            rad = o + 16
            near = min((math.radians(a) for a in (15, 45, 75)), key=lambda a: abs(a - s))
            u = rad * math.sin(s - near)
        return (u, o) if abs(u) < 2 else None

    def rail_at(x, y):
        _, o = track(x, y)
        return 6 <= abs(o) < 8

    im = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    nb = ((1, 0), (-1, 0), (0, 1), (0, -1))
    for y in range(32):
        for x in range(32):
            t = tie_at(x, y)
            if t:
                u, o = t
                c = TIE[2] if u < -0.8 else TIE[1] if u < 0.9 else TIE[0]
                if int(abs(o) * 1.0 + (x * 3 + y * 5) % 7) % 9 == 0:
                    c = shade(c, 0.85)            # grain
                if abs(o) > 10.8:
                    c = TIE[0]                    # cut ends
                im.putpixel((x, y), c + (255,))
            elif any(tie_at(x + a, y + b) for a, b in nb):
                im.putpixel((x, y), OUT + (255,))
    for y in range(32):
        for x in range(32):
            if rail_at(x, y):
                # lit pixel of each 2px rail = the one whose upper/left neighbour is outside the rail
                if corner is None:
                    lit = not (rail_at(x, y - 1) if kind == 0 else rail_at(x - 1, y))
                else:
                    # angle is measured from the horizontal line through the corner centre, so near 0 is the
                    # north/south edge (rails run vertically there) and near pi/2 is the east/west edge.
                    ang, o = track(x, y)
                    larger = (o % 2) >= 1         # the outer-radius pixel of the 2px pair
                    left_is_larger = corner[0] == 32
                    top_is_larger = corner[1] == 32
                    want_larger = left_is_larger if ang < math.pi / 4 else top_is_larger
                    lit = larger == want_larger
                im.putpixel((x, y), (RAIL_HI if lit else RAIL_LO) + (255,))
            elif any(rail_at(x + a, y + b) for a, b in nb):
                im.putpixel((x, y), RAIL_EDGE + (255,))
    return im


def cave_rail():
    sheet = Image.new("RGBA", (192, 32), (0, 0, 0, 0))
    for k in range(6):
        sheet.paste(rail_tile(k), (k * 32, 0))
    save(sheet, "cave_rail.png")


# ---------------------------------------------------------------- cart
def _part(im, fn):
    layer = Image.new("RGBA", im.size, (0, 0, 0, 0))
    fn(ImageDraw.Draw(layer))
    outline_pass(layer)
    im.alpha_composite(layer)


def cart_side(f):
    im = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    ImageDraw.Draw(im).ellipse([3, 27, 28, 31], fill=(20, 14, 16, 80))
    bob = f
    top, bot = 9 + bob, 23 + bob

    def box(d):
        d.polygon([(3, top + 2), (28, top + 2), (25, bot), (6, bot)], fill=WOOD[2] + (255,))
    _part(im, box)
    d = ImageDraw.Draw(im)
    for y in (top + 6, top + 10):                       # plank seams
        d.line([5, y, 26, y], fill=WOOD[0] + (255,))
        d.line([5, y + 1, 26, y + 1], fill=WOOD[3] + (255,))

    def rim(d):
        d.rectangle([2, top, 29, top + 2], fill=IRON[2] + (255,))
    _part(im, rim)
    d = ImageDraw.Draw(im)
    d.line([2, top, 29, top], fill=IRON[3] + (255,))
    for x in (8, 22):                                   # iron bands with rivets
        d.rectangle([x, top + 3, x + 1, bot - 1], fill=IRON[1] + (255,))
        d.line([x, top + 3, x, bot - 1], fill=IRON[2] + (255,))
        for y in (top + 4, top + 12):
            d.point([x, y], fill=IRON[3] + (255,))
    d.line([7, bot - 1, 24, bot - 1], fill=IRON[0] + (255,))
    for wx in (9, 22):
        def wheel(d, wx=wx):
            d.ellipse([wx - 5, 20, wx + 5, 30], fill=IRON[1] + (255,))
        _part(im, wheel)
        d = ImageDraw.Draw(im)
        d.ellipse([wx - 3, 22, wx + 3, 28], fill=(38, 30, 32, 255))
        if f == 0:                                      # + spokes
            d.line([wx - 3, 25, wx + 3, 25], fill=IRON[3] + (255,))
            d.line([wx, 22, wx, 28], fill=IRON[3] + (255,))
        else:                                           # x spokes
            d.line([wx - 2, 23, wx + 2, 27], fill=IRON[3] + (255,))
            d.line([wx - 2, 27, wx + 2, 23], fill=IRON[3] + (255,))
        d.rectangle([wx - 1, 24, wx, 25], fill=IRON[2] + (255,))
        d.line([wx - 3, 21, wx - 1, 20], fill=IRON[3] + (255,))
    return im


def cart_front(f):
    im = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    ImageDraw.Draw(im).ellipse([5, 27, 26, 31], fill=(20, 14, 16, 80))
    bob = f
    # wheels seen edge-on, centred over the rails (14px apart)
    for x0 in (7, 21):
        def wheel(d, x0=x0):
            d.rectangle([x0, 21, x0 + 3, 30], fill=IRON[1] + (255,))
        _part(im, wheel)
        d = ImageDraw.Draw(im)
        d.line([x0, 21, x0, 30], fill=IRON[2] + (255,))
        for y in range(22 + f * 2, 31, 4):              # moving tread marks
            d.line([x0, y, x0 + 3, y], fill=IRON[3] + (255,))

    def box(d):
        d.polygon([(5, 12 + bob), (26, 12 + bob), (24, 25 + bob), (7, 25 + bob)], fill=WOOD[2] + (255,))
    _part(im, box)
    d = ImageDraw.Draw(im)
    for y in (17 + bob, 21 + bob):
        d.line([7, y, 24, y], fill=WOOD[0] + (255,))
        d.line([7, y + 1, 24, y + 1], fill=WOOD[3] + (255,))

    def rim(d):
        d.polygon([(6, 6 + bob), (25, 6 + bob), (27, 12 + bob), (27, 14 + bob), (4, 14 + bob), (4, 12 + bob)],
                  fill=IRON[2] + (255,))
    _part(im, rim)
    d = ImageDraw.Draw(im)
    d.polygon([(7, 8 + bob), (24, 8 + bob), (25, 11 + bob), (6, 11 + bob)], fill=(40, 26, 20, 255))  # inside
    d.line([8, 8 + bob, 23, 8 + bob], fill=(22, 14, 14, 255))
    d.line([9, 11 + bob, 22, 11 + bob], fill=WOOD[0] + (255,))
    d.line([6, 6 + bob, 25, 6 + bob], fill=IRON[3] + (255,))
    d.line([5, 12 + bob, 26, 12 + bob], fill=IRON[3] + (255,))
    for x in (10, 20):
        d.rectangle([x, 15 + bob, x + 1, 24 + bob], fill=IRON[1] + (255,))
        d.line([x, 15 + bob, x, 24 + bob], fill=IRON[2] + (255,))
        for y in (16 + bob, 23 + bob):
            d.point([x, y], fill=IRON[3] + (255,))
    d.rectangle([14, 24 + bob, 17, 25 + bob], fill=IRON[1] + (255,), outline=OUT + (255,))        # coupler
    return im


def cave_cart():
    sheet = Image.new("RGBA", (128, 32), (0, 0, 0, 0))
    for i, im in enumerate((cart_side(0), cart_side(1), cart_front(0), cart_front(1))):
        sheet.paste(im, (i * 32, 0))
    save(sheet, "cave_cart.png")


# ---------------------------------------------------------------- falling rock
def cave_rock():
    im = Image.new("RGBA", (24, 24), (0, 0, 0, 0))
    boulder(im, 12, 12, 9.5, 9, 207, (124, 110, 102))
    crack(im, [(13, 5), (12, 9), (15, 12), (14, 16)])
    crack(im, [(12, 9), (8, 12)])
    for p in ((8, 7), (9, 6), (7, 8)):
        im.putpixel(p, (186, 174, 156, 255))
    save(im, "cave_rock.png")


def main():
    for fn in (ore_silver, ore_gold, cave_warden, cave_rail, cave_cart, cave_rock):
        fn()


if __name__ == "__main__":
    main()
