"""The Chowk's art style, as building blocks every prop can use.

After the reference picture (docs/reference-chowk.jpg): warm wood, rosy
brick and cream stone, teal accents, bands of diamonds, striped awnings with a
scalloped edge and warm bulbs on a dark wire. Everything is made of blocks,
cylinders and balls, so it looks the same when the game builds it from parts.

Coordinates are Blender's: x across, y front (-y) to back, z up.
"""

from kit import LIGHT, NOCOLLIDE

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


def diamonds(p, x0, x1, y, z, height=0.8, band=GOLD, colors=(TEAL, "red"), step=None):
    """A band with a row of diamonds along it, on a face looking towards -y."""
    p.box((x1 - x0, 0.12, height), ((x0 + x1) / 2, y, z), None, band, "SmoothPlastic", D)
    size = height * 0.62
    step = step or height * 1.9
    n = max(1, int((x1 - x0 - size) / step) + 1)
    start = (x0 + x1) / 2 - (n - 1) * step / 2
    for i in range(n):
        p.box((size, 0.14, size), (start + i * step, y - 0.03, z), (0, 45, 0), colors[i % len(colors)],
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
