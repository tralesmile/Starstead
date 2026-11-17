#!/usr/bin/env python3
"""Animal sprites (original, CC0): chicken 16x16 and horse 32x28, side view facing right, plus a heart. Deterministic."""
import os
from PIL import Image, ImageDraw
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = (42, 26, 16)
def save(im, n): im.save(os.path.join(ROOT, "assets", "sprites", n)); print("wrote", n)

# chicken: 2 frames (idle, peck) -> 32x16 sheet
im = Image.new("RGBA", (32, 16), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
for f in range(2):
    ox = f * 16; hy = 0 if f == 0 else 3
    d.ellipse([ox+3, 6, ox+12, 13], fill=(246, 240, 226), outline=OUT)      # body
    d.rectangle([ox+3, 8, ox+5, 10], fill=(222, 210, 190))                  # tail shade
    d.ellipse([ox+9, 2+hy, ox+13, 6+hy], fill=(246, 240, 226), outline=OUT)  # head
    d.point((ox+11, 3+hy), fill=OUT)
    d.rectangle([ox+12, 4+hy, ox+14, 4+hy], fill=(240, 170, 40))            # beak
    d.rectangle([ox+10, 1+hy, ox+11, 2+hy], fill=(210, 50, 50))             # comb
    d.line([ox+6, 13, ox+6, 15], fill=(240, 170, 40)); d.line([ox+9, 13, ox+9, 15], fill=(240, 170, 40))
save(im, "chicken.png")

# horse: 2 frames (stand, step) -> 64x28 sheet
im = Image.new("RGBA", (64, 28), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
for f in range(2):
    ox = f * 32; b = (150, 98, 56); lt = (176, 120, 72)
    d.ellipse([ox+4, 8, ox+24, 19], fill=b, outline=OUT)                    # body
    d.rectangle([ox+8, 9, ox+20, 11], fill=lt)
    d.polygon([(ox+20, 10), (ox+26, 2), (ox+30, 4), (ox+27, 12), (ox+22, 14)], fill=b, outline=OUT)  # neck+head
    d.rectangle([ox+27, 3, ox+30, 8], fill=lt)
    d.point((ox+28, 4), fill=OUT)
    d.polygon([(ox+22, 3), (ox+24, 0), (ox+25, 4)], fill=(70, 44, 26), outline=OUT)  # mane
    d.line([ox+4, 11, ox+1, 17], fill=(70, 44, 26), width=2)                # tail
    lo = 2 if f else 0
    for lx in (7, 11, 18, 22):
        dx = lo if lx in (7, 18) else -lo
        d.rectangle([ox+lx+dx, 18, ox+lx+dx+1, 26], fill=b, outline=OUT)
        d.rectangle([ox+lx+dx, 25, ox+lx+dx+1, 26], fill=(40, 28, 20))
save(im, "horse.png")

# heart 8x8
im = Image.new("RGBA", (8, 8), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
for p in [(1,1),(2,1),(5,1),(6,1),(0,2),(1,2),(2,2),(3,2),(4,2),(5,2),(6,2),(7,2),(0,3),(1,3),(2,3),(3,3),(4,3),(5,3),(6,3),(7,3),(1,4),(2,4),(3,4),(4,4),(5,4),(6,4),(2,5),(3,5),(4,5),(5,5),(3,6),(4,6)]:
    d.point(p, fill=(235, 70, 90))
d.point((2,2), fill=(255, 170, 180))
save(im, "heart.png")

# cow: 2 frames (stand, step) -> 56x22 sheet (28x22 each), side view facing right, white with dark patches
im = Image.new("RGBA", (56, 22), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
for f in range(2):
    ox = f * 28; wh = (244, 240, 232); pa = (70, 58, 52)
    d.ellipse([ox+3, 5, ox+21, 16], fill=wh, outline=OUT)                          # body
    d.ellipse([ox+6, 6, ox+11, 11], fill=pa); d.ellipse([ox+13, 9, ox+19, 14], fill=pa)  # patches
    d.rectangle([ox+19, 3, ox+25, 10], fill=wh, outline=OUT)                       # head
    d.rectangle([ox+23, 7, ox+25, 10], fill=(238, 170, 160))                       # muzzle
    d.point((ox+22, 5), fill=OUT)
    d.rectangle([ox+19, 1, ox+20, 3], fill=(230, 210, 150)); d.rectangle([ox+24, 1, ox+25, 3], fill=(230, 210, 150))  # horns
    d.line([ox+3, 8, ox+1, 14], fill=pa, width=2)                                   # tail
    d.ellipse([ox+10, 14, ox+14, 17], fill=(238, 170, 160))                         # udder
    lo = 2 if f else 0
    for lx in (6, 9, 16, 19):
        dx = lo if lx in (6, 16) else -lo
        d.rectangle([ox+lx+dx, 15, ox+lx+dx+1, 20], fill=wh, outline=OUT)
        d.rectangle([ox+lx+dx, 19, ox+lx+dx+1, 20], fill=(40, 28, 20))
save(im, "cow.png")

# sheep: 2 frames -> 44x18 sheet (22x18 each), fluffy wool body, dark face
im = Image.new("RGBA", (44, 18), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
for f in range(2):
    ox = f * 22; wool = (240, 238, 228); wd = (206, 202, 190)
    for cx, cy, r in [(7, 8, 4), (11, 6, 4), (15, 8, 4), (9, 10, 4), (13, 10, 4)]:
        d.ellipse([ox+cx-r, cy-r+2, ox+cx+r, cy+r+2], fill=wool, outline=OUT)
    for cx, cy, r in [(8, 8, 3), (12, 7, 3), (14, 9, 3), (10, 10, 3)]:
        d.ellipse([ox+cx-r, cy-r+2, ox+cx+r, cy+r+2], fill=wool)
    d.point((ox+9, 7), fill=wd); d.point((ox+13, 9), fill=wd)
    d.ellipse([ox+15, 5, ox+20, 11], fill=(86, 70, 60), outline=OUT)               # face
    d.point((ox+18, 7), fill=(240, 240, 240))
    lo = 1 if f else 0
    for lx in (7, 10, 14):
        dx = lo if lx == 7 else -lo
        d.rectangle([ox+lx+dx, 13, ox+lx+dx+1, 16], fill=(86, 70, 60), outline=OUT)
save(im, "sheep.png")
