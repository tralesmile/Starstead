#!/usr/bin/env python3
"""Generates placeholder 32x32 pixel art (CC0, original) into assets/. Run: python3 tools/gen_art.py"""
import random, os
from PIL import Image
T = 32
def rng(seed): return random.Random(seed)
def save(img, path):
    os.makedirs(os.path.dirname(path), exist_ok=True); img.save(path)

def speckle(base, shades, n, seed, size=(T, T)):
    r = rng(seed); im = Image.new("RGBA", size, base)
    for _ in range(n):
        x, y = r.randrange(size[0]), r.randrange(size[1])
        im.putpixel((x, y), r.choice(shades))
    return im

def grass(i):
    im = speckle((74, 140, 62, 255), [(60, 120, 52, 255), (92, 160, 72, 255), (50, 104, 48, 255)], 90, i)
    r = rng(100 + i)
    for _ in range(6):  # blades
        x, y = r.randrange(1, T - 1), r.randrange(2, T)
        im.putpixel((x, y), (110, 178, 84, 255)); im.putpixel((x, y - 1), (110, 178, 84, 255))
    return im
def dirt(i):
    return speckle((133, 96, 64, 255), [(112, 78, 50, 255), (150, 112, 76, 255), (98, 68, 44, 255)], 110, 50 + i)
def path(i):
    im = speckle((190, 164, 118, 255), [(170, 144, 100, 255), (206, 182, 136, 255), (150, 128, 90, 255)], 80, 70 + i)
    return im
def water(depth):
    base = [(70, 150, 190, 255), (30, 90, 140, 255)][depth]
    lite = [(110, 190, 220, 255), (50, 120, 170, 255)][depth]
    im = speckle(base, [lite], 20, 200 + depth)
    for x in range(4, 28, 8):
        y = 8 + 12 * (x % 3 == 0)
        for dx in range(4): im.putpixel((x + dx, y % T), lite)
    return im
def tree():
    im = Image.new("RGBA", (64, 96), (0, 0, 0, 0)); r = rng(7)
    for y in range(60, 92):
        for x in range(26, 38): im.putpixel((x, y), (96, 64, 40, 255) if x < 33 else (74, 48, 30, 255))
    for cy, rad in ((34, 28), (22, 22), (46, 24)):
        for y in range(96):
            for x in range(64):
                if (x - 32) ** 2 + (y - cy) ** 2 < rad ** 2:
                    c = r.choice([(30, 92, 56, 255), (38, 108, 64, 255), (24, 78, 50, 255)])
                    if y < cy - rad // 3: c = (46, 124, 72, 255)
                    im.putpixel((x, y), c)
    return im
def rock():
    im = Image.new("RGBA", (T, T), (0, 0, 0, 0)); r = rng(9)
    for y in range(T):
        for x in range(T):
            if ((x - 16) / 13) ** 2 + ((y - 20) / 9) ** 2 < 1:
                im.putpixel((x, y), r.choice([(128, 128, 134, 255), (110, 110, 118, 255), (146, 146, 152, 255)]) if y < 20 else (88, 88, 96, 255))
    return im
def player(frame_dir):
    # 4 dirs x 3 frames sheet, each 32x32 (chunky placeholder)
    sheet = Image.new("RGBA", (T * 3, T * 4), (0, 0, 0, 0))
    skin, shirt, pants, hair = (240, 196, 150, 255), (70, 110, 200, 255), (60, 60, 90, 255), (90, 56, 30, 255)
    for d in range(4):
        for f in range(3):
            ox, oy = f * T, d * T
            bob = 1 if f == 1 else 0
            def px(x0, y0, x1, y1, c):
                for y in range(y0, y1):
                    for x in range(x0, x1): sheet.putpixel((ox + x, oy + y), c)
            px(11, 20 - bob, 21, 26 - bob, shirt)
            leg = [0, -1, 1][f]
            px(12, 26, 16, 30 + (1 if leg > 0 else 0), pants); px(16, 26, 20, 30 + (1 if leg < 0 else 0), pants)
            px(11, 9 - bob, 21, 20 - bob, skin)
            px(10, 7 - bob, 22, 12 - bob, hair)
            if d == 0: px(12, 14 - bob, 14, 16 - bob, (30, 30, 30, 255)); px(18, 14 - bob, 20, 16 - bob, (30, 30, 30, 255))  # down: eyes
            if d == 2: px(10, 12 - bob, 22, 18 - bob, hair)  # up: back of head
            if d == 1: px(11, 14 - bob, 13, 16 - bob, (30, 30, 30, 255))  # left
            if d == 3: px(19, 14 - bob, 21, 16 - bob, (30, 30, 30, 255))  # right
    return sheet

for i in range(3): save(grass(i), f"assets/tiles/grass_{i}.png"); save(dirt(i), f"assets/tiles/dirt_{i}.png"); save(path(i), f"assets/tiles/path_{i}.png")
save(water(0), "assets/tiles/water_shallow.png"); save(water(1), "assets/tiles/water_deep.png")
save(tree(), "assets/sprites/tree.png"); save(rock(), "assets/sprites/rock.png"); save(player(0), "assets/sprites/player.png")
# tileset atlas: grass0-2, dirt0-2, path0-2, water shallow, water deep (11 tiles in a row)
names = [f"grass_{i}" for i in range(3)] + [f"dirt_{i}" for i in range(3)] + [f"path_{i}" for i in range(3)] + ["water_shallow", "water_deep"]
atlas = Image.new("RGBA", (T * len(names), T))
for i, n in enumerate(names): atlas.paste(Image.open(f"assets/tiles/{n}.png"), (i * T, 0))
save(atlas, "assets/tiles/atlas.png")
print("art generated")
