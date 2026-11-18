#!/usr/bin/env python3
"""Wooden signpost sprite (original, CC0): 32x40, post with two arrow boards. Deterministic."""
import os
from PIL import Image, ImageDraw
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = (42, 26, 16)
im = Image.new("RGBA", (32, 40), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
d.rectangle([14, 10, 18, 37], fill=(122, 80, 46), outline=OUT)            # post
d.line([(15, 12), (15, 36)], fill=(150, 104, 62))
d.polygon([(4, 8), (22, 8), (28, 12), (22, 16), (4, 16)], fill=(196, 150, 92), outline=OUT)   # board 1 (arrow right)
d.polygon([(28, 19), (10, 19), (4, 23), (10, 27), (28, 27)], fill=(176, 128, 76), outline=OUT)  # board 2 (arrow left)
for y in (11, 13): d.line([(7, y), (18, y)], fill=(122, 80, 46))
for y in (22, 24): d.line([(14, y), (25, y)], fill=(106, 70, 40))
d.ellipse([11, 36, 21, 39], fill=(96, 70, 44), outline=OUT)                 # base mound
d.point((6, 10), fill=(230, 196, 140)); d.point((6, 21), fill=(214, 176, 120))
im.save(os.path.join(ROOT, "assets", "sprites", "signpost.png")); print("wrote signpost.png")
