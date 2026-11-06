"""Trees, bushes, crops, reeds, rocks and crystals for each biome."""

import math

from kit import LIGHT, NOCOLLIDE, prop


def around(count, radius, start=0.0):
    for i in range(count):
        a = start + i * 2 * math.pi / count
        yield i, a, math.cos(a) * radius, math.sin(a) * radius


# --------------------------------------------------------------------- trees
def kikar_tree(p, leaf, dark, light):
    p.rod((0, 0, 0), (0.6, 0.3, 5.5), 0.45, "darkwood", "Wood")
    p.rod((0.6, 0.3, 5.5), (-1.8, -0.6, 7.6), 0.28, "darkwood", "Wood")
    p.rod((0.6, 0.3, 5.5), (2.6, 0.9, 7.3), 0.28, "darkwood", "Wood")
    p.blob(3.6, (0.4, 0.2, 7.9), (1.4, 1.2, 0.35), leaf, seed=1)
    p.blob(2.6, (-2.2, -0.7, 7.9), (1.2, 1.1, 0.35), dark, seed=2)
    p.blob(2.4, (2.9, 1.0, 7.6), (1.2, 1.0, 0.35), light, seed=3)


@prop("KikarTree", "plant", "Acacia with a flat, wide crown (Khet and the countryside)")
def kikar(p):
    kikar_tree(p, "leaf", "leafdark", "leaflight")


@prop("KikarDry", "plant", "A dry desert acacia (Registan)")
def kikar_dry(p):
    kikar_tree(p, "leafyellow", "leaf", "leafyellow")


@prop("MangoTree", "plant", "A round, dense mango tree with mangoes")
def mango_tree(p):
    p.rod((0, 0, 0), (0, 0, 4.6), 0.6, "darkwood", "Wood")
    p.rod((0, 0, 3.6), (1.6, 0.5, 5.4), 0.3, "darkwood", "Wood")
    p.rod((0, 0, 3.8), (-1.5, -0.4, 5.6), 0.3, "darkwood", "Wood")
    p.blob(3.6, (0, 0, 6.8), (1.1, 1.1, 0.85), "leafdark", seed=11)
    p.blob(2.6, (1.9, 0.6, 6.0), (1, 1, 0.9), "leaf", seed=12)
    p.blob(2.5, (-1.8, -0.5, 6.2), (1, 1, 0.9), "leafdark", seed=13)
    for i, a, x, y in around(6, 3.2, 0.4):
        p.blob(0.28, (x, y, 5.6 + (i % 2) * 1.2), (1, 1, 1.3), "mango", "SmoothPlastic", seed=20 + i, jitter=0,
               fallback="None")


@prop("BanyanTree", "plant", "A giant banyan with hanging roots (Jungle)")
def banyan(p):
    p.rod((0, 0, 0), (0.4, 0.2, 11), 1.6, "wood", "Wood", verts=10)
    tips = []
    for i, a, x, y in around(4, 6.5, 0.5):
        tip = (x, y, 9.5 + (i % 2))
        tips.append(tip)
        p.rod((0.3, 0.1, 8.5), tip, 0.55, "wood", "Wood")
        p.blob(4.2, (x, y, tip[2] + 1.8), (1.2, 1.2, 0.6), "leafdark" if i % 2 else "leaf", seed=30 + i)
        for k in range(2):
            rx, ry = x * (0.6 + k * 0.3), y * (0.6 + k * 0.3)
            p.rod((rx, ry, tip[2] - 0.2), (rx, ry, 0), 0.12, "darkwood", "Wood", NOCOLLIDE, verts=6)
    p.blob(5.0, (0.4, 0.2, 13.0), (1.2, 1.2, 0.65), "leaf", seed=35)
    for i, a, x, y in around(5, 2.2, 0.2):
        p.rod((x * 0.5, y * 0.5, 1.4), (x, y, 0), 0.5, "wood", "Wood")


@prop("JungleTree", "plant", "A tall jungle tree with vines")
def jungle_tree(p):
    p.rod((0, 0, 0), (0.3, -0.2, 13), 0.8, "wood", "Wood")
    p.blob(3.8, (0.3, -0.2, 14.0), (1.1, 1.1, 0.7), "leafdark", seed=41)
    p.blob(3.0, (2.2, 0.8, 12.6), (1, 1, 0.7), "leaf", seed=42)
    p.blob(2.8, (-2.0, -1.0, 12.8), (1, 1, 0.7), "leafdark", seed=43)
    for i, (x, y) in enumerate(((2.4, 0.9), (-2.1, -1.0), (0.4, 2.2))):
        p.rod((x, y, 12.0), (x * 1.05, y * 1.05, 6.0 + i), 0.08, "leaf", "Grass", NOCOLLIDE, verts=5)


@prop("Bamboo", "plant", "A clump of tall bamboo")
def bamboo(p):
    for i, a, x, y in around(7, 1.1, 0.3):
        h = 12 + (i * 37 % 6)
        top = (x * 2.2, y * 2.2, h)
        p.rod((x * 0.6, y * 0.6, 0), top, 0.22, "bamboo", "Wood", verts=6)
        p.blob(1.3, top, (1, 1, 1.4), "leaflight", seed=50 + i, fallback="None" if i % 2 else None)
    p.blob(1.6, (0, 0, 0.6), (1.2, 1.2, 0.5), "leaf", seed=58)


@prop("JungleBush", "plant", "A leafy bush")
def jungle_bush(p):
    p.blob(1.8, (0, 0, 1.0), (1.2, 1.1, 0.8), "leafdark", seed=61)
    p.blob(1.4, (1.3, 0.5, 0.9), (1, 1, 0.8), "leaf", seed=62)
    p.blob(1.2, (-1.1, -0.4, 0.8), (1, 1, 0.8), "leaflight", seed=63)


@prop("Fern", "plant", "A fern")
def fern(p):
    for i, a, x, y in around(7, 1.3, 0.2):
        p.box((0.5, 2.8, 0.08), (x, y, 0.75), (35, 0, math.degrees(a) - 90), "leaflight", "Grass", NOCOLLIDE)


@prop("CoconutPalm", "plant", "A leaning coconut palm (Samandar)")
def coconut_palm(p):
    pts = [(0, 0, 0), (0.4, 0, 3), (1.0, 0, 6), (1.8, 0, 9), (2.8, 0, 12), (3.9, 0, 14.5)]
    for k, (a, b) in enumerate(zip(pts, pts[1:])):
        p.rod(a, b, 0.55 - k * 0.03, "coconut" if k % 2 else "wood", "Wood", verts=8)
    top = pts[-1]
    for i, a, x, y in around(7, 1.0, 0.3):
        inner = (top[0] + x * 2.4, top[1] + y * 2.4, top[2] + 0.6)
        outer = (top[0] + x * 5.0, top[1] + y * 5.0, top[2] - 1.2)
        p.beam(top, inner, 1.2, 0.12, "palmleaf", "Grass", NOCOLLIDE)
        p.beam(inner, outer, 1.0, 0.12, "palmleaf", "Grass", NOCOLLIDE)
    for i, a, x, y in around(3, 0.55):
        p.ball(0.42, (top[0] + x, top[1] + y, top[2] - 0.5), "coconut", "Wood", NOCOLLIDE, segments=8, rings=5)


@prop("Willow", "plant", "A weeping willow by the lake (Jheel)")
def willow(p):
    p.rod((0, 0, 0), (0.2, 0, 6.5), 0.75, "wood", "Wood")
    p.blob(4.2, (0.2, 0, 8.0), (1.15, 1.15, 0.75), "leaflight", seed=71)
    for i, a, x, y in around(12, 4.2, 0.1):
        p.box((0.5, 0.3, 4.5), (x, y, 5.6), (0, 0, math.degrees(a)), "leaflight", "Grass", NOCOLLIDE)


@prop("Poplar", "plant", "A tall, narrow poplar (Jheel)")
def poplar(p):
    p.rod((0, 0, 0), (0, 0, 3.5), 0.4, "wood", "Wood")
    p.blob(2.0, (0, 0, 8.5), (1, 1, 3.0), "leaf", seed=81)


def deodar(p, snowy):
    p.rod((0, 0, 0), (0, 0, 3), 0.55, "darkwood", "Wood")
    for k in range(5):
        r = 4.4 - k * 0.7
        z = 3.5 + k * 2.3
        p.cone(r, 3.4, (0, 0, z), color="leafdark", mat="Grass", verts=8, flags=NOCOLLIDE if k else 0,
               fallback="Cylinder", fallback_scale=(0.7, 0.7, 0.8))
        if snowy:
            p.cone(r * 0.62, 1.4, (0, 0, z + 1.05), color="snow", mat="Snow", verts=8, flags=NOCOLLIDE,
                   fallback="None" if k % 2 else "Cylinder", fallback_scale=(0.7, 0.7, 0.6))


@prop("Deodar", "plant", "A deodar pine")
def deodar_green(p):
    deodar(p, False)


@prop("DeodarSnowy", "plant", "A deodar pine with snow on its branches (Pahar)")
def deodar_snowy(p):
    deodar(p, True)


@prop("Mangrove", "plant", "A mangrove on arching roots (Delta)")
def mangrove(p):
    p.rod((0, 0, 3), (0.2, 0, 8), 0.45, "darkwood", "Wood")
    for i, a, x, y in around(6, 1.0, 0.2):
        mid = (x * 2.4, y * 2.4, 1.8)
        p.rod((x * 0.3, y * 0.3, 3.3), mid, 0.18, "darkwood", "Wood", verts=6)
        p.rod(mid, (x * 3.3, y * 3.3, -0.3), 0.16, "darkwood", "Wood", verts=6)
    p.blob(3.2, (0.2, 0, 9.2), (1.2, 1.2, 0.7), "leafdark", seed=91)
    p.blob(2.4, (2.0, 0.8, 8.4), (1, 1, 0.7), "leaf", seed=92)
    p.blob(2.2, (-1.8, -0.8, 8.6), (1, 1, 0.7), "leafdark", seed=93)


@prop("Juniper", "plant", "A low mountain juniper bush (Pahar)")
def juniper(p):
    p.blob(1.6, (0, 0, 0.9), (1.2, 1, 0.8), "leafdark", seed=101)
    p.blob(1.2, (1.2, 0.4, 0.8), (1, 1, 0.9), "leafdark", seed=102)
    p.blob(0.9, (0.3, 0.3, 1.8), (1, 1, 0.6), "snow", "Snow", seed=103, fallback="None")


@prop("DesertShrub", "plant", "An ak bush with little purple flowers (Registan)")
def desert_shrub(p):
    p.blob(1.4, (0, 0, 0.9), (1.2, 1.2, 0.8), "leafyellow", seed=111)
    p.blob(1.0, (1.0, -0.5, 0.7), (1, 1, 0.8), "leaf", seed=112)
    for i, a, x, y in around(4, 1.2, 0.5):
        p.blob(0.25, (x, y, 1.7), (1, 1, 1), "flowerpurple", "SmoothPlastic", seed=113 + i, jitter=0,
               fallback="None")


def tuft(p, color, blades=6, height=2.0):
    for i, a, x, y in around(blades, 0.25, 0.4):
        h = height * (0.75 + (i % 3) * 0.15)
        p.box((0.16, 0.1, h), (x, y, h / 2), (math.cos(a) * 18, -math.sin(a) * 18, 0), color, "Grass",
              NOCOLLIDE)


@prop("DuneGrass", "plant", "A tuft of dry grass (Samandar, Registan)")
def dune_grass(p):
    tuft(p, "straw")


@prop("Reeds", "plant", "Reeds and cattails at the water's edge")
def reeds(p):
    for i, a, x, y in around(6, 0.6, 0.3):
        h = 3.6 + (i % 3) * 0.6
        p.rod((x * 0.4, y * 0.4, 0), (x, y, h), 0.07, "reed", "Grass", NOCOLLIDE, verts=5)
        if i % 2 == 0:
            p.cyl(0.18, 0.8, (x, y, h - 0.3), color="cattail", mat="Fabric", flags=NOCOLLIDE, verts=6)


@prop("FlowerPatch", "plant", "Wild flowers in a meadow (Jheel)")
def flower_patch(p):
    p.blob(1.5, (0, 0, 0.3), (1.4, 1.2, 0.35), "leaflight", seed=121)
    colors = ("flowerpink", "floweryellow", "flowerpurple", "flowerwhite", "flowerpink", "floweryellow", "orange")
    for i, a, x, y in around(7, 1.2, 0.2):
        p.ball(0.35, (x, y, 0.9 + (i % 2) * 0.3), colors[i], "SmoothPlastic", NOCOLLIDE, segments=6, rings=4)


@prop("LilyPads", "plant", "Lily pads and lotus flowers on the lake (Jheel)")
def lily_pads(p):
    for i, a, x, y in around(6, 2.4, 0.5):
        p.cyl(0.8 + (i % 3) * 0.25, 0.08, (x, y, 0.05), color="leaf", mat="Grass", flags=NOCOLLIDE, verts=10)
    for i, (x, y) in enumerate(((1.0, 0.5), (-1.4, -1.0))):
        p.ball(0.35, (x, y, 0.3), "flowerpink" if i == 0 else "flowerwhite", "SmoothPlastic", NOCOLLIDE,
               segments=6, rings=4)


# ------------------------------------------------------------------- rocks
@prop("Boulder", "plant", "A pair of boulders")
def boulder(p):
    p.rock(2.4, (0, 0, 1.2), seed=131)
    p.rock(1.4, (2.4, 0.8, 0.7), seed=132, color="darkstone")


@prop("MossyRock", "plant", "A rock with moss on top (Jungle)")
def mossy_rock(p):
    p.rock(2.2, (0, 0, 1.1), seed=141)
    p.blob(1.6, (0, 0, 2.2), (1.2, 1.2, 0.35), "leaf", "Grass", seed=142, fallback="None")


@prop("SnowRock", "plant", "A rock with a cap of snow (Pahar)")
def snow_rock(p):
    p.rock(2.6, (0, 0, 1.3), seed=151, color="darkstone")
    p.blob(2.0, (0, 0, 2.6), (1.2, 1.2, 0.35), "snow", "Snow", seed=152, fallback="Disc")
    p.rock(1.2, (2.6, -0.6, 0.6), seed=153)


@prop("BeachRocks", "plant", "Dark rocks on the beach (Samandar)")
def beach_rocks(p):
    p.rock(1.8, (0, 0, 0.8), seed=161, color="darkstone")
    p.rock(1.2, (1.9, 0.6, 0.5), seed=162, color="darkstone")
    p.rock(0.9, (-1.6, 0.9, 0.4), seed=163, color="stone")


@prop("RockMesa", "plant", "Layered sandstone rocks (Registan)")
def rock_mesa(p):
    for k, (w, d, h, color) in enumerate(((10, 8, 3, "sandstone"), (8, 6.5, 3, "sandlight"), (5.5, 4.5, 2.6, "sandstone"))):
        z = sum(x[2] for x in ((10, 8, 3), (8, 6.5, 3), (5.5, 4.5, 2.6))[:k]) + h / 2
        p.box((w, d, h), (k * 0.4, -k * 0.3, z), (0, 0, k * 9), color, "Sandstone")
    p.rock(1.6, (5.5, -3.0, 0.7), seed=171, color="sandstone", mat="Sandstone")
    p.rock(1.2, (-5.4, 2.2, 0.5), seed=172, color="sandlight", mat="Sandstone")


# ---------------------------------------------------------------- crystals
@prop("SaltCrystals", "plant", "A small cluster of glowing pink salt crystals (Namak Kaan)")
def salt_crystals(p):
    p.rock(1.6, (0, 0, 0.5), seed=181, color="saltwhite", mat="Salt")
    for i, a, x, y in around(5, 0.8, 0.3):
        h = 2.4 + (i % 3) * 1.1
        tilt = 18 + (i % 2) * 10
        p.box((0.6, 0.6, h), (x, y, h / 2 + 0.3), (math.sin(a) * -tilt, math.cos(a) * tilt, i * 30), "crystal",
              "Neon", NOCOLLIDE | (LIGHT if i == 0 else 0))


@prop("Stalagmites", "plant", "Rocky stalagmites in the salt caves")
def stalagmites(p):
    for i, (x, y, h, r) in enumerate(((0, 0, 5.5, 1.1), (1.6, 0.8, 3.4, 0.8), (-1.2, 1.1, 2.4, 0.6))):
        p.cone(r, h, (x, y, h / 2), color="saltpink" if i % 2 else "stone", mat="Salt", verts=7,
               fallback="Cylinder", fallback_scale=(0.6, 0.6, 1))


# ------------------------------------------------------------------ fields
def field(p, crop, height, rows=6, tufts=True):
    p.box((20, 20, 0.3), (0, 0, 0.15), color="mud", mat="Ground")
    for k in range(rows):
        x = -8.4 + k * (16.8 / (rows - 1))
        p.box((2.2, 19, height), (x, 0, 0.3 + height / 2), color=crop, mat="Grass", flags=NOCOLLIDE | 16)
        if tufts:
            for j in range(5):
                p.detail((1.0, 1.0, height * 0.5), (x + (j % 2) * 0.4 - 0.2, -7.6 + j * 3.8, 0.3 + height),
                         (0, 0, 45), color=crop, mat="Grass")


@prop("WheatField", "plant", "A patch of golden wheat")
def wheat_field(p):
    field(p, "wheat", 1.6)


@prop("SarsonField", "plant", "A patch of yellow sarson (mustard) in flower")
def sarson_field(p):
    field(p, "sarson", 1.4)


@prop("SugarcaneField", "plant", "A patch of tall sugarcane")
def sugarcane_field(p):
    field(p, "sugarcane", 4.5, rows=5)
