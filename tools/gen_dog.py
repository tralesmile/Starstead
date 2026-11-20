#!/usr/bin/env python3
"""Guard dog sprite (original, CC0): 2 frames (stand, run) 28x22, side view facing right. Deterministic.
Writes assets/sprites/guard_dog.png; preview /tmp/dog.png."""
import os
from PIL import Image, ImageDraw
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = (30, 20, 14, 255)
FUR = [(92, 58, 30), (132, 86, 46), (170, 118, 66), (200, 152, 96)]


def frame(run):
    im = Image.new("RGBA", (28, 22), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    d.ellipse([3, 18, 25, 21], fill=(0, 0, 0, 70))                       # ground shadow
    legs = [(7, 19), (10, 19), (18, 19), (21, 19)] if not run else [(4, 17), (11, 19), (16, 19), (23, 17)]
    for x, bottom in legs:
        d.rectangle([x, 14, x + 1, bottom], fill=FUR[0])
    d.ellipse([5, 7, 23, 16], fill=FUR[1])                                # body
    d.ellipse([7, 7, 20, 11], fill=FUR[2])                                # lit back
    d.line([(5, 10), (1, 5 if not run else 8)], fill=FUR[1], width=2)    # tail
    d.ellipse([18, 3, 27, 11], fill=FUR[1]); d.ellipse([19, 3, 25, 7], fill=FUR[2])   # head
    d.rectangle([24, 7, 27, 9], fill=FUR[1])                              # snout
    d.point((27, 8), fill=(20, 14, 10)); d.point((23, 5), fill=(20, 14, 10))          # nose, eye
    d.polygon([(19, 3), (21, 0), (22, 4)], fill=FUR[0])                   # ear
    d.rectangle([18, 8, 19, 11], fill=(176, 40, 34))                      # red collar at the neck
    d.point((19, 11), fill=(236, 200, 80))                                # tag
    px = im.load(); w, h = im.size
    edge = []
    for y in range(h):
        for x in range(w):
            if px[x, y][3] > 200:
                continue
            for dx, dy in ((0, 1), (1, 0), (-1, 0), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < w and 0 <= ny < h and px[nx, ny][3] > 200:
                    edge.append((x, y)); break
    for x, y in edge:
        if px[x, y][3] < 100:
            px[x, y] = OUT
    return im


sheet = Image.new("RGBA", (56, 22), (0, 0, 0, 0))
sheet.paste(frame(False), (0, 0)); sheet.paste(frame(True), (28, 0))
sheet.save(os.path.join(ROOT, "assets", "sprites", "guard_dog.png"))
sheet.resize((224, 88), Image.NEAREST).save("/tmp/dog.png")
print("wrote guard_dog.png")
