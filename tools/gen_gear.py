#!/usr/bin/env python3
"""Animal clothing overlays (original, CC0). Deterministic.
One sheet per (animal, slot) in data/animals.json gear_slots: gear_<animal>_<slot>.png, same size and
2-frame layout as <animal>.png, transparent except the gear. Draw order: animal, coat, armour, saddle.
All animals face right. Cloth and plate are clipped to the animal sheet's own opaque, non-outline
pixels, so they follow each frame's body and keep its inner lines. Eyes are never covered."""
import os, json
from PIL import Image, ImageDraw
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SPR = os.path.join(ROOT, "assets", "sprites")
OUT = (42, 26, 16)
COAT = {"hi": (198, 92, 58), "mid": (164, 64, 44), "lo": (122, 44, 34), "st": (108, 40, 30), "gold": (226, 160, 86)}
FUR = [(242, 228, 196), (190, 158, 116)]
STEEL = {"hi": (208, 216, 226), "mid": (146, 156, 172), "lo": (98, 106, 124), "seam": (62, 66, 82), "rivet": (244, 246, 250)}
LEATHER = {"hi": (184, 118, 62), "mid": (140, 84, 44), "lo": (96, 56, 30)}
BLANKET = [(62, 112, 150), (42, 78, 112), (232, 190, 84)]


class Frame:
    """One animal frame plus the overlay being painted on it."""
    def __init__(self, base, eyes):
        self.base = base
        self.w, self.h = base.size
        self.eyes = set(eyes)
        self.im = Image.new("RGBA", base.size, (0, 0, 0, 0))

    def solid(self, x, y):
        return 0 <= x < self.w and 0 <= y < self.h and self.base.getpixel((x, y))[3] > 0

    def body(self, x, y):
        return self.solid(x, y) and self.base.getpixel((x, y))[:3] != OUT

    def put(self, x, y, c):
        if 0 <= x < self.w and 0 <= y < self.h and (x, y) not in self.eyes:
            self.im.putpixel((x, y), tuple(c) + (255,))

    def clip(self, pts):
        return {p for p in pts if self.body(*p) and p not in self.eyes}

    def free(self, pts, outline=True):
        """A raised piece that may stick out past the animal; pts = {(x, y): colour}."""
        if outline:
            for (x, y) in pts:
                for q in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                    if q not in pts:
                        self.put(q[0], q[1], OUT)
        for (x, y), c in pts.items():
            self.put(x, y, c)


def rows(spec):
    """{y: (x0, x1)} -> pixel set."""
    return {(x, y) for y, (a, b) in spec.items() for x in range(a, b + 1)}


def coat(f, region, collar_x):
    m = f.clip(rows(region))
    top = {}
    bot = {}
    for x, y in m:
        top[x] = min(y, top.get(x, 99))
        bot[x] = max(y, bot.get(x, -1))
    for x, y in m:
        c = COAT["mid"]
        if y <= top[x] + 1:
            c = COAT["hi"]
        if y >= bot[x] - 2:
            c = COAT["lo"]
        if (x + y) % 6 == 0 or (x - y) % 6 == 0:      # quilted diamonds
            c = COAT["st"]
        if (x + y) % 6 == 0 and (x - y) % 6 == 0 and top[x] + 1 < y < bot[x] - 1:   # brass tacks where stitches cross
            c = COAT["gold"]
        if y == bot[x]:                                # fur hem
            c = FUR[(x % 3) == 0]
        elif x >= collar_x:                            # fur collar
            c = FUR[(y % 3) == 0]
        f.put(x, y, c)
    for x, y in m:                                     # shadow line under the hem
        if y == bot[x] and f.body(x, y + 1):
            f.put(x, y + 1, OUT)


def plate(f, spec, rivets=(), seams=()):
    m = f.clip(rows(spec))
    for x, y in m:
        c = STEEL["mid"]
        if (x, y - 1) not in m or (x - 1, y) not in m:
            c = STEEL["hi"]
        if (x, y + 1) not in m or (x + 1, y) not in m:
            c = STEEL["lo"]
        if (x, y) in seams:
            c = STEEL["seam"]
        f.put(x, y, c)
    for x, y in m:                                     # dark edge where plate meets hide or cloth
        for q in ((x + 1, y), (x - 1, y), (x, y + 1)):
            if q not in m and f.body(*q):
                f.put(q[0], q[1], OUT)
    for p in rivets:
        if p in m:
            f.put(p[0], p[1], STEEL["rivet"])
            if (p[0], p[1] + 1) in m:
                f.put(p[0], p[1] + 1, STEEL["seam"])


def saddle(f, x0, x1, back, drop, girth_to):
    """x0..x1 blanket span, back = y of the back's outline, drop = blanket depth."""
    bl = {}
    for x in range(x0, x1 + 1):
        for y in range(back + 1, back + drop + 1):
            c = BLANKET[0] if x < x1 - 1 else BLANKET[1]
            if y == back + drop:
                c = BLANKET[2]
            bl[(x, y)] = c
    gx = (x0 + x1) // 2
    for y in range(back + drop + 1, girth_to + 1):      # girth strap under the belly
        if f.solid(gx - 2, y):
            f.put(gx - 2, y, LEATHER["lo"])
    f.free(bl)
    s = {}
    for x in range(x0 + 1, x1):                         # seat
        s[(x, back)] = LEATHER["hi"]
        s[(x, back + 1)] = LEATHER["mid"]
    for x in range(x0 + 2, x1 - 1):
        s[(x, back + 2)] = LEATHER["lo"]
    s[(x0 + 1, back - 1)] = LEATHER["hi"]               # cantle
    s[(x0 + 2, back - 1)] = LEATHER["mid"]
    s[(x1 - 1, back - 1)] = LEATHER["hi"]               # pommel and horn
    s[(x1 - 1, back - 2)] = LEATHER["mid"]
    f.free(s)
    sy = back + drop + 2                                # stirrup: a leather, then an open iron loop
    for y in range(back + 3, sy):
        f.put(gx + 1, y, LEATHER["hi"])
    loop = {(gx + 1, sy): STEEL["hi"], (gx, sy + 1): STEEL["hi"], (gx + 2, sy + 1): STEEL["mid"],
            (gx, sy + 2): STEEL["mid"], (gx + 1, sy + 2): STEEL["mid"], (gx + 2, sy + 2): STEEL["lo"]}
    for (x, y) in loop:
        for q in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if q not in loop and q != (gx + 1, sy + 1) and q[1] >= sy and not (q == (gx + 1, sy - 1)):
                f.put(q[0], q[1], OUT)
    for (x, y), c in loop.items():
        f.put(x, y, c)


def cow(f, slot, i):
    if slot == "coat":
        coat(f, {y: (4, 18) for y in range(6, 14)} | {y: (4, 21) for y in range(11, 14)}, 18)
    elif slot == "armour":
        plate(f, {y: (3, 5) for y in range(6, 14)}, rivets=[(4, 8), (4, 12)], seams={(x, 10) for x in range(3, 6)})
        plate(f, {y: (18, 18) for y in range(6, 11)} | {y: (18, 21) for y in range(11, 15)},
              rivets=[(19, 12)])
        plate(f, {3: (20, 24), 4: (20, 24)}, rivets=[(21, 3), (23, 3)])
        f.put(24, 5, STEEL["mid"]); f.put(24, 6, STEEL["lo"])
        f.free({(22, 2): STEEL["hi"], (22, 1): (196, 62, 50), (21, 1): (196, 62, 50)})
    else:
        saddle(f, 8, 15, 5, 4, 16)


def horse(f, slot, i):
    if slot == "coat":
        coat(f, {y: (5, 23) for y in range(9, 17)}, 21)
    elif slot == "armour":
        plate(f, {y: (4, 7) for y in range(9, 17)}, rivets=[(5, 11), (5, 14)], seams={(x, 13) for x in range(4, 8)})
        # chest plate and segmented neck guard
        plate(f, {y: (20, 29) for y in range(8, 18)} | {y: (23, 28) for y in range(5, 8)},
              rivets=[(21, 15), (25, 9), (27, 6), (21, 11)],
              seams={(x, y) for x in range(19, 30) for y in (7, 10, 13)})
        plate(f, {y: (23, 28) for y in range(2, 4)} | {4: (23, 26)}, rivets=[(26, 3)])
        for y in (4, 5, 6):                             # face strip in front of the eye
            f.put(29, y, STEEL["hi"] if y < 6 else STEEL["lo"])
        f.free({(26, 1): (196, 62, 50), (25, 0): (196, 62, 50), (26, 0): (232, 104, 72)})
    else:
        saddle(f, 10, 17, 8, 5, 19)


def sheep(f, slot, i):
    if slot == "coat":
        coat(f, {y: (3, 15) for y in range(7, 14)}, 14)
    else:
        plate(f, {y: (3, 6) for y in range(7, 13)}, rivets=[(5, 8), (5, 11)])
        plate(f, {y: (12, 15) for y in range(10, 15)}, rivets=[(13, 11)])
        plate(f, {5: (15, 20), 6: (15, 20)}, rivets=[(17, 5)])
        plate(f, {y: (15, 16) for y in range(7, 10)})   # cheek guard behind the eye
        f.free({(17, 4): STEEL["hi"], (18, 4): STEEL["mid"], (17, 3): (196, 62, 50)})


def goat(f, slot, i):
    if slot == "coat":
        coat(f, {y: (3, 14) for y in range(8, 13)}, 13)
    else:
        plate(f, {y: (3, 7) for y in range(8, 13)}, rivets=[(5, 9)])
        plate(f, {y: (13, 18) for y in range(9, 13)}, rivets=[(15, 10)])
        plate(f, {y: (14, 18) for y in range(7, 9)})    # neck guard
        plate(f, {4: (17, 20), 5: (17, 20)}, rivets=[(18, 5)])
        f.free({(17, 4): STEEL["hi"], (18, 4): STEEL["mid"]})


def chicken(f, slot, i):
    # the head drops when pecking: find it from the red comb
    comb = [y for y in range(f.h) for x in range(f.w) if f.base.getpixel((x, y))[:3] == (210, 50, 50)]
    hy = min(comb) - 1
    # breast and back plate, clipped clear of the head
    spec = {y: (4, 11) for y in range(9, 13)}
    if hy:
        spec = {y: (4, 8) for y in range(8, 10)} | {y: (4, 11) for y in range(10, 13)}
    plate(f, spec, rivets=[(5, 10), (9, 11)], seams={(7, y) for y in range(8, 13)})
    f.free({(10, 1 + hy): STEEL["hi"], (11, 1 + hy): STEEL["hi"], (12, 1 + hy): STEEL["mid"],
            (9, 2 + hy): STEEL["mid"], (10, 2 + hy): STEEL["mid"], (11, 2 + hy): STEEL["rivet"],
            (12, 2 + hy): STEEL["lo"], (10, hy): (210, 50, 50), (9, hy): (210, 50, 50)}, outline=False)
    for p in ((8, 2 + hy), (13, 2 + hy), (9, 1 + hy), (13, 1 + hy), (11, hy), (8, hy)):
        f.put(p[0], p[1], OUT)


PAINT = {"cow": cow, "horse": horse, "sheep": sheep, "goat": goat, "chicken": chicken}


def eyes_of(animal, frame):
    if animal == "chicken":
        comb = [y for y in range(frame.height) for x in range(frame.width) if frame.getpixel((x, y))[:3] == (210, 50, 50)]
        return [(11, 2 + min(comb))]
    return [{"cow": (22, 5), "horse": (28, 4), "sheep": (18, 7), "goat": (19, 6)}[animal]]


def main():
    animals = json.load(open(os.path.join(ROOT, "data", "animals.json")))["animals"]
    for a, paint in PAINT.items():
        sheet = Image.open(os.path.join(SPR, a + ".png")).convert("RGBA")
        fw = sheet.width // 2
        for slot in animals[a]["gear_slots"]:
            out = Image.new("RGBA", sheet.size, (0, 0, 0, 0))
            for i in range(2):
                base = sheet.crop((i * fw, 0, (i + 1) * fw, sheet.height))
                f = Frame(base, eyes_of(a, base))
                paint(f, slot, i)
                out.paste(f.im, (i * fw, 0))
            name = "gear_%s_%s.png" % (a, slot)
            out.save(os.path.join(SPR, name))
            print("wrote", name, out.size)


if __name__ == "__main__":
    main()
