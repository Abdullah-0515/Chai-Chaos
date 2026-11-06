"""Brainrot models, part 3: the Legendaries, Mythics and Collection Book specials."""

import math

from brainrot_kit import D, Frame, arm, blush, brows, cap, crown, eyes, leg, moustache, puffs, rope_ring, smile, wing
from kit import GLASS, KEEP, LIGHT, prop


def wheel_x(p, x, y, z, r, tyre="tyre", hub="metal", spokes=4, width=0.2):
    """A wheel turning about the X axis."""
    p.cyl(r, width, (x, y, z), (0, 90, 0), tyre, "SmoothPlastic", D, verts=16)
    p.cyl(r * 0.25, width + 0.05, (x, y, z), (0, 90, 0), hub, "Metal", D, verts=8)
    for k in range(spokes):
        p.box((0.05, r * 1.85, 0.05), (x, y, z), (k * 180 / spokes, 0, 0), hub, "Metal", D)


# --------------------------------------------------------------- Legendaries
@prop("TruckArtTotaa", "brainrot")
def truck_art_parrot(p):
    # a green parrot painted with truck art, bells on its wings and a crown crest
    p.blob(1.25, (0, 0.15, 2.6), (0.95, 1, 1.35), "parrot", "SmoothPlastic", D, seed=200, jitter=0.02,
           fallback="Ball")
    p.blob(0.88, (0, -0.25, 4.25), (1, 1, 1), "parrot", "SmoothPlastic", D, seed=201, jitter=0.02, fallback="Ball")
    p.cone(0.3, 0.75, (0, -1.15, 4.0), (-120, 0, 0), "orange", "SmoothPlastic", D, verts=8, fallback="Cylinder")
    p.cone(0.18, 0.35, (0, -0.95, 3.75), (-70, 0, 0), "orange", "SmoothPlastic", D, verts=6, fallback="None")
    eyes(p, 0, -0.98, 4.45, 0.7, 0.24)
    p.box((1.5, 0.3, 0.95), (0, -0.05, 5.05), (-10, 0, 0), "red", "WoodPlanks", D)
    p.box((1.6, 0.32, 0.2), (0, -0.05, 5.5), (-10, 0, 0), "gold", "Metal", D)
    for k, color in enumerate(("yellow", "skyblue", "pink")):
        p.ball(0.15, (-0.45 + k * 0.45, -0.25, 5.05), color, "SmoothPlastic", D, segments=6, rings=4)
    flowers = [("red", -0.4, 2.9), ("yellow", 0.4, 2.6), ("blue", 0.0, 2.1), ("pink", -0.45, 1.85), ("yellow", 0.45, 3.3)]
    for color, x, z in flowers:
        p.cyl(0.22, 0.06, (x, -1.12 + abs(x) * 0.15, z), (90, 0, 0), color, "SmoothPlastic", D, verts=8)
        p.cyl(0.08, 0.08, (x, -1.15 + abs(x) * 0.15, z), (90, 0, 0), "white", "SmoothPlastic", D, verts=6)
    for side in (-1, 1):
        p.box((0.28, 1.3, 1.8), (side * 1.12, 0.25, 2.7), (0, side * -10, 0), "blue", "SmoothPlastic", D)
        for k, color in enumerate(("red", "yellow", "green")):
            p.box((0.06, 1.2, 0.18), (side * 1.27, 0.25, 2.1 + k * 0.5), (0, side * -10, 0), color, "SmoothPlastic", D)
        for k in range(4):
            p.ball(0.12, (side * 1.3, -0.2 + k * 0.32, 1.7), "gold", "Metal", D, segments=6, rings=4)
        p.box((0.25, 0.5, 0.2), (side * 0.4, -0.3, 0.1), None, "orange", "SmoothPlastic", D)
        p.rod((side * 0.35, 0, 1.3), (side * 0.4, -0.2, 0.15), 0.1, "orange", "SmoothPlastic", D)
    for k, color in enumerate(("yellow", "red", "blue")):  # the tail, with its lettering panel
        p.box((0.45, 0.12, 2.2), (-0.45 + k * 0.45, 1.5, 1.2), (35, 0, (k - 1) * 8), color, "SmoothPlastic", D)
    p.box((1.3, 0.1, 0.45), (0, 1.62, 1.0), (35, 0, 0), "white", "SmoothPlastic", D)
    p.anchor("Tail", (0, 1.661, 1.029))  # on the face of the lettering panel


@prop("SixerSher", "brainrot")
def sixer_sher(p):
    # a street-cricket lion with a taped bat on its shoulder and a taped tennis ball
    p.blob(1.3, (0, 0.15, 2.3), (1, 0.95, 1.1), "lion", "SmoothPlastic", D, seed=210, jitter=0.03, fallback="Ball")
    p.cone(1.35, 1.4, (0, 0.1, 2.4), None, "red", "Fabric", D, verts=14, top=1.15, fallback="Cylinder")
    p.cyl(1.38, 0.15, (0, 0.1, 2.5), None, "white", "Fabric", D, verts=14)
    p.blob(1.45, (0, 0.2, 4.05), (1.1, 0.8, 1.1), "mane", "SmoothPlastic", D, seed=211, jitter=0.15,
           fallback="Ball")
    p.ball(1.0, (0, -0.35, 4.0), "lion", "SmoothPlastic", D, segments=14, rings=8)
    p.blob(0.5, (0, -1.15, 3.7), (1.2, 0.7, 0.8), "cream2", "SmoothPlastic", D, seed=212, fallback="Ball")
    p.ball(0.15, (0, -1.5, 3.85), "pakoradark", "SmoothPlastic", D)
    for side in (-1, 1):
        p.ball(0.28, (side * 0.75, -0.3, 4.8), "lion", "SmoothPlastic", D)
    eyes(p, 0, -1.25, 4.2, 0.7, 0.24)
    brows(p, 0, -1.25, 4.2, 0.7, 0.24, "mane", tilt=12)
    smile(p, 0, -1.55, 3.55, 0.45)
    cap(p, 0, -0.2, 4.95, 0.55, "blue", "navy", backwards=True)
    for side in (-1, 1):
        leg(p, side * 0.5, 0.1, 0.9, 0.26, "lion", "white")
    arm(p, (1.25, 0, 2.8), (0.9, -0.6, 3.6), 0.18, "lion", "lion", 0.26)
    p.box((0.55, 0.18, 2.3), (0.85, 0.3, 4.1), (0, 0, 35), "willow", "Wood", D)
    p.cyl(0.13, 0.9, (0.25, -0.55, 3.15), (0, -35, 0), "black", "Fabric", D, verts=8)
    for k, color in enumerate(("black", "red", "black")):
        p.box((0.58, 0.2, 0.12), (1.0 + k * 0.25, 0.3, 4.3 + k * 0.35), (0, 0, 35), color, "Fabric", D)
    arm(p, (-1.25, 0, 2.8), (-1.6, -0.6, 2.4), 0.18, "lion", "lion", 0.26)
    p.ball(0.3, (-1.65, -0.95, 2.45), "tennisball", "Fabric", D)
    p.cyl(0.31, 0.12, (-1.65, -0.95, 2.45), (30, 0, 0), "black", "Fabric", D, verts=10)
    p.rod((0, 1.1, 1.5), (0, 2.0, 1.8), 0.1, "lion", "SmoothPlastic", D)
    p.ball(0.25, (0, 2.1, 1.85), "mane", "SmoothPlastic", D)


@prop("ChilgozaChachaChipka", "brainrot")
def chilgoza(p):
    # a pine-nut uncle clinging to a spinning ceiling fan, moustache blown sideways
    hub = (0, 0, 5.2)
    p.rod((0, 0, 5.4), (0, 0, 6.4), 0.1, "white", "Metal", D)
    p.cyl(0.45, 0.15, (0, 0, 6.45), None, "white", "Metal", D, verts=12)
    p.cyl(0.55, 0.5, hub, None, "white", "Metal", D, verts=12)
    for k in range(3):
        a = k * 2 * math.pi / 3 + 0.4
        p.box((2.6, 0.65, 0.08), (math.cos(a) * 1.6, math.sin(a) * 1.6, 5.05), (8, 0, math.degrees(a)), "tin", "Metal",
              D)
    f = Frame((1.55, -0.55, 3.75), (0, -15, 20))
    p.blob(0.62, f.p(0, 0, 0), (0.8, 0.8, 1.9), "pinenut", "SmoothPlastic", D, seed=220, jitter=0.03,
           fallback="Cylinder", rot=f.r())
    p.cone(0.25, 0.5, f.p(0, 0, -1.25), f.r((180, 0, 0)), "pinenut", "SmoothPlastic", D, verts=8,
           fallback="None")
    eyes(p, 0, -0.45, 0.45, 0.5, 0.2, f=f)
    brows(p, 0, -0.45, 0.45, 0.5, 0.2, tilt=-15, f=f)
    for k in range(2):  # moustache blown sideways by the wind
        p.box((0.75, 0.2, 0.2), f.p(0.35 + k * 0.1, -0.5, 0.05 + k * 0.12), f.r((0, -20 - k * 15, 0)), "black",
              "SmoothPlastic", D)
    smile(p, 0, -0.5, -0.2, 0.3, f=f, open_mouth=True)
    arm(p, (-0.5, 0, 0.5), (-0.2, 0.3, 1.25), 0.1, "pinenut", f=f)
    arm(p, (0.5, 0, 0.5), (0.35, 0.3, 1.25), 0.1, "pinenut", f=f)
    for k, z in enumerate((2.3, 1.55, 0.6)):  # dripping honey
        p.ball(0.18 - k * 0.03, (1.45, -0.6, z), "honey", "Glass", D | GLASS, segments=8, rings=5)


@prop("MelaMaharaja", "brainrot")
def mela_maharaja(p):
    # a laughing Ferris wheel king with a crown, cabins and light bulbs
    cz, r = 3.4, 2.4
    rim = [(math.cos(a) * r, 0, cz + math.sin(a) * r) for a in (i * 2 * math.pi / 16 for i in range(16))]
    for k, (a, b) in enumerate(zip(rim, rim[1:] + rim[:1])):
        p.rod(a, b, 0.12, "pink" if k % 2 else "yellow", "SmoothPlastic", D, verts=6)
    for i in range(0, 16, 2):
        p.rod((0, 0, cz), rim[i], 0.06, "white", "Metal", D, verts=4)
    for i in range(16):
        x, _, z = rim[i]
        p.ball(0.1, (x, -0.12, z), ("yellow", "pink", "skyblue", "lime")[i % 4], "Neon", D | KEEP | (LIGHT if i == 0 else 0),
               segments=6, rings=4)
    for i in range(1, 16, 2):
        x, _, z = rim[i]
        p.box((0.45, 0.4, 0.4), (x, 0, z - 0.35), None, ("red", "teal", "orange", "purple")[(i // 2) % 4], "SmoothPlastic",
              D)
        p.box((0.55, 0.45, 0.1), (x, 0, z - 0.1), None, "white", "SmoothPlastic", D)
    p.ball(0.85, (0, -0.1, cz), "cream2", "SmoothPlastic", D, segments=14, rings=8)
    for side in (-1, 1):  # laughing, eyes squeezed shut
        p.box((0.35, 0.08, 0.1), (side * 0.3, -0.92, cz + 0.22), (0, side * -25, 0), "black", "SmoothPlastic", D)
        p.box((0.35, 0.08, 0.1), (side * 0.3, -0.92, cz + 0.32), (0, side * 25, 0), "black", "SmoothPlastic", D)
    smile(p, 0, -0.92, cz - 0.25, 0.65, open_mouth=True)
    blush(p, 0, -0.88, cz, 1.1, 0.14)
    crown(p, 0, 0, cz + r + 0.1, 0.65, "gold", "red")
    for side in (-1, 1):
        p.rod((0, 0.25, cz), (side * 1.6, 0.25, 0.4), 0.14, "white", "Metal", D)
        p.box((0.6, 0.9, 0.35), (side * 1.65, 0.05, 0.18), None, "red", "SmoothPlastic", D)


@prop("CylinderCycleChacha", "brainrot")
def cylinder_cycle(p):
    # a living bicycle: headlight eyes, a handlebar moustache and a tower of gas cylinders
    wheel_x(p, 0, -1.7, 1.0, 1.0)
    wheel_x(p, 0, 1.7, 1.0, 1.0)
    frame = [((0, 1.7, 1.0), (0, 0.6, 2.4)), ((0, 0.6, 2.4), (0, 0.0, 1.0)), ((0, 0.0, 1.0), (0, 1.7, 1.0)),
             ((0, 0.6, 2.4), (0, -1.3, 2.5)), ((0, 0.0, 1.0), (0, -1.3, 2.5)), ((0, -1.3, 2.5), (0, -1.7, 1.0))]
    for a, b in frame:
        p.rod(a, b, 0.09, "black", "Metal", D, verts=6)
    p.rod((0, -1.3, 2.5), (0, -1.45, 3.0), 0.09, "black", "Metal", D, verts=6)
    p.box((0.45, 0.8, 0.18), (0, 0.6, 2.55), None, "leather", "Fabric", D)
    # the handlebar is a big curly moustache
    for side in (-1, 1):
        p.rod((0, -1.45, 3.0), (side * 0.75, -1.5, 2.9), 0.11, "black", "Metal", D, verts=6)
        p.rod((side * 0.75, -1.5, 2.9), (side * 0.95, -1.4, 3.25), 0.11, "black", "Metal", D, verts=6)
        p.ball(0.17, (side * 0.97, -1.38, 3.33), "black", "SmoothPlastic", D)
    face = Frame((0, -1.45, 3.45), (0, 0, 35))  # the headlight eyes turn to look at you
    p.box((0.9, 0.3, 0.4), face.p(0, 0.05, 0), face.r(), "steel", "Metal", D)
    for side in (-1, 1):
        p.cyl(0.34, 0.16, face.p(side * 0.36, -0.12, 0.1), face.r((90, 0, 0)), "steel", "Metal", D, verts=12)
    eyes(p, 0, -0.22, 0.1, 0.72, 0.28, f=face)
    p.cyl(0.1, 0.12, (0.45, -1.5, 3.0), None, "steel", "Metal", D, verts=8)
    p.box((0.9, 1.4, 0.1), (0, 1.5, 2.0), None, "darkmetal", "Metal", D)
    for k in range(3):  # the tower of gas cylinders
        n = 3 - k // 2
        for j in range(n):
            x = (j - (n - 1) / 2) * 0.6
            p.cyl(0.27, 0.95, (x, 1.5, 2.55 + k * 1.0), None, "red", "Metal", D, verts=10)
            p.cyl(0.08, 0.12, (x, 1.5, 3.1 + k * 1.0), None, "steel", "Metal", D, verts=6)
    for k in range(3):
        p.box((1.95, 0.06, 0.06), (0, 1.22, 2.4 + k * 1.0), None, "rope", "Fabric", D)
    p.rod((0.15, 0.3, 0.95), (0.6, 0.6, 0.0), 0.05, "black", "Metal", D, verts=4)
    p.transform(1.1, (0, 0, -45))


# ------------------------------------------------------------------- Mythics
@prop("AmmiKiUdtiChappal", "brainrot")
def udti_chappal(p):
    # the legendary flying blue hawai chappal: sole to the front with stern-cute eyes, wings, whoosh lines, a glow
    f = Frame((0, 0, 3.3), (0, 14, -10))
    stand = (90, 0, 0)  # the sole's shapes are built flat, then stood up facing the front
    layers = (  # blue sole in front, the white top layer behind it, a glow around the edge
        (0.0, 0.0, "chappal", "SmoothPlastic", D),
        (0.3, 0.07, "white", "SmoothPlastic", D),
        (0.48, 0.17, "lightning", "Neon", D | KEEP),
    )
    for k, (dy, grow, color, mat, flags) in enumerate(layers):
        p.blob(1.05 + grow, f.p(0, dy, 1.05), (0.92, 0.92, 0.17), color, mat, flags, seed=230 + k, jitter=0.0,
               subdiv=2, fallback="Disc", rot=f.r(stand))
        p.blob(0.85 + grow, f.p(0, dy, -1.15), (0.92, 0.92, 0.17), color, mat, flags, seed=233 + k, jitter=0.0,
               subdiv=2, fallback="Disc", rot=f.r(stand))
        p.box((1.45 + grow * 2, 0.32, 1.6), f.p(0, dy, -0.05), f.r(), color, mat, flags)
    p.cyl(0.14, 0.1, f.p(0, -0.19, 1.6), f.r(stand), "white", "SmoothPlastic", D, verts=10)  # the strap plugs
    for side in (-1, 1):
        p.cyl(0.13, 0.1, f.p(side * 0.6, -0.19, -0.3), f.r(stand), "white", "SmoothPlastic", D, verts=10)
    for z in (-1.2, -1.5, -1.8):  # tread on the heel
        p.box((1.0 - abs(z + 1.5) * 0.6, 0.06, 0.07), f.p(0, -0.18, z), f.r(), "navy", "SmoothPlastic", D)
    for side in (-1, 1):  # the white V strap on the back
        p.rod(f.p(0, 0.4, 1.6), f.p(side * 0.45, 0.85, 0.65), 0.14, "white", "SmoothPlastic", D)
        p.rod(f.p(side * 0.45, 0.85, 0.65), f.p(side * 0.65, 0.4, -0.3), 0.14, "white", "SmoothPlastic", D)
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
    # a giant red-and-yellow patang in a captain's hat, its string running to a spool
    f = Frame((0, 0, 4.4), (0, 8, 0))
    q = 1.3
    for k, (dx, dz, color) in enumerate(((0, q, "red"), (q, 0, "yellow"), (0, -q, "red"), (-q, 0, "yellow"))):
        p.box((1.84, 0.1, 1.84), f.p(dx, 0, dz), f.r((0, 45, 0)), color, "Fabric", D)
    p.rod(f.p(0, 0.08, 2.65), f.p(0, 0.08, -2.65), 0.06, "bamboo", "Wood", D, verts=4)
    bow = [(-2.5, 0.3), (-1.6, 0.9), (0, 1.15), (1.6, 0.9), (2.5, 0.3)]
    for (x0, z0), (x1, z1) in zip(bow, bow[1:]):
        p.rod(f.p(x0, 0.08, z0), f.p(x1, 0.08, z1), 0.05, "bamboo", "Wood", D, verts=4)
    eyes(p, 0, -0.12, 0.35, 0.85, 0.3, f=f)
    smile(p, 0, -0.1, -0.45, 0.6, f=f)
    blush(p, 0, -0.08, -0.1, 1.4, 0.16, f=f)
    hat = Frame((0, 0, 4.4), (0, 8, 0))
    p.cyl(0.55, 0.45, hat.p(0, 0, 2.8), hat.r(), "white", "Fabric", D, verts=12)
    p.cyl(0.58, 0.15, hat.p(0, 0, 2.65), hat.r(), "navy", "Fabric", D, verts=12)
    p.box((0.9, 0.5, 0.08), hat.p(0, -0.45, 2.58), hat.r(), "black", "SmoothPlastic", D)
    p.ball(0.12, hat.p(0, -0.56, 2.78), "gold", "Metal", D, segments=6, rings=4)
    tail = [f.p(0, 0, -2.6), (0.4, 0, 1.0), (-0.2, 0, 0.0)]
    for k, (a, b) in enumerate(zip(tail, tail[1:])):
        p.beam(a, b, 0.25, 0.06, ("pink", "skyblue")[k], "Fabric", D)
    for k in range(3):
        p.box((0.35, 0.06, 0.2), (0.25 - k * 0.2, 0, 1.6 - k * 0.55), (0, 45, 0), ("green", "orange", "purple")[k],
              "Fabric", D)
    p.rope(f.p(0, 0.1, 0), (1.6, 0.6, 0.6), 0.6, 0.03, "white", 6)
    p.cyl(0.4, 0.8, (1.6, 0.6, 0.45), (0, 90, 0), "wood", "Wood", D, verts=10)
    for side in (-1, 1):
        p.cyl(0.6, 0.08, (1.6 + side * 0.4, 0.6, 0.45), (0, 90, 0), "red", "Wood", D, verts=10)
    for i in range(5):
        a = i * 1.2
        p.box((0.14, 0.14, 0.14), (math.cos(a) * 2.6, 0.3, 4.4 + math.sin(a) * 2.2), (45, 45, 0), "gold", "Neon",
              D | KEEP)


@prop("ChandRaatCheetah", "brainrot")
def bangle_cheetah(p):
    # a sleek golden cheetah with glowing spots, glass bangles, mehndi paws and a moon charm
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
    spots = [(-0.6, -0.6, 2.4), (0.6, -0.2, 2.5), (-0.55, 0.6, 2.3), (0.6, 0.9, 2.2), (0, -0.2, 2.85), (0, 1.0, 2.75),
             (-0.5, 1.6, 2.1), (0.5, -1.1, 2.3)]
    for i, (x, y, z) in enumerate(spots):
        p.ball(0.15, (x, y, z), "spots", "SmoothPlastic", D, segments=6, rings=4)
    colours = ("red", "green", "blue", "gold", "pink", "purple")
    for x in (-0.45, 0.45):
        for y in (-1.0, 1.3):
            p.cyl(0.18, 1.6, (x, y, 0.85), None, "cheetah", "SmoothPlastic", D, verts=8)
            p.box((0.36, 0.5, 0.15), (x, y - 0.12, 0.07), None, "henna", "SmoothPlastic", D)
            if y < 0:
                for k in range(4):
                    p.cyl(0.26, 0.09, (x, y, 0.55 + k * 0.14), None, colours[(k + (x > 0) * 2) % 6], "Glass", D, verts=12)
    tail = [(0, 1.9, 2.1), (0, 2.6, 2.6), (0, 2.9, 3.4)]
    for a, b in zip(tail, tail[1:]):
        p.rod(a, b, 0.14, "cheetah", "SmoothPlastic", D)
    for k in range(4):
        p.cyl(0.22, 0.08, (0, 2.45 + k * 0.12, 2.45 + k * 0.2), (-35, 0, 0), colours[k + 1], "Glass", D, verts=10)
    p.cyl(0.62, 0.14, (0, -1.25, 2.45), (60, 0, 0), "gold", "Metal", D, verts=12)
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
    # a round laddoo uncle in a little vest, carrying a tray of sweets
    p.ball(1.5, (0, 0, 2.0), "laddoo", "SmoothPlastic", D, segments=14, rings=9)
    for i in range(12):
        a = i * 0.8
        p.detail((0.16, 0.16, 0.16), (math.cos(a) * 1.25, math.sin(a) * 0.9, 1.6 + (i % 4) * 0.35), (i * 20, i * 30, 0),
                 "saffron")
    p.cone(1.5, 1.0, (0, 0, 1.3), (180, 0, 0), "maroon", "Fabric", D, verts=14, top=1.15, fallback="Cylinder")
    for z in (1.1, 1.4):
        p.ball(0.08, (0, -1.38, z), "gold", "Metal", D, segments=6, rings=4)
    for x, y in ((-0.5, -0.3), (0.4, 0.2), (0.0, 0.5)):
        p.box((0.4, 0.4, 0.04), (x, y, 3.5), (0, 0, x * 60), "warq", "Foil", D)
    eyes(p, 0, -1.4, 2.4, 0.9, 0.3)
    moustache(p, 0, -1.48, 1.95, 1.2, "black", thick=0.22)
    smile(p, 0, -1.47, 1.75, 0.55, open_mouth=True)
    blush(p, 0, -1.38, 2.1, 1.45, 0.18)
    for side in (-1, 1):
        arm(p, (side * 1.3, -0.3, 1.8), (side * 0.75, -1.65, 1.5), 0.16, "laddoo")
        leg(p, side * 0.55, 0, 0.7, 0.22, "laddoo", "black")
    p.box((2.1, 1.2, 0.12), (0, -1.95, 1.55), None, "steel", "Metal", D)
    p.box((0.45, 0.45, 0.22), (-0.6, -1.95, 1.72), None, "barfi", "SmoothPlastic", D)
    p.box((0.35, 0.35, 0.05), (-0.6, -1.95, 1.85), None, "pistachio", "SmoothPlastic", D)
    p.cyl(0.28, 0.12, (0.05, -1.95, 1.68), None, "jalebi", "SmoothPlastic", D, verts=10)
    for x in (0.55, 0.85):
        p.ball(0.2, (x, -1.9, 1.8), "gulabjamun", "SmoothPlastic", D, segments=8, rings=5)


@prop("LassiLightning", "brainrot")
def lassi_lightning(p):
    # a flying lassi glass hero with goggles, a cape, lightning wings and blue sparks
    p.cyl(0.95, 2.8, (0, 0, 1.4), None, "glass", "Glass", D | GLASS, verts=16)
    p.cyl(0.86, 2.5, (0, 0, 1.3), None, "lassi", "SmoothPlastic", D, verts=16)
    p.blob(1.0, (0, 0, 2.85), (1, 1, 0.45), "malai", "SmoothPlastic", D, seed=250, fallback="Disc")
    eyes(p, 0, -0.9, 1.8, 0.75, 0.26)
    for side in (-1, 1):
        p.cyl(0.36, 0.14, (side * 0.38, -0.92, 1.8), (90, 0, 0), "black", "SmoothPlastic", D, verts=12)
        p.cyl(0.3, 0.12, (side * 0.38, -1.0, 1.8), (90, 0, 0), "lightning", "Glass", D | GLASS, verts=12)
    p.cyl(0.97, 0.12, (0, 0, 1.8), None, "black", "Fabric", D, verts=16)
    smile(p, 0, -0.95, 1.05, 0.45)
    p.rod((0.3, 0, 3.0), (0.6, 0.1, 4.3), 0.08, "red", "SmoothPlastic", D)
    for k, (a, b) in enumerate((((0.6, 0.1, 4.3), (0.85, 0.1, 4.7)), ((0.85, 0.1, 4.7), (0.6, 0.1, 4.9)),
                               ((0.6, 0.1, 4.9), (0.9, 0.1, 5.35)))):
        p.beam(a, b, 0.14, 0.08, "lightning", "Neon", D | KEEP | (LIGHT if k == 0 else 0))
    for side in (-1, 1):  # lightning-bolt wings
        pts = [(side * 0.9, 0.2, 2.0), (side * 1.6, 0.3, 2.6), (side * 1.35, 0.3, 2.75), (side * 2.1, 0.4, 3.4)]
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
    # a round yellow chick in a khaki watchman's uniform, with a whistle, stick and torch
    p.ball(1.3, (0, 0, 1.75), "chick", "SmoothPlastic", D, segments=14, rings=8)
    for k in range(3):
        p.box((0.12, 0.12, 0.5), (-0.15 + k * 0.15, 0.1, 3.15), (0, (k - 1) * 25, 0), "chick", "SmoothPlastic", D)
    p.cone(1.32, 1.1, (0, 0, 1.15), (180, 0, 0), "khaki", "Fabric", D, verts=14, top=1.0, fallback="Cylinder")
    p.cyl(1.3, 0.15, (0, 0, 1.0), None, "leather", "Fabric", D, verts=14)
    for z in (1.25, 1.55):
        p.ball(0.07, (0, -1.25, z), "gold", "Metal", D, segments=6, rings=4)
    for side in (-1, 1):
        p.box((0.4, 0.1, 0.35), (side * 0.55, -1.12, 1.45), (0, side * -20, 0), "khaki", "Fabric", D)
    p.cyl(0.62, 0.35, (0, 0, 3.0), None, "khaki", "Fabric", D, verts=12)
    p.box((1.0, 0.6, 0.08), (0, -0.55, 2.85), None, "black", "SmoothPlastic", D)
    p.ball(0.12, (0, -0.63, 3.08), "gold", "Metal", D, segments=6, rings=4)
    eyes(p, 0, -1.18, 2.3, 0.75, 0.27)
    brows(p, 0, -1.18, 2.3, 0.75, 0.27, "khaki", tilt=10)
    p.cone(0.22, 0.4, (0, -1.4, 1.95), (90, 0, 0), "orange", "SmoothPlastic", D, verts=6, fallback="Cylinder")
    p.cyl(0.08, 0.25, (0.25, -1.45, 1.9), (90, 0, 0), "steel", "Metal", D, verts=6)
    p.rope((0.25, -1.4, 1.9), (0.8, -0.6, 2.3), 0.3, 0.03, "rope", 4)
    for side in (-1, 1):
        p.box((0.25, 0.8, 0.9), (side * 1.25, -0.2, 1.7), (0, side * -15, 0), "chick", "SmoothPlastic", D)
        p.box((0.25, 0.6, 0.12), (side * 0.45, -0.25, 0.06), None, "orange", "SmoothPlastic", D)
        p.rod((side * 0.45, 0, 0.6), (side * 0.45, -0.1, 0.1), 0.07, "orange", "SmoothPlastic", D)
    p.rod((1.5, -0.6, 0.0), (1.45, -0.6, 2.4), 0.07, "lightwood", "Wood", D)
    p.cyl(0.18, 0.7, (-1.5, -0.7, 1.5), (90, 0, 0), "black", "Metal", D, verts=10)
    p.cyl(0.16, 0.05, (-1.5, -1.07, 1.5), (90, 0, 0), "yellow", "Neon", D | KEEP | LIGHT, verts=10)


@prop("RangeelaRaja", "brainrot")
def rangeela_raja(p):
    # a plump peacock king with a rainbow tail fan, a crown and puffs of colour
    rainbow = ("red", "orange", "yellow", "green", "teal", "blue", "purple")
    for i, color in enumerate(rainbow):
        a = math.radians(-66 + i * 22)
        tip = (math.sin(a) * 3.2, 0.9, 1.6 + math.cos(a) * 3.2)
        p.beam((0, 0.7, 1.5), tip, 0.7, 0.08, color, "SmoothPlastic", D)
        p.cyl(0.32, 0.06, (tip[0] * 0.95, 0.82, tip[2] - 0.05), (90 - 0, 0, 0), "navy", "SmoothPlastic", D, verts=10)
        p.cyl(0.18, 0.08, (tip[0] * 0.95, 0.78, tip[2] - 0.05), (90, 0, 0), "peacockteal", "SmoothPlastic", D, verts=8)
    p.blob(1.1, (0, 0, 2.0), (0.9, 1.0, 1.25), "peacock", "SmoothPlastic", D, seed=260, jitter=0.02,
           fallback="Ball")
    p.blob(0.62, (0, -0.35, 3.45), (1, 1, 1.05), "peacock", "SmoothPlastic", D, seed=261, jitter=0.02,
           fallback="Ball")
    p.cone(0.15, 0.35, (0, -0.98, 3.35), (90, 0, 0), "cream2", "SmoothPlastic", D, verts=6, fallback="Cylinder")
    eyes(p, 0, -0.85, 3.6, 0.5, 0.19)
    crown(p, 0, -0.35, 3.98, 0.38, "gold", "green")
    for side in (-1, 1):
        p.box((0.3, 0.9, 1.2), (side * 0.9, 0.1, 2.0), (0, side * -12, 0), "peacockteal", "SmoothPlastic", D)
        p.rod((side * 0.35, 0, 0.9), (side * 0.4, -0.15, 0.1), 0.07, "cream2", "SmoothPlastic", D)
        p.box((0.3, 0.6, 0.1), (side * 0.4, -0.3, 0.05), None, "cream2", "SmoothPlastic", D)
    for i, color in enumerate(("pink", "yellow", "lime", "skyblue")):
        a = i * 1.6 + 0.4
        p.blob(0.35, (math.cos(a) * 1.4, -0.4 + math.sin(a) * 0.9, 0.35), (1, 1, 0.8), color, "SmoothPlastic", D,
               seed=262 + i, fallback="Ball")


@prop("ShalimarSultan", "brainrot")
def shalimar_sultan(p):
    # a floating sultan whose body is a tiered marble garden fountain with a crown of water jets
    p.cyl(1.6, 0.5, (0, 0, 0.25), None, "white", "Marble", D, verts=18)
    p.cyl(1.4, 0.08, (0, 0, 0.52), None, "fountain", "Glass", D | GLASS, verts=18)
    p.cyl(0.45, 1.2, (0, 0, 1.1), None, "white", "Marble", D, verts=12)
    p.cyl(1.15, 0.35, (0, 0, 1.85), None, "white", "Marble", D, verts=16)
    p.cyl(0.95, 0.07, (0, 0, 2.04), None, "fountain", "Glass", D | GLASS, verts=16)
    p.ball(0.9, (0, 0, 2.8), "cream2", "Marble", D, segments=14, rings=8)
    p.blob(0.85, (0, 0.05, 3.55), (1.15, 1.15, 0.62), "green", "Fabric", D, seed=280, jitter=0.04,
           fallback="Ball", fallback_scale=(1, 1, 0.7))  # the turban
    p.cyl(0.98, 0.16, (0, 0.05, 3.3), None, "gold", "Metal", D, verts=14)
    p.ball(0.17, (0, -0.95, 3.5), "red", "SmoothPlastic", D, segments=8, rings=5)
    p.cyl(0.24, 0.08, (0, -0.9, 3.5), (90, 0, 0), "gold", "Metal", D, verts=10)
    eyes(p, 0, -0.84, 2.95, 0.6, 0.21)
    moustache(p, 0, -0.9, 2.55, 0.85, "black", thick=0.17)
    smile(p, 0, -0.88, 2.38, 0.3)
    blush(p, 0, -0.8, 2.7, 1.05, 0.12)
    for i in range(5):  # a crown of water jets rising from the turban
        a = i * 2 * math.pi / 5 + math.pi / 2
        base = (math.cos(a) * 0.25, math.sin(a) * 0.25, 3.85)
        top = (math.cos(a) * 0.7, math.sin(a) * 0.7, 4.75)
        p.rod(base, top, 0.08, "fountain", "Glass", D | GLASS, verts=6)
        p.ball(0.12, (top[0] * 1.15, top[1] * 1.15, 4.6), "fountain", "Glass", D | GLASS, segments=6, rings=4)
    for side in (-1, 1):
        p.cone(0.38, 1.6, (side * 1.0, 0, 2.75), None, "cypress", "Grass", D, verts=8, fallback="Cylinder",
               fallback_scale=(0.7, 0.7, 1))
    for i in range(8):
        a = i * 2 * math.pi / 8
        p.ball(0.16, (math.cos(a) * 1.55, math.sin(a) * 1.55, 0.6), ("pink", "yellow", "white", "red")[i % 4],
               "SmoothPlastic", D, segments=6, rings=4)


@prop("TaaronWalaTonga", "brainrot")
def star_tonga(p):
    # a starry night-blue tonga pulled by a glowing winged horse, crescent-moon wheels
    p.box((2.6, 2.4, 0.35), (0, 0.6, 1.9), None, "starnavy", "WoodPlanks", D)
    p.box((2.6, 0.2, 1.0), (0, 1.75, 2.55), None, "starnavy", "WoodPlanks", D)
    for x in (-1.2, 1.2):
        for y in (-0.5, 1.7):
            p.rod((x, y, 2.05), (x, y, 3.6), 0.06, "gold", "Metal", D)
    p.box((2.8, 2.6, 0.2), (0, 0.6, 3.7), None, "starnavy", "Fabric", D)
    for k in range(6):
        p.ball(0.11, (-1.25 + k * 0.5, -0.65, 3.5), "gold", "SmoothPlastic", D, segments=6, rings=4)
    for i in range(6):
        x = -1.0 + (i % 3) * 1.0
        y = 0.1 + (i // 3) * 1.0
        for k in range(2):
            p.box((0.3, 0.06, 0.06), (x, y, 3.82), (0, 0, k * 90 + 45), "yellow", "Neon", D | KEEP)
    for side in (-1, 1):
        p.cyl(1.0, 0.2, (side * 1.45, 0.6, 1.3), (0, 90, 0), "gold", "Neon", D | KEEP, verts=16)
        p.cyl(0.8, 0.24, (side * 1.45, 0.75, 1.55), (0, 90, 0), "starnavy", "SmoothPlastic", D, verts=16)
    p.rod((0, -0.6, 2.1), (0, -1.6, 2.3), 0.07, "gold", "Metal", D)
    # the winged horse
    p.blob(0.75, (0, -2.3, 2.4), (0.8, 1.35, 0.8), "white", "SmoothPlastic", D, seed=270, jitter=0.02,
           fallback="Ball")
    p.rod((0, -2.9, 2.7), (0, -3.2, 3.3), 0.3, "white", "SmoothPlastic", D)
    p.blob(0.45, (0, -3.45, 3.5), (0.8, 1.2, 0.8), "white", "SmoothPlastic", D, seed=271, fallback="Ball")
    for side in (-1, 1):
        p.box((0.1, 0.1, 0.3), (side * 0.18, -3.3, 3.95), None, "white", "SmoothPlastic", D)
        wing(p, (side * 0.5, -2.2, 2.8), side, 1.3, 0.9, "white", angle=35)
        for y in (-2.0, -2.7):
            p.rod((side * 0.3, y, 2.1), (side * 0.3, y + 0.3, 1.35), 0.09, "white", "SmoothPlastic", D, verts=6)
    for k in range(3):
        p.box((0.12, 0.25, 0.35), (0, -3.05 + k * 0.2, 3.7 - k * 0.25), (-30, 0, 0), "lightning", "Neon", D | KEEP)
    eyes(p, 0, -3.95, 3.6, 0.36, 0.13)
    smile(p, 0, -4.0, 3.3, 0.22)
    p.box((0.3, 0.3, 0.4), (1.3, -0.65, 3.3), None, "gold", "Metal", D)
    p.box((0.22, 0.22, 0.3), (1.3, -0.65, 3.3), None, "yellow", "Neon", D | KEEP | LIGHT)
    for i in range(5):
        p.box((0.14, 0.14, 0.14), (0.4 - i * 0.2, 2.2 + i * 0.5, 1.6 + i * 0.15), (45, 45, 0), "white", "Neon",
              D | KEEP)
