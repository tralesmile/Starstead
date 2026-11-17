#!/usr/bin/env python3
"""Meadow flowers (original, CC0): 6 frames of 16x16: white daisy, yellow buttercup, pink, blue cornflower, red poppy, purple clover. Deterministic."""
import os
from PIL import Image, ImageDraw
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = (42, 26, 16); STEM = (74, 138, 56); STEM_D = (50, 100, 42)
cols = [((250, 250, 244), (250, 206, 70)), ((252, 218, 70), (232, 150, 40)), ((240, 130, 170), (252, 220, 120)),
        ((90, 130, 232), (240, 240, 250)), ((226, 62, 56), (60, 30, 24)), ((170, 110, 210), (230, 200, 250))]
im = Image.new("RGBA", (16 * len(cols), 16), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
for i, (petal, mid) in enumerate(cols):
    ox = i * 16
    d.line([ox + 8, 15, ox + 8, 8], fill=STEM, width=1)
    d.line([ox + 8, 13, ox + 5, 11], fill=STEM_D); d.line([ox + 8, 12, ox + 11, 10], fill=STEM_D)
    for dx, dy in [(0, -3), (3, 0), (0, 3), (-3, 0), (2, -2), (-2, -2), (2, 2), (-2, 2)]:
        d.ellipse([ox + 8 + dx - 1, 6 + dy - 1, ox + 8 + dx + 1, 6 + dy + 1], fill=petal)
    d.ellipse([ox + 7, 5, ox + 9, 7], fill=mid)
    d.point((ox + 8, 6), fill=OUT if i == 4 else mid)
im.save(os.path.join(ROOT, "assets", "sprites", "flowers.png")); print("wrote flowers.png")
