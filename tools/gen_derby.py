#!/usr/bin/env python3
"""Derby racer sprite sheet + finish post (original, CC0). Deterministic.
derby_racer.png: 192x32, 4 frames of 48x32, side view facing right, galloping
horse (neutral light-grey coat) with jockey; cap+silks pure red (200,40,40) so
the game can tint via modulate. derby_finish.png: 16x64 chequered post strip.
1px dark outline, light from top-left."""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gen_interior import new, shade, save, OUT  # noqa: E402

COAT = [(150, 150, 156), (190, 190, 196), (222, 222, 228), (244, 244, 248)]
MANE = (96, 96, 106)
HOOF = (70, 66, 70)
SILK = (200, 40, 40)
SKIN = (222, 170, 140)
BOOT = (60, 44, 36)

# leg poses: (hip_dx, knee_dx, foot_dx, knee_y, foot_y) relative to hip x; hip y = 19
# frames: 0 extended, 1 gathered, 2 extended other way, 3 gathered
FRONT = [((0, 5, 9, 22, 27), (-1, 3, 7, 22, 26)),
         ((0, 3, 1, 23, 25), (-1, 2, 0, 23, 24)),
         ((0, -3, -5, 22, 27), (-1, -2, -3, 22, 26)),
         ((0, 4, 2, 23, 25), (-1, 3, 1, 23, 24))]
HIND = [((0, -5, -10, 22, 27), (1, -4, -8, 22, 26)),
        ((0, -2, 0, 23, 25), (1, -1, 1, 23, 24)),
        ((0, 5, 4, 22, 27), (1, 5, 3, 22, 26)),
        ((0, 1, -3, 23, 25), (1, 0, -4, 23, 24))]


def leg(d, x, pose, col, hoof):
    hx, kx, fx, ky, fy = pose
    pts = [(x + hx, 18), (x + kx, ky), (x + fx, fy)]
    d.line(pts, fill=OUT, width=3)
    d.line(pts, fill=col, width=1)
    d.point([x + fx, fy], fill=hoof)


def frame(i):
    im, d = new(48, 32)
    d.line([14, 30, 36, 30], fill=(42, 26, 16, 60))                 # ground shadow
    # far legs (darker), then body, then near legs
    leg(d, 30, FRONT[i][1], COAT[0], HOOF)
    leg(d, 16, HIND[i][1], COAT[0], HOOF)
    # tail streaming back
    d.polygon([(13, 10), (6, 11), (2, 15), (7, 14), (12, 14)], fill=MANE, outline=OUT)
    d.line([6, 12, 11, 11], fill=shade(MANE, 1.3))
    # neck + head (up and right)
    d.polygon([(30, 9), (35, 4), (39, 6), (36, 15), (31, 17)], fill=COAT[1], outline=OUT)
    d.polygon([(37, 4), (45, 8), (46, 12), (43, 13), (38, 9)], fill=COAT[1], outline=OUT)
    d.line([38, 5, 43, 8], fill=COAT[3])
    d.point([44, 11], fill=COAT[0]); d.point([45, 10], fill=OUT)    # muzzle/nostril
    d.point([41, 8], fill=OUT)                                      # eye
    d.polygon([(36, 4), (37, 1), (39, 4)], fill=COAT[1], outline=OUT)  # ear
    d.line([33, 6, 36, 10], fill=MANE)                              # mane
    d.line([32, 8, 34, 12], fill=MANE)
    # barrel body
    d.ellipse([11, 8, 34, 20], fill=COAT[2], outline=OUT)
    d.line([14, 10, 28, 9], fill=COAT[3])                           # top-left light
    d.line([15, 18, 31, 19], fill=COAT[1])                          # belly shade
    d.line([32, 12, 32, 17], fill=COAT[1])                          # shoulder line
    # near legs
    leg(d, 31, FRONT[i][0], COAT[2], HOOF)
    leg(d, 15, HIND[i][0], COAT[2], HOOF)
    # saddle cloth
    d.rectangle([20, 8, 25, 12], fill=SILK, outline=OUT)
    # jockey: crouched, leaning forward
    d.polygon([(19, 8), (24, 3), (30, 4), (28, 9), (22, 10)], fill=SILK, outline=OUT)
    d.line([22, 5, 26, 4], fill=shade(SILK, 1.3))                   # lit back
    d.line([27, 8, 31, 11], fill=OUT)                               # arm to reins
    d.line([28, 8, 30, 10], fill=SKIN)
    d.rectangle([21, 10, 24, 12], fill=BOOT, outline=OUT)           # boot
    d.ellipse([28, 0, 32, 4], fill=SKIN, outline=OUT)               # head
    d.pieslice([27, -1, 33, 5], 180, 360, fill=SILK, outline=OUT)   # cap
    d.line([31, 2, 33, 2], fill=SILK)                               # peak
    d.point([28, 0], fill=shade(SILK, 1.3))
    d.line([31, 9, 38, 7], fill=(90, 60, 40))                       # reins
    return im


def racer():
    sheet, _ = new(192, 32)
    for i in range(4):
        sheet.paste(frame(i), (i * 48, 0))
    save(sheet, "derby_racer.png")


def finish():
    im, d = new(16, 64)
    for y in range(16):
        for x in range(4):
            c = (250, 250, 250) if (x + y) % 2 == 0 else (16, 16, 16)
            d.rectangle([x * 4, y * 4, x * 4 + 3, y * 4 + 3], fill=c)
    save(im, "derby_finish.png")


def main():
    racer()
    finish()


if __name__ == "__main__":
    main()
