"""Brainrot models, part 4: the Secret brainrots of Barfani Pahar."""

import math

from brainrot_kit import D, Frame, arm, blush, brows, eyes, leg, puffs, smile
from kit import KEEP, prop


@prop("KahwaYeti", "brainrot")
def kahwa_yeti(p):
    # a big, fluffy, friendly yeti with frosty eyebrows, holding a steaming brass samovar of kahwa
    p.blob(2.1, (0, 0.2, 3.4), (1, 0.9, 1.2), "white", "SmoothPlastic", D, seed=400, jitter=0.08, fallback="Ball")
    for i in range(10):  # tufts of fur
        a = i * 2 * math.pi / 10
        p.blob(0.6, (math.cos(a) * 1.9, 0.2 + math.sin(a) * 1.6, 2.4 + (i % 3) * 0.9), (1, 1, 1), "white",
               "SmoothPlastic", D, seed=401 + i, jitter=0.2, fallback="None")
    p.blob(1.5, (0, -0.4, 6.1), (1, 0.95, 0.95), "white", "SmoothPlastic", D, seed=412, jitter=0.07,
           fallback="Ball")
    p.blob(1.0, (0, -1.35, 5.8), (1.1, 0.5, 0.85), "skyblue", "SmoothPlastic", D, seed=413, fallback="None")
    eyes(p, 0, -1.65, 6.2, 0.75, 0.27)
    brows(p, 0, -1.65, 6.2, 0.75, 0.27, "ice", tilt=-8)
    smile(p, 0, -1.8, 5.45, 0.55, open_mouth=True)
    blush(p, 0, -1.6, 5.8, 1.15, 0.15)
    for i, z in enumerate((4.4, 3.7, 3.0)):  # cardamom-pod buttons
        p.blob(0.2, (0, -1.85 + i * 0.05, z), (0.8, 0.6, 1.3), "pistachio", "SmoothPlastic", D, seed=414 + i,
               fallback="Ball")
    for side in (-1, 1):
        leg(p, side * 0.95, 0.2, 1.2, 0.55, "white", "skyblue", foot_len=1.8)
        arm(p, (side * 1.8, -0.3, 4.4), (side * 1.0, -2.2, 3.4), 0.45, "white", "white", 0.6)
    # the samovar in its arms
    p.cyl(0.7, 1.6, (0, -2.6, 3.3), None, "copper", "Metal", D, verts=12)
    p.cone(0.7, 0.6, (0, -2.6, 4.4), None, "copper", "Metal", D, verts=12, top=0.25, fallback="None")
    p.ball(0.22, (0, -2.6, 4.85), "gold", "Metal", D)
    p.rod((0, -3.25, 3.2), (0, -3.7, 3.0), 0.08, "gold", "Metal", D)
    puffs(p, [(0, -2.6, 5.3), (0.2, -2.7, 5.9), (-0.1, -2.6, 6.5)], 0.32, seed=420)


@prop("GolaGandaGolem", "brainrot")
def gola_golem(p):
    # a giant ice golem built from crushed-ice gola gandas, rainbow syrup dripping, gola sticks for fingers
    syrup = ("red", "orange", "green", "pink", "blue", "yellow")
    p.blob(1.9, (0, 0, 3.6), (1.1, 0.9, 1.15), "ice", "Ice", D, seed=430, jitter=0.12, fallback="Ball")
    p.blob(1.3, (0, -0.2, 6.2), (1, 1, 0.95), "ice", "Ice", D, seed=431, jitter=0.1, fallback="Ball")
    for i in range(6):  # syrup splashes on the ice
        a = i * 1.05
        p.blob(0.65, (math.cos(a) * 1.4, -0.9 + math.sin(a) * 0.4, 2.8 + (i % 3) * 1.1), (1, 0.6, 1),
               syrup[i], "SmoothPlastic", D, seed=432 + i, jitter=0.15, fallback="None")
    p.blob(0.9, (0, -0.2, 7.3), (1.2, 1.1, 0.5), "red", "SmoothPlastic", D, seed=440, fallback="None")
    for i, x in enumerate((-0.7, 0.1, 0.8)):
        p.ball(0.18, (x, -1.25, 6.8 - i * 0.1), syrup[i + 2], "SmoothPlastic", D, segments=6, rings=4)
    eyes(p, 0, -1.25, 6.25, 0.7, 0.26)
    brows(p, 0, -1.25, 6.25, 0.7, 0.26, "blue", tilt=6)
    smile(p, 0, -1.35, 5.55, 0.55)
    for side in (-1, 1):
        p.blob(0.9, (side * 1.2, 0, 1.0), (0.9, 1, 1.1), "ice", "Ice", D, seed=441 + side, jitter=0.15,
               fallback="Ball")
        shoulder = (side * 2.0, 0, 4.6)
        hand = (side * 2.9, -0.6, 2.8)
        p.blob(0.8, shoulder, (1, 1, 1), "ice", "Ice", D, seed=444 + side, jitter=0.15, fallback="Ball")
        p.rod(shoulder, hand, 0.6, "ice", "Ice", D)
        p.blob(0.7, hand, (1, 1, 1), syrup[(side + 2) % 6], "Ice", D, seed=447 + side, jitter=0.15,
               fallback="Ball")
        for k in range(3):  # wooden gola sticks for fingers
            p.rod((hand[0], hand[1], hand[2] - 0.3), (hand[0] + side * (0.3 + k * 0.2), hand[1] - 0.5 + k * 0.4,
                                                       hand[2] - 1.5), 0.08, "lightwood", "Wood", D, verts=4)
    for i, (x, z) in enumerate(((-1.0, 2.0), (0.6, 1.6), (1.3, 2.6))):  # drips
        p.ball(0.16, (x, -1.8, z), syrup[i], "SmoothPlastic", D, segments=6, rings=4)


@prop("BarfiBarfaniBagh", "brainrot")
def barfi_bagh(p):
    # a snow leopard made of white and pistachio barfi squares, silver warq spots, a woolly pakol cap
    f = Frame((0, 0, 0), (0, 0, -30))  # turned three-quarters so you see its long body and tail
    for i in range(4):  # the body: barfi squares in a row
        y = -0.9 + i * 1.3
        p.box((2.2, 1.3, 1.9), f.p(0, y, 2.6), f.r(), "white" if i % 2 == 0 else "pistachio", "SmoothPlastic", D)
        p.box((2.25, 1.1, 0.25), f.p(0, y, 3.5), f.r(), "pistachio" if i % 2 == 0 else "white", "SmoothPlastic", D)
    for i, (x, y, z) in enumerate(((-0.7, -0.6, 3.66), (0.5, 0.6, 3.66), (-0.2, 1.9, 3.66), (0.7, 2.8, 3.66),
                                   (-1.12, 1.2, 2.6), (1.12, 0.0, 2.4))):
        p.box((0.45, 0.45, 0.05), f.p(x, y, z), f.r((0, 0, i * 25)), "warq", "Foil", D)
    p.box((2.4, 2.2, 2.2), f.p(0, -2.4, 3.6), f.r(), "white", "SmoothPlastic", D)  # head
    p.box((1.3, 0.8, 0.9), f.p(0, -3.7, 3.2), f.r(), "pistachio", "SmoothPlastic", D)  # muzzle
    p.ball(0.18, f.p(0, -4.12, 3.45), "pakoradark", "SmoothPlastic", D)
    for side in (-1, 1):
        p.box((0.6, 0.4, 0.6), f.p(side * 0.85, -2.2, 4.95), f.r(), "white", "SmoothPlastic", D)
    eyes(p, 0, -3.55, 4.05, 0.85, 0.3, f=f)
    smile(p, 0, -4.12, 2.95, 0.4, f=f)
    blush(p, 0, -3.5, 3.55, 1.5, 0.15, f=f)
    # the pakol: a round woolly cap with a rolled rim
    p.cyl(1.2, 0.5, f.p(0, -2.4, 4.95), f.r(), "naan", "Fabric", D, verts=14)
    p.cyl(1.25, 0.4, f.p(0, -2.4, 4.75), f.r(), "naanchar", "Fabric", D, verts=14)
    for x in (-0.65, 0.65):
        for y in (-1.6, 2.6):
            leg(p, x, y, 1.6, 0.35, "white", "pistachio", f=f)
    tail = [(0, 3.2, 2.8), (0, 4.4, 3.4), (0, 5.0, 4.6), (0, 4.6, 5.6)]
    for k, (a, b) in enumerate(zip(tail, tail[1:])):
        p.rod(f.p(*a), f.p(*b), 0.45 - k * 0.04, "white" if k % 2 == 0 else "pistachio", "SmoothPlastic", D)
    p.ball(0.5, f.p(0, 4.6, 5.8), "white", "SmoothPlastic", D)
    for i in range(4):
        a = i * 1.6
        p.box((0.16, 0.16, 0.16), (math.cos(a) * 2.6, math.sin(a) * 2.2, 5 + (i % 2) * 0.6), (45, 45, 0), "white",
              "Neon", D | KEEP)


@prop("JalebiMarkhor", "brainrot")
def jalebi_markhor(p):
    # a markhor (Pakistan's national animal) with huge spiral jalebi horns, a warm shawl and little bells
    p.blob(1.5, (0, 0.6, 3.1), (0.85, 1.5, 0.8), "llama", "SmoothPlastic", D, seed=460, jitter=0.03,
           fallback="Block", fallback_scale=(0.8, 0.85, 0.8))
    p.blob(1.05, (0, -1.7, 4.6), (0.85, 1.05, 1), "llama", "SmoothPlastic", D, seed=461, jitter=0.03,
           fallback="Ball")
    p.blob(0.55, (0, -2.55, 4.15), (0.9, 0.9, 0.8), "cream2", "SmoothPlastic", D, seed=462, fallback="Ball")
    p.cone(0.35, 1.4, (0, -2.3, 3.2), (180, 0, 0), "naanchar", "SmoothPlastic", D, verts=6,
           fallback="Cylinder")  # beard
    eyes(p, 0, -2.45, 4.9, 0.72, 0.26)
    smile(p, 0, -3.0, 4.1, 0.35)
    blush(p, 0, -2.45, 4.5, 1.1, 0.13)
    for side in (-1, 1):  # the jalebi horns: tall golden-orange spirals
        base = (side * 0.45, -1.4, 5.5)
        points = []
        for k in range(18):  # a corkscrew twisting up and out, like a real markhor's horn
            t = k / 17
            a = t * 4.5 * math.pi
            r = 0.45 - 0.2 * t
            points.append((base[0] + side * (0.2 + t * 0.7) + math.cos(a) * r * side,
                           base[1] + 0.5 * t + math.sin(a) * r, base[2] + t * 3.4))
        for k, (a, b) in enumerate(zip(points, points[1:])):
            p.rod(a, b, 0.24 - k * 0.008, "jalebi", "SmoothPlastic", D, verts=6)
        p.ball(0.2, points[-1], "honey", "Glass", D)
        p.box((0.25, 0.15, 0.5), (side * 0.95, -1.5, 5.15), (0, side * -30, 0), "llama", "SmoothPlastic", D)
    # the shawl over its back, maroon with a gold border
    p.blob(1.25, (0, 0.8, 3.75), (0.95, 1.4, 0.45), "maroon", "Fabric", D, seed=463, fallback="None")
    p.box((2.6, 3.4, 0.15), (0, 0.8, 3.95), None, "gold", "Fabric", D)
    for x in (-0.6, 0.6):
        for y in (-0.6, 1.8):
            leg(p, x, y, 2.0, 0.28, "llama", "darkwood", f=Frame())
    p.cyl(0.75, 0.25, (0, -1.15, 3.85), (60, 0, 0), "red", "Fabric", D, verts=12)  # collar
    for i in range(3):
        a = math.radians(-50 + i * 50)
        p.ball(0.18, (math.sin(a) * 0.7, -1.6, 3.5 - abs(math.cos(a)) * 0.1), "gold", "Metal", D, segments=6,
               rings=4)
    p.rod((0, 2.6, 3.4), (0, 3.1, 3.9), 0.15, "llama", "SmoothPlastic", D)
