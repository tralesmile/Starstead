#!/usr/bin/env python3
"""Streetball art for Starstead (original, CC0).

Run from repo root:  python3 tools/gen_basketball.py
Writes into assets/sprites/:
  bball_players.png  264x408  11 cols x 12 rows (4 crews x 3 players) of 24x34 frames, feet at y=32, centred on x=12
      crews: 0 Starstead Ballers, 1 Dockside Dunkers, 2 Highland Hammers, 3 Skyline Aces
      cols: 0 idle front, 1-4 run right, 5-6 run down, 7-8 run up (also idle seen from behind),
            9 jump shot from behind, 10 jump / block facing us
  bball_ball.png     44x11    4 rolling frames of 11x11
  bball_court.png    440x236  painted asphalt half court (rim ground point at 220,30; arc radius 150)
  bball_backdrop.png 640x360  brick wall, chain fence and benches round the court (court drawn at 100,112)
  bball_hoop.png     40x72    world prop: street hoop on its pole
Dark outlines, warm shading, light from the top left, like the other generators.
"""
import math
import os
import random

from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SPRITES = os.path.join(ROOT, "assets", "sprites")
FW, FH = 24, 34
OUT = (30, 18, 22, 255)


def rgb(h, a=255):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


def ramp(a, b, c):
    return (rgb(a), rgb(b), rgb(c))


SKINS = [ramp("#b06c4c", "#dc9c74", "#f6c49c"), ramp("#78462e", "#a4684a", "#c4875e"), ramp("#5a3222", "#80503a", "#9e6a4a")]
HAIRS = [rgb("#2c2632"), rgb("#7c4a26"), rgb("#d4a448"), rgb("#18141c"), rgb("#a4401e")]
KITS = [  # jersey, shorts, trim, shoes
    (ramp("#b47a18", "#f0b42c", "#ffdc62"), ramp("#101630", "#243060", "#3a4c84"), rgb("#243060"), rgb("#f4f0e8")),
    (ramp("#8e1c24", "#d23232", "#f25e48"), ramp("#2a1c20", "#443034", "#64484c"), rgb("#f6f0e6"), rgb("#f4f0e8")),
    (ramp("#12502c", "#1f8248", "#3cb466"), ramp("#0e2a1a", "#17422a", "#28643e"), rgb("#ffd24a"), rgb("#30303c")),
    (ramp("#a8a8b8", "#e6e4ee", "#ffffff"), ramp("#42186e", "#6c2ca8", "#9450d0"), rgb("#7c30c0"), rgb("#6c2ca8")),
]


class Fig:
    def __init__(self):
        self.img = Image.new("RGBA", (FW, FH))

    def part(self, px):
        """Stamp a set of {(x,y): colour} with its own 1px outline."""
        for (x, y) in px:
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                n = (x + dx, y + dy)
                if n not in px and 0 <= n[0] < FW and 0 <= n[1] < FH:
                    self.img.putpixel(n, OUT)
        for (x, y), c in px.items():
            if 0 <= x < FW and 0 <= y < FH:
                self.img.putpixel((x, y), c)


def limb(a, b, r, width=2, split=None, r2=None):
    """A shaded stroke from a to b; after fraction `split` it uses ramp r2."""
    px = {}
    n = max(abs(b[0] - a[0]), abs(b[1] - a[1]), 1)
    for i in range(n + 1):
        x = int(a[0] + (b[0] - a[0]) * i / n + 100.5) - 100
        y = int(a[1] + (b[1] - a[1]) * i / n + 100.5) - 100
        use = r2 if split is not None and i / n > split else r
        for k in range(width):
            px[(x + k, y)] = use[2] if k == 0 else use[1]
    return px


def block(rows, r):
    """rows: [(y, x0, x1)] shaded left light, right dark."""
    px = {}
    for y, x0, x1 in rows:
        for x in range(x0, x1 + 1):
            px[(x, y)] = r[2] if x <= x0 + 1 else (r[0] if x >= x1 - 1 else r[1])
    return px


def darker(r):
    return tuple(tuple(int(v * 0.76) for v in c[:3]) + (255,) for c in r)


def shoe(x, y, col, side):
    px = {(x + i, y + j): col for i in range(3 + side) for j in range(2)}
    for i in range(3 + side):
        px[(x + i, y + 1)] = tuple(int(v * 0.65) for v in col[:3]) + (255,)
    return px


def head(f, skin, hair, bob, view, style, band):
    """view: front, back, side."""
    top = 3 + bob
    rows = [(top + 1, 9, 14), (top + 2, 8, 15), (top + 3, 8, 15), (top + 4, 8, 15), (top + 5, 8, 15), (top + 6, 8, 15), (top + 7, 9, 14), (top + 8, 10, 13)]
    px = block(rows, skin)
    hr = (tuple(int(v * 0.7) for v in hair[:3]) + (255,), hair, tuple(min(255, int(v * 1.35) + 12) for v in hair[:3]) + (255,))
    cap = [(top, 10, 13), (top + 1, 9, 14), (top + 2, 8, 15)]
    if style == 1:   # tall flat top
        cap = [(top - 2, 9, 14), (top - 1, 9, 14)] + cap
    if style == 2:   # round afro
        cap = [(top - 2, 9, 14), (top - 1, 8, 15), (top, 7, 16), (top + 1, 7, 16), (top + 2, 7, 16), (top + 3, 7, 8), (top + 3, 15, 16)]
    px.update(block(cap, hr))
    if view == "back":
        px.update(block([(top + 3, 8, 15), (top + 4, 8, 15), (top + 5, 8, 15), (top + 6, 9, 14)], hr))
    elif view == "front":
        for ex in (10, 13):
            px[(ex, top + 5)] = OUT
        px[(11, top + 7)] = skin[0]
        px[(12, top + 7)] = skin[0]
    else:
        px.update(block([(top + 3, 8, 10), (top + 4, 8, 10), (top + 5, 8, 9)], hr))
        px[(14, top + 5)] = OUT
        px[(16, top + 6)] = skin[1]
    for x in range(8, 16):   # headband
        if (x, top + 3) in px and style != 2:
            px[(x, top + 3)] = band
    f.part(px)


def torso(f, kit, bob, view, lean=0):
    shirt, shorts, trim, _ = kit
    rows = [(13 + bob, 8 + lean, 15 + lean), (14 + bob, 7 + lean, 16 + lean), (15 + bob, 8 + lean, 15 + lean),
            (16 + bob, 8 + lean, 15 + lean), (17 + bob, 8 + lean, 15 + lean), (18 + bob, 8, 15), (19 + bob, 8, 15), (20 + bob, 8, 15)]
    if view == "side":
        rows = [(y, x0 + 1, x1 - 1) for y, x0, x1 in rows]
    px = block(rows, shirt)
    if view == "front":
        for x in (11, 12):
            px[(x + lean, 13 + bob)] = trim
        for x, y in ((11, 16), (12, 16), (12, 17), (11, 18), (12, 18)):
            px[(x, y + bob)] = trim
    elif view == "back":
        for x, y in ((10, 15), (11, 15), (13, 15), (13, 16), (11, 16), (10, 17), (11, 17), (13, 17), (10, 18), (13, 18), (11, 18)):
            px[(x, y + bob)] = trim
    for y, x0, x1 in rows:
        if y == 20 + bob:
            for x in range(x0, x1 + 1):
                px[(x, y)] = trim
    f.part(px)
    f.part(block([(21 + bob, 8, 15), (22 + bob, 8, 15), (23 + bob, 8, 15)], shorts))


def frame(crew, col, who):
    kit = KITS[crew]
    skin = SKINS[who % 3]
    hair = HAIRS[(who + crew) % 5]
    style = (crew + who) % 3
    shoe_c = kit[3]
    shorts = kit[1]
    sock = ramp("#b8b8c0", "#e8e8ee", "#ffffff")
    f = Fig()
    if 1 <= col <= 4:   # run right
        i = col - 1
        legs = [((16, 29), (7, 28)), ((13, 28), (11, 31)), ((8, 28), (16, 29)), ((11, 31), (13, 28))][i]
        bob = -1 if i % 2 else 0
        swing = [(-4, 5), (-1, 2), (5, -4), (2, -1)][i]
        far, near = legs[1], legs[0]
        f.part(limb((11, 15 + bob), (11 + swing[1], 20 + bob), darker(skin)))
        f.part(limb((11, 23 + bob), far, darker(shorts), 3, 0.45, darker(skin)))
        f.part(shoe(far[0] - 1, far[1], shoe_c, 1))
        f.part(limb((11, 23 + bob), near, shorts, 3, 0.45, skin))
        f.part(shoe(near[0] - 1, near[1], shoe_c, 1))
        torso(f, kit, bob, "side", 1)
        head(f, skin, hair, bob + 1, "side", style, kit[2])
        f.part(limb((12, 15 + bob), (12 + swing[0], 20 + bob), skin))
        return f.img
    view = "back" if col in (7, 8, 9) else "front"
    bob = 0
    lifts = (0, 0)
    if col in (5, 7):
        lifts = (3, 0)
        bob = -1
    if col in (6, 8):
        lifts = (0, 3)
        bob = -1
    jumping = col >= 9
    for side, x in enumerate((8, 13)):
        foot_y = 31 - lifts[side] - (2 if jumping and side == (1 if col == 9 else 0) else 0)
        foot_x = x + (-1 if side == 0 else 1) * (0 if jumping else 1)
        f.part(limb((x, 23 + bob), (foot_x, foot_y - 1), shorts, 3, 0.4, skin))
        f.part(limb((foot_x, foot_y - 3), (foot_x, foot_y - 1), sock, 3))
        f.part(shoe(foot_x, foot_y, shoe_c, 0))
    torso(f, kit, bob, view)
    head(f, skin, hair, bob + 1, view, style, kit[2])
    if col == 9:      # both hands up by the ball
        f.part(limb((7, 15), (6, 9), skin))
        f.part(limb((6, 9), (10, 2), skin))
        f.part(limb((16, 15), (16, 8), skin))
        f.part(limb((16, 8), (14, 2), skin))
    elif col == 10:   # arms stretched to block
        f.part(limb((7, 15), (3, 3), skin))
        f.part(limb((16, 15), (19, 3), skin))
    elif col == 0:    # ready stance, hands out
        f.part(limb((7, 15), (4, 20), skin))
        f.part(limb((16, 15), (18, 20), skin))
    else:
        a = 2 if lifts[0] else -1
        f.part(limb((7, 15), (5, 20 - a), skin))
        f.part(limb((16, 15), (17, 21 + a - 1), skin))
    return f.img


def make_players():
    # one row per crew; the view draws team mates with the same row, told apart by hair and skin via 3 variants
    sheet = Image.new("RGBA", (FW * 11, FH * 12))
    for crew in range(4):
        for who in range(3):
            for c in range(11):
                sheet.paste(frame(crew, c, who), (c * FW, (crew * 3 + who) * FH))
    return sheet


def make_ball():
    sheet = Image.new("RGBA", (44, 11))
    for fr in range(4):
        for y in range(11):
            for x in range(11):
                dx, dy = x - 5, y - 5
                d = math.hypot(dx, dy)
                if d > 5.4:
                    continue
                if d > 4.3:
                    c = OUT
                else:
                    c = rgb("#e8742a")
                    if dx + dy < -2:
                        c = rgb("#ff9c46")
                    if dx + dy > 2:
                        c = rgb("#b44e1c")
                    seam = fr - 1.5
                    if abs(dx - round(seam + dy * dy * 0.09 * (1 if fr < 2 else -1))) < 0.6 or dy == (1 if fr % 2 else 0):
                        c = rgb("#4a2010")
                    if (dx, dy) in ((-2, -3), (-3, -2)):
                        c = rgb("#ffd2a0")
                sheet.putpixel((fr * 11 + x, y), c)
    return sheet


def speckle(img, box, cols, n, rng, size=(1, 1)):
    d = ImageDraw.Draw(img)
    for _ in range(n):
        x = rng.randrange(box[0], box[2])
        y = rng.randrange(box[1], box[3])
        d.rectangle([x, y, x + size[0] - 1, y + size[1] - 1], fill=rng.choice(cols))


def make_court():
    rng = random.Random(46)
    w, h = 440, 236
    img = Image.new("RGBA", (w, h), rgb("#59606e"))
    speckle(img, (0, 0, w, h), [rgb("#626a79"), rgb("#515764"), rgb("#656d7a"), rgb("#4d5260")], 5200, rng)
    cx, cy, arc = 220, 30, 150
    # painted zones: brick red inside the arc, teal key
    paint = Image.new("RGBA", (w, h))
    d = ImageDraw.Draw(paint)
    d.ellipse([cx - arc, cy - arc, cx + arc, cy + arc], fill=rgb("#a4574a", 190))
    d.rectangle([cx - 42, 0, cx + 42, 108], fill=rgb("#2f7f86", 215))
    d.ellipse([cx - 30, 78, cx + 30, 138], fill=rgb("#2f7f86", 215))
    img.alpha_composite(paint)
    d = ImageDraw.Draw(img)
    line = rgb("#efe9d6")
    d.arc([cx - arc, cy - arc, cx + arc, cy + arc], 0, 180, fill=line, width=3)
    d.line([cx - arc, 0, cx - arc, cy], fill=line, width=3)
    d.line([cx + arc - 1, 0, cx + arc - 1, cy], fill=line, width=3)
    d.rectangle([cx - 42, -2, cx + 42, 108], outline=line, width=2)
    d.ellipse([cx - 30, 78, cx + 30, 138], outline=line, width=2)
    d.arc([cx - 24, cy - 24, cx + 24, cy + 24], 0, 180, fill=line, width=2)
    d.arc([cx - 34, h - 34, cx + 34, h + 34], 180, 360, fill=line, width=2)
    d.rectangle([0, 0, w - 1, h - 1], outline=line, width=2)
    for y in (58, 76, 94):   # hash marks on the key
        for x in (cx - 47, cx + 43):
            d.rectangle([x, y, x + 4, y + 2], fill=line)
    # wear: scuffed paint, cracks, a weed or two
    speckle(img, (0, 0, w, h), [rgb("#555c6a"), rgb("#6a6f7a")], 1100, rng, (2, 1))
    for _ in range(9):
        x, y = rng.randrange(10, w - 10), rng.randrange(10, h - 10)
        for _ in range(rng.randrange(12, 34)):
            d.point((x, y), fill=rgb("#353a46"))
            x += rng.choice((1, 1, 0, -1))
            y += rng.choice((0, 1, 0))
    for x, y in ((6, 8), (431, 214), (12, 226), (428, 20)):
        for _ in range(14):
            px, py = x + rng.randrange(-4, 5), y + rng.randrange(-2, 3)
            d.line([px, py, px + rng.randrange(-1, 2), py - 3], fill=rng.choice([rgb("#5c9440"), rgb("#7ab04c")]))
    return img


def make_backdrop():
    rng = random.Random(47)
    img = Image.new("RGBA", (640, 360), rgb("#3c3a44"))
    d = ImageDraw.Draw(img)
    for y in range(0, 108, 8):   # brick wall behind the hoop
        off = 8 if (y // 8) % 2 else 0
        for x in range(-16, 640, 20):
            c = rng.choice(["#8a4a3a", "#7c4034", "#945242", "#82463a"])
            d.rectangle([x + off, y, x + off + 18, y + 6], fill=rgb(c))
            d.line([x + off, y, x + off + 18, y], fill=rgb("#a8644e"))
    d.rectangle([0, 104, 640, 112], fill=rgb("#2a2630"))
    # original wall paint: star, wave stripes and blocks
    for cx, col in ((56, "#f0c23c"), (584, "#48b4c8")):
        pts = []
        for i in range(10):
            r = 30 if i % 2 == 0 else 13
            a = -math.pi / 2 + i * math.pi / 5
            pts.append((cx + r * math.cos(a), 74 + r * math.sin(a)))
        d.polygon(pts, fill=rgb(col), outline=OUT)
    for k, col in enumerate(("#48b4c8", "#efe9d6", "#d8567c")):
        d.line([(x, 66 + k * 9 + int(5 * math.sin(x / 11.0))) for x in range(96, 150)], fill=rgb(col), width=4)
        d.line([(x, 66 + k * 9 + int(5 * math.sin(x / 11.0))) for x in range(492, 546)], fill=rgb(col), width=4)
    speckle(img, (0, 112, 640, 360), [rgb("#45434e"), rgb("#34323c")], 2600, rng)
    # chain-link fence down both sides of the court
    for x0, x1 in ((0, 94), (546, 640)):
        for k in range(-260, 260, 9):
            for x in range(x0, x1):
                for y in (112 + (x + k) % 250, 112 + (k - x) % 250):
                    if y < 350:
                        img.putpixel((x, y), rgb("#8c93a0", 255) if x % 3 else rgb("#6c7280"))
        for px in (x0 + 2, (x0 + x1) // 2, x1 - 4):
            d.rectangle([px, 104, px + 3, 352], fill=rgb("#a8aebc"), outline=OUT)
        d.rectangle([x0, 106, x1, 109], fill=rgb("#a8aebc"), outline=OUT)
    # benches, bags and bottles beside the court
    for bx, by in ((22, 190), (562, 190), (22, 268), (562, 268)):
        d.rectangle([bx, by + 8, bx + 56, by + 11], fill=rgb("#0000002c"[:7]))
        d.rectangle([bx, by, bx + 56, by + 7], fill=rgb("#b87c42"), outline=OUT)
        d.line([bx + 1, by + 1, bx + 55, by + 1], fill=rgb("#dca464"))
        for lx in (bx + 4, bx + 48):
            d.rectangle([lx, by + 8, lx + 4, by + 15], fill=rgb("#4c4c58"), outline=OUT)
        bag = rng.choice(["#d23232", "#2f7f86", "#f0b42c", "#6c2ca8"])
        d.rounded_rectangle([bx + rng.randrange(4, 30), by - 8, bx + 44, by + 2], 4, fill=rgb(bag), outline=OUT)
        d.rectangle([bx + 50, by - 7, bx + 53, by + 1], fill=rgb("#8cd8f0"), outline=OUT)
    d.rectangle([97, 109, 542, 351], outline=rgb("#221e28"), width=3)
    d.rectangle([0, 350, 640, 360], fill=rgb("#221e28"))
    return img


def make_prop():
    img = Image.new("RGBA", (40, 72))
    d = ImageDraw.Draw(img)
    d.ellipse([9, 65, 31, 71], fill=(0, 0, 0, 60))
    d.rectangle([14, 62, 26, 69], fill=rgb("#7c808c"), outline=OUT)
    d.rectangle([18, 24, 22, 64], fill=rgb("#8c93a0"), outline=OUT)
    d.line([19, 25, 19, 63], fill=rgb("#c4cad6"))
    d.rectangle([17, 44, 23, 54], fill=rgb("#d23232"), outline=OUT)   # pole pad
    d.rectangle([3, 2, 37, 26], fill=rgb("#efe9d6"), outline=OUT)
    d.rectangle([5, 4, 35, 24], outline=rgb("#d23232"))
    d.rectangle([14, 12, 26, 21], outline=rgb("#d23232"))
    for i in range(5):   # net
        x = 13 + i * 3.5
        d.line([x, 25, 20 + (x - 20) * 0.5, 37], fill=rgb("#f4f4f4"))
    d.line([15, 30, 25, 30], fill=rgb("#d8d8e0"))
    d.line([17, 34, 23, 34], fill=rgb("#d8d8e0"))
    d.ellipse([12, 21, 28, 27], outline=OUT, width=3)
    d.ellipse([13, 22, 27, 26], outline=rgb("#ff7a22"), width=1)
    d.ellipse([30, 62, 39, 70], fill=rgb("#e8742a"), outline=OUT)
    d.line([31, 66, 38, 66], fill=rgb("#4a2010"))
    return img


def main():
    for name, img in (("bball_players", make_players()), ("bball_ball", make_ball()), ("bball_court", make_court()),
                      ("bball_backdrop", make_backdrop()), ("bball_hoop", make_prop())):
        img.save(os.path.join(SPRITES, name + ".png"))
        print(name, img.size)


if __name__ == "__main__":
    main()
