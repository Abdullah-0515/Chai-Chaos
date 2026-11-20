"""Brainrot models, part 3: the Legendaries, Mythics and Collection Book specials."""

import math

import style
from brainrot_kit import block_arm, block_cap, block_leg, chunk, cube_puff, D, Frame, arm, blush, brows, cap, crown, eyes, leg, moustache, puffs, rope_ring, smile, wing
from kit import GLASS, KEEP, LIGHT, PARTSONLY, prop


def wheel_x(p, x, y, z, r, tyre="tyre", hub="metal", spokes=4, width=0.2):
    """A wheel turning about the X axis."""
    p.cyl(r, width, (x, y, z), (0, 90, 0), tyre, "SmoothPlastic", D, verts=16)
    p.cyl(r * 0.25, width + 0.05, (x, y, z), (0, 90, 0), hub, "Metal", D, verts=8)
    for k in range(spokes):
        p.box((0.05, r * 1.85, 0.05), (x, y, z), (k * 180 / spokes, 0, 0), hub, "Metal", D)


# --------------------------------------------------------------- Legendaries
@prop("TruckArtTotaa", "brainrot")
def truck_art_parrot(p):
    # a green parrot painted with truck art, bells on its wings and a crown crest.
    # A chunky body with square painted flowers; its head stays round.
    chunk(p, 1.25, (0, 0.15, 2.5), (0.95, 1, 1.05), "parrot", seed=200)
    p.blob(0.88, (0, -0.25, 4.25), (1, 1, 1), "parrot", "SmoothPlastic", D, seed=201, jitter=0.02, fallback="Ball")
    p.box((0.5, 0.6, 0.4), (0, -1.15, 4.05), (-30, 0, 0), "orange", "SmoothPlastic", D)  # the beak
    p.box((0.34, 0.4, 0.3), (0, -1.35, 3.85), (-50, 0, 0), "orange", "SmoothPlastic", D)
    eyes(p, 0, -1.05, 4.45, 0.7, 0.24)
    p.box((1.5, 0.3, 0.95), (0, -0.05, 5.05), (-10, 0, 0), "red", "WoodPlanks", D)
    p.box((1.6, 0.32, 0.2), (0, -0.05, 5.5), (-10, 0, 0), "gold", "Metal", D)
    for k, color in enumerate(("yellow", "skyblue", "pink")):
        p.box((0.22, 0.1, 0.22), (-0.45 + k * 0.45, -0.25, 5.05), (0, 45, 0), color, "SmoothPlastic", D)
    flowers = [("red", -0.4, 2.9), ("yellow", 0.4, 2.6), ("blue", 0.0, 2.1), ("pink", -0.45, 1.85), ("yellow", 0.45, 3.3)]
    for color, x, z in flowers:  # painted square flowers
        p.box((0.42, 0.06, 0.42), (x, -1.03, z), (0, 45, 0), color, "SmoothPlastic", D)
        p.box((0.3, 0.07, 0.3), (x, -1.04, z), None, color, "SmoothPlastic", D)
        p.box((0.14, 0.08, 0.14), (x, -1.06, z), None, "white", "SmoothPlastic", D)
    for side in (-1, 1):
        with p.rigged("wingL" if side < 0 else "wingR", (side * 1.05, 0.25, 3.4)):
            p.box((0.28, 1.3, 1.8), (side * 1.2, 0.25, 2.7), (0, side * -10, 0), "blue", "SmoothPlastic", D)
            for k, color in enumerate(("red", "yellow", "green")):
                p.box((0.06, 1.2, 0.18), (side * 1.35, 0.25, 2.1 + k * 0.5), (0, side * -10, 0), color, "SmoothPlastic", D)
            for k in range(4):
                p.ball(0.12, (side * 1.38, -0.2 + k * 0.32, 1.7), "gold", "Metal", D, segments=6, rings=4)
        with p.rigged("legLF" if side < 0 else "legRF", (side * 0.35, 0, 1.3)):
            p.box((0.25, 0.5, 0.2), (side * 0.4, -0.3, 0.1), None, "orange", "SmoothPlastic", D)
            p.beam((side * 0.35, 0, 1.3), (side * 0.4, -0.2, 0.15), 0.2, 0.2, "orange", "SmoothPlastic", D)
    for k, color in enumerate(("yellow", "red", "blue")):  # the tail, with its lettering panel
        p.box((0.45, 0.12, 2.2), (-0.45 + k * 0.45, 1.5, 1.2), (35, 0, (k - 1) * 8), color, "SmoothPlastic", D)
    p.box((1.3, 0.1, 0.45), (0, 1.62, 1.0), (35, 0, 0), "white", "SmoothPlastic", D)
    p.anchor("Tail", (0, 1.661, 1.029))  # on the face of the lettering panel


@prop("SixerSher", "brainrot")
def sixer_sher(p):
    # a street-cricket lion with a taped bat on its shoulder and a taped tennis ball.
    # Chunky style: a round head and face, a block body in a red jersey with a gold
    # band of diamonds, a faceted spiky mane, block arms and legs, a blocky cap.
    p.box((2.5, 2.2, 2.0), (0, 0.1, 2.3), None, "red", "Fabric", D)  # the body, in its jersey
    p.box((1.75, 1.75, 2.2), (0, 0.1, 2.3), (0, 0, 45), "red", "Fabric", D)
    p.box((2.56, 2.26, 0.22), (0, 0.1, 3.2), None, "white", "Fabric", D)  # the collar
    style.diamonds(p, -1.1, 1.1, -1.03, 2.35, height=0.42, band="gold", colors=("dhabateal", "white"))
    # the mane: a flat back with spikes all round the head
    p.box((2.1, 0.6, 2.1), (0, 0.45, 4.05), (0, 45, 0), "mane", "SmoothPlastic", D)
    for i in range(8):
        a = i * math.pi / 4
        p.box((0.75, 0.7, 0.75), (math.cos(a) * 1.15, 0.15, 4.05 + math.sin(a) * 1.15), (0, 45 + i * 45, 0),
              "mane" if i % 2 else "orange", "SmoothPlastic", D)
    p.ball(1.0, (0, -0.35, 4.0), "lion", "SmoothPlastic", D, segments=14, rings=8)
    p.blob(0.5, (0, -1.15, 3.7), (1.2, 0.7, 0.8), "cream2", "SmoothPlastic", D, seed=212, fallback="Ball")
    p.ball(0.15, (0, -1.5, 3.85), "pakoradark", "SmoothPlastic", D)
    for side in (-1, 1):
        p.ball(0.28, (side * 0.75, -0.3, 4.8), "lion", "SmoothPlastic", D)
    eyes(p, 0, -1.25, 4.2, 0.7, 0.24)
    brows(p, 0, -1.25, 4.2, 0.7, 0.24, "mane", tilt=12)
    smile(p, 0, -1.55, 3.55, 0.45)
    block_cap(p, 0, -0.2, 4.95, 0.55, "blue", "navy", backwards=True, band="gold")
    for side in (-1, 1):
        block_leg(p, side * 0.5, 0.1, 1.0, 0.5, "lion", "white")
    block_arm(p, (1.25, 0, 2.8), (0.9, -0.6, 3.6), 0.36, "lion", "lion", 0.5)
    with p.rigged("armR"):  # the bat on its shoulder
        p.box((0.55, 0.18, 2.3), (0.85, 0.3, 4.1), (0, 0, 35), "willow", "Wood", D)
        p.cyl(0.13, 0.9, (0.25, -0.55, 3.15), (0, -35, 0), "black", "Fabric", D, verts=8)
        for k, color in enumerate(("black", "red", "black")):
            p.box((0.58, 0.2, 0.12), (1.0 + k * 0.25, 0.3, 4.3 + k * 0.35), (0, 0, 35), color, "Fabric", D)
    block_arm(p, (-1.25, 0, 2.8), (-1.6, -0.6, 2.4), 0.36, "lion", "lion", 0.5)
    with p.rigged("armL"):  # the sweatband and ball
        p.box((0.38, 0.38, 0.38), (-1.62, -0.62, 2.88), None, "red", "Fabric", D)  # a sweatband
        p.ball(0.3, (-1.65, -0.95, 2.45), "tennisball", "Fabric", D)
        p.cyl(0.31, 0.12, (-1.65, -0.95, 2.45), (30, 0, 0), "black", "Fabric", D, verts=10)
    with p.rigged("tail", (0, 1.1, 1.5)):
        p.beam((0, 1.1, 1.5), (0, 2.0, 1.8), 0.2, 0.2, "lion", "SmoothPlastic", D)
        p.box((0.45, 0.45, 0.45), (0, 2.1, 1.85), (45, 35.26, 0), "mane", "SmoothPlastic", D)


@prop("ChilgozaChachaChipka", "brainrot")
def chilgoza(p):
    # a pine-nut uncle clinging to a spinning ceiling fan, moustache blown sideways.
    # A chunky nut body, block arms, a square fan hub, red and teal diamonds painted
    # on the blades.
    hub = (0, 0, 5.2)
    p.box((0.2, 0.2, 1.0), (0, 0, 5.9), None, "white", "Metal", D)
    p.box((0.8, 0.8, 0.15), (0, 0, 6.45), (0, 0, 45), "white", "Metal", D)
    p.box((1.0, 1.0, 0.5), hub, (0, 0, 22), "white", "Metal", D)
    for k in range(3):
        a = k * 2 * math.pi / 3 + 0.4
        p.box((2.6, 0.65, 0.08), (math.cos(a) * 1.6, math.sin(a) * 1.6, 5.05), (8, 0, math.degrees(a)), "tin", "Metal",
              D)
        p.box((0.36, 0.36, 0.1), (math.cos(a) * 2.2, math.sin(a) * 2.2, 5.0), (8, 0, math.degrees(a) + 45),
              "red" if k % 2 else "dhabateal", "SmoothPlastic", D)
    f = Frame((1.55, -0.55, 3.75), (0, -15, 20))
    chunk(p, 0.62, (0, 0, 0), (0.8, 0.8, 1.9), "pinenut", seed=220, f=f)
    p.cone(0.25, 0.5, f.p(0, 0, -1.25), f.r((180, 0, 0)), "pinenut", "SmoothPlastic", D, verts=8,
           fallback="None")
    p.box((0.34, 0.34, 0.4), f.p(0, 0, -1.25), f.r((0, 0, 45)), "pinenut", "SmoothPlastic", D | PARTSONLY)
    eyes(p, 0, -0.47, 0.45, 0.5, 0.2, f=f)
    brows(p, 0, -0.47, 0.45, 0.5, 0.2, tilt=-15, f=f)
    for k in range(2):  # moustache blown sideways by the wind
        p.box((0.75, 0.2, 0.2), f.p(0.35 + k * 0.1, -0.52, 0.05 + k * 0.12), f.r((0, -20 - k * 15, 0)), "black",
              "SmoothPlastic", D)
    smile(p, 0, -0.52, -0.2, 0.3, f=f, open_mouth=True)
    block_arm(p, (-0.5, 0, 0.5), (-0.2, 0.3, 1.25), 0.2, "pinenut", f=f, still=True)
    block_arm(p, (0.5, 0, 0.5), (0.35, 0.3, 1.25), 0.2, "pinenut", f=f, still=True)
    for k, z in enumerate((2.3, 1.55, 0.6)):  # dripping honey
        s = 0.32 - k * 0.05
        p.box((s, s, s), (1.45, -0.6, z), (45, 35.26, 0), "honey", "Glass", D | GLASS)


@prop("MelaMaharaja", "brainrot")
def mela_maharaja(p):
    # a laughing Ferris wheel king with a crown, cabins and light bulbs. Square rim
    # and spokes like the Mela Ground's wheel; his round face stays round.
    cz, r = 3.4, 2.4
    rim = [(math.cos(a) * r, 0, cz + math.sin(a) * r) for a in (i * 2 * math.pi / 16 for i in range(16))]
    for k, (a, b) in enumerate(zip(rim, rim[1:] + rim[:1])):
        p.beam(a, b, 0.24, 0.24, "pink" if k % 2 else "yellow", "SmoothPlastic", D)
    for i in range(0, 16, 2):
        p.beam((0, 0, cz), rim[i], 0.12, 0.12, "white", "Metal", D)
    for i in range(16):
        x, _, z = rim[i]
        p.ball(0.12, (x, -0.16, z), ("yellow", "pink", "skyblue", "lime")[i % 4], "Neon", D | KEEP | (LIGHT if i == 0 else 0),
               segments=6, rings=4)
    for i in range(1, 16, 2):
        x, _, z = rim[i]
        p.box((0.45, 0.4, 0.4), (x, 0, z - 0.35), None, ("red", "teal", "orange", "purple")[(i // 2) % 4], "SmoothPlastic",
              D)
        p.box((0.55, 0.45, 0.1), (x, 0, z - 0.1), None, "white", "SmoothPlastic", D)
        p.box((0.5, 0.06, 0.1), (x, -0.22, z - 0.3), None, "gold", "SmoothPlastic", D)
    p.ball(0.85, (0, -0.1, cz), "cream2", "SmoothPlastic", D, segments=14, rings=8)
    for side in (-1, 1):  # laughing, eyes squeezed shut
        p.box((0.35, 0.08, 0.1), (side * 0.3, -0.92, cz + 0.22), (0, side * -25, 0), "black", "SmoothPlastic", D)
        p.box((0.35, 0.08, 0.1), (side * 0.3, -0.92, cz + 0.32), (0, side * 25, 0), "black", "SmoothPlastic", D)
    smile(p, 0, -0.92, cz - 0.25, 0.65, open_mouth=True)
    blush(p, 0, -0.88, cz, 1.1, 0.14)
    crown(p, 0, 0, cz + r + 0.1, 0.65, "gold", "red")
    for side in (-1, 1):
        with p.rigged("legLF" if side < 0 else "legRF", (side * 0.3, 0.25, cz - 0.6)):
            p.beam((0, 0.25, cz), (side * 1.6, 0.25, 0.4), 0.28, 0.28, "white", "Metal", D)
            p.box((0.6, 0.9, 0.35), (side * 1.65, 0.05, 0.18), None, "red", "SmoothPlastic", D)
            style.side_diamonds(p, side * 1.96, -0.3, 0.4, 0.18, height=0.24, band="gold", colors=("dhabateal", "white"))


@prop("CylinderCycleChacha", "brainrot")
def cylinder_cycle(p):
    # a living bicycle: headlight eyes, a handlebar moustache with red tassels and a
    # tower of gas cylinders on a rack painted with truck-art diamonds
    wheel_x(p, 0, -1.7, 1.0, 1.0)
    wheel_x(p, 0, 1.7, 1.0, 1.0)
    frame = [((0, 1.7, 1.0), (0, 0.6, 2.4)), ((0, 0.6, 2.4), (0, 0.0, 1.0)), ((0, 0.0, 1.0), (0, 1.7, 1.0)),
             ((0, 0.6, 2.4), (0, -1.3, 2.5)), ((0, 0.0, 1.0), (0, -1.3, 2.5)), ((0, -1.3, 2.5), (0, -1.7, 1.0))]
    for a, b in frame:
        p.beam(a, b, 0.18, 0.18, "black", "Metal", D)
    p.beam((0, -1.3, 2.5), (0, -1.45, 3.0), 0.18, 0.18, "black", "Metal", D)
    p.box((0.45, 0.8, 0.18), (0, 0.6, 2.55), None, "leather", "Fabric", D)
    # the handlebar is a big curly moustache
    for side in (-1, 1):
        p.beam((0, -1.45, 3.0), (side * 0.75, -1.5, 2.9), 0.22, 0.22, "black", "Metal", D)
        p.beam((side * 0.75, -1.5, 2.9), (side * 0.95, -1.4, 3.25), 0.22, 0.22, "black", "Metal", D)
        p.box((0.3, 0.3, 0.3), (side * 0.97, -1.38, 3.33), (45, 35.26, 0), "black", "SmoothPlastic", D)
        p.box((0.16, 0.16, 0.35), (side * 0.97, -1.38, 3.0), (0, 0, 45), "red", "Fabric", D)
    face = Frame((0, -1.45, 3.45), (0, 0, 35))  # the headlight eyes turn to look at you
    p.box((0.9, 0.3, 0.4), face.p(0, 0.05, 0), face.r(), "steel", "Metal", D)
    for side in (-1, 1):
        p.box((0.6, 0.16, 0.6), face.p(side * 0.36, -0.12, 0.1), face.r(), "steel", "Metal", D)
    eyes(p, 0, -0.22, 0.1, 0.72, 0.28, f=face)
    p.box((0.18, 0.18, 0.12), (0.45, -1.5, 3.0), None, "steel", "Metal", D)
    p.box((0.9, 1.4, 0.1), (0, 1.5, 2.0), None, "darkmetal", "Metal", D)
    for side in (-1, 1):
        style.side_diamonds(p, side * 0.47, 0.85, 2.15, 1.85, height=0.24, band="gold", colors=("red", "dhabateal"))
    for k in range(3):  # the tower of gas cylinders
        n = 3 - k // 2
        for j in range(n):
            x = (j - (n - 1) / 2) * 0.6
            p.cyl(0.27, 0.95, (x, 1.5, 2.55 + k * 1.0), None, "red", "Metal", D, verts=10)
            p.box((0.16, 0.16, 0.12), (x, 1.5, 3.1 + k * 1.0), None, "steel", "Metal", D)
    for k in range(3):
        p.box((1.95, 0.06, 0.06), (0, 1.22, 2.4 + k * 1.0), None, "rope", "Fabric", D)
    p.beam((0.15, 0.3, 0.95), (0.6, 0.6, 0.0), 0.1, 0.1, "black", "Metal", D)
    p.transform(1.1, (0, 0, -45))


# ------------------------------------------------------------------- Mythics
@prop("AmmiKiUdtiChappal", "brainrot")
def udti_chappal(p):
    # the legendary flying blue hawai chappal: sole to the front with stern-cute eyes,
    # wings, whoosh lines, a glow. The rounded toe and heel are eight-pointed stars
    # of two crossed squares as parts (smooth discs before); a gold diamond badge on
    # the strap.
    f = Frame((0, 0, 3.3), (0, 14, -10))
    stand = (90, 0, 0)  # the sole's shapes are built flat, then stood up facing the front
    layers = (  # blue sole in front, the white top layer behind it, a glow around the edge
        (0.0, 0.0, "chappal", "SmoothPlastic", D),
        (0.3, 0.07, "white", "SmoothPlastic", D),
        (0.48, 0.17, "lightning", "Neon", D | KEEP),
    )
    for k, (dy, grow, color, mat, flags) in enumerate(layers):
        for z, r, seed in ((1.05, 1.05, 230), (-1.15, 0.85, 233)):
            p.blob(r + grow, f.p(0, dy, z), (0.92, 0.92, 0.17), color, mat, flags, seed=seed + k, jitter=0.0,
                   subdiv=2, fallback="None", rot=f.r(stand))
            w = (r + grow) * 0.92 * 1.62
            for spin, s in ((0, 1.0), (45, 0.92)):
                p.box((w * s, 0.3, w * s), f.p(0, dy, z), f.r((0, spin, 0)), color, mat, flags | PARTSONLY)
        p.box((1.45 + grow * 2, 0.32, 1.6), f.p(0, dy, -0.05), f.r(), color, mat, flags)
    p.box((0.26, 0.1, 0.26), f.p(0, -0.19, 1.6), f.r((0, 45, 0)), "white", "SmoothPlastic", D)  # the strap plugs
    for side in (-1, 1):
        p.box((0.24, 0.1, 0.24), f.p(side * 0.6, -0.19, -0.3), f.r((0, 45, 0)), "white", "SmoothPlastic", D)
    for z in (-1.2, -1.5, -1.8):  # tread on the heel
        p.box((1.0 - abs(z + 1.5) * 0.6, 0.06, 0.07), f.p(0, -0.18, z), f.r(), "navy", "SmoothPlastic", D)
    for side in (-1, 1):  # the white V strap on the back
        p.beam(f.p(0, 0.4, 1.6), f.p(side * 0.45, 0.85, 0.65), 0.28, 0.28, "white", "SmoothPlastic", D)
        p.beam(f.p(side * 0.45, 0.85, 0.65), f.p(side * 0.65, 0.4, -0.3), 0.28, 0.28, "white", "SmoothPlastic", D)
    p.box((0.34, 0.12, 0.34), f.p(0, 0.62, 1.55), f.r((0, 45, 0)), "gold", "Metal", D)
    eyes(p, 0, -0.2, 0.85, 0.8, 0.3, f=f)
    brows(p, 0, -0.2, 0.85, 0.8, 0.3, "navy", tilt=24, f=f)
    p.box((0.45, 0.08, 0.1), f.p(0, -0.22, 0.05), f.r((0, 8, 0)), "black", "SmoothPlastic", D)
    blush(p, 0, -0.19, 0.3, 1.2, 0.14, f=f)
    for side in (-1, 1):
        wing(p, (side * 0.9, 0.3, 0.3), side, 1.4, 1.0, "white", f=f, angle=32)
    for k in range(4):  # whoosh lines
        p.box((0.08, 0.08, 1.3 - k * 0.2), (0.9 + k * 0.35, 0.9, 1.0 - k * 0.15), (0, 25, 0), "white",
              "SmoothPlastic", D)
    p.transform(1.15)


@prop("KiteKaptaan", "brainrot")
def kite_kaptaan(p):
    # a giant red-and-yellow patang in a blocky captain's hat, gold diamonds on its
    # tips, its string running to a square spool
    f = Frame((0, 0, 4.4), (0, 8, 0))
    q = 1.3
    for k, (dx, dz, color) in enumerate(((0, q, "red"), (q, 0, "yellow"), (0, -q, "red"), (-q, 0, "yellow"))):
        p.box((1.84, 0.1, 1.84), f.p(dx, 0, dz), f.r((0, 45, 0)), color, "Fabric", D)
    for dx, dz in ((0, 2.3), (2.3, 0), (0, -2.3), (-2.3, 0)):
        p.box((0.42, 0.14, 0.42), f.p(dx, -0.04, dz), f.r((0, 45, 0)), "gold", "Fabric", D)
    p.beam(f.p(0, 0.08, 2.65), f.p(0, 0.08, -2.65), 0.12, 0.12, "bamboo", "Wood", D)
    bow = [(-2.5, 0.3), (-1.6, 0.9), (0, 1.15), (1.6, 0.9), (2.5, 0.3)]
    for (x0, z0), (x1, z1) in zip(bow, bow[1:]):
        p.beam(f.p(x0, 0.08, z0), f.p(x1, 0.08, z1), 0.1, 0.1, "bamboo", "Wood", D)
    eyes(p, 0, -0.12, 0.35, 0.85, 0.3, f=f)
    smile(p, 0, -0.1, -0.45, 0.6, f=f)
    blush(p, 0, -0.08, -0.1, 1.4, 0.16, f=f)
    hat = Frame((0, 0, 4.4), (0, 8, 0))
    p.box((1.05, 1.05, 0.45), hat.p(0, 0, 2.8), hat.r(), "white", "Fabric", D)
    p.box((1.1, 1.1, 0.15), hat.p(0, 0, 2.65), hat.r(), "navy", "Fabric", D)
    p.box((0.9, 0.5, 0.08), hat.p(0, -0.55, 2.58), hat.r(), "black", "SmoothPlastic", D)
    p.box((0.2, 0.08, 0.2), hat.p(0, -0.57, 2.82), hat.r((0, 45, 0)), "gold", "Metal", D)
    with p.rigged("tail", f.p(0, 0, -2.6)):
        tail = [f.p(0, 0, -2.6), (0.4, 0, 1.0), (-0.2, 0, 0.0)]
        for k, (a, b) in enumerate(zip(tail, tail[1:])):
            p.beam(a, b, 0.25, 0.06, ("pink", "skyblue")[k], "Fabric", D)
        for k in range(3):
            p.box((0.35, 0.06, 0.2), (0.25 - k * 0.2, 0, 1.6 - k * 0.55), (0, 45, 0), ("green", "orange", "purple")[k],
                  "Fabric", D)
    p.rope(f.p(0, 0.1, 0), (1.6, 0.6, 0.6), 0.6, 0.03, "white", 6)
    p.box((0.8, 0.7, 0.7), (1.6, 0.6, 0.45), None, "wood", "Wood", D)
    for side in (-1, 1):
        p.box((0.08, 1.1, 1.1), (1.6 + side * 0.4, 0.6, 0.45), (45, 0, 0), "red", "Wood", D)
    for i in range(5):
        a = i * 1.2
        p.box((0.14, 0.14, 0.14), (math.cos(a) * 2.6, 0.3, 4.4 + math.sin(a) * 2.2), (45, 45, 0), "gold", "Neon",
              D | KEEP)


@prop("ChandRaatCheetah", "brainrot")
def bangle_cheetah(p):
    # a sleek golden cheetah with glowing square spots, square glass bangles, mehndi
    # paws, a gold collar with diamonds and a moon charm. Its head stays round.
    p.blob(1.0, (0, 0.2, 2.05), (0.8, 1.9, 0.85), "cheetah", "SmoothPlastic", D, seed=240, jitter=0.02,
           fallback="Block", fallback_scale=(0.8, 0.85, 0.8))
    p.blob(0.88, (0, -1.75, 2.95), (1, 1.0, 0.95), "cheetah", "SmoothPlastic", D, seed=241, jitter=0.02,
           fallback="Ball")
    p.blob(0.42, (0, -2.55, 2.7), (1.1, 0.7, 0.75), "cream2", "SmoothPlastic", D, seed=242, fallback="Ball")
    p.ball(0.13, (0, -2.86, 2.82), "pakoradark", "SmoothPlastic", D)
    for side in (-1, 1):
        p.ball(0.25, (side * 0.55, -1.6, 3.72), "cheetah", "SmoothPlastic", D)
        p.box((0.06, 0.04, 0.5), (side * 0.4, -2.5, 2.9), (0, side * -15, 0), "spots", "SmoothPlastic", D)
    eyes(p, 0, -2.45, 3.2, 0.7, 0.25, pupil="spots")
    smile(p, 0, -2.86, 2.5, 0.32)
    spots = [(-0.6, -0.6, 2.4), (0.6, -0.2, 2.5), (-0.55, 0.6, 2.3), (0.6, 0.9, 2.2), (0, -0.2, 2.75), (0, 1.0, 2.7),
             (-0.5, 1.6, 2.1), (0.5, -1.1, 2.3)]
    for i, (x, y, z) in enumerate(spots):
        p.box((0.26, 0.26, 0.26), (x * 1.1, y, z), (45, 35.26, i * 20), "spots", "SmoothPlastic", D)
    colours = ("red", "green", "blue", "gold", "pink", "purple")
    for x in (-0.45, 0.45):
        for y in (-1.0, 1.3):
            with p.rigged(("legL" if x < 0 else "legR") + ("F" if y < 0 else "B"), (x, y, 1.65)):
                p.box((0.36, 0.36, 1.6), (x, y, 0.85), None, "cheetah", "SmoothPlastic", D)
                p.box((0.42, 0.55, 0.15), (x, y - 0.12, 0.07), None, "henna", "SmoothPlastic", D)
                if y < 0:
                    for k in range(4):
                        p.box((0.5, 0.5, 0.09), (x, y, 0.55 + k * 0.14), (0, 0, 45 * (k % 2)),
                              colours[(k + (x > 0) * 2) % 6], "Glass", D)
    with p.rigged("tail", (0, 1.9, 2.1)):
        tail = [(0, 1.9, 2.1), (0, 2.6, 2.6), (0, 2.9, 3.4)]
        for a, b in zip(tail, tail[1:]):
            p.beam(a, b, 0.28, 0.28, "cheetah", "SmoothPlastic", D)
        for k in range(4):
            p.box((0.42, 0.42, 0.08), (0, 2.45 + k * 0.12, 2.45 + k * 0.2), (-35, 0, 45 * (k % 2)), colours[k + 1],
                  "Glass", D)
    p.box((1.15, 1.15, 0.16), (0, -1.25, 2.45), (60, 0, 0), "gold", "Metal", D)  # the collar
    for k, x in enumerate((-0.32, 0, 0.32)):
        p.box((0.16, 0.08, 0.16), (x, -1.62, 2.18), (60, 45, 0), "red" if k == 1 else "dhabateal", "SmoothPlastic", D)
    p.cyl(0.3, 0.06, (0, -1.75, 1.95), (90, 0, 0), "gold", "Neon", D | KEEP | LIGHT, verts=12)
    p.cyl(0.25, 0.07, (0.1, -1.8, 2.05), (90, 0, 0), "cheetah", "SmoothPlastic", D, verts=12)
    for i in range(4):
        a = i * 1.6
        p.box((0.12, 0.12, 0.12), (math.cos(a) * 1.6, -0.6 + math.sin(a) * 1.2, 3.6 + (i % 2) * 0.4), (45, 45, 0),
              "white", "Neon", D | KEEP)
    p.transform(1.35, (0, 0, -35))


# ------------------------------------------------------------------ Specials
@prop("MithaiMamu", "brainrot")
def mithai_mamu(p):
    # a round laddoo uncle in a little maroon vest with a gold band of diamonds,
    # carrying a tray of sweets. A laddoo is a ball, so he stays round.
    p.ball(1.5, (0, 0, 2.0), "laddoo", "SmoothPlastic", D, segments=14, rings=9)
    for i in range(12):
        a = i * 0.8
        p.box((0.2, 0.2, 0.2), (math.cos(a) * 1.4, math.sin(a) * 1.05, 1.9 + (i % 4) * 0.3), (i * 20, i * 30, 0),
              "saffron", "SmoothPlastic", D)
    p.cone(1.5, 1.0, (0, 0, 1.3), (180, 0, 0), "maroon", "Fabric", D, verts=14, top=1.15, fallback="None")
    p.box((2.0, 2.0, 0.5), (0, 0, 1.05), None, "maroon", "Fabric", D | PARTSONLY)
    p.box((2.75, 2.75, 0.5), (0, 0, 1.55), None, "maroon", "Fabric", D | PARTSONLY)
    style.diamonds(p, -1.2, 1.2, -1.44, 1.55, height=0.3, band="gold", colors=("dhabateal", "white"), step=0.5)
    for x, y in ((-0.5, -0.3), (0.4, 0.2), (0.0, 0.5)):
        p.box((0.4, 0.4, 0.04), (x, y, 3.5), (0, 0, x * 60), "warq", "Foil", D)
    eyes(p, 0, -1.4, 2.4, 0.9, 0.3)
    moustache(p, 0, -1.48, 1.95, 1.2, "black", thick=0.22)
    smile(p, 0, -1.47, 1.75, 0.55, open_mouth=True)
    blush(p, 0, -1.38, 2.1, 1.45, 0.18)
    for side in (-1, 1):
        block_arm(p, (side * 1.3, -0.3, 1.8), (side * 0.75, -1.65, 1.5), 0.32, "laddoo", still=True)
        block_leg(p, side * 0.55, 0, 0.75, 0.44, "laddoo", "black")
    p.box((2.1, 1.2, 0.12), (0, -1.95, 1.55), None, "steel", "Metal", D)
    p.box((0.45, 0.45, 0.22), (-0.6, -1.95, 1.72), None, "barfi", "SmoothPlastic", D)
    p.box((0.35, 0.35, 0.05), (-0.6, -1.95, 1.85), None, "pistachio", "SmoothPlastic", D)
    p.box((0.5, 0.5, 0.12), (0.05, -1.95, 1.68), (0, 0, 45), "jalebi", "SmoothPlastic", D)
    for x in (0.55, 0.85):
        p.ball(0.2, (x, -1.9, 1.8), "gulabjamun", "SmoothPlastic", D, segments=8, rings=5)


@prop("LassiLightning", "brainrot")
def lassi_lightning(p):
    # a flying square lassi glass hero with square goggles, a cape, lightning wings,
    # blue sparks and a hero's diamond emblem
    p.box((1.9, 1.9, 2.8), (0, 0, 1.4), None, "glass", "Glass", D | GLASS)
    p.box((1.7, 1.7, 2.5), (0, 0, 1.3), None, "lassi", "SmoothPlastic", D)
    p.blob(1.0, (0, 0, 2.85), (1, 1, 0.45), "malai", "SmoothPlastic", D, seed=250, fallback="None")
    for spin in (0, 45):
        p.box((1.75, 1.75, 0.4), (0, 0, 2.88 + spin * 0.001), (0, 0, spin), "malai", "SmoothPlastic", D | PARTSONLY)
    eyes(p, 0, -1.0, 1.8, 0.75, 0.26)
    for side in (-1, 1):
        p.box((0.66, 0.14, 0.62), (side * 0.38, -0.98, 1.8), None, "black", "SmoothPlastic", D)
        p.box((0.52, 0.12, 0.48), (side * 0.38, -1.06, 1.8), None, "lightning", "Glass", D | GLASS)
    p.box((1.96, 1.96, 0.12), (0, 0, 1.8), None, "black", "Fabric", D)
    smile(p, 0, -1.02, 1.12, 0.45)
    p.box((0.6, 0.08, 0.6), (0, -1.0, 0.55), (0, 45, 0), "red", "SmoothPlastic", D)  # the emblem
    p.box((0.36, 0.1, 0.36), (0, -1.03, 0.55), (0, 45, 0), "yellow", "SmoothPlastic", D)
    p.beam((0.3, 0, 3.0), (0.6, 0.1, 4.3), 0.16, 0.16, "red", "SmoothPlastic", D)
    for k, (a, b) in enumerate((((0.6, 0.1, 4.3), (0.85, 0.1, 4.7)), ((0.85, 0.1, 4.7), (0.6, 0.1, 4.9)),
                               ((0.6, 0.1, 4.9), (0.9, 0.1, 5.35)))):
        p.beam(a, b, 0.14, 0.08, "lightning", "Neon", D | KEEP | (LIGHT if k == 0 else 0))
    for side in (-1, 1):  # lightning-bolt wings
        with p.rigged("wingL" if side < 0 else "wingR", (side * 0.95, 0.2, 2.0)):
            pts = [(side * 0.95, 0.2, 2.0), (side * 1.6, 0.3, 2.6), (side * 1.35, 0.3, 2.75), (side * 2.1, 0.4, 3.4)]
            for a, b in zip(pts, pts[1:]):
                p.beam(a, b, 0.3, 0.1, "yellow", "SmoothPlastic", D)
    for k in range(2):
        p.box((1.5 - k * 0.3, 0.1, 1.2), (0, 1.05 + k * 0.4, 1.9 - k * 0.6), (-25 - k * 15, 0, 0), "red", "Fabric", D)
    for i in range(5):
        a = i * 1.3
        p.box((0.1, 0.1, 0.35), (math.cos(a) * 1.5, -0.3 + math.sin(a) * 1.2, 1.2 + (i % 3) * 0.7), (30, 0, i * 40),
              "lightning", "Neon", D | KEEP)


@prop("ChowkidarChoocha", "brainrot")
def chowkidar_choocha(p):
    # a round yellow chick in a khaki watchman's uniform with a gold diamond badge,
    # a blocky cap, a whistle, stick and torch. The chick is its face, so it stays round.
    p.ball(1.3, (0, 0, 1.75), "chick", "SmoothPlastic", D, segments=14, rings=8)
    for k in range(3):
        p.box((0.12, 0.12, 0.5), (-0.15 + k * 0.15, 0.1, 3.15), (0, (k - 1) * 25, 0), "chick", "SmoothPlastic", D)
    p.cone(1.32, 1.1, (0, 0, 1.15), (180, 0, 0), "khaki", "Fabric", D, verts=14, top=1.0, fallback="None")
    p.box((2.5, 2.5, 1.1), (0, 0, 1.15), None, "khaki", "Fabric", D | PARTSONLY)
    p.box((2.56, 2.56, 0.15), (0, 0, 1.0), None, "leather", "Fabric", D)
    p.box((0.34, 0.1, 0.24), (0, -1.3, 1.0), None, "gold", "Metal", D)
    for z in (1.3, 1.55):
        p.box((0.12, 0.1, 0.12), (0, -1.27, z), (0, 45, 0), "gold", "Metal", D)
    for side in (-1, 1):
        p.box((0.4, 0.1, 0.35), (side * 0.6, -1.28, 1.45), None, "khaki", "Fabric", D)
    p.box((0.3, 0.1, 0.3), (-0.6, -1.32, 1.5), (0, 45, 0), "gold", "Metal", D)  # the watchman's badge
    p.box((0.16, 0.11, 0.16), (-0.6, -1.36, 1.5), (0, 45, 0), "red", "SmoothPlastic", D)
    block_cap(p, 0, 0, 3.05, 0.62, "khaki", "black", band="leather")
    eyes(p, 0, -1.18, 2.3, 0.75, 0.27)
    brows(p, 0, -1.18, 2.3, 0.75, 0.27, "khaki", tilt=10)
    p.box((0.4, 0.45, 0.32), (0, -1.4, 1.95), None, "orange", "SmoothPlastic", D)  # the beak
    p.box((0.14, 0.3, 0.14), (0.25, -1.5, 1.9), None, "steel", "Metal", D)  # the whistle
    p.rope((0.25, -1.4, 1.9), (0.8, -0.6, 2.3), 0.3, 0.03, "rope", 4)
    for side in (-1, 1):
        with p.rigged("wingL" if side < 0 else "wingR", (side * 1.3, -0.2, 2.1)):
            p.box((0.25, 0.8, 0.9), (side * 1.3, -0.2, 1.7), (0, side * -15, 0), "chick", "SmoothPlastic", D)
        with p.rigged("legLF" if side < 0 else "legRF", (side * 0.45, 0, 0.6)):
            p.box((0.25, 0.6, 0.12), (side * 0.45, -0.25, 0.06), None, "orange", "SmoothPlastic", D)
            p.beam((side * 0.45, 0, 0.6), (side * 0.45, -0.1, 0.1), 0.14, 0.14, "orange", "SmoothPlastic", D)
    p.box((0.14, 0.14, 2.4), (1.48, -0.6, 1.2), None, "lightwood", "Wood", D)
    p.box((0.34, 0.7, 0.34), (-1.5, -0.7, 1.5), None, "black", "Metal", D)  # the torch
    p.box((0.28, 0.05, 0.28), (-1.5, -1.07, 1.5), None, "yellow", "Neon", D | KEEP | LIGHT)


@prop("RangeelaRaja", "brainrot")
def rangeela_raja(p):
    # a plump peacock king with a rainbow tail fan with diamond eyes, a crown and
    # puffs of Holi colour. A chunky body; the head stays round.
    rainbow = ("red", "orange", "yellow", "green", "teal", "blue", "purple")
    with p.rigged("tail", (0, 0.7, 1.5)):
        for i, color in enumerate(rainbow):
            a = math.radians(-66 + i * 22)
            tip = (math.sin(a) * 3.2, 0.9, 1.6 + math.cos(a) * 3.2)
            p.beam((0, 0.7, 1.5), tip, 0.7, 0.08, color, "SmoothPlastic", D)
            p.box((0.5, 0.06, 0.5), (tip[0] * 0.95, 0.82, tip[2] - 0.05), (0, 45 - math.degrees(a), 0), "navy",
                  "SmoothPlastic", D)
            p.box((0.28, 0.08, 0.28), (tip[0] * 0.95, 0.78, tip[2] - 0.05), (0, 45 - math.degrees(a), 0), "peacockteal",
                  "SmoothPlastic", D)
    chunk(p, 1.1, (0, 0, 2.0), (0.9, 1.0, 1.25), "peacock", seed=260)
    p.blob(0.62, (0, -0.35, 3.45), (1, 1, 1.05), "peacock", "SmoothPlastic", D, seed=261, jitter=0.02,
           fallback="Ball")
    p.box((0.22, 0.4, 0.2), (0, -1.0, 3.35), None, "cream2", "SmoothPlastic", D)  # the beak
    eyes(p, 0, -0.9, 3.6, 0.5, 0.19)
    crown(p, 0, -0.35, 3.98, 0.38, "gold", "green")
    for side in (-1, 1):
        with p.rigged("wingL" if side < 0 else "wingR", (side * 1.0, 0.1, 2.5)):
            p.box((0.3, 0.9, 1.2), (side * 1.0, 0.1, 2.0), (0, side * -12, 0), "peacockteal", "SmoothPlastic", D)
            p.box((0.32, 0.92, 0.14), (side * 1.0, 0.1, 1.42), (0, side * -12, 0), "gold", "SmoothPlastic", D)
        with p.rigged("legLF" if side < 0 else "legRF", (side * 0.35, 0, 0.9)):
            p.beam((side * 0.35, 0, 0.9), (side * 0.4, -0.15, 0.1), 0.14, 0.14, "cream2", "SmoothPlastic", D)
            p.box((0.3, 0.6, 0.1), (side * 0.4, -0.3, 0.05), None, "cream2", "SmoothPlastic", D)
    for i, color in enumerate(("pink", "yellow", "lime", "skyblue")):
        a = i * 1.6 + 0.4
        p.box((0.55, 0.55, 0.45), (math.cos(a) * 1.4, -0.4 + math.sin(a) * 0.9, 0.35), (45, 35.26, i * 25), color,
              "SmoothPlastic", D)


@prop("ShalimarSultan", "brainrot")
def shalimar_sultan(p):
    # a floating sultan whose body is a tiered marble garden fountain, its base inlaid
    # with a gold band of diamonds like the Shalimar Gardens, a chunky green turban and
    # a crown of water jets. The marble head stays round.
    p.box((3.0, 3.0, 0.5), (0, 0, 0.25), None, "white", "Marble", D)
    style.diamonds(p, -1.35, 1.35, -1.56, 0.25, height=0.3, band="gold", colors=("red", "dhabateal"), step=0.5)
    p.box((2.6, 2.6, 0.08), (0, 0, 0.52), None, "fountain", "Glass", D | GLASS)
    p.box((0.8, 0.8, 1.2), (0, 0, 1.1), (0, 0, 45), "white", "Marble", D)
    p.box((2.1, 2.1, 0.35), (0, 0, 1.85), None, "white", "Marble", D)
    p.box((1.8, 1.8, 0.07), (0, 0, 2.04), None, "fountain", "Glass", D | GLASS)
    p.ball(0.9, (0, 0, 2.8), "cream2", "Marble", D, segments=14, rings=8)
    p.blob(0.85, (0, 0.05, 3.55), (1.15, 1.15, 0.62), "green", "Fabric", D, seed=280, jitter=0.04,
           fallback="None")  # the turban
    p.box((1.75, 1.75, 0.7), (0, 0.05, 3.62), (0, 0, 0), "green", "Fabric", D | PARTSONLY)
    p.box((1.35, 1.35, 0.9), (0, 0.05, 3.7), (0, 0, 45), "green", "Fabric", D | PARTSONLY)
    p.box((1.82, 1.82, 0.16), (0, 0.05, 3.3), None, "gold", "Metal", D)
    p.box((0.3, 0.3, 0.3), (0, -0.92, 3.5), (45, 35.26, 0), "red", "SmoothPlastic", D)
    p.box((0.44, 0.08, 0.44), (0, -0.86, 3.5), (0, 45, 0), "gold", "Metal", D)
    eyes(p, 0, -0.84, 2.95, 0.6, 0.21)
    moustache(p, 0, -0.9, 2.55, 0.85, "black", thick=0.17)
    smile(p, 0, -0.88, 2.38, 0.3)
    blush(p, 0, -0.8, 2.7, 1.05, 0.12)
    for i in range(5):  # a crown of water jets rising from the turban
        a = i * 2 * math.pi / 5 + math.pi / 2
        base = (math.cos(a) * 0.25, math.sin(a) * 0.25, 4.0)
        top = (math.cos(a) * 0.7, math.sin(a) * 0.7, 4.85)
        p.beam(base, top, 0.14, 0.14, "fountain", "Glass", D | GLASS)
        p.box((0.2, 0.2, 0.2), (top[0] * 1.15, top[1] * 1.15, 4.7), (45, 35.26, 0), "fountain", "Glass", D | GLASS)
    for side in (-1, 1):  # cypress trees: tiers like the deodars
        p.cone(0.38, 1.6, (side * 1.0, 0, 2.75), None, "cypress", "Grass", D, verts=8, fallback="None")
        for k, w in enumerate((0.62, 0.46, 0.3)):
            p.box((w, w, 0.55), (side * 1.0, 0, 2.2 + k * 0.52), (0, 0, 45 * (k % 2)), "cypress", "Grass",
                  D | PARTSONLY)
    for i in range(8):
        a = i * 2 * math.pi / 8
        p.ball(0.16, (math.cos(a) * 1.55, math.sin(a) * 1.55, 0.6), ("pink", "yellow", "white", "red")[i % 4],
               "SmoothPlastic", D, segments=6, rings=4)


@prop("TaaronWalaTonga", "brainrot")
def star_tonga(p):
    # a starry night-blue tonga with gold diamond bands, pulled by a glowing winged
    # horse with a chunky body (its head stays round); crescent-moon wheels
    p.box((2.6, 2.4, 0.35), (0, 0.6, 1.9), None, "starnavy", "WoodPlanks", D)
    p.box((2.6, 0.2, 1.0), (0, 1.75, 2.55), None, "starnavy", "WoodPlanks", D)
    for side in (-1, 1):
        style.side_diamonds(p, side * 1.33, -0.3, 1.5, 1.9, height=0.3, band="gold", colors=("starnavy", "white"))
    for x in (-1.2, 1.2):
        for y in (-0.5, 1.7):
            p.box((0.12, 0.12, 1.55), (x, y, 2.82), None, "gold", "Metal", D)
    p.box((2.8, 2.6, 0.2), (0, 0.6, 3.7), None, "starnavy", "Fabric", D)
    for k in range(6):
        p.box((0.2, 0.2, 0.26), (-1.25 + k * 0.5, -0.65, 3.5), (0, 0, 45), "gold", "SmoothPlastic", D)
    for i in range(6):
        x = -1.0 + (i % 3) * 1.0
        y = 0.1 + (i // 3) * 1.0
        for k in range(2):
            p.box((0.3, 0.06, 0.06), (x, y, 3.82), (0, 0, k * 90 + 45), "yellow", "Neon", D | KEEP)
    for side in (-1, 1):
        p.cyl(1.0, 0.2, (side * 1.45, 0.6, 1.3), (0, 90, 0), "gold", "Neon", D | KEEP, verts=16)
        p.cyl(0.8, 0.24, (side * 1.45, 0.75, 1.55), (0, 90, 0), "starnavy", "SmoothPlastic", D, verts=16)
    p.beam((0, -0.6, 2.1), (0, -1.6, 2.3), 0.14, 0.14, "gold", "Metal", D)
    # the winged horse
    chunk(p, 0.75, (0, -2.3, 2.4), (0.8, 1.35, 0.8), "white", seed=270)
    p.beam((0, -2.9, 2.7), (0, -3.2, 3.3), 0.55, 0.55, "white", "SmoothPlastic", D)
    p.blob(0.45, (0, -3.45, 3.5), (0.8, 1.2, 0.8), "white", "SmoothPlastic", D, seed=271, fallback="Ball")
    for side in (-1, 1):
        p.box((0.1, 0.1, 0.3), (side * 0.18, -3.3, 3.95), None, "white", "SmoothPlastic", D)
        wing(p, (side * 0.55, -2.2, 2.8), side, 1.3, 0.9, "white", angle=35)
        for y in (-2.0, -2.7):
            with p.rigged(("legL" if side < 0 else "legR") + ("F" if y < -2.3 else "B"), (side * 0.3, y, 2.1)):
                p.beam((side * 0.3, y, 2.1), (side * 0.3, y + 0.3, 1.35), 0.18, 0.18, "white", "SmoothPlastic", D)
    for k in range(3):
        p.box((0.12, 0.25, 0.35), (0, -3.05 + k * 0.2, 3.7 - k * 0.25), (-30, 0, 0), "lightning", "Neon", D | KEEP)
    eyes(p, 0, -3.95, 3.6, 0.36, 0.13)
    smile(p, 0, -4.0, 3.3, 0.22)
    p.box((0.3, 0.3, 0.4), (1.3, -0.65, 3.3), None, "gold", "Metal", D)
    p.box((0.22, 0.22, 0.3), (1.3, -0.65, 3.3), None, "yellow", "Neon", D | KEEP | LIGHT)
    for i in range(5):
        p.box((0.14, 0.14, 0.14), (0.4 - i * 0.2, 2.2 + i * 0.5, 1.6 + i * 0.15), (45, 45, 0), "white", "Neon",
              D | KEEP)
