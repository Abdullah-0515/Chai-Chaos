"""Landmarks and buildings for the 12 zones and the Lahore bazaar.

Railway Junction's station and train, Qissa Khawani's clock tower and tall
houses, Lahore Qila's gate, walls and pavilions, Karachi Port's containers,
cranes and ship, Mohenjo-daro's brick ruins and Great Bath, Barfani Pahar's
ice cave and snowmen, the camel fair, plus the petrol pump, zone gates, the
Gaari Showroom, Ustad's Workshop and the bazaar stalls.
"""

import math

from kit import GLASS, LIGHT, NOCOLLIDE, prop

D = NOCOLLIDE


def merlons(p, x0, x1, y, z, size, color, mat="Brick", step=None):
    """A row of battlements from x0 to x1 at height z."""
    step = step or size * 2
    x = x0 + size / 2
    while x <= x1 - size / 2 + 0.01:
        p.box((size, size, size), (x, y, z + size / 2), None, color, mat)
        x += step


def clock(p, pos, rot, radius):
    """A white clock face with black hands, facing along its rotation."""
    p.cyl(radius, 0.3, pos, rot, "white", "SmoothPlastic", D, verts=16)
    p.cyl(radius * 1.12, 0.2, pos, rot, "gold", "Metal", D, verts=16)
    return pos


def dome(p, pos, radius, color="white", mat="Marble", finial="gold"):
    x, y, z = pos
    p.ball(radius, (x, y, z), color, mat, segments=12, rings=7)
    p.cone(radius * 0.15, radius * 0.6, (x, y, z + radius * 1.1), None, finial, "Metal", D, verts=6,
           fallback="Cylinder")


def chhatri(p, pos, size, color="sandstone", dome_color="white"):
    """A small domed pavilion on four pillars."""
    x, y, z = pos
    h = size * 1.2
    for dx in (-1, 1):
        for dy in (-1, 1):
            p.box((size * 0.16, size * 0.16, h), (x + dx * size * 0.4, y + dy * size * 0.4, z + h / 2), None, color,
                  "Sandstone")
    p.box((size, size, size * 0.15), (x, y, z + h + size * 0.075), None, color, "Sandstone")
    dome(p, (x, y, z + h + size * 0.15), size * 0.42, dome_color)


# ------------------------------------------------------------ Railway Junction
@prop("RailwayStation", "zone", "Railway Junction: a red-brick station with arches, a clock and a platform")
def station(p):
    p.box((32, 10, 1.4), (0, -2, 0.7), None, "stone", "Concrete")  # the platform
    p.box((32, 0.4, 0.3), (0, -6.8, 1.45), None, "yellow", "SmoothPlastic", D)
    p.box((20, 8, 9), (0, 4, 1.4 + 4.5), None, "brick", "Brick")
    p.box((21, 9, 0.8), (0, 4, 10.8), None, "slate", "Slate")
    for i in range(5):  # white arches
        x = -8 + i * 4
        p.box((2.6, 0.3, 4.6), (x, -0.1, 3.7), None, "darkwood", "Wood")
        p.box((3.2, 0.4, 0.5), (x, -0.15, 6.3), None, "whitewash", "SmoothPlastic")
    p.box((8, 3, 4), (0, 2, 13.2), None, "brick", "Brick")  # the clock tower
    clock(p, (0, 0.4, 13.4), (90, 0, 0), 1.3)
    p.cone(4.2, 2.4, (0, 2, 16.4), None, "slate", "Slate", verts=4, fallback="Block", fallback_scale=(0.8, 0.8, 1))
    p.box((10, 0.4, 1.6), (0, -0.25, 8.6), None, "maroon", "SmoothPlastic")  # sign board
    p.anchor("Sign", (0, -0.5, 8.6))
    for x in (-12, 12):  # benches and lamps on the platform
        p.box((4, 1.2, 0.3), (x, -2, 2.4), None, "wood", "Wood")
        p.box((4, 0.25, 1.0), (x, -1.4, 3.0), None, "wood", "Wood")
        p.rod((x + 3, -5, 1.4), (x + 3, -5, 6.4), 0.12, "darkmetal", "Metal")
        p.ball(0.45, (x + 3, -5, 6.6), "bulb", "Neon", D | LIGHT)


@prop("Train", "zone", "Railway Junction: a green engine pulling two maroon carriages (it runs the track)")
def train(p):
    # engine at the front (-Y), carriages behind; about 40 studs long
    p.box((7, 12, 7), (0, -12, 4.5), None, "green", "SmoothPlastic")
    p.box((7.2, 12.2, 0.8), (0, -12, 4.0), None, "yellow", "SmoothPlastic", D)
    p.box((6, 0.3, 2.4), (0, -18.1, 6.0), None, "skyblue", "Glass", D | GLASS)
    p.ball(0.7, (0, -18.2, 3.5), "bulb", "Neon", D | LIGHT)
    p.box((7.4, 1.0, 1.0), (0, -18.3, 1.6), None, "red", "Metal")  # cow catcher
    p.cyl(0.8, 2.2, (0, -15.5, 9.0), None, "darkmetal", "Metal", verts=10)  # horn stack
    for k, y in enumerate((2, 15)):
        p.box((7, 11.6, 6.4), (0, y, 4.2), None, "maroon", "SmoothPlastic")
        p.box((7.4, 12, 0.6), (0, y, 7.7), None, "darkmetal", "Metal")
        for side in (-1, 1):
            for i in range(4):
                p.box((0.2, 1.6, 1.4), (side * 3.55, y - 4.2 + i * 2.8, 5.0), None, "glass", "Glass", D | GLASS)
            p.box((0.15, 11.6, 0.4), (side * 3.56, y, 3.0), None, "yellow", "SmoothPlastic", D)
        p.box((2.4, 1.6, 2.4), (0, y - 6.6, 3.8), None, "darkmetal", "Metal", D)  # coupling
    for y in (-16, -8, -2, 6, 11, 19):  # wheels
        for x in (-3.0, 3.0):
            p.cyl(1.0, 0.6, (x, y, 1.0), (0, 90, 0), "darkmetal", "Metal", D, verts=12)


# --------------------------------------------------------------- Qissa Khawani
@prop("GhantaGhar", "zone", "Qissa Khawani: the old clock tower; treasure sits on the gallery at the top")
def ghanta_ghar(p):
    p.box((11, 11, 2), (0, 0, 1), None, "sandstone", "Sandstone")
    p.box((9, 9, 36), (0, 0, 20), None, "brick", "Brick")
    for z in (12, 24):
        p.box((9.6, 9.6, 0.8), (0, 0, z), None, "sandlight", "Sandstone")
    for rot, pos in (((90, 0, 0), (0, -4.6, 30)), ((90, 0, 0), (0, 4.6, 30)), ((0, 90, 0), (4.6, 0, 30)),
                     ((0, 90, 0), (-4.6, 0, 30))):
        clock(p, pos, rot, 2.6)
    p.box((11, 11, 1), (0, 0, 38.5), None, "sandlight", "Sandstone")  # the gallery
    for x in (-5, 5):
        p.box((0.6, 11, 1.4), (x, 0, 39.7), None, "darkwood", "Wood")
        p.box((11, 0.6, 1.4), (0, x, 39.7), None, "darkwood", "Wood")
    chhatri(p, (0, 0, 39), 6, "sandstone", "white")
    p.anchor("Top", (3, 3, 39))


def qissa_house(p, wall, trim, height):
    p.box((14, 12, height), (0, 0, height / 2), None, wall, "Plaster")
    p.box((14.6, 12.6, 0.8), (0, 0, height + 0.4), None, trim, "Wood")
    for floor in range(int(height // 8)):
        z = 3 + floor * 8
        for x in (-4, 0, 4):
            p.box((2.2, 0.3, 3.0), (x, -6.1, z + 1), None, "darkwood", "Wood")
    for z in (8.5, 16.5):  # carved wooden balconies (jharokhas)
        if z < height - 2:
            p.box((13, 3.2, 0.6), (0, -7.4, z), None, trim, "Wood")
            p.box((13, 0.4, 2.2), (0, -8.8, z + 1.4), None, trim, "Wood")
            for i in range(9):
                p.box((0.25, 0.25, 2.2), (-6 + i * 1.5, -8.8, z + 1.4), None, "darkwood", "Wood", D)
            p.box((13.4, 3.6, 0.4), (0, -7.4, z + 3.6), (8, 0, 0), "darkwood", "Wood")
    p.box((3.4, 0.3, 4), (0, -6.1, 2.4), None, "darkwood", "Wood")  # door


@prop("QissaHouseA", "zone", "Qissa Khawani: a tall house with carved wooden balconies")
def qissa_a(p):
    qissa_house(p, "plaster", "darkwood", 20)


@prop("QissaHouseB", "zone", "Qissa Khawani: a taller house with green balconies")
def qissa_b(p):
    qissa_house(p, "sandlight", "green", 24)


@prop("KahwaStall", "zone", "Qissa Khawani: a kahwa stall with a big brass samovar")
def kahwa(p):
    p.box((8, 4, 3), (0, 0, 1.5), None, "wood", "WoodPlanks")
    p.cyl(1.3, 3.2, (-2, 0, 4.6), None, "copper", "Metal", verts=12)
    p.cone(1.3, 1.2, (-2, 0, 6.8), None, "copper", "Metal", verts=12, top=0.3, fallback="Cylinder")
    p.ball(0.4, (-2, 0, 7.6), "gold", "Metal", D)
    p.rod((-2, -1.2, 3.8), (-2, -2.0, 3.6), 0.12, "gold", "Metal", D)
    for x in (0.5, 1.5, 2.5):
        p.cyl(0.3, 0.5, (x, -0.8, 3.25), None, "white", "SmoothPlastic", D, verts=8)
    for x in (-3.6, 3.6):
        p.rod((x, 1.8, 0), (x, 1.8, 7), 0.15, "darkwood", "Wood")
    p.box((9, 5, 0.3), (0, 0.5, 7.2), (-10, 0, 0), "red", "Fabric", D)


@prop("DryFruitStall", "zone", "Qissa Khawani: heaps of almonds, pistachios, raisins and chilgoza")
def dry_fruit(p):
    p.box((10, 4, 2.6), (0, 0, 1.3), None, "wood", "WoodPlanks")
    for x, color in zip((-3.5, -1.2, 1.2, 3.5), ("almond", "pistachio", "maroon", "pinenut")):
        p.cone(1.1, 1.2, (x, -0.2, 3.2), None, color, "SmoothPlastic", D, verts=8, fallback="Ball")
    for x in (-4.6, 4.6):
        p.rod((x, 1.8, 0), (x, 1.8, 6.5), 0.15, "darkwood", "Wood")
    p.box((11, 5, 0.3), (0, 0.4, 6.6), (-10, 0, 0), "orange", "Fabric", D)


# ----------------------------------------------------------------- Lahore Qila
@prop("QilaGate", "zone", "Lahore Qila: the great red gate with two towers; treasure on the walkway")
def qila_gate(p):
    red, dark = "maroon", "rust"
    for x in (-11, 11):
        p.cyl(6, 26, (x, 0, 13), None, red, "Sandstone", verts=12)
        p.cyl(6.4, 1.0, (x, 0, 26.5), None, "sandlight", "Sandstone", verts=12)
        chhatri(p, (x, 0, 27), 5, "sandstone", "white")
    p.box((10, 10, 8), (0, 0, 22), None, red, "Sandstone")  # over the arch
    for x in (-5.5, 5.5):
        p.box((1.6, 10, 18), (x, 0, 9), None, red, "Sandstone")
    p.box((9.4, 10.4, 1.2), (0, 0, 18.6), None, dark, "Sandstone")
    p.cone(4.7, 3.2, (0, -5.0, 16.4), (90, 0, 0), dark, "Sandstone", D, verts=3, fallback="None")  # pointed arch
    p.box((11, 1, 3), (0, -5.3, 23.5), None, "sandlight", "Sandstone")
    for i in range(5):
        p.box((1.2, 1.2, 1.4), (-4.4 + i * 2.2, -5.5, 26.7), None, red, "Sandstone")
    p.anchor("Top", (0, 2, 26))


@prop("QilaWall", "zone", "Lahore Qila: a 24-stud piece of red sandstone fort wall")
def qila_wall(p):
    p.box((24, 5, 15), (0, 0, 7.5), None, "maroon", "Sandstone")
    p.box((24, 5.6, 1), (0, 0, 15.5), None, "sandlight", "Sandstone")
    merlons(p, -12, 12, -2.4, 16, 1.6, "maroon", "Sandstone")
    for x in (-8, 0, 8):
        p.box((1.6, 0.3, 3), (x, -2.6, 9), None, "rust", "Sandstone", D)


@prop("QilaTower", "zone", "Lahore Qila: a round corner tower with a pavilion on top")
def qila_tower(p):
    p.cyl(6.5, 20, (0, 0, 10), None, "maroon", "Sandstone", verts=12)
    p.cyl(7, 1, (0, 0, 20.5), None, "sandlight", "Sandstone", verts=12)
    chhatri(p, (0, 0, 21), 6, "sandstone", "white")


@prop("Chhatri", "zone", "Lahore Qila: a white domed pavilion on a platform")
def big_chhatri(p):
    p.box((14, 14, 2), (0, 0, 1), None, "sandlight", "Sandstone")
    chhatri(p, (0, 0, 2), 11, "white", "white")


# ---------------------------------------------------------------- Karachi Port
def container(p, color):
    p.box((8, 20, 8), (0, 0, 4), None, color, "Metal")
    for i in range(9):
        p.box((8.2, 0.3, 7.4), (0, -9 + i * 2.25, 4), None, color, "Metal", D)
    p.box((7.6, 0.2, 7.4), (0, -10.05, 4), None, "darkmetal", "Metal", D)
    for x in (-1.5, 1.5):
        p.rod((x, -10.2, 0.5), (x, -10.2, 7.5), 0.1, "metal", "Metal", D)


@prop("ContainerRed", "zone", "Karachi Port: a red shipping container")
def container_red(p):
    container(p, "red")


@prop("ContainerBlue", "zone", "Karachi Port: a blue shipping container")
def container_blue(p):
    container(p, "blue")


@prop("ContainerYellow", "zone", "Karachi Port: a yellow shipping container")
def container_yellow(p):
    container(p, "orange")


@prop("ContainerGreen", "zone", "Karachi Port: a green shipping container")
def container_green(p):
    container(p, "green")


@prop("PortCrane", "zone", "Karachi Port: a giant yellow crane; treasure sits in its cab")
def crane(p):
    for x in (-7, 7):
        for y in (-5, 5):
            p.box((1.6, 1.6, 34), (x, y, 17), None, "yellow", "Metal")
        p.box((1.4, 11.6, 1.4), (x, 0, 12), None, "yellow", "Metal")
    p.box((17, 13, 2.4), (0, 0, 35), None, "yellow", "Metal")
    p.box((3, 46, 2.4), (0, -12, 38), None, "yellow", "Metal")  # the arm, out over the water
    p.box((5, 5, 4), (0, 3, 39), None, "white", "SmoothPlastic")  # cab
    p.box((4.6, 0.2, 2), (0, 0.45, 39.5), None, "skyblue", "Glass", D | GLASS)
    p.rod((0, -30, 37), (0, -30, 20), 0.15, "black", "Metal", D)
    p.box((3, 3, 1.2), (0, -30, 19.5), None, "red", "Metal", D)
    p.anchor("Top", (0, 3, 41.2))


@prop("CargoShip", "zone", "Karachi Port: a cargo ship stacked with containers")
def ship(p):
    p.box((16, 56, 8), (0, 0, 4), None, "darkmetal", "Metal")
    p.box((16.4, 56.4, 1.6), (0, 0, 1.2), None, "red", "Metal")
    p.cone(8, 10, (0, -32, 4), (90, 0, 0), "darkmetal", "Metal", verts=4, fallback="Block",
           fallback_scale=(0.7, 0.7, 1))
    p.box((14, 10, 10), (0, 20, 13), None, "white", "SmoothPlastic")  # bridge
    p.box((14.2, 0.3, 2), (0, 14.9, 15.5), None, "skyblue", "Glass", D | GLASS)
    p.cyl(1.6, 6, (0, 23, 21), None, "red", "Metal", verts=10)
    colors = ("red", "blue", "orange", "green")
    for i in range(6):
        for j in range(2):
            p.box((6.6, 7.6, 3.6), (-3.4 + j * 6.8, -20 + i * 6.4, 9.8), None, colors[(i + j) % 4], "Metal")


# ---------------------------------------------------------------- Mohenjo-daro
@prop("RuinWallA", "zone", "Mohenjo-daro: a broken brick wall")
def ruin_a(p):
    for i, h in enumerate((5, 7, 6, 3, 4.5)):
        p.box((3, 3, h), (-6 + i * 3, 0, h / 2), None, "brick", "Brick")
    p.box((2, 2, 1.2), (8, 1.5, 0.6), None, "brick", "Brick")


@prop("RuinWallB", "zone", "Mohenjo-daro: the corner of an old brick house")
def ruin_b(p):
    for i, h in enumerate((4, 6, 5.5, 2.5)):
        p.box((3, 3, h), (-4.5 + i * 3, 0, h / 2), None, "brick", "Brick")
    for i, h in enumerate((5, 3.5, 4)):
        p.box((3, 3, h), (-4.5, 3 + i * 3, h / 2), None, "brick", "Brick")


@prop("GreatBath", "zone", "Mohenjo-daro: the Great Bath, a brick pool with steps at both ends")
def great_bath(p):
    p.box((36, 26, 2.4), (0, 0, 1.2), None, "brick", "Brick")
    p.box((30, 20, 0.4), (0, 0, 1.6), None, "water", "Glass", D | GLASS)
    for y in (-11.5, 11.5):
        for k in range(3):
            p.box((8, 1.2, 0.8 + k * 0.6), (0, y + (k - 1) * (1 if y < 0 else -1) * 0.01, 2.4 + k * 0.6), None,
                  "brick", "Brick")
    for x in (-18.5, 18.5):
        p.box((1, 26, 3.4), (x, 0, 1.7), None, "brick", "Brick")


@prop("RuinMound", "zone", "Mohenjo-daro: the high brick citadel mound; treasure on top")
def mound(p):
    for k, (w, h) in enumerate(((30, 6), (22, 5), (14, 5))):
        z = sum(hh for _, hh in ((30, 6), (22, 5), (14, 5))[:k])
        p.box((w, w, h), (0, 0, z + h / 2), None, "brick" if k % 2 == 0 else "claydark", "Brick")
    p.anchor("Top", (0, 0, 16))


# --------------------------------------------------------------- Barfani Pahar
@prop("IceCave", "zone", "Barfani Pahar: an ice cave you can walk through; treasure on the roof")
def ice_cave(p):
    for x in (-11, 11):
        p.box((5, 24, 14), (x, 0, 7), None, "ice", "Ice")
    p.box((27, 24, 5), (0, 0, 16.5), None, "ice", "Ice")
    p.box((27.5, 24.5, 1.4), (0, 0, 19.6), None, "snow", "Snow")
    for i in range(7):
        p.cone(0.6, 2.4, (-7 + i * 2.3, -11, 12.8), (180, 0, 0), "crystal", "Glass", D | GLASS, verts=5,
               fallback="None")
    p.anchor("Top", (0, 0, 20.3))


@prop("Snowman", "zone", "Barfani Pahar: a snowman with a carrot nose and a warm scarf")
def snowman(p):
    p.ball(3, (0, 0, 2.8), "snow", "Snow", segments=12, rings=8)
    p.ball(2.1, (0, 0, 6.8), "snow", "Snow", segments=12, rings=8)
    p.cone(0.3, 1.4, (0, -2.6, 7.0), (90, 0, 0), "orange", "SmoothPlastic", D, verts=6, fallback="None")
    for x in (-0.7, 0.7):
        p.ball(0.25, (x, -1.9, 7.6), "black", "SmoothPlastic", D)
    p.cyl(2.2, 0.8, (0, 0, 5.2), None, "red", "Fabric", D, verts=12)
    p.box((0.8, 0.4, 2.2), (1.2, -1.9, 4.2), None, "red", "Fabric", D)
    p.cyl(1.4, 0.3, (0, 0, 8.7), None, "black", "SmoothPlastic", D, verts=12)
    p.cyl(1.0, 1.6, (0, 0, 9.6), None, "black", "SmoothPlastic", D, verts=12)


# ------------------------------------------------------------------ Camel Mela
@prop("Camel", "zone", "A camel in a colourful saddle cloth with tassels")
def camel(p):
    p.blob(2.2, (0, 0.5, 5.0), (0.75, 1.5, 0.7), "sandlight", "SmoothPlastic", D, seed=301, jitter=0.03,
           fallback="Block", fallback_scale=(0.8, 0.85, 0.8))
    p.blob(1.3, (0, 0.8, 6.6), (0.8, 1.1, 0.9), "sandlight", "SmoothPlastic", D, seed=302, fallback="Ball")
    p.rod((0, -2.2, 5.6), (0, -3.4, 8.6), 0.6, "sandlight", "SmoothPlastic", D)
    p.blob(0.9, (0, -4.0, 8.9), (0.7, 1.4, 0.7), "sandlight", "SmoothPlastic", D, seed=303, fallback="Ball")
    for x in (-0.95, 0.95):
        for y in (-1.8, 2.6):
            p.rod((x, y, 4.0), (x, y, 0.2), 0.32, "sandlight", "SmoothPlastic", D)
    p.box((3.4, 3.4, 0.3), (0, 0.6, 7.4), None, "red", "Fabric", D)
    p.box((3.5, 3.0, 1.6), (0, 0.6, 6.4), None, "red", "Fabric", D)
    for i, color in enumerate(("yellow", "green", "blue", "pink", "yellow")):
        p.ball(0.22, (-1.75, -0.6 + i * 0.6, 5.5), color, "SmoothPlastic", D, segments=6, rings=4)
        p.ball(0.22, (1.75, -0.6 + i * 0.6, 5.5), color, "SmoothPlastic", D, segments=6, rings=4)
    for x in (-0.35, 0.35):
        p.ball(0.15, (x, -4.9, 9.2), "black", "SmoothPlastic", D)


@prop("MelaTent", "zone", "Camel Mela: a striped fair tent with bunting and a flag")
def mela_tent(p):
    colors = ("red", "yellow", "red", "yellow", "red", "yellow", "red", "yellow")
    for i, color in enumerate(colors):
        a = i * math.pi / 4
        p.box((5.4, 0.3, 8), (math.cos(a) * 6.4, math.sin(a) * 6.4, 4), (0, 0, math.degrees(a) + 90), color,
              "Fabric")
    p.cone(8.6, 6, (0, 0, 10.8), None, "white", "Fabric", verts=8, fallback="Cylinder",
           fallback_scale=(0.9, 0.9, 0.3))
    p.rod((0, 0, 13.6), (0, 0, 17), 0.15, "darkwood", "Wood", D)
    p.box((2.2, 0.1, 1.2), (1.1, 0, 16.4), None, "green", "Fabric", D)
    p.box((4, 0.3, 6.2), (0, -6.5, 3.1), None, "maroon", "Fabric", D)  # the door flap


@prop("Scarecrow", "zone", "Sarson Fields: a scarecrow in a kurta and a turban")
def scarecrow(p):
    p.rod((0, 0, 0), (0, 0, 8), 0.2, "darkwood", "Wood")
    p.rod((-3, 0, 5.6), (3, 0, 5.6), 0.15, "darkwood", "Wood")
    p.box((2.6, 1.2, 3.4), (0, 0, 4.4), None, "skyblue", "Fabric", D)
    p.box((6, 0.8, 0.8), (0, 0, 5.6), None, "skyblue", "Fabric", D)
    p.ball(1.0, (0, 0, 7.0), "straw", "Fabric", D, segments=8, rings=5)
    p.cyl(1.1, 0.8, (0, 0, 7.8), None, "orange", "Fabric", D, verts=10)
    for x in (-0.35, 0.35):
        p.ball(0.12, (x, -0.95, 7.1), "black", "SmoothPlastic", D)


# ------------------------------------------------------- Bazaar and the roads
@prop("PetrolPump", "zone", "A petrol pump with a canopy and two pumps; the game writes PETROL on it")
def petrol_pump(p):
    p.box((16, 12, 0.4), (0, 0, 0.2), None, "stone", "Concrete")
    for x in (-6.5, 6.5):
        for y in (-4.5, 4.5):
            p.box((0.8, 0.8, 9), (x, y, 4.7), None, "white", "SmoothPlastic")
    p.box((16, 12, 1.2), (0, 0, 9.8), None, "green", "SmoothPlastic")
    p.box((16.2, 12.2, 0.4), (0, 0, 9.2), None, "white", "SmoothPlastic", D)
    p.box((8, 0.3, 1.6), (0, -6.2, 9.8), None, "white", "SmoothPlastic", D)
    p.anchor("Sign", (0, -6.4, 9.8))
    for x in (-3, 3):
        p.box((1.6, 1.0, 3.6), (x, 0, 2.2), None, "red", "SmoothPlastic")
        p.box((1.2, 0.2, 1.0), (x, -0.55, 3.2), None, "black", "SmoothPlastic", D)
        p.box((1.0, 0.1, 0.5), (x, -0.62, 3.2), None, "lime", "Neon", D)
        p.rod((x + 0.8, -0.3, 2.8), (x + 1.2, -0.8, 1.2), 0.08, "black", "SmoothPlastic", D)
    p.ball(0.6, (0, 0, 9.0), "bulb", "Neon", D | LIGHT)


@prop("ZoneGate", "zone", "The arch over a zone's gate (30 studs wide); the game writes the zone and its price")
def zone_gate(p):
    for x in (-16.5, 16.5):
        p.box((3, 3, 20), (x, 0, 10), None, "sandstone", "Sandstone")
        p.box((3.6, 3.6, 1), (x, 0, 20.5), None, "sandlight", "Sandstone")
        dome(p, (x, 0, 21), 1.6, "gold", "Metal", "red")
    p.box((36, 3, 3), (0, 0, 22.5), None, "sandstone", "Sandstone")
    p.box((22, 0.4, 3.2), (0, -1.7, 18.4), None, "maroon", "SmoothPlastic", D)
    p.box((22, 0.4, 3.2), (0, 1.7, 18.4), None, "maroon", "SmoothPlastic", D)
    p.anchor("Sign", (0, -1.95, 18.4))
    p.anchor("SignBack", (0, 1.95, 18.4))
    for i, color in enumerate(("red", "yellow", "green", "blue", "pink", "orange", "red", "yellow", "green")):
        p.box((1.2, 0.1, 1.2), (-12 + i * 3, -1.8, 20.6), (0, 45, 0), color, "Fabric", D)


@prop("Showroom", "zone", "The Gaari Showroom at the Rickshaw Stand; the game writes its name")
def showroom(p):
    p.box((26, 16, 0.6), (0, 0, 0.3), None, "white", "Marble")
    p.box((26, 1, 11), (0, 7.5, 6), None, "white", "SmoothPlastic")
    for x in (-12.5, 12.5):
        p.box((1, 16, 11), (x, 0, 6), None, "white", "SmoothPlastic")
    p.box((24, 0.3, 9), (0, -7.6, 5), None, "skyblue", "Glass", D | GLASS)
    p.box((5, 0.4, 8), (0, -7.7, 4.4), None, "darkmetal", "Metal", D)
    p.box((27, 17, 1), (0, 0, 12), None, "blue", "SmoothPlastic")
    p.box((18, 0.4, 2.6), (0, -8.6, 13.6), None, "blue", "SmoothPlastic")
    p.anchor("Sign", (0, -8.85, 13.6))
    p.cyl(4.5, 0.6, (0, 1.5, 0.9), None, "gold", "Metal", D, verts=16)  # the turntable
    for x in (-10, 10):
        p.ball(0.5, (x, -8.2, 11.4), "bulb", "Neon", D | LIGHT)


@prop("Workshop", "zone", "Ustad's Workshop in the Chai Dhaba Bazaar; the game writes its name")
def workshop(p):
    p.box((22, 14, 0.4), (0, 0, 0.2), None, "darkstone", "Concrete")
    p.box((22, 1, 9), (0, 6.5, 4.5), None, "brick", "Brick")
    for x in (-10.5, 10.5):
        p.box((1, 14, 9), (x, 0, 4.5), None, "brick", "Brick")
    p.box((23, 15, 0.6), (0, 0, 9.3), (-4, 0, 0), "tin", "Metal")
    p.box((16, 0.4, 2.4), (0, -7.6, 10.4), None, "yellow", "SmoothPlastic")
    p.anchor("Sign", (0, -7.85, 10.4))
    for k in range(4):  # a stack of tyres
        p.cyl(1.4, 0.8, (-7.5, -3, 0.8 + k * 0.85), None, "tyre", "SmoothPlastic", verts=12)
    for x in (6, 8):  # oil drums
        p.cyl(1.0, 2.6, (x, 4, 1.7), None, "blue" if x == 6 else "red", "Metal", verts=10)
    p.box((8, 0.3, 4), (0, 5.9, 5), None, "darkwood", "Wood")  # tool board
    for i in range(6):
        p.box((0.3, 0.2, 1.6), (-3 + i * 1.2, 5.7, 5), None, "metal", "Metal", D)
    p.box((5, 2.4, 0.6), (3, 0, 0.7), None, "darkmetal", "Metal")  # car lift


def bazaar_stall(p, awning):
    p.box((7, 4, 3), (0, 0, 1.5), None, "wood", "WoodPlanks")
    for x in (-3.3, 3.3):
        p.rod((x, 1.8, 0), (x, 1.8, 8.5), 0.15, "darkwood", "Wood")
        p.rod((x, -1.8, 0), (x, -1.8, 6.5), 0.15, "darkwood", "Wood")
    p.box((8, 5.6, 0.3), (0, 0, 7.6), (-20, 0, 0), awning, "Fabric", D)
    for i in range(5):
        p.box((1.6, 0.3, 0.6), (-3.2 + i * 1.6, -2.75, 6.5), None, "white" if i % 2 else awning, "Fabric", D)
    for i, color in enumerate(("orange", "red", "yellow", "green")):
        p.ball(0.5, (-2.4 + i * 1.6, -0.6, 3.4), color, "SmoothPlastic", D, segments=6, rings=4)


@prop("BazaarStallRed", "zone", "A bazaar stall with a red awning")
def stall_red(p):
    bazaar_stall(p, "red")


@prop("BazaarStallGreen", "zone", "A bazaar stall with a green awning")
def stall_green(p):
    bazaar_stall(p, "green")


@prop("BazaarStallBlue", "zone", "A bazaar stall with a blue awning")
def stall_blue(p):
    bazaar_stall(p, "blue")


@prop("BazaarStallYellow", "zone", "A bazaar stall with a yellow awning")
def stall_yellow(p):
    bazaar_stall(p, "yellow")


@prop("FerrisWheel", "zone", "Mela Ground: a big Ferris wheel with coloured cabins")
def ferris_wheel(p):
    cz, r = 17, 13
    rim = [(math.cos(a) * r, 0, cz + math.sin(a) * r) for a in (i * 2 * math.pi / 16 for i in range(16))]
    for k, (a, b) in enumerate(zip(rim, rim[1:] + rim[:1])):
        p.rod(a, b, 0.35, "pink" if k % 2 else "yellow", "Metal", D, verts=6)
    for i in range(0, 16, 2):
        p.rod((0, 0, cz), rim[i], 0.18, "white", "Metal", D, verts=4)
    for i in range(1, 16, 2):
        x, _, z = rim[i]
        p.box((2.2, 2.0, 2.0), (x, 0, z - 1.6), None, ("red", "teal", "orange", "purple")[(i // 2) % 4],
              "SmoothPlastic", D)
    p.cyl(1.2, 1.6, (0, 0, cz), (90, 0, 0), "gold", "Metal", D, verts=10)
    for side in (-1, 1):
        p.rod((0, side * 1.2, cz), (side * 8, side * 1.2, 0), 0.5, "white", "Metal")
        p.rod((0, side * 1.2, cz), (-side * 8, side * 1.2, 0), 0.5, "white", "Metal")
    p.box((18, 5, 1), (0, 0, 0.5), None, "darkstone", "Concrete")


@prop("KiteTower", "zone", "Kite Point: a rooftop tower with kites flying from it")
def kite_tower(p):
    p.box((12, 12, 18), (0, 0, 9), None, "whitewash", "Plaster")
    p.box((13, 13, 1), (0, 0, 18.5), None, "sandlight", "Sandstone")
    for x in (-6, 6):
        p.box((0.5, 13, 1.4), (x, 0, 19.7), None, "darkwood", "Wood")
        p.box((13, 0.5, 1.4), (0, x, 19.7), None, "darkwood", "Wood")
    colors = ("red", "yellow", "green", "blue", "pink")
    for i, color in enumerate(colors):
        a = i * 1.25
        kx, ky, kz = math.cos(a) * 9, math.sin(a) * 9, 30 + (i % 3) * 3
        p.box((2.4, 0.15, 2.4), (kx, ky, kz), (0, 45, math.degrees(a)), color, "Fabric", D)
        p.rod((0, 0, 20), (kx, ky, kz - 1.2), 0.04, "white", "SmoothPlastic", D, verts=4)


@prop("MelaStage", "zone", "Mela Ground: a stage with bright curtains")
def mela_stage(p):
    p.box((24, 12, 4), (0, 0, 2), None, "purple", "WoodPlanks")
    for x in (-11, 11):
        p.rod((x, 5, 4), (x, 5, 14), 0.4, "gold", "Metal")
        p.box((3, 0.3, 9), (x * 0.9, 5.4, 8.6), None, "red", "Fabric", D)
    p.box((24, 1, 1.4), (0, 5, 14.4), None, "gold", "Metal")
    for i in range(8):
        p.ball(0.4, (-10.5 + i * 3, 4.4, 13.6), ("red", "yellow", "green", "blue")[i % 4], "Neon", D)
