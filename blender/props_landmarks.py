"""The big landmark of each biome, and the pieces of the salt cavern."""

import math

import style
from kit import GLASS, LIGHT, NOCOLLIDE, prop
from style import BRICK, CREAM, TEAL, WOOD, D


def circle(count, radius, z=0.0, start=0.0, cx=0.0, cy=0.0):
    for i in range(count):
        a = start + i * 2 * math.pi / count
        yield i, a, (cx + math.cos(a) * radius, cy + math.sin(a) * radius, z)


# ------------------------------------------------------------------- Khet
@prop("Rehat", "landmark", "Khet: a wooden rehat (Persian water wheel) over the canal")
def rehat(p):
    """The canal runs left to right (the game digs it). The big wheel stands over it
    and dips its pots in the water; a gear and a long beam stand on the back bank."""
    hub = (0, 0, 3.6)
    r = 6.0
    # the big wheel: rim, spokes and clay pots
    rim = [(math.cos(a) * r, 0, hub[2] + math.sin(a) * r) for a in (i * 2 * math.pi / 16 for i in range(16))]
    for a, b in zip(rim, rim[1:] + rim[:1]):
        p.rod(a, b, 0.32, WOOD, "Wood", verts=6)
    for i in range(0, 16, 2):
        p.rod(hub, rim[i], 0.2, "wood", "Wood", verts=6)
    for i, a in enumerate(i * 2 * math.pi / 16 for i in range(16)):
        p.ball(0.5, (math.cos(a) * (r + 0.5), 0.35, hub[2] + math.sin(a) * (r + 0.5)),
               "terracotta" if i % 2 else "clay", "Slate", D, segments=8, rings=5)
    p.rod((0, -4.8, hub[2]), (0, 5.8, hub[2]), 0.32, "darkwood", "Wood")
    # a painted hub with a gold ring
    p.cyl(0.9, 0.5, (0, -0.45, hub[2]), (90, 0, 0), TEAL, "SmoothPlastic", D, verts=12)
    p.cyl(1.05, 0.3, (0, -0.25, hub[2]), (90, 0, 0), "gold", "SmoothPlastic", D, verts=12)
    # supports on both banks, on brick plinths with cream caps
    for y in (-4.6, 4.6):
        p.rod((-1.8, y, 0.8), (0, y, hub[2] + 0.4), 0.3, "darkwood", "Wood")
        p.rod((1.8, y, 0.8), (0, y, hub[2] + 0.4), 0.3, "darkwood", "Wood")
        p.box((4.4, 1.6, 0.6), (0, y, 0.3), color=BRICK, mat="Brick")
        p.box((4.6, 1.8, 0.2), (0, y, 0.7), color=CREAM, mat="Concrete")
    # the gear on the back bank, the walking circle and the beam
    p.cyl(8.5, 0.15, (0, 9.5, 0.08), color="mudlight", mat="Ground", verts=20, flags=NOCOLLIDE)
    gear = [(math.cos(a) * 1.8, 5.4, hub[2] + math.sin(a) * 1.8) for a in (i * 2 * math.pi / 8 for i in range(8))]
    for a, b in zip(gear, gear[1:] + gear[:1]):
        p.rod(a, b, 0.18, WOOD, "Wood", NOCOLLIDE, verts=5)
    p.rod((0, 7.2, 0.5), (0, 7.2, 6.2), 0.35, "darkwood", "Wood")
    p.cyl(2.6, 0.5, (0, 7.2, 5.1), color=WOOD, mat="Wood", verts=12)
    p.cyl(1.0, 0.2, (0, 7.2, 5.45), color=TEAL, mat="SmoothPlastic", verts=12, flags=D)
    for i, a, pos in circle(10, 2.4, 5.6, cx=0, cy=7.2):
        p.box((0.3, 0.3, 0.6), pos, color="darkwood", mat="Wood", flags=NOCOLLIDE)
    p.rod((0, 7.2, 5.9), (0, 17.0, 5.0), 0.25, WOOD, "Wood")
    p.box((4.0, 4.0, 0.5), (0, 7.2, 0.25), color=BRICK, mat="Brick")
    # a striped shade over the gear, on four posts
    for x in (-3.6, 3.6):
        for y in (3.9, 10.5):
            style.post(p, x, y, 8.0 + (y - 3.9) / 6.6 * 1.0, 0.4)
    style.awning(p, -3.9, 3.9, 10.7, 3.7, 9.1, 8.0, stripes=6)
    # the channel that carries water to the fields, with painted diamonds
    p.box((2.6, 6.0, 0.8), (3.5, -8.0, 0.4), color=BRICK, mat="Brick")
    p.box((1.8, 6.0, 0.1), (3.5, -8.0, 0.82), color="water", mat="Glass", flags=NOCOLLIDE)
    style.side_diamonds(p, 4.87, -10.6, -5.4, 0.42, height=0.5)
    p.anchor("CanalLeft", (-30, 0, 0))
    p.anchor("CanalRight", (30, 0, 0))


# ------------------------------------------------------------------ Jungle
@prop("Treehouse", "landmark", "Jungle: a treehouse in a giant tree, with a rope ladder")
def treehouse(p):
    p.rod((0, 0, 0), (0.4, 0.3, 22), 2.2, "wood", "Wood", verts=10)
    for i, a, pos in circle(5, 4.6, 0.0, 0.3):
        p.rod((pos[0] * 0.38, pos[1] * 0.38, 2.6), pos, 0.6, "wood", "Wood", verts=6)
    tips = []
    for i, a, pos in circle(4, 6.5, 0, 0.8):
        tip = (pos[0], pos[1], 21.5 + (i % 2) * 1.5)
        tips.append(tip)
        p.rod((0.3, 0.2, 17.5 + i * 0.6), tip, 0.6, "wood", "Wood", verts=6)
        style.canopy(p, 5.0, (tip[0], tip[1], tip[2] + 1.5), (1.1, 1.1, 0.65), "leafdark" if i % 2 else "leaf",
                     seed=200 + i)
    style.canopy(p, 6.0, (0.4, 0.3, 25.0), (1.1, 1.1, 0.7), "leaf", seed=205)
    # the deck, with warm planks across it, and its railing
    deck_z = 12.0
    p.box((12, 12, 0.5), (0, 0, deck_z), color="lightwood", mat="WoodPlanks")
    for k in (-4.5, -1.5, 1.5, 4.5):
        p.box((1.2, 11.8, 0.06), (k, 0, deck_z + 0.26), color=WOOD, mat="WoodPlanks", flags=D)
    for x, y in ((-5.6, -5.6), (5.6, -5.6), (-5.6, 5.6), (5.6, 5.6)):
        p.rod((0.6 * x / abs(x), 0.6 * y / abs(y), deck_z - 4.5), (x, y, deck_z - 0.3), 0.25, "darkwood", "Wood")
    for x, y in ((-5.8, -5.8), (5.8, -5.8), (-5.8, 5.8), (5.8, 5.8), (0, 5.8), (-5.8, 0), (5.8, 0), (2.2, -5.8),
                 (-2.2, -5.8)):
        p.box((0.25, 0.25, 1.6), (x, y, deck_z + 1.05), color="darkwood", mat="Wood")
    p.box((11.8, 0.2, 0.2), (0, 5.8, deck_z + 1.8), color=CREAM, mat="Wood")
    p.box((0.2, 11.8, 0.2), (-5.8, 0, deck_z + 1.8), color=CREAM, mat="Wood")
    p.box((0.2, 11.8, 0.2), (5.8, 0, deck_z + 1.8), color=CREAM, mat="Wood")
    for x in (-4.0, 4.0):
        p.box((3.6, 0.2, 0.2), (x, -5.8, deck_z + 1.8), color=CREAM, mat="Wood")
    # the little hut, around the trunk
    hz = deck_z + 0.25
    p.box((7, 0.3, 4.2), (0, 3.3, hz + 2.1), color="bamboo", mat="WoodPlanks")
    for x in (-3.4, 3.4):
        p.box((0.3, 6.6, 4.2), (x, 0, hz + 2.1), color="bamboo", mat="WoodPlanks")
    for x in (-2.4, 2.4):
        p.box((2.2, 0.3, 4.2), (x, -3.3, hz + 2.1), color="bamboo", mat="WoodPlanks")
    p.box((2.6, 0.3, 1.0), (0, -3.3, hz + 3.7), color="bamboo", mat="WoodPlanks")
    p.hip_roof((0, 0, hz + 4.2), 7.0, 6.6, pitch=32, thickness=0.35, overhang=0.9, color="thatch")
    # painted front: a band of diamonds, teal shutters, a striped awning over the door and bulbs
    style.diamonds(p, -3.5, 3.5, -3.53, hz + 3.85, height=0.55)
    for x in (-2.4, 2.4):
        p.box((1.0, 0.1, 1.1), (x, -3.5, hz + 2.2), color="darkwood", mat="Wood", flags=D)
        for dx in (-0.78, 0.78):
            p.box((0.5, 0.12, 1.2), (x + dx, -3.52, hz + 2.2), color=TEAL, mat="WoodPlanks", flags=D)
    style.awning(p, -1.6, 1.6, -3.5, -4.7, hz + 3.45, hz + 2.95, stripes=4)
    style.bulbs(p, -4.2, 4.2, -4.35, hz + 3.75, 8)
    # the rope ladder
    for x in (-0.7, 0.7):
        p.rod((x, -6.0, deck_z), (x, -8.2, 0), 0.08, "rope", "Fabric", NOCOLLIDE, verts=5)
    for k in range(11):
        t = (k + 0.5) / 11
        p.box((1.5, 0.25, 0.15), (0, -6.0 - 2.2 * t, deck_z * (1 - t)), color=WOOD, mat="Wood")
    p.anchor("Deck", (3.5, -4.0, deck_z + 0.25))
    p.anchor("LadderBase", (0, -9.5, 0))


@prop("RopeBridge", "landmark", "Jungle: a swaying rope bridge over the river")
def rope_bridge(p):
    length, width, sag = 36.0, 4.0, 0.7
    count = 34
    for k in range(count):
        t = (k + 0.5) / count
        y = -length / 2 + t * length
        z = 1.0 - sag * 4 * t * (1 - t)
        p.box((width, 0.8, 0.22), (0, y, z), color="lightwood" if k % 3 else WOOD, mat="WoodPlanks")
    for x in (-width / 2 - 0.2, width / 2 + 0.2):
        for y in (-length / 2, length / 2):
            p.rod((x, y, -1.0), (x, y, 4.2), 0.25, "darkwood", "Wood", verts=6)
            p.ball(0.4, (x, y, 4.4), "gold", "SmoothPlastic", D, segments=8, rings=5)
        rail = p.rope((x, -length / 2, 4.0), (x, length / 2, 4.0), sag + 0.8, 0.1, "rope", 10)
        style.flags_along(p, [(x, q.y, q.z) for q in rail[2:9:2]], x)
        for k in range(1, 10, 2):
            q = rail[k]
            p.rod((x, q.y, q.z), (x, q.y, 1.0 - sag * 4 * (k / 10) * (1 - k / 10)), 0.05, "rope", "Fabric",
                  NOCOLLIDE, verts=4)


# ---------------------------------------------------------------- Samandar
@prop("Lighthouse", "landmark", "Samandar: a striped lighthouse on the island")
def lighthouse(p):
    for i in range(7):
        a = i * 2 * math.pi / 7
        style.rock(p, 2.2, (math.cos(a) * 5, math.sin(a) * 5, 0.6), seed=i, color="darkstone")
    p.cyl(5.2, 1.2, (0, 0, 0.6), color="stone", mat="Concrete", verts=16)
    p.cyl(5.4, 0.3, (0, 0, 1.25), color=CREAM, mat="Concrete", verts=16)
    bands = 7
    height = 28.0
    for i in range(bands):
        z0 = 1.2 + i * height / bands
        r = 3.8 - i * 0.18
        p.cyl(r, height / bands, (0, 0, z0 + height / bands / 2), color="red" if i % 2 == 0 else "white",
              mat="Concrete", verts=16)
    top = 1.2 + height
    # a teal door in a cream frame, under a little striped awning
    p.box((2.2, 0.4, 3.6), (0, -3.68, 3.1), color=CREAM, mat="Concrete")
    p.box((1.6, 0.4, 3.0), (0, -3.8, 2.9), color=TEAL, mat="WoodPlanks")
    style.awning(p, -1.5, 1.5, -3.9, -5.0, 5.3, 4.8, stripes=4)
    for z in (9, 17, 24):
        y = -3.6 + (z - 9) * 0.03
        p.box((1.4, 0.3, 1.9), (0, y + 0.05, z), color=CREAM, mat="Concrete")
        p.box((0.9, 0.3, 1.4), (0, y - 0.05, z), color="skyblue", mat="Glass")
    p.cyl(4.6, 0.6, (0, 0, top + 0.3), color="darkmetal", mat="Metal", verts=16)
    for i in range(16):
        a = i * 2 * math.pi / 16
        p.rod((math.cos(a) * 4.4, math.sin(a) * 4.4, top + 0.6), (math.cos(a) * 4.4, math.sin(a) * 4.4, top + 2.0),
              0.08, "darkmetal", "Metal", NOCOLLIDE, verts=4)
    p.cyl(4.45, 0.15, (0, 0, top + 2.0), color="gold", mat="Metal", verts=16, flags=NOCOLLIDE)
    p.cyl(2.4, 3.6, (0, 0, top + 2.4), color="glass", mat="Glass", flags=GLASS | NOCOLLIDE, verts=12)
    p.ball(1.1, (0, 0, top + 2.4), color="yellow", mat="Neon", flags=LIGHT | NOCOLLIDE)
    p.cyl(2.6, 0.4, (0, 0, top + 4.4), color="darkmetal", mat="Metal", verts=12)
    style.cone(p, 2.9, 2.6, (0, 0, top + 5.9), "red", "Metal")
    p.ball(0.45, (0, 0, top + 7.4), color="gold", mat="Metal")
    p.anchor("Gallery", (2.6, -2.6, top + 0.6))
    p.anchor("GalleryStand", (-2.6, -2.6, top + 0.9))
    p.anchor("Door", (0, -6.5, 0))


# ------------------------------------------------------------------- Jheel
@prop("RestHouse", "landmark", "Jheel: a lakeside rest house with a veranda")
def rest_house(p):
    p.box((22, 15, 1.0), (0, 0.5, 0.5), color="stone", mat="Concrete")
    p.box((18, 10, 6.0), (0, 2.0, 4.0), color="whitewash", mat="Concrete")
    p.box((18.2, 10.2, 0.5), (0, 2.0, 6.7), color=CREAM, mat="Concrete")
    p.box((2.6, 0.2, 4.0), (0, -3.02, 3.0), color=CREAM, mat="Concrete")
    p.box((2.0, 0.2, 3.6), (0, -3.1, 2.8), color=TEAL, mat="WoodPlanks")
    for x in (-6.0, -3.0, 3.0, 6.0):
        p.box((1.6, 0.2, 1.8), (x, -3.05, 4.0), color="skyblue", mat="Glass")
        for dx in (-1.1, 1.1):
            p.box((0.6, 0.12, 1.9), (x + dx, -3.12, 4.0), color=TEAL, mat="WoodPlanks", flags=D)
    style.diamonds(p, -8.6, 8.6, -3.12, 5.6, height=0.6)
    p.hip_roof((0, 2.0, 7.0), 18, 10, pitch=30, thickness=0.45, overhang=1.0, color="green", mat="Metal")
    p.box((1.4, 1.4, 3.4), (5.5, 4.0, 10.0), color=BRICK, mat="Brick")
    # the veranda
    p.box((18.6, 4.6, 0.3), (0, -5.3, 7.0), (-4, 0, 0), color="green", mat="Metal")
    for x in (-8.5, -5.1, -1.7, 1.7, 5.1, 8.5):
        p.cyl(0.32, 6.0, (x, -6.9, 4.0), color=CREAM, mat="Concrete", verts=8)
    for x in (-8.5, -5.1, 5.1, 8.5):
        p.box((3.4, 0.2, 0.9), (x + 1.7 if x < 0 else x - 1.7, -6.9, 1.45), color=CREAM, mat="Concrete")
    for k in range(3):
        p.box((4.0, 0.9, 0.35), (0, -7.4 - k * 0.9, 0.85 - k * 0.33), color="stone", mat="Concrete")
    style.bulbs(p, -8.0, 8.0, -7.6, 6.0, 10)
    p.anchor("Front", (0, -10.5, 0))


@prop("Jetty", "landmark", "Jheel: a long wooden jetty into the lake, with a lamp at the end")
def jetty(p):
    deck_z = 1.4
    p.box((4.0, 32.0, 0.4), (0, -16.0, deck_z), color="lightwood", mat="WoodPlanks")
    for k in range(8):
        p.box((3.9, 1.6, 0.06), (0, -2.0 - k * 4.0, deck_z + 0.21), color=WOOD, mat="WoodPlanks", flags=D)
    for k in range(9):
        y = -2.0 - k * 4.0
        for x in (-2.1, 2.1):
            p.rod((x, y, -5.0), (x, y, deck_z + 0.6), 0.28, "darkwood", "Wood", verts=6)
    p.box((9.0, 7.0, 0.4), (0, -35.5, deck_z), color="lightwood", mat="WoodPlanks")
    # a shelter at the end: tall corner posts under a striped awning, with bulbs along the front
    for x in (-4.4, 4.4):
        for y in (-32.2, -35.5, -38.8):
            # the corner posts stop just under the sloping awning
            top = deck_z + (5.3 - 0.6 * (-31.9 - y) / 7.2 - 0.12 if y != -35.5 else 1.8)
            p.rod((x, y, -5.0), (x, y, top), 0.25, "darkwood", "Wood", verts=6)
        p.box((0.2, 7.0, 0.2), (x, -35.5, deck_z + 1.7), color=CREAM, mat="Wood")
    p.box((9.0, 0.2, 0.2), (0, -38.9, deck_z + 1.7), color=CREAM, mat="Wood")
    style.awning(p, -4.7, 4.7, -31.9, -39.1, deck_z + 5.3, deck_z + 4.7, colors=("green", style.STRIPE), stripes=8)
    style.bulbs(p, -4.0, 4.0, -38.6, deck_z + 3.8, 7)
    p.box((4.0, 1.0, 0.25), (-1.8, -37.8, deck_z + 1.2), color=WOOD, mat="WoodPlanks")
    for x in (-3.4, -0.2):
        p.box((0.25, 0.9, 1.0), (x, -37.8, deck_z + 0.7), color="darkwood", mat="Wood")
    p.cyl(0.7, 0.18, (-4.6, -33.0, deck_z + 1.0), (0, 90, 0), color="red", mat="SmoothPlastic", verts=12,
          flags=NOCOLLIDE)
    p.anchor("End", (0, -36.0, deck_z + 0.2))


# ---------------------------------------------------------------- Registan
@prop("DesertFort", "landmark", "Registan: an old desert fort with round towers and a gate")
def desert_fort(p):
    half, h, t = 26.0, 14.0, 3.0
    stone, light = "sandstone", "sandlight"
    # walls: back, sides, and the front either side of the gate
    p.box((2 * half, t, h), (0, half, h / 2), color=stone, mat="Sandstone")
    for x in (-half, half):
        p.box((t, 2 * half, h), (x, 0, h / 2), color=stone, mat="Sandstone")
    gate = 5.0
    seg = half - gate
    for x in (-(gate + seg / 2), gate + seg / 2):
        p.box((seg, t, h), (x, -half, h / 2), color=stone, mat="Sandstone")
    # merlons along the tops
    def merlons(x0, y0, x1, y1, z):
        n = max(2, int(math.hypot(x1 - x0, y1 - y0) / 3.4))
        for k in range(n):
            u = (k + 0.5) / n
            p.box((1.6, 1.6, 1.4), (x0 + (x1 - x0) * u, y0 + (y1 - y0) * u, z), color=light, mat="Sandstone")

    merlons(-half + 4, half, half - 4, half, h + 0.7)
    merlons(-half, -half + 4, -half, half - 4, h + 0.7)
    merlons(half, -half + 4, half, half - 4, h + 0.7)
    merlons(-half + 4, -half, -gate - 1, -half, h + 0.7)
    merlons(gate + 1, -half, half - 4, -half, h + 0.7)
    # four round towers with crenellated tops
    for x in (-half, half):
        for y in (-half, half):
            p.cyl(6.0, 20.0, (x, y, 10.0), color=stone, mat="Sandstone", verts=14)
            p.cyl(6.6, 1.0, (x, y, 20.5), color=light, mat="Sandstone", verts=14)
            for i, a, pos in circle(10, 6.0, 21.7, cx=x, cy=y):
                p.box((1.5, 1.2, 1.4), pos, (0, 0, math.degrees(a)), color=stone, mat="Sandstone")
            p.box((1.2, 0.4, 2.2), (x, y - 6.0 if y < 0 else y + 6.0, 15.0), color="black", mat="Sandstone",
                  flags=NOCOLLIDE)
    # the gate: pillars, lintel, pointed arch and open doors
    for x in (-gate - 1.2, gate + 1.2):
        p.box((2.6, 4.4, h + 3.0), (x, -half, (h + 3.0) / 2), color=light, mat="Sandstone")
    p.box((2 * gate + 5.0, 4.2, 2.7), (0, -half, h + 1.35), color=light, mat="Sandstone")
    for side in (-1, 1):
        p.box((gate * 1.2, 3.2, 1.2), (side * gate * 0.45, -half, h - 1.6), (0, side * 32, 0), color=light,
              mat="Sandstone", flags=NOCOLLIDE)
        p.box((gate - 0.4, 0.5, h - 4.0), (side * (gate + 1.2), -half - 4.2, (h - 4.0) / 2), (0, 0, side * -60),
              color=TEAL, mat="WoodPlanks")
        # painted bands of diamonds along the front wall
        style.diamonds(p, side * 7.7, side * 19.5, -half - 1.58, h - 2.6, height=1.8, band=CREAM)
    style.bulbs(p, -6.0, 6.0, -half - 2.35, h - 0.45, 9)
    # a jharokha balcony over the gate, with teal shutters and a gold finial
    p.box((6.0, 2.2, 3.0), (0, -half - 2.6, h + 4.5), color=light, mat="Sandstone")
    p.box((2.0, 0.1, 1.8), (0, -half - 3.72, h + 4.6), color="darkwood", mat="Wood", flags=D)
    for x in (-1.5, 1.5):
        p.box((1.0, 0.12, 2.0), (x, -half - 3.74, h + 4.6), color=TEAL, mat="WoodPlanks", flags=D)
    p.box((6.6, 2.8, 0.4), (0, -half - 2.6, h + 3.1), color=CREAM, mat="Sandstone")
    p.ball(2.0, (0, -half - 2.6, h + 6.4), color="white", mat="Marble")
    p.ball(0.4, (0, -half - 2.6, h + 8.6), color="gold", mat="Metal")
    # inside: a block of rooms and a well
    p.box((16, 8, 7), (0, half - 5.5, 3.5), color="plaster", mat="Concrete")
    p.box((2.2, 0.2, 3.6), (0, half - 9.6, 1.8), color=TEAL, mat="WoodPlanks")
    p.cyl(2.0, 1.2, (8, -6, 0.6), color="stone", mat="Concrete", verts=12)
    p.cyl(1.5, 0.1, (8, -6, 1.15), color="water", mat="Glass", verts=12, flags=NOCOLLIDE)
    for x in (6.6, 9.4):
        p.rod((x, -6, 1.2), (x, -6, 3.6), 0.12, "darkwood", "Wood")
    p.rod((6.4, -6, 3.5), (9.6, -6, 3.5), 0.12, "darkwood", "Wood")
    # stairs up to the wall walk on the back wall
    for k in range(10):
        p.box((1.4, 3.0, 1.4 * (k + 1)), (-half + 6 + k * 1.4, half - 3.2, 0.7 * (k + 1)), color=stone,
              mat="Sandstone")
    p.anchor("TowerTop", (half - 1.5, half - 1.5, 21.0))
    p.anchor("TowerStand", (half + 1.5, half + 1.5, 21.3))
    p.anchor("TowerBase", (half + 8.0, half, 0))
    p.anchor("Gate", (0, -half - 8.0, 0))


# ------------------------------------------------------------------- Delta
def stilt_hut(p, cx, cy, deck_z, roof_color="thatch", awning=("red", style.STRIPE)):
    for x in (-3.6, 3.6):
        for y in (-3.6, 3.6):
            p.rod((cx + x, cy + y, -2.0), (cx + x, cy + y, deck_z), 0.3, "darkwood", "Wood", verts=6)
    p.box((8.4, 8.4, 0.4), (cx, cy, deck_z + 0.2), color="lightwood", mat="WoodPlanks")
    wz = deck_z + 0.4
    p.box((7.0, 0.3, 3.4), (cx, cy + 3.4, wz + 1.7), color="bamboo", mat="WoodPlanks")
    for x in (-3.4, 3.4):
        p.box((0.3, 7.0, 3.4), (cx + x, cy, wz + 1.7), color="bamboo", mat="WoodPlanks")
    for x in (-2.35, 2.35):
        p.box((2.3, 0.3, 3.4), (cx + x, cy - 3.4, wz + 1.7), color="bamboo", mat="WoodPlanks")
    # a painted door frame and a striped awning over the doorway
    for x in (-1.3, 1.3):
        p.box((0.3, 0.12, 2.8), (cx + x, cy - 3.6, wz + 1.4), color=TEAL, mat="WoodPlanks", flags=D)
    style.awning(p, cx - 1.6, cx + 1.6, cy - 3.6, cy - 4.8, wz + 3.1, wz + 2.6, colors=awning, stripes=4,
                 scallops=False)
    return p.hip_roof((cx, cy, wz + 3.4), 7.0, 7.0, pitch=35, thickness=0.35, overhang=1.0, color=roof_color)


@prop("StiltVillage", "landmark", "Delta: a fishing village of huts on stilts, with walkways and a pier")
def stilt_village(p):
    deck_z = 6.0
    peaks = {}
    for x in (-9, 9):
        for y in (-9, 9):
            peaks[(x, y)] = stilt_hut(p, x, y, deck_z, "thatch" if (x + y) % 4 else "straw",
                                      (("red", "dhabateal")[(x > 0) ^ (y > 0)], style.STRIPE))
    p.box((8.0, 8.0, 0.4), (0, 0, deck_z + 0.2), color="lightwood", mat="WoodPlanks")
    for x in (-3.6, 3.6):
        for y in (-3.6, 3.6):
            p.rod((x, y, -2.0), (x, y, deck_z), 0.3, "darkwood", "Wood", verts=6)
    for x in (-1, 1):
        for y in (-1, 1):
            p.beam((x * 3.6, y * 3.6, deck_z + 0.2), (x * 5.2, y * 5.2, deck_z + 0.2), 2.4, 0.3, WOOD, "WoodPlanks")
    # the pier down to the water
    p.box((2.6, 16.0, 0.3), (0, -12.0, 3.6), (-17, 0, 0), color=WOOD, mat="WoodPlanks")
    for k in range(4):
        y = -6.0 - k * 4.0
        z = deck_z - 0.3 - (k + 0.5) * 1.2
        for x in (-1.3, 1.3):
            p.rod((x, y, -2.0), (x, y, z), 0.22, "darkwood", "Wood", verts=6)
    # nets and drying fish on the middle deck
    p.rod((-2.5, 2.5, deck_z + 0.4), (-2.5, 2.5, deck_z + 3.6), 0.12, "wood", "Wood")
    p.rod((2.5, 2.5, deck_z + 0.4), (2.5, 2.5, deck_z + 3.6), 0.12, "wood", "Wood")
    p.box((5.0, 0.08, 2.6), (0, 2.5, deck_z + 2.2), color="teal", mat="Fabric", flags=NOCOLLIDE)
    for k in range(5):
        p.box((0.25, 0.1, 0.9), (-1.6 + k * 0.8, 2.62, deck_z + 2.6), color="metal", flags=D)
    style.bulbs(p, -2.4, 2.4, 2.1, deck_z + 3.3, 5, light_every=2)
    p.anchor("HutRoof", (9, 9, peaks[(9, 9)] + 0.4))
    p.anchor("HutRoofStand", (7.4, 9, peaks[(9, 9)] - 1.0))
    p.anchor("HutBase", (14.5, 14.5, 0))
    p.anchor("PierEnd", (0, -21.0, 0))


# ------------------------------------------------------------------- Pahar
@prop("SuspensionBridge", "landmark", "Pahar: a rope suspension bridge over the gorge")
def suspension_bridge(p):
    span, width, sag = 60.0, 4.0, 1.4
    half = span / 2
    count = 30
    for k in range(count):
        t = (k + 0.5) / count
        z = -sag * 4 * t * (1 - t)
        p.box((width, span / count + 0.05, 0.3), (0, -half + t * span, z), color="lightwood" if k % 2 else WOOD,
              mat="WoodPlanks")
    for y in (-half, half):
        for x in (-2.8, 2.8):
            p.rod((x, y, -6.0), (x, y, 7.5), 0.45, "darkwood", "Wood", verts=8)
            p.ball(0.55, (x, y, 7.8), "gold", "SmoothPlastic", D, segments=8, rings=5)
        p.box((6.4, 0.7, 0.7), (0, y, 7.0), color=TEAL, mat="Wood")
        out = -1 if y < 0 else 1
        style.diamonds(p, -2.3, 2.3, y + out * 0.42, 7.0, height=0.5, facing=out)
        p.box((7.0, 3.0, 1.0), (0, y + (2.0 if y > 0 else -2.0), -0.42), color="stone", mat="Slate")
    for x in (-2.8, 2.8):
        cable = p.rope((x, -half, 7.2), (x, half, 7.2), 6.5, 0.14, "rope", 12)
        style.flags_along(p, [(x, q.y, q.z) for q in cable[1:12]], x, size=0.7)
        for k in range(1, 12):
            q = cable[k]
            t = k / 12
            p.rod((x * 0.75, q.y, q.z), (x * 0.72, q.y, -sag * 4 * t * (1 - t) + 0.1), 0.05, "rope", "Fabric",
                  NOCOLLIDE, verts=4)
    p.anchor("NearEnd", (0, -half - 3.0, 0))
    p.anchor("FarEnd", (0, half + 3.0, 0))


@prop("MountainHut", "landmark", "Pahar: a stone mountain hut with snow on the roof")
def mountain_hut(p):
    p.box((10, 8, 5.0), (0, 0, 2.5), color="stone", mat="Slate")
    for x in (-5.0, 5.0):
        for y in (-4.0, 4.0):
            for k in range(3):
                p.box((1.0, 1.0, 1.0), (x, y, 0.8 + k * 1.6), color=CREAM, mat="Slate", flags=D)
    style.diamonds(p, -4.4, 4.4, -4.08, 4.45, height=0.5)
    top = p.hip_roof((0, 0, 5.0), 10, 8, pitch=38, thickness=0.45, overhang=0.9, color="slate", mat="Slate")
    p.box((11.2, 3.0, 0.25), (0, -2.4, (5.0 + top) / 2 + 0.3), (38, 0, 0), color="snow", mat="Snow",
          flags=NOCOLLIDE)
    p.box((11.2, 3.0, 0.25), (0, 2.4, (5.0 + top) / 2 + 0.3), (-38, 0, 0), color="snow", mat="Snow",
          flags=NOCOLLIDE)
    p.box((1.4, 1.4, 4.0), (3.0, 1.5, top + 0.2), color="darkstone", mat="Slate")
    p.box((2.4, 0.2, 3.6), (-2.0, -4.02, 1.8), color=CREAM, mat="Wood")
    p.box((1.8, 0.2, 3.2), (-2.0, -4.1, 1.6), color=TEAL, mat="WoodPlanks")
    p.box((1.5, 0.2, 1.3), (2.5, -4.05, 3.0), color="skyblue", mat="Glass")
    p.box((1.9, 0.15, 1.7), (2.5, -4.0, 3.0), color=WOOD, mat="Wood", flags=NOCOLLIDE)
    for dx in (-1.25, 1.25):
        p.box((0.6, 0.12, 1.6), (2.5 + dx, -4.08, 3.0), color=TEAL, mat="WoodPlanks", flags=D)
    for k in range(6):
        p.rod((5.5 + (k % 3) * 0.7 - 0.7, -1.6, 0.3 + (k // 3) * 0.6), (5.5 + (k % 3) * 0.7 - 0.7, 1.6,
              0.3 + (k // 3) * 0.6), 0.3, WOOD, "Wood", verts=6)
    p.box((3.6, 1.0, 0.25), (-2.2, -5.2, 1.3), color=WOOD, mat="WoodPlanks")
    for x in (-3.6, -0.8):
        p.box((0.25, 0.8, 1.2), (x, -5.2, 0.6), color="darkwood", mat="Wood")
    p.ball(0.3, (-0.6, -4.4, 3.6), color="bulb", mat="Neon", flags=LIGHT | NOCOLLIDE)


# -------------------------------------------------------------- Namak Kaan
@prop("CrystalCluster", "landmark", "Namak Kaan: a giant cluster of glowing salt crystals")
def crystal_cluster(p):
    style.rock(p, 2.6, (0, 0, 0.6), (1.2, 1.2, 0.45), color="saltpink", seed=301, mat="Salt")
    style.rock(p, 1.6, (2.9, 1.3, 0.5), color="saltwhite", seed=302, mat="Salt")
    style.rock(p, 1.3, (-2.6, -1.6, 0.4), color="saltpink", seed=303, mat="Salt")
    specs = [(0, 0, 9.0, 0, 0), (1.6, 0.6, 6.5, 22, 0.3), (-1.4, 1.0, 7.0, -20, 1.1), (0.4, -1.6, 5.5, 18, 2.0),
             (-1.2, -1.2, 4.6, -24, 2.6), (2.4, -0.8, 4.0, 28, 3.4), (-2.6, 0.2, 3.6, -30, 4.2)]
    for i, (x, y, h, tilt, a) in enumerate(specs):
        p.box((1.3, 1.3, h), (x, y, h / 2 + 0.6), (tilt * math.cos(a), tilt * math.sin(a), i * 25),
              "crystal" if i % 2 == 0 else "saltpink", "Neon" if i == 0 else "Ice", NOCOLLIDE | (LIGHT if i == 0 else 0))


@prop("MineTrack", "landmark", "Namak Kaan: a 16-stud piece of mine-cart track")
def mine_track(p):
    for x in (-1.2, 1.2):
        p.box((0.3, 16.0, 0.3), (x, 0, 0.45), color="darkmetal", mat="Metal")
    for k in range(8):
        p.box((3.4, 0.6, 0.25), (0, -7.0 + k * 2.0, 0.15), color=WOOD if k % 2 else "darkwood", mat="Wood")


@prop("MineCart", "landmark", "Namak Kaan: a mine cart full of pink salt")
def mine_cart(p):
    p.box((3.0, 4.2, 0.3), (0, 0, 1.2), color="rust", mat="Metal")
    for x in (-1.5, 1.5):
        p.box((0.25, 4.6, 1.8), (x * 1.05, 0, 2.1), (0, x * 6, 0), color=TEAL, mat="Metal")
        style.side_diamonds(p, x * 1.05 + (0.14 if x > 0 else -0.14), -1.6, 1.6, 2.1, height=0.55)
    for y in (-2.2, 2.2):
        p.box((3.4, 0.25, 1.8), (0, y * 1.03, 2.1), (y * -3, 0, 0), color="rust", mat="Metal")
    # a heap of chunky salt
    for i, (x, y, size, turn) in enumerate(((-0.6, -0.9, 1.5, 20), (0.6, 0.2, 1.7, 55), (-0.3, 1.2, 1.4, 35),
                                            (0.5, -1.2, 1.1, 70))):
        p.box((size, size, size * 0.8), (x, y, 2.7), (12, -10, turn), "saltpink" if i % 2 == 0 else "saltwhite",
              "Salt")
    for x in (-1.3, 1.3):
        for y in (-1.4, 1.4):
            p.cyl(0.5, 0.3, (x, y, 0.5), (0, 90, 0), color="darkmetal", mat="Metal", verts=10)


@prop("CaveSupport", "landmark", "Namak Kaan: a timber frame holding up the tunnel, with a dim lamp")
def cave_support(p):
    for x in (-5.0, 5.0):
        p.box((0.8, 0.8, 9.0), (x, 0, 4.0), color="darkwood", mat="Wood")
    p.box((11.0, 0.9, 0.9), (0, 0, 8.6), color="darkwood", mat="Wood")
    style.diamonds(p, -3.6, 3.6, -0.52, 8.6, height=0.55)
    for x in (-1, 1):
        p.beam((x * 5.0, 0, 6.6), (x * 3.0, 0, 8.6), 0.5, 0.5, "wood", "Wood", NOCOLLIDE)
    p.rod((0, 0, 8.1), (0, 0, 7.0), 0.05, "black", "Metal", NOCOLLIDE, verts=4)
    p.ball(0.35, (0, 0, 6.8), color="bulb", mat="Neon", flags=LIGHT | NOCOLLIDE)


@prop("MineEntrance", "landmark", "Namak Kaan: the timber mine entrance; the game writes NAMAK KAAN on the sign")
def mine_entrance(p):
    for x in (-6.5, 6.5):
        p.box((1.4, 1.4, 12.0), (x, 0, 6.0), color="darkwood", mat="Wood")
    p.box((15.0, 1.6, 1.6), (0, 0, 12.4), color="darkwood", mat="Wood")
    style.diamonds(p, -5.6, 5.6, -0.86, 12.4, height=0.8)
    style.signboard(p, 0, -0.97, 14.6, 9.6, 1.9)
    for x in (-3.5, 3.5):
        p.rod((x, -0.7, 13.2), (x, -0.7, 13.4), 0.1, "black", "Metal", NOCOLLIDE, verts=4)
    p.anchor("Sign", (0, -1.11, 14.6))
    for i, (x, y) in enumerate(((-8.8, -2.0), (-9.6, 0.4), (8.8, -1.6))):
        p.cyl(0.9, 2.0, (x, y, 1.0), color=WOOD, mat="Wood", verts=10)
        p.cyl(0.95, 0.15, (x, y, 1.6), color="darkmetal", mat="Metal", verts=10, flags=NOCOLLIDE)
    for i in range(4):
        style.rock(p, 1.0 + (i % 2) * 0.4, (9.6 + (i % 2), 1.6 + i * 0.6, 0.5), color="saltpink", seed=320 + i,
                   mat="Salt")
    style.bulbs(p, -6.2, 6.2, -1.1, 11.0, 9)
