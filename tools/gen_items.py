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

GLOW = {'glow_bait': (96, 240, 176, 120), 'golden_koi': (255, 224, 96, 90), 'river_king': (255, 200, 80, 110)}

def main():
    keys = list(json.load(open(os.path.join(ROOT, "data", "items.json"))).keys())
    old_map = json.load(open(os.path.join(ROOT, "data", "item_icons.json")))
    old_img = Image.open(os.path.join(ROOT, "assets", "sprites", "items.png")).convert("RGBA")
    OLD = {k: old_img.crop((v * S, 0, v * S + S, S)) for k, v in old_map.items()}
    strip = Image.new("RGBA", (S * len(keys), S), (0, 0, 0, 0))
    mapping = {}
    for n, k in enumerate(keys):
        if k in icons:
            strip.paste(icons[k]().image(GLOW.get(k)), (n * S, 0))
        elif k in OLD:  # icons made earlier by a one-off script: keep their pixels
            strip.paste(OLD[k], (n * S, 0))
        mapping[k] = n
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
