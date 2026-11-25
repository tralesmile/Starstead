#!/usr/bin/env python3
"""Dock props sheet 320x32 (10 frames of 32x32, original, CC0). Deterministic.
0 barrel, 1 two stacked crates, 2 coiled rope, 3 fish drying rack, 4 fisherman's basket, 5 net on stakes, 6 mooring bollard, 7 lobster pots, 8 gull on barrel, 9 bollard lamp."""
import os
from PIL import Image, ImageDraw
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = (42, 26, 16)
WOOD = [(110, 70, 38), (138, 90, 52), (166, 112, 63), (190, 132, 76)]
IRON = [(52, 48, 52), (84, 80, 86), (122, 118, 124), (160, 156, 160)]
ROPE = [(150, 118, 70), (200, 168, 108), (232, 208, 150)]
FISH = [(120, 144, 164), (170, 196, 212), (232, 244, 250)]

def new():
    im = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    return im, d

def shadow(im, x0=4, x1=28):
    ov = Image.new("RGBA", (32, 32), (0, 0, 0, 0)); od = ImageDraw.Draw(ov)
    od.ellipse([x0, 26, x1, 31], fill=(30, 20, 12, 80))
    od.ellipse([x0 + 3, 27, x1 - 3, 30], fill=(30, 20, 12, 40))
    im.alpha_composite(ov)

def barrel():
    im, d = new(); shadow(im, 5, 27); d = ImageDraw.Draw(im)
    d.ellipse([6, 24, 26, 30], fill=WOOD[0], outline=OUT)
    d.rectangle([6, 8, 26, 27], fill=WOOD[1])
    d.ellipse([5, 14, 27, 29], fill=WOOD[1]) if False else None
    d.line([6, 8, 6, 27], fill=OUT); d.line([26, 8, 26, 27], fill=OUT)
    d.line([7, 9, 7, 26], fill=WOOD[3]); d.line([9, 9, 9, 26], fill=WOOD[2])
    d.line([23, 9, 23, 26], fill=WOOD[0]); d.line([25, 9, 25, 26], fill=WOOD[0])
    for x in (13, 17, 20):
        d.line([x, 9, x, 26], fill=WOOD[0])
    d.arc([6, 22, 26, 31], 0, 180, fill=OUT)
    for y in (12, 23):
        d.rectangle([6, y, 26, y + 1], fill=IRON[1]); d.line([7, y, 24, y], fill=IRON[3]); d.line([6, y + 2, 26, y + 2], fill=OUT) if False else None
    d.ellipse([6, 4, 26, 12], fill=WOOD[3], outline=OUT)
    d.ellipse([8, 5, 24, 11], fill=WOOD[2])
    d.arc([11, 6, 21, 10], 0, 360, fill=WOOD[1])
    d.ellipse([9, 5, 14, 8], fill=WOOD[3])
    return im

def crate_box(d, x0, y0, x1, y1):
    d.rectangle([x0, y0, x1, y1], fill=WOOD[2], outline=OUT)
    d.line([x0 + 1, y0 + 1, x1 - 1, y0 + 1], fill=WOOD[3])
    d.line([x0 + 1, y1 - 1, x1 - 1, y1 - 1], fill=WOOD[0])
    d.line([x1 - 1, y0 + 2, x1 - 1, y1 - 2], fill=WOOD[0])
    mid = (y0 + y1) // 2
    d.line([x0 + 1, mid, x1 - 1, mid], fill=WOOD[0])
    for x in (x0 + 1, x1 - 3):
        d.rectangle([x, y0 + 1, x + 1, y1 - 1], fill=WOOD[1])
    d.line([x0 + 2, y0 + 2, x1 - 2, y1 - 2], fill=WOOD[1]) if False else None
    d.point([x0 + 2, y0 + 2], fill=IRON[3]); d.point([x1 - 2, y1 - 2], fill=IRON[3])

def crates():
    im, d = new(); shadow(im, 3, 29); d = ImageDraw.Draw(im)
    crate_box(d, 4, 16, 27, 29)
    crate_box(d, 8, 3, 23, 15)
    d.line([6, 20, 25, 20], fill=WOOD[0])
    return im

def rope():
    im, d = new(); shadow(im, 5, 27); d = ImageDraw.Draw(im)
    for k, (y, rx) in enumerate(((22, 11), (18, 10), (14, 8))):   # stacked coils
        d.ellipse([16 - rx - 1, y - 4, 16 + rx + 1, y + 6], fill=ROPE[0], outline=OUT)
        d.ellipse([16 - rx + 1, y - 3, 16 + rx - 1, y + 4], fill=ROPE[1])
        d.ellipse([16 - rx + 4, y - 1, 16 + rx - 4, y + 3], fill=ROPE[0], outline=OUT)
    d.arc([7, 11, 25, 21], 190, 330, fill=ROPE[2])
    for x, y in ((9, 22), (13, 25), (21, 24), (25, 21), (12, 14), (20, 15)):
        d.point([x, y], fill=ROPE[0]); d.point([x + 1, y - 1], fill=ROPE[2])
    d.line([21, 19, 27, 26], fill=OUT); d.line([22, 19, 28, 26], fill=ROPE[1])   # loose tail
    d.point([28, 27], fill=OUT); d.point([27, 27], fill=ROPE[0])
    return im

def fish_hang(d, x, y):
    d.line([x, y, x, y + 2], fill=OUT)
    d.ellipse([x - 3, y + 2, x + 3, y + 12], fill=FISH[1], outline=OUT)
    d.line([x - 1, y + 4, x - 1, y + 10], fill=FISH[2])
    d.line([x + 2, y + 5, x + 2, y + 10], fill=FISH[0])
    d.point([x, y + 4], fill=OUT)                       # eye
    d.line([x - 2, y + 7, x + 1, y + 7], fill=FISH[0])  # gill line
    d.polygon([(x, y + 12), (x - 4, y + 16), (x + 4, y + 16)], fill=FISH[0], outline=OUT)   # tail
    d.point([x, y + 14], fill=FISH[1])

def fish_rack():
    im, d = new(); shadow(im, 3, 29); d = ImageDraw.Draw(im)
    for x in (4, 26):
        d.rectangle([x, 6, x + 2, 30], fill=WOOD[1], outline=OUT)
        d.line([x + 1, 7, x + 1, 29], fill=WOOD[3])
    d.rectangle([3, 5, 29, 8], fill=WOOD[2], outline=OUT)
    d.line([4, 6, 28, 6], fill=WOOD[3])
    fish_hang(d, 11, 9); fish_hang(d, 20, 9)
    return im

def basket():
    im, d = new(); shadow(im, 5, 27); d = ImageDraw.Draw(im)
    CANE = [(124, 88, 44), (180, 138, 72), (214, 176, 100)]
    # fish tail sticking out the top
    d.polygon([(17, 14), (21, 14), (24, 6), (19, 8), (14, 5)], fill=FISH[0], outline=OUT)
    d.polygon([(16, 14), (20, 14), (21, 9), (18, 9)], fill=FISH[1])
    d.line([18, 9, 18, 13], fill=FISH[2])
    d.polygon([(8, 15), (24, 15), (26, 29), (6, 29)], fill=CANE[1], outline=OUT)
    for y in (18, 22, 26):
        d.line([8, y, 25, y], fill=CANE[0])
    for x in range(10, 25, 4):
        d.line([x, 16, x + 1, 28], fill=CANE[0])
    d.line([8, 16, 7, 28], fill=CANE[2])
    d.ellipse([6, 12, 26, 18], fill=CANE[2], outline=OUT)
    d.ellipse([8, 13, 24, 17], fill=CANE[0])
    d.polygon([(15, 14), (19, 14), (20, 12), (14, 12)], fill=FISH[1])
    d.line([15, 13, 18, 13], fill=FISH[2])
    d.arc([8, 6, 24, 22], 200, 340, fill=OUT)        # carry handle
    d.point([6, 22], fill=CANE[2])
    return im

def net_stakes():
    im, d = new(); shadow(im, 2, 30); d = ImageDraw.Draw(im)
    NET = (212, 196, 150); NET_D = (140, 120, 80)
    pts = [(5, 8), (27, 8)]
    # net sagging between the stakes, with a mesh
    d.polygon([(5, 9), (27, 9), (28, 25), (22, 28), (10, 28), (4, 25)], fill=(150, 130, 90, 120), outline=None)
    for k in range(-14, 30, 4):
        d.line([k, 9, k + 14, 28], fill=NET_D)
        d.line([k + 14, 9, k, 28], fill=NET)
    mask = Image.new("L", (32, 32), 0); md = ImageDraw.Draw(mask)
    md.polygon([(5, 9), (27, 9), (28, 25), (22, 28), (10, 28), (4, 25)], fill=255)
    net = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    net.paste(im, (0, 0), mask)
    im2 = Image.new("RGBA", (32, 32), (0, 0, 0, 0)); shadow(im2, 2, 30); im2.alpha_composite(net)
    d = ImageDraw.Draw(im2)
    d.line([5, 9, 4, 25], fill=OUT); d.line([27, 9, 28, 25], fill=OUT)
    d.line([4, 25, 10, 28], fill=OUT); d.line([10, 28, 22, 28], fill=OUT); d.line([22, 28, 28, 25], fill=OUT)
    d.line([5, 9, 27, 9], fill=OUT)
    for x in (3, 26):
        d.rectangle([x, 2, x + 2, 30], fill=WOOD[1], outline=OUT)
        d.line([x + 1, 3, x + 1, 29], fill=WOOD[3])
    d.line([5, 10, 26, 10], fill=ROPE[1])
    for x, y in ((9, 27), (15, 28), (21, 27)):
        d.point([x, y], fill=IRON[2])                       # sinkers
    return im2

def bollard():
    im, d = new(); shadow(im, 6, 26); d = ImageDraw.Draw(im)
    d.ellipse([8, 24, 24, 30], fill=IRON[1], outline=OUT)
    d.rectangle([11, 10, 21, 26], fill=IRON[1])
    d.line([11, 10, 11, 26], fill=OUT); d.line([21, 10, 21, 26], fill=OUT)
    d.line([12, 11, 12, 25], fill=IRON[3]); d.line([13, 11, 13, 25], fill=IRON[2])
    d.line([19, 11, 19, 25], fill=IRON[0]); d.line([20, 11, 20, 25], fill=IRON[0])
    d.arc([8, 22, 24, 30], 0, 180, fill=OUT)
    d.ellipse([9, 5, 23, 12], fill=IRON[2], outline=OUT)      # cap
    d.ellipse([11, 6, 19, 10], fill=IRON[3])
    # rope loop around the neck
    d.ellipse([8, 13, 24, 20], outline=OUT, width=3)
    d.ellipse([9, 14, 23, 19], outline=ROPE[1], width=1)
    d.line([10, 15, 14, 14], fill=ROPE[2])
    d.line([22, 18, 27, 24], fill=OUT); d.line([23, 18, 28, 24], fill=ROPE[1])   # hanging tail
    d.point([28, 25], fill=OUT); d.point([27, 25], fill=ROPE[0])
    return im

def lobster_pots():
    im, d = new(); shadow(im, 3, 29); d = ImageDraw.Draw(im)
    CANE = [(124, 88, 44), (180, 138, 72), (214, 176, 100)]
    def pot(x0, y0, x1, y1):
        d.rectangle([x0, y0, x1, y1], fill=CANE[1], outline=OUT)
        d.line([x0 + 1, y0 + 1, x1 - 1, y0 + 1], fill=CANE[2])
        for x in range(x0 + 3, x1, 4):
            d.line([x, y0 + 2, x, y1 - 1], fill=CANE[0])
        for y in range(y0 + 4, y1, 4):
            d.line([x0 + 1, y, x1 - 1, y], fill=CANE[0])
        d.rectangle([x0 + 1, y1 - 1, x1 - 1, y1 - 1], fill=WOOD[0])
        d.arc([x0 + 3, y0 + 3, x0 + 9, y0 + 9], 0, 360, fill=OUT)
    pot(3, 17, 18, 29)
    pot(14, 18, 29, 30)
    pot(8, 5, 23, 17)
    d.line([24, 8, 29, 14], fill=OUT); d.line([25, 8, 30, 14], fill=ROPE[1])   # float line
    d.ellipse([26, 3, 31, 8], fill=(200, 70, 50), outline=OUT); d.point([27, 4], fill=(240, 150, 120))
    return im

def gull_barrel():
    im = barrel(); d = ImageDraw.Draw(im)
    W = (238, 238, 232); G = (170, 176, 184); B = (236, 170, 50)
    d.ellipse([11, 0, 21, 8], fill=W, outline=OUT)        # body on the lid
    d.ellipse([17, -1, 22, 4], fill=W, outline=OUT) if False else None
    d.rectangle([12, 2, 17, 6], fill=W)
    d.line([12, 2, 16, 2], fill=(255, 255, 255))
    d.polygon([(10, 3), (15, 7), (19, 5), (12, 1)], fill=G, outline=OUT)   # folded wing
    d.rectangle([18, 0, 21, 3], fill=W, outline=OUT)      # head
    d.point([20, 1], fill=OUT)
    d.polygon([(22, 1), (25, 2), (22, 3)], fill=B, outline=OUT)    # beak
    d.line([14, 7, 14, 8], fill=B); d.line([17, 7, 17, 8], fill=B)
    return im

def bollard_lamp():
    im, d = new(); shadow(im, 8, 24); d = ImageDraw.Draw(im)
    d.ellipse([10, 25, 22, 30], fill=IRON[1], outline=OUT)
    d.rectangle([14, 10, 18, 27], fill=IRON[1], outline=OUT)
    d.line([15, 11, 15, 26], fill=IRON[3]); d.line([17, 11, 17, 26], fill=IRON[0])
    d.rectangle([11, 8, 21, 11], fill=IRON[2], outline=OUT)
    d.rectangle([12, 0, 20, 8], fill=(255, 214, 120), outline=OUT)      # glass
    d.rectangle([13, 1, 15, 7], fill=(255, 244, 190))
    d.line([18, 2, 18, 7], fill=(236, 170, 50)); d.line([14, 4, 18, 4], fill=OUT) if False else None
    d.polygon([(10, 1), (22, 1), (19, -1), (13, -1)], fill=IRON[0], outline=OUT) if False else None
    d.line([11, 0, 21, 0], fill=OUT)
    return im

def main():
    frames = [barrel(), crates(), rope(), fish_rack(), basket(), net_stakes(), bollard(), lobster_pots(), gull_barrel(), bollard_lamp()]
    sheet = Image.new("RGBA", (32 * len(frames), 32), (0, 0, 0, 0))
    for i, f in enumerate(frames):
        sheet.paste(f, (i * 32, 0))
    sheet.save(os.path.join(ROOT, "assets", "sprites", "dock_props.png"))
    print("wrote dock_props.png", sheet.size)

if __name__ == "__main__":
    main()
