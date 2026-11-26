#!/usr/bin/env python3
"""Villager sprite sheet for Starstead NPCs (original, CC0).

Run from repo root:  python3 tools/gen_npcs.py
Writes assets/sprites/npcs.png and a 3x preview to /tmp/npcs_preview.png.

Reuses the lit-surface renderer of tools/gen_player_hd.py (same proportions, light, outline rules)
but swaps the palette per outfit and draws beardless heads with three hair styles, so townsfolk no
longer look like tinted copies of the player.

Layout: 256 x (192 * outfits). Each outfit is a block of 4 rows (down, left, up, right) x 8 columns
(idle, 6 walk frames, tool pose), frames 32x48, like columns 0..7 of player_hd.png.
Outfit index = block (row // 4). Order is OUTFITS below; scripts/npc_look.gd mirrors it.
"""
import os, sys
import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gen_player_hd as g  # noqa: E402
from gen_player_hd import rect, ellipse, Layer, YY, XX, PX, PY, CX, quant, hair_locks  # noqa: E402

ROOT = g.ROOT
OUT = os.path.join(ROOT, "assets", "sprites", "npcs.png")
PREVIEW = "/tmp/npcs_preview.png"

SKINS = {
    "fair": ("#7a4634", "#c08060", "#dca27c", "#eebe98", "#fad6b4"),
    "tan": ("#5e3424", "#9a5e3e", "#b87a52", "#d0966a", "#e2b088"),
    "deep": ("#2e1810", "#5a3424", "#76462e", "#8e5a3a", "#a8704a"),
}
HAIRS = {
    "black": ("#141016", "#24202a", "#36303c", "#4a4250", "#5e5464"),
    "brown": ("#2c180e", "#4e2e1a", "#6e4224", "#8e5a32", "#a8703e"),
    "blond": ("#5a3e16", "#a07a32", "#c89c48", "#e2be6a", "#f4dc96"),
    "red": ("#3e140c", "#7a2a16", "#a4401e", "#c85a2a", "#e07c40"),
    "grey": ("#3a3a40", "#6a6a72", "#8e8e96", "#b0b0b8", "#d0d0d6"),
}
# id, skin, hair colour, hair style, tunic ramp (outline + 4), pants ramp (outline + 3), belt accent
OUTFITS = [
    ("farmer", "tan", "brown", "bun",
     ("#3a2410", "#7a4e1e", "#9e6a2a", "#c08a3c", "#dcaa58"), ("#1c2430", "#2e3c52", "#3e5070", "#52688c"), "gold"),
    ("shopkeeper", "fair", "blond", "short",
     ("#1a2840", "#2e4a7a", "#3e64a0", "#5682c0", "#78a2da"), ("#22201a", "#3a362c", "#4e4a3c", "#646050"), "gold"),
    ("fisher", "deep", "black", "short",
     ("#14302a", "#24584a", "#2e7460", "#409478", "#5cb294"), ("#202024", "#34343a", "#46464e", "#5a5a64"), "gold"),
    ("mechanic", "fair", "red", "short",
     ("#3a1410", "#742620", "#963428", "#b44a34", "#d06a48"), ("#1a1a1e", "#2a2a30", "#3a3a42", "#4c4c56"), "gold"),
    ("police", "tan", "black", "short",
     ("#0e1a36", "#1c3466", "#284688", "#3a5ca8", "#5476c4"), ("#101420", "#1c2234", "#283048", "#363e5a"), "gold"),
    ("citizen_a", "deep", "black", "long",
     ("#3a1438", "#6e2a68", "#8c3a86", "#a854a2", "#c474be"), ("#1e1c24", "#302e3a", "#42404e", "#565464"), "gold"),
    ("citizen_b", "fair", "grey", "short",
     ("#2a2a2a", "#4e4e4e", "#686868", "#848484", "#a4a4a4"), ("#1c160e", "#30261a", "#443626", "#5a4834"), "gold"),
    ("citizen_c", "tan", "blond", "long",
     ("#3a3010", "#6e5e1e", "#94802c", "#b8a03e", "#d6c05c"), ("#1a2430", "#2a3a4e", "#3a4e68", "#4e6484"), "gold"),
    ("vance", "fair", "grey", "short",   # Mr. Vance: charcoal suit, near-black trousers
     ("#121216", "#24242c", "#34343e", "#46465a", "#5c5c72"), ("#0c0c10", "#16161c", "#202028", "#2c2c36"), "gold"),
]


def set_palette(skin, hair, tunic, pants):
    g.PAL["skin"] = g.ramp(*SKINS[skin])
    g.PAL["hair"] = g.ramp(*HAIRS[hair])
    g.PAL["tunic"] = g.ramp(*tunic)
    g.PAL["pants"] = g.ramp(*pants)


STYLE = {"v": "short"}


# ---------------------------------------------------------------- beardless heads
def head_front(cv, L, b, dx=0):
    hy = b
    cx = CX + dx
    style = STYLE["v"]
    ears = Layer()
    for ex in (9 + dx, 22 + dx):
        for y in (18, 19, 20):
            ears.put(ex, y + hy, "skin", 2 if y == 19 else (3 if y == 18 else 1))
    cv.comp(ears)
    lay = Layer()
    # long hair falls behind the face down to the shoulders
    if style == "long":
        lm, ldx, ldy, lnz = ellipse(cx, 20.0 + hy, 7.4, 8.4)
        lm &= YY <= 27 + hy
        lm &= ~((abs(PX - cx) < 4.6) & (YY >= 21 + hy))   # nothing under the chin (read as a beard)
        lay.paint(lm, "hair", quant(L.dot(ldx, ldy, lnz), 1, 3, -0.2, 0.95))
        hair_locks(lay, lm & (YY >= 20 + hy), 8, 23, 20, 0, dx, 3)
    m, ndx, ndy, nz = ellipse(cx, 17.6 + hy, 6.8, 6.6)
    cap = m & (YY <= 16 + hy)
    lay.paint(cap, "hair", quant(L.dot(ndx, ndy, nz), 1, 4, -0.15, 0.95))
    # face: rounded with a chin
    fm, fdx, fdy, fnz = ellipse(cx, 18.6 + hy, 5.9, 6.2)
    face = fm & (YY >= 14 + hy)
    fs = quant(L.dot(fdx * 0.8, fdy, fnz), 1, 4, -0.15, 0.9)
    lay.paint(face, "skin", fs)
    # fringe
    for x in range(11, 21):
        fy = 15 + hy + (1 if x in (11, 12, 13, 18) else 0)
        for y in range(14 + hy, fy + 1):
            if fm[y, x + dx] or cap[y, x + dx]:
                lay.put(x + dx, y, "hair", 3 if x < 16 else 2)
    for x in (10, 21):
        for y in range(15, 19 if style == "short" else 21):
            lay.put(x + dx, y + hy, "hair", 2 if x == 10 else 1)
    # bun on top
    if style == "bun":
        bm, bdx, bdy, bnz = ellipse(cx + 0.5, 10.4 + hy, 3.0, 2.6)
        lay.paint(bm, "hair", quant(L.dot(bdx, bdy, bnz), 1, 4, -0.15, 0.95))
    # eyes
    for ex in (12, 18):
        lay.put(ex + dx, 18 + hy, "eye", 2); lay.put(ex + 1 + dx, 18 + hy, "eye", 1)
        lay.put(ex + dx, 19 + hy, "eye", 1); lay.put(ex + 1 + dx, 19 + hy, "eye", 1)
    for x in (12, 13, 18, 19):
        lay.put(x + dx, 17 + hy, "hair", 1)
    # nose, mouth, cheeks
    lay.put(15 + dx, 20 + hy, "skin", 4); lay.put(16 + dx, 20 + hy, "skin", 2)
    lay.put(15 + dx, 21 + hy, "skin", 1); lay.put(16 + dx, 21 + hy, "skin", 1)
    for x in (14, 15, 16, 17):
        lay.put(x + dx, 22 + hy, "skin", 1 if x in (15, 16) else 2)
    lay.put(12 + dx, 21 + hy, "skin", 2); lay.put(19 + dx, 21 + hy, "skin", 2)
    for (x, y) in ((12, 12), (13, 12), (12, 13), (14, 12)):
        if lay.mat[y + hy, x + dx] == g.MI["hair"]:
            lay.put(x + dx, y + hy, "hair", 4)
    # neck
    for x in range(14, 18):
        lay.put(x + dx, 24 + hy, "skin", 1 if x >= 16 else 2)
    cv.comp(lay)


def head_back(cv, L, b, dx=0):
    hy = b
    cx = CX + dx
    style = STYLE["v"]
    ears = Layer()
    for ex in (9 + dx, 22 + dx):
        for y in (18, 19, 20):
            ears.put(ex, y + hy, "skin", 2 if y != 20 else 1)
    cv.comp(ears)
    lay = Layer()
    bottom = 27 if style == "long" else 22
    m, ndx, ndy, nz = ellipse(cx, 18.0 + hy, 7.0 if style == "long" else 6.8, 7.4 if style == "long" else 6.6)
    if style == "long":
        m |= rect(9 + dx, 18 + hy, 22 + dx, 27 + hy) & (abs(PX - cx) < 7.0 - np.maximum(0, PY - (25 + hy)))
    m &= YY <= bottom + hy
    lay.paint(m, "hair", quant(L.dot(ndx, np.clip(ndy, -1, 0.6), nz), 1, 4, -0.2, 0.95))
    hair_locks(lay, m, 9, 22, 14, hy, dx, 3)
    for x in range(14, 18):
        for y in range(bottom + 1, 25):
            lay.put(x + dx, y + hy, "skin", 2 if x < 16 else 1)
    if style == "bun":
        bm, bdx, bdy, bnz = ellipse(cx + 0.5, 11.4 + hy, 3.2, 2.8)
        lay.paint(bm, "hair", quant(L.dot(bdx, bdy, bnz), 1, 4, -0.15, 0.95))
    for (x, y) in ((12, 13), (13, 13), (14, 12), (12, 14)):
        lay.put(x + dx, y + hy, "hair", 4)
    cv.comp(lay)


def head_side(cv, L, b, lean=0):
    hy = b
    ox = lean
    style = STYLE["v"]
    lay = Layer()
    if style == "long":
        lm, ldx, ldy, lnz = ellipse(CX - 2.0 + ox, 20.5 + hy, 5.4, 7.5)
        lm &= (YY <= 27 + hy) & (XX <= 16 + ox)
        lay.paint(lm, "hair", quant(L.dot(ldx, ldy, lnz), 1, 3, -0.2, 0.95))
    m, ndx, ndy, nz = ellipse(CX - 0.3 + ox, 17.8 + hy, 6.7, 6.8)
    hm = m & ((YY <= 15 + hy) | (XX <= 15 + ox)) & (YY <= (24 if style == "long" else 21) + hy)
    lay.paint(hm, "hair", quant(L.dot(ndx, ndy, nz), 1, 4, -0.15, 0.95))
    face = np.zeros(YY.shape, bool)
    rows = {15: (17, 21), 16: (16, 22), 17: (16, 22), 18: (16, 22), 19: (16, 22), 20: (16, 22),
            21: (16, 21), 22: (16, 21), 23: (17, 20)}
    for y, (a, c) in rows.items():
        face |= rect(a + ox, y + hy, c + ox, y + hy)
    fdx = (PX - (CX + ox - 1)) / 7.0; fdy = (PY - (18.5 + hy)) / 6.0
    lay.paint(face, "skin", quant(L.dot(fdx * 0.6, fdy, np.sqrt(np.clip(1 - fdx ** 2 * 0.3 - fdy ** 2 * 0.5, 0.05, 1))), 1, 4, -0.25, 0.8))
    lay.put(23 + ox, 19 + hy, "skin", 3); lay.put(23 + ox, 20 + hy, "skin", 2); lay.put(22 + ox, 19 + hy, "skin", 4)
    for x in range(15, 22):
        lay.put(x + ox, 15 + hy, "hair", 3 if x < 19 else 2)
    lay.put(16 + ox, 16 + hy, "hair", 2)
    lay.put(20 + ox, 18 + hy, "eye", 1); lay.put(20 + ox, 19 + hy, "eye", 1)
    lay.put(19 + ox, 17 + hy, "hair", 1); lay.put(20 + ox, 17 + hy, "hair", 1)
    lay.put(14 + ox, 18 + hy, "skin", 3); lay.put(14 + ox, 19 + hy, "skin", 2); lay.put(14 + ox, 20 + hy, "skin", 1)
    lay.put(21 + ox, 22 + hy, "skin", 1)
    for x in range(15, 18):
        lay.put(x + ox, 24 + hy, "skin", 1)
    if style == "bun":
        bm, bdx, bdy, bnz = ellipse(CX - 3.0 + ox, 11.6 + hy, 2.8, 2.6)
        lay.paint(bm, "hair", quant(L.dot(bdx, bdy, bnz), 1, 4, -0.15, 0.95))
    hair_locks(lay, hm & (XX <= 14 + ox), 9, 14, 15, hy, ox, 3)
    cv.comp(lay)


def cap_layer(cv, L, b, view, ox=0):
    """Peaked police cap in the pants (navy) material, gold badge on the front."""
    lay = Layer()
    cx = CX + ox
    m, ndx, ndy, nz = ellipse(cx - (0.3 if view == "side" else 0), 13.2 + b, 7.2, 3.6)
    m &= YY <= 14 + b
    lay.paint(m, "pants", quant(L.dot(ndx, ndy, nz), 1, 3, -0.2, 0.95))
    band = rect(int(cx) - 7, 14 + b, int(cx) + 6, 15 + b) if view != "side" else rect(int(cx) - 7, 14 + b, int(cx) + 6, 15 + b)
    lay.paint(band, "pants", 1)
    if view == "front":
        lay.paint(rect(int(cx) - 6, 16 + b, int(cx) + 5, 16 + b), "boots", 1)   # visor shadow
        lay.put(cx - 0.5, 13 + b, "gold", 3); lay.put(cx + 0.5, 13 + b, "gold", 2)
    elif view == "side":
        lay.paint(rect(int(cx) + 4, 15 + b, int(cx) + 8, 15 + b), "boots", 1)
    cv.comp(lay)


def with_cap(fn, view):
    def wrapped(cv, L, b, d=0):
        fn(cv, L, b, d)
        if STYLE.get("cap"):
            cap_layer(cv, L, b, view, d)
    return wrapped


head_front = with_cap(head_front, "front")
head_back = with_cap(head_back, "back")
head_side = with_cap(head_side, "side")

g.head_front = head_front
g.head_back = head_back
g.head_side = head_side


def main():
    blocks = []
    for (oid, skin, hair, style, tunic, pants, _acc) in OUTFITS:
        set_palette(skin, hair, tunic, pants)
        STYLE["v"] = style
        STYLE["cap"] = oid == "police"
        blocks.append(g.make_sheet())
    sheet = Image.new("RGBA", (g.FW * 8, g.FH * 4 * len(blocks)), (0, 0, 0, 0))
    for i, b in enumerate(blocks):
        sheet.paste(b, (0, i * g.FH * 4))
    sheet.save(OUT)
    print("wrote", os.path.relpath(OUT, ROOT), sheet.size)
    # preview: idle + walk frame of each direction for every outfit (compact)
    s = 3
    cols = [0, 2]
    pv = Image.new("RGBA", (g.FW * 8 * s, g.FH * len(blocks) * s), (96, 150, 72, 255))
    for i in range(len(blocks)):
        for d in range(4):
            for k, c in enumerate(cols):
                fr = sheet.crop((c * g.FW, (i * 4 + d) * g.FH, (c + 1) * g.FW, (i * 4 + d + 1) * g.FH))
                fr = fr.resize((g.FW * s, g.FH * s), Image.NEAREST)
                pv.alpha_composite(fr, ((d * 2 + k) * g.FW * s, i * g.FH * s))
    pv.save(PREVIEW)
    print("preview", PREVIEW)


if __name__ == "__main__":
    main()
