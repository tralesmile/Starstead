#!/usr/bin/env python3
"""Football match art for Starstead (original, CC0).

Run from repo root:  python3 tools/gen_football.py
Writes into assets/sprites/:
  football_players.png  192x160  8 cols x 5 rows of 24x32 frames, feet at y=30, centred on x=12
      rows: 0 Starstead Rovers, 1 Dockers, 2 Vance XI, 3 Highland Miners, 4 goalkeeper
      cols: 0-3 run right (0 = idle), 4 kick right, 5-6 run down, 7 facing up
  football_ball.png     40x10    4 rolling frames of 10x10
  football_goal.png     28x96    LEFT goal, goal line = right edge (mirror for the right goal)
  football_crowd.png    320x48   two tileable 320x24 frames (bottom one = cheering)
Same look as the other generators: dark outlines, warm shading, light from the top left.
"""
import os
import random

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SPRITES = os.path.join(ROOT, "assets", "sprites")
FW, FH = 24, 32
OUTLINE = (34, 20, 24, 255)


def rgb(h, a=255):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


def ramp(shade, base, light):
    return (rgb(shade), rgb(base), rgb(light))


SKINS = [
    ramp("#b06c4c", "#dc9c74", "#f6c49c"),
    ramp("#78462e", "#a4684a", "#c4875e"),
    ramp("#5a3222", "#80503a", "#9e6a4a"),
]
HAIR = [  # one per kit row
    ramp("#4e2c18", "#7c4a26", "#a86c36"),
    ramp("#18141c", "#2c2632", "#4a4052"),
    ramp("#a0742e", "#d4a448", "#f4d476"),
    ramp("#782814", "#b0461e", "#dc6c30"),
    ramp("#2c1c14", "#48301e", "#6c482c"),
]
ROW_SKIN = [0, 1, 0, 0, 2]
BOOT = ramp("#17141c", "#2a2632", "#524c5e")
GLOVE = ramp("#a8b0c0", "#e4e8ee", "#ffffff")

KITS = [
    dict(shirt=ramp("#b47a18", "#eab02c", "#ffda5e"), shorts=ramp("#101630", "#202c54", "#34447a"),
         sock=ramp("#b47a18", "#eab02c", "#ffda5e"), trim=rgb("#202c54"), stripes=None),
    dict(shirt=ramp("#9c1e22", "#d2322e", "#f05a48"), shorts=ramp("#a8a4a8", "#dedad6", "#fcf8f0"),
         sock=ramp("#9c1e22", "#d2322e", "#f05a48"), trim=rgb("#f6f0e6"),
         stripes=ramp("#beb6b2", "#eee8e0", "#fffcf6")),
    dict(shirt=ramp("#b4b4bc", "#e8e6e4", "#fffdf6"), shorts=ramp("#0c5058", "#14808a", "#2cacaa"),
         sock=ramp("#b4b4bc", "#e8e6e4", "#fffdf6"), trim=rgb("#169098"), stripes=None),
    dict(shirt=ramp("#12361e", "#1e5430", "#347844"), shorts=ramp("#0e2616", "#183c24", "#285634"),
         sock=ramp("#b05410", "#e87c1c", "#ffa63e"), trim=rgb("#f28820"), stripes=None),
    dict(shirt=ramp("#561a90", "#842cd0", "#b056f6"), shorts=ramp("#2a1444", "#401e66", "#5c308c"),
         sock=ramp("#561a90", "#842cd0", "#b056f6"), trim=rgb("#d8a8ff"), stripes=None),
]


# ------------------------------------------------------------------ pixel helpers
class Part:
    """A set of pixels that receives its own 1px outline when stamped."""

    def __init__(self):
        self.px = {}

    def put(self, x, y, c):
        self.px[(int(x), int(y))] = c

    def row(self, y, x0, x1, c):
        for x in range(x0, x1 + 1):
            self.put(x, y, c)

    def shaded_row(self, y, x0, x1, r):
        for x in range(x0, x1 + 1):
            self.put(x, y, r[2] if x == x0 else (r[0] if x == x1 else r[1]))


def stamp(img, part, outline=OUTLINE, soft=False):
    """soft: where the outline falls on pixels already drawn, only darken them (keeps limbs readable)."""
    w, h = img.size
    if outline:
        for (x, y) in part.px:
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                n = (x + dx, y + dy)
                if n not in part.px and 0 <= n[0] < w and 0 <= n[1] < h:
                    under = img.getpixel(n)
                    if soft and under[3] == 255 and under != OUTLINE:
                        img.putpixel(n, tuple(int(v * 0.55) for v in under[:3]) + (255,))
                    else:
                        img.putpixel(n, outline)
    for (x, y), c in part.px.items():
        if 0 <= x < w and 0 <= y < h:
            img.putpixel((x, y), c)


def line_pts(a, b):
    n = max(abs(b[0] - a[0]), abs(b[1] - a[1]), 1)
    return [(int(a[0] + (b[0] - a[0]) * i / n + 100.5) - 100,
             int(a[1] + (b[1] - a[1]) * i / n + 100.5) - 100) for i in range(n + 1)]


def tone(r, k):
    """Darker copy of a ramp for limbs on the far side."""
    if not k:
        return r
    return tuple(tuple(int(v * 0.74) for v in c[:3]) + (255,) for c in r)


# ------------------------------------------------------------------ side view
def side_leg(img, kit, skin, hip, knee, ankle, far, toe=(1, 0)):
    p = Part()
    shorts, skin, sock, boot = (tone(r, far) for r in (kit["shorts"], skin, kit["sock"], BOOT))
    upper = line_pts(hip, knee)
    for i, (x, y) in enumerate(upper):
        c = shorts if i <= len(upper) // 2 else skin
        p.put(x, y, c[1])
        p.put(x + 1, y, c[0] if c is skin else c[1])
    for i, (x, y) in enumerate(line_pts(knee, ankle)):
        c = skin if i == 0 else sock
        p.put(x, y, c[2] if i == 1 else c[1])
        p.put(x + 1, y, c[0])
    ax, ay = ankle
    p.put(ax, ay + 1, boot[1])
    p.put(ax + 1, ay + 1, boot[1])
    p.put(ax + 2 * toe[0], ay + 1 + toe[1], boot[2])
    if toe[1]:
        p.put(ax + 1, ay + 1 + toe[1], boot[1])
    stamp(img, p)


def arm(img, kit, skin, shoulder, elbow, hand, far=False, keeper=False):
    p = Part()
    sh, sk, gl = (tone(r, far) for r in (kit["shirt"], skin, GLOVE))
    upper = line_pts(shoulder, elbow)
    for i, (x, y) in enumerate(upper):
        c = sh[1] if (keeper or i < len(upper) - 1) else sk[1]
        p.put(x, y, c)
        p.put(x + 1, y, sh[0] if (keeper or i < len(upper) - 1) else sk[0])
    for (x, y) in line_pts(elbow, hand)[1:]:
        p.put(x, y, sh[1] if keeper else sk[1])
    hx, hy = hand
    if keeper:
        for dx in (-1, 0, 1):
            for dy in (0, 1, 2):
                if (dx, dy) != (-1, 2):
                    p.put(hx + dx, hy + dy - 1, gl[2] if dy == 0 else (gl[0] if dx == 1 and dy == 2 else gl[1]))
    else:
        p.put(hx, hy, sk[2])
        p.put(hx, hy + 1, sk[1])
    stamp(img, p, soft=True)


def torso_colour(kit, x, level, x0, x1):
    r = kit["shirt"]
    if kit["stripes"] and (x - x0) % 4 in (2, 3):
        r = kit["stripes"]
    if level == "shade" or x >= x1:
        return r[0]
    if x <= x0 + 1 and level == "top":
        return r[2]
    return r[1]


def side_torso(img, kit, lean, bob):
    p = Part()
    spans = [(17, 9, 14), (18, 8, 15), (19, 8, 15), (20, 9, 14), (21, 9, 14), (22, 9, 14)]
    for y, a, b in spans:
        s = lean if y <= 19 else 0
        for x in range(a, b + 1):
            lvl = "top" if y <= 19 else ("shade" if y == 22 else "mid")
            p.put(x + s, y + bob, torso_colour(kit, x, lvl, a, b))
    # collar
    p.row(17 + bob, 11 + lean, 13 + lean, kit["trim"])
    stamp(img, p)
    sh = Part()
    for y, a, b in [(23, 9, 14), (24, 9, 14)]:
        sh.shaded_row(y + bob, a, b, kit["shorts"])
    sh.row(23 + bob, 11, 11, kit["trim"])
    stamp(img, sh)


def side_head(img, skin, hair, lean, bob, style):
    ox, oy = lean, bob
    p = Part()
    face = {8: (10, 15), 9: (9, 16), 10: (9, 16), 11: (9, 16), 12: (9, 17), 13: (9, 16),
            14: (10, 16), 15: (11, 15)}
    for y, (a, b) in face.items():
        for x in range(a, b + 1):
            p.put(x + ox, y + oy, skin[0] if y == 15 else skin[1])
    for x in (14, 15):
        p.put(x + ox, 10 + oy, skin[2])
    p.put(17 + ox, 12 + oy, skin[2])
    # hair: crown, back of head, fringe
    cells = {6: (10, 14), 7: (9, 15), 8: (8, 16), 9: (8, 16), 10: (8, 12), 11: (8, 11), 12: (8, 10),
             13: (9, 10)}
    for y, (a, b) in cells.items():
        for x in range(a, b + 1):
            p.put(x + ox, y + oy, hair[1])
    for x, y in ((11, 7), (12, 7), (13, 7), (10, 8), (11, 8), (14, 8), (15, 8)):
        p.put(x + ox, y + oy, hair[2])
    for x, y in ((8, 11), (8, 12), (9, 13), (10, 13), (10, 12), (9, 12), (14, 9), (15, 9), (16, 9)):
        p.put(x + ox, y + oy, hair[0])
    if style == 1:      # cropped, taller top
        p.row(5 + oy, 11 + ox, 14 + ox, hair[1])
    elif style == 2:    # floppy fringe
        p.put(17 + ox, 9 + oy, hair[1])
        p.put(7 + ox, 12 + oy, hair[1])
        p.put(7 + ox, 13 + oy, hair[0])
    elif style == 3:    # spiky
        for x, y in ((10, 5), (13, 5), (7, 8), (7, 10)):
            p.put(x + ox, y + oy, hair[1])
    # ear, eye, mouth
    p.put(11 + ox, 12 + oy, skin[2])
    p.put(11 + ox, 13 + oy, skin[0])
    p.put(15 + ox, 11 + oy, OUTLINE)
    p.put(15 + ox, 12 + oy, OUTLINE)
    p.put(15 + ox, 14 + oy, skin[0])
    stamp(img, p)
    neck = Part()
    neck.put(12 + ox, 16 + oy, skin[0])
    neck.put(13 + ox, 16 + oy, skin[0])
    stamp(img, neck, None)


STYLES = [0, 1, 2, 3, 0]

# Per frame: bob, lean, near leg, far leg (hip, knee, ankle[, toe]), near arm, far arm (shoulder, elbow, hand)
SIDE = [
    dict(bob=0, lean=0,   # idle / passing
         near=((11, 24), (12, 26), (12, 28)), far=((11, 24), (10, 26), (9, 28)),
         arm_n=((10, 18), (9, 20), (10, 22)), arm_f=((14, 18), (15, 20), (16, 21))),
    dict(bob=-1, lean=1,  # near leg forward
         near=((11, 23), (14, 26), (16, 28)), far=((11, 23), (9, 25), (6, 26), (-1, 1)),
         arm_n=((10, 17), (7, 19), (5, 21)), arm_f=((14, 17), (17, 19), (19, 17))),
    dict(bob=0, lean=1,   # passing, far knee up
         near=((11, 24), (11, 26), (11, 28)), far=((11, 24), (15, 25), (12, 26)),
         arm_n=((10, 18), (10, 20), (12, 22)), arm_f=((14, 18), (15, 20), (17, 20))),
    dict(bob=-1, lean=1,  # far leg forward
         near=((11, 23), (9, 25), (6, 26), (-1, 1)), far=((11, 23), (14, 26), (16, 28)),
         arm_n=((11, 17), (14, 19), (17, 18)), arm_f=((12, 17), (8, 19), (6, 20))),
    dict(bob=0, lean=-1,  # kick
         near=((12, 24), (15, 25), (19, 24), (1, -1)), far=((10, 24), (10, 26), (9, 28)),
         arm_n=((10, 18), (7, 18), (4, 17)), arm_f=((13, 18), (16, 19), (18, 18))),
]


def draw_side(row, f):
    img = Image.new("RGBA", (FW, FH))
    kit, skin, hair = KITS[row], SKINS[ROW_SKIN[row]], HAIR[row]
    keeper = row == 4
    d = SIDE[f]
    b, ln = d["bob"], d["lean"]
    sx = lambda pts: [(pts[0][0] + ln, pts[0][1]), (pts[1][0], pts[1][1]), (pts[2][0], pts[2][1])]
    arm(img, kit, skin, *sx(d["arm_f"]), far=True, keeper=keeper)
    leg_f, leg_n = d["far"], d["near"]
    side_leg(img, kit, skin, *leg_f[:3], far=True, toe=leg_f[3] if len(leg_f) > 3 else (1, 0))
    side_leg(img, kit, skin, *leg_n[:3], far=False, toe=leg_n[3] if len(leg_n) > 3 else (1, 0))
    side_torso(img, kit, ln, b)
    side_head(img, skin, hair, ln, b, STYLES[row])
    arm(img, kit, skin, *sx(d["arm_n"]), keeper=keeper)
    return img


# ------------------------------------------------------------------ front / back view
def front_leg(img, kit, skin, x, lift, back):
    """x = left column of a 2px wide leg; lift raises the foot (shorter, tucked leg)."""
    p = Part()
    far = lift > 0
    sk, sock, boot = (tone(r, far and back is False) for r in (skin, kit["sock"], BOOT))
    foot = 29 - lift
    for y in range(24, foot):
        r = kit["shorts"] if y <= 24 else (sk if y <= 25 else sock)
        if y >= foot - 2 and r is sk:
            r = sock
        p.put(x, y, r[2] if y == foot - 3 else r[1])
        p.put(x + 1, y, r[0])
    p.row(foot, x, x + 1, boot[1])
    p.put(x + (0 if x < 12 else 1), foot, boot[2])
    stamp(img, p)


def front_torso(img, kit, bob, back):
    p = Part()
    spans = [(17, 9, 14), (18, 8, 15), (19, 8, 15), (20, 8, 15), (21, 8, 15), (22, 8, 15)]
    for y, a, b in spans:
        for x in range(a, b + 1):
            lvl = "top" if y <= 19 else ("shade" if y == 22 else "mid")
            p.put(x, y + bob, torso_colour(kit, x, lvl, 8, 15))
    p.row(17 + bob, 10, 13, kit["trim"])
    if back:    # squad number
        num = kit["trim"] if not kit["stripes"] else rgb("#241418")
        if kit["stripes"]:
            for y in range(19, 22):
                p.row(y + bob, 10, 13, kit["stripes"][1])
        for x, y in ((11, 19), (12, 19), (12, 20), (12, 21), (11, 21), (13, 21)):
            p.put(x, y + bob, num)
    else:
        p.put(11, 18 + bob, kit["trim"])
        p.put(12, 18 + bob, kit["trim"])
        p.put(13, 19 + bob, kit["trim"] if not kit["stripes"] else rgb("#241418"))
    stamp(img, p)
    sh = Part()
    sh.shaded_row(23 + bob, 8, 15, kit["shorts"])
    sh.shaded_row(24 + bob, 8, 15, kit["shorts"])
    sh.put(11, 24 + bob, kit["shorts"][0])
    sh.put(12, 24 + bob, kit["shorts"][0])
    sh.put(8, 23 + bob, kit["trim"])
    sh.put(15, 23 + bob, kit["trim"])
    stamp(img, sh)


def front_head(img, skin, hair, bob, back, style):
    p = Part()
    shape = {7: (10, 13), 8: (9, 14), 9: (8, 15), 10: (8, 15), 11: (8, 15), 12: (8, 15),
             13: (8, 15), 14: (9, 14), 15: (10, 13)}
    for y, (a, b) in shape.items():
        for x in range(a, b + 1):
            p.put(x, y + bob, skin[0] if (y == 15 or x == 15) else skin[1])
    top = {6: (10, 13), 7: (9, 14), 8: (8, 15), 9: (8, 15)}
    for y, (a, b) in top.items():
        for x in range(a, b + 1):
            p.put(x, y + bob, hair[1])
    for y in (10, 11):
        p.put(8, y + bob, hair[1])
        p.put(15, y + bob, hair[0])
    for x, y in ((10, 7), (11, 7), (9, 8), (10, 8), (12, 7)):
        p.put(x, y + bob, hair[2])
    if style == 1:
        p.row(5 + bob, 10, 13, hair[1])
    elif style == 2:
        for x, y in ((9, 10), (10, 10), (11, 10), (7, 10), (7, 11), (16, 10), (16, 11)):
            p.put(x, y + bob, hair[1])
    elif style == 3:
        for x, y in ((9, 5), (12, 5), (15, 6), (7, 9)):
            p.put(x, y + bob, hair[1])
    if back:
        for y, a, b in ((10, 8, 15), (11, 8, 15), (12, 8, 15), (13, 9, 14), (14, 10, 13)):
            for x in range(a, b + 1):
                p.put(x, y + bob, hair[0] if (x >= 14 or y >= 13) else hair[1])
        for x in (7, 16):
            p.put(x, 12 + bob, skin[1])
            p.put(x, 13 + bob, skin[0])
    else:
        for x in (10, 13):
            p.put(x, 11 + bob, OUTLINE)
            p.put(x, 12 + bob, OUTLINE)
        for x in (9, 14):
            p.put(x, 13 + bob, skin[2])
        p.put(11, 14 + bob, skin[0])
        p.put(12, 14 + bob, skin[0])
        p.put(10, 10 + bob, skin[2])
        for x in (7, 16):
            p.put(x, 12 + bob, skin[1])
    stamp(img, p)
    n = Part()
    n.put(11, 16 + bob, skin[0])
    n.put(12, 16 + bob, skin[0])
    stamp(img, n, None)


def draw_front(row, col):
    img = Image.new("RGBA", (FW, FH))
    kit, skin, hair = KITS[row], SKINS[ROW_SKIN[row]], HAIR[row]
    keeper = row == 4
    back = col == 7
    bob = -1 if col in (5, 6) else 0
    lifts = {5: (0, 3), 6: (3, 0), 7: (0, 0)}[col]
    front_leg(img, kit, skin, 9, lifts[0], back)
    front_leg(img, kit, skin, 13, lifts[1], back)
    if col == 5:    # arms swing against the legs: raised hand opposite the planted foot's partner
        arms = [((7, 18), (5, 19), (5, 17)), ((15, 18), (17, 20), (17, 23))]
    elif col == 6:
        arms = [((7, 18), (5, 20), (5, 23)), ((15, 18), (17, 19), (17, 17))]
    else:
        spread = 1 if keeper else 0
        arms = [((7, 18), (6 - spread, 20), (6 - spread, 22)), ((15, 18), (16 + spread, 20), (16 + spread, 22))]
    for a in arms:
        arm(img, kit, skin, (a[0][0], a[0][1] + bob), (a[1][0], a[1][1] + bob), (a[2][0], a[2][1] + bob),
            keeper=keeper)
    front_torso(img, kit, bob, back)
    front_head(img, skin, hair, bob, back, STYLES[row])
    return img


def make_players():
    sheet = Image.new("RGBA", (FW * 8, FH * 5))
    for r in range(5):
        for c in range(8):
            fr = draw_side(r, c) if c <= 4 else draw_front(r, c)
            sheet.paste(fr, (c * FW, r * FH))
    return sheet


# ------------------------------------------------------------------ ball
BALL_FRAMES = [  # 8x8 insides; '#' = black patch. The centre patch rolls off right as the next arrives.
    ["...##...", "...##...", "........", "#..##...", "#.####.#", "...##..#", "........", "..##...."],
    ["....##..", "........", "#.......", "#...##..", "...####.", "....##..", "##......", ".#...#.."],
    [".....##.", "##......", "##......", ".....##.", ".....###", ".....##.", "...#....", "..###..."],
    [".##.....", ".#....#.", "......##", ".##.....", "####....", ".##....#", "......##", "....##.."],
]


def make_ball():
    sheet = Image.new("RGBA", (40, 10))
    for f, rows in enumerate(BALL_FRAMES):
        img = Image.new("RGBA", (10, 10))
        p = Part()
        for y in range(1, 9):
            for x in range(1, 9):
                dx, dy = x - 4.5, y - 4.5
                if dx * dx + dy * dy <= 17.0:
                    lit = -(dx + dy)
                    if rows[y - 1][x - 1] == "#":
                        c = rgb("#4e4858") if lit > 2 else rgb("#241e2a")
                    elif lit < -3.0:
                        c = rgb("#a6a4b2")
                    elif lit < -0.5:
                        c = rgb("#d6d3d6")
                    else:
                        c = rgb("#fbf8ee")
                    p.put(x, y, c)
        stamp(img, p)
        sheet.paste(img, (f * 10, 0))
    return sheet


# ------------------------------------------------------------------ goal
def make_goal():
    """Left goal in 3/4 view: front posts on the right edge, net running back to the left."""
    w, h = 28, 96
    img = Image.new("RGBA", (w, h))
    top, bot = 4, 91
    back = 4            # x of the back frame
    # soft shadow, thrown down and right of the frame
    for y in range(h):
        for x in range(w):
            if back + 1 <= x <= 25 and top + 4 <= y <= bot + 3:
                edge = min(x - back - 1, 25 - x, y - top - 4, bot + 3 - y)
                img.putpixel((x, y), (16, 30, 20, 34 if edge == 0 else 58))

    def blend(x, y, c):
        if 0 <= x < w and 0 <= y < h:
            img.alpha_composite(Image.new("RGBA", (1, 1), c), (x, y))

    # net floor / roof: faint haze then diamond mesh
    def inside(x, y):
        inset = max(0, (back + 5) - x) // 2       # rounded back corners
        return back <= x <= 24 and top + inset <= y <= bot - inset

    for y in range(top, bot + 1):
        for x in range(back, 25):
            if not inside(x, y):
                continue
            deep = (24 - x) / 20.0
            blend(x, y, (20, 34, 30, int(20 + 50 * deep)))        # darker toward the back: depth
            if (x + y) % 6 == 0 or (x - y) % 6 == 0:
                blend(x, y, (236, 240, 236, int(200 - 65 * deep)))
    # side netting is seen at an angle: a denser band along both side bars
    for x in range(back + 4, 25):
        for k in range(1, 4):
            for y in (top + k, bot - k):
                if (x + k) % 2 == 0:
                    blend(x, y, (244, 246, 242, 150))

    def bar(pts, light, shade):
        p = Part()
        for x, y, c in pts:
            p.put(x, y, light if c else shade)
        stamp(img, p)

    grey, dgrey = rgb("#c4c6cc"), rgb("#8e919c")
    # back frame and rear stanchions
    rear = [(back, y, 1) for y in range(top + 4, bot - 3)]
    rear += [(x, y, 0) for x, y in line_pts((back, top + 4), (back + 5, top + 1))]
    rear += [(x, y, 0) for x, y in line_pts((back, bot - 4), (back + 5, bot - 1))]
    bar(rear, grey, dgrey)
    white, soft = rgb("#fbf9f0"), rgb("#cfccc8")
    # side bars running back from the posts
    for y in (top, bot):
        bar([(x, y, 1) for x in range(back + 6, 25)], rgb("#e6e4e0"), dgrey)
    # crossbar along the goal mouth, then the chunky post caps
    frame = Part()
    for y in range(top, bot + 1):
        frame.put(24, y, white)
        frame.put(25, y, white)
        frame.put(26, y, soft)
    for cy in (top, bot):
        for y in range(cy - 2, cy + 3):
            for x in range(23, 27):
                if not (x in (23, 26) and y in (cy - 2, cy + 2)):
                    frame.put(x, y, soft if (x == 26 or y == cy + 2) else white)
    stamp(img, frame)
    return img


# ------------------------------------------------------------------ crowd
CW, CH = 320, 24
SCARVES = ["#eab02c", "#d2322e", "#169098", "#2e7a3e", "#8a34d0", "#e87c1c", "#3a64c0", "#eee8e0"]
COATS = [("#3a2c44", "#554262"), ("#28405a", "#3a5a7c"), ("#5a2c28", "#7c403a"), ("#2c4c34", "#40684a"),
         ("#5a4426", "#7e6238"), ("#44444e", "#62626e"), ("#8a6420", "#b4862c")]
CROWD_HAIR = ["#2c2632", "#5a3418", "#8a5226", "#d4a448", "#a4401e", "#b0b0b8"]


def wrap_stamp(img, part, outline=OUTLINE):
    """Stamp with horizontal wrap-around so the strip tiles."""
    q = Part()
    for (x, y), c in part.px.items():
        q.put(x, y, c)
    if outline:
        for (x, y) in q.px:
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                if (x + dx, y + dy) not in q.px and 0 <= y + dy < img.size[1]:
                    img.putpixel(((x + dx) % img.size[0], y + dy), outline)
    for (x, y), c in q.px.items():
        if 0 <= y < img.size[1]:
            img.putpixel((x % img.size[0], y), c)


def spectator(img, x, y, rng_vals, cheer, dim):
    coat, hair, skin_i, scarf, hat, wave = rng_vals

    def d(c):
        return tuple(int(v * dim) for v in c[:3]) + (255,)

    skin = SKINS[skin_i]
    coat_s, coat_l = d(rgb(COATS[coat][0])), d(rgb(COATS[coat][1]))
    sc = d(rgb(SCARVES[scarf]))
    up = cheer and wave > 0
    hop = -1 if up else 0
    raised, overhead = [], None
    if up:      # raised arms: a V of sleeves with pale hands up by the top of the head
        sides = (-1, 1) if wave in (1, 3) else ((1,) if x % 4 < 2 else (-1,))
        for s_ in sides:
            a = Part()
            inner = x + (-5 if s_ < 0 else 4)
            for k in range(3, 9):
                sleeve = tuple(min(255, int(v * 1.45)) for v in coat_l[:3]) + (255,)
                a.put(inner + (s_ if k < 6 else 0), y + k + hop, sleeve)
            for k in (1, 2):
                a.put(inner + s_, y + k + hop, d(skin[2]))
            a.put(inner + 2 * s_, y + 1 + hop, d(skin[2]))
            raised.append(a)
        if wave == 3:   # scarf stretched between the hands
            a = Part()
            for k in range(-5, 5):
                a.put(x + k, y - 1 + hop + 1, sc if ((k + 6) // 2) % 2 else d(rgb("#f6f0e6")))
            overhead = a
    body = Part()
    for dy, half in ((7, 3), (8, 4), (9, 4), (10, 4), (11, 4)):
        for k in range(-half, half):
            body.put(x + k, y + dy + hop, coat_l if k < 0 else coat_s)
    wrap_stamp(img, body)
    head = Part()
    for dy, a_, b_ in ((1, -2, 1), (2, -3, 2), (3, -3, 2), (4, -3, 2), (5, -3, 2), (6, -2, 1)):
        for k in range(a_, b_ + 1):
            head.put(x + k, y + dy + hop, d(skin[0] if k == b_ else skin[1]))
    hc = d(rgb(CROWD_HAIR[hair]))
    for dy, a_, b_ in ((1, -2, 1), (2, -3, 2)):
        for k in range(a_, b_ + 1):
            head.put(x + k, y + dy + hop, hc)
    head.put(x - 3, y + 3 + hop, hc)
    head.put(x + 2, y + 3 + hop, hc)
    if hat:     # bobble hat in a team colour
        for dy, a_, b_ in ((1, -2, 1), (2, -3, 2)):
            for k in range(a_, b_ + 1):
                head.put(x + k, y + dy + hop, sc)
        head.put(x - 1, y + hop, d(rgb("#f6f0e6")))
        head.put(x, y + hop, d(rgb("#f6f0e6")))
    head.put(x - 2, y + 4 + hop, OUTLINE)
    head.put(x + 1, y + 4 + hop, OUTLINE)
    if up:
        head.put(x - 1, y + 5 + hop, d(rgb("#5a2420")))
        head.put(x, y + 5 + hop, d(rgb("#5a2420")))
    wrap_stamp(img, head)
    s = Part()
    for k in range(-3, 3):
        s.put(x + k, y + 7 + hop, sc)
    tail = x + (1 if wave % 2 else -2)
    s.put(tail, y + 8 + hop, sc)
    s.put(tail, y + 9 + hop, d(rgb("#f6f0e6")))
    wrap_stamp(img, s, None)
    for a in raised:        # in front of neighbours so the cheer reads at 1x
        wrap_stamp(img, a, None)
    if overhead:
        wrap_stamp(img, overhead)


def plank(img, y0, y1):
    light, base, seam = rgb("#c48a50"), rgb("#9c6636"), rgb("#6a4024")
    for y in range(y0, y1 + 1):
        for x in range(CW):
            c = light if y == y0 else (seam if y == y1 else base)
            off = (x + (y0 * 7)) % 40
            if off == 0 and y > y0:
                c = seam
            elif off in (3, 36) and y == y0 + 1:
                c = rgb("#3c2418")
            elif y == y0 + 1 and (x * 13 + y0) % 17 < 3:
                c = rgb("#8a5830")
            img.putpixel((x, y), c)


def make_crowd_frame(cheer):
    img = Image.new("RGBA", (CW, CH), rgb("#3a2620"))
    for x in range(CW):
        if x % 16 == 0:
            for y in range(CH):
                img.putpixel((x, y), rgb("#2a1a16"))
    rng = random.Random(1126)
    rows = []
    for r in range(2):
        people = []
        for i in range(CW // 10):
            vals = (rng.randrange(len(COATS)), rng.randrange(len(CROWD_HAIR)), rng.choice((0, 0, 0, 1, 2)),
                    rng.randrange(len(SCARVES)), rng.random() < 0.25,
                    rng.choice((0, 1, 1, 2, 3 if i % 3 == 0 else 2)))
            people.append((i * 10 + (5 if r == 0 else 10) + rng.choice((-1, 0, 0, 1)),
                           rng.choice((0, 0, 1)), vals))
        rows.append(people)
    # back row, its bench rail, then the front row and the front rail
    for x, j, v in rows[0]:
        spectator(img, x, 1 + j, v, cheer, 0.80)
    plank(img, 11, 13)
    for x, j, v in rows[1]:
        spectator(img, x, 10 + j, v, cheer, 1.0)
    plank(img, 20, 23)
    return img


def make_crowd():
    sheet = Image.new("RGBA", (CW, CH * 2))
    sheet.paste(make_crowd_frame(False), (0, 0))
    sheet.paste(make_crowd_frame(True), (0, CH))
    return sheet


def main():
    os.makedirs(SPRITES, exist_ok=True)
    for name, img in (("football_players.png", make_players()), ("football_ball.png", make_ball()),
                      ("football_goal.png", make_goal()), ("football_crowd.png", make_crowd())):
        img.save(os.path.join(SPRITES, name))
        print("wrote assets/sprites/" + name, img.size)


if __name__ == "__main__":
    main()
