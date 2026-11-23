#!/usr/bin/env python3
"""Scarecrow world sprite 32x48 + crow flap sheet 64x16 (original, CC0). Deterministic."""
import os
from PIL import Image, ImageDraw
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = (42, 26, 16)
im = Image.new("RGBA", (32, 48), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
d.ellipse([6, 41, 26, 47], fill=(20, 30, 14, 90))                              # shadow
d.rectangle([14, 20, 18, 44], fill=(138, 90, 52), outline=OUT)                 # post
d.line([(15, 22), (15, 43)], fill=(190, 138, 84))
d.rectangle([13, 43, 19, 45], fill=(106, 64, 38), outline=OUT)                 # foot block
d.rectangle([2, 19, 29, 23], fill=(150, 100, 58), outline=OUT)                 # crossbar
d.line([(3, 20), (28, 20)], fill=(196, 146, 90))
d.polygon([(8, 21), (24, 21), (26, 36), (6, 36)], fill=(176, 120, 78), outline=OUT)  # burlap shirt
d.polygon([(9, 22), (14, 22), (13, 35), (8, 35)], fill=(206, 152, 100))        # light left
d.polygon([(21, 22), (24, 22), (25, 35), (20, 35)], fill=(140, 92, 58))        # shade right
d.line([(10, 28), (12, 30)], fill=(90, 54, 34)); d.line([(12, 28), (10, 30)], fill=(90, 54, 34))  # patch
d.rectangle([17, 29, 21, 33], fill=(120, 150, 96), outline=(70, 90, 56))       # green patch
d.line([(7, 35), (25, 35)], fill=(100, 64, 36))                                # rope belt
for x, y in [(8, 37), (12, 38), (16, 37), (20, 38), (24, 37)]:                 # straw hem
    d.line([(x, 36), (x - 1, y + 2)], fill=(232, 200, 96)); d.line([(x + 1, 36), (x + 1, y + 3)], fill=(196, 160, 60))
for sx, dirn in ((2, -1), (29, 1)):                                            # straw tufts at sleeves
    for k, (dx, dy) in enumerate([(0, 1), (1, 2), (-1, 3), (2, 0), (0, 4)]):
        x = sx + dirn * dx
        d.line([(x, 22), (x + dirn * (1 + k % 2), 22 + dy + 1)], fill=(240, 210, 104) if k % 2 == 0 else (204, 168, 64))
d.ellipse([9, 6, 23, 20], fill=(214, 186, 128), outline=OUT)                   # sack head
d.ellipse([11, 8, 17, 13], fill=(236, 214, 158))
d.line([(14, 19), (18, 19)], fill=(120, 84, 50)); d.line([(13, 18), (13, 20)], fill=(120, 84, 50)); d.line([(19, 18), (19, 20)], fill=(120, 84, 50))  # neck tie
d.rectangle([12, 12, 14, 14], fill=OUT); d.rectangle([18, 12, 20, 14], fill=OUT)   # eyes
d.point((12, 12), fill=(255, 255, 255)); d.point((18, 12), fill=(255, 255, 255))
d.line([(13, 17), (19, 17)], fill=OUT)                                         # stitched mouth
for x in (14, 16, 18):
    d.line([(x, 16), (x, 18)], fill=OUT)
d.line([(21, 12), (21, 14)], fill=(110, 76, 44)); d.point((21, 13), fill=(110, 76, 44))  # patch stitch on head
d.ellipse([3, 4, 29, 10], fill=(122, 78, 42), outline=OUT)                     # hat brim, floppy
d.polygon([(10, 6), (12, 0), (21, 0), (23, 6)], fill=(138, 90, 48), outline=OUT)  # crown
d.polygon([(11, 5), (13, 1), (16, 1), (15, 5)], fill=(170, 118, 66))
d.rectangle([11, 5, 22, 6], fill=(90, 50, 30))                                  # hat band
d.point((4, 8), fill=(90, 56, 30)); d.point((28, 9), fill=(90, 56, 30))
im.save(os.path.join(ROOT, "assets", "sprites", "scarecrow.png")); print("wrote scarecrow.png")

# crow sheet: 4 frames 16x16 (wings up, mid, down, mid), facing right
BLK = (28, 28, 38); LT = (74, 78, 100); BEAK = (232, 176, 60)
sheet = Image.new("RGBA", (64, 16), (0, 0, 0, 0))
for f, wing in enumerate(("up", "mid", "down", "mid")):
    fr = Image.new("RGBA", (16, 16), (0, 0, 0, 0)); g = ImageDraw.Draw(fr)
    g.ellipse([4, 7, 12, 12], fill=BLK, outline=OUT)                           # body
    g.polygon([(3, 9), (0, 10), (1, 12), (4, 8)], fill=BLK, outline=OUT)      # tail
    g.ellipse([10, 5, 14, 9], fill=BLK, outline=OUT)                           # head
    g.polygon([(14, 7), (16, 8), (14, 8)], fill=BEAK)
    g.point((12, 6), fill=(255, 255, 255))
    g.line([(5, 8), (10, 8)], fill=LT)
    pts = {"up": [(6, 8), (3, 1), (8, 3), (10, 8)], "mid": [(5, 8), (1, 6), (9, 6), (10, 8)],
           "down": [(5, 9), (4, 15), (9, 14), (10, 10)]}[wing]
    g.polygon(pts, fill=(40, 40, 54), outline=OUT)
    a, b = pts[1], pts[2]
    g.line([a, ((a[0] + b[0]) // 2, (a[1] + b[1]) // 2)], fill=LT)
    g.line([(6, 12), (6, 14)], fill=(110, 80, 40)); g.line([(9, 12), (9, 14)], fill=(110, 80, 40))
    sheet.paste(fr, (f * 16, 0))
sheet.save(os.path.join(ROOT, "assets", "sprites", "crow.png")); print("wrote crow.png")
