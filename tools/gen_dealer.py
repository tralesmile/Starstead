#!/usr/bin/env python3
"""Back-alley black-market dealer sprite (original, CC0). Deterministic.
dealer.png: 32x48, hooded dark-green coat, face in shadow with two pale eyes,
hands behind a small wooden crate stall. Light top-left, 1px dark outline."""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gen_interior import new, shade, box, shadow, save, OUT, WOOD, IRON  # noqa: E402

COAT = [(28, 52, 38), (42, 78, 54), (64, 110, 74), (92, 142, 98)]
SHADOW = (14, 20, 18)
EYE = (240, 244, 214)
SKIN = (196, 140, 112)
GOLD = (222, 190, 90)
LEATHER = [(94, 60, 34), (138, 90, 52), (176, 122, 72)]


def dealer():
    im, d = new(32, 48)
    shadow(d, 4, 46, 27)
    # coat body (behind the crate), slightly tapered
    d.polygon([(8, 20), (23, 20), (26, 38), (5, 38)], fill=COAT[1], outline=OUT)
    d.line([9, 21, 9, 36], fill=COAT[2])                      # lit left edge
    d.line([24, 24, 25, 37], fill=COAT[0])                    # shaded right edge
    d.line([16, 22, 16, 37], fill=COAT[0])                    # coat opening seam
    d.point([12, 24], fill=COAT[3])
    # belt and buckle
    d.line([7, 30, 24, 30], fill=LEATHER[0])
    d.rectangle([15, 29, 17, 31], fill=GOLD, outline=OUT)
    # shoulders / collar
    d.rounded_rectangle([6, 15, 25, 24], radius=3, fill=COAT[2], outline=OUT)
    d.line([8, 16, 14, 16], fill=COAT[3])
    d.line([8, 17, 8, 21], fill=COAT[3])
    d.line([22, 22, 24, 22], fill=COAT[1])
    # hood: big rounded shape over the head
    d.ellipse([7, 1, 24, 20], fill=COAT[1], outline=OUT)
    d.pieslice([8, 2, 23, 14], 180, 360, fill=COAT[2])
    d.line([11, 3, 17, 2], fill=COAT[3])                      # top-left highlight
    d.point([9, 7], fill=COAT[3])
    d.line([23, 9, 23, 15], fill=COAT[0])                     # shaded right rim
    # shadowed face opening
    d.ellipse([10, 7, 21, 18], fill=SHADOW, outline=OUT)
    d.rectangle([12, 15, 19, 17], fill=(24, 24, 24))
    d.point([15, 17], fill=SKIN)                              # hint of chin / nose
    d.point([16, 17], fill=shade(SKIN, 0.7))
    # two tiny pale eyes
    d.rectangle([12, 11, 13, 12], fill=EYE)
    d.rectangle([18, 11, 19, 12], fill=EYE)
    d.point([13, 12], fill=(120, 130, 110))
    d.point([19, 12], fill=(120, 130, 110))
    # hood fold hanging over the shoulders
    d.line([8, 19, 11, 20], fill=COAT[0])
    d.line([20, 20, 23, 19], fill=COAT[0])

    # crate stall in front: top surface + front face
    d.polygon([(2, 33), (29, 33), (31, 37), (0, 37)], fill=WOOD[3], outline=OUT)
    d.line([3, 34, 28, 34], fill=(210, 150, 92))
    box(d, 0, 37, 31, 46, WOOD[1], hi=WOOD[2], lo=WOOD[0])
    for x in (9, 22):                                         # vertical planks
        d.line([x, 38, x, 45], fill=WOOD[0])
    d.line([1, 41, 30, 41], fill=WOOD[0])                     # plank gap
    d.line([1, 42, 30, 42], fill=WOOD[2])
    for x, y in ((2, 39), (28, 39), (2, 44), (28, 44)):       # nails
        d.point([x, y], fill=IRON[3])
    # hands peeking over the back edge of the crate
    for x in (7, 22):
        d.ellipse([x, 31, x + 3, 34], fill=SKIN, outline=OUT)
        d.point([x + 1, 32], fill=(238, 188, 150))

    # shady goods on the crate top
    # lockpick roll (leather, with strap and picks sticking out)
    d.rectangle([4, 33, 11, 36], fill=LEATHER[1], outline=OUT)
    d.line([5, 34, 10, 34], fill=LEATHER[2])
    d.line([7, 33, 7, 36], fill=(216, 200, 160))              # strap
    d.line([5, 31, 5, 32], fill=IRON[3])                      # picks poking out
    d.line([9, 30, 9, 32], fill=(200, 210, 222))
    d.point([10, 30], fill=(240, 244, 250))
    # coin
    d.ellipse([22, 34, 26, 36], fill=GOLD, outline=OUT)
    d.point([23, 34], fill=(255, 240, 160))
    # second stacked coin, offset
    d.ellipse([25, 33, 28, 35], fill=GOLD, outline=OUT)
    d.point([26, 33], fill=(255, 240, 160))
    # small vial
    d.rectangle([15, 33, 17, 36], fill=(120, 200, 120), outline=OUT)
    d.point([16, 33], fill=(210, 240, 200))
    save(im, "dealer.png")


def main():
    os.makedirs(os.path.dirname(os.path.join(os.path.dirname(__file__), "..", "assets", "sprites")), exist_ok=True)
    dealer()


if __name__ == "__main__":
    main()
