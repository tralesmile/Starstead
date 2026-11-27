#!/usr/bin/env python3
"""Warden's Hall decor (original, CC0): broken pillars, braziers, wall banners and carved faces, the carved
rune floor circle (stone + glow layer) and floor litter (rubble, bones, old mining gear).
Same style as gen_cave.py (painterly pixel art, dark 1px outline, light from top-left). Deterministic."""
import math
import random
from PIL import Image, ImageDraw

from gen_cave import OUT, WOOD, IRON, shade, mix, Noise, outline_pass, save
from gen_deep import boulder

STONE = (128, 116, 108)
BONE = [(122, 108, 90), (170, 156, 128), (206, 194, 162), (232, 224, 196)]
MOSS = [(50, 82, 40), (78, 116, 50), (114, 150, 62)]
RUST = [(96, 50, 30), (140, 76, 40), (178, 108, 56)]
TEAL = [(42, 106, 124), (78, 172, 184), (170, 238, 232)]


def blank(w, h):
    return Image.new("RGBA", (w, h), (0, 0, 0, 0))


def contact(im, box, a=90):
    layer = blank(*im.size)
    ImageDraw.Draw(layer).ellipse(box, fill=(20, 14, 16, a))
    im.alpha_composite(layer)


def part(im, fn):
    """Draw one piece on its own layer so it gets its own outline."""
    layer = blank(*im.size)
    fn(ImageDraw.Draw(layer))
    outline_pass(layer)
    im.alpha_composite(layer)


def sheet(frames, name):
    w, h = frames[0].size
    out = blank(w * len(frames), h)
    for i, f in enumerate(frames):
        out.paste(f, (i * w, 0))
    save(out, name)


# ---------------------------------------------------------------- pillars (32x64, base on row 60)
def column(im, cx, top, bot, rad, seed, jag=True):
    """Fluted stone shaft lit from the left, with drum seams and a snapped (jagged) top."""
    r = random.Random(seed)
    n = Noise(seed, 8, 32, 64, wrap_y=False)
    layer = blank(32, 64)
    px = layer.load()
    edge = {}
    h = r.randint(-2, 2)
    for x in range(cx - rad, cx + rad + 1):
        if jag:
            h = max(-4, min(4, h + r.choice((-2, -1, 0, 1, 2))))
        edge[x] = top + (h if jag else 0) + (int((x - cx) * 0.35) if jag else 0)
    for x in range(cx - rad, cx + rad + 1):
        u = (x - cx) / float(rad)
        k = 1.32 if u < -0.55 else 1.16 if u < -0.15 else 0.98 if u < 0.3 else 0.8 if u < 0.7 else 0.66
        for y in range(edge[x], bot + 1):
            c = shade(STONE, k * (0.9 + 0.2 * n.at(x, y)))
            if (x - cx) in (-rad // 3, rad // 3):          # flutes
                c = shade(c, 0.84)
            if r.random() < 0.04:
                c = shade(c, r.choice((0.8, 1.18)))
            px[x, y] = c + (255,)
        if jag:                                             # pale broken face
            for i in range(3):
                if edge[x] + i <= bot:
                    px[x, edge[x] + i] = shade((176, 162, 146), (1.08, 0.96, 0.7)[i] - max(0, u) * 0.18) + (255,)
    for sy in range(bot - 11, top + 6, -12):                # drum seams
        for x in range(cx - rad, cx + rad + 1):
            y = sy + (1 if abs(x - cx) < rad * 0.6 else 0)
            if y > edge[x] + 3:
                px[x, y] = shade(px[x, y][:3], 0.56) + (255,)
                px[x, y + 1] = shade(px[x, y + 1][:3], 1.2) + (255,)
    outline_pass(layer)
    im.alpha_composite(layer)


def plinth(im, cx, y, hw, seed):
    """Square two-step base block with a lit top face."""
    def draw(d):
        d.rectangle([cx - hw, y, cx + hw, y + 7], fill=shade(STONE, 0.86) + (255,))
        d.rectangle([cx - hw, y, cx + hw, y + 2], fill=shade(STONE, 1.24) + (255,))
        d.line([cx - hw, y + 3, cx - hw, y + 7], fill=shade(STONE, 1.1) + (255,))
        d.line([cx + hw - 2, y + 3, cx + hw - 2, y + 7], fill=shade(STONE, 0.68) + (255,))
        d.line([cx - hw, y + 7, cx + hw, y + 7], fill=shade(STONE, 0.58) + (255,))
        r = random.Random(seed)
        for _ in range(5):
            x = r.randrange(cx - hw + 2, cx + hw - 2)
            d.point([x, y + r.randrange(4, 7)], fill=shade(STONE, 0.66) + (255,))
    part(im, draw)


def moss_tuft(im, spots):
    px = im.load()
    r = random.Random(len(spots) * 7 + spots[0][0])
    for x, y in spots:
        for dx, dy in ((0, 0), (1, 0), (2, 0), (0, 1), (1, 1), (-1, 1), (0, 2)):
            if 0 <= x + dx < im.width and 0 <= y + dy < im.height and px[x + dx, y + dy][3] == 255 \
                    and px[x + dx, y + dy][:3] != OUT and r.random() < 0.8:
                px[x + dx, y + dy] = MOSS[2 if dy == 0 else 1 if dy == 1 else 0] + (255,)


def pillar_tall():
    im = blank(32, 64)
    contact(im, [2, 53, 31, 63])
    column(im, 15, 13, 53, 8, 301)
    plinth(im, 15, 52, 12, 302)
    part(im, lambda d: d.rectangle([5, 48, 25, 52], fill=shade(STONE, 1.02) + (255,)))
    ImageDraw.Draw(im).line([6, 49, 23, 49], fill=shade(STONE, 1.28) + (255,))
    d = ImageDraw.Draw(im)
    # a carved warden eye on the shaft
    d.polygon([(15, 28), (19, 33), (15, 38), (11, 33)], fill=(58, 48, 48, 255))
    d.polygon([(15, 30), (17, 33), (15, 36), (13, 33)], fill=TEAL[0] + (255,))
    d.point([15, 32], fill=TEAL[2] + (255,))
    d.line([(18, 14), (17, 19), (19, 23), (18, 26)], fill=(52, 42, 42, 255))
    moss_tuft(im, [(8, 50), (9, 45), (21, 52)])
    boulder(im, 27, 59, 4, 3, 303, STONE)
    return im


def pillar_short():
    im = blank(32, 64)
    contact(im, [1, 53, 31, 63])
    column(im, 16, 33, 53, 8, 311)
    plinth(im, 16, 52, 12, 312)
    d = ImageDraw.Draw(im)
    d.line([(13, 37), (14, 41), (12, 45), (13, 49)], fill=(52, 42, 42, 255))
    moss_tuft(im, [(19, 36), (21, 38), (7, 53)])
    boulder(im, 6, 59, 5, 4, 313, STONE)
    boulder(im, 27, 60, 3, 3, 314, STONE)
    return im


def pillar_fallen():
    """Stump with its toppled drum lying beside it."""
    im = blank(32, 64)
    contact(im, [0, 50, 31, 63])
    column(im, 10, 40, 53, 6, 321)
    plinth(im, 10, 52, 9, 322)

    def drum(d):
        d.rectangle([13, 49, 27, 61], fill=shade(STONE, 0.96) + (255,))
        d.rectangle([13, 49, 27, 51], fill=shade(STONE, 1.28) + (255,))
        d.rectangle([13, 52, 27, 53], fill=shade(STONE, 1.12) + (255,))
        d.rectangle([13, 58, 27, 61], fill=shade(STONE, 0.7) + (255,))
        d.line([19, 49, 19, 61], fill=shade(STONE, 0.6) + (255,))
        d.line([20, 49, 20, 61], fill=shade(STONE, 1.18) + (255,))
    part(im, drum)
    part(im, lambda d: d.ellipse([23, 49, 30, 61], fill=shade(STONE, 1.2) + (255,)))
    d = ImageDraw.Draw(im)
    d.ellipse([25, 52, 28, 58], outline=shade(STONE, 0.76) + (255,))
    moss_tuft(im, [(15, 49), (8, 42)])
    boulder(im, 4, 60, 3, 3, 323, STONE)
    return im


# ---------------------------------------------------------------- braziers (32x48, base on row 45)
def brazier(f):
    im = blank(32, 48)
    contact(im, [4, 39, 28, 47])
    halo = blank(32, 48)
    hd = ImageDraw.Draw(halo)
    hd.ellipse([2, 1, 29, 30], fill=(255, 140, 40, 26))
    hd.ellipse([6, 7, 25, 27], fill=(255, 170, 60, 36))
    im.alpha_composite(halo)
    # stone foot + iron legs
    part(im, lambda d: d.rectangle([9, 40, 22, 44], fill=shade(STONE, 0.9) + (255,)))
    ImageDraw.Draw(im).line([9, 40, 22, 40], fill=shade(STONE, 1.26) + (255,))
    for pts in ([(8, 28), (11, 28), (14, 40), (12, 40)], [(23, 28), (20, 28), (17, 40), (19, 40)]):
        part(im, lambda d: d.polygon(pts, fill=IRON[1] + (255,)))
    part(im, lambda d: d.rectangle([14, 29, 17, 40], fill=IRON[0] + (255,)))
    ImageDraw.Draw(im).line([9, 29, 12, 38], fill=IRON[3] + (255,))
    # bowl
    part(im, lambda d: d.polygon([(5, 23), (26, 23), (23, 29), (19, 32), (12, 32), (8, 29)], fill=IRON[1] + (255,)))
    d = ImageDraw.Draw(im)
    d.polygon([(19, 25), (24, 25), (22, 29), (19, 31), (16, 31)], fill=IRON[0] + (255,))
    d.line([7, 25, 9, 28], fill=IRON[3] + (255,))
    part(im, lambda dd: dd.rectangle([4, 21, 27, 24], fill=IRON[2] + (255,)))
    d = ImageDraw.Draw(im)
    d.line([5, 22, 20, 22], fill=IRON[3] + (255,))
    for x in (8, 15, 23):
        d.point([x, 27], fill=(176, 130, 70, 255))
    # coals
    for x in range(7, 25):
        d.point([x, 20], fill=((250, 140, 40) if (x + f) % 3 else (120, 40, 24)) + (255,))
        if 8 < x < 23:
            d.point([x, 19], fill=((255, 200, 70) if (x * 2 + f) % 4 else (200, 70, 28)) + (255,))
    # flame: three tongues that swap height frame by frame
    lean = (0, 1, 0, -1)[f]
    hs = ((15, 8, 11), (13, 11, 7), (16, 7, 10), (12, 10, 12))[f]
    mid, lft, rgt = hs
    outer = [(8, 19), (8, 15), (10 + lean, 19 - lft), (12, 15), (15 + lean * 2, 19 - mid),
             (19, 13), (21 - lean, 19 - rgt), (23, 15), (23, 19)]
    part(im, lambda dd: dd.polygon(outer, fill=(228, 88, 28, 255)))
    d = ImageDraw.Draw(im)
    d.polygon([(10, 19), (11 + lean, 20 - lft + 2), (13, 16), (15 + lean, 23 - mid), (19, 15),
               (20 - lean, 22 - rgt), (21, 19)], fill=(252, 142, 38, 255))
    d.polygon([(11, 19), (13, 16), (15 + lean, 27 - mid), (18, 15), (20, 19)], fill=(255, 204, 70, 255))
    d.polygon([(13, 19), (14, 17), (15 + lean // 2, 14), (17, 17), (18, 19)], fill=(255, 245, 172, 255))
    for x, y in (((6, 9), (24, 5)), ((25, 8), (9, 3)), ((7, 5), (23, 11)), ((24, 3), (8, 11)))[f]:
        d.point([x, y], fill=(255, 208, 90, 255))
    return im


# ---------------------------------------------------------------- wall decor (32x40, hung from the wall lip)
def banner(cloth, seed):
    im = blank(32, 40)
    r = random.Random(seed)
    dark, mid, lit = shade(cloth, 0.68), cloth, shade(cloth, 1.28)
    hem = [(25, 31), (23, 36), (20, 31), (18, 33), (15, 38), (12, 32), (10, 34), (7, 29)]
    part(im, lambda d: d.polygon([(7, 6), (25, 6)] + hem, fill=mid + (255,)))
    px = im.load()
    for y in range(7, 38):
        for x in range(8, 25):
            if px[x, y][3] == 255 and px[x, y][:3] != OUT:
                fold = (x - 8) % 6
                c = lit if fold == 1 else dark if fold in (4, 5) else mid
                if r.random() < 0.07:
                    c = shade(c, 0.82)
                px[x, y] = c + (255,)
    d = ImageDraw.Draw(im)
    gold, gold_d = (206, 164, 78, 255), (142, 104, 48, 255)
    d.line([9, 8, 9, 27], fill=gold_d)
    d.line([23, 8, 23, 28], fill=gold_d)
    # warden eye sigil
    d.polygon([(16, 11), (21, 18), (16, 26), (11, 18)], fill=(40, 26, 26, 255))
    d.polygon([(16, 12), (20, 18), (16, 24), (12, 18)], outline=gold)
    d.rectangle([15, 16, 17, 20], fill=gold)
    d.point([15, 16], fill=(255, 232, 160, 255))
    d.line([12, 9, 20, 9], fill=gold)
    d.point([19, 29], fill=OUT + (255,))                    # moth holes
    d.point([11, 26], fill=OUT + (255,))
    part(im, lambda dd: dd.rectangle([4, 3, 28, 5], fill=WOOD[2] + (255,)))
    d = ImageDraw.Draw(im)
    d.line([5, 3, 27, 3], fill=WOOD[3] + (255,))
    for x in (3, 28):
        part(im, lambda dd: dd.rectangle([x - 1, 2, x + 1, 6], fill=IRON[2] + (255,)))
    return im


def carved_face():
    im = blank(32, 40)
    slab = [(5, 6), (10, 3), (22, 3), (27, 6), (27, 27), (22, 33), (10, 33), (5, 27)]
    part(im, lambda d: d.polygon(slab, fill=shade(STONE, 0.9) + (255,)))
    d = ImageDraw.Draw(im)
    d.line([(6, 27), (6, 7), (10, 4), (21, 4)], fill=shade(STONE, 1.36) + (255,))
    d.line([(26, 8), (26, 27), (22, 32), (11, 32)], fill=shade(STONE, 0.62) + (255,))
    # brow, nose, mouth
    d.polygon([(8, 11), (15, 13), (17, 13), (24, 11), (24, 14), (17, 16), (15, 16), (8, 14)], fill=shade(STONE, 1.14) + (255,))
    d.line([(8, 15), (14, 17)], fill=OUT + (255,))
    d.line([(18, 17), (24, 15)], fill=OUT + (255,))
    for x0 in (9, 19):                                      # glowing slit eyes in dark sockets
        d.rectangle([x0, 17, x0 + 4, 19], fill=(34, 24, 26, 255))
        d.line([x0 + 1, 18, x0 + 3, 18], fill=TEAL[1] + (255,))
        d.point([x0 + 2, 18], fill=TEAL[2] + (255,))
    d.polygon([(15, 16), (17, 16), (19, 24), (13, 24)], fill=shade(STONE, 1.06) + (255,))
    d.line([(15, 16), (13, 24)], fill=shade(STONE, 1.34) + (255,))
    d.line([(13, 25), (19, 25)], fill=shade(STONE, 0.56) + (255,))
    d.rectangle([10, 27, 22, 29], fill=(40, 30, 30, 255))
    for x in (12, 15, 18, 21):
        d.line([x, 27, x, 29], fill=shade(STONE, 0.9) + (255,))
    d.line([(21, 4), (20, 8), (22, 10)], fill=(48, 38, 40, 255))
    moss_tuft(im, [(9, 4), (12, 3), (6, 8)])
    return im


# ---------------------------------------------------------------- floor litter (32x32)
def rubble(seed, big):
    im = blank(32, 32)
    contact(im, [4, 17, 29, 28] if big else [8, 18, 25, 26], 70)
    stones = [(12, 19, 6, 5), (21, 21, 5, 4), (16, 14, 4, 3), (7, 23, 3, 2), (26, 25, 2, 2), (16, 25, 3, 2)] if big \
        else [(13, 20, 4, 3), (20, 22, 3, 2), (10, 25, 2, 2), (23, 17, 2, 2)]
    for i, (x, y, rx, ry) in enumerate(stones):
        boulder(im, x, y, rx, ry, seed + i, (108, 98, 92))
    return im


def bone(d, a, b):
    d.line([a, b], fill=BONE[2] + (255,), width=2)
    for x, y in (a, b):
        d.rectangle([x - 1, y - 1, x + 1, y], fill=BONE[2] + (255,))


def skull(im, x, y):
    part(im, lambda d: (d.ellipse([x - 4, y - 4, x + 4, y + 3], fill=BONE[2] + (255,)),
                        d.rectangle([x - 2, y + 2, x + 2, y + 5], fill=BONE[1] + (255,))))
    d = ImageDraw.Draw(im)
    d.line([x - 2, y - 3, x, y - 3], fill=BONE[3] + (255,))
    d.rectangle([x - 3, y - 1, x - 1, y + 1], fill=OUT + (255,))
    d.rectangle([x + 1, y - 1, x + 3, y + 1], fill=OUT + (255,))
    d.point([x, y + 2], fill=OUT + (255,))
    d.point([x - 1, y + 4], fill=OUT + (255,))
    d.point([x + 1, y + 4], fill=OUT + (255,))


def bones_skull():
    im = blank(32, 32)
    contact(im, [5, 18, 27, 28], 55)
    part(im, lambda d: bone(d, (6, 18), (17, 26)))
    part(im, lambda d: bone(d, (8, 26), (19, 20)))
    skull(im, 21, 20)
    part(im, lambda d: bone(d, (24, 27), (28, 26)))
    return im


def ribcage():
    im = blank(32, 32)
    contact(im, [5, 17, 27, 27], 55)
    part(im, lambda d: d.line([(7, 19), (23, 22)], fill=BONE[1] + (255,), width=2))
    for i, x in enumerate((9, 13, 17, 21)):
        part(im, lambda d: d.line([(x, 19 + i), (x - 2, 15 + i), (x + 1, 12 + i)], fill=BONE[2] + (255,)))
        part(im, lambda d: d.line([(x, 20 + i), (x - 1, 24 + i // 2), (x + 2, 26)], fill=BONE[1] + (255,)))
    skull(im, 27, 22)
    return im


def pickaxe():
    im = blank(32, 32)
    contact(im, [5, 18, 28, 27], 50)
    part(im, lambda d: d.line([(7, 26), (16, 20)], fill=WOOD[1] + (255,), width=3))
    part(im, lambda d: d.line([(19, 18), (22, 16)], fill=WOOD[1] + (255,), width=3))   # snapped haft
    part(im, lambda d: d.polygon([(17, 10), (23, 12), (27, 17), (28, 24), (24, 19), (21, 16), (16, 13), (12, 13)],
                                 fill=IRON[2] + (255,)))
    d = ImageDraw.Draw(im)
    d.line([(13, 13), (18, 11), (23, 13), (26, 17)], fill=IRON[3] + (255,))
    d.point([24, 16], fill=RUST[1] + (255,))
    d.point([20, 13], fill=RUST[2] + (255,))
    d.line([(8, 25), (14, 21)], fill=WOOD[3] + (255,))
    return im


def helmet_lamp():
    im = blank(32, 32)
    contact(im, [4, 18, 28, 28], 60)
    part(im, lambda d: d.pieslice([5, 13, 19, 29], 180, 360, fill=(170, 128, 52, 255)))
    part(im, lambda d: d.rectangle([4, 21, 20, 23], fill=(128, 92, 40, 255)))
    d = ImageDraw.Draw(im)
    d.line([(7, 18), (9, 15), (12, 14)], fill=(226, 188, 100, 255))
    d.rectangle([13, 16, 16, 19], fill=IRON[2] + (255,), outline=OUT + (255,))
    d.point([14, 17], fill=(240, 232, 190, 255))
    # tipped oil lamp
    part(im, lambda dd: dd.rectangle([22, 19, 28, 26], fill=IRON[1] + (255,)))
    part(im, lambda dd: dd.rectangle([23, 16, 27, 18], fill=IRON[2] + (255,)))
    d = ImageDraw.Draw(im)
    d.rectangle([23, 21, 27, 24], fill=(98, 110, 100, 255))
    d.line([25, 20, 25, 25], fill=IRON[0] + (255,))
    d.line([23, 21, 23, 23], fill=(168, 190, 170, 255))
    d.arc([22, 12, 28, 20], 180, 360, fill=OUT + (255,))
    return im


def cart_wheel():
    im = blank(32, 32)
    contact(im, [3, 19, 29, 29], 60)
    part(im, lambda d: d.rectangle([17, 22, 29, 25], fill=WOOD[1] + (255,)))   # splintered plank
    ImageDraw.Draw(im).line([18, 22, 27, 22], fill=WOOD[3] + (255,))
    ring = blank(32, 32)
    d = ImageDraw.Draw(ring)
    d.ellipse([4, 13, 20, 27], fill=RUST[1] + (255,))
    d.ellipse([7, 15, 17, 25], fill=(0, 0, 0, 0))
    d.line([12, 15, 12, 25], fill=RUST[0] + (255,), width=2)
    d.line([7, 20, 17, 20], fill=RUST[0] + (255,), width=2)
    d.ellipse([10, 18, 14, 22], fill=IRON[2] + (255,))
    d.arc([4, 13, 20, 27], 150, 290, fill=RUST[2] + (255,))
    outline_pass(ring)
    im.alpha_composite(ring)
    boulder(im, 24, 18, 3, 3, 401, (108, 98, 92))
    return im


def cracks(seed):
    """Flat impact cracks, no outline: they sit in the floor."""
    im = blank(32, 32)
    r = random.Random(seed)
    d = ImageDraw.Draw(im)
    base = r.random() * 6.28
    for arm in range(4):
        x, y = 16.0, 16.0
        a = base + arm * 1.57 + r.uniform(-0.5, 0.5)
        for seg in range(r.randint(2, 4)):
            a += r.uniform(-0.7, 0.7)
            nx, ny = x + math.cos(a) * 4, y + math.sin(a) * 3
            d.line([x, y + 1, nx, ny + 1], fill=(140, 126, 112, 90))
            d.line([x, y, nx, ny], fill=(32, 24, 26, 210 - seg * 36))
            x, y = nx, ny
    for _ in range(6):
        x, y = r.randrange(8, 24), r.randrange(10, 23)
        d.rectangle([x, y, x + 1, y], fill=(132, 120, 108, 200))
        d.point([x, y + 1], fill=(34, 26, 28, 200))
    return im


# ---------------------------------------------------------------- rune floor circle
RW, RH = 296, 232
CX, CY, RX, RY = 148, 116, 144.0, 112.0
GLYPHS = [
    ["..#..", ".###.", "#.#.#", "..#..", "..#..", "..#..", "..#.."],
    ["#...#", ".#.#.", "..#..", ".#.#.", "#...#", "..#..", "..#.."],
    ["####.", "#....", "###..", "#....", "#....", "#.###", "#...."],
    ["..#..", ".#.#.", "#...#", ".#.#.", "..#..", ".#.#.", "#...#"],
    ["#....", "##...", "#.#..", "#..#.", "#.#..", "##...", "#...."],
    ["#...#", "#...#", ".#.#.", "..#..", "..#..", ".###.", "#.#.#"],
]


def epolar(a, k):
    return (CX + math.cos(a) * RX * k, CY + math.sin(a) * RY * k)


def rune_lines():
    """1-bit mask of everything that is carved (and later glows)."""
    m = Image.new("L", (RW, RH), 0)
    d = ImageDraw.Draw(m)
    for k in (0.955, 0.69):
        d.ellipse([CX - RX * k, CY - RY * k, CX + RX * k, CY + RY * k], outline=255)
    for i in range(16):                                      # glyph band
        a = 2 * math.pi * (i + 0.5) / 16
        gx, gy = epolar(a, 0.825)
        g = GLYPHS[i % len(GLYPHS)]
        for row, line in enumerate(g):
            for col, ch in enumerate(line):
                if ch == "#":
                    x, y = int(gx) - 5 + col * 2, int(gy) - 7 + row * 2
                    d.rectangle([x, y, x + 1, y + 1], fill=255)
    for i in range(8):                                       # spokes from the inner ring to the sigil
        a = 2 * math.pi * i / 8
        d.line([epolar(a, 0.42), epolar(a, 0.66)], fill=255)
        x, y = epolar(a, 0.42)
        d.polygon([(x, y - 3), (x + 3, y), (x, y + 3), (x - 3, y)], outline=255)
    d.ellipse([CX - RX * 0.3, CY - RY * 0.3, CX + RX * 0.3, CY + RY * 0.3], outline=255)
    # the warden's eye: the same diamond as the core in its chest
    d.line([(CX, CY - 26), (CX + 20, CY), (CX, CY + 26), (CX - 20, CY), (CX, CY - 26)], fill=255, width=2)
    d.line([(CX, CY - 14), (CX + 10, CY), (CX, CY + 14), (CX - 10, CY), (CX, CY - 14)], fill=255)
    d.rectangle([CX - 2, CY - 5, CX + 1, CY + 4], fill=255)
    for s in (-1, 1):
        d.line([(CX + s * 24, CY), (CX + s * 38, CY - 5)], fill=255)
        d.line([(CX + s * 24, CY), (CX + s * 38, CY + 5)], fill=255)
    return m


def hall_rune():
    """Worn flagstone dais with the carved circle: low contrast so warning rings and rock shadows stay on top."""
    im = blank(RW, RH)
    px = im.load()
    r = random.Random(501)
    n = Noise(502, 8, RW, RH, wrap_y=False)
    n2 = Noise(503, 4, RW, RH, wrap_y=False)
    bands = [(0.0, 0.30, 6), (0.30, 0.69, 12), (0.69, 0.955, 20), (0.955, 1.02, 40)]
    tone, gone = {}, set()
    for b, (_, _, cnt) in enumerate(bands):
        for s in range(cnt):
            tone[(b, s)] = r.uniform(0.9, 1.1)
            if b >= 2 and r.random() < 0.13:                 # flagstones that have broken away
                gone.add((b, s))
    ids = {}
    for y in range(RH):
        for x in range(RW):
            u, v = (x - CX) / RX, (y - CY) / RY
            k = math.hypot(u, v) + (n2.at(x, y) - 0.5) * 0.012
            for b, (lo, hi, cnt) in enumerate(bands):
                if lo <= k < hi:
                    s = int(((math.atan2(v, u) / (2 * math.pi)) + 1.0 + b * 0.021) * cnt) % cnt
                    if (b, s) not in gone:
                        ids[(x, y)] = (b, s)
                    break
    for (x, y), key in ids.items():
        c = shade((100, 91, 86), tone[key] * (0.9 + 0.2 * n.at(x, y)))
        if key[0] == 2:
            c = shade(c, 0.9)
        if r.random() < 0.05:
            c = shade(c, r.choice((0.84, 1.14)))
        a = 215
        up = ids.get((x - 1, y)) != key or ids.get((x, y - 1)) != key
        down = ids.get((x + 1, y)) != key or ids.get((x, y + 1)) != key
        if down:                                             # seam: dark gap on the far side of each slab
            c, a = (42, 35, 36), 225
        elif up:                                             # lit top-left bevel
            c = shade(c, 1.2)
        px[x, y] = c + (a,)
    lines = rune_lines().load()
    for y in range(1, RH - 1):
        for x in range(1, RW - 1):
            if lines[x, y]:
                px[x, y] = (38, 34, 40, 240)
            elif lines[x - 1, y - 1] or lines[x, y - 1]:     # lower lip of each groove catches the light
                if px[x, y][3]:
                    px[x, y] = shade(px[x, y][:3], 1.28) + (px[x, y][3],)
    d = ImageDraw.Draw(im)
    for _ in range(9):                                       # long cracks across the dais
        a, k = r.uniform(0, 6.28), r.uniform(0.35, 0.9)
        x, y = epolar(a, k)
        h = r.uniform(0, 6.28)
        for _s in range(r.randint(3, 7)):
            h += r.uniform(-0.8, 0.8)
            nx, ny = x + math.cos(h) * 5, y + math.sin(h) * 4
            d.line([x, y, nx, ny], fill=(40, 32, 34, 210))
            x, y = nx, ny
    save(im, "hall_rune.png")


def hall_rune_glow():
    """Additive light layer that follows the grooves: bright line plus a soft 1-2 px bleed."""
    lines = rune_lines()
    lp = lines.load()
    im = blank(RW, RH)
    px = im.load()
    for y in range(2, RH - 2):
        for x in range(2, RW - 2):
            if lp[x, y]:
                px[x, y] = (120, 232, 220, 255)
                continue
            if any(lp[x + a, y + b] for a, b in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                px[x, y] = (50, 170, 180, 105)
            elif any(lp[x + a, y + b] for a, b in ((2, 0), (-2, 0), (0, 2), (0, -2), (1, 1), (-1, -1), (1, -1), (-1, 1))):
                px[x, y] = (40, 130, 160, 45)
    save(im, "hall_rune_glow.png")


def main():
    sheet([pillar_tall(), pillar_short(), pillar_fallen()], "hall_pillar.png")
    sheet([brazier(f) for f in range(4)], "hall_brazier.png")
    sheet([banner((128, 48, 46), 601), banner((52, 82, 98), 602), carved_face()], "hall_wall.png")
    sheet([rubble(700, True), rubble(720, False), bones_skull(), ribcage(), pickaxe(), helmet_lamp(),
           cart_wheel(), cracks(801), cracks(807)], "hall_litter.png")
    hall_rune()
    hall_rune_glow()


if __name__ == "__main__":
    main()
