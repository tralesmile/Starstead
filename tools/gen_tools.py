#!/usr/bin/env python3
"""Held tool sprites (original, CC0): 8 icons 16x16 in a 128x16 strip, handle at the bottom-left, head toward the upper right.
Order: hoe, watering_can, axe, pickaxe, rod, club, hand(empty), scythe. Deterministic."""
import os
from PIL import Image, ImageDraw
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = (42, 26, 16); WOOD = (150, 100, 58); WOOD_L = (186, 132, 78); STEEL = (176, 186, 196); STEEL_D = (110, 120, 134)
im = Image.new("RGBA", (128, 16), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
def handle(ox):
    d.line([ox+2, 14, ox+11, 3], fill=OUT, width=3)
    d.line([ox+2, 14, ox+11, 3], fill=WOOD, width=1)
    d.point((ox+5, 11), fill=WOOD_L)
# hoe
handle(0); d.polygon([(10, 2), (15, 3), (14, 7), (11, 5)], fill=STEEL, outline=OUT)
# watering can
ox = 16; d.rectangle([ox+3, 6, ox+10, 13], fill=(70, 120, 190), outline=OUT); d.line([ox+10, 8, ox+14, 5], fill=OUT, width=2); d.line([ox+10, 8, ox+14, 5], fill=(70, 120, 190)); d.arc([ox+0, 4, ox+5, 10], 90, 270, fill=OUT); d.line([ox+4, 7, ox+9, 7], fill=(120, 170, 230))
# axe
ox = 32; handle(ox); d.polygon([(ox+8, 1), (ox+15, 2), (ox+14, 8), (ox+9, 6)], fill=STEEL, outline=OUT); d.line([ox+10, 3, ox+13, 4], fill=(230, 236, 242))
# pickaxe
ox = 48; handle(ox); d.arc([ox+5, -2, ox+16, 9], 200, 340, fill=OUT, width=3); d.arc([ox+5, -2, ox+16, 9], 205, 335, fill=STEEL, width=1)
# rod
ox = 64; d.line([ox+1, 15, ox+14, 2], fill=OUT, width=3); d.line([ox+1, 15, ox+14, 2], fill=WOOD_L, width=1); d.line([ox+14, 2, ox+15, 8], fill=(230, 230, 230)); d.point((ox+15, 9), fill=(220, 60, 60))
# club
ox = 80; d.line([ox+2, 14, ox+11, 4], fill=OUT, width=5); d.line([ox+2, 14, ox+11, 4], fill=WOOD, width=3); d.ellipse([ox+8, 1, ox+14, 7], fill=WOOD, outline=OUT); d.point((ox+10, 3), fill=WOOD_L)
# scythe (frame 7): long handle, curved blade sweeping to the upper right
ox = 112; handle(ox); d.arc([ox+3, -4, ox+16, 9], 200, 330, fill=OUT, width=3); d.arc([ox+3, -4, ox+16, 9], 205, 325, fill=STEEL, width=1); d.point((ox+8, 1), fill=(230, 236, 242))
im.save(os.path.join(ROOT, "assets", "sprites", "held_tools.png")); print("wrote held_tools.png")
#, "sprites", "held_tools.png")); print("wrote held_tools.png")
