#!/usr/bin/env python3
"""Flying arrow sprite (original, CC0): one 16x5 arrow pointing RIGHT. Deterministic."""
import os
from PIL import Image
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PAL = {"o": (42, 26, 16, 255), "w": (150, 100, 58, 255), "l": (186, 132, 78, 255),
       "s": (176, 186, 196, 255), "h": (230, 236, 242, 255), "d": (110, 120, 134, 255),
       "f": (244, 240, 228, 255), "r": (200, 74, 74, 255)}
ROWS = [
    "oooo......oo....",
    "ofrfo.....oho...",
    ".owwwwllwwwsshho",
    "ofrfo.....odo...",
    "oooo......oo....",
]

def main():
    im = Image.new("RGBA", (16, 5), (0, 0, 0, 0))
    for y, row in enumerate(ROWS):
        for x, ch in enumerate(row):
            if ch != ".":
                im.putpixel((x, y), PAL[ch])
    im.save(os.path.join(ROOT, "assets", "sprites", "arrow.png"))
    print("wrote arrow.png")

if __name__ == "__main__":
    main()
