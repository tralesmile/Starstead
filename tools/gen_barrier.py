#!/usr/bin/env python3
"""Road barricade sprite (original, CC0): 32x32, red/white striped plank on two wooden legs with a small sign. Deterministic."""
import os
from PIL import Image, ImageDraw
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = (40, 24, 20)
im = Image.new("RGBA", (32, 32), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
d.ellipse([2, 26, 30, 31], fill=(0, 0, 0, 60))                       # soft ground shadow
for x in (5, 24):                                                    # legs
    d.rectangle([x, 14, x + 2, 28], fill=(112, 76, 44), outline=OUT)
    d.line([(x + 1, 15), (x + 1, 27)], fill=(146, 104, 62))
for y0 in (8, 16):                                                   # two striped planks
    d.rectangle([1, y0, 30, y0 + 5], fill=(236, 232, 222), outline=OUT)
    for sx in range(-6, 32, 8):
        d.polygon([(sx + 1, y0 + 5), (sx + 5, y0 + 5), (sx + 9, y0 + 1), (sx + 5, y0 + 1)], fill=(200, 48, 40))
    d.rectangle([0, y0, 0, y0 + 5], fill=OUT); d.rectangle([31, y0, 31, y0 + 5], fill=OUT)
d.rectangle([13, 1, 18, 7], fill=(236, 196, 60), outline=OUT)        # warning sign on top
d.line([(15, 3), (16, 5)], fill=OUT); d.point((16, 6), fill=OUT)
d.point((3, 10), fill=(255, 255, 255)); d.point((3, 18), fill=(255, 255, 255))
im.save(os.path.join(ROOT, "assets", "sprites", "road_barrier.png")); print("wrote road_barrier.png")
