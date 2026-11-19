"""Brainrot models, part 4: the Secret brainrots of Barfani Pahar."""

import math

import style
from brainrot_kit import block_arm, block_leg, chunk, cube_puff, D, Frame, arm, blush, brows, eyes, leg, puffs, smile
from kit import KEEP, PARTSONLY, prop


@prop("KahwaYeti", "brainrot")
def kahwa_yeti(p):
    # a big, fluffy, friendly yeti with frosty eyebrows, holding a steaming brass
    # samovar of kahwa engraved with a gold band of diamonds. A chunky body with
    # faceted fur tufts; its head stays round.
    chunk(p, 2.1, (0, 0.2, 3.4), (1, 0.9, 1.2), "white", seed=400)
    for i in range(10):  # tufts of fur
        a = i * 2 * math.pi / 10
        p.blob(0.6, (math.cos(a) * 1.9, 0.2 + math.sin(a) * 1.6, 2.4 + (i % 3) * 0.9), (1, 1, 1), "white",
               "SmoothPlastic", D, seed=401 + i, jitter=0.2, fallback="None")
        p.box((0.8, 0.8, 0.8), (math.cos(a) * 2.0, 0.2 + math.sin(a) * 1.75, 2.4 + (i % 3) * 0.9),
              (45, 35.26, i * 30), "white", "SmoothPlastic", D | PARTSONLY)
    p.blob(1.5, (0, -0.4, 6.1), (1, 0.95, 0.95), "white", "SmoothPlastic", D, seed=412, jitter=0.07,
           fallback="Ball")
    p.blob(1.0, (0, -1.35, 5.8), (1.1, 0.5, 0.85), "skyblue", "SmoothPlastic", D, seed=413, fallback="None")
    eyes(p, 0, -1.65, 6.2, 0.75, 0.27)
    brows(p, 0, -1.65, 6.2, 0.75, 0.27, "ice", tilt=-8)
    smile(p, 0, -1.8, 5.45, 0.55, open_mouth=True)
    blush(p, 0, -1.6, 5.8, 1.15, 0.15)
    for i, z in enumerate((4.4, 3.7, 3.0)):  # cardamom-pod buttons
        p.box((0.3, 0.2, 0.42), (0, -1.78 + i * 0.05, z), (0, 0, 45), "pistachio", "SmoothPlastic", D)
    for side in (-1, 1):
        block_leg(p, side * 0.95, 0.2, 1.2, 1.0, "white", "skyblue", foot_len=1.8)
        block_arm(p, (side * 1.8, -0.3, 4.4), (side * 1.0, -2.2, 3.4), 0.85, "white", "white", 1.0)
    # the samovar in its arms
    p.box((1.3, 1.3, 1.6), (0, -2.6, 3.3), None, "copper", "Metal", D)
    p.box((0.95, 0.95, 0.35), (0, -2.6, 4.27), None, "copper", "Metal", D)
    p.box((0.55, 0.55, 0.3), (0, -2.6, 4.6), (0, 0, 45), "copper", "Metal", D)
    p.box((0.36, 0.36, 0.36), (0, -2.6, 4.9), (45, 35.26, 0), "gold", "Metal", D)
    style.diamonds(p, -0.6, 0.6, -3.29, 3.3, height=0.32, band="gold", colors=("red", "dhabateal"), step=0.45)
    p.beam((0, -3.25, 3.2), (0, -3.7, 3.0), 0.16, 0.16, "gold", "Metal", D)
    cube_puff(p, [(0, -2.6, 5.4), (0.2, -2.7, 6.0), (-0.1, -2.6, 6.6)], 0.5)


@prop("GolaGandaGolem", "brainrot")
def gola_golem(p):
    # a giant ice golem built from crushed-ice gola gandas, rainbow syrup dripping,
    # gola sticks for fingers, a cart-style gold band of diamonds round its middle. A
    # chunky ice body and limbs; its head stays round.
    syrup = ("red", "orange", "green", "pink", "blue", "yellow")
    chunk(p, 1.9, (0, 0, 3.6), (1.1, 0.9, 1.15), "ice", "Ice", seed=430)
    p.blob(1.3, (0, -0.2, 6.2), (1, 1, 0.95), "ice", "Ice", D, seed=431, jitter=0.1, fallback="Ball")
    for i in range(6):  # syrup splashes on the ice
        a = i * 1.05
        p.blob(0.65, (math.cos(a) * 1.4, -0.9 + math.sin(a) * 0.4, 2.8 + (i % 3) * 1.1), (1, 0.6, 1),
               syrup[i], "SmoothPlastic", D, seed=432 + i, jitter=0.15, fallback="None")
        p.box((0.75, 0.12, 0.8), (math.cos(a) * 1.25, -1.62, 2.8 + (i % 3) * 1.1), (0, i * 17, 0), syrup[i],
              "SmoothPlastic", D | PARTSONLY)
    style.diamonds(p, -1.7, 1.7, -1.62, 2.2, height=0.36, band="gold", colors=("red", "dhabateal"), step=0.6)
    p.blob(0.9, (0, -0.2, 7.3), (1.2, 1.1, 0.5), "red", "SmoothPlastic", D, seed=440, fallback="None")
    for spin in (0, 45):
        p.box((1.7, 1.7, 0.4), (0, -0.2, 7.3 + spin * 0.001), (0, 0, spin), "red", "SmoothPlastic", D | PARTSONLY)
    for i, x in enumerate((-0.7, 0.1, 0.8)):
        p.box((0.3, 0.3, 0.3), (x, -1.25, 6.8 - i * 0.1), (45, 35.26, 0), syrup[i + 2], "SmoothPlastic", D)
    eyes(p, 0, -1.3, 6.25, 0.7, 0.26)
    brows(p, 0, -1.3, 6.25, 0.7, 0.26, "blue", tilt=6)
    smile(p, 0, -1.38, 5.55, 0.55)
    for side in (-1, 1):
        p.box((1.6, 1.8, 1.9), (side * 1.2, 0, 1.0), None, "ice", "Ice", D)  # the feet
        shoulder = (side * 2.0, 0, 4.6)
        hand = (side * 2.9, -0.6, 2.8)
        p.box((1.4, 1.4, 1.4), shoulder, (45, 35.26, 0), "ice", "Ice", D)
        p.beam(shoulder, hand, 1.1, 1.1, "ice", "Ice", D)
        p.box((1.2, 1.2, 1.2), hand, (45, 35.26, side * 20), syrup[(side + 2) % 6], "Ice", D)
        for k in range(3):  # wooden gola sticks for fingers
            p.beam((hand[0], hand[1], hand[2] - 0.3), (hand[0] + side * (0.3 + k * 0.2), hand[1] - 0.5 + k * 0.4,
                                                        hand[2] - 1.5), 0.16, 0.16, "lightwood", "Wood", D)
    for i, (x, z) in enumerate(((-1.0, 2.0), (0.6, 1.6), (1.3, 2.6))):  # drips
        p.box((0.28, 0.28, 0.28), (x, -1.85, z), (45, 35.26, 0), syrup[i], "SmoothPlastic", D)


@prop("BarfiBarfaniBagh", "brainrot")
def barfi_bagh(p):
    # a snow leopard made of white and pistachio barfi squares, silver warq spots, a
    # blocky woolly pakol cap with gold and teal diamonds on its rolled rim
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
    # the pakol: a blocky woolly cap with a rolled rim
    p.box((2.2, 2.2, 0.5), f.p(0, -2.4, 5.0), f.r(), "naan", "Fabric", D)
    p.box((2.45, 2.45, 0.4), f.p(0, -2.4, 4.75), f.r(), "naanchar", "Fabric", D)
    for k, x in enumerate((-0.6, 0, 0.6)):
        p.box((0.22, 0.08, 0.22), f.p(x, -3.66, 4.75), f.r((0, 45, 0)), "gold" if k != 1 else "dhabateal",
              "SmoothPlastic", D)
    for x in (-0.65, 0.65):
        for y in (-1.6, 2.6):
            block_leg(p, x, y, 1.6, 0.7, "white", "pistachio", f=f)
    tail = [(0, 3.2, 2.8), (0, 4.4, 3.4), (0, 5.0, 4.6), (0, 4.6, 5.6)]
    for k, (a, b) in enumerate(zip(tail, tail[1:])):
        w = 0.9 - k * 0.08
        p.beam(f.p(*a), f.p(*b), w, w, "white" if k % 2 == 0 else "pistachio", "SmoothPlastic", D)
    p.box((0.9, 0.9, 0.9), f.p(0, 4.6, 5.8), f.r((45, 35.26, 0)), "white", "SmoothPlastic", D)
    for i in range(4):
        a = i * 1.6
        p.box((0.16, 0.16, 0.16), (math.cos(a) * 2.6, math.sin(a) * 2.2, 5 + (i % 2) * 0.6), (45, 45, 0), "white",
              "Neon", D | KEEP)


@prop("JalebiMarkhor", "brainrot")
def jalebi_markhor(p):
    # a markhor (Pakistan's national animal) with huge square-spiral jalebi horns, a
    # maroon shawl with a gold border and hanging sides painted with diamonds, and
    # little bells. Its head stays round.
    p.blob(1.5, (0, 0.6, 3.1), (0.85, 1.5, 0.8), "llama", "SmoothPlastic", D, seed=460, jitter=0.03,
           fallback="Block", fallback_scale=(0.8, 0.85, 0.8))
    p.blob(1.05, (0, -1.7, 4.6), (0.85, 1.05, 1), "llama", "SmoothPlastic", D, seed=461, jitter=0.03,
           fallback="Ball")
    p.blob(0.55, (0, -2.55, 4.15), (0.9, 0.9, 0.8), "cream2", "SmoothPlastic", D, seed=462, fallback="Ball")
    p.cone(0.35, 1.4, (0, -2.3, 3.2), (180, 0, 0), "naanchar", "SmoothPlastic", D, verts=6,
           fallback="None")  # beard
    for k, w in enumerate((0.6, 0.42, 0.26)):
        p.box((w, w, 0.48), (0, -2.3, 3.7 - k * 0.46), (0, 0, 45), "naanchar", "SmoothPlastic", D | PARTSONLY)
    eyes(p, 0, -2.45, 4.9, 0.72, 0.26)
    smile(p, 0, -3.0, 4.1, 0.35)
    blush(p, 0, -2.45, 4.5, 1.1, 0.13)
    for side in (-1, 1):  # the jalebi horns: tall golden-orange spirals of square pieces
        base = (side * 0.45, -1.4, 5.5)
        points = []
        for k in range(18):  # a corkscrew twisting up and out, like a real markhor's horn
            t = k / 17
            a = t * 4.5 * math.pi
            r = 0.45 - 0.2 * t
            points.append((base[0] + side * (0.2 + t * 0.7) + math.cos(a) * r * side,
                           base[1] + 0.5 * t + math.sin(a) * r, base[2] + t * 3.4))
        for k, (a, b) in enumerate(zip(points, points[1:])):
            w = 0.46 - k * 0.015
            p.beam(a, b, w, w, "jalebi", "SmoothPlastic", D)
        p.box((0.36, 0.36, 0.36), points[-1], (45, 35.26, 0), "honey", "Glass", D)
        p.box((0.25, 0.15, 0.5), (side * 0.95, -1.5, 5.15), (0, side * -30, 0), "llama", "SmoothPlastic", D)
    # the shawl over its back, maroon with a gold border, hanging down both sides
    p.blob(1.25, (0, 0.8, 3.75), (0.95, 1.4, 0.45), "maroon", "Fabric", D, seed=463, fallback="None")
    p.box((2.6, 3.4, 0.15), (0, 0.8, 3.95), None, "gold", "Fabric", D)
    p.box((2.3, 3.1, 0.2), (0, 0.8, 4.05), None, "maroon", "Fabric", D | PARTSONLY)
    for side in (-1, 1):
        p.box((0.1, 2.8, 0.9), (side * 1.1, 0.8, 3.5), None, "maroon", "Fabric", D)
        style.side_diamonds(p, side * 1.18, -0.4, 2.0, 3.25, height=0.3, band="gold", colors=("dhabateal", "white"))
    for x in (-0.6, 0.6):
        for y in (-0.6, 1.8):
            block_leg(p, x, y, 2.0, 0.56, "llama", "darkwood", f=Frame())
    p.box((1.45, 1.45, 0.25), (0, -1.15, 3.85), (60, 0, 0), "red", "Fabric", D)  # collar
    for i in range(3):
        a = math.radians(-50 + i * 50)
        p.ball(0.18, (math.sin(a) * 0.7, -1.6, 3.5 - abs(math.cos(a)) * 0.1), "gold", "Metal", D, segments=6,
               rings=4)
    p.beam((0, 2.6, 3.4), (0, 3.1, 3.9), 0.3, 0.3, "llama", "SmoothPlastic", D)
