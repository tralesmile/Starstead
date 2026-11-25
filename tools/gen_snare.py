#!/usr/bin/env python3
"""Snare trap world sprite sheet 64x32: frame 0 set, frame 1 sprung with a rabbit (original, CC0). Deterministic."""
import os
from PIL import Image, ImageDraw
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = (42, 26, 16)
WIRE = (196, 204, 216); WIRE_HI = (240, 244, 250)
CORD = (216, 200, 160)

def base(d):
    d.ellipse([3, 24, 28, 31], fill=(20, 30, 14, 90))                      # shadow
    d.ellipse([2, 21, 29, 30], fill=(86, 142, 62), outline=(52, 96, 40))   # grass patch
    d.ellipse([5, 22, 20, 27], fill=(112, 172, 80))                        # light top-left
    for x, y in ((5, 26), (9, 29), (21, 28), (26, 25), (14, 22)):          # blades
        d.line([(x, y), (x - 1, y - 3)], fill=(130, 190, 90)); d.point((x + 1, y - 2), fill=(60, 110, 44))

def stake(d, x, top, light, dark):
    d.rectangle([x, top, x + 2, 27], fill=light, outline=OUT)
    d.line([(x + 1, top + 1), (x + 1, 26)], fill=(200, 150, 96))
    d.point((x + 2, top + 1), fill=dark)

def frame_set():
    im = Image.new("RGBA", (32, 32), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    base(d)
    # bent sapling arm: springs from right stake up and over, tied to cord
    d.line([(24, 22), (27, 14), (26, 7), (21, 3), (14, 3)], fill=OUT, width=3)
    d.line([(24, 22), (27, 14), (26, 7), (21, 3), (14, 3)], fill=(120, 150, 70), width=1)
    d.line([(24, 20), (26, 13)], fill=(150, 184, 92))
    d.point((15, 3), fill=(168, 200, 104))
    d.line([(14, 4), (14, 8)], fill=CORD)                                  # trigger line down
    stake(d, 5, 12, (138, 90, 52), (100, 62, 36))                           # left stake
    stake(d, 22, 17, (118, 76, 44), (84, 52, 30))                           # right stake
    d.line([(8, 14), (23, 19)], fill=CORD)                                  # rope between stakes (top)
    d.ellipse([10, 15, 21, 25], outline=OUT)                                # noose outline
    d.ellipse([11, 16, 20, 24], outline=WIRE)                               # twig/wire loop
    d.arc([11, 16, 20, 24], 180, 270, fill=WIRE_HI)
    d.rectangle([13, 12, 15, 15], fill=(180, 130, 80), outline=OUT)         # trigger twig
    d.point((14, 13), fill=(220, 176, 120))
    d.line([(14, 8), (14, 12)], fill=CORD)
    return im

def frame_sprung():
    im = Image.new("RGBA", (32, 32), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    base(d)
    # sapling sprung upright, carrying the cord
    d.line([(24, 22), (25, 14), (22, 6), (18, 1)], fill=OUT, width=3)
    d.line([(24, 22), (25, 14), (22, 6), (18, 1)], fill=(120, 150, 70), width=1)
    d.line([(24, 20), (25, 14)], fill=(150, 184, 92))
    stake(d, 5, 17, (138, 90, 52), (100, 62, 36))
    stake(d, 22, 20, (118, 76, 44), (84, 52, 30))
    d.line([(18, 2), (17, 13)], fill=CORD)                                  # taut line up
    # rabbit bundle, brown fur
    FUR = (150, 104, 62); FUR_L = (196, 148, 96); FUR_D = (108, 70, 40)
    d.ellipse([7, 14, 22, 27], fill=FUR, outline=OUT)                       # body
    d.ellipse([9, 16, 16, 22], fill=FUR_L)                                  # light top-left
    d.arc([8, 15, 21, 26], 20, 120, fill=FUR_D)
    d.ellipse([3, 18, 11, 25], fill=FUR, outline=OUT)                       # head
    d.ellipse([4, 19, 8, 22], fill=FUR_L)
    d.polygon([(4, 19), (2, 11), (5, 10), (7, 18)], fill=FUR, outline=OUT)  # ears, one up
    d.line([(4, 17), (4, 12)], fill=(232, 170, 160))
    d.polygon([(7, 18), (9, 12), (12, 12), (10, 19)], fill=FUR_D, outline=OUT)  # ear flopped
    d.point((5, 21), fill=OUT); d.point((4, 24), fill=(230, 160, 150))      # eye, nose
    d.ellipse([19, 19, 24, 25], fill=(236, 226, 206), outline=OUT)          # white tail
    d.ellipse([12, 24, 18, 28], fill=FUR_D, outline=OUT)                    # hind foot
    d.line([(10, 24), (17, 17)], fill=WIRE)                                 # noose around neck/body
    d.point((10, 24), fill=WIRE_HI)
    return im

sheet = Image.new("RGBA", (64, 32), (0, 0, 0, 0))
sheet.paste(frame_set(), (0, 0)); sheet.paste(frame_sprung(), (32, 0))
sheet.save(os.path.join(ROOT, "assets", "sprites", "snare.png")); print("wrote snare.png")
