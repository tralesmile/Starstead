#!/usr/bin/env python3
"""Item icon strip (original, CC0): 16x16 icons in data/items.json key order. Deterministic."""
import os, json
from PIL import Image
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = (42, 26, 16, 255)
S = 16

def C(h):
    return tuple(int(h[i:i + 2], 16) for i in (1, 3, 5)) + (255,)

class Ic:
    def __init__(self):
        self.p = {}
    def px(self, x, y, c):
        if 0 <= x < S and 0 <= y < S:
            self.p[(x, y)] = C(c) if isinstance(c, str) else c
    def rect(self, x0, y0, x1, y1, c):
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                self.px(x, y, c)
    def ell(self, cx, cy, rx, ry, c):
        for y in range(S):
            for x in range(S):
                if ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 <= 1:
                    self.px(x, y, c)
    def line(self, x0, y0, x1, y1, c):
        n = max(abs(x1 - x0), abs(y1 - y0), 1)
        for i in range(n + 1):
            self.px(round(x0 + (x1 - x0) * i / n), round(y0 + (y1 - y0) * i / n), c)
    def image(self, glow=None):
        im = Image.new("RGBA", (S, S), (0, 0, 0, 0))
        out = set()
        for (x, y) in self.p:
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                q = (x + dx, y + dy)
                if q not in self.p and 0 <= q[0] < S and 0 <= q[1] < S:
                    out.add(q)
        if glow:
            for (x, y) in list(out):
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    q = (x + dx, y + dy)
                    if q not in self.p and q not in out and 0 <= q[0] < S and 0 <= q[1] < S:
                        im.putpixel(q, glow)
        for q in out:
            im.putpixel(q, OUT)
        for q, c in self.p.items():
            im.putpixel(q, c)
        return im

def fish(body, belly, fin, stripe=None, spot=None, big=False):
    i = Ic()
    h = 4 if big else 3
    i.ell(7, 8, 6, h, body)
    i.ell(7, 9, 5, h - 1, belly) if False else None
    for x in range(3, 11):
        i.px(x, 8 + h - 1, belly)
        i.px(x, 8 + h - 2, belly)
    # tail
    i.px(12, 8, fin); i.px(13, 6, fin); i.px(13, 7, fin); i.px(13, 8, fin); i.px(13, 9, fin); i.px(13, 10, fin); i.px(14, 5, fin); i.px(14, 11, fin)
    i.px(12, 7, body); i.px(12, 9, body)
    # dorsal fin
    i.px(6, 8 - h - 1, fin); i.px(7, 8 - h - 1, fin); i.px(8, 8 - h - 1, fin)
    # eye
    i.px(3, 7, "#ffffff"); i.px(3, 7 if False else 7, "#ffffff"); i.px(2, 7, body)
    i.px(3, 7, "#fff8e8"); i.px(3, 8, "#2a1a10")
    if stripe:
        for x in (6, 8, 10):
            for y in range(8 - h + 1, 8 + 1):
                i.px(x, y, stripe)
    if spot:
        for (x, y) in spot:
            i.px(x, y, spot[(x, y)] if isinstance(spot, dict) else "#ffffff")
    # highlight
    i.px(5, 8 - h + 1, "#ffffff")
    i.px(4, 8 - h + 2, body if False else "#ffffff")
    return i

icons = {}

def wood():
    i = Ic()
    i.rect(2, 5, 13, 11, "#8a5a34")
    i.rect(2, 5, 13, 6, "#a8743f")
    i.rect(2, 10, 13, 11, "#6a4026")
    for x in (5, 8, 11):
        i.px(x, 8, "#6a4026")
    i.rect(1, 6, 3, 10, "#d8a868")  # cut end
    i.px(2, 8, "#8a5a34"); i.px(1, 7, "#fff0c0")
    i.px(3, 7, "#8a5a34")
    return i
icons['wood'] = wood

def stone():
    i = Ic()
    i.ell(8, 9, 6, 4.2, "#8c8c94")
    i.rect(4, 11, 12, 12, "#6a6a74")
    i.ell(7, 7, 3.2, 1.8, "#a8a8b2")
    i.px(6, 6, "#f4f4f8"); i.px(7, 6, "#f4f4f8"); i.px(5, 7, "#d8d8e0")
    i.px(11, 9, "#6a6a74"); i.px(10, 10, "#6a6a74")
    return i
icons['stone'] = stone

def turnip_seed():
    i = Ic()
    i.rect(3, 2, 12, 14, "#e8d4a0")
    i.rect(3, 2, 12, 4, "#b8456a")  # top band
    i.rect(3, 13, 12, 14, "#c8b480")
    i.rect(4, 3, 5, 3, "#d86a8a")
    # turnip pic
    i.ell(8, 9, 2.6, 2.4, "#f4f0f4")
    i.rect(6, 10, 10, 10, "#c070b0")
    i.px(8, 6, "#4a9a3a"); i.px(7, 5, "#5ab04a"); i.px(9, 5, "#5ab04a")
    i.px(7, 8, "#ffffff")
    return i
icons['turnip_seed'] = turnip_seed

def turnip():
    i = Ic()
    i.ell(8, 10, 5, 4, "#f2eaf2")
    i.rect(4, 11, 12, 12, "#c070b0")
    i.rect(6, 12, 10, 13, "#a8509a")
    i.rect(5, 9, 11, 10, "#d890c8")
    i.px(8, 14, "#d8c8b0")
    for (x, y) in ((8, 6), (7, 5), (6, 3), (9, 5), (10, 3), (8, 4), (8, 3), (8, 2)):
        i.px(x, y, "#4a9a3a")
    i.px(6, 4, "#5ab04a"); i.px(10, 4, "#5ab04a")
    i.px(5, 8, "#ffffff"); i.px(6, 7, "#ffffff"); i.px(6, 8, "#ffffff")
    return i
icons['turnip'] = turnip

def egg():
    i = Ic()
    i.ell(8, 9, 4, 5, "#f4e4c4")
    i.ell(8, 6, 3, 3, "#f4e4c4")
    i.rect(10, 10, 12, 12, "#d8bf94")
    i.px(9, 13, "#d8bf94"); i.px(8, 13, "#d8bf94")
    i.px(6, 5, "#ffffff"); i.px(6, 6, "#ffffff"); i.px(7, 4, "#ffffff")
    i.px(9, 9, "#d8bf94")
    return i
icons['egg'] = egg

def milk():
    i = Ic()
    i.rect(6, 1, 9, 2, "#c84a4a")  # cap
    i.rect(6, 3, 9, 4, "#e8f0f4")  # neck
    i.rect(4, 5, 11, 14, "#e8f0f4")
    i.rect(4, 8, 11, 12, "#ffffff")
    i.rect(5, 9, 10, 11, "#c84a4a") if False else None
    i.rect(5, 9, 10, 11, "#6aa8d8")  # label
    i.px(7, 10, "#ffffff"); i.px(8, 10, "#ffffff")
    i.rect(10, 5, 11, 14, "#c0d0d8")
    i.px(5, 6, "#ffffff"); i.px(5, 7, "#ffffff")
    i.rect(4, 13, 11, 14, "#c0d0d8")
    return i
icons['milk'] = milk
def goat_milk():
    i = Ic()
    i.rect(6, 1, 9, 2, "#6a8a3a")  # green cap
    i.rect(6, 3, 9, 4, "#f4ecd8")  # neck
    i.rect(4, 5, 11, 14, "#f4ecd8")
    i.rect(4, 8, 11, 12, "#fffaf0")
    i.rect(5, 9, 10, 11, "#b89a5a")  # label
    i.px(7, 10, "#fffaf0"); i.px(8, 10, "#fffaf0")   # a little goat head mark
    i.px(6, 9, "#7a5a2a"); i.px(9, 9, "#7a5a2a")
    i.rect(10, 5, 11, 14, "#d8ccb0")
    i.px(5, 6, "#fffaf0"); i.px(5, 7, "#fffaf0")
    i.rect(4, 13, 11, 14, "#d8ccb0")
    return i
icons['goat_milk'] = goat_milk

def fish_small():
    i = Ic()
    i.ell(7, 8, 4.5, 2.3, "#9ab8c8")
    for x in range(4, 10):
        i.px(x, 9, "#e0eef4")
    i.px(11, 7, "#7a98a8"); i.px(11, 8, "#7a98a8"); i.px(11, 9, "#7a98a8")
    i.px(12, 6, "#7a98a8"); i.px(12, 7, "#7a98a8"); i.px(12, 9, "#7a98a8"); i.px(12, 10, "#7a98a8")
    i.px(4, 7, "#ffffff"); i.px(4, 8, "#2a1a10")
    i.px(6, 7, "#d0e4ee"); i.px(7, 7, "#d0e4ee")
    return i
icons['minnow'] = fish_small

def perch():
    i = fish("#6a9a48", "#e8e090", "#d86a38", stripe="#3a6a2a")
    i.px(7, 4, "#d86a38"); i.px(9, 4, "#d86a38")
    return i
icons['perch'] = perch

def carp():
    i = fish("#c89a48", "#f0d890", "#a8742c", big=True)
    for (x, y) in ((6, 7), (8, 6), (7, 9), (9, 8), (10, 7), (5, 9)):
        i.px(x, y, "#e8c070")
    i.px(1, 9, "#f0d890"); i.px(2, 10, "#a8742c")  # barbel
    return i
icons['carp'] = carp

def pike():
    i = Ic()
    i.ell(7, 8, 6.5, 2.6, "#4a7a58")
    for x in range(2, 12):
        i.px(x, 9, "#d8e0a8")
    i.rect(0, 8, 2, 9, "#4a7a58")  # long snout
    i.px(0, 9, "#d8e0a8")
    for x in (5, 7, 9):
        i.px(x, 7, "#b8d088")
    i.px(10, 5, "#386048"); i.px(11, 5, "#386048"); i.px(11, 6, "#386048")
    i.px(12, 7, "#4a7a58"); i.px(12, 8, "#4a7a58"); i.px(12, 9, "#4a7a58")
    i.px(13, 6, "#386048"); i.px(13, 7, "#386048"); i.px(13, 9, "#386048"); i.px(13, 10, "#386048"); i.px(13, 8, "#386048")
    i.px(3, 7, "#ffe070"); i.px(3, 8, "#2a1a10") if False else None
    i.px(4, 7, "#fff0a0")
    i.px(5, 6, "#a8d0a0")
    i.px(8, 10, "#386048")
    return i
icons['pike'] = pike

def koi():
    i = fish("#f4a028", "#fff4d8", "#ffd860", big=True)
    for (x, y) in ((6, 6), (7, 6), (8, 6), (9, 7), (8, 9)):
        i.px(x, y, "#fff8f0")
    i.px(6, 5, "#e84a28"); i.px(7, 5, "#e84a28")
    i.px(9, 6, "#e84a28")
    # sparkle
    for (x, y) in ((1, 2), (0, 2), (2, 2), (1, 1), (1, 3)):
        i.px(x, y, "#fff4a0")
    i.px(14, 13, "#fff4a0"); i.px(13, 13, "#ffd860"); i.px(15, 13, "#ffd860")
    return i
icons['golden_koi'] = koi

def sardine():
    i = Ic()
    i.ell(7, 8, 5.5, 2.4, "#8aa8c8")
    for x in range(3, 11):
        i.px(x, 9, "#e4eef8")
    for x in range(3, 11):
        i.px(x, 7, "#5a7aa8")  # dark back
    i.px(12, 8, "#6a88b0"); i.px(12, 7, "#6a88b0"); i.px(12, 9, "#6a88b0")
    i.px(13, 6, "#6a88b0"); i.px(13, 7, "#6a88b0"); i.px(13, 9, "#6a88b0"); i.px(13, 10, "#6a88b0")
    i.px(3, 8, "#ffffff"); i.px(3, 7, "#2a1a10")
    i.px(6, 8, "#d8e8f4"); i.px(8, 8, "#d8e8f4")  # scale glints
    i.px(7, 5, "#6a88b0")
    return i
icons['sardine'] = sardine

def mackerel():
    i = fish("#3a9a8a", "#d8ecd8", "#2a6a6a", stripe="#1a4a5a")
    i.px(5, 8 - 3 - 1, "#2a6a6a")  # second dorsal
    for x in (4, 5, 6, 7, 8, 9, 10):
        i.px(x, 6, "#5ac0a8") if x % 2 else None
    return i
icons['mackerel'] = mackerel

def tuna():
    i = fish("#2a3e78", "#e4ecf4", "#1e2c58", big=True)
    for (x, y) in ((8, 12), (9, 12), (10, 12)):
        i.px(x, y, "#f4d83a")  # yellow finlets along belly
    for (x, y) in ((11, 6), (11, 10), (10, 5)):
        i.px(x, y, "#f4d83a")
    i.px(5, 6, "#5a74b8"); i.px(6, 5, "#4a64a8"); i.px(7, 6, "#4a64a8")  # sheen
    i.px(14, 8, "#1e2c58")
    return i
icons['tuna'] = tuna

def swordfish():
    i = Ic()
    i.ell(8, 8, 5.5, 3.4, "#5a7a98")
    for x in range(5, 12):
        i.px(x, 10, "#c8d8e4"); i.px(x, 11, "#c8d8e4") if x < 11 else None
    i.line(0, 7, 4, 8, "#c0ccd8")  # long bill
    i.px(1, 7, "#a0b0c0"); i.px(0, 6, "#c0ccd8")
    i.px(12, 7, "#5a7a98"); i.px(12, 8, "#5a7a98"); i.px(12, 9, "#5a7a98")
    i.px(13, 5, "#3a5870"); i.px(13, 6, "#3a5870"); i.px(13, 7, "#3a5870"); i.px(13, 9, "#3a5870"); i.px(13, 10, "#3a5870"); i.px(13, 11, "#3a5870")
    i.px(14, 4, "#3a5870"); i.px(14, 12, "#3a5870")
    for x in (6, 7, 8, 9):
        i.px(x, 4, "#3a5870")  # tall dorsal
    i.px(7, 3, "#3a5870"); i.px(8, 3, "#3a5870")
    i.px(5, 7, "#ffffff"); i.px(5, 8, "#2a1a10")
    i.px(7, 6, "#8aa8c0"); i.px(8, 6, "#8aa8c0"); i.px(6, 5, "#8aa8c0")
    return i
icons['swordfish'] = swordfish

def smuggle_crate():
    i = Ic()
    i.rect(2, 4, 13, 13, "#8a5a34")
    i.rect(2, 4, 13, 5, "#a8743f")
    i.rect(2, 12, 13, 13, "#6a4026")
    i.rect(2, 8, 13, 8, "#6a4026")  # plank gap
    i.rect(11, 5, 13, 12, "#7a4e2c")
    i.rect(5, 4, 6, 13, "#c43a3a")  # red stripe
    i.px(5, 5, "#e46a5a")
    for (x, y) in ((3, 6), (9, 10), (10, 6)):
        i.rect(x, y, x + 1, y + 1, "#2a1e18")  # tarry seals
    i.px(3, 10, "#2a1e18"); i.px(4, 10, "#2a1e18")
    return i
icons['smuggle_crate'] = smuggle_crate

def worm():
    i = Ic()
    pts = [(3, 11), (4, 10), (5, 10), (6, 11), (7, 12), (8, 11), (9, 10), (10, 9), (11, 8), (12, 9)]
    for k, (x, y) in enumerate(pts):
        i.rect(x, y, x, y + 1, "#d87a8a" if k % 2 == 0 else "#b85a6a")
    for k, (x, y) in enumerate(pts):
        i.px(x, y, "#f0a0aa" if k % 2 == 0 else "#d87a8a")
    i.px(12, 9, "#f0a0aa"); i.px(13, 8, "#f0a0aa") if False else None
    i.px(12, 10, "#b85a6a")
    i.px(11, 9, "#fff0f0") if False else None
    return i
icons['worm_bait'] = worm

def glow():
    i = Ic()
    i.ell(8, 8, 4, 4, "#60f0b0")
    i.ell(8, 8, 2.4, 2.4, "#d8ffe8")
    i.px(8, 8, "#ffffff"); i.px(7, 7, "#ffffff")
    i.px(8, 3, "#a8ffd8"); i.px(8, 13, "#a8ffd8"); i.px(3, 8, "#a8ffd8"); i.px(13, 8, "#a8ffd8")
    return i
icons['glow_bait'] = glow

def rod(c1, c2, tip, reel):
    i = Ic()
    i.line(2, 14, 12, 3, c1)
    i.line(3, 14, 13, 3, c2)
    i.px(12, 3, tip); i.px(13, 2, tip)
    i.rect(3, 11, 4, 12, "#6a4a30")  # grip
    i.px(5, 10, reel); i.px(6, 10, reel); i.px(5, 11, reel); i.px(6, 11, reel)
    i.line(13, 3, 14, 9, "#e8e8e8")  # line
    i.px(14, 10, "#c84a4a"); i.px(14, 11, "#ffffff")
    i.px(3, 12, "#8a6a48")
    return i
icons['rod_bamboo'] = lambda: rod("#c8a850", "#a88838", "#8a6a28", "#8c8c94")
def carbon():
    i = rod("#4a4a58", "#2e2e3a", "#2e2e3a", "#e0b040")
    i.px(8, 8, "#9aa0b8"); i.px(7, 9, "#9aa0b8"); i.px(10, 6, "#9aa0b8")
    return i
icons['rod_carbon'] = carbon

def wool():
    i = Ic()
    for (cx, cy, r) in ((6, 7, 3), (10, 7, 3), (8, 10, 3.4), (8, 6, 2.6)):
        i.ell(cx, cy, r, r, "#f4f0e4")
    for (x, y) in ((5, 11), (10, 12), (11, 10), (7, 12), (4, 9)):
        i.px(x, y, "#d8d0bc")
    i.px(5, 5, "#ffffff"); i.px(6, 5, "#ffffff"); i.px(4, 6, "#ffffff")
    i.px(8, 8, "#d8d0bc"); i.px(9, 9, "#d8d0bc")
    return i
icons['wool'] = wool

def saddle():
    i = Ic()
    i.rect(2, 6, 13, 10, "#a85a30")
    i.rect(2, 4, 5, 8, "#c0703c")  # pommel
    i.rect(11, 4, 13, 8, "#c0703c")  # cantle
    i.rect(5, 10, 10, 12, "#8a4424")
    i.rect(6, 12, 9, 13, "#6a3418") if False else None
    i.rect(3, 8, 12, 9, "#8a4424")
    i.rect(6, 6, 9, 7, "#d08a50")
    i.px(3, 5, "#f0b878"); i.px(4, 5, "#f0b878")
    i.px(7, 14, "#e0c050"); i.px(8, 14, "#e0c050"); i.px(7, 13, "#e0c050"); i.px(8, 13, "#e0c050")
    i.px(7, 12, "#8a4424")
    return i
icons['saddle'] = saddle

def fur():
    i = Ic()
    i.rect(4, 3, 11, 14, "#8a5a3a")
    i.rect(1, 4, 4, 10, "#8a5a3a")   # sleeves
    i.rect(11, 4, 14, 10, "#8a5a3a")
    i.rect(6, 2, 9, 3, "#f0e4cc")    # collar
    i.rect(5, 3, 10, 4, "#f0e4cc")
    i.rect(7, 5, 8, 14, "#6a4228")   # opening
    i.rect(4, 13, 11, 14, "#f0e4cc") # hem
    i.rect(1, 9, 4, 10, "#f0e4cc"); i.rect(11, 9, 14, 10, "#f0e4cc")
    for (x, y) in ((5, 7), (10, 8), (5, 11), (10, 11), (2, 6)):
        i.px(x, y, "#a8744c")
    i.px(6, 2, "#ffffff"); i.px(5, 3, "#ffffff")
    return i
icons['fur_coat'] = fur

def armour():
    i = Ic()
    i.rect(3, 2, 12, 11, "#9aa4b4")
    i.rect(2, 3, 13, 5, "#9aa4b4")
    i.rect(4, 11, 11, 13, "#9aa4b4")
    i.rect(6, 13, 9, 14, "#9aa4b4")
    i.rect(10, 3, 12, 12, "#6e7888")   # shade
    i.rect(7, 4, 8, 11, "#c0c8d4")     # ridge
    i.rect(5, 6, 10, 7, "#c0c8d4")
    i.rect(7, 4, 8, 11, "#d8a838") if False else None
    i.px(7, 6, "#d8a838"); i.px(8, 6, "#d8a838"); i.px(7, 7, "#d8a838"); i.px(8, 7, "#d8a838")
    i.px(4, 3, "#ffffff"); i.px(5, 3, "#ffffff"); i.px(3, 4, "#ffffff")
    i.rect(5, 2, 10, 2, "#6e7888")
    return i
icons['armour'] = armour

def hoe(metal, shade):
    i = Ic()
    i.line(3, 13, 11, 4, "#8a5a2c")      # handle
    i.line(4, 13, 12, 4, "#a87a40")
    i.rect(9, 2, 13, 3, metal)           # blade head
    i.rect(12, 3, 13, 6, metal)
    i.px(13, 6, shade); i.px(12, 6, shade); i.px(9, 3, shade)
    i.px(10, 2, "#ffffff")
    return i
icons['hoe_copper'] = lambda: hoe("#d4814a", "#a85a2a")
icons['hoe_iron'] = lambda: hoe("#b8c0cc", "#7a8494")

def can(body, shade):
    i = Ic()
    i.rect(3, 6, 10, 12, body)           # tank
    i.rect(3, 6, 4, 12, shade)
    i.rect(4, 5, 9, 5, shade)            # rim
    i.line(10, 8, 14, 5, body)           # spout
    i.line(10, 9, 14, 6, body)
    i.rect(14, 3, 14, 6, shade)          # rose
    i.line(4, 4, 9, 4, shade)            # handle arc
    i.px(4, 5, shade); i.px(9, 5, shade)
    i.px(5, 8, "#ffffff"); i.px(5, 9, "#ffffff")
    return i
icons['watering_can_copper'] = lambda: can("#d4814a", "#a85a2a")
icons['watering_can_iron'] = lambda: can("#b8c0cc", "#7a8494")

def fibre():
    i = Ic()
    for k, (x0, y0, x1, y1) in enumerate([(3, 13, 6, 3), (6, 14, 8, 2), (9, 13, 10, 4), (11, 13, 13, 6)]):
        i.line(x0, y0, x1, y1, "#6aa238" if k % 2 == 0 else "#8cc050")
    i.rect(4, 11, 11, 12, "#c8a050")   # twine
    i.px(5, 11, "#e8c878")
    return i
icons['fibre'] = fibre

def hay():
    i = Ic()
    i.ell(8, 10, 6, 4, "#c8a040")                 # bundle
    for x in range(3, 14, 2):                     # straws, lit on the left
        i.line(x, 6 + (x % 3), x + 1, 13, "#e8c860" if x < 8 else "#b08a30")
    i.rect(3, 9, 13, 10, "#8a6020")               # twine band
    i.px(4, 9, "#c08840")
    i.px(5, 6, "#fff0a0"); i.px(7, 5, "#fff0a0")
    return i
icons['hay'] = hay

def fertiliser():
    i = Ic()
    i.rect(4, 4, 11, 14, "#8a6a3a")              # sack
    i.rect(5, 5, 10, 13, "#b08850")
    i.rect(5, 5, 6, 13, "#c8a066")               # lit side
    i.rect(4, 3, 11, 4, "#6a4e28")               # tied top
    i.px(7, 2, "#6a4e28"); i.px(8, 2, "#6a4e28")
    i.ell(8, 10, 2, 2, "#5a9a30")                # green sprout mark
    i.px(8, 7, "#5a9a30"); i.px(9, 7, "#7ac040")
    return i
icons['fertiliser'] = fertiliser

def sprinkler():
    i = Ic()
    i.rect(7, 8, 8, 13, "#b8c0cc")      # pipe
    i.rect(6, 12, 9, 14, "#787c82")     # base
    i.rect(4, 5, 11, 7, "#d4814a")      # head
    i.rect(5, 4, 10, 4, "#eeaa6e")
    i.px(2, 4, "#96d2ff"); i.px(13, 4, "#96d2ff"); i.px(7, 1, "#96d2ff"); i.px(1, 6, "#96d2ff"); i.px(14, 6, "#96d2ff")
    return i
icons['sprinkler'] = sprinkler

def packet(band, band_l, pic):
    def f():
        i = Ic()
        i.rect(3, 2, 12, 14, "#e8d4a0")
        i.rect(3, 2, 12, 4, band)
        i.rect(3, 13, 12, 14, "#c8b480")
        i.rect(4, 3, 5, 3, band_l)
        pic(i)
        return i
    return f

def pic_potato(i):
    i.ell(8, 9, 3, 2.2, "#c89a58"); i.px(7, 8, "#e8c888"); i.px(9, 10, "#8a5a2c")
def pic_tomato(i):
    i.ell(8, 9, 2.8, 2.6, "#e04a3a"); i.px(7, 8, "#ff9a8a"); i.px(8, 6, "#4a9a3a"); i.px(7, 6, "#4a9a3a"); i.px(9, 6, "#4a9a3a")
def pic_pumpkin(i):
    i.ell(8, 9, 3.2, 2.6, "#f08a20"); i.px(8, 7, "#a85a10"); i.px(8, 6, "#4a9a3a"); i.px(6, 9, "#c86a10"); i.px(10, 9, "#c86a10")
def pic_strawberry(i):
    i.ell(8, 9, 2.6, 2.8, "#e0345a"); i.px(7, 8, "#ff8aa0"); i.px(8, 6, "#4a9a3a"); i.px(7, 6, "#4a9a3a"); i.px(9, 6, "#4a9a3a"); i.px(7, 10, "#ffe08a"); i.px(9, 9, "#ffe08a")
def pic_kale(i):
    i.ell(8, 9, 3.2, 2.8, "#3f9a52"); i.px(8, 7, "#7ad08a"); i.px(7, 9, "#2a7a3c"); i.px(9, 10, "#2a7a3c"); i.px(6, 8, "#7ad08a")
icons['strawberry_seed'] = packet("#b8244a", "#e0546e", pic_strawberry)
icons['kale_seed'] = packet("#2f7a42", "#5ab06a", pic_kale)
def pic_radish(i):
    i.ell(8, 9, 2.4, 2.8, "#d8406a"); i.px(8, 12, "#f4e8e8"); i.px(8, 6, "#4a9a3a"); i.px(7, 6, "#4a9a3a")
def pic_corn(i):
    i.rect(7, 6, 9, 12, "#e8c840"); i.px(6, 8, "#5ab04a"); i.px(10, 8, "#5ab04a"); i.px(8, 7, "#fff0a0")
icons['radish_seed'] = packet("#a82a50", "#d8546e", pic_radish)
icons['corn_seed'] = packet("#b8982a", "#e8c860", pic_corn)
icons['potato_seed'] = packet("#8a6a3a", "#b08a54", pic_potato)
icons['tomato_seed'] = packet("#b8342a", "#e05a4a", pic_tomato)
icons['pumpkin_seed'] = packet("#c86a10", "#f0922a", pic_pumpkin)

def potato():
    i = Ic()
    i.ell(8, 9, 5.5, 4, "#c89a58"); i.rect(4, 11, 12, 12, "#a87a40")
    i.px(6, 7, "#e8c888"); i.px(7, 7, "#e8c888"); i.px(10, 10, "#7a5028"); i.px(5, 10, "#7a5028"); i.px(9, 6, "#7a5028")
    return i
def tomato():
    i = Ic()
    i.ell(8, 9, 5, 4.5, "#e04a3a"); i.rect(4, 11, 12, 12, "#b8342a")
    i.px(6, 6, "#ffb0a0"); i.px(7, 6, "#ffb0a0"); i.px(6, 7, "#ffb0a0")
    for x, y in [(8, 4), (7, 4), (9, 4), (8, 3), (6, 5), (10, 5)]:
        i.px(x, y, "#4a9a3a")
    return i
def pumpkin():
    i = Ic()
    i.ell(8, 10, 6, 4.5, "#f08a20"); i.ell(5.5, 10, 2, 4.2, "#d66a12"); i.ell(10.5, 10, 2, 4.2, "#d66a12")
    i.rect(7, 5, 9, 6, "#5a8a2a"); i.px(9, 4, "#5a8a2a"); i.px(6, 8, "#ffc060"); i.px(7, 8, "#ffc060")
    return i
def strawberry():
    i = Ic()
    i.ell(8, 9, 4.2, 4.4, "#e0345a"); i.rect(5, 12, 11, 13, "#b8244a")
    i.px(6, 7, "#ff9ab0"); i.px(7, 7, "#ff9ab0")
    for x, y in [(6, 10), (9, 9), (8, 12), (10, 11), (7, 11)]:
        i.px(x, y, "#ffe08a")
    for x, y in [(8, 4), (7, 4), (9, 4), (6, 5), (10, 5), (8, 3)]:
        i.px(x, y, "#4a9a3a")
    return i
def kale():
    i = Ic()
    i.ell(8, 9, 5.5, 4.2, "#3f9a52"); i.ell(5.5, 9, 2, 3.6, "#2f7a42"); i.ell(10.5, 9, 2, 3.6, "#2f7a42")
    i.line(8, 5, 8, 13, "#a8e0b0")
    i.px(6, 7, "#7ad08a"); i.px(10, 7, "#7ad08a"); i.px(6, 10, "#7ad08a"); i.px(10, 10, "#7ad08a")
    return i
icons['strawberry'] = strawberry
icons['kale'] = kale
def radish():
    i = Ic()
    i.ell(8, 9, 3.8, 4.2, "#d8406a"); i.ell(8, 10, 2.4, 2.8, "#e8708a"); i.px(8, 14, "#f4e8e8"); i.px(8, 15, "#f4e8e8")
    for x, y in [(8, 4), (7, 3), (9, 3), (6, 4), (10, 4), (8, 2)]:
        i.px(x, y, "#4a9a3a")
    i.px(6, 8, "#ff9ab0")
    return i
def corn():
    i = Ic()
    i.ell(8, 8, 2.8, 5.6, "#e8c840"); i.ell(8, 8, 1.6, 4.4, "#f8e070")
    for y in (5, 7, 9, 11):
        i.px(7, y, "#c8a028"); i.px(9, y + 1, "#c8a028")
    i.line(3, 14, 7, 6, "#4a9a3a"); i.line(13, 14, 9, 6, "#3a8a2a")
    return i
icons['radish'] = radish
icons['corn'] = corn
icons['potato'] = potato
icons['tomato'] = tomato
icons['pumpkin'] = pumpkin

def dish(food, food_l, extra=None):
    def f():
        i = Ic()
        i.ell(8, 10, 7, 3.5, "#e8e8f0")      # plate
        i.ell(8, 9, 5.5, 2.6, "#c8ccd8")
        i.ell(8, 8, 4.5, 2.6, food)
        i.px(6, 7, food_l); i.px(7, 7, food_l); i.px(9, 8, food_l)
        if extra:
            extra(i)
        return i
    return f
icons['baked_potato'] = dish("#c89a58", "#f0d898", lambda i: (i.px(8, 6, "#fff4a0"), i.px(7, 6, "#fff4a0")))
icons['fried_egg'] = dish("#f6f2e4", "#ffffff", lambda i: (i.ell(8, 8, 1.6, 1.4, "#f8c030"), i.px(7, 7, "#fff0a0")))
icons['grilled_fish'] = dish("#b0a08a", "#e0d0b0", lambda i: (i.px(11, 8, "#8a7a6a"), i.px(5, 8, "#8a7a6a"), i.px(8, 7, "#6a5a4a")))
icons['turnip_stew'] = dish("#b87aa8", "#e8d8e8", lambda i: (i.px(7, 6, "#5ab04a"), i.px(9, 7, "#f4f0f4")))
icons['strawberry_tart'] = dish("#e8c078", "#f8e0a0", lambda i: (i.px(6, 7, "#e0345a"), i.px(8, 6, "#e0345a"), i.px(10, 7, "#e0345a"), i.px(8, 8, "#ff8aa0")))
icons['kale_soup'] = dish("#4a9a52", "#8ad090", lambda i: (i.px(6, 7, "#2a7a3c"), i.px(9, 6, "#2a7a3c"), i.px(8, 8, "#d8f0d0")))
icons['hunters_stew'] = dish("#8a5a34", "#b88a58", lambda i: (i.px(6, 7, "#c85a4a"), i.px(9, 7, "#e8c878"), i.px(8, 6, "#5ab04a")))
icons['tomato_salad'] = dish("#78b848", "#a0d868", lambda i: (i.px(6, 7, "#e04a3a"), i.px(9, 7, "#e04a3a"), i.px(8, 8, "#e04a3a")))
icons['pumpkin_pie'] = dish("#e8902c", "#f8c060", lambda i: (i.px(6, 7, "#c86a10"), i.px(10, 8, "#c86a10"), i.px(8, 6, "#fff0c8")))

def river_king():
    i = Ic()
    i.ell(8, 8, 7, 3.6, "#2a5a6a"); i.ell(8, 8, 6, 2.6, "#3f8a9a")
    i.rect(3, 9, 12, 10, "#c8e0c0")        # belly
    i.rect(13, 6, 15, 10, "#e8a838")       # tail
    i.rect(1, 6, 2, 9, "#e8a838")
    i.px(3, 7, "#ffffff"); i.px(3, 7, "#101820")   # eye
    for x in (6, 8, 10):
        i.px(x, 5, "#e8c850")              # crest
    i.rect(5, 6, 11, 6, "#8ad0b8")
    return i
icons['river_king'] = river_king

def lantern_eel():
    i = Ic()
    pts = [(2, 6), (3, 5), (4, 5), (5, 6), (6, 8), (7, 9), (8, 10), (9, 10), (10, 9), (11, 8), (12, 7), (13, 7), (14, 8)]
    for k, (x, y) in enumerate(pts):
        r = 2 if k < 9 else 1
        for dy in range(r + 1):
            i.px(x, y + dy, "#2a4a3a" if dy == 0 else "#3e6e4e")
    for (x, y) in ((4, 7), (7, 11), (10, 10), (12, 8)):
        i.px(x, y, "#c8ff7a")
    i.px(2, 6, "#fff8a0"); i.px(1, 7, "#3e6e4e"); i.px(2, 8, "#3e6e4e")
    i.px(1, 3, "#c8ff7a"); i.px(2, 4, "#2a4a3a")
    return i
icons['lantern_eel'] = lantern_eel

def anvil_sturgeon():
    i = fish("#5a626e", "#c8ccd2", "#3a404a", big=True)
    for x in (5, 7, 9):
        i.px(x, 3, "#2a2e36"); i.px(x, 4, "#8a929e")
    i.px(0, 8, "#5a626e"); i.px(0, 9, "#3a404a"); i.px(1, 11, "#3a404a"); i.px(2, 11, "#3a404a")
    return i
icons['anvil_sturgeon'] = anvil_sturgeon

def glass_marlin():
    i = fish("#7ac8e8", "#f0fcff", "#3a7ab8", big=True)
    i.line(0, 6, 3, 8, "#d8f4ff")
    for x in range(5, 11):
        i.px(x, 2 + abs(x - 7) // 2, "#3a7ab8"); i.px(x, 3 + abs(x - 7) // 2, "#a8e0f8")
    i.px(8, 7, "#ffffff"); i.px(9, 8, "#ffffff")
    return i
icons['glass_marlin'] = glass_marlin

def crab_pot():
    i = Ic()
    i.ell(8, 9, 6, 5, "#a8885a")
    for x in (4, 6, 8, 10, 12):
        i.line(x, 5, x, 13, "#6a4e2a")
    i.line(3, 8, 13, 8, "#6a4e2a"); i.line(3, 11, 13, 11, "#6a4e2a")
    i.rect(6, 2, 9, 4, "#d8503a")      # float
    i.px(7, 2, "#ff9a80")
    return i
icons['crab_pot'] = crab_pot

def snare():
    i = Ic()
    i.line(2, 13, 14, 13, "#4c7a34")                 # grass strip
    i.rect(3, 6, 4, 12, "#8a5a32"); i.px(3, 6, "#c08a54")     # left stake
    i.rect(11, 6, 12, 12, "#6e4626"); i.px(11, 6, "#a8743e")  # right stake
    i.line(4, 6, 11, 6, "#d8c8a0")                  # cord between stakes
    i.px(7, 5, "#f0e4c4"); i.px(8, 5, "#f0e4c4")
    for (x, y) in ((6, 7), (5, 8), (5, 9), (6, 10), (7, 11), (8, 11), (9, 10), (10, 9), (10, 8), (9, 7)):
        i.px(x, y, "#c4ccd8")                         # wire noose loop
    i.px(6, 7, "#e8eef6"); i.px(5, 8, "#e8eef6")
    return i
icons['snare'] = snare

def crab():
    i = Ic()
    i.ell(8, 9, 5.5, 3.6, "#d8583a"); i.ell(8, 8, 4, 2.4, "#ee7a58")
    i.rect(2, 5, 4, 7, "#d8583a"); i.rect(12, 5, 14, 7, "#d8583a")    # claws
    i.px(3, 4, "#ee7a58"); i.px(13, 4, "#ee7a58")
    for x in (4, 6, 10, 12):
        i.px(x, 13, "#a8402a")
    i.px(6, 7, "#ffffff"); i.px(10, 7, "#ffffff")
    return i
icons['crab'] = crab

# ---- cave / smelting items
def ore(rock, a, b, spots):
    i = Ic()
    i.ell(8, 9, 6, 4.5, rock)
    i.rect(4, 12, 12, 12, shade_hex(rock, 0.75))
    i.ell(7, 7, 3.4, 1.8, shade_hex(rock, 1.2))
    for (x, y) in spots:
        i.px(x, y, a); i.px(x + 1, y, b); i.px(x, y + 1, b)
    return i

def shade_hex(h, k):
    c = C(h)
    return tuple(max(0, min(255, int(v * k))) for v in c[:3]) + (255,)

icons['copper_ore'] = lambda: ore("#8a7a6c", "#e87a38", "#7ac098", [(5, 8), (9, 10), (10, 7)])
icons['iron_ore'] = lambda: ore("#868082", "#e0b898", "#a87c60", [(5, 9), (9, 7), (10, 10)])
def coal():
    i = ore("#5a5660", "#26242c", "#14121a", [(5, 8), (9, 10), (10, 7), (7, 11)])
    i.px(6, 6, "#8a90b0"); i.px(10, 8, "#8a90b0")
    return i
icons['coal'] = coal

def bar(top, mid, low, hi):
    i = Ic()
    i.rect(3, 6, 12, 11, mid)
    i.rect(5, 4, 13, 7, top)       # top face
    i.rect(3, 8, 12, 11, mid)
    i.rect(3, 10, 12, 11, low)
    i.rect(12, 6, 13, 10, low)
    i.px(5, 4, hi); i.px(6, 4, hi); i.px(4, 8, hi); i.px(5, 8, hi)
    return i
icons['copper_bar'] = lambda: bar("#f0a068", "#d4814a", "#a85a2a", "#ffe0b8")
icons['iron_bar'] = lambda: bar("#d8e0ea", "#b8c0cc", "#7a8494", "#ffffff")

# ---- deep mine items
icons['silver_ore'] = lambda: ore("#686c80", "#eef8ff", "#8cb0e4", [(5, 8), (9, 10), (10, 7), (7, 11)])
icons['gold_ore'] = lambda: ore("#7a6252", "#ffe060", "#d89420", [(5, 8), (9, 10), (10, 7), (7, 11), (6, 6)])
icons['silver_bar'] = lambda: bar("#f4fbff", "#c4dcf4", "#7e9cca", "#ffffff")
icons['gold_bar'] = lambda: bar("#ffe468", "#f2bc2c", "#bc7c14", "#fffbd0")

def warden_core():
    i = Ic()                                          # glowing amber heart held in stone claws
    for y, w in ((2, 0), (3, 1), (4, 2), (5, 3), (6, 4), (7, 5), (8, 5), (9, 4), (10, 3), (11, 2), (12, 1), (13, 0)):
        i.rect(8 - w, y, 8 + w, y, "#e87018")
    for y, w in ((4, 0), (5, 1), (6, 2), (7, 3), (8, 3), (9, 2), (10, 1)):
        i.rect(8 - w, y, 8 + w, y, "#ffb02c")
    i.ell(7.5, 7, 1.8, 2, "#ffe26e")
    i.px(7, 6, "#fffbe0"); i.px(7, 5, "#fffbe0"); i.px(6, 6, "#fffbe0")
    for x, y in ((11, 9), (10, 10), (9, 11), (12, 8), (8, 12)):
        i.px(x, y, "#963e12")
    i.rect(2, 10, 4, 12, "#706664"); i.rect(3, 13, 6, 14, "#706664"); i.px(2, 10, "#a89a8a"); i.px(3, 10, "#a89a8a")
    i.rect(12, 10, 14, 12, "#564c50"); i.rect(10, 13, 13, 14, "#564c50"); i.px(12, 10, "#8c8078")
    i.px(2, 9, "#729632"); i.px(3, 9, "#4e7430")        # a bit of moss
    return i
icons['warden_core'] = warden_core

def pickaxe_gold():
    i = Ic()                                          # same silhouette as the copper / iron pickaxes
    for y, xs in ((2, (7, 8, 9)), (3, (5, 6, 10, 11)), (4, (4, 5, 6, 7, 8, 9, 10)), (5, (3, 4, 5, 9, 10, 11)),
                  (6, (3, 4, 12)), (7, (4,))):
        for x in xs:
            i.px(x, y, "#f2bc2c")
    for x, y in ((7, 2), (8, 2), (9, 2), (5, 3), (6, 3)):
        i.px(x, y, "#fff0a0")
    for x, y in ((11, 5), (12, 6)):
        i.px(x, y, "#bc7c14")
    i.px(11, 6, "#825832")
    for x, y in ((9, 7), (10, 6), (8, 8), (7, 9), (6, 10), (5, 11), (4, 12), (3, 13)):
        i.px(x, y, "#825832")
    i.px(8, 2, "#fffbe0")
    return i
icons['pickaxe_gold'] = pickaxe_gold

def deep_lamp():
    i = Ic()                                          # brass miner's lantern with a teal-white flame
    i.rect(6, 1, 9, 1, "#d8a838"); i.px(5, 2, "#d8a838"); i.px(10, 2, "#a87820")   # carry loop
    i.rect(5, 3, 10, 3, "#f0c850"); i.rect(4, 4, 11, 4, "#d8a838")                 # cap
    i.rect(4, 5, 11, 11, "#58d8c8")                                                # glass
    i.ell(7.5, 8.5, 2.4, 2.8, "#a8fff0")
    i.rect(7, 7, 8, 10, "#f0fffc"); i.px(7, 6, "#f0fffc")
    i.rect(4, 5, 4, 11, "#d8a838"); i.rect(11, 5, 11, 11, "#a87820")               # cage bars
    i.px(5, 5, "#ffffff"); i.px(5, 6, "#ffffff")
    i.rect(4, 12, 11, 12, "#f0c850"); i.rect(3, 13, 12, 14, "#a87820")             # base
    i.rect(3, 13, 12, 13, "#d8a838")
    return i
icons['deep_lamp'] = deep_lamp

def bat_wing():
    i = Ic()
    # membrane: fan from the wrist (3,4) with a scalloped lower edge
    edge = {3: 12, 4: 12, 5: 10, 6: 12, 7: 12, 8: 10, 9: 12, 10: 12, 11: 10, 12: 11, 13: 8}
    for x, yb in edge.items():
        top = 4 + max(0, (x - 3)) // 3 if x > 6 else 4
        top = 4 if x < 8 else 4 + (x - 7)
        for y in range(top, yb + 1):
            i.px(x, y, "#5a4670" if y < yb else "#3e2e52")
    # finger bones
    i.line(3, 4, 5, 10, "#a890c0"); i.line(3, 4, 8, 10, "#a890c0"); i.line(3, 4, 11, 10, "#a890c0")
    i.line(2, 3, 13, 5, "#c8b0d8")   # leading arm
    i.px(2, 4, "#c8b0d8"); i.px(2, 2, "#e8d8f0")
    i.px(6, 6, "#7a6090"); i.px(9, 6, "#7a6090")
    return i
icons['bat_wing'] = bat_wing

def raw_meat():
    i = Ic()
    i.ell(8, 9, 6, 4.5, "#c8403c")
    i.ell(7, 8, 3.6, 2, "#e0605a")
    i.rect(4, 12, 12, 12, "#9a2c2c")
    i.ell(10, 10, 2.2, 1.6, "#f0d8c8")   # fat marbling
    i.px(10, 10, "#ffffff")
    i.px(6, 7, "#ff9a90"); i.px(5, 8, "#ff9a90")
    i.rect(12, 5, 14, 6, "#f4ecd8"); i.px(14, 4, "#f4ecd8"); i.px(14, 7, "#f4ecd8")  # bone knob
    i.px(11, 7, "#d8c8a8"); i.px(12, 8, "#d8c8a8")
    return i
icons['raw_meat'] = raw_meat

def hide():
    i = Ic()
    i.rect(4, 4, 11, 12, "#a8743f")
    i.rect(2, 5, 4, 7, "#a8743f"); i.rect(11, 5, 13, 7, "#a8743f")      # front legs
    i.rect(3, 11, 5, 14, "#a8743f"); i.rect(10, 11, 12, 14, "#a8743f")  # hind legs
    i.rect(6, 3, 9, 3, "#a8743f")                                       # neck
    i.rect(9, 5, 11, 12, "#8a5a34"); i.rect(4, 12, 11, 12, "#8a5a34")   # shade
    for (x, y) in ((6, 6), (7, 9), (5, 10), (8, 7)):
        i.px(x, y, "#c8944f")                                           # fur flecks
    i.px(5, 5, "#e8b878"); i.px(6, 5, "#e8b878"); i.px(3, 6, "#e8b878")
    i.px(8, 10, "#6a4026"); i.px(7, 11, "#6a4026")
    return i
icons['hide'] = hide

def feather():
    i = Ic()
    # diagonal vane (leaf shape) with a centre quill running bottom-left to top-right
    for k in range(10):
        x, y = 4 + k, 12 - k
        w = 2 if 2 <= k <= 7 else 1
        for t in range(1, w + 1):
            i.px(x - t, y - t + 1, "#f4f0e4" if k % 2 else "#dcd8c8")    # upper-left barbs
            i.px(x + t, y + t - 1, "#e4e0d0" if k % 2 else "#c8c4b4")    # lower-right barbs
    i.line(3, 13, 13, 3, "#a89878")      # quill
    i.px(2, 14, "#8a7a60")
    i.px(8, 6, "#ffffff"); i.px(9, 5, "#ffffff")
    return i
icons['feather'] = feather

def leather_boots():
    i = Ic()
    for (x0, x1) in ((3, 7), (9, 13)):
        i.rect(x0, 3, x1 - 1, 9, "#8a5a34")          # shaft
        i.rect(x0, 9, x1 + 1, 12, "#a8743f")         # foot
        i.rect(x0, 12, x1 + 1, 13, "#4a2c18")        # sole
        i.rect(x0, 3, x1 - 1, 4, "#c8944f")          # cuff
        i.px(x0 + 1, 6, "#c8944f"); i.px(x0 + 1, 7, "#6a4026")   # lace/stitch
        i.px(x1 + 1, 10, "#c8944f")
    return i
icons['leather_boots'] = leather_boots

def club_icon(band, band_l):
    def f():
        i = Ic()
        i.line(3, 13, 11, 5, "#8a5a34"); i.line(4, 13, 12, 5, "#a8743f")     # shaft
        i.ell(11, 5, 3.2, 3.2, "#a8743f"); i.px(10, 4, "#c8944f"); i.px(12, 6, "#6a4026")   # head
        i.line(9, 8, 13, 4, band); i.line(10, 8, 14, 4, band_l)                 # metal band
        i.px(3, 14, "#6a4026"); i.px(2, 14, "#6a4026")
        return i
    return f
icons['club_copper'] = club_icon("#b8602c", "#e0904c")
icons['club_iron'] = club_icon("#7a8494", "#c4ccd8")

# ---- artisan goods ----
def cheese():
    i = Ic()
    # cut wedge: pale top face, yellow cut side with holes, orange rind at the back
    for y, (a, b) in enumerate(((10, 12), (8, 13), (6, 13), (4, 13), (2, 13))):
        i.rect(a, 3 + y, b, 3 + y, "#fbe68a")
    i.rect(2, 8, 13, 12, "#eebc3c")
    i.rect(2, 8, 13, 8, "#fff2b0")
    i.rect(2, 12, 13, 12, "#c8902a")
    i.rect(13, 4, 13, 12, "#d88a28")
    for (x, y) in ((4, 10), (5, 10), (4, 11), (5, 11), (9, 9), (10, 11), (11, 11), (10, 5)):
        i.px(x, y, "#b47c20")
    return i
icons['cheese'] = cheese

def goat_cheese():
    i = Ic()
    # white soft log with a cut round face, herbs, resting on a green leaf
    i.rect(2, 12, 13, 13, "#5c8c3a"); i.px(14, 12, "#5c8c3a"); i.rect(3, 12, 8, 12, "#86b052")
    i.rect(5, 5, 12, 11, "#f4efdc")
    i.ell(12, 8, 2, 3.4, "#e0d8bc")
    i.rect(5, 5, 11, 5, "#ffffff"); i.rect(5, 11, 11, 11, "#cfc6a8")
    i.ell(5, 8, 2.6, 3.4, "#fffdf2")
    i.ell(5, 8, 1.2, 1.8, "#efe8d0")
    for (x, y) in ((8, 6), (10, 7), (9, 9), (7, 10), (12, 7)):
        i.px(x, y, "#5c8c3a")
    return i
icons['goat_cheese'] = goat_cheese

def cloth():
    i = Ic()
    # folded bolt of woven teal cloth with a cream stripe and a loose fringe
    i.rect(3, 3, 13, 6, "#7cc4bc"); i.rect(3, 3, 13, 3, "#b4e4da")
    i.rect(2, 7, 12, 9, "#4e9c98"); i.rect(2, 7, 12, 7, "#8cd0c6")
    i.rect(3, 10, 13, 12, "#3a7e80"); i.rect(3, 10, 13, 10, "#68b0aa")
    for y in range(3, 13):
        i.px(9, y, "#f0e2b8"); i.px(10, y, "#d8c490")
    for (x, y) in ((4, 5), (6, 4), (5, 8), (7, 9), (4, 11), (6, 12), (12, 5), (12, 11)):
        i.px(x, y, "#2e6a6c")
    for x in (3, 5, 7):
        i.px(x, 13, "#8cd0c6")
    return i
icons['cloth'] = cloth

def _jar(i, liquid, light, dark):
    i.rect(5, 4, 10, 4, "#cfe4e4")                       # neck
    i.rect(3, 5, 12, 13, liquid); i.rect(4, 14, 11, 14, dark)
    i.rect(3, 5, 12, 5, "#e4f4f2")                       # glass shoulder
    i.rect(11, 6, 12, 13, dark)
    i.rect(4, 6, 4, 12, light)

def pickles():
    i = Ic()
    _jar(i, "#b8bc58", "#e8ec9c", "#848a34")
    i.rect(4, 1, 11, 3, "#a8a4ac"); i.rect(4, 1, 11, 1, "#d8d4dc"); i.rect(10, 2, 11, 3, "#74707a")
    for x, y0 in ((5, 7), (8, 6)):
        i.rect(x, y0, x + 1, y0 + 6, "#3e6e28")
        i.rect(x, y0, x, y0 + 5, "#6a9c3a")
        i.px(x, y0 + 2, "#a8c860"); i.px(x + 1, y0 + 4, "#a8c860")
    i.px(10, 8, "#d85030"); i.px(10, 12, "#f0e8c0")
    return i
icons['pickles'] = pickles

def jam():
    i = Ic()
    _jar(i, "#b82c44", "#f07880", "#7c1830")
    # checked cloth cover tied with string
    i.rect(5, 1, 10, 1, "#f4ecd8"); i.rect(4, 2, 11, 3, "#f4ecd8"); i.rect(3, 3, 12, 3, "#f4ecd8")
    for (x, y) in ((5, 1), (7, 1), (9, 1), (4, 2), (6, 2), (8, 2), (10, 2), (3, 3), (5, 3), (7, 3), (9, 3), (11, 3)):
        i.px(x, y, "#d84848")
    i.rect(5, 4, 10, 4, "#c8a060")
    i.rect(5, 8, 10, 12, "#f4e8c8")                      # label with a berry
    i.rect(7, 10, 8, 11, "#c82c40"); i.px(7, 9, "#4c8030"); i.px(8, 9, "#4c8030")
    return i
icons['jam'] = jam

def pumpkin_butter():
    i = Ic()
    # squat crock of orange spread with a wooden lid and a pumpkin label
    i.rect(4, 2, 11, 3, "#a6703f"); i.rect(4, 2, 11, 2, "#d09858")
    i.rect(7, 1, 8, 1, "#8a5a34")
    i.rect(3, 4, 12, 5, "#f08c24"); i.rect(3, 4, 12, 4, "#ffb850")
    i.rect(2, 6, 13, 13, "#e0d0ac"); i.rect(3, 14, 12, 14, "#b49c74")
    i.rect(12, 6, 13, 13, "#bca880"); i.rect(3, 6, 3, 12, "#f8eed4")
    i.px(5, 6, "#f08c24"); i.px(5, 7, "#f08c24"); i.px(10, 6, "#f08c24")   # drips
    i.ell(7.5, 10.5, 3.3, 2.4, "#e8741c")
    i.rect(6, 9, 6, 12, "#ffa844"); i.rect(9, 9, 9, 12, "#b45210")
    i.px(7, 7, "#4c7a2c"); i.px(8, 8, "#4c7a2c")
    return i
icons['pumpkin_butter'] = pumpkin_butter

GLOW = {'warden_core': (255, 170, 50, 110), 'deep_lamp': (110, 255, 230, 100), 'lantern_eel': (170, 255, 110, 100), 'anvil_sturgeon': (255, 200, 80, 100), 'glass_marlin': (190, 240, 255, 110), 'glow_bait': (96, 240, 176, 120), 'golden_koi': (255, 224, 96, 90), 'river_king': (255, 200, 80, 110)}

def scarecrow_icon():
    i = Ic()
    i.rect(7, 4, 8, 14, "#8a5a34"); i.px(7, 6, "#a8743f"); i.px(7, 9, "#a8743f")      # post
    i.rect(2, 6, 13, 7, "#a8743f"); i.rect(2, 7, 13, 7, "#8a5a34")                     # crossbar
    i.rect(5, 7, 10, 11, "#c8a45a"); i.rect(5, 7, 6, 11, "#e0c078"); i.rect(10, 8, 10, 11, "#a8843c")  # shirt
    i.px(7, 9, "#8a6a2c"); i.px(8, 10, "#8a6a2c")
    i.px(1, 7, "#f0d060"); i.px(1, 6, "#f0d060"); i.px(14, 7, "#f0d060"); i.px(14, 8, "#d8b040")  # straw hands
    i.rect(6, 3, 9, 5, "#d8bc84"); i.px(6, 3, "#f0dca4")                               # sack head
    i.px(7, 4, "#2a1a10"); i.px(9, 4, "#2a1a10")                                       # eyes
    i.rect(5, 2, 10, 2, "#7a4a24"); i.rect(7, 0, 8, 1, "#8a5a34"); i.px(7, 0, "#a8743f")  # hat
    i.px(4, 2, "#7a4a24"); i.px(11, 2, "#6a3c1c")
    return i
icons['scarecrow'] = scarecrow_icon

def franchise_deed():
    i = Ic()
    i.rect(2, 3, 13, 12, "#f0e0b0"); i.rect(2, 3, 13, 4, "#fff4d0"); i.rect(2, 11, 13, 12, "#d0b87c")
    i.rect(1, 2, 2, 13, "#d8b878"); i.rect(1, 2, 1, 13, "#f0d898")                      # left roll
    i.rect(13, 2, 14, 13, "#c0a060"); i.rect(14, 3, 14, 12, "#a88848")                  # right roll
    for y in (5, 7, 9):
        i.line(4, y, 10, y, "#8a6a3c")                                                  # text lines
    i.ell(9, 10, 2.6, 2.6, "#c8302c"); i.px(8, 9, "#f06858"); i.px(9, 9, "#f06858")     # wax seal
    i.px(10, 11, "#8a1c1c"); i.px(9, 11, "#a02424")
    i.px(8, 13, "#c8302c"); i.px(10, 13, "#a82424")                                     # ribbon tails
    return i
icons['franchise_deed'] = franchise_deed

def slime_gel():
    i = Ic()
    i.ell(8, 10, 6, 4.2, "#4aa84a")
    i.ell(8, 8, 4.6, 3.6, "#6ccc5c")
    i.ell(8, 7, 3, 2.4, "#8ee07a")
    i.rect(3, 12, 13, 13, "#2f7a38")
    i.px(6, 6, "#e8ffe0"); i.px(7, 6, "#e8ffe0"); i.px(5, 7, "#e8ffe0")
    i.px(10, 10, "#3a9040"); i.px(11, 9, "#3a9040")
    i.px(8, 4, "#6ccc5c"); i.px(8, 3, "#8ee07a")   # drip tip
    return i
icons['slime_gel'] = slime_gel

def crab_shell():
    i = Ic()
    i.ell(8, 9, 6.5, 5, "#8a7a6c")
    i.ell(7, 8, 5, 3.6, "#a89886")
    i.rect(3, 12, 13, 13, "#5e5248")
    i.rect(11, 6, 13, 12, "#6e6256")                   # shaded right edge
    i.line(8, 5, 8, 12, "#6e6256")                     # centre ridge
    i.line(4, 8, 7, 9, "#6e6256"); i.line(12, 8, 9, 9, "#6e6256")
    i.px(5, 6, "#d8ccb8"); i.px(6, 6, "#d8ccb8"); i.px(4, 7, "#d8ccb8")
    i.px(6, 11, "#c0b098"); i.px(10, 11, "#7a6c5e")
    return i
icons['crab_shell'] = crab_shell

def vest_icon(base, light, dark, trim):
    def f():
        i = Ic()
        i.rect(3, 3, 12, 13, base)
        i.rect(3, 3, 5, 4, light); i.rect(10, 3, 12, 4, light)               # shoulders
        i.rect(6, 3, 9, 5, (0, 0, 0, 0)) if False else None
        for y in range(3, 6):
            for x in (6, 7, 8, 9):
                i.p.pop((x, y), None)                                        # neck hole
        i.px(6, 6, trim); i.px(9, 6, trim); i.px(7, 5, dark); i.px(8, 5, dark)
        i.line(7, 6, 7, 13, dark); i.line(8, 6, 8, 13, dark)                 # front opening
        i.rect(3, 12, 12, 13, dark)                                          # hem
        i.rect(11, 5, 12, 11, dark)                                          # shaded side
        i.rect(3, 5, 4, 10, light)
        for y in (8, 10):
            i.px(6, y, trim); i.px(9, y, trim)                               # studs
        return i
    return f
icons['copper_vest'] = vest_icon("#b8602c", "#e0904c", "#8a4420", "#f4c070")
icons['iron_vest'] = vest_icon("#7a8494", "#c4ccd8", "#545e6c", "#e8eef6")

def engine_kit():
    i = Ic()
    i.rect(4, 6, 11, 12, "#6a7280"); i.rect(4, 6, 11, 7, "#9aa4b4"); i.rect(4, 12, 11, 12, "#444c58")
    i.rect(10, 7, 11, 11, "#545e6c")
    for x in (5, 7, 9):
        i.rect(x, 3, x + 1, 5, "#8a94a4"); i.px(x, 3, "#c4ccd8")             # cylinder heads
    i.rect(1, 9, 3, 10, "#b8602c"); i.px(1, 9, "#e0904c")                     # side pipe
    i.rect(12, 8, 14, 9, "#b8602c"); i.px(12, 8, "#e0904c")
    i.rect(13, 10, 14, 12, "#b8602c")
    i.px(6, 9, "#d8d0c0"); i.px(7, 9, "#d8d0c0"); i.px(6, 10, "#a89886")      # bolt/plate
    i.px(8, 10, "#f0c040")
    i.rect(5, 13, 10, 13, "#2a2e36")
    return i
icons['engine_kit'] = engine_kit

def grip_tyres():
    i = Ic()
    i.ell(8, 8, 6.5, 6.5, "#2c2c34")
    i.ell(8, 8, 3.6, 3.6, "#9aa4b4")
    i.ell(8, 8, 2.2, 2.2, "#6a7280")
    i.px(8, 8, "#c4ccd8")
    for a in range(12):                                                       # tread blocks
        import math
        x = 8 + 5.6 * math.cos(a * math.pi / 6); y = 8 + 5.6 * math.sin(a * math.pi / 6)
        i.px(round(x), round(y), "#5a5a66")
    i.px(4, 4, "#4a4a56"); i.px(5, 3, "#4a4a56")                              # sidewall highlight
    return i
icons['grip_tyres'] = grip_tyres

def bumper_guard():
    i = Ic()
    i.rect(1, 6, 14, 9, "#9aa4b4"); i.rect(1, 6, 14, 6, "#e8eef6"); i.rect(1, 9, 14, 9, "#545e6c")
    i.rect(1, 7, 14, 8, "#7a8494")
    i.rect(0, 7, 0, 8, "#7a8494"); i.rect(15, 7, 15, 8, "#545e6c")
    i.rect(3, 10, 4, 13, "#6a7280"); i.rect(11, 10, 12, 13, "#6a7280")        # mounts
    i.px(3, 10, "#9aa4b4"); i.px(11, 10, "#9aa4b4")
    i.px(3, 7, "#e8eef6"); i.px(12, 7, "#e8eef6")                             # bolts
    return i
icons['bumper_guard'] = bumper_guard

def lockpick_set():
    i = Ic()
    i.rect(2, 7, 13, 13, "#8a5a32"); i.rect(2, 7, 13, 7, "#b88050"); i.rect(2, 13, 13, 13, "#5e3c20")   # leather roll
    i.rect(2, 7, 2, 13, "#b88050"); i.rect(13, 8, 13, 13, "#5e3c20")
    i.rect(2, 10, 13, 10, "#6e4626")                                          # pocket seam
    i.rect(6, 6, 7, 14, "#d8c8a0"); i.px(6, 6, "#f0e4c4"); i.px(7, 14, "#a89870")   # tie strap
    i.px(7, 10, "#a89870")
    i.line(4, 6, 4, 2, "#c4ccd8"); i.px(3, 2, "#e8eef6"); i.px(4, 1, "#e8eef6")      # pick with hook
    i.line(8, 6, 8, 1, "#9aa4b4"); i.px(9, 1, "#e8eef6"); i.px(8, 0, "#e8eef6")
    i.line(11, 6, 11, 3, "#c4ccd8"); i.px(11, 2, "#e8eef6"); i.px(12, 2, "#e8eef6")
    return i
icons['lockpick_set'] = lockpick_set

def leather():
    i = Ic()
    i.rect(3, 4, 12, 12, "#c8955a")
    i.rect(3, 4, 12, 5, "#e0b077")                    # lit top fold
    i.rect(3, 10, 12, 12, "#a4733f")                  # shaded lower fold
    i.rect(11, 5, 12, 12, "#a4733f")
    i.line(4, 8, 11, 8, "#a4733f")                    # fold crease
    i.line(4, 7, 11, 7, "#dcaa70")
    i.px(2, 6, "#c8955a"); i.px(13, 9, "#a4733f"); i.px(13, 10, "#a4733f")
    for x in (5, 7, 9):
        i.px(x, 11, "#8a5c30")                        # grain flecks
    i.px(4, 4, "#f4d29a"); i.px(5, 4, "#f4d29a")
    return i
icons['leather'] = leather

def jerky():
    i = Ic()
    for (x0, y0, x1, y1, c, h) in ((2, 11, 12, 4, "#7a3a2c", "#a85a44"), (4, 13, 14, 6, "#6a3026", "#965040"), (1, 8, 9, 2, "#85402f", "#b46048")):
        i.line(x0, y0, x1, y1, c); i.line(x0, y0 + 1, x1, y1 + 1, c); i.line(x0 + 1, y0 - 1, x1 + 1, y1 - 1, h)
    for (x, y) in ((6, 8), (9, 7), (8, 11), (11, 9)):
        i.px(x, y, "#4a201a")                         # dark dried streaks
    i.px(4, 10, "#d08a70"); i.px(7, 6, "#d08a70"); i.px(10, 8, "#d08a70")
    return i
icons['jerky'] = jerky

def snare_bait():
    i = Ic()
    i.ell(8, 10, 5.2, 4.2, "#d8c498")                 # pouch
    i.rect(4, 12, 12, 13, "#b09c72")
    i.ell(6.5, 9, 2.6, 2, "#ece0bc")
    i.rect(6, 5, 10, 6, "#d8c498")                    # gathered neck
    i.rect(6, 6, 10, 6, "#b09c72")
    i.rect(6, 7, 10, 7, "#9a4a38")                    # cord tie
    i.px(11, 7, "#9a4a38"); i.px(11, 8, "#9a4a38"); i.px(5, 8, "#9a4a38")
    i.px(10, 4, "#d8c498"); i.px(6, 4, "#d8c498")
    i.line(8, 4, 10, 0, "#f4f0e4"); i.line(8, 4, 9, 1, "#c8c4b4")   # feather
    i.px(7, 3, "#c84a4a"); i.px(6, 3, "#a83838")                    # meat bit
    i.px(9, 10, "#b09c72"); i.px(8, 12, "#ece0bc")
    return i
icons['snare_bait'] = snare_bait

def leather_vest():
    f = vest_icon("#9a6234", "#c48a50", "#6a4022", "#e8d8a8")()
    f.rect(11, 6, 11, 11, "#6a4022")
    for y in (7, 9, 11):
        f.px(4, y, "#e8d8a8")                         # stitching down the side
    f.line(3, 12, 12, 12, "#e8d8a8") if False else None
    for x in (4, 6, 9, 11):
        f.px(x, 12, "#e8d8a8")                        # hem stitching
    return f
icons['leather_vest'] = leather_vest

def arrow():
    i = Ic()
    i.line(4, 11, 11, 4, "#966438")                   # wooden shaft
    i.px(6, 9, "#ba844e"); i.px(9, 6, "#ba844e")
    for x, y in ((10, 3), (11, 3), (12, 3), (12, 4), (12, 5), (11, 4), (13, 2), (12, 2), (13, 3)):
        i.px(x, y, "#b0bac4")                         # steel head
    i.px(14, 1, "#e6ecf2"); i.px(12, 3, "#e6ecf2"); i.px(12, 5, "#6e7886"); i.px(12, 4, "#6e7886")
    for k in range(3):                                # fletching: white upper vane, red lower vane
        i.px(2 + k, 11 - k, "#f4f0e4"); i.px(1 + k, 11 - k, "#f4f0e4")
        i.px(4 + k, 13 - k, "#c84a4a"); i.px(4 + k, 12 - k, "#c84a4a")
    i.px(1, 12, "#c8c4b4"); i.px(3, 13, "#a83838")
    i.px(3, 12, "#966438"); i.px(2, 13, "#6a4022")    # nock
    return i
icons['arrow'] = arrow

def shell():
    i = Ic()                                          # scallop: fan of ribs over a hinge
    i.ell(8, 7.5, 6.2, 5.4, "#f0b49a")
    for x in range(S):
        for y in range(11, S):
            i.p.pop((x, y), None)
    i.rect(5, 11, 10, 11, "#e09a84"); i.rect(6, 12, 9, 13, "#d08672"); i.rect(5, 13, 10, 13, "#b86e60")
    for x1, y1 in ((3, 6), (5, 3), (8, 2), (11, 3), (13, 6)):
        i.line(8, 11, x1, y1, "#c87466")
    for x, y in ((3, 8), (4, 5), (6, 4), (7, 3), (6, 5), (4, 6)):
        i.px(x, y, "#ffe4cc")
    i.px(12, 9, "#d08672"); i.px(13, 8, "#d08672"); i.px(11, 10, "#d08672")
    return i
icons['shell'] = shell

def sea_glass():
    i = Ic()                                          # two frosted tumbled shards
    for y, x0, x1 in ((2, 5, 7), (3, 4, 9), (4, 3, 9), (5, 3, 10), (6, 2, 10), (7, 2, 9), (8, 3, 8), (9, 4, 6)):
        i.rect(x0, y, x1, y, "#4cc4a4")
    i.line(5, 3, 3, 6, "#b8f4dc"); i.line(6, 3, 5, 4, "#b8f4dc"); i.px(5, 3, "#ffffff")
    i.line(9, 5, 7, 8, "#2e9484"); i.line(10, 6, 8, 8, "#2e9484"); i.px(5, 9, "#2e9484"); i.px(6, 9, "#2e9484")
    for y, x0, x1 in ((9, 10, 11), (10, 8, 13), (11, 7, 14), (12, 7, 13), (13, 9, 12)):
        i.rect(x0, y, x1, y, "#5a9ee0")
    i.line(8, 11, 10, 10, "#c4e4ff"); i.px(9, 11, "#c4e4ff")
    i.line(10, 13, 12, 13, "#3a6cb0"); i.line(12, 12, 14, 11, "#3a6cb0")
    i.px(12, 3, "#ffffff"); i.px(12, 2, "#b8f4dc"); i.px(12, 4, "#b8f4dc"); i.px(11, 3, "#b8f4dc"); i.px(13, 3, "#b8f4dc")
    return i
icons['sea_glass'] = sea_glass

def pearl():
    i = Ic()
    i.ell(8, 8, 5.2, 5.2, "#b8b0cc")                  # lilac rim
    i.ell(7.4, 7.4, 4.3, 4.3, "#e4dcec")
    i.ell(6.8, 6.8, 2.8, 2.8, "#faf4f4")
    i.rect(5, 5, 6, 6, "#ffffff"); i.px(7, 5, "#ffffff")
    for x, y in ((11, 9), (10, 10), (9, 11)):
        i.px(x, y, "#f0c4d4")                         # pink reflected light
    for x, y in ((12, 10), (11, 11), (10, 12), (8, 13), (9, 12)):
        i.px(x, y, "#8c84a8")
    i.px(11, 6, "#c4e4ec"); i.px(12, 7, "#c4e4ec")
    return i
icons['pearl'] = pearl

def kelp():
    i = Ic()                                          # three wavy olive-green fronds from one holdfast
    def frond(pts, c, h):
        for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
            i.line(x0, y0, x1, y1, c); i.line(x0 + 1, y0, x1 + 1, y1, c)
        for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
            i.line(x0, y0, x1, y1, h)
    frond([(7, 12), (3, 9), (4, 6), (2, 3)], "#4e7a2c", "#78a43c")
    frond([(8, 12), (11, 9), (10, 6), (12, 3)], "#3c6428", "#5e8a30")
    frond([(7, 12), (6, 8), (8, 5), (6, 1)], "#5e8a30", "#a4c850")
    i.rect(5, 12, 10, 13, "#6a5428"); i.rect(6, 12, 8, 12, "#947838")
    i.px(5, 8, "#c4a848"); i.px(10, 8, "#c4a848")      # air bladders
    return i
icons['kelp'] = kelp

def acorn():
    i = Ic()
    i.ell(7.5, 10, 4, 4.5, "#c98a3c"); i.rect(6, 8, 6, 12, "#e8b060"); i.ell(7.5, 6, 5, 2.5, "#7a5030"); i.rect(4, 5, 7, 5, "#9c6c40"); i.rect(8, 2, 9, 3, "#5e3c22")
    return i

def pine_cone():
    i = Ic()
    i.ell(7.5, 9, 4, 5.5, "#8a5630")
    for y in (6, 9, 12):
        for x in (5, 8, 11):
            i.px(x - (y % 2), y, "#c0884c"); i.px(x - (y % 2), y + 1, "#5e381e")
    i.rect(7, 2, 8, 3, "#4a7a3a")
    return i

def sap():
    i = Ic()
    i.ell(7.5, 10.5, 4.5, 3.8, "#e09a20"); i.line(8, 2, 8, 8, "#e09a20"); i.rect(7, 5, 9, 8, "#e09a20"); i.rect(5, 9, 6, 11, "#ffd860"); i.rect(9, 12, 10, 12, "#a86410")
    return i

def hardwood():
    i = Ic()
    i.rect(2, 6, 11, 12, "#6e3c26"); i.rect(2, 6, 11, 7, "#92583a"); i.line(3, 10, 8, 10, "#4a2618"); i.ell(11, 9, 3, 3.4, "#c47c48"); i.ell(11, 9, 1.2, 1.5, "#8a4c2c")
    return i

for _f in (acorn, pine_cone, sap, hardwood):
    icons[_f.__name__] = _f

NEW_IDS = ['scarecrow', 'franchise_deed', 'slime_gel', 'crab_shell', 'copper_vest', 'iron_vest', 'engine_kit', 'grip_tyres', 'bumper_guard', 'lockpick_set', 'snare', 'leather', 'jerky', 'snare_bait', 'leather_vest', 'arrow', 'shell', 'sea_glass', 'pearl', 'kelp']  # appended after the last old icon, in this order

def is_variant(k, keys):
    """Quality variant ("turnip_gold") of another item. Ids like "pickaxe_gold" have no base item, so they get their own icon."""
    return k.endswith(('_silver', '_gold')) and k.rsplit("_", 1)[0] in keys

def main():
    keys = list(json.load(open(os.path.join(ROOT, "data", "items.json"))).keys())
    old_map = json.load(open(os.path.join(ROOT, "data", "item_icons.json")))
    old_img = Image.open(os.path.join(ROOT, "assets", "sprites", "items.png")).convert("RGBA")
    OLD = {k: old_img.crop((v * S, 0, v * S + S, S)) for k, v in old_map.items()}
    frames = [k for k in keys if not is_variant(k, keys)]
    for k in NEW_IDS:
        if k not in frames:
            frames.append(k)
    idx = {}
    nxt = max([v for k, v in old_map.items() if not is_variant(k, keys)] + [-1]) + 1
    for k in frames:  # stable: ids keep their old index, new ids take the next free one
        if k in old_map:
            idx[k] = old_map[k]
        else:
            idx[k] = nxt; nxt += 1
    strip = Image.new("RGBA", (S * nxt, S), (0, 0, 0, 0))
    mapping = {}
    for k in frames:
        n = idx[k]
        if k in icons:
            strip.paste(icons[k]().image(GLOW.get(k)), (n * S, 0))
        elif k in OLD:  # icons made earlier by a one-off script: keep their pixels
            strip.paste(OLD[k], (n * S, 0))
        mapping[k] = n
    for k in keys:  # quality variants reuse the base icon (the rarity border shows the quality)
        if is_variant(k, keys):
            mapping[k] = mapping[k.rsplit("_", 1)[0]]
    order = [k for k in keys] + [k for k in frames if k not in keys]
    mapping = {k: mapping[k] for k in order}
    strip.save(os.path.join(ROOT, "assets", "sprites", "items.png"))
    with open(os.path.join(ROOT, "data", "item_icons.json"), "w") as f:
        json.dump(mapping, f, indent=1)
        f.write("\n")
    # preview
    bg = Image.new("RGBA", strip.size, (70, 150, 70, 255))
    bg.alpha_composite(strip)
    bg.resize((strip.width * 6, strip.height * 6), Image.NEAREST).save("/tmp/items_preview.png")
    print("wrote items.png + item_icons.json,", len(keys), "frames")

if __name__ == "__main__":
    main()
