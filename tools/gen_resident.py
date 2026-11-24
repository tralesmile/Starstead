#!/usr/bin/env python3
"""Sleeping resident sprites (original, CC0). Deterministic.
int_sleeper.png: 8 frames of 32x64 (same footprint/anchor as int_bed, drawn on top of it),
variant-major: 4 variants (blanket blue/green/red-brown/mustard, hair dark/blond/grey/ginger)
x 2 breathing frames (blanket rises 1px). zzz.png: 3 frames of 16x16 'z' (small, medium, large)."""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gen_interior import new, shade, OUT, SPR  # noqa: E402
from PIL import Image  # noqa: E402

SKIN = [(196, 140, 112), (238, 188, 150), (252, 214, 176)]
VARIANTS = [
    # blanket (dark, mid, light), hair (dark, mid, light)
    ([(52, 78, 118), (76, 108, 150), (110, 144, 184)], [(24, 18, 22), (46, 36, 40), (82, 66, 70)]),
    ([(60, 90, 52), (90, 128, 70), (130, 164, 96)], [(176, 136, 52), (222, 188, 96), (248, 228, 150)]),
    ([(110, 48, 36), (146, 72, 52), (180, 100, 74)], [(150, 150, 158), (200, 200, 208), (240, 240, 246)]),
    ([(168, 126, 28), (214, 170, 52), (240, 208, 96)], [(142, 62, 30), (196, 98, 44), (232, 140, 72)]),
]


def sleeper(blanket, hair, lift):
    im, d = new(32, 64)
    # head on the pillow (pillow spans x6-25, y15-25)
    d.ellipse([10, 15, 21, 27], fill=SKIN[1], outline=OUT)
    d.line([13, 24, 18, 24], fill=SKIN[0])                    # chin shade
    d.point([12, 22], fill=(226, 130, 120))                   # cheeks
    d.point([19, 22], fill=(226, 130, 120))
    d.line([12, 21, 14, 21], fill=OUT)                        # closed eyes
    d.line([17, 21, 19, 21], fill=OUT)
    d.point([16, 23], fill=SKIN[0])                           # nose hint
    # hair cap over the top of the head
    d.pieslice([10, 15, 21, 26], 180, 360, fill=hair[1], outline=OUT)
    d.rectangle([11, 18, 20, 19], fill=hair[1])
    d.point([11, 20], fill=hair[1])
    d.point([20, 20], fill=hair[1])
    d.line([12, 17, 16, 16], fill=hair[2])
    d.point([13, 18], fill=hair[2])
    d.line([15, 19, 17, 19], fill=hair[0])
    # blanket body: shoulders, then legs, then feet (all inside the sheet x3-28)
    top = 27 - lift
    d.rounded_rectangle([3, top, 28, 55], radius=3, fill=blanket[1], outline=OUT)
    d.rectangle([5, top + 1, 26, top + 4], fill=(240, 232, 214))      # folded sheet edge
    d.line([5, top + 5, 26, top + 5], fill=OUT)
    d.line([5, top + 1, 26, top + 1], fill=(255, 250, 238))
    d.line([4, top + 6, 4, 53], fill=blanket[2])
    d.line([5, top + 6, 26, top + 6], fill=blanket[2])
    d.line([27, top + 6, 27, 54], fill=blanket[0])
    d.line([5, 54, 26, 54], fill=blanket[0])
    # shoulder bumps and leg mound shading
    d.line([8, top + 8, 11, top + 8], fill=blanket[2])
    d.line([20, top + 8, 23, top + 8], fill=blanket[0])
    d.line([16, 40, 16, 52], fill=blanket[0])                 # fold between legs
    d.line([11, 44, 14, 44], fill=blanket[2])
    d.line([18, 47, 21, 47], fill=blanket[2])
    for y in (49,):                                           # quilt stripe
        d.line([5, y, 26, y], fill=blanket[2])
        d.line([5, y + 1, 26, y + 1], fill=blanket[0])
    # a hand resting on the blanket edge
    d.ellipse([20, top + 7, 23, top + 10], fill=SKIN[1], outline=OUT)
    return im


def make_sleeper():
    strip = Image.new("RGBA", (32 * 8, 64), (0, 0, 0, 0))
    i = 0
    for blanket, hair in VARIANTS:
        for lift in (0, 1):
            strip.paste(sleeper(blanket, hair, lift), (i * 32, 0))
            i += 1
    strip.save(os.path.join(SPR, "int_sleeper.png"))
    print("wrote int_sleeper.png")


# 'z' glyph bitmaps drawn as a thick diagonal letter; scale = stroke size
def zglyph(size, x0, y0):
    """Returns pixel list for a z of given size (width) at x0,y0."""
    pts = []
    for x in range(size):
        pts.append((x, 0))
        pts.append((x, size - 1))
    for i in range(size):
        pts.append((size - 1 - i, i))
    return [(x0 + x, y0 + y) for x, y in pts]


def make_zzz():
    strip = Image.new("RGBA", (48, 16), (0, 0, 0, 0))
    fill = (228, 240, 255, 255)
    light = (255, 255, 255, 255)
    for f, (size, th) in enumerate(((5, 1), (7, 1), (9, 2))):
        fr = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
        ox = (16 - size) // 2
        oy = (16 - size) // 2
        body = set()
        for x, y in zglyph(size, ox, oy):
            for t in range(th):
                body.add((x, y + t if y == oy + size - 1 else y))
                if th > 1 and y != oy and y != oy + size - 1:
                    body.add((x + 1, y))
        if th > 1:
            for x in range(size):
                body.add((ox + x, oy + 1))
                body.add((ox + x, oy + size - 2))
        px = fr.load()
        for (x, y) in body:
            for dx in (-1, 0, 1):
                for dy in (-1, 0, 1):
                    if 0 <= x + dx < 16 and 0 <= y + dy < 16 and (x + dx, y + dy) not in body:
                        px[x + dx, y + dy] = OUT + (255,)
        for (x, y) in body:
            px[x, y] = fill
        for x in range(size):
            if (ox + x, oy) in body:
                px[ox + x, oy] = light
        strip.paste(fr, (f * 16, 0))
    strip.save(os.path.join(SPR, "zzz.png"))
    print("wrote zzz.png")


def main():
    os.makedirs(SPR, exist_ok=True)
    make_sleeper()
    make_zzz()


if __name__ == "__main__":
    main()
