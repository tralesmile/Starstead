#!/usr/bin/env python3
"""Building-kit sprites (original, CC0): wood floor, wall, door, fence. Deterministic.
Light from top-left, 1px dark outlines, warm palette matching stall.png / dock.png."""
import os
import random
from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SPR = os.path.join(ROOT, "assets", "sprites")
OUT = (42, 26, 16)
WOOD = [(110, 70, 38), (138, 90, 52), (166, 112, 63), (190, 132, 76)]
# door uses a redder, deeper wood
DOOR = [(88, 48, 32), (118, 64, 40), (148, 86, 52), (176, 112, 70)]


def shade(c, k):
    return tuple(max(0, min(255, int(v * k))) for v in c)


def new(w, h):
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    return im, ImageDraw.Draw(im)


def save(im, name):
    im.save(os.path.join(SPR, name))
    print("wrote", name)


def floor():
    rng = random.Random(11)
    im, d = new(32, 32)
    # 4 horizontal planks of 8px; seam = bottom row of each plank (tiles seamlessly)
    for p in range(4):
        y0 = p * 8
        base = shade(WOOD[2], rng.uniform(0.93, 1.07))
        d.rectangle([0, y0, 31, y0 + 7], fill=base)
        d.line([0, y0, 31, y0], fill=shade(base, 1.12))          # top-left lit edge
        d.line([0, y0 + 7, 31, y0 + 7], fill=shade(WOOD[0], 0.9))  # seam
        # grain streaks
        for _ in range(5):
            gx = rng.randrange(0, 28); gy = y0 + rng.randrange(2, 6); gl = rng.randrange(4, 10)
            d.line([gx, gy, min(31, gx + gl), gy], fill=shade(base, rng.choice((0.9, 1.08))))
        # staggered end joint (butt seam), wraps cleanly inside the tile
        jx = (p * 13 + 7) % 30 + 1
        d.line([jx, y0 + 1, jx, y0 + 6], fill=shade(WOOD[0], 0.9))
        d.point([jx + 1, y0 + 1], fill=shade(base, 1.15))
        # nails near joint
        for nx in (jx - 3, jx + 3):
            if 0 <= nx < 32:
                d.point([nx, y0 + 3], fill=shade(WOOD[0], 0.8))
        # occasional knot
        if p in (1, 3):
            kx = rng.randrange(4, 27); ky = y0 + 3
            d.ellipse([kx, ky - 1, kx + 2, ky + 1], fill=shade(WOOD[0], 0.95))
            d.point([kx, ky - 1], fill=shade(base, 1.1))
    save(im, "build_floor.png")


def plank_face(d, x0, y0, x1, y1, pal, rng, seed_shift=0):
    """Vertical planks on a front face."""
    d.rectangle([x0, y0, x1, y1], fill=pal[1])
    px = x0
    i = 0
    while px <= x1:
        pw = 8 if x1 - px >= 8 else x1 - px + 1
        base = shade(pal[1], rng.uniform(0.93, 1.07))
        d.rectangle([px, y0, px + pw - 1, y1], fill=base)
        d.line([px, y0, px, y1], fill=shade(base, 1.15))          # lit left edge
        d.line([px + pw - 1, y0, px + pw - 1, y1], fill=shade(pal[0], 0.95))  # seam
        for _ in range(3):
            gx = px + rng.randrange(2, max(3, pw - 2)); gy = rng.randrange(y0 + 2, y1 - 6)
            d.line([gx, gy, gx, gy + rng.randrange(3, 8)], fill=shade(base, rng.choice((0.88, 1.1))))
        # nails top and bottom
        d.point([px + 3, y0 + 2], fill=shade(pal[0], 0.8))
        d.point([px + 3, y1 - 2], fill=shade(pal[0], 0.8))
        px += pw
        i += 1


def wall():
    rng = random.Random(23)
    im, d = new(32, 48)
    # front face y10..47, cap (top face) y0..11
    plank_face(d, 0, 10, 31, 47, WOOD, rng)
    # base shadow strip
    d.line([1, 45, 30, 45], fill=shade(WOOD[0], 0.85))
    # horizontal brace/rail across the face
    d.line([1, 28, 30, 28], fill=shade(WOOD[0], 0.9))
    d.line([1, 29, 30, 29], fill=shade(WOOD[3], 0.95))
    # top cap with lit top edge
    d.rectangle([0, 0, 31, 11], fill=WOOD[3])
    for y in (3, 7):
        d.line([1, y, 30, y], fill=shade(WOOD[3], 0.9))
    d.line([1, 1, 30, 1], fill=(214, 156, 96))
    d.line([0, 11, 31, 11], fill=WOOD[0])  # shadowed lip under cap
    d.line([1, 10, 30, 10], fill=shade(WOOD[1], 0.85))
    # outline (whole silhouette) + cap/face divider
    d.rectangle([0, 0, 31, 47], outline=OUT)
    d.line([0, 11, 31, 11], fill=OUT)
    save(im, "build_wall.png")


def wall_auto():
    """16-frame wall sheet (512x48): frame index = neighbour mask N1|E2|S4|W8. Walls that touch run on without
    an outline between them, so a row of walls reads as one long wall; free ends keep the outline."""
    sheet = Image.new("RGBA", (512, 48), (0, 0, 0, 0))
    for m in range(16):
        rng = random.Random(23)
        im, d = new(32, 48)
        plank_face(d, 0, 10, 31, 47, WOOD, rng)
        d.line([1, 45, 30, 45], fill=shade(WOOD[0], 0.85))
        d.line([0, 28, 31, 28], fill=shade(WOOD[0], 0.9))
        d.line([0, 29, 31, 29], fill=shade(WOOD[3], 0.95))
        d.rectangle([0, 0, 31, 11], fill=WOOD[3])
        for y in (3, 7):
            d.line([0, y, 31, y], fill=shade(WOOD[3], 0.9))
        d.line([0, 1, 31, 1], fill=(214, 156, 96))
        d.line([0, 11, 31, 11], fill=WOOD[0])
        d.line([0, 10, 31, 10], fill=shade(WOOD[1], 0.85))
        d.line([0, 11, 31, 11], fill=OUT)
        d.line([0, 47, 31, 47], fill=OUT)            # bottom edge always
        if not m & 1:
            d.line([0, 0, 31, 0], fill=OUT)          # no wall above: closed top edge
        if not m & 8:
            d.line([0, 0, 0, 47], fill=OUT)          # free west end
        if not m & 2:
            d.line([31, 0, 31, 47], fill=OUT)        # free east end
        if m & 4:                                    # wall continues south: no bottom line, a darker seam instead
            d.line([0, 47, 31, 47], fill=shade(WOOD[0], 0.8))
        sheet.alpha_composite(im, (m * 32, 0))
    save(sheet, "build_wall_auto.png")


def door():
    rng = random.Random(37)
    im, d = new(32, 48)
    # lintel / cap in the wall wood
    d.rectangle([0, 0, 31, 11], fill=WOOD[3])
    d.line([1, 1, 30, 1], fill=(214, 156, 96))
    d.line([1, 5, 30, 5], fill=shade(WOOD[3], 0.9))
    d.line([0, 11, 31, 11], fill=WOOD[0])
    # frame (wall wood) on the face
    d.rectangle([0, 12, 31, 47], fill=WOOD[1])
    d.line([0, 12, 0, 47], fill=WOOD[3])
    # door leaf
    lx0, lx1, ly0, ly1 = 4, 27, 14, 47
    d.rectangle([lx0, ly0, lx1, ly1], fill=DOOR[1], outline=OUT)
    for k, px in enumerate(range(lx0 + 1, lx1, 6)):
        pw = min(6, lx1 - px)
        base = shade(DOOR[1] if k % 2 == 0 else DOOR[2], rng.uniform(0.96, 1.04))
        d.rectangle([px, ly0 + 1, px + pw - 1, ly1 - 1], fill=base)
        d.line([px, ly0 + 1, px, ly1 - 1], fill=DOOR[3])
        d.line([px + pw - 1, ly0 + 1, px + pw - 1, ly1 - 1], fill=DOOR[0])
    # iron-ish bands
    for y in (19, 38):
        d.line([lx0 + 1, y, lx1 - 1, y], fill=DOOR[0])
        d.line([lx0 + 1, y + 1, lx1 - 1, y + 1], fill=shade(DOOR[3], 0.9))
    # handle: brass knob + plate
    d.rectangle([22, 29, 24, 34], fill=(70, 56, 44), outline=OUT)
    d.ellipse([21, 30, 25, 34], fill=(232, 190, 60), outline=OUT)
    d.point([22, 31], fill=(255, 240, 160))
    # threshold step
    d.rectangle([2, 45, 29, 47], fill=WOOD[2], outline=OUT)
    # outline
    d.rectangle([0, 0, 31, 47], outline=OUT)
    d.line([0, 11, 31, 11], fill=OUT)
    save(im, "build_door.png")


def fence():
    rng = random.Random(51)
    im, d = new(32, 32)
    # soft ground shadow
    sh = Image.new("RGBA", (32, 32), (0, 0, 0, 0)); sd = ImageDraw.Draw(sh)
    sd.ellipse([8, 25, 25, 31], fill=(30, 20, 12, 70))
    im.alpha_composite(sh)
    # rails run full width so neighbouring tiles connect
    for ry in (11, 20):
        d.rectangle([0, ry, 31, ry + 3], fill=WOOD[2])
        d.line([0, ry, 31, ry], fill=OUT); d.line([0, ry + 3, 31, ry + 3], fill=OUT)
        d.line([0, ry + 1, 31, ry + 1], fill=WOOD[3])
        d.line([0, ry + 2, 31, ry + 2], fill=shade(WOOD[1], 0.95))
        for gx in (rng.randrange(2, 8), rng.randrange(16, 28)):
            d.line([gx, ry + 1, gx + 3, ry + 1], fill=shade(WOOD[3], 0.92))
    # post (over rails)
    d.rectangle([12, 5, 19, 29], fill=WOOD[1], outline=OUT)
    d.rectangle([13, 6, 15, 28], fill=WOOD[2])              # lit left side
    d.line([13, 6, 13, 28], fill=WOOD[3])
    d.line([18, 7, 18, 28], fill=WOOD[0])                    # shaded right side
    d.line([14, 12, 14, 15], fill=WOOD[1]); d.line([16, 20, 16, 24], fill=WOOD[1])
    # pointed/cap top
    d.rectangle([11, 3, 20, 6], fill=WOOD[3], outline=OUT)
    d.line([12, 4, 18, 4], fill=(214, 156, 96))
    # nails
    for y in (12, 21):
        d.point([17, y], fill=shade(WOOD[0], 0.7))
    # foot
    d.line([11, 29, 20, 29], fill=OUT)
    save(im, "build_fence.png")


def fence_auto():
    """16-frame fence sheet (512x32): frame index = neighbour mask N1|E2|S4|W8. Rails only run toward connected sides."""
    sheet = Image.new("RGBA", (512, 32), (0, 0, 0, 0))
    rng = random.Random(52)
    for m in range(16):
        im, d = new(32, 32)
        sh = Image.new("RGBA", (32, 32), (0, 0, 0, 0)); sd = ImageDraw.Draw(sh)
        sd.ellipse([8, 25, 25, 31], fill=(30, 20, 12, 70))
        if m & 1: sd.rectangle([13, 6, 19, 14], fill=(30, 20, 12, 55))
        if m & 4: sd.rectangle([13, 24, 19, 32], fill=(30, 20, 12, 55))
        im.alpha_composite(sh)
        for ry in (11, 20):
            x0 = 0 if m & 8 else 12
            x1 = 31 if m & 2 else 19
            if (m & 2) or (m & 8):
                d.rectangle([x0, ry, x1, ry + 3], fill=WOOD[2])
                d.line([x0, ry, x1, ry], fill=OUT); d.line([x0, ry + 3, x1, ry + 3], fill=OUT)
                d.line([x0, ry + 1, x1, ry + 1], fill=WOOD[3])
                d.line([x0, ry + 2, x1, ry + 2], fill=shade(WOOD[1], 0.95))
        if m & 1:   # rail going up (away from the viewer): short thick beam above the post
            d.rectangle([13, 0, 18, 8], fill=WOOD[2], outline=OUT)
            d.line([14, 1, 14, 8], fill=WOOD[3]); d.line([17, 1, 17, 8], fill=WOOD[0])
        if m & 4:   # rail coming toward the viewer: beam in front of the post
            d.rectangle([13, 22, 18, 31], fill=WOOD[2], outline=OUT)
            d.line([14, 23, 14, 30], fill=WOOD[3]); d.line([17, 23, 17, 30], fill=WOOD[0])
        d.rectangle([12, 5, 19, 29], fill=WOOD[1], outline=OUT)
        d.rectangle([13, 6, 15, 28], fill=WOOD[2])
        d.line([13, 6, 13, 28], fill=WOOD[3])
        d.line([18, 7, 18, 28], fill=WOOD[0])
        d.rectangle([11, 3, 20, 6], fill=WOOD[3], outline=OUT)
        d.line([12, 4, 18, 4], fill=(214, 156, 96))
        d.line([11, 29, 20, 29], fill=OUT)
        sheet.alpha_composite(im, (m * 32, 0))
    save(sheet, "build_fence_auto.png")


def roof():
    rng = random.Random(67)
    im, d = new(32, 32)
    rows = 4  # 8px shingle rows, staggered, fully opaque
    for r in range(rows):
        y0 = r * 8
        off = 0 if r % 2 == 0 else 4
        x = -off
        while x < 32:
            w = 8
            base = shade(WOOD[1], rng.uniform(0.9, 1.1))
            x0, x1 = max(0, x), min(31, x + w - 1)
            d.rectangle([x0, y0, x1, y0 + 7], fill=base)
            d.line([x0, y0, x1, y0], fill=shade(base, 1.18))              # lit top edge
            if x >= 0:
                d.line([x0, y0, x0, y0 + 7], fill=shade(base, 1.1))       # lit left edge
            d.line([x0, y0 + 7, x1, y0 + 7], fill=shade(WOOD[0], 0.8))    # shadow under row
            if x + w - 1 <= 31:
                d.line([x1, y0 + 1, x1, y0 + 7], fill=shade(WOOD[0], 0.9))
            d.point([min(31, x0 + 3), y0 + 3], fill=shade(base, rng.choice((0.85, 1.12))))
            x += w
    d.rectangle([0, 0, 31, 31], outline=OUT)
    save(im, "build_roof.png")


if __name__ == "__main__":
    os.makedirs(SPR, exist_ok=True)
    floor(); wall(); door(); fence(); fence_auto(); wall_auto(); roof()
