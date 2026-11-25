#!/usr/bin/env python3
"""Butcher block 32x32 (original, CC0): chopping stump with cleaver + small drying rack with jerky. Deterministic."""
import os
from PIL import Image, ImageDraw
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = (42, 26, 16)
WOOD = [(110, 70, 38), (138, 90, 52), (166, 112, 63), (190, 132, 76)]
IRON = [(52, 48, 52), (84, 80, 86), (122, 118, 124), (160, 156, 160)]
MEAT = [(74, 34, 28), (122, 58, 44), (170, 92, 70)]

def main():
    im = Image.new("RGBA", (32, 32), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    d.line([2, 31, 30, 31], fill=(42, 26, 16, 70)); d.line([4, 30, 28, 30], fill=(42, 26, 16, 40))
    # drying rack (right): two posts, crossbar, hanging jerky
    for x in (21, 28):
        d.rectangle([x, 8, x + 1, 30], fill=WOOD[1], outline=OUT)
        d.line([x + 1, 9, x + 1, 29], fill=WOOD[3]) if False else d.line([x, 9, x, 29], fill=WOOD[3])
    d.rectangle([19, 6, 30, 8], fill=WOOD[2], outline=OUT)
    d.line([20, 7, 29, 7], fill=WOOD[3])
    d.line([20, 30, 22, 30], fill=OUT); d.line([27, 30, 29, 30], fill=OUT)
    for x, ln in ((23, 9), (25, 12), (27, 8)):
        d.line([x, 9, x, 9 + ln], fill=OUT)                      # strip outline column
        d.line([x, 10, x, 9 + ln], fill=MEAT[1])
        d.point([x, 10], fill=MEAT[2]); d.point([x, 9 + ln - 3], fill=MEAT[0])
        d.point([x, 9 + ln + 1], fill=OUT)
    d.point([24, 14], fill=(200, 160, 110))
    # chopping stump (left)
    d.polygon([(3, 19), (18, 19), (19, 30), (2, 30)], fill=WOOD[1], outline=OUT)
    d.line([4, 21, 4, 29], fill=WOOD[3])
    d.line([16, 21, 17, 29], fill=WOOD[0])
    d.line([9, 24, 9, 29], fill=WOOD[0]); d.line([12, 23, 13, 29], fill=WOOD[2])
    d.ellipse([2, 14, 19, 22], fill=WOOD[3], outline=OUT)
    d.ellipse([4, 15, 17, 20], fill=WOOD[2])
    d.arc([6, 16, 14, 19], 0, 360, fill=WOOD[1])                 # growth rings
    d.point([10, 17], fill=WOOD[0])
    d.line([5, 19, 8, 20], fill=WOOD[0])                         # old cut marks
    d.point([13, 15], fill=MEAT[1]); d.point([14, 16], fill=MEAT[0])   # blood spot
    # cleaver stuck in the block
    d.rectangle([10, 3, 13, 6], fill=WOOD[2], outline=OUT)       # handle
    d.polygon([(5, 8), (13, 7), (14, 13), (5, 13)], fill=IRON[2], outline=OUT)   # blade
    d.line([6, 9, 13, 8], fill=IRON[3]); d.line([6, 12, 13, 12], fill=IRON[1])
    d.point([7, 10], fill=IRON[1]); d.point([12, 10], fill=OUT)  # hang hole
    d.line([5, 14, 14, 14], fill=OUT)
    im.save(os.path.join(ROOT, "assets", "sprites", "int_butcher.png"))
    print("wrote int_butcher.png")

if __name__ == "__main__":
    main()
