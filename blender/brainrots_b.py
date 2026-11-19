"""Brainrot models, part 2: the Rares and Epics."""

import math

import style
from brainrot_kit import block_arm, block_cap, block_leg, chunk, cube_puff, D, Frame, arm, blush, brows, cap, crown, eyes, leg, moustache, puffs, rope_ring, smile, wing
from kit import GLASS, KEEP, LIGHT, PARTSONLY, prop


# -------------------------------------------------------------------- Rares
@prop("LoadSheddingLattoo", "brainrot")
def lattoo(p):
    # a striped wooden spinning top with a light bulb for a head. The top is a stack
    # of chunky square slabs; the glowing bulb head stays round.
    p.box((0.4, 0.4, 0.25), (0, 0, 0.12), (0, 0, 45), "metal", "Metal", D)
    p.box((0.62, 0.62, 0.22), (0, 0, 0.34), (0, 0, 45), "metal", "Metal", D)
    radii = (0.55, 0.85, 1.15, 1.4, 1.55, 1.55, 1.3, 0.9)
    z = 0.45
    for k, r in enumerate(radii):
        h = 0.32
        p.box((r * 1.8, r * 1.8, h), (0, 0, z + h / 2), None, "red" if k % 2 == 0 else "yellow", "Wood", D)
        z += h
    for k in range(3):
        p.box((2.56, 2.56, 0.06), (0, 0, 1.35 + k * 0.14), None, "rope", "Fabric", D)
    style.diamonds(p, -1.25, 1.25, -1.43, 2.33, height=0.24, band="dhabateal", colors=("gold", "white"))
    p.box((0.7, 0.7, 0.45), (0, 0, z + 0.2), (0, 0, 45), "metal", "Metal", D)
    p.ball(0.75, (0, 0, z + 1.0), "bulb", "Neon", D | LIGHT)
    p.box((0.08, 0.08, 0.6), (0, 0, z + 0.9), None, "darkmetal", "Metal", D)
    eyes(p, 0, -1.48, 2.0, 0.85, 0.27)
    brows(p, 0, -1.48, 2.0, 0.85, 0.27, tilt=-15)
    smile(p, 0, -1.32, 1.55, 0.55, open_mouth=True)


@prop("BiryaniBadshah", "brainrot")
def biryani(p):
    # a copper biryani degh with rice hair, a crown with a potato jewel and a ladle
    # sceptre. The degh is a chunky square pot with a gold band of diamonds.
    p.box((2.5, 2.5, 0.3), (0, 0, 0.25), None, "copper", "Metal", D)
    p.box((3.1, 3.1, 1.6), (0, 0, 1.2), None, "copper", "Metal", D)
    p.box((3.3, 3.3, 0.2), (0, 0, 2.0), None, "gold", "Metal", D)
    style.diamonds(p, -1.4, 1.4, -1.6, 0.55, height=0.3, band="gold", colors=("red", "dhabateal"))
    for side in (-1, 1):
        p.box((0.25, 0.5, 0.5), (side * 1.68, 0, 1.6), None, "copper", "Metal", D)
    p.blob(1.55, (0, 0, 2.2), (1, 1, 0.6), "rice", "SmoothPlastic", D, seed=100, jitter=0.12, fallback="None")
    for spin in (0, 45):
        p.box((2.8, 2.8, 0.5), (0, 0, 2.3 + spin * 0.001), (0, 0, spin), "rice", "SmoothPlastic", D | PARTSONLY)
    for i in range(5):
        a = i * 1.25
        p.box((0.4, 0.4, 0.14), (math.cos(a) * 0.8, math.sin(a) * 0.8, 2.6), (0, 0, i * 30), "saffron",
              "SmoothPlastic", D)
    crown(p, 0, 0, 2.95, 0.75, "gold", "red")
    p.box((0.4, 0.32, 0.36), (0, -0.72, 3.25), (0, 0, 45), "potato", "SmoothPlastic", D)
    eyes(p, 0, -1.6, 1.45, 0.9, 0.3)
    moustache(p, 0, -1.68, 1.0, 1.7, "black", thick=0.28)
    smile(p, 0, -1.66, 0.82, 0.5)
    for side in (-1, 1):
        p.box((0.45, 0.55, 0.36), (side * 0.6, -1.0, 0.18), None, "copper", "Metal", D)
    block_arm(p, (1.6, -0.2, 1.3), (1.9, -0.45, 1.45), 0.28, "copper", "gold", 0.38)
    p.box((0.14, 0.14, 3.0), (1.95, -0.45, 1.8), None, "steel", "Metal", D)
    p.box((0.55, 0.55, 0.3), (1.95, -0.45, 3.4), (0, 0, 45), "steel", "Metal", D)
    block_arm(p, (-1.6, -0.2, 1.3), (-1.95, -0.6, 1.1), 0.28, "copper", "gold", 0.38)


@prop("CricketBatBhaijaan", "brainrot")
def cricket_bat(p):
    # a cricket bat in a green jersey with a gold band, a blocky cap on its handle,
    # commentating into a mic
    p.box((1.45, 0.45, 2.6), (0, 0, 2.2), None, "willow", "Wood", D)
    p.box((0.9, 0.2, 2.4), (0, 0.3, 2.2), None, "willow", "Wood", D)
    p.box((1.55, 0.6, 1.25), (0, 0, 1.55), None, "jersey", "Fabric", D)
    p.box((0.6, 0.62, 0.15), (0, 0, 2.1), None, "white", "Fabric", D)
    style.diamonds(p, -0.72, 0.72, -0.36, 1.08, height=0.22, band="gold", colors=("white", "jersey"), step=0.38)
    p.box((0.1, 0.05, 0.5), (-0.18, -0.32, 1.55), None, "white", "Fabric", D)
    p.cyl(0.2, 0.05, (0.18, -0.32, 1.55), (90, 0, 0), "white", "Fabric", D, verts=12)
    p.cyl(0.11, 0.06, (0.18, -0.34, 1.55), (90, 0, 0), "jersey", "Fabric", D, verts=10)
    p.box((0.38, 0.38, 1.1), (0, 0, 4.05), None, "willow", "Wood", D)
    p.box((0.46, 0.46, 0.85), (0, 0, 4.15), None, "red", "Fabric", D)
    block_cap(p, 0, 0, 4.75, 0.42, "blue", "navy", band="gold")
    eyes(p, 0, -0.25, 3.05, 0.7, 0.24)
    smile(p, 0, -0.3, 2.6, 0.45, open_mouth=True)
    block_arm(p, (-0.75, 0, 1.8), (-0.55, -0.7, 2.45), 0.24, "jersey", "white", 0.34)
    p.box((0.12, 0.12, 0.4), (-0.47, -0.67, 2.65), (0, 20, 0), "black", "SmoothPlastic", D)
    p.box((0.34, 0.34, 0.34), (-0.38, -0.65, 2.9), (45, 35.26, 0), "darkmetal", "Metal", D)
    block_arm(p, (0.75, 0, 1.8), (1.25, -0.2, 1.35), 0.24, "jersey", "white", 0.34)
    for side in (-1, 1):
        block_leg(p, side * 0.35, 0, 0.95, 0.28, "white", "black")


@prop("DhabaDragon", "brainrot")
def dhaba_dragon(p):
    # a chubby red dragon with a glowing tandoor belly, breathing a naan. A chunky
    # body with a stepped clay tandoor ringed in gold diamonds; its head stays round.
    chunk(p, 1.25, (0, 0.2, 1.7), (1, 1.05, 1.05), "dragon", seed=110)
    p.cone(0.95, 1.1, (0, -0.85, 1.55), (90, 0, 0), "clay", "Slate", D, verts=12, top=0.75, fallback="None")
    p.box((1.7, 0.5, 1.7), (0, -1.05, 1.55), None, "clay", "Slate", D | PARTSONLY)
    p.box((1.4, 0.4, 1.4), (0, -1.4, 1.55), None, "clay", "Slate", D | PARTSONLY)
    style.diamonds(p, -0.8, 0.8, -1.35, 2.3, height=0.24, band="gold", colors=("red", "dhabateal"), step=0.45)
    p.box((0.95, 0.1, 0.95), (0, -1.62, 1.55), None, "flame", "Neon", D | LIGHT)
    p.blob(0.8, (0, -0.4, 3.15), (1, 1.05, 0.95), "dragon", "SmoothPlastic", D, seed=111, jitter=0.03,
           fallback="Ball")
    p.box((0.7, 0.55, 0.45), (0, -1.05, 3.0), None, "dragon", "SmoothPlastic", D)
    for side in (-1, 1):
        p.box((0.24, 0.24, 0.55), (side * 0.4, -0.2, 3.95), (0, side * 20, 0), "cream2", "SmoothPlastic", D)
        wing(p, (side * 0.8, 0.6, 2.4), side, 1.2, 1.0, "maroon", angle=35, style="bat")
    eyes(p, 0, -1.0, 3.35, 0.62, 0.22)
    smile(p, 0, -1.34, 2.95, 0.4)
    p.box((0.5, 1.4, 0.12), (0.75, 0.0, 2.55), (0, 30, 0), "white", "Fabric", D)
    p.box((0.52, 0.16, 0.14), (0.75, -0.7, 2.55), (0, 30, 0), "dhabateal", "Fabric", D)
    for a, b, r in (((0, 1.3, 1.2), (0, 2.2, 0.8), 0.55), ((0, 2.2, 0.8), (0, 2.9, 0.6), 0.38)):
        p.beam(a, b, r, r, "dragon", "SmoothPlastic", D)
    p.box((0.45, 0.45, 0.12), (0, 3.05, 0.6), (0, 0, 45), "maroon", "SmoothPlastic", D)
    for side in (-1, 1):
        block_leg(p, side * 0.55, 0.1, 0.6, 0.54, "dragon", "maroon")
    p.box((0.5, 0.5, 0.5), (0, -1.6, 2.95), (45, 35.26, 0), "flame", "Neon", D | KEEP)
    p.blob(0.45, (0, -2.25, 3.15), (1, 0.35, 0.8), "naan", "SmoothPlastic", D, seed=113, fallback="None")
    p.box((0.85, 0.28, 0.65), (0, -2.25, 3.15), (0, 0, 8), "naan", "SmoothPlastic", D | PARTSONLY)


@prop("GeneratorGainda", "brainrot")
def generator_rhino(p):
    # a grey rhino with a truck-art painted yellow generator on its back and fairy
    # lights on its horn. A chunky body; its head stays round.
    chunk(p, 1.3, (0, 0.2, 1.45), (1, 1.4, 0.9), "rhinogrey", seed=120)
    p.blob(0.8, (0, -1.55, 1.65), (1, 1.05, 0.95), "rhinogrey", "SmoothPlastic", D, seed=121, jitter=0.03,
           fallback="Ball")
    p.box((0.4, 0.4, 0.5), (0, -2.25, 2.35), (-30, 0, 45), "cream2", "SmoothPlastic", D)  # the horns
    p.box((0.26, 0.26, 0.45), (0, -2.42, 2.7), (-30, 0, 45), "cream2", "SmoothPlastic", D)
    p.box((0.22, 0.22, 0.4), (0, -1.95, 2.45), (-15, 0, 45), "cream2", "SmoothPlastic", D)
    for side in (-1, 1):
        p.box((0.2, 0.12, 0.35), (side * 0.45, -1.3, 2.4), (0, side * -20, 0), "rhinogrey", "SmoothPlastic", D)
    eyes(p, 0, -2.36, 1.95, 0.75, 0.2)  # on the front of the head (further in, they were hidden)
    smile(p, 0, -2.4, 1.5, 0.4)
    for x in (-0.65, 0.65):
        for y in (-0.8, 1.0):
            block_leg(p, x, y, 0.8, 0.6, "rhinogrey")
    p.box((1.6, 1.3, 0.95), (0, 0.4, 2.55), None, "yellow", "Metal", D)
    for side in (-1, 1):
        style.side_diamonds(p, side * 0.83, -0.1, 0.9, 2.3, height=0.3, band="red", colors=("dhabateal", "white"))
    for x in (-0.85, 0.85):
        p.box((0.1, 1.4, 0.1), (x, 0.4, 3.05), None, "black", "Metal", D)
        p.box((0.1, 0.1, 1.0), (x, -0.25, 2.55), None, "black", "Metal", D)
    p.box((0.9, 0.08, 0.4), (0, -0.28, 2.55), None, "darkmetal", "Metal", D)
    p.box((0.24, 0.24, 0.8), (0.6, 1.0, 3.3), None, "darkmetal", "Metal", D)
    cube_puff(p, [(0.6, 1.1, 3.95), (0.7, 1.4, 4.3)], 0.42, "stone")
    p.beam((-0.5, 0.0, 2.7), (-0.75, -0.3, 2.95), 0.1, 0.1, "darkmetal", "Metal", D)
    p.box((0.35, 0.12, 0.12), (-0.8, -0.35, 2.98), None, "red", "SmoothPlastic", D)
    wire = [(0.3, -0.2, 2.9), (0.25, -1.0, 2.55), (0.1, -1.7, 2.45), (0, -2.35, 2.6)]
    for a, b in zip(wire, wire[1:]):
        p.beam(a, b, 0.07, 0.07, "black", "SmoothPlastic", D)
    for i, color in enumerate(("yellow", "pink", "skyblue", "lime")):
        q = wire[min(i, 3)]
        p.ball(0.11, (q[0], q[1], q[2] - 0.12), color, "Neon", D | KEEP | (LIGHT if i == 0 else 0), segments=6,
               rings=4)


@prop("ShaadiShehnaiShark", "brainrot")
def wedding_shark(p):
    # a friendly blue shark standing on its tail, in a maroon sherwani with a gold
    # band of embroidered diamonds and a marigold garland, playing the shehnai. A
    # chunky body; the rounded snout on top stays round.
    chunk(p, 1.05, (0, 0, 2.75), (0.95, 0.92, 1.7), "shark", seed=130)
    p.blob(0.85, (0, -0.32, 2.95), (0.85, 0.62, 1.55), "sharkbelly", "SmoothPlastic", D, seed=131, jitter=0.0,
           fallback="None")
    p.box((1.2, 0.2, 1.2), (0, -0.82, 3.5), None, "sharkbelly", "SmoothPlastic", D | PARTSONLY)
    p.blob(0.72, (0, 0.05, 4.3), (0.95, 0.95, 1.1), "shark", "SmoothPlastic", D, seed=132, jitter=0.0,
           fallback="Ball")  # the rounded snout on top
    for side in (-1, 1):  # the tail it stands on
        p.box((1.2, 0.42, 0.22), (side * 0.62, 0.15, 0.35), (0, side * -28, 0), "shark", "SmoothPlastic", D)
    p.box((0.7, 0.5, 0.5), (0, 0.15, 0.55), None, "shark", "SmoothPlastic", D)
    p.box((0.2, 1.1, 1.1), (0, 0.95, 3.15), (45, 0, 0), "shark", "SmoothPlastic", D)  # the big back fin
    p.box((2.05, 1.95, 1.4), (0, 0, 2.0), None, "maroon", "Fabric", D)  # the sherwani
    p.box((2.1, 2.0, 0.15), (0, 0, 2.75), None, "gold", "Metal", D)
    style.diamonds(p, -0.9, 0.9, -1.03, 1.45, height=0.28, band="gold", colors=("dhabateal", "red"), step=0.45)
    for z in (1.85, 2.2, 2.5):
        p.box((0.14, 0.1, 0.14), (0, -1.02, z), (0, 45, 0), "gold", "Metal", D)
    for i in range(12):  # the marigold garland
        a = i * 2 * math.pi / 12
        p.ball(0.16, (math.cos(a) * 0.98, math.sin(a) * 0.92, 2.92 - (0.25 if math.sin(a) < -0.5 else 0)),
               "marigold" if i % 2 else "orange", "SmoothPlastic", D, segments=6, rings=4)
    eyes(p, 0, -0.8, 3.85, 0.66, 0.23)
    blush(p, 0, -0.9, 3.5, 1.15, 0.13)
    p.box((0.75, 0.1, 0.12), (0, -0.93, 3.3), None, "black", "SmoothPlastic", D)  # a wide grin with little teeth
    for side in (-1, 1):
        p.box((0.22, 0.1, 0.12), (side * 0.45, -0.92, 3.38), (0, side * -30, 0), "black", "SmoothPlastic", D)
    for x in (-0.24, -0.08, 0.08, 0.24):
        p.cone(0.06, 0.12, (x, -0.96, 3.2), (180, 0, 0), "white", "SmoothPlastic", D, verts=4, fallback="Block")
    for side in (-1, 1):  # gills
        for k in range(3):
            p.box((0.06, 0.25, 0.04), (side * 0.92, -0.15, 3.45 + k * 0.17), (0, 0, side * 30), "navy",
                  "SmoothPlastic", D)
    p.beam((0.25, -1.0, 3.2), (0.25, -1.75, 2.75), 0.18, 0.18, "wood", "Wood", D)  # the shehnai
    p.box((0.5, 0.3, 0.5), (0.25, -1.95, 2.65), (30, 0, 45), "gold", "Metal", D)
    for side in (-1, 1):
        p.box((0.75, 0.3, 0.15), (side * 0.7, -0.6, 2.6), (0, side * -40, side * 20), "shark", "SmoothPlastic", D)


# -------------------------------------------------------------------- Epics
@prop("ChipaSahab", "brainrot")
def chipa_sahab(p):
    # a tiny uncle with a gigantic moustache, glasses, sweater vest and suction-cup hands
    p.ball(1.1, (0, 0, 1.75), "uncle", "SmoothPlastic", D, segments=14, rings=8)
    p.cone(1.12, 1.0, (0, 0, 1.15), (180, 0, 0), "vest", "Fabric", D, verts=14, top=0.8, fallback="Cylinder")
    for k in range(3):
        p.detail((1.0, 0.06, 0.08), (0, -0.98, 0.9 + k * 0.3), (0, 0, 0), "white")
    for side in (-1, 1):
        p.blob(0.3, (side * 0.95, 0.15, 2.3), (0.8, 1, 0.9), "white", "SmoothPlastic", D, seed=140 + side,
               fallback="Ball")
        p.cyl(0.3, 0.07, (side * 0.36, -1.0, 2.05), (90, 0, 0), "black", "SmoothPlastic", D, verts=12)
    eyes(p, 0, -0.98, 2.05, 0.72, 0.22)
    p.box((0.2, 0.06, 0.06), (0, -1.07, 2.05), None, "black", "SmoothPlastic", D)
    # the gigantic moustache, much wider than him
    for side in (-1, 1):
        p.box((1.5, 0.3, 0.32), (side * 0.85, -1.08, 1.6), (0, side * 10, 0), "black", "SmoothPlastic", D)
        p.box((0.6, 0.3, 0.3), (side * 1.75, -1.05, 1.85), (0, side * -40, 0), "black", "SmoothPlastic", D)
        p.ball(0.26, (side * 2.0, -1.03, 2.1), "black", "SmoothPlastic", D)
    p.ball(0.18, (0, -1.15, 1.8), "uncle", "SmoothPlastic", D)
    for side in (-1, 1):
        arm(p, (side * 0.95, 0, 1.3), (side * 1.45, -0.3, 0.9), 0.12, "vest", "uncle", 0.15)
        p.cyl(0.3, 0.12, (side * 1.5, -0.38, 0.85), (90, 0, 0), "red", "SmoothPlastic", D, verts=10)
        p.rod((side * 0.4, 0, 0.6), (side * 0.45, 0, 0.12), 0.12, "vest", "SmoothPlastic", D)
        p.cyl(0.32, 0.12, (side * 0.45, -0.05, 0.06), None, "red", "SmoothPlastic", D, verts=10)
    p.box((1.0, 0.14, 1.25), (-1.2, 0.1, 1.2), (0, -15, 0), "newspaper", "Fabric", D)
    for k in range(4):
        p.detail((0.7, 0.04, 0.05), (-1.2, -0.0, 0.85 + k * 0.22), (0, -15, 0), "stone")


@prop("JalebiJinn", "brainrot")
def jalebi_jinn(p):
    # a chubby jalebi genie swirling up out of a mithai box, sweets orbiting
    p.box((1.8, 1.8, 0.6), (0, 0.3, 0.3), None, "pink", "SmoothPlastic", D)
    p.box((1.85, 0.12, 1.2), (0, 1.25, 0.95), (-20, 0, 0), "pink", "SmoothPlastic", D)
    pts = []
    for i in range(18):
        t = i / 17
        a = t * 4 * math.pi
        r = 0.85 - t * 0.55
        pts.append((math.cos(a) * r, 0.3 + math.sin(a) * r * 0.8, 0.6 + t * 1.9))
    for a, b in zip(pts, pts[1:]):
        p.rod(a, b, 0.24, "jalebi", "SmoothPlastic", D, verts=8)
    p.blob(1.0, (0, 0.2, 3.1), (1.05, 0.95, 0.9), "jalebi", "SmoothPlastic", D, seed=150, jitter=0.03,
           fallback="Ball")
    p.blob(0.72, (0, 0.1, 4.25), (1, 1, 1), "saffron", "SmoothPlastic", D, seed=151, jitter=0.02, fallback="Ball")
    hair = []
    for i in range(8):
        t = i / 7
        a = t * 2 * math.pi
        hair.append((math.cos(a) * 0.3 * (1 - t * 0.5), 0.15 + math.sin(a) * 0.3, 4.95 + t * 0.4))
    for a, b in zip(hair, hair[1:]):
        p.rod(a, b, 0.11, "jalebi", "SmoothPlastic", D, verts=6)
    eyes(p, 0, -0.55, 4.35, 0.58, 0.21)
    moustache(p, 0, -0.66, 3.95, 0.95, "black", thick=0.18)
    smile(p, 0, -0.64, 3.78, 0.36)
    for side in (-1, 1):  # arms crossed
        arm(p, (side * 0.95, 0.1, 3.3), (-side * 0.35, -0.85, 3.05), 0.16, "jalebi", "saffron", 0.22)
        p.ball(0.12, (side * 0.72, -0.1, 4.25), "gold", "Metal", D, segments=6, rings=4)
    sweets = [("laddoo", "ball"), ("barfi", "box"), ("gulabjamun", "ball"), ("laddoo", "ball"), ("barfi", "box")]
    for i, (color, kind) in enumerate(sweets):
        a = i * 2 * math.pi / len(sweets)
        pos = (math.cos(a) * 1.8, 0.2 + math.sin(a) * 1.6, 3.4 + math.sin(a * 2) * 0.3)
        if kind == "ball":
            p.ball(0.22, pos, color, "SmoothPlastic", D, segments=8, rings=5)
        else:
            p.box((0.4, 0.4, 0.2), pos, (0, 0, i * 30), color, "SmoothPlastic", D)
            p.box((0.3, 0.3, 0.05), (pos[0], pos[1], pos[2] + 0.12), (0, 0, i * 30), "pistachio", "SmoothPlastic", D)


@prop("MehndiMummy", "brainrot")
def mehndi_mummy(p):
    # a cute mummy in henna-patterned bandages, holding a henna cone like a pen
    p.cyl(0.95, 2.4, (0, 0, 1.75), None, "bandage", "Fabric", D, verts=14)
    p.ball(0.95, (0, 0, 3.0), "bandage", "Fabric", D, segments=14, rings=8)
    p.ball(0.95, (0, 0, 0.6), "bandage", "Fabric", D, segments=14, rings=8)
    for k in range(6):
        p.cyl(0.98, 0.12, (0, 0, 0.9 + k * 0.42), (8 if k % 2 else -8, 0, 0), "cream2", "Fabric", D, verts=14)
    p.box((1.3, 0.2, 0.36), (0, -0.86, 3.05), None, "black", "Fabric", D)
    eyes(p, 0, -0.9, 3.05, 0.6, 0.24)
    blush(p, 0, -0.92, 2.7, 1.0, 0.14)
    smile(p, 0, -0.95, 2.55, 0.32)
    for i, (x, z) in enumerate(((-0.35, 1.9), (0.3, 1.5), (0.0, 2.2), (-0.45, 1.2), (0.45, 2.3), (0.15, 1.05))):
        p.blob(0.14, (x, -0.95, z), (1, 0.35, 1.4), "henna", "SmoothPlastic", D, seed=160 + i, fallback="Ball")
    for k in range(10):
        a = k * 0.6
        p.detail((0.07, 0.04, 0.07), (math.cos(a) * 0.55, -0.97, 1.6 + math.sin(a) * 0.45), (0, 0, 0), "henna")
    for side in (-1, 1):
        arm(p, (side * 0.9, -0.2, 2.25), (side * 0.75, -1.2, 2.3), 0.18, "bandage", "bandage", 0.22)
        leg(p, side * 0.38, 0, 0.5, 0.2, "bandage", "bandage")
    p.cone(0.14, 0.75, (0.75, -1.45, 2.1), (-55, 0, 0), "henna", "SmoothPlastic", D, verts=6, top=0.05,
           fallback="Cylinder")
    for k in range(3):  # the trailing bandage
        p.box((0.25, 0.7, 0.06), (-0.5 - k * 0.1, 1.0 + k * 0.55, 1.6 - k * 0.45), (-30 - k * 10, 0, 10), "bandage",
              "Fabric", D)


@prop("DholakDino", "brainrot")
def dholak_dino(p):
    # a chubby green dino with a painted dholak belly, drumming and stomping
    p.blob(1.2, (0, 0.25, 2.25), (1, 1, 1.1), "dino", "SmoothPlastic", D, seed=170, jitter=0.03, fallback="Ball")
    p.cyl(0.85, 2.0, (0, -0.85, 2.0), (0, 90, 0), "red", "Wood", D, verts=14)
    for x in (-0.6, 0, 0.6):
        p.cyl(0.88, 0.14, (x, -0.85, 2.0), (0, 90, 0), "yellow", "Wood", D, verts=14)
    for side in (-1, 1):
        p.cyl(0.82, 0.06, (side * 1.02, -0.85, 2.0), (0, 90, 0), "cream2", "Fabric", D, verts=14)
    for k in range(6):
        a = k * math.pi / 3
        p.detail((1.9, 0.05, 0.05), (0, -0.85 + math.cos(a) * 0.86, 2.0 + math.sin(a) * 0.86), (0, 0, 0), "cream2")
    p.blob(0.85, (0, -0.45, 3.8), (1, 1.1, 0.95), "dino", "SmoothPlastic", D, seed=171, jitter=0.03,
           fallback="Ball")
    p.box((0.75, 0.6, 0.45), (0, -1.15, 3.65), None, "dino", "SmoothPlastic", D)
    eyes(p, 0, -1.1, 4.0, 0.65, 0.22)
    smile(p, 0, -1.48, 3.55, 0.45, open_mouth=True)
    for k in range(4):
        p.cone(0.2, 0.45, (0, 0.6 + k * 0.35, 3.75 - k * 0.45), (-20 - k * 10, 0, 0), "lime", "SmoothPlastic", D,
               verts=6, fallback="Cylinder")
    p.cyl(0.62, 0.18, (0, -0.4, 3.18), None, "pink", "Fabric", D, verts=12)
    for side in (-1, 1):
        p.box((0.35, 0.1, 0.22), (side * 0.22, -1.0, 3.12), (0, side * 30, 0), "pink", "Fabric", D)
        arm(p, (side * 0.8, -0.2, 2.6), (side * 1.0, -0.85, 2.15), 0.14, "dino")
    leg(p, -0.5, 0.2, 1.0, 0.32, "dino", "dino")
    p.rod((0.5, 0.2, 1.2), (0.55, -0.2, 0.75), 0.32, "dino", "SmoothPlastic", D)
    p.box((0.65, 0.8, 0.32), (0.55, -0.45, 0.6), (-15, 0, 0), "dino", "SmoothPlastic", D)
    for a, b, r in (((0, 1.35, 1.7), (0, 2.3, 1.2), 0.3), ((0, 2.3, 1.2), (0, 3.0, 0.9), 0.18)):
        p.rod(a, b, r, "dino", "SmoothPlastic", D)


@prop("TongaTornado", "brainrot")
def tonga_tornado(p):
    # a colourful horse cart whose bottom is a spinning dust tornado; nobody is driving
    p.cone(1.6, 1.8, (0, 0, 0.9), (180, 0, 0), "sandlight", "Glass", D | GLASS, verts=12, top=0.25,
           fallback="Cylinder", fallback_scale=(0.6, 0.6, 1))
    for k in range(3):
        p.cyl(0.6 + k * 0.4, 0.08, (0, 0, 0.5 + k * 0.5), (0, 0, k * 20), "sandstone", "SmoothPlastic", D, verts=10)
    p.box((2.6, 2.2, 0.35), (0, 0.3, 2.1), None, "red", "WoodPlanks", D)
    p.box((2.6, 0.2, 1.0), (0, 1.35, 2.75), None, "blue", "WoodPlanks", D)
    p.box((2.4, 0.9, 0.2), (0, 0.9, 2.55), None, "gold", "Fabric", D)
    for x in (-1.2, 1.2):
        for y in (-0.7, 1.3):
            p.rod((x, y, 2.25), (x, y, 3.9), 0.06, "gold", "Metal", D)
    p.box((2.8, 2.4, 0.18), (0, 0.3, 4.0), None, "blue", "Fabric", D)
    for k in range(6):
        p.ball(0.12, (-1.25 + k * 0.5, -0.9, 3.8), "gold", "SmoothPlastic", D, segments=6, rings=4)
    for side in (-1, 1):
        p.cyl(1.05, 0.2, (side * 1.45, 0.3, 1.7), (0, 90, 0), "yellow", "Wood", D, verts=16)
        p.cyl(0.3, 0.26, (side * 1.45, 0.3, 1.7), (0, 90, 0), "red", "Wood", D, verts=10)
        for k in range(4):
            p.box((0.08, 1.9, 0.1), (side * 1.45, 0.3, 1.7), (k * 45, 0, 0), "red", "Wood", D)
    # the wooden horse head at the front
    p.box((0.5, 0.6, 1.3), (0, -1.15, 2.85), (-25, 0, 0), "wood", "Wood", D)
    p.box((0.55, 1.0, 0.55), (0, -1.6, 3.55), None, "wood", "Wood", D)
    for side in (-1, 1):
        p.box((0.12, 0.12, 0.35), (side * 0.18, -1.3, 3.95), None, "darkwood", "Wood", D)
    p.box((0.12, 0.4, 0.9), (0, -0.95, 3.4), (-25, 0, 0), "black", "Fabric", D)
    eyes(p, 0, -1.85, 3.65, 0.42, 0.15)
    smile(p, 0, -2.1, 3.4, 0.3)
    p.rope((0.2, -1.5, 3.3), (0.25, -0.3, 2.55), 0.2, 0.03, "black", 4)


@prop("TikkaTiger", "brainrot")
def tikka_tiger(p):
    # a chubby tiger roasting a giant skewer of tikka over the flame on its own tail
    p.blob(1.2, (0, 0.2, 1.95), (1, 1, 1.1), "tiger", "SmoothPlastic", D, seed=180, jitter=0.03, fallback="Ball")
    p.blob(0.8, (0, -0.35, 1.8), (0.85, 0.6, 1.0), "cream2", "SmoothPlastic", D, seed=181, fallback="None")
    p.blob(0.9, (0, -0.25, 3.4), (1.05, 0.95, 0.9), "tiger", "SmoothPlastic", D, seed=182, jitter=0.03,
           fallback="Ball")
    p.blob(0.45, (0, -0.95, 3.15), (1.2, 0.7, 0.8), "cream2", "SmoothPlastic", D, seed=183, fallback="Ball")
    for side in (-1, 1):
        p.ball(0.3, (side * 0.62, -0.1, 4.15), "tiger", "SmoothPlastic", D)
        p.ball(0.16, (side * 0.62, -0.32, 4.15), "blush", "SmoothPlastic", D, segments=6, rings=4)
    for k in range(5):  # grill-mark stripes
        p.box((0.12, 0.08, 0.7), (-0.8 + k * 0.4, -0.95 + abs(k - 2) * 0.12, 2.1), (0, 25, 0), "kebab",
              "SmoothPlastic", D)
    for k in range(3):
        p.box((0.1, 0.08, 0.4), (-0.3 + k * 0.3, -0.95, 3.75), (0, 20, 0), "kebab", "SmoothPlastic", D)
    eyes(p, 0, -1.0, 3.55, 0.62, 0.22)
    p.ball(0.12, (0, -1.32, 3.25), "pink", "SmoothPlastic", D)
    smile(p, 0, -1.32, 3.05, 0.38)
    for side in (-1, 1):
        for k in range(2):
            p.detail((0.6, 0.03, 0.03), (side * 0.55, -1.25, 3.18 + k * 0.1), (0, side * (5 - k * 10), 0), "white")
        leg(p, side * 0.5, 0.2, 0.75, 0.26, "tiger", "cream2")
    a, b = (-1.5, -1.0, 2.7), (1.6, -1.15, 2.85)
    p.rod(a, b, 0.05, "steel", "Metal", D, verts=6)
    for k in range(5):
        t = 0.2 + k * 0.15
        q = tuple(a[i] + (b[i] - a[i]) * t for i in range(3))
        p.box((0.36, 0.36, 0.36), q, (k * 20, k * 35, 0), "tikka" if k % 2 == 0 else "chutney", "SmoothPlastic", D)
    arm(p, (-0.9, -0.2, 2.4), (-1.3, -0.95, 2.7), 0.16, "tiger", "cream2", 0.22)
    arm(p, (0.9, -0.2, 2.4), (1.25, -1.1, 2.8), 0.16, "tiger", "cream2", 0.22)
    tail = [(0, 1.2, 1.4), (0.9, 1.2, 1.3), (1.3, 0.2, 1.4), (1.0, -0.9, 1.8)]
    for k, (x, y) in enumerate(zip(tail, tail[1:])):
        p.rod(x, y, 0.15, "tiger" if k % 2 == 0 else "kebab", "SmoothPlastic", D)
    p.blob(0.3, (1.0, -1.0, 2.15), (1, 1, 1.4), "flame", "Neon", D | KEEP | LIGHT, seed=184, fallback="Ball")


@prop("RishtaAuntyRobot", "brainrot")
def aunty_robot(p):
    # a silver aunty robot with cat-eye glasses, a dupatta, a clipboard and a telescope eye
    p.ball(1.15, (0, 0, 2.0), "robot", "Metal", D, segments=14, rings=8)
    p.cone(1.25, 1.1, (0, 0, 1.0), None, "magenta", "Fabric", D, verts=14, top=0.85, fallback="Cylinder")
    for side in (-1, 1):
        p.cyl(0.2, 0.55, (side * 0.4, 0, 0.3), None, "steeldark", "Metal", D, verts=8)
        p.box((0.45, 0.65, 0.2), (side * 0.4, -0.15, 0.1), None, "robot", "Metal", D)
    p.ball(0.9, (0, 0, 3.6), "robot", "Metal", D, segments=14, rings=8)
    p.rod((0, 0, 4.45), (0, 0, 4.85), 0.05, "steeldark", "Metal", D)
    p.ball(0.3, (0, 0.05, 5.0), "black", "SmoothPlastic", D)
    eyes(p, -0.3, -0.82, 3.7, 0.0, 0.22, single=True)
    p.cyl(0.24, 0.6, (0.3, -1.05, 3.7), (90, 0, 0), "steeldark", "Metal", D, verts=10)
    p.cyl(0.2, 0.08, (0.3, -1.36, 3.7), (90, 0, 0), "skyblue", "Glass", D | GLASS, verts=10)
    for side in (-1, 1):  # cat-eye glasses
        p.box((0.55, 0.08, 0.36), (side * 0.3, -0.88, 3.72), None, "magenta", "SmoothPlastic", D)
        p.box((0.25, 0.08, 0.12), (side * 0.62, -0.86, 3.86), (0, side * -30, 0), "magenta", "SmoothPlastic", D)
    smile(p, 0, -0.86, 3.25, 0.4)
    blush(p, 0, -0.84, 3.4, 1.0, 0.12)
    for side in (-1, 1):  # the dupatta
        p.box((0.45, 0.12, 1.6), (side * 0.6, -0.95, 2.3), (side * 8, side * -10, 0), "pink", "Fabric", D)
    p.box((1.6, 0.12, 0.4), (0, 0.9, 2.8), (10, 0, 0), "pink", "Fabric", D)
    arm(p, (-1.1, 0, 2.2), (-0.8, -0.85, 2.0), 0.12, "steeldark", "robot", 0.18)
    p.box((0.75, 0.08, 1.0), (-0.75, -1.0, 2.25), (-15, 0, 0), "wood", "Wood", D)
    p.box((0.6, 0.09, 0.75), (-0.75, -1.03, 2.2), (-15, 0, 0), "white", "SmoothPlastic", D)
    arm(p, (1.1, 0, 2.2), (0.45, -0.95, 2.35), 0.12, "steeldark", "robot", 0.18)
    p.rod((0.45, -1.0, 2.35), (0.25, -1.1, 2.75), 0.04, "blue", "SmoothPlastic", D, verts=4)
    p.box((0.6, 0.3, 0.5), (1.35, -0.1, 1.3), None, "gold", "SmoothPlastic", D)
    p.rope((1.15, -0.1, 1.55), (1.3, 0, 2.2), 0.05, 0.04, "gold", 3)
