#!/usr/bin/env python3
"""Sprinkler world sprite (original, CC0): 32x32, copper head on a short pipe with a stone base. Deterministic."""
import os
from PIL import Image, ImageDraw
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = (42, 26, 16)
im = Image.new("RGBA", (32, 32), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
d.ellipse([8, 22, 24, 29], fill=(120, 124, 130), outline=OUT)            # stone base
d.ellipse([11, 23, 21, 27], fill=(150, 154, 160))
d.rectangle([14, 13, 17, 24], fill=(176, 186, 196), outline=OUT)         # pipe
d.line([(15, 14), (15, 23)], fill=(226, 232, 238))
d.ellipse([9, 8, 22, 15], fill=(212, 129, 74), outline=OUT)              # copper head
d.ellipse([11, 9, 19, 12], fill=(238, 170, 110))
for x, y in [(6, 7), (4, 10), (26, 7), (28, 10), (16, 4), (11, 5), (21, 5)]:
    d.point((x, y), fill=(150, 210, 255))                                # spray droplets
im.save(os.path.join(ROOT, "assets", "sprites", "sprinkler.png")); print("wrote sprinkler.png")
