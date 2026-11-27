#!/usr/bin/env python3
"""The Stone Warden's thrown boulder (original pixel art, CC0): 16 evenly turned frames of a round, cracked rock.
The surface turns clockwise frame by frame while the light stays top-left. Deterministic."""
import math
import os
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_PATH = os.path.join(ROOT, "assets", "sprites", "cave_boulder.png")
FRAMES, SIZE, R = 16, 24, 11.0
OUT = (30, 22, 22)
ROCK = [(52, 46, 46), (76, 68, 66), (104, 94, 88), (136, 124, 112), (170, 156, 140)]
CRACKS = [[(-8, -2), (-3, -1), (-1, 3), (2, 5)], [(-1, 3), (-5, 6)], [(2, -9), (3, -5), (7, -3)]]
PITS = [(4, 2, 1.6), (-4, -6, 1.3), (6, 6, 1.0), (-7, 3, 1.0)]
KNOBS = [(-2, -4, 2.6), (5, -1, 2.0), (-3, 6, 1.8)]


def seg_dist(px, py, a, b):
    ax, ay, bx, by = a[0], a[1], b[0], b[1]
    dx, dy = bx - ax, by - ay
    t = max(0.0, min(1.0, ((px - ax) * dx + (py - ay) * dy) / (dx * dx + dy * dy)))
    return math.hypot(px - ax - dx * t, py - ay - dy * t)


def edge(a):
    """Lumpy outline radius at surface angle a; it turns with the rock."""
    return R - 0.1 + 0.55 * math.sin(3 * a + 0.7) + 0.3 * math.sin(7 * a)


def pixel(x, y, turn):
    dx, dy = x + 0.5 - SIZE / 2, y + 0.5 - SIZE / 2
    d = math.hypot(dx, dy)
    a = math.atan2(dy, dx) - turn
    if d > edge(a):
        return None
    if d > edge(a) - 1.15:
        return OUT
    u, v = math.cos(a) * d, math.sin(a) * d          # surface coordinates
    nx, ny = dx / R, dy / R
    nz = math.sqrt(max(0.0, 1 - nx * nx - ny * ny))
    lit = max(0.0, -0.5 * nx - 0.6 * ny + 0.62 * nz)  # fixed light, top-left
    level = 0.4 + lit * 3.5
    for kx, ky, kr in KNOBS:
        if math.hypot(u - kx, v - ky) < kr:
            level += 0.9
    for px, py, pr in PITS:
        if math.hypot(u - px, v - py) < pr:
            level -= 1.3
    if any(seg_dist(u, v, c[i], c[i + 1]) < 0.65 for c in CRACKS for i in range(len(c) - 1)):
        level -= 2.0
    return ROCK[max(0, min(len(ROCK) - 1, int(round(level))))]


def main():
    sheet = Image.new("RGBA", (SIZE * FRAMES, SIZE), (0, 0, 0, 0))
    for f in range(FRAMES):
        for y in range(SIZE):
            for x in range(SIZE):
                c = pixel(x, y, math.tau * f / FRAMES)
                if c:
                    sheet.putpixel((f * SIZE + x, y), c + (255,))
    sheet.save(OUT_PATH)
    print("wrote cave_boulder.png", sheet.size)


if __name__ == "__main__":
    main()
