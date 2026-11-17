#!/usr/bin/env python3
"""Grass tuft sprite (16x16, original): a few layered blades in the ground-shader greens. Run from repo root."""
from PIL import Image
import random
rnd = random.Random(11)
G = [(52, 92, 40), (70, 120, 52), (92, 146, 62), (118, 172, 80)]
im = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
blades = [(5, 9, -2), (7, 11, -1), (8, 12, 0), (10, 10, 1), (11, 8, 2)]
for bx, h, lean in blades:
    for k in range(h):
        t = k / h
        x = int(round(bx + lean * t * t * 2))
        y = 14 - k
        im.putpixel((x, y), G[min(3, 1 + int(t * 3))] + (255,))
        if k < 2:
            im.putpixel((x, y), G[0] + (255,))
im.save("assets/sprites/grass_tuft.png")
print("wrote assets/sprites/grass_tuft.png")
