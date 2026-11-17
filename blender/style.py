"""The Chowk's art style, as building blocks every prop can use.

After the reference picture (docs/reference-chowk.jpg): warm wood, rosy
brick and cream stone, teal accents, bands of diamonds, striped awnings with a
scalloped edge and warm bulbs on a dark wire. Everything is made of blocks,
cylinders and balls, so it looks the same when the game builds it from parts.

Coordinates are Blender's: x across, y front (-y) to back, z up.
"""

from kit import LIGHT, NOCOLLIDE, PARTSONLY

D = NOCOLLIDE

# the palette names the style uses most
WOOD = "warmwood"  # posts, frames, planks
DARK_WOOD = "wood"  # legs and heavy beams
BRICK = "rosebrick"
CREAM = "cream"
TEAL = "dhabateal"
GOLD = "gold"
STRIPE = "cream2"  # the light stripe on awnings


def awning(p, x0, x1, y_back, y_front, z_back, z_front, colors=("red", STRIPE), stripes=6, scallops=True):
    """A striped awning sloping down from the back edge to the front edge, with a
    scalloped edge along the front: a strip with round tabs behind it, so only
    the bottom half of each tab shows."""
    width = (x1 - x0) / stripes
    for i in range(stripes):
        x = x0 + width * (i + 0.5)
        p.beam((x, y_back, z_back), (x, y_front, z_front), width + 0.02, 0.2, colors[i % len(colors)], "Fabric", D)
    if not scallops:
        return
    cx = (x0 + x1) / 2
    p.box((x1 - x0, 0.14, 0.6), (cx, y_front - 0.12, z_front - 0.2), None, colors[0], "Fabric", D)
    tabs = stripes * 2
    r = (x1 - x0) / tabs / 2
    for i in range(tabs):
        p.cyl(r, 0.1, (x0 + r * (2 * i + 1), y_front - 0.02, z_front - 0.5), (90, 0, 0), colors[(i // 2) % len(colors)],
              "Fabric", D, verts=12)


def diamonds(p, x0, x1, y, z, height=0.8, band=GOLD, colors=(TEAL, "red"), step=None, facing=-1):
    """A band with a row of diamonds along it, on a face looking towards -y
    (or towards +y with facing=1)."""
    p.box((x1 - x0, 0.12, height), ((x0 + x1) / 2, y, z), None, band, "SmoothPlastic", D)
    size = height * 0.62
    step = step or height * 1.9
    n = max(1, int((x1 - x0 - size) / step) + 1)
    start = (x0 + x1) / 2 - (n - 1) * step / 2
    for i in range(n):
        p.box((size, 0.14, size), (start + i * step, y + facing * 0.03, z), (0, 45, 0), colors[i % len(colors)],
              "SmoothPlastic", D)


def bulbs(p, x0, x1, y, z, count, light_every=3, size=0.28):
    """Warm bulbs hanging under a dark wire from x0 to x1."""
    p.box((x1 - x0, 0.06, 0.06), ((x0 + x1) / 2, y, z + size + 0.05), None, "black", "SmoothPlastic", D)
    for i in range(count):
        x = x0 + (x1 - x0) * (i + 0.5) / count
        p.ball(size, (x, y, z), "bulb", "Neon", D | (LIGHT if light_every and i % light_every == 0 else 0))


def post(p, x, y, height, size=0.5, color=WOOD, z0=0.0):
    """A chunky square wooden post standing on z0."""
    p.box((size, size, height), (x, y, z0 + height / 2), None, color, "Wood")


def signboard(p, x, y, z, width, height, color=TEAL, frame=CREAM):
    """A sign in a cream frame facing -y (the game writes on it at the returned point)."""
    p.box((width + 0.6, 0.25, height + 0.6), (x, y + 0.15, z), None, frame, "WoodPlanks", D)
    p.box((width, 0.25, height), (x, y, z), None, color, "WoodPlanks", D)
    return (x, y - 0.14, z)


def side_diamonds(p, x, y0, y1, z, height=0.7, band="dhabateal", colors=("gold", "red")):
    """A band of diamonds on a side face (looking along +x or -x)."""
    p.box((0.12, y1 - y0, height), (x, (y0 + y1) / 2, z), None, band, "SmoothPlastic", D)
    size, step = height * 0.62, height * 1.9
    n = max(1, int((y1 - y0 - size) / step) + 1)
    start = (y0 + y1) / 2 - (n - 1) * step / 2
    out = 0.03 if x > 0 else -0.03
    for i in range(n):
        p.box((0.14, size, size), (x + out, start + i * step, z), (45, 0, 0), colors[i % len(colors)],
              "SmoothPlastic", D)


def canopy(p, radius, pos, scale=(1, 1, 1), color="leaf", seed=0, blocks=2, mat="Grass", flags=D, jitter=0.18):
    """A faceted tree top like the Chowk's trees: the mesh is a lumpy low-poly
    ball, and the parts version is blocks turned different ways (a plain ball
    would look smooth and round in the game)."""
    p.blob(radius, pos, scale, color, mat, flags, seed=seed, jitter=jitter, fallback="None")
    turns = ((0, 0, 20 + seed * 7 % 40), (35, 0, 55 + seed * 11 % 30), (-30, 40, seed * 13 % 60))
    size = radius * 1.4
    for turn in turns[:blocks]:
        p.box((size * scale[0], size * scale[1], size * scale[2]), pos, turn, color, mat, flags | PARTSONLY)


def rock(p, radius, pos, scale=(1, 1, 0.75), color="stone", seed=0, mat="Slate", flags=0):
    """A chunky faceted rock: lumpy in the mesh, two turned blocks as parts."""
    canopy(p, radius, pos, scale, color, seed, 2, mat, flags, jitter=0.3)


def flags_along(p, points, x, drop=0.55, size=0.6, colors=("red", "gold", "dhabateal", "cream")):
    """Little diamond flags hanging from a rope that runs along y (at x)."""
    for i, q in enumerate(points):
        p.box((0.06, size, size), (x, q[1], q[2] - drop), (45, 0, 0), colors[i % len(colors)], "Fabric", D)


def cone(p, radius, height, pos, color, mat="SmoothPlastic", flags=0, steps=3):
    """A pointed roof or cap: a cone in the mesh, and stepped cylinders in the
    parts version (a cone would become a plain cylinder)."""
    x, y, z = pos  # the middle of the cone
    p.cone(radius, height, pos, None, color, mat, flags, verts=12, fallback="None")
    bottom = z - height / 2
    for k in range(steps):
        r = radius * (1 - k / steps)
        h = height / steps
        p.cyl(r, h, (x, y, bottom + h * (k + 0.5)), None, color, mat, flags | PARTSONLY, verts=12)
