#!/usr/bin/env python3
"""Saplings (3 stages x oak/pine, 32x40 frames) and big hardwood stump + fallen log (48x32 frames). Original, CC0. Deterministic."""
import os
from PIL import Image, ImageDraw
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = (42, 26, 16, 255)

def outline(im):
    src = im.copy()
    for y in range(im.height):
        for x in range(im.width):
            if src.getpixel((x, y))[3]:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                q = (x + dx, y + dy)
                if 0 <= q[0] < im.width and 0 <= q[1] < im.height and src.getpixel(q)[3]:
                    im.putpixel((x, y), OUT)
                    break
    return im

def blob(d, cx, cy, r, dark, mid, light):
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=dark)
    d.ellipse([cx - r, cy - r, cx + r - 2, cy + r - 2], fill=mid)
    d.ellipse([cx - r + 1, cy - r + 1, cx, cy - 1], fill=light)

def sapling(kind, stage):
    # foot of the plant is at (16, 36)
    im = Image.new("RGBA", (32, 40), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    d.ellipse([10, 34, 22, 38], fill=(122, 88, 52))      # mound of turned earth
    d.line([(12, 35), (18, 35)], fill=(150, 112, 68))
    h = [8, 16, 25][stage]
    d.rectangle([15, 36 - h, 16 if stage < 2 else 17, 35], fill=(126, 84, 46))
    d.line([(15, 36 - h), (15, 35)], fill=(160, 112, 64))
    if kind == "oak":
        dk, md, lt = (46, 104, 46), (76, 142, 54), (130, 188, 74)
        if stage == 0:
            blob(d, 12, 28, 3, dk, md, lt); blob(d, 20, 27, 3, dk, md, lt)
        elif stage == 1:
            blob(d, 11, 24, 4, dk, md, lt); blob(d, 21, 23, 4, dk, md, lt); blob(d, 16, 18, 5, dk, md, lt)
        else:
            blob(d, 10, 20, 6, dk, md, lt); blob(d, 22, 19, 6, dk, md, lt); blob(d, 16, 12, 8, dk, md, lt)
    else:
        dk, md, lt = (28, 78, 62), (44, 112, 76), (92, 158, 94)
        tiers = [[(25, 5, 7)], [(18, 4, 7), (24, 7, 8)], [(7, 4, 8), (13, 7, 9), (20, 10, 10)]][stage]
        for top, half, tall in reversed(tiers):
            d.polygon([(16, top), (16 - half, top + tall), (16 + half, top + tall)], fill=md)
            d.polygon([(16, top), (16 - half, top + tall), (14, top + tall)], fill=lt)
            d.line([(16 - half, top + tall), (16 + half, top + tall)], fill=dk)
            d.line([(16, top + 1), (16 + half - 1, top + tall - 1)], fill=dk)
    return outline(im)

def stump():
    im = Image.new("RGBA", (48, 32), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    d.polygon([(8, 28), (11, 12), (37, 12), (40, 28)], fill=(104, 62, 40))
    d.polygon([(8, 28), (11, 12), (18, 12), (16, 28)], fill=(134, 86, 52))
    for x in (14, 21, 27, 33):
        d.line([(x, 17), (x - 1, 27)], fill=(76, 44, 30))
    d.polygon([(2, 30), (10, 22), (14, 29)], fill=(116, 72, 44))
    d.polygon([(46, 30), (38, 22), (33, 29)], fill=(86, 52, 34))
    d.polygon([(19, 31), (23, 25), (29, 31)], fill=(100, 62, 40))
    d.ellipse([10, 4, 38, 19], fill=(104, 62, 40))
    d.ellipse([12, 5, 36, 17], fill=(188, 128, 76))
    d.ellipse([15, 7, 33, 15], outline=(142, 88, 52)); d.ellipse([20, 9, 28, 13], outline=(124, 74, 44))
    d.line([(24, 11), (34, 8)], fill=(92, 54, 34))                      # split
    for p in [(9, 20), (10, 19), (10, 20), (11, 19), (11, 20), (12, 21), (13, 6), (14, 6), (13, 7), (36, 25), (37, 25), (37, 24)]:
        d.point(p, fill=(104, 150, 62))                                  # moss
    return outline(im)

def log():
    im = Image.new("RGBA", (48, 32), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    d.rectangle([8, 13, 39, 28], fill=(104, 62, 40))
    d.rectangle([8, 13, 39, 17], fill=(142, 92, 56))
    d.rectangle([8, 25, 39, 28], fill=(76, 44, 30))
    for x0, y, x1 in [(11, 20, 19), (23, 22, 34), (15, 24, 22), (27, 18, 33)]:
        d.line([(x0, y), (x1, y)], fill=(72, 42, 28))
    d.polygon([(18, 13), (20, 6), (25, 7), (24, 13)], fill=(122, 78, 48))   # snapped branch
    d.ellipse([20, 5, 25, 8], fill=(188, 128, 76))
    d.ellipse([33, 13, 45, 28], fill=(104, 62, 40))
    d.ellipse([35, 15, 43, 26], fill=(188, 128, 76)); d.ellipse([37, 18, 41, 23], outline=(132, 80, 48))
    for x in range(9, 17):
        d.line([(x, 13), (x, 14 + (x * 3) % 3)], fill=(104, 150, 62))
    d.line([(10, 13), (14, 13)], fill=(150, 190, 82))
    return outline(im)

def main():
    sap = Image.new("RGBA", (96, 80), (0, 0, 0, 0))
    for row, kind in enumerate(["oak", "pine"]):
        for st in range(3):
            sap.paste(sapling(kind, st), (st * 32, row * 40))
    sap.save(os.path.join(ROOT, "assets", "sprites", "saplings.png"))
    big = Image.new("RGBA", (96, 32), (0, 0, 0, 0))
    big.paste(stump(), (0, 0)); big.paste(log(), (48, 0))
    big.save(os.path.join(ROOT, "assets", "sprites", "big_stump.png"))
    prev = Image.new("RGBA", (96, 112), (96, 160, 80, 255))
    prev.alpha_composite(sap, (0, 0)); prev.alpha_composite(big, (0, 80))
    prev.resize((576, 672), Image.NEAREST).save(os.environ.get("PREVIEW", "/tmp/forestry_preview.png"))
    print("wrote saplings.png + big_stump.png")

if __name__ == "__main__":
    main()
