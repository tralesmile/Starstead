#!/usr/bin/env python3
"""Lantern post sprite (original, CC0): 16x40, wooden post with a hanging glass lantern. Deterministic."""
import os
from PIL import Image, ImageDraw
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = (42, 26, 16)
im = Image.new("RGBA", (16, 40), (0, 0, 0, 0))
d = ImageDraw.Draw(im)
# post
d.rectangle([7, 12, 9, 38], fill=(138, 90, 52), outline=OUT)
d.line([8, 13, 8, 37], fill=(166, 112, 63))
d.rectangle([5, 37, 11, 39], fill=(110, 70, 38), outline=OUT)
# arm
d.rectangle([7, 10, 14, 11], fill=(110, 70, 38), outline=OUT)
# lantern body
d.rectangle([11, 12, 14, 19], fill=(255, 214, 110), outline=OUT)
d.line([12, 13, 12, 18], fill=(255, 240, 180))
d.rectangle([10, 11, 15, 12], fill=(60, 44, 36), outline=OUT)
d.rectangle([10, 19, 15, 20], fill=(60, 44, 36), outline=OUT)
im.save(os.path.join(ROOT, "assets", "sprites", "lantern.png"))
print("wrote lantern.png")
