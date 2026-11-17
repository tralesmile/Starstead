#!/usr/bin/env python3
"""Tree stump sprite (original, CC0): 32x24, cut top with rings, root flare. Deterministic."""
import os
from PIL import Image, ImageDraw
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = (42, 26, 16)
im = Image.new("RGBA", (32, 24), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
d.polygon([(6, 22), (9, 12), (23, 12), (26, 22)], fill=(122, 80, 46), outline=OUT)        # trunk side
d.line([(11, 14), (10, 21)], fill=(96, 62, 36)); d.line([(20, 14), (22, 21)], fill=(150, 104, 62))
d.polygon([(3, 23), (7, 20), (8, 23)], fill=(110, 72, 42), outline=OUT)                    # roots
d.polygon([(29, 23), (25, 20), (24, 23)], fill=(110, 72, 42), outline=OUT)
d.ellipse([8, 6, 24, 16], fill=(214, 170, 108), outline=OUT)                               # cut top
d.ellipse([11, 8, 21, 14], outline=(176, 128, 76)); d.ellipse([14, 10, 18, 12], outline=(160, 112, 64))
d.point((16, 11), fill=(140, 96, 56))
im.save(os.path.join(ROOT, "assets", "sprites", "stump.png")); print("wrote stump.png")
