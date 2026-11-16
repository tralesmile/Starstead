#!/usr/bin/env python3
"""Market stall sprite (original, CC0): striped awning, plank counter, crates. 64x56, feet at bottom."""
import os
from PIL import Image, ImageDraw
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
W, H = 64, 56
im = Image.new("RGBA", (W, H), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
OUT = (42, 26, 16); WOOD = [(110, 70, 38), (138, 90, 52), (166, 112, 63), (190, 132, 76)]
RED = [(142, 38, 38), (196, 64, 54)]; CREAM = [(214, 196, 150), (240, 226, 186)]
# back wall + posts
d.rectangle([6, 14, 57, 44], fill=WOOD[0], outline=OUT)
for x in (4, 56):
    d.rectangle([x, 8, x + 3, 50], fill=WOOD[1], outline=OUT); d.line([x + 1, 9, x + 1, 49], fill=WOOD[3])
# awning: alternating stripes with scalloped edge
for i, x in enumerate(range(2, 62, 6)):
    c = RED if i % 2 == 0 else CREAM
    d.rectangle([x, 2, x + 5, 16], fill=c[1], outline=OUT)
    d.rectangle([x + 1, 3, x + 2, 15], fill=c[1]); d.line([x + 4, 3, x + 4, 15], fill=c[0])
    d.pieslice([x, 12, x + 5, 20], 0, 180, fill=c[1], outline=OUT)
# counter
d.rectangle([4, 32, 59, 46], fill=WOOD[2], outline=OUT)
for y in (36, 40, 44):
    d.line([5, y, 58, y], fill=WOOD[1])
d.rectangle([4, 30, 59, 33], fill=WOOD[3], outline=OUT)
# goods on the counter: turnips, a crate
for x, col in ((10, (222, 200, 230)), (17, (230, 214, 236)), (24, (222, 200, 230))):
    d.ellipse([x, 24, x + 6, 30], fill=col, outline=OUT); d.rectangle([x + 2, 21, x + 4, 24], fill=(80, 140, 60))
d.rectangle([40, 22, 54, 31], fill=WOOD[2], outline=OUT); d.line([41, 26, 53, 26], fill=WOOD[1])
for x in (42, 47, 52):
    d.ellipse([x - 1, 17, x + 4, 23], fill=(200, 60, 50), outline=OUT)
# sign
d.rectangle([22, 5, 42, 13], fill=CREAM[1], outline=OUT)
d.ellipse([27, 6, 37, 12], fill=(232, 190, 60), outline=OUT); d.line([30, 8, 34, 8], fill=(150, 110, 30))
# feet
d.rectangle([4, 50, 8, 54], fill=WOOD[0], outline=OUT); d.rectangle([55, 50, 59, 54], fill=WOOD[0], outline=OUT)
im.save(os.path.join(ROOT, "assets", "sprites", "stall.png"))
print("wrote stall.png")
