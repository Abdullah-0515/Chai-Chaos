"""Brainrot models, part 1: the Commons and Uncommons.

Each function models one brainrot, named after its id in Brainrots.luau.
The look of each one is described in the README (Characters).
"""

import math

from brainrot_kit import D, Frame, arm, blush, brows, cap, eyes, leg, moustache, puffs, smile
from kit import GLASS, PARTSONLY, prop


def stepped(p, base_z, top_z, widths, depth, color, mat="SmoothPlastic", y=0.0):
    """A parts-only stand-in for a shape the mesh does better (a samosa, a teardrop)."""
    h = (top_z - base_z) / len(widths)
    for k, w in enumerate(widths):
        p.box((w, depth, h), (0, y, base_z + h * (k + 0.5)), None, color, mat, D | PARTSONLY)


# ------------------------------------------------------------------ Commons
@prop("GolGappaGhostu", "brainrot")
def gol_gappa(p):
    # a leaky, floating puri with a ghostly tail of imli pani
    p.blob(1.4, (0, 0, 2.5), (1, 1, 0.92), "puri", "SmoothPlastic", D, seed=1, jitter=0.06, fallback="Ball")
    p.cyl(1.38, 0.18, (0, 0, 2.95), None, "puricrust", "SmoothPlastic", D, verts=16)
    p.cyl(0.5, 0.1, (0, 0, 3.78), None, "imlipani", "SmoothPlastic", D, verts=12)
    for i, (x, y) in enumerate(((-0.18, 0.1), (0.2, 0.05), (0.02, -0.22))):
        p.ball(0.17, (x, y, 3.82), "chickpea", "SmoothPlastic", D, segments=8, rings=5)
    for i, (x, y, z, r) in enumerate(((0.15, 0.1, 1.15, 0.85), (-0.25, 0.25, 0.65, 0.58), (0.2, 0.35, 0.28, 0.32))):
        p.blob(r, (x, y, z), (1, 1, 0.8), "imlipani", "Glass", D | GLASS, seed=10 + i, jitter=0.12, fallback="Ball")
    for x, z in ((-1.1, 1.9), (1.2, 2.1), (0.9, 1.6)):
        p.ball(0.13, (x, -0.4, z), "imlipani", "Glass", D | GLASS, segments=6, rings=4)
    eyes(p, 0, -1.22, 2.65, 1.0, 0.34)
    smile(p, 0, -1.3, 2.05, 0.75, open_mouth=True)
    blush(p, 0, -1.2, 2.3, 1.55)


@prop("SamosaSupremo", "brainrot")
def samosa(p):
    # a cool boss samosa in shades, arms crossed, on a plate like a stage
    p.cyl(1.9, 0.2, (0, 0, 0.1), None, "white", "SmoothPlastic", D, verts=20)
    p.cyl(1.6, 0.22, (0, 0, 0.12), None, "cream2", "SmoothPlastic", D, verts=20)
    fl, fr, bk, apex = (-1.5, -0.75, 0.22), (1.5, -0.75, 0.22), (0, 1.35, 0.22), (0, 0.1, 3.4)
    p.poly([fl, fr, bk, apex], [(0, 2, 1), (0, 1, 3), (1, 2, 3), (2, 0, 3)], (0, 0, 0), "samosa", "SmoothPlastic", D)
    stepped(p, 0.22, 3.4, (2.8, 2.0, 1.2, 0.5), 1.6, "samosa", y=0.2)
    for t in (0.2, 0.45, 0.7):  # crimped edges
        for a, b in ((fl, apex), (fr, apex)):
            q = [a[i] + (b[i] - a[i]) * t for i in range(3)]
            p.detail((0.32, 0.32, 0.18), (q[0], q[1] - 0.05, q[2]), (0, 0, 45), "samosadark")
    tilt = math.degrees(math.atan2(0.85, 3.18))
    for side in (-1, 1):  # the shades
        p.box((0.78, 0.14, 0.46), (side * 0.42, -0.44, 2.0), (-tilt, 0, 0), "black", "SmoothPlastic", D)
        p.box((0.16, 0.15, 0.08), (side * 0.55, -0.52, 2.13), (-tilt, 0, 0), "white", "SmoothPlastic", D)
    p.box((0.25, 0.12, 0.1), (0, -0.46, 2.08), (-tilt, 0, 0), "black", "SmoothPlastic", D)
    p.box((0.5, 0.1, 0.09), (0.15, -0.6, 1.45), (-tilt, 0, -12), "black", "SmoothPlastic", D)  # smirk
    for side in (-1, 1):  # arms crossed
        arm(p, (side * 1.0, -0.4, 1.05), (-side * 0.45, -0.85, 0.95), 0.16, "samosadark", "samosa", 0.24)


@prop("ChaiyooKettlesaurus", "brainrot")
def kettlesaurus(p):
    # a steel kettle dino: spout neck, lid hat, handle tail, steam roar
    p.ball(1.3, (0, 0.2, 1.6), "steel", "Metal", D, segments=14, rings=8)
    p.cyl(1.05, 0.35, (0, 0.2, 0.55), None, "steeldark", "Metal", D, verts=14)
    p.cyl(0.72, 0.22, (0, 0.2, 2.85), None, "steeldark", "Metal", D, verts=12)
    p.ball(0.2, (0, 0.2, 3.08), "black", "SmoothPlastic", D)
    neck = [(0, -0.8, 2.0), (0, -1.35, 2.55), (0, -1.6, 3.1)]
    p.rod(neck[0], neck[1], 0.3, "steel", "Metal", D)
    p.rod(neck[1], neck[2], 0.26, "steel", "Metal", D)
    p.ball(0.58, (0, -1.75, 3.35), "steel", "Metal", D, segments=12, rings=7)
    p.box((0.7, 0.6, 0.45), (0, -2.15, 3.22), None, "steel", "Metal", D)
    eyes(p, 0, -2.2, 3.72, 0.56, 0.21)
    brows(p, 0, -2.2, 3.72, 0.56, 0.21, "steeldark", tilt=-10)
    smile(p, 0, -2.46, 3.1, 0.45, open_mouth=True)
    for x in (-0.15, 0.15):
        p.box((0.08, 0.06, 0.12), (x, -2.46, 3.24), None, "white", "SmoothPlastic", D)
    for a, b in (((0, 1.35, 2.4), (0, 1.9, 1.9)), ((0, 1.9, 1.9), (0, 1.75, 1.0))):
        p.rod(a, b, 0.14, "black", "SmoothPlastic", D)
    for x in (-0.6, 0.6):
        for y in (-0.35, 0.75):
            leg(p, x, y, 0.55, 0.28, "steeldark", "steeldark")
    puffs(p, [(0, -2.75, 3.4), (0.15, -3.15, 3.75), (-0.1, -3.5, 4.1)], 0.32)


@prop("ChanaChaatChacha", "brainrot")
def chana_chaat(p):
    # a steel katori of chana chaat with a sev moustache and a spoon stick
    p.cone(1.62, 1.1, (0, 0, 1.45), None, "steel", "Metal", D, verts=16, top=1.15, fallback="Cylinder",
           fallback_scale=(0.85, 0.85, 1))
    p.cyl(1.68, 0.12, (0, 0, 1.98), None, "steeldark", "Metal", D, verts=16)
    p.blob(1.45, (0, 0, 2.05), (1, 1, 0.4), "chickpea", "SmoothPlastic", D, seed=3, jitter=0.12, fallback="Disc")
    bits = [("onion", 0.6, 0.2), ("tomato", -0.5, 0.4), ("onion", -0.2, -0.6), ("tomato", 0.4, -0.5),
            ("coriander", 0.1, 0.6), ("coriander", -0.7, -0.1), ("chickpea", 0.75, -0.2)]
    for color, x, y in bits:
        p.ball(0.17, (x, y, 2.5), color, "SmoothPlastic", D, segments=6, rings=4)
    for i in range(8):
        p.detail((0.9, 0.06, 0.06), (-0.4 + (i % 4) * 0.25, -0.1 + (i // 4) * 0.25, 2.55), (0, 0, i * 37), "sev")
    eyes(p, 0, -1.42, 1.5, 0.8, 0.28)
    moustache(p, 0, -1.5, 1.08, 1.5, "sev", thick=0.24)
    smile(p, 0, -1.48, 0.88, 0.5)
    for x in (-0.5, 0.5):
        leg(p, x, -0.1, 0.9, 0.18, "steeldark", "black")
    arm(p, (1.45, -0.1, 1.4), (1.75, -0.35, 1.7), 0.12, "steeldark", "steel", 0.18)
    p.rod((1.85, -0.35, 0.0), (1.75, -0.35, 2.3), 0.07, "steel", "Metal", D)
    p.ball(0.24, (1.74, -0.35, 2.45), "steel", "Metal", D)


@prop("KulfiKangaroo", "brainrot")
def kulfi(p):
    # a pistachio kulfi kangaroo, bouncing on its stick
    p.cone(1.0, 2.3, (0, 0, 2.35), (180, 0, 0), "kulfi", "SmoothPlastic", D, verts=12, top=0.55,
           fallback="Cylinder", fallback_scale=(0.8, 0.8, 1))
    p.cyl(1.02, 0.45, (0, 0, 3.55), None, "pistachio", "SmoothPlastic", D, verts=12)
    p.blob(0.95, (0, 0, 3.8), (1, 1, 0.45), "pistachio", "SmoothPlastic", D, seed=5, jitter=0.1, fallback="Disc")
    for i in range(6):
        a = i * math.pi / 3
        p.detail((0.14, 0.14, 0.08), (math.cos(a) * 0.5, math.sin(a) * 0.5, 4.08), (0, 0, i * 20), "green")
    for x, z in ((-0.85, 3.2), (0.7, 3.25), (0.0, 3.25)):  # drips frozen into icicles
        p.cone(0.14, 0.45, (x, -0.55, z - 0.25), (180, 0, 0), "ice", "Glass", D, verts=6, fallback="Cylinder",
               fallback_scale=(0.8, 0.8, 1))
    for side in (-1, 1):
        p.box((0.32, 0.18, 1.0), (side * 0.45, 0.1, 4.45), (0, side * -12, 0), "kulfi", "SmoothPlastic", D)
        p.box((0.18, 0.08, 0.7), (side * 0.45, 0.0, 4.45), (0, side * -12, 0), "blush", "SmoothPlastic", D)
    eyes(p, 0, -0.92, 2.75, 0.75, 0.27)
    smile(p, 0, -0.85, 2.2, 0.5)
    blush(p, 0, -0.86, 2.45, 1.15, 0.16)
    for side in (-1, 1):
        arm(p, (side * 0.75, -0.3, 2.1), (side * 0.75, -0.75, 1.75), 0.12, "kulfi")
        p.box((0.5, 1.3, 0.3), (side * 0.45, -0.35, 0.15), None, "kulfi", "SmoothPlastic", D)
        p.rod((side * 0.45, -0.1, 0.3), (side * 0.35, 0.0, 1.25), 0.16, "kulfi", "SmoothPlastic", D)
    p.box((0.32, 0.16, 1.9), (0, 0.55, 0.85), (25, 0, 0), "kulfistick", "Wood", D)


@prop("PakoraPanda", "brainrot")
def pakora_panda(p):
    # a crispy pakora panda with a little umbrella, on a paper plate
    p.cyl(1.8, 0.12, (0, 0, 0.06), None, "white", "SmoothPlastic", D, verts=18)
    p.blob(0.45, (1.15, 0.85, 0.2), (1.2, 1, 0.35), "chutney", "SmoothPlastic", D, seed=7, fallback="Disc")
    p.blob(1.35, (0, 0, 1.45), (1, 0.95, 0.95), "pakora", "SmoothPlastic", D, seed=8, jitter=0.22, fallback="Ball")
    for i in range(7):
        a = i * 0.9
        p.detail((0.3, 0.3, 0.2), (math.cos(a) * 1.1, math.sin(a) * 0.9 + 0.2, 1.4 + (i % 3) * 0.35), (i * 20, i * 30, 0),
                 "pakoradark")
    for side in (-1, 1):
        p.ball(0.42, (side * 0.95, 0.15, 2.55), "pakoradark", "SmoothPlastic", D)
        p.blob(0.42, (side * 0.38, -1.12, 1.75), (1.1, 0.4, 1.25), "pakoradark", "SmoothPlastic", D, seed=9 + side,
               fallback="Ball")
    eyes(p, 0, -1.3, 1.78, 0.76, 0.24)
    p.ball(0.14, (0, -1.38, 1.42), "black", "SmoothPlastic", D)
    smile(p, 0, -1.33, 1.2, 0.45)
    for x in (-0.55, 0.55):
        p.ball(0.3, (x, -0.6, 0.35), "pakoradark", "SmoothPlastic", D)
    arm(p, (1.1, -0.4, 1.35), (1.35, -0.55, 1.7), 0.12, "pakoradark")
    p.rod((1.35, -0.55, 1.4), (1.35, -0.55, 3.9), 0.06, "darkmetal", "Metal", D)
    p.cone(1.25, 0.6, (1.35, -0.55, 3.95), None, "blue", "Fabric", D, verts=8, fallback="Disc",
           fallback_scale=(1, 1, 0.4))
    p.cone(0.6, 0.32, (1.35, -0.55, 4.12), None, "white", "Fabric", D, verts=8, fallback="None")


@prop("NaanNinja", "brainrot")
def naan_ninja(p):
    # a teardrop naan in a black headband and mask, roti stars ready
    f = Frame((0, 0, 0), (0, 0, -8))
    p.blob(1.45, f.p(0, 0, 2.15), (0.82, 0.32, 1.22), "naan", "SmoothPlastic", D, seed=12, jitter=0.07,
           fallback="Block", fallback_scale=(0.82, 1, 0.82), rot=f.r())
    for i, (x, z) in enumerate(((-0.5, 1.4), (0.55, 1.7), (-0.2, 3.1), (0.45, 2.75), (0.1, 1.2))):
        p.blob(0.16, f.p(x, -0.42, z), (1, 0.4, 1), "naanchar", "SmoothPlastic", D, seed=20 + i, fallback="None")
    p.box((1.95, 0.6, 0.32), f.p(0, -0.05, 3.0), f.r(), "black", "Fabric", D)
    for k in range(2):
        p.box((0.22, 0.08, 1.2), f.p(0.35 + k * 0.3, 0.45, 2.55 - k * 0.15), f.r((10, 0, 25 + k * 15)), "black",
              "Fabric", D)
    p.box((1.6, 0.12, 0.42), f.p(0, -0.45, 2.45), f.r(), "black", "Fabric", D)
    eyes(p, 0, -0.55, 2.45, 0.62, 0.22, f=f)
    brows(p, 0, -0.55, 2.45, 0.62, 0.22, tilt=22, f=f)
    smile(p, 0, -0.48, 1.85, 0.4, f=f)
    arm(p, (-0.95, -0.1, 2.0), (-1.55, -0.55, 2.4), 0.11, "naan", f=f)
    arm(p, (0.95, -0.1, 2.0), (1.5, -0.5, 1.6), 0.11, "naan", f=f)
    for k in range(2):  # a roti star in hand
        p.box((0.7, 0.08, 0.14), f.p(-1.6, -0.7, 2.5), f.r((0, k * 90 + 45, 0)), "cream2", "SmoothPlastic", D)
    for side in (-1, 1):
        p.rod(f.p(side * 0.35, 0, 1.0), f.p(side * 0.55, -0.15, 0.25), 0.12, "naan", "SmoothPlastic", D)
        p.box((0.36, 0.6, 0.22), f.p(side * 0.58, -0.3, 0.11), f.r(), "black", "SmoothPlastic", D)


@prop("PyaazPehelwan", "brainrot")
def pyaaz(p):
    # a wrestler onion with a curly moustache and a champion's belt
    p.blob(1.35, (0, 0, 1.75), (1, 1, 1.05), "onion", "SmoothPlastic", D, seed=14, jitter=0.05, fallback="Ball")
    for i in range(6):
        a = i * math.pi / 3
        p.detail((0.06, 0.06, 2.4), (math.cos(a) * 1.0, math.sin(a) * 1.0, 1.8), (math.sin(a) * 25, -math.cos(a) * 25, 0),
                 "onionpale")
    for i, (x, y, lean) in enumerate(((0, 0, 0), (-0.25, 0.1, -20), (0.25, 0.05, 22))):
        p.cone(0.14, 1.2, (x, y, 3.65), (0, lean, 0), "coriander", "Grass", D, verts=6, fallback="Cylinder",
               fallback_scale=(1.2, 1.2, 1))
    eyes(p, 0, -1.25, 2.05, 0.82, 0.27)
    brows(p, 0, -1.25, 2.05, 0.82, 0.27, tilt=20)
    moustache(p, 0, -1.35, 1.6, 1.4, "black", thick=0.24)
    smile(p, 0, -1.33, 1.38, 0.42)
    p.cyl(1.08, 0.55, (0, 0, 0.85), None, "red", "Fabric", D, verts=14)
    p.cyl(1.16, 0.26, (0, 0, 1.22), None, "gold", "Metal", D, verts=14)
    p.box((0.7, 0.2, 0.5), (0, -1.15, 1.22), None, "gold", "Metal", D)
    p.ball(0.12, (0, -1.27, 1.22), "red", "SmoothPlastic", D)
    for side in (-1, 1):
        p.ball(0.42, (side * 1.25, -0.1, 2.0), "onion", "SmoothPlastic", D)
        arm(p, (side * 1.25, -0.1, 2.0), (side * 1.85, -0.2, 2.35), 0.2, "onion", "onionpale", 0.3)
        p.ball(0.34, (side * 1.6, -0.12, 2.25), "onion", "SmoothPlastic", D)
        leg(p, side * 0.45, 0, 0.75, 0.2, "onion", "black")
    for side in (-1, 1):
        p.ball(0.12, (side * 2.3, -0.6, 2.4), "skyblue", "Glass", D, segments=6, rings=4)


# ---------------------------------------------------------------- Uncommons
@prop("ParathaPilot", "brainrot")
def paratha(p):
    # a flaky paratha flying in goggles, cap and scarf, dripping ghee
    f = Frame((0, 0, 2.3), (0, 0, 0))
    disc = f.r((65, 0, 0))
    p.cyl(1.9, 0.45, f.p(0, 0, 0), disc, "paratha", "SmoothPlastic", D, verts=18)
    p.cyl(1.55, 0.5, f.p(0, 0.02, 0.0), disc, "ghee", "SmoothPlastic", D, verts=18)
    for i, (x, z) in enumerate(((-0.8, -0.6), (0.9, -0.4), (0.3, -1.1), (-0.3, 0.9))):
        p.blob(0.18, f.p(x, -0.35 + z * 0.1, z), (1, 0.4, 1), "naanchar", "SmoothPlastic", D, seed=30 + i,
               fallback="None", rot=disc)
    fz = Frame((0, -0.25, 2.3), (-25, 0, 0))
    eyes(p, 0, -0.15, 0.55, 0.85, 0.27, f=fz)
    for side in (-1, 1):  # aviator goggles
        p.cyl(0.4, 0.14, fz.p(side * 0.43, -0.12, 0.55), fz.r((90, 0, 0)), "leather", "Fabric", D, verts=12)
        p.cyl(0.32, 0.12, fz.p(side * 0.43, -0.2, 0.55), fz.r((90, 0, 0)), "skyblue", "Glass", D | GLASS, verts=12)
    p.box((2.1, 0.1, 0.16), fz.p(0, -0.04, 0.55), fz.r(), "leather", "Fabric", D)
    smile(p, 0, -0.18, -0.25, 0.55, f=fz, open_mouth=True)
    cap(p, 0, 0.35, 2.05, 0.55, "leather", f=Frame((0, 0, 2.3), (-25, 0, 0)))
    for k in range(3):  # the scarf trailing behind
        p.box((0.45, 0.9, 0.12), (0.9 + k * 0.15, 1.0 + k * 0.75, 3.1 - k * 0.1), (0, 15 * k, 20), "white",
              "Fabric", D)
    for x in (-0.7, 0.2, 0.9):
        p.ball(0.14, (x, 0.2, 0.55 + abs(x) * 0.2), "ghee", "Glass", D, segments=6, rings=4)


@prop("RickshawRaptor", "brainrot")
def rickshaw_raptor(p):
    # a green-and-yellow rickshaw on raptor legs, headlight eyes, grille grin
    p.box((2.2, 3.0, 1.2), (0, 0.3, 2.6), None, "rickshawgreen", "SmoothPlastic", D)
    p.box((2.25, 3.05, 0.3), (0, 0.3, 2.3), None, "yellow", "SmoothPlastic", D)
    p.box((1.4, 1.0, 1.5), (0, -1.6, 2.85), None, "rickshawgreen", "SmoothPlastic", D)
    p.box((2.4, 2.8, 0.22), (0, 0.4, 4.05), None, "black", "Fabric", D)
    for x in (-1.1, 1.1):
        for y in (-0.9, 1.6):
            p.rod((x, y, 3.2), (x, y, 4.0), 0.06, "black", "Metal", D)
    eyes(p, 0, -2.12, 3.05, 0.72, 0.3, pupil="black")
    p.box((1.0, 0.12, 0.42), (0, -2.12, 2.42), None, "black", "SmoothPlastic", D)
    for k in range(5):
        p.box((0.14, 0.1, 0.18), (-0.36 + k * 0.18, -2.2, 2.52), (0, 0, 45), "white", "SmoothPlastic", D)
    p.cyl(0.14, 0.4, (0.75, -2.0, 3.45), (0, 90, 0), "yellow", "Metal", D, verts=8)
    p.cone(0.25, 0.35, (1.05, -2.0, 3.45), (0, 90, 0), "yellow", "Metal", D, verts=8, fallback="None")
    for side in (-1, 1):  # raptor legs with three toes
        knee, ankle = (side * 0.7, 0.9, 1.2), (side * 0.7, 0.4, 0.35)
        p.rod((side * 0.6, 0.3, 2.1), knee, 0.28, "dino", "SmoothPlastic", D)
        p.rod(knee, ankle, 0.2, "dino", "SmoothPlastic", D)
        for t in (-25, 0, 25):
            a = math.radians(t)
            p.box((0.16, 0.6, 0.16), (side * 0.7 + math.sin(a) * 0.3, 0.1 - math.cos(a) * 0.3, 0.1), (0, 0, t), "dino",
                  "SmoothPlastic", D)
    for a, b, r in (((0, 1.75, 2.6), (0, 2.8, 2.35), 0.3), ((0, 2.8, 2.35), (0, 3.7, 2.1), 0.2)):
        p.rod(a, b, r, "dino", "SmoothPlastic", D)
    p.ball(0.16, (0, 3.75, 2.1), "red", "SmoothPlastic", D)


@prop("LassiLlama", "brainrot")
def lassi_llama(p):
    # a fluffy llama sitting in a tall glass of lassi, malai moustache on
    p.cyl(1.1, 2.6, (0, 0, 1.3), None, "glass", "Glass", D | GLASS, verts=16)
    p.cyl(1.0, 2.3, (0, 0, 1.17), None, "lassi", "SmoothPlastic", D, verts=16)
    p.blob(1.05, (0, 0, 2.4), (1, 1, 0.35), "malai", "SmoothPlastic", D, seed=40, fallback="Disc")
    p.cyl(0.42, 1.3, (0, 0, 2.95), None, "llama", "SmoothPlastic", D, verts=10)
    p.ball(0.58, (0, -0.1, 3.85), "llama", "SmoothPlastic", D, segments=12, rings=7)
    p.box((0.6, 0.55, 0.45), (0, -0.55, 3.62), None, "llama", "SmoothPlastic", D)
    for i in range(3):
        p.blob(0.28, (-0.2 + i * 0.2, 0.0, 4.4), (1, 1, 0.8), "malai", "SmoothPlastic", D, seed=41 + i,
               fallback="Ball")
    for side in (-1, 1):
        p.box((0.16, 0.14, 0.55), (side * 0.38, 0.05, 4.45), (0, side * -15, 0), "llama", "SmoothPlastic", D)
    eyes(p, 0, -0.64, 3.98, 0.5, 0.18)
    blush(p, 0, -0.6, 3.75, 0.85, 0.1)
    p.box((0.22, 0.06, 0.12), (0, -0.83, 3.72), None, "pakoradark", "SmoothPlastic", D)  # nose
    p.box((0.75, 0.2, 0.16), (0, -0.84, 3.55), None, "malai", "SmoothPlastic", D)
    for side in (-1, 1):
        p.ball(0.13, (side * 0.4, -0.84, 3.58), "malai", "SmoothPlastic", D)
        p.rod((side * 0.4, -0.55, 2.5), (side * 0.48, -1.12, 2.62), 0.12, "llama", "SmoothPlastic", D)
        p.ball(0.13, (side * 0.48, -1.14, 2.62), "mudlight", "SmoothPlastic", D)
    p.rod((0.6, 0.3, 2.3), (1.1, 0.55, 4.2), 0.07, "red", "SmoothPlastic", D)


@prop("BunKebabBhai", "brainrot")
def bun_kebab(p):
    # a muscly bun kebab posing on a little stage with a trophy
    p.box((3.4, 2.4, 0.4), (0, 0.1, 0.2), None, "red", "Fabric", D)
    p.box((3.5, 2.5, 0.1), (0, 0.1, 0.42), None, "gold", "Metal", D)
    p.cyl(1.1, 0.45, (0, 0, 0.7), None, "bun", "SmoothPlastic", D, verts=16)
    p.cyl(1.18, 0.42, (0, 0, 1.12), None, "kebab", "SmoothPlastic", D, verts=16)
    p.cyl(1.22, 0.1, (0, 0, 1.38), None, "eggyolk", "SmoothPlastic", D, verts=16)
    p.cyl(1.16, 0.08, (0, 0, 1.47), None, "chutney", "SmoothPlastic", D, verts=16)
    for i in range(4):
        p.detail((0.7, 0.08, 0.06), (-0.6 + i * 0.4, -1.1, 1.5), (0, 0, 0), "onionpale")
    p.blob(1.14, (0, 0, 1.6), (1, 1, 0.62), "bun", "SmoothPlastic", D, seed=50, jitter=0.04, fallback="Ball",
           fallback_scale=(1, 1, 0.75))
    for i in range(7):
        a = i * 0.9
        p.detail((0.12, 0.07, 0.05), (math.cos(a) * 0.6, math.sin(a) * 0.6, 2.28), (0, 0, i * 30), "white")
    eyes(p, 0, -1.03, 1.98, 0.7, 0.24)
    brows(p, 0, -1.03, 1.98, 0.7, 0.24, tilt=-10)
    smile(p, 0, -1.1, 1.62, 0.5)
    p.box((1.9, 0.18, 0.12), (0, -1.0, 2.45), None, "red", "Fabric", D)  # sweatband
    # left arm flexing, right arm holding a trophy up
    p.ball(0.4, (-1.2, 0, 1.45), "bun", "SmoothPlastic", D)
    arm(p, (-1.2, 0, 1.45), (-1.85, -0.1, 1.7), 0.2, "bun")
    arm(p, (-1.85, -0.1, 1.7), (-1.8, -0.1, 2.5), 0.18, "bun", "bun", 0.26)
    p.ball(0.36, (-1.55, -0.12, 1.85), "bun", "SmoothPlastic", D)
    arm(p, (1.2, 0, 1.45), (1.6, -0.3, 2.6), 0.2, "bun", "bun", 0.26)
    p.cyl(0.22, 0.35, (1.6, -0.3, 2.95), None, "gold", "Metal", D, verts=8)
    p.cone(0.45, 0.6, (1.6, -0.3, 3.45), (180, 0, 0), "gold", "Metal", D, verts=10, top=0.2, fallback="Cylinder")
    for side in (-1, 1):
        p.box((0.08, 0.3, 0.35), (1.6 + side * 0.5, -0.3, 3.45), None, "gold", "Metal", D)
        leg(p, side * 0.45, 0, 0.55, 0.16, "bun", "white")


@prop("RoohAfzaRhino", "brainrot")
def sharbat_rhino(p):
    # a glossy red rhino shaped like a sharbat bottle, pink drink in its belly
    p.blob(1.3, (0, 0.1, 1.55), (1, 1.35, 0.9), "rhinored", "SmoothPlastic", D, seed=60, jitter=0.03,
           fallback="Ball")
    for side in (-1, 1):  # see-through windows on its sides show the pink drink inside
        p.blob(0.62, (side * 1.02, 0.15, 1.5), (0.45, 1.25, 0.95), "sharbat", "Glass", D | GLASS, seed=62 + side,
               fallback="Ball")
        p.ball(0.12, (side * 1.27, -0.2, 1.75), "white", "SmoothPlastic", D, segments=6, rings=4)
    p.blob(0.78, (0, -1.6, 1.8), (1, 1.05, 0.95), "rhinored", "SmoothPlastic", D, seed=61, jitter=0.03,
           fallback="Ball")
    p.cone(0.32, 0.9, (0, -2.45, 2.25), (35, 0, 0), "rhinored", "SmoothPlastic", D, verts=10, top=0.2,
           fallback="Cylinder", fallback_scale=(0.8, 0.8, 1))
    p.cyl(0.24, 0.22, (0, -2.73, 2.66), (35, 0, 0), "gold", "Metal", D, verts=10)
    for side in (-1, 1):
        p.box((0.2, 0.12, 0.35), (side * 0.45, -1.4, 2.55), (0, side * -20, 0), "rhinored", "SmoothPlastic", D)
    eyes(p, 0, -2.22, 2.12, 0.8, 0.21)
    smile(p, 0, -2.36, 1.62, 0.4)
    for x in (-0.65, 0.65):
        for y in (-0.8, 0.9):
            p.cyl(0.33, 0.8, (x, y, 0.4), None, "rhinored", "SmoothPlastic", D, verts=10)
    p.rod((0, 1.85, 1.6), (0, 2.3, 1.2), 0.07, "rhinored", "SmoothPlastic", D)
    p.ball(0.15, (0, 2.32, 1.15), "maroon", "SmoothPlastic", D)
    for i, (x, y, z) in enumerate(((-1.4, -0.6, 2.6), (1.3, 0.2, 2.9), (-1.0, 1.2, 3.1), (1.5, -1.2, 2.2))):
        p.box((0.3, 0.06, 0.24), (x, y, z), (i * 30, i * 50, i * 20), "rosepetal", "SmoothPlastic", D)


@prop("GajarHalwaGorilla", "brainrot")
def halwa_gorilla(p):
    # a chunky halwa gorilla in a woolly scarf and shawl, with a bowl of halwa
    p.blob(1.3, (0, 0.1, 1.9), (1.1, 0.9, 1.0), "halwa", "SmoothPlastic", D, seed=70, jitter=0.12,
           fallback="Ball")
    for i in range(10):
        a = i * 1.3
        p.detail((0.16, 0.1, 0.1), (math.cos(a) * 1.15, math.sin(a) * 0.9, 1.3 + (i % 4) * 0.4), (0, 0, i * 40),
                 "almond" if i % 2 else "pistachio")
    p.blob(0.82, (0, -0.35, 3.3), (1, 0.95, 0.95), "halwa", "SmoothPlastic", D, seed=71, jitter=0.1,
           fallback="Ball")
    p.blob(0.5, (0, -0.95, 3.1), (1.2, 0.7, 0.8), "almond", "SmoothPlastic", D, seed=72, fallback="Ball")
    eyes(p, 0, -1.0, 3.5, 0.6, 0.2)
    brows(p, 0, -1.0, 3.5, 0.6, 0.2, "pakoradark", tilt=-8)
    smile(p, 0, -1.33, 3.0, 0.4)
    p.cyl(0.85, 0.4, (0, -0.3, 2.75), None, "blue", "Fabric", D, verts=12)
    p.box((0.4, 0.15, 1.1), (0.5, -1.05, 2.2), (0, 10, 0), "blue", "Fabric", D)
    for side in (-1, 1):
        p.box((0.9, 1.6, 0.25), (side * 0.85, 0.2, 2.75), (0, side * 35, 0), "maroon", "Fabric", D)
        p.rod((side * 1.25, 0, 2.55), (side * 1.6, -0.3, 1.3), 0.3, "halwa", "SmoothPlastic", D)
        leg(p, side * 0.55, 0.1, 0.8, 0.28, "halwa", "pakoradark")
    p.rod((1.6, -0.3, 1.3), (1.4, -0.9, 1.0), 0.22, "halwa", "SmoothPlastic", D)
    p.ball(0.36, (-1.65, -0.35, 0.95), "halwa", "SmoothPlastic", D)
    p.cone(0.7, 0.5, (1.3, -1.1, 1.0), (180, 0, 0), "steel", "Metal", D, verts=12, top=0.4, fallback="Cylinder",
           fallback_scale=(0.9, 0.9, 1))
    p.blob(0.62, (1.3, -1.1, 1.3), (1, 1, 0.35), "halwa", "SmoothPlastic", D, seed=73, fallback="Disc")
    puffs(p, [(1.3, -1.1, 1.8), (1.4, -1.15, 2.25)], 0.22)


@prop("DoodhPattiDolphin", "brainrot")
def chai_dolphin(p):
    # a chai-coloured dolphin leaping out of a clay kulhad, splash and steam
    p.cone(1.05, 1.3, (0.5, 0.5, 0.65), (180, 0, 0), "clay", "Slate", D, verts=14, top=0.72, fallback="Cylinder",
           fallback_scale=(0.9, 0.9, 1))
    p.cyl(1.08, 0.12, (0.5, 0.5, 1.3), None, "claydark", "Slate", D, verts=14)
    p.cyl(0.96, 0.1, (0.5, 0.5, 1.33), None, "chai", "SmoothPlastic", D, verts=14)
    f = Frame((-0.25, -0.1, 2.75), (-32, 0, -58))  # nose up, leaping to the front-left
    p.blob(1.0, f.p(0, 0, 0), (0.72, 2.0, 0.78), "dolphin", "SmoothPlastic", D, seed=80, jitter=0.02,
           fallback="Block", fallback_scale=(0.8, 0.85, 0.8), rot=f.r())
    p.blob(0.8, f.p(0, -0.25, -0.32), (0.75, 2.0, 0.55), "cream2", "SmoothPlastic", D, seed=81, jitter=0.02,
           fallback="None", rot=f.r())
    p.cone(0.36, 0.7, f.p(0, -2.15, -0.12), f.r((90, 0, 0)), "dolphin", "SmoothPlastic", D, verts=8, top=0.16,
           fallback="Cylinder", fallback_scale=(0.9, 0.9, 1))
    p.box((0.16, 0.9, 0.85), f.p(0, 0.15, 0.82), f.r((-35, 0, 0)), "dolphin", "SmoothPlastic", D)  # dorsal fin
    for side in (-1, 1):
        p.box((0.75, 0.5, 0.12), f.p(side * 0.75, -0.55, -0.4), f.r((0, side * 30, 0)), "dolphin", "SmoothPlastic", D)
        p.box((0.9, 0.5, 0.14), f.p(side * 0.45, 2.05, 0.0), f.r((0, 0, side * 28)), "dolphin", "SmoothPlastic", D)
    eyes(p, 0, -1.5, 0.3, 0.72, 0.24, f=f)
    smile(p, 0, -1.88, -0.25, 0.5, f=f)
    blush(p, 0, -1.55, 0.02, 1.0, 0.13, f=f)
    for i, t in enumerate((0.1, 0.3, 0.5, 0.7, 0.9)):  # the chai splash arc
        p.ball(0.17 - i * 0.02, (1.3 - t * 2.4, -0.7 - t * 0.4, 1.5 + math.sin(t * math.pi) * 0.9), "chai",
               "SmoothPlastic", D, segments=6, rings=4)
    puffs(p, [(1.0, 0.9, 1.75), (1.15, 1.0, 2.2), (1.05, 1.1, 2.6)], 0.24)