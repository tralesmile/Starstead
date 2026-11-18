#!/usr/bin/env python3
"""Wildlife sprites (original, CC0): deer 30x24, rabbit 16x14, boar 22x18 frames, 2-frame sheets, side view facing right. Deterministic."""
import os
from PIL import Image, ImageDraw
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = (42, 26, 16)
def save(im, n): im.save(os.path.join(ROOT, "assets", "sprites", n)); print("wrote", n)

# deer: 2 frames -> 60x26 sheet (30x26 each), brown, antlers, white tail patch
class Dy:  # draw with a fixed y offset so parts may sit above y=0 in the sketch
    def __init__(s, d, oy): s.d, s.oy = d, oy
    def _y(s, v): return [(p[0], p[1]+s.oy) for p in v] if isinstance(v[0], (tuple, list)) else [v[i]+(s.oy if i % 2 else 0) for i in range(len(v))]
    def rectangle(s, v, **k): s.d.rectangle(s._y(v), **k)
    def ellipse(s, v, **k): s.d.ellipse(s._y(v), **k)
    def polygon(s, v, **k): s.d.polygon(s._y(v), **k)
    def line(s, v, **k): s.d.line(s._y(v), **k)
    def point(s, p, **k): s.d.point((p[0], p[1]+s.oy), **k)
im = Image.new("RGBA", (60, 26), (0, 0, 0, 0)); d = Dy(ImageDraw.Draw(im), 2)
for f in range(2):
    ox = f * 30; b = (156, 104, 62); lt = (196, 146, 96); dk = (110, 70, 42); wh = (246, 240, 226)
    lo = 2 if f else 0
    for lx in (6, 20):   # far legs (darker), drawn first
        dx = -lo if lx == 6 else lo
        d.rectangle([ox+lx+dx, 14, ox+lx+dx, 21], fill=dk, outline=OUT)
    d.ellipse([ox+3, 8, ox+22, 17], fill=b, outline=OUT)                     # body
    d.rectangle([ox+7, 14, ox+18, 16], fill=lt)                              # belly
    d.rectangle([ox+7, 9, ox+17, 10], fill=(176, 122, 76))                   # back light
    d.rectangle([ox+2, 9, ox+4, 12], fill=wh, outline=OUT)                   # tail patch
    d.point((ox+3, 10), fill=wh)
    d.polygon([(ox+19, 11), (ox+22, 3), (ox+25, 3), (ox+24, 12), (ox+21, 14)], fill=b, outline=OUT)  # neck
    d.rectangle([ox+22, 1, ox+27, 6], fill=b, outline=OUT)                   # head
    d.rectangle([ox+26, 4, ox+28, 6], fill=lt, outline=OUT)                  # muzzle
    d.point((ox+28, 4), fill=(30, 20, 16)); d.point((ox+25, 3), fill=OUT)    # nose, eye
    d.rectangle([ox+21, 0, ox+22, 2], fill=b, outline=OUT)                   # ear
    for (x0, y0, x1, y1) in [(24, 1, 24, -1), (26, 1, 27, -1)]:             # antlers
        d.line([ox+x0, y0, ox+x1, y1], fill=(226, 206, 160))
    d.point((ox+23, 0), fill=(226, 206, 160))
    for lx in (8, 18):   # near legs
        dx = lo if lx == 8 else -lo
        d.rectangle([ox+lx+dx, 15, ox+lx+dx+1, 22], fill=b, outline=OUT)
        d.rectangle([ox+lx+dx, 21, ox+lx+dx+1, 22], fill=(40, 28, 20))
save(im, "deer.png")

# rabbit: 2 frames -> 32x14 sheet (16x14 each), grey-brown, long ears, cotton tail
im = Image.new("RGBA", (32, 14), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
for f in range(2):
    ox = f * 16; b = (150, 130, 112); lt = (190, 172, 152); dk = (110, 92, 78)
    sy = 0 if f == 0 else -1   # frame 2 = stretched hop
    d.ellipse([ox+2, 6+sy, ox+11, 12+sy], fill=b, outline=OUT)               # body
    d.rectangle([ox+4, 10+sy, ox+9, 11+sy], fill=lt)                         # belly
    d.ellipse([ox+0, 8+sy, ox+3, 11+sy], fill=(246, 240, 226), outline=OUT)  # tail
    d.ellipse([ox+9, 4+sy, ox+14, 9+sy], fill=b, outline=OUT)                # head
    d.rectangle([ox+8, 0+sy, ox+9, 5+sy], fill=b, outline=OUT)               # ears
    d.rectangle([ox+10, 1+sy, ox+11, 5+sy], fill=b, outline=OUT)
    d.point((ox+9, 2+sy), fill=(222, 160, 160)); d.point((ox+10, 3+sy), fill=(222, 160, 160))
    d.point((ox+12, 6+sy), fill=OUT); d.point((ox+14, 7+sy), fill=(222, 150, 150))
    if f == 0:
        d.rectangle([ox+4, 11, ox+7, 12], fill=dk, outline=OUT)              # haunch foot
        d.rectangle([ox+10, 11, ox+12, 12], fill=dk, outline=OUT)            # front paw
    else:
        d.rectangle([ox+2, 12, ox+6, 13], fill=dk, outline=OUT)              # stretched hind
        d.rectangle([ox+11, 11, ox+14, 12], fill=dk, outline=OUT)            # reaching front
save(im, "rabbit.png")

# boar: 2 frames -> 44x18 sheet (22x18 each), dark bristly, tusks
im = Image.new("RGBA", (44, 18), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
for f in range(2):
    ox = f * 22; b = (84, 64, 54); lt = (118, 92, 76); dk = (52, 40, 36)
    lo = 1 if f else 0
    for lx in (6, 15):   # far legs
        dx = -lo if lx == 6 else lo
        d.rectangle([ox+lx+dx, 12, ox+lx+dx+1, 16], fill=dk, outline=OUT)
    d.ellipse([ox+2, 4, ox+17, 14], fill=b, outline=OUT)                     # body
    d.rectangle([ox+5, 5, ox+14, 6], fill=lt)                                # mane highlight
    for x in range(4, 16, 2):                                                # bristles along the back
        d.point((ox+x, 3), fill=OUT); d.point((ox+x, 4), fill=dk)
    d.rectangle([ox+0, 6, ox+2, 7], fill=dk)                                 # tail tuft
    d.ellipse([ox+14, 5, ox+20, 12], fill=b, outline=OUT)                    # head
    d.rectangle([ox+18, 8, ox+21, 11], fill=(150, 110, 96), outline=OUT)     # snout
    d.point((ox+16, 7), fill=(240, 230, 210))                                # eye
    d.rectangle([ox+14, 4, ox+15, 5], fill=dk, outline=OUT)                  # ear
    d.point((ox+19, 12), fill=(240, 236, 220)); d.point((ox+19, 13), fill=(240, 236, 220))  # tusk
    d.point((ox+18, 13), fill=(240, 236, 220))
    for lx in (8, 14):   # near legs
        dx = lo if lx == 8 else -lo
        d.rectangle([ox+lx+dx, 12, ox+lx+dx+1, 17], fill=b, outline=OUT)
        d.rectangle([ox+lx+dx, 16, ox+lx+dx+1, 17], fill=(32, 24, 20))
save(im, "boar.png")
