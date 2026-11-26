#!/usr/bin/env python3
"""Sunday League noticeboard beside the pitch: two posts, a framed board, a pinned fixture sheet and a ball emblem."""
from PIL import Image, ImageDraw
W, H = 32, 44
im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
d = ImageDraw.Draw(im)
OUT, DARK, WOOD, LIT = (45, 26, 14, 255), (104, 66, 34, 255), (146, 97, 49, 255), (187, 135, 72, 255)
for x in (5, 23):
    d.rectangle([x, 22, x + 3, 42], fill=DARK, outline=OUT)
    d.line([x + 1, 23, x + 1, 41], fill=WOOD)
d.rectangle([1, 5, 30, 29], fill=WOOD, outline=OUT)
d.line([2, 6, 29, 6], fill=LIT)
d.rectangle([4, 9, 27, 26], fill=(232, 218, 176, 255), outline=DARK)
d.polygon([(0, 6), (15, 0), (16, 0), (31, 6)], fill=(120, 54, 38, 255), outline=OUT)
d.ellipse([6, 11, 14, 19], fill=(250, 250, 245, 255), outline=OUT)
d.rectangle([9, 14, 11, 16], fill=OUT)
for p in [(8, 12), (12, 12), (7, 17), (13, 17)]:
    d.point(p, fill=OUT)
for i, y in enumerate((12, 15, 18, 21, 23)):
    d.line([17, y, 25 - (i % 2) * 3, y], fill=(96, 74, 52, 255))
d.point((16, 10), fill=(200, 52, 40, 255))
d.rectangle([6, 22, 14, 24], fill=(226, 172, 48, 255))
im.save("assets/sprites/league_board.png")
