"""Desi everyday props: charpais, matkas, dhabas, stalls, trucks, rickshaws, huts and boats."""

import math

from kit import GLASS, LIGHT, NOCOLLIDE, prop


def legs(p, w, l, h, color="darkwood", size=0.3, inset=0.2, mat="Wood"):
    for x in (-w / 2 + inset, w / 2 - inset):
        for y in (-l / 2 + inset, l / 2 - inset):
            p.box((size, size, h), (x, y, h / 2), color=color, mat=mat)


def wheel(p, radius, pos, width=0.6, color="tyre", hub="metal"):
    """A wheel turning about the X axis (on a vehicle facing -Y)."""
    p.cyl(radius, width, pos, (0, 90, 0), color=color, mat="SmoothPlastic", verts=12)
    p.cyl(radius * 0.45, width + 0.1, pos, (0, 90, 0), color=hub, mat="Metal", verts=8, flags=NOCOLLIDE)


def umbrella(p, pos, height, radius, color, stripe=None):
    x, y, _ = pos
    p.rod((x, y, 0), (x, y, height), 0.1, "metal", "Metal")
    p.cone(radius, 1.4, (x, y, height + 0.4), color=color, mat="Fabric", verts=8, flags=NOCOLLIDE,
           fallback="Disc", fallback_scale=(1, 1, 0.3))
    if stripe:
        p.cone(radius * 0.5, 0.75, (x, y, height + 0.75), color=stripe, mat="Fabric", verts=8, flags=NOCOLLIDE,
               fallback="None")


@prop("Charpai", "desi", "A woven rope bed")
def charpai(p):
    w, l, h = 3.4, 6.4, 1.5
    legs(p, w, l, h, size=0.35)
    for x in (-w / 2 + 0.2, w / 2 - 0.2):
        p.box((0.3, l, 0.35), (x, 0, h - 0.1), color="wood", mat="Wood")
    for y in (-l / 2 + 0.2, l / 2 - 0.2):
        p.box((w, 0.3, 0.35), (0, y, h - 0.1), color="wood", mat="Wood")
    p.box((w - 0.5, l - 0.5, 0.12), (0, 0, h - 0.05), color="rope", mat="Fabric")
    for i in range(-5, 6):
        p.detail((w - 0.6, 0.06, 0.04), (0, i * 0.5, h + 0.02), color="straw")


@prop("Milestone", "desi", "A roadside milestone; the game writes the distance on it")
def milestone(p):
    p.box((1.6, 0.9, 2.4), (0, 0, 1.2), color="whitewash", mat="Concrete")
    p.cyl(0.8, 0.9, (0, 0, 2.4), (90, 0, 0), color="yellow", mat="Concrete", verts=16)
    p.box((1.8, 1.1, 0.25), (0, 0, 0.12), color="stone", mat="Concrete")
    p.anchor("Face", (0, -0.46, 1.5))


@prop("Matka", "desi", "Clay water pots on a wooden stand")
def matka(p):
    p.box((3.6, 1.4, 0.25), (0, 0, 1.6), color="wood", mat="Wood")
    legs(p, 3.6, 1.4, 1.5, size=0.25)
    for i, x in enumerate((-1.15, 0, 1.15)):
        p.ball(0.62, (x, 0, 2.3), color="clay" if i != 1 else "claydark", mat="Slate", segments=10, rings=7)
        p.cyl(0.28, 0.35, (x, 0, 2.95), color="claydark", mat="Slate", verts=8)
        p.cyl(0.36, 0.08, (x, 0, 3.1), color="wood", mat="Wood", verts=8, flags=NOCOLLIDE)


@prop("TubeWell", "desi", "A hand pump with a trough")
def tubewell(p):
    p.box((4, 4, 0.4), (0, 0.4, 0.2), color="brick", mat="Brick")
    p.cyl(0.35, 3.2, (0, 0.8, 2.0), color="green", mat="Metal", verts=10)
    p.ball(0.45, (0, 0.8, 3.65), color="green", mat="Metal")
    p.rod((0, 0.8, 3.4), (0, 2.6, 4.1), 0.12, "darkmetal", "Metal")
    p.rod((0, 0.8, 2.6), (0, -0.3, 2.3), 0.14, "green", "Metal")
    p.box((2.2, 1.2, 0.6), (0, -1.0, 0.7), color="stone", mat="Concrete")
    p.box((1.9, 0.9, 0.08), (0, -1.0, 0.98), color="water", mat="Glass", flags=NOCOLLIDE)
    p.cyl(0.4, 0.6, (1.4, -0.4, 0.7), color="metal", mat="Metal", verts=8)


@prop("ChaiDhaba", "desi", "A roadside tea stall with a tin roof; the game writes CHAI on its sign")
def dhaba(p):
    p.box((12, 9, 0.3), (0, 0, 0.15), color="stone", mat="Concrete")
    p.box((10, 1.6, 2.8), (0, 3.3, 1.7), color="brick", mat="Brick")
    p.box((10.4, 2.0, 0.25), (0, 3.2, 3.2), color="lightwood", mat="WoodPlanks")
    for x in (-5.6, 5.6):
        for y in (-4.1, 4.1):
            p.cyl(0.2, 8.0, (x, y, 4.2), color="wood", mat="Wood", verts=8)
    p.box((13, 10, 0.2), (0, 0, 8.25), (6, 0, 0), color="tin", mat="Metal")
    for i in range(-6, 7, 2):
        p.detail((0.25, 10, 0.12), (i, 0, 8.4), (6, 0, 0), color="metal")
    # the stove and kettle
    p.box((1.4, 1.1, 0.7), (-3, 3.2, 3.65), color="darkmetal", mat="Metal")
    p.ball(0.65, (-3, 3.2, 4.55), color="metal", mat="Metal")
    p.rod((-3, 2.9, 4.5), (-3, 2.2, 4.9), 0.12, "metal", "Metal", NOCOLLIDE)
    p.rod((-3.5, 3.2, 5.1), (-2.5, 3.2, 5.1), 0.06, "darkmetal", "Metal", NOCOLLIDE)
    for i in range(5):
        p.detail((0.3, 0.3, 0.35), (0.5 + i * 0.6, 3.0, 3.5), color="white")
    p.box((1.8, 1.0, 1.4), (3.5, 3.4, 3.95), color="glass", mat="Glass", flags=GLASS | NOCOLLIDE)
    for i in range(3):
        p.detail((0.5, 0.5, 0.25), (3.0 + i * 0.5, 3.4, 3.6), color="orange")
    # sign
    p.box((6, 0.2, 1.4), (0, -4.35, 7.3), color="red", mat="WoodPlanks")
    p.box((6.3, 0.15, 1.7), (0, -4.25, 7.3), color="yellow", mat="WoodPlanks")
    p.anchor("Sign", (0, -4.47, 7.3))
    # benches
    for x in (-3.2, 3.2):
        p.box((4.6, 1.0, 0.25), (x, -1.8, 1.3), color="wood", mat="WoodPlanks")
        for dx in (-2, 2):
            p.box((0.25, 0.8, 1.0), (x + dx, -1.8, 0.8), color="darkwood", mat="Wood")
    p.cyl(0.9, 0.12, (0, -1.8, 1.7), color="green", mat="Metal", verts=10, flags=NOCOLLIDE)


@prop("FruitStall", "desi", "A fruit cart with an umbrella")
def fruit_stall(p):
    p.box((5.2, 3.2, 0.4), (0, 0, 2.6), color="wood", mat="WoodPlanks")
    for x in (-2.5, 2.5):
        p.box((0.2, 3.2, 0.5), (x, 0, 3.0), color="darkwood", mat="Wood")
    for y in (-1.5, 1.5):
        p.box((5.2, 0.2, 0.5), (0, y, 3.0), color="darkwood", mat="Wood")
    wheel(p, 1.3, (-2.9, 0.4, 1.3), 0.35)
    wheel(p, 1.3, (2.9, 0.4, 1.3), 0.35)
    p.rod((0, -1.6, 2.4), (0, -1.6, 0), 0.15, "darkwood", "Wood")
    for x in (-0.8, 0.8):
        p.rod((x, 1.6, 2.6), (x, 3.6, 2.4), 0.12, "darkwood", "Wood")
    fruit = [("orange", (-1.6, -0.6)), ("red", (0, -0.6)), ("yellow", (1.6, -0.6)), ("mango", (-1.6, 0.7)),
             ("green", (0, 0.7)), ("orange", (1.6, 0.7))]
    for color, (x, y) in fruit:
        p.box((1.4, 1.1, 0.5), (x, y, 3.05), color="lightwood", mat="WoodPlanks")
        for k in range(3):
            p.ball(0.32, (x - 0.35 + k * 0.35, y + (0.15 if k == 1 else -0.1), 3.5), color=color,
                   mat="SmoothPlastic", flags=NOCOLLIDE, segments=8, rings=5)
    umbrella(p, (0, 0.2, 0), 6.5, 3.4, "blue", "white")


@prop("PakoraStall", "desi", "A pakora and samosa stall with a big kadhai")
def pakora_stall(p):
    p.box((4.6, 2.6, 0.25), (0, 0, 2.6), color="lightwood", mat="WoodPlanks")
    legs(p, 4.6, 2.6, 2.5, size=0.25)
    p.box((1.4, 1.4, 0.6), (-1.2, 0.2, 3.0), color="darkmetal", mat="Metal")
    p.cyl(0.95, 0.45, (-1.2, 0.2, 3.5), color="black", mat="Metal", verts=12)
    p.cyl(0.8, 0.05, (-1.2, 0.2, 3.72), color="orange", mat="SmoothPlastic", flags=NOCOLLIDE, verts=12)
    p.box((1.8, 1.2, 0.12), (1.0, 0.0, 2.8), color="metal", mat="Metal")
    for i in range(6):
        p.blob(0.22, (0.4 + (i % 3) * 0.5, -0.25 + (i // 3) * 0.5, 2.95), color="orange", mat="SmoothPlastic",
               seed=i, fallback="None")
    for i in range(3):
        p.blob(0.22, (0.4 + i * 0.6, 0.45, 3.0), (1.2, 1, 0.8), color="gold", mat="SmoothPlastic", seed=10 + i,
               fallback="None")
    umbrella(p, (1.6, 0.9, 0), 6.0, 3.0, "red", "white")


@prop("GolaCart", "desi", "A gola ganda (shaved ice) cart with syrup bottles")
def gola_cart(p):
    p.box((4.2, 2.4, 2.2), (0, 0, 2.3), color="teal", mat="SmoothPlastic")
    p.box((4.4, 2.6, 0.2), (0, 0, 3.5), color="white", mat="SmoothPlastic")
    wheel(p, 0.9, (-2.3, 0.3, 0.9), 0.3)
    wheel(p, 0.9, (2.3, 0.3, 0.9), 0.3)
    p.rod((0, -1.3, 1.6), (0, -1.3, 0), 0.12, "darkmetal", "Metal")
    p.box((1.1, 1.1, 1.0), (-1.2, 0.3, 4.1), color="ice", mat="Glass", flags=GLASS)
    for i, color in enumerate(("red", "yellow", "green", "pink", "blue", "orange")):
        p.cyl(0.16, 0.9, (0.0 + i * 0.35, 0.5, 4.05), color=color, mat="Glass", verts=6, flags=NOCOLLIDE)
    umbrella(p, (0, 0.6, 0), 6.0, 2.8, "yellow", "red")


@prop("TruckArt", "desi", "A painted Bedford truck with its wooden crown")
def truck(p):
    p.box((5.6, 18, 0.7), (0, 0.5, 1.7), color="darkmetal", mat="Metal")
    # hood, cab and windscreen
    p.box((5.0, 3.0, 2.2), (0, -8.6, 3.0), color="green", mat="SmoothPlastic")
    p.box((6.2, 3.8, 3.8), (0, -5.4, 3.9), color="yellow", mat="SmoothPlastic")
    p.box((5.2, 0.15, 1.5), (0, -7.33, 4.8), color="skyblue", mat="Glass")
    for x in (-3.15, 3.15):
        p.box((0.15, 1.6, 1.3), (x, -5.8, 4.7), color="skyblue", mat="Glass")
    p.box((5.6, 0.6, 1.0), (0, -10.3, 2.2), color="red", mat="Metal")
    for x in (-1.9, 1.9):
        p.ball(0.45, (x, -10.15, 3.1), color="white", mat="SmoothPlastic", flags=NOCOLLIDE)
    # the famous wooden crown over the cab, with paint and mirrors
    p.box((6.6, 0.7, 3.2), (0, -6.9, 7.4), color="red", mat="WoodPlanks")
    p.box((5.6, 0.75, 2.2), (0, -6.95, 7.6), color="green", mat="WoodPlanks")
    p.box((3.4, 0.8, 1.2), (0, -7.0, 7.9), color="yellow", mat="WoodPlanks")
    p.box((7.2, 0.8, 0.4), (0, -6.9, 9.1), color="gold", mat="Metal")
    for x, color in zip((-3.0, -1.5, 0, 1.5, 3.0), ("pink", "blue", "pink", "blue", "pink")):
        p.ball(0.32, (x, -7.3, 9.4), color=color, mat="SmoothPlastic", flags=NOCOLLIDE)
    for x in (-3.6, 3.6):
        p.cyl(0.5, 0.2, (x, -7.3, 7.6), (90, 0, 0), color="glass", mat="Glass", verts=10, flags=NOCOLLIDE)
    # the cargo body, painted panels on every side
    p.box((6.6, 13.2, 0.4), (0, 2.8, 2.25), color="wood", mat="WoodPlanks")
    stripes = ("red", "yellow", "green", "blue")
    for x in (-3.2, 3.2):
        p.box((0.25, 13.2, 3.6), (x, 2.8, 4.25), color="orange", mat="WoodPlanks")
        for k, color in enumerate(stripes):
            p.box((0.1, 12.6, 0.55), (x * 1.02, 2.8, 2.95 + k * 0.85), color=color, mat="SmoothPlastic",
                  flags=NOCOLLIDE)
    p.box((6.6, 0.25, 3.6), (0, 9.3, 4.25), color="blue", mat="WoodPlanks")
    for k, color in enumerate(("yellow", "pink", "green")):
        p.box((5.4, 0.1, 0.6), (0, 9.45, 3.2 + k * 1.0), color=color, mat="SmoothPlastic", flags=NOCOLLIDE)
    p.box((6.6, 0.25, 3.6), (0, -3.6, 4.25), color="maroon", mat="WoodPlanks")
    # wheels, mud flaps and chains
    for y in (-8.5, 4.0, 6.8):
        for x in (-2.7, 2.7):
            wheel(p, 1.35, (x, y, 1.35), 0.8)
    for x in (-2.7, 2.7):
        p.box((1.4, 0.12, 1.4), (x, 8.4, 1.0), color="black", mat="Fabric", flags=NOCOLLIDE)
    for i in range(12):
        p.detail((0.12, 0.12, 0.9), (-2.6 + i * 0.47, -10.65, 1.4), color="gold", mat="Metal")


@prop("Rickshaw", "desi", "An auto rickshaw")
def rickshaw(p):
    p.box((3.8, 5.6, 0.6), (0, 0.6, 1.3), color="green", mat="SmoothPlastic")
    p.box((1.6, 1.6, 2.8), (0, -3.0, 2.6), color="green", mat="SmoothPlastic")
    p.box((1.5, 0.15, 1.2), (0, -3.82, 3.6), color="skyblue", mat="Glass")
    p.rod((-1.0, -2.7, 3.9), (1.0, -2.7, 3.9), 0.1, "black", "Metal")
    p.box((3.6, 1.6, 1.4), (0, 2.4, 2.3), color="black", mat="Fabric")
    p.box((3.8, 0.3, 2.2), (0, 3.3, 3.0), color="yellow", mat="SmoothPlastic")
    p.box((4.2, 5.4, 0.3), (0, 0.6, 5.6), color="black", mat="Fabric")
    for x in (-1.9, 1.9):
        for y in (-1.9, 3.2):
            p.rod((x, y, 1.6), (x, y, 5.5), 0.09, "black", "Metal")
        p.box((0.1, 4.2, 0.35), (x * 1.05, 0.9, 1.9), color="yellow", mat="SmoothPlastic", flags=NOCOLLIDE)
    wheel(p, 0.85, (0, -3.4, 0.85), 0.4)
    wheel(p, 0.85, (-1.95, 2.2, 0.85), 0.4)
    wheel(p, 0.85, (1.95, 2.2, 0.85), 0.4)


@prop("TractorTrolley", "desi", "A red tractor pulling a trolley of hay")
def tractor(p):
    p.box((2.4, 4.2, 2.2), (0, -6.2, 2.8), color="red", mat="SmoothPlastic")
    p.box((3.0, 2.8, 2.6), (0, -3.0, 3.0), color="red", mat="SmoothPlastic")
    p.box((2.2, 0.2, 1.4), (0, -8.35, 2.8), color="darkmetal", mat="Metal")
    p.box((1.2, 1.0, 1.4), (0, -1.2, 4.6), color="black", mat="Fabric")
    p.rod((0, -2.2, 4.0), (0, -2.8, 5.4), 0.1, "black", "Metal")
    p.cyl(0.55, 0.12, (0, -2.85, 5.45), (30, 0, 0), color="black", mat="Metal", verts=10)
    p.rod((0.8, -6.8, 3.9), (0.8, -6.8, 6.0), 0.15, "darkmetal", "Metal")
    wheel(p, 2.2, (-2.2, -2.2, 2.2), 1.2)
    wheel(p, 2.2, (2.2, -2.2, 2.2), 1.2)
    wheel(p, 1.1, (-1.5, -6.8, 1.1), 0.6)
    wheel(p, 1.1, (1.5, -6.8, 1.1), 0.6)
    for x in (-2.2, 2.2):
        p.box((1.5, 3.2, 0.25), (x, -2.2, 4.6), color="red", mat="SmoothPlastic")
    p.rod((0, 0.2, 1.4), (0, 2.6, 1.4), 0.15, "darkmetal", "Metal")
    # the trolley
    p.box((5.6, 9.0, 0.4), (0, 7.2, 2.6), color="wood", mat="WoodPlanks")
    for x in (-2.7, 2.7):
        p.box((0.25, 9.0, 1.6), (x, 7.2, 3.6), color="blue", mat="WoodPlanks")
    for y in (2.8, 11.6):
        p.box((5.6, 0.25, 1.6), (0, y, 3.6), color="blue", mat="WoodPlanks")
    wheel(p, 1.3, (-3.0, 7.2, 1.3), 0.7)
    wheel(p, 1.3, (3.0, 7.2, 1.3), 0.7)
    p.blob(3.6, (0, 7.2, 4.3), (0.8, 1.25, 0.45), color="hay", mat="Grass", flags=0, seed=4, fallback="Ball")


@prop("BusStop", "desi", "A bus stop shelter with a bench")
def bus_stop(p):
    p.box((7.4, 3.2, 0.3), (0, 0, 0.15), color="stone", mat="Concrete")
    p.box((7.0, 0.3, 4.6), (0, 1.3, 2.6), color="blue", mat="SmoothPlastic")
    p.box((7.0, 0.32, 1.0), (0, 1.3, 1.0), color="white", mat="SmoothPlastic")
    p.box((7.6, 3.6, 0.3), (0, 0.1, 5.1), (-5, 0, 0), color="white", mat="Metal")
    for x in (-3.4, 3.4):
        p.box((0.3, 0.3, 4.9), (x, -1.3, 2.6), color="darkmetal", mat="Metal")
    p.box((5.2, 1.0, 0.3), (0, 0.5, 1.6), color="wood", mat="WoodPlanks")
    for x in (-2.2, 2.2):
        p.box((0.3, 0.8, 1.3), (x, 0.5, 0.95), color="darkmetal", mat="Metal")
    p.rod((4.4, -0.8, 0), (4.4, -0.8, 5.6), 0.1, "darkmetal", "Metal")
    p.cyl(0.9, 0.15, (4.4, -0.8, 5.9), (90, 0, 0), color="red", mat="SmoothPlastic", verts=16)
    p.cyl(0.65, 0.17, (4.4, -0.8, 5.9), (90, 0, 0), color="white", mat="SmoothPlastic", verts=16,
          flags=NOCOLLIDE)
    p.anchor("Sign", (4.4, -0.9, 5.9))


@prop("Signboard", "desi", "A green road sign; the game writes on it")
def signboard(p):
    for x in (-2.4, 2.4):
        p.box((0.25, 0.25, 6.4), (x, 0.15, 3.2), color="darkmetal", mat="Metal")
    p.box((6.0, 0.15, 3.0), (0, 0.05, 5.0), color="white", mat="Metal")
    p.box((5.6, 0.2, 2.6), (0, 0, 5.0), color="green", mat="Metal")
    p.anchor("Face", (0, -0.11, 5.0))


@prop("Tandoor", "desi", "A clay tandoor oven")
def tandoor(p):
    p.cyl(1.2, 1.8, (0, 0, 0.9), color="clay", mat="Slate", verts=12)
    p.cyl(0.85, 0.2, (0, 0, 1.75), color="black", mat="Slate", verts=12, flags=NOCOLLIDE)
    p.box((2.8, 2.8, 0.3), (0, 0, 0.15), color="brick", mat="Brick")


@prop("Haystack", "desi", "A round haystack with a pole")
def haystack(p):
    p.blob(3.2, (0, 0, 2.0), (1, 1, 0.85), color="hay", mat="Grass", flags=0, seed=7, fallback="Ball")
    p.rod((0, 0, 3.5), (0.3, 0.2, 6.5), 0.12, "darkwood", "Wood", NOCOLLIDE)


@prop("MudHut", "desi", "A village mud house with a flat roof and a ladder")
def mud_hut(p):
    p.box((8, 7, 4.5), (0, 0, 2.25), color="mud", mat="Slate")
    p.box((8.6, 7.6, 0.4), (0, 0, 4.7), color="mudlight", mat="Slate")
    for sx, sy, px, py in ((8.6, 0.4, 0, -3.6), (8.6, 0.4, 0, 3.6), (0.4, 6.8, -4.1, 0), (0.4, 6.8, 4.1, 0)):
        p.box((sx, sy, 0.7), (px, py, 5.25), color="mudlight", mat="Slate")
    p.box((1.8, 0.2, 3.2), (-1.5, -3.52, 1.6), color="darkwood", mat="Wood")
    p.box((1.2, 0.2, 1.0), (2.0, -3.52, 2.8), color="black", mat="Wood")
    for k in range(3):
        p.detail((0.5, 0.05, 0.5), (-3.0 + k * 1.2, -3.52, 4.0), color="whitewash")
    for y in (-0.5, 0.5):
        p.rod((4.6, y, 0), (4.3, y, 5.4), 0.1, "wood", "Wood")
    for k in range(5):
        p.box((0.12, 1.1, 0.12), (4.55 - k * 0.06, 0, 0.9 + k * 1.0), color="wood", mat="Wood")


@prop("WaterTank", "desi", "The village water tank on stilts; treasure sits on its lid")
def water_tank(p):
    for x in (-3, 3):
        for y in (-3, 3):
            p.box((0.8, 0.8, 16), (x, y, 8), color="metal", mat="Metal")
    for z in (5, 11):
        p.box((6.8, 0.3, 0.3), (0, -3, z), color="metal", mat="Metal")
        p.box((6.8, 0.3, 0.3), (0, 3, z), color="metal", mat="Metal")
        p.box((0.3, 6.8, 0.3), (-3, 0, z), color="metal", mat="Metal")
        p.box((0.3, 6.8, 0.3), (3, 0, z), color="metal", mat="Metal")
    p.cyl(4.5, 6, (0, 0, 19), color="slate", mat="Metal", verts=16)
    p.cyl(4.7, 0.4, (0, 0, 22.2), color="darkmetal", mat="Metal", verts=16)
    for x in (-0.5, 0.5):
        p.box((0.12, 0.12, 16), (x, -3.5, 8), color="darkmetal", mat="Metal", flags=NOCOLLIDE)
    for k in range(10):
        p.box((1.1, 0.1, 0.1), (0, -3.5, 1.2 + k * 1.5), color="darkmetal", mat="Metal", flags=NOCOLLIDE)
    p.anchor("Top", (0, 0, 22.4))
    p.anchor("TopStand", (2.6, 0, 22.6))
    p.anchor("Base", (0, -7, 0))


def beach_hut(p, wall, roof):
    for x in (-3, 3):
        for y in (-2.5, 2.5):
            p.box((0.4, 0.4, 1.6), (x, y, 0.8), color="wood", mat="Wood")
    p.box((7, 6.4, 0.3), (0, -0.3, 1.65), color="lightwood", mat="WoodPlanks")
    p.box((6, 5, 4), (0, 0.5, 3.8), color=wall, mat="WoodPlanks")
    p.box((1.4, 0.2, 2.6), (0, -2.05, 3.1), color="white", mat="WoodPlanks")
    p.hip_roof((0, 0.5, 5.8), 6, 5, pitch=28, thickness=0.3, overhang=0.6, color=roof, mat="WoodPlanks")
    for k in range(3):
        p.box((1.6, 0.6, 0.3), (0, -3.3 - k * 0.6, 1.3 - k * 0.45), color="lightwood", mat="WoodPlanks")
    for x in (-3.3, 3.3):
        p.box((0.15, 6.0, 0.15), (x, -0.3, 2.6), color="white", mat="Wood", flags=NOCOLLIDE)


@prop("BeachHutTeal", "desi", "A beach hut on short stilts")
def beach_hut_teal(p):
    beach_hut(p, "teal", "white")


@prop("BeachHutPink", "desi", "A beach hut on short stilts")
def beach_hut_pink(p):
    beach_hut(p, "pink", "white")


@prop("BeachHutYellow", "desi", "A beach hut on short stilts")
def beach_hut_yellow(p):
    beach_hut(p, "yellow", "red")


def hull(p, length, width, depth, color, trim):
    p.box((width * 0.7, length * 0.86, 0.5), (0, 0, 0.25), color=color, mat="WoodPlanks")
    for side in (-1, 1):
        p.box((0.35, length * 0.9, depth), (side * width * 0.42, 0, depth / 2 + 0.1), (0, side * 14, 0),
              color=color, mat="WoodPlanks")
        p.box((0.12, length * 0.88, 0.35), (side * width * 0.48, 0, depth - 0.1), (0, side * 14, 0),
              color=trim, mat="SmoothPlastic", flags=NOCOLLIDE)
        p.box((0.35, length * 0.22, depth), (side * width * 0.2, -length * 0.5, depth / 2 + 0.1),
              (0, side * 10, side * -32), color=color, mat="WoodPlanks")
    p.box((width * 0.8, 0.35, depth), (0, length * 0.45, depth / 2 + 0.1), color=color, mat="WoodPlanks")


@prop("FishingBoat", "desi", "A colourful fishing boat")
def fishing_boat(p):
    hull(p, 16, 5, 2.4, "blue", "yellow")
    p.box((3.0, 4.0, 2.4), (0, 3.2, 2.6), color="white", mat="WoodPlanks")
    p.box((3.1, 4.1, 0.4), (0, 3.2, 3.9), color="red", mat="WoodPlanks")
    p.box((3.05, 0.1, 0.8), (0, 1.15, 2.9), color="skyblue", mat="Glass", flags=NOCOLLIDE)
    p.rod((0, -2.5, 0.4), (0, -2.5, 10.5), 0.16, "wood", "Wood")
    p.rod((0, -2.5, 6.0), (0, 1.2, 6.0), 0.1, "wood", "Wood", NOCOLLIDE)
    p.rope((0, -2.5, 10.4), (0, 6.5, 2.6), 0.6, 0.05, "rope", 6)
    for i, color in enumerate(("red", "yellow", "green", "pink", "orange")):
        p.detail((0.05, 0.5, 0.45), (0, -1.5 + i * 1.5, 9.6 - i * 1.4), color=color, mat="Fabric")
    p.box((4.8, 0.2, 0.6), (0, -6.7, 1.9), (0, 0, 0), color="red", mat="SmoothPlastic", flags=NOCOLLIDE)


@prop("RowBoat", "desi", "A small rowing boat with oars")
def row_boat(p):
    hull(p, 8, 3.2, 1.4, "red", "white")
    for y in (-1.2, 1.6):
        p.box((2.4, 0.6, 0.15), (0, y, 1.0), color="lightwood", mat="WoodPlanks")
    for side in (-1, 1):
        p.rod((side * 0.9, 0.2, 1.1), (side * 3.0, -1.5, 0.6), 0.07, "lightwood", "Wood", NOCOLLIDE)
        p.box((0.15, 1.0, 0.45), (side * 3.0, -1.6, 0.58), (0, 0, side * 50), color="lightwood", mat="Wood",
              flags=NOCOLLIDE)


@prop("NetRack", "desi", "Fishing nets drying on poles")
def net_rack(p):
    for x in (-3.2, 3.2):
        p.rod((x, 0, 0), (x, 0, 6), 0.15, "wood", "Wood")
    p.rod((-3.4, 0, 5.8), (3.4, 0, 5.8), 0.1, "wood", "Wood")
    p.box((6.2, 0.08, 3.8), (0, 0, 3.8), color="teal", mat="Fabric", flags=NOCOLLIDE)
    for k in range(7):
        p.ball(0.18, (-2.7 + k * 0.9, -0.05, 1.95), color="orange", mat="SmoothPlastic", flags=NOCOLLIDE,
               segments=6, rings=4)


@prop("DesertTent", "desi", "A striped tent with a rug and cushions")
def desert_tent(p):
    p.box((7, 7, 0.1), (0, 0, 0.05), color="red", mat="Fabric")
    p.box((5.6, 5.6, 0.11), (0, 0, 0.06), color="yellow", mat="Fabric", flags=NOCOLLIDE)
    p.rod((0, 0, 0), (0, 0, 6.2), 0.15, "wood", "Wood")
    # four panels leaning in from the rug's edges to the top of the pole
    tilt = math.degrees(math.atan2(3.5, 6.2))
    for k, color in enumerate(("red", "orange", "red", "orange")):
        a = k * 90
        rad = math.radians(a)
        p.box((7.0, 0.15, 7.1), (1.75 * math.sin(rad), -1.75 * math.cos(rad), 3.1), (-tilt, 0, a),
              color=color, mat="Fabric")
    for k in range(3):
        p.box((1.2, 0.8, 0.5), (-1.6 + k * 1.6, 2.0, 0.3), color=("blue", "green", "purple")[k], mat="Fabric")
    p.ball(0.5, (2.2, -2.4, 0.5), color="clay", mat="Slate")


@prop("BeachUmbrella", "desi", "A beach umbrella with a deck chair")
def beach_umbrella(p):
    umbrella(p, (0, 0, 0), 5.5, 3.4, "pink", "white")
    p.box((1.8, 3.2, 0.15), (1.8, -1.2, 0.9), (-20, 0, 0), color="blue", mat="Fabric")
    p.box((1.8, 0.15, 1.6), (1.8, 0.4, 1.5), (-20, 0, 0), color="blue", mat="Fabric")
    for x in (1.0, 2.6):
        p.rod((x, -2.6, 0), (x, 0.5, 2.0), 0.06, "white", "Metal", NOCOLLIDE)


@prop("Lamppost", "desi", "A lamp post that lights up")
def lamppost(p):
    p.box((0.9, 0.9, 0.6), (0, 0, 0.3), color="darkmetal", mat="Metal")
    p.cyl(0.18, 7, (0, 0, 3.8), color="darkmetal", mat="Metal", verts=8)
    p.rod((0, 0, 7.0), (0, -1.2, 7.4), 0.1, "darkmetal", "Metal", NOCOLLIDE)
    p.ball(0.45, (0, -1.3, 7.0), color="yellow", mat="Neon", flags=LIGHT | NOCOLLIDE)
    p.cone(0.7, 0.5, (0, -1.3, 7.55), color="darkmetal", mat="Metal", verts=8, flags=NOCOLLIDE)


@prop("KiteLine", "desi", "Bamboo poles with a string of patang kites")
def kite_line(p):
    for x in (-6, 6):
        p.rod((x, 0, 0), (x, 0, 10), 0.16, "bamboo", "Wood")
    points = p.rope((-6, 0, 9.8), (6, 0, 9.8), 1.2, 0.04, "white", 8)
    for k, color in enumerate(("red", "yellow", "green", "pink", "blue")):
        q = points[k + 2]
        p.box((1.3, 0.06, 1.3), (q.x, q.y - 0.1, q.z - 0.9), (0, 45, 0), color=color, mat="Fabric", flags=NOCOLLIDE)
        p.detail((0.1, 0.05, 1.2), (q.x, q.y - 0.1, q.z - 2.1), color=color, mat="Fabric")


@prop("Bench", "desi", "A wooden bench")
def bench(p):
    p.box((4.6, 1.2, 0.25), (0, 0, 1.3), color="wood", mat="WoodPlanks")
    p.box((4.6, 0.2, 1.0), (0, 0.55, 2.0), (-10, 0, 0), color="wood", mat="WoodPlanks")
    for x in (-1.9, 1.9):
        p.box((0.3, 1.0, 1.2), (x, 0, 0.6), color="darkwood", mat="Wood")


@prop("CricketStumps", "desi", "Stumps, bails and a bat for a game of street cricket")
def cricket(p):
    for x in (-0.35, 0, 0.35):
        p.rod((x, 0, 0), (x, 0, 2.2), 0.06, "cream", "Wood")
    p.box((0.9, 0.08, 0.08), (0, 0, 2.25), color="cream", mat="Wood", flags=NOCOLLIDE)
    p.box((0.5, 0.15, 2.4), (1.4, 0.2, 1.1), (0, 0, 15), color="lightwood", mat="Wood", flags=NOCOLLIDE)
    p.rod((1.4, 0.2, 2.3), (1.45, 0.2, 3.1), 0.08, "black", "Fabric", NOCOLLIDE)
    p.ball(0.18, (0.6, -1.0, 0.18), color="red", mat="SmoothPlastic", flags=NOCOLLIDE)
    for x in (-0.35, 0, 0.35):
        p.rod((x, -18, 0), (x, -18, 2.2), 0.06, "cream", "Wood")
    p.box((2.4, 19.4, 0.04), (0, -9, 0.02), color="sandlight", mat="Concrete", flags=NOCOLLIDE)
