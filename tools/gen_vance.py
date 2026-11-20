#!/usr/bin/env python3
"""Vance Aerospace rocket yard sprites (original, CC0). Deterministic.

Run from repo root:  python3 tools/gen_vance.py
Writes into assets/sprites/: yard_fence.png (32x48 chain-link panel, razor wire), yard_fence_v.png (side run),
yard_gate.png (96x40 shut sliding gate), rocket.png (56x176 half-built rocket in scaffolding),
launch_pad.png (288x192 ground decal), hangar.png (176x128), fuel_tank.png (44x64), floodlight.png (20x88),
yard_crates.png (48x40). Light from the top-left; 1px dark outlines like the rest of the props.
Preview: /tmp/vance_preview.png
"""
import math, os, random
from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SP = os.path.join(ROOT, "assets", "sprites")
OUT = (26, 26, 32, 255)
STEEL = [(44, 48, 58), (70, 76, 88), (100, 108, 120), (138, 146, 158), (176, 184, 194)]
WHITE = [(120, 124, 136), (168, 172, 182), (206, 208, 214), (232, 233, 236), (248, 248, 250)]
RED = [(92, 24, 22), (150, 40, 34), (196, 60, 46), (226, 92, 70)]
YEL = (232, 186, 40)
CONC = [(92, 92, 90), (116, 116, 112), (138, 138, 132), (160, 160, 152)]


def img(w, h):
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    return im, ImageDraw.Draw(im)


def shadow(d, box, a=70):
    d.ellipse(box, fill=(0, 0, 0, a))


def cyl_shade(x, x0, x1, ramp):
    """Cylinder lit from the left: pick a ramp index for column x of a cylinder spanning x0..x1."""
    t = (x - x0 + 0.5) / max(1, (x1 - x0 + 1))
    v = math.cos((t - 0.28) * math.pi * 0.95)          # brightest a bit left of centre
    i = int(round((v * 0.5 + 0.5) * (len(ramp) - 1)))
    return ramp[max(0, min(len(ramp) - 1, i))]


def outline(im):
    """1px dark outline around opaque pixels (outside)."""
    w, h = im.size
    px = im.load()
    add = []
    for y in range(h):
        for x in range(w):
            if px[x, y][3] > 0:
                continue
            for dx, dy in ((0, 1), (1, 0), (-1, 0), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < w and 0 <= ny < h and px[nx, ny][3] > 200:
                    add.append((x, y)); break
    for x, y in add:
        px[x, y] = OUT


def fence(vertical=False):
    im, d = img(32, 48)
    if vertical:
        # side run seen edge-on: post at the cell centre and a thin mesh strip going up/down the cell
        d.rectangle([13, 6, 18, 47], fill=STEEL[1])
        for y in range(6, 48, 3):
            d.line([(13, y), (18, y + 2)], fill=STEEL[3])
        d.rectangle([14, 2, 17, 47], outline=None, fill=None)
        d.rectangle([15, 0, 16, 44], fill=STEEL[0])
        d.line([(15, 0), (15, 44)], fill=STEEL[3])
        for y in range(1, 46, 6):   # razor coil seen from the side
            d.ellipse([12, y, 19, y + 5], outline=STEEL[4])
        shadow(d, [10, 43, 22, 47], 60)
    else:
        shadow(d, [0, 42, 31, 47], 50)
        d.rectangle([0, 14, 31, 42], fill=(0, 0, 0, 0))
        for i in range(-30, 40, 4):  # diamond chain-link mesh, see-through
            d.line([(i, 14), (i + 28, 42)], fill=STEEL[2] + (230,))
            d.line([(i + 28, 14), (i, 42)], fill=STEEL[1] + (230,))
        d.rectangle([0, 12, 31, 13], fill=STEEL[3])     # top rail
        d.line([(0, 12), (31, 12)], fill=STEEL[4])
        d.rectangle([0, 41, 31, 42], fill=STEEL[1])     # bottom rail
        for px in (0, 30):                              # posts
            d.rectangle([px, 4, px + 1, 44], fill=STEEL[0])
            d.line([(px, 4), (px, 44)], fill=STEEL[3])
        for k in range(4):                              # razor wire coils along the top
            cx = 4 + k * 8
            d.ellipse([cx - 4, 2, cx + 4, 11], outline=STEEL[4])
            d.ellipse([cx - 3, 4, cx + 3, 10], outline=STEEL[2])
            d.point((cx - 2, 3), fill=(255, 255, 255))
    return im


def gate():
    im, d = img(96, 40)
    shadow(d, [2, 33, 94, 39], 60)
    d.rectangle([2, 10, 93, 34], fill=STEEL[1])
    for i in range(-40, 100, 10):   # hazard diagonal stripes
        d.polygon([(i, 34), (i + 5, 34), (i + 29, 10), (i + 24, 10)], fill=YEL)
    d.rectangle([0, 10, 1, 34], fill=OUT)
    d.rectangle([94, 10, 95, 34], fill=OUT)
    d.rectangle([2, 8, 93, 10], fill=STEEL[3])
    d.line([(2, 8), (93, 8)], fill=STEEL[4])
    d.rectangle([2, 33, 93, 34], fill=STEEL[0])
    for x in (2, 47, 92):           # posts
        d.rectangle([x, 2, x + 2, 36], fill=STEEL[0])
        d.line([(x, 2), (x, 36)], fill=STEEL[3])
    # company plate: red diamond on a white plate (no lettering)
    d.rectangle([38, 15, 57, 28], fill=WHITE[3], outline=OUT)
    d.polygon([(47, 17), (53, 21), (47, 26), (41, 21)], fill=RED[2], outline=RED[0])
    d.point((45, 19), fill=RED[3])
    return im


def rocket():
    W, H = 56, 176
    im, d = img(W, H)
    shadow(d, [6, 166, 50, 175], 80)
    x0, x1 = 18, 37            # body
    top, base = 34, 160
    for x in range(x0, x1 + 1):
        c = cyl_shade(x, x0, x1, WHITE)
        d.line([(x, top), (x, base)], fill=c)
    # nose cone
    for y in range(8, top):
        t = (y - 8) / (top - 8)
        hw = (x1 - x0 + 1) / 2 * math.sqrt(t)
        cx = (x0 + x1) / 2 + 0.5
        for x in range(int(cx - hw), int(cx + hw)):
            d.point((x, y), fill=cyl_shade(x, int(cx - hw), int(cx + hw), RED))
    # red band, porthole, panel seams
    for x in range(x0, x1 + 1):
        d.line([(x, 52), (x, 57)], fill=cyl_shade(x, x0, x1, RED))
        d.line([(x, 120), (x, 122)], fill=cyl_shade(x, x0, x1, RED))
    for y in (70, 92, 140):
        d.line([(x0, y), (x1, y)], fill=WHITE[1])
    d.ellipse([23, 61, 31, 69], fill=(40, 70, 104), outline=STEEL[0])
    d.point((25, 63), fill=(190, 226, 250)); d.point((26, 63), fill=(150, 200, 236))
    # half-built: a missing panel shows the ribs
    d.rectangle([24, 96, 36, 116], fill=(40, 40, 48))
    for y in range(98, 116, 4):
        d.line([(24, y), (36, y)], fill=STEEL[2])
    d.line([(30, 96), (30, 116)], fill=STEEL[1])
    # fins
    for side in (-1, 1):
        fx = x0 - 1 if side < 0 else x1 + 1
        pts = [(fx, 130), (fx + side * 9, 150), (fx + side * 9, 162), (fx, 154)]
        d.polygon(pts, fill=RED[1] if side > 0 else RED[2], outline=RED[0])
    d.polygon([(26, 140), (29, 140), (29, 164), (26, 164)], fill=RED[1], outline=RED[0])   # front fin edge-on
    # engine bell
    d.polygon([(21, 160), (34, 160), (37, 168), (18, 168)], fill=STEEL[1], outline=STEEL[0])
    d.line([(22, 161), (19, 167)], fill=STEEL[3])
    # scaffolding tower on the right
    sx0, sx1 = 42, 53
    for x in (sx0, sx1):
        d.line([(x, 20), (x, 168)], fill=STEEL[2])
    for y in range(24, 168, 12):
        d.line([(sx0, y), (sx1, y)], fill=STEEL[1])
        d.line([(sx0, y), (sx1, y + 12)], fill=STEEL[1])
    for y in (60, 108):        # access arms
        d.line([(x1 + 1, y), (sx0, y)], fill=STEEL[3])
        d.line([(x1 + 1, y + 1), (sx0, y + 1)], fill=STEEL[0])
    d.rectangle([sx0 - 1, 16, sx1 + 1, 20], fill=STEEL[1])
    d.point((sx1, 16), fill=(255, 80, 60))   # warning beacon
    outline(im)
    return im


def launch_pad():
    W, H = 288, 192
    im, d = img(W, H)
    rnd = random.Random(7)
    d.rectangle([0, 0, W - 1, H - 1], fill=CONC[1])
    for _ in range(900):        # concrete speckle
        x, y = rnd.randrange(W), rnd.randrange(H)
        d.point((x, y), fill=CONC[rnd.choice((0, 2, 3))])
    for y in range(0, H, 48):   # slab joints
        d.line([(0, y), (W, y)], fill=CONC[0])
    for x in range(0, W, 48):
        d.line([(x, 0), (x, H)], fill=CONC[0])
    for i in range(0, W + H, 12):   # hazard border
        for (a, b) in (((i, 0), (i + 6, 0)), ((i, H - 1), (i + 6, H - 1))):
            pass
    for x in range(0, W, 12):
        d.rectangle([x, 0, x + 5, 5], fill=YEL); d.rectangle([x + 6, 0, x + 11, 5], fill=(30, 30, 30))
        d.rectangle([x, H - 6, x + 5, H - 1], fill=YEL); d.rectangle([x + 6, H - 6, x + 11, H - 1], fill=(30, 30, 30))
    for y in range(0, H, 12):
        d.rectangle([0, y, 5, y + 5], fill=YEL); d.rectangle([0, y + 6, 5, y + 11], fill=(30, 30, 30))
        d.rectangle([W - 6, y, W - 1, y + 5], fill=YEL); d.rectangle([W - 6, y + 6, W - 1, y + 11], fill=(30, 30, 30))
    # scorched flame trench in the middle
    cx, cy = W // 2, H // 2 + 16
    for r in range(56, 0, -4):
        k = r / 56
        col = (int(60 + 40 * k), int(56 + 40 * k), int(54 + 36 * k), int(255 * (1 - k * 0.4)))
        d.ellipse([cx - r, cy - r * 0.6, cx + r, cy + r * 0.6], fill=col)
    d.rectangle([cx - 20, cy - 6, cx + 20, cy + 6], fill=(22, 20, 22))
    for x in range(cx - 18, cx + 19, 4):
        d.line([(x, cy - 5), (x, cy + 5)], fill=(60, 56, 54))
    return im


def hangar():
    W, H = 176, 128
    im, d = img(W, H)
    shadow(d, [4, 116, 172, 127], 80)
    # arched corrugated roof (front face), walls below
    for x in range(4, W - 4):
        t = (x - 4) / (W - 9)
        roof_top = 24 - int(20 * math.sin(t * math.pi))
        c = cyl_shade(x, 4, W - 5, STEEL)
        if (x // 3) % 2 == 0:
            c = tuple(max(0, v - 14) for v in c)
        d.line([(x, roof_top), (x, 70)], fill=c)
    d.rectangle([4, 70, W - 5, 120], fill=STEEL[2])
    for x in range(6, W - 5, 4):
        d.line([(x, 72), (x, 119)], fill=STEEL[1])
    # big hangar door (slightly open: dark gap)
    d.rectangle([44, 78, 132, 120], fill=STEEL[3], outline=STEEL[0])
    for x in range(48, 130, 8):
        d.line([(x, 80), (x, 119)], fill=STEEL[2])
    d.rectangle([86, 80, 92, 120], fill=(24, 24, 30))
    d.rectangle([4, 68, W - 5, 71], fill=RED[1])             # red trim
    d.rectangle([14, 86, 30, 100], fill=(70, 110, 150), outline=STEEL[0])   # windows
    d.rectangle([146, 86, 162, 100], fill=(70, 110, 150), outline=STEEL[0])
    for wx in (16, 148):
        d.line([(wx, 88), (wx + 4, 88)], fill=(170, 210, 236))
    outline(im)
    return im


def tank():
    W, H = 44, 64
    im, d = img(W, H)
    shadow(d, [2, 54, 42, 63], 70)
    for x in range(6, 38):
        d.line([(x, 10), (x, 56)], fill=cyl_shade(x, 6, 37, WHITE))
    d.ellipse([6, 4, 37, 16], fill=WHITE[4], outline=WHITE[1])
    for x in range(6, 38):
        d.line([(x, 30), (x, 33)], fill=cyl_shade(x, 6, 37, RED))
    d.line([(32, 12), (32, 56)], fill=STEEL[0])       # ladder
    d.line([(35, 12), (35, 56)], fill=STEEL[0])
    for y in range(14, 56, 4):
        d.line([(32, y), (35, y)], fill=STEEL[2])
    d.polygon([(14, 44), (18, 38), (22, 44)], fill=YEL, outline=OUT)   # hazard triangle
    outline(im)
    return im


def floodlight():
    W, H = 20, 88
    im, d = img(W, H)
    shadow(d, [3, 82, 17, 87], 70)
    d.line([(8, 14), (8, 84)], fill=STEEL[1]); d.line([(11, 14), (11, 84)], fill=STEEL[1])
    for y in range(16, 84, 6):
        d.line([(8, y), (11, y + 6)], fill=STEEL[2])
    d.rectangle([2, 4, 17, 13], fill=STEEL[0])
    for i, x in enumerate((3, 7, 11, 15)):
        d.rectangle([x, 6, x + 2, 10], fill=(250, 244, 200) if i % 2 == 0 else (236, 226, 170))
    d.rectangle([6, 82, 13, 85], fill=STEEL[1])
    outline(im)
    return im


def crates():
    W, H = 48, 40
    im, d = img(W, H)
    shadow(d, [2, 32, 46, 39], 70)
    wood = [(92, 60, 34), (128, 88, 50), (160, 116, 66)]
    for (x0, y0, x1, y1) in ((4, 16, 24, 34), (24, 16, 44, 34), (12, 2, 32, 18)):
        d.rectangle([x0, y0, x1, y1], fill=wood[1], outline=wood[0])
        d.line([(x0, y0), (x1, y1)], fill=wood[0]); d.line([(x0 + 1, y0 + 1), (x0 + 1, y1 - 1)], fill=wood[2])
    d.polygon([(13, 2), (31, 2), (33, 9), (11, 9)], fill=(70, 96, 70))   # tarp
    d.polygon([(30, 20), (36, 26), (30, 32)], fill=RED[2])               # stencil mark (no text)
    outline(im)
    return im


def main():
    items = {
        "yard_fence": fence(), "yard_fence_v": fence(True), "yard_gate": gate(), "rocket": rocket(),
        "launch_pad": launch_pad(), "hangar": hangar(), "fuel_tank": tank(), "floodlight": floodlight(),
        "yard_crates": crates(),
    }
    for k, im in items.items():
        im.save(os.path.join(SP, k + ".png"))
        print("wrote", k, im.size)
    pv = Image.new("RGBA", (720, 220), (110, 150, 80, 255))
    x = 4
    for k in ("yard_fence", "yard_fence_v", "yard_gate", "rocket", "hangar", "fuel_tank", "floodlight", "yard_crates"):
        im = items[k]
        pv.alpha_composite(im, (x, 210 - im.height))
        x += im.width + 6
    pv = pv.resize((pv.width * 2, pv.height * 2), Image.NEAREST)
    pv.save("/tmp/vance_preview.png")


if __name__ == "__main__":
    main()
