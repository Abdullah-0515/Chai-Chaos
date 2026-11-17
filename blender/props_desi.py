"""Desi everyday props: charpais, matkas, dhabas, stalls, trucks, rickshaws, huts and boats."""

import math

from kit import GLASS, LIGHT, NOCOLLIDE, prop
import style


def legs(p, w, l, h, color="darkwood", size=0.3, inset=0.2, mat="Wood"):
    for x in (-w / 2 + inset, w / 2 - inset):
        for y in (-l / 2 + inset, l / 2 - inset):
            p.box((size, size, h), (x, y, h / 2), color=color, mat=mat)


def wheel(p, radius, pos, width=0.6, color="tyre", hub="metal"):
    """A wheel turning about the X axis (on a vehicle facing -Y)."""
    p.cyl(radius, width, pos, (0, 90, 0), color=color, mat="SmoothPlastic", verts=12)
    p.cyl(radius * 0.45, width + 0.1, pos, (0, 90, 0), color=hub, mat="Metal", verts=8, flags=NOCOLLIDE)


def umbrella(p, pos, height, radius, color, stripe=None):
    x, y, _ = pos
    p.rod((x, y, 0), (x, y, height), 0.1, "metal", "Metal")
    p.cone(radius, 1.4, (x, y, height + 0.4), color=color, mat="Fabric", verts=8, flags=NOCOLLIDE,
           fallback="Disc", fallback_scale=(1, 1, 0.3))
    if stripe:
        p.cone(radius * 0.5, 0.75, (x, y, height + 0.75), color=stripe, mat="Fabric", verts=8, flags=NOCOLLIDE,
               fallback="None")


def weave(p, a, b, z, spacing, color, width=0.14):
    """Diagonal strips both ways across an a x b rectangle (half sizes), like a woven charpai."""
    reach = a + b
    steps = int(reach * 2 / spacing)
    for sign in (1, -1):
        for k in range(steps + 1):
            c = -reach + k * spacing
            # the line y = sign * (x - c), clipped to the rectangle
            ends = []
            for x in (-a, a):
                y = sign * (x - c)
                if -b <= y <= b:
                    ends.append((x, y))
            for y in (-b, b):
                x = c + y * sign
                if -a < x < a:
                    ends.append((x, y))
            if len(ends) >= 2:
                (x0, y0), (x1, y1) = ends[0], ends[-1]
                if math.hypot(x1 - x0, y1 - y0) > 0.3:
                    # one direction sits a little higher, so crossing strips never share a face
                    lift = 0.02 if sign < 0 else 0
                    p.beam((x0, y0, z + lift), (x1, y1, z + lift), width, 0.04, color, "Fabric", NOCOLLIDE)


@prop("Charpai", "desi", "A woven rope bed")
def charpai(p):
    w, l, h = 3.4, 6.4, 1.5
    # thick dark legs that poke up above the frame at the corners
    for x in (-w / 2 + 0.25, w / 2 - 0.25):
        for y in (-l / 2 + 0.25, l / 2 - 0.25):
            p.box((0.5, 0.5, h + 0.2), (x, y, (h + 0.2) / 2), color="wood", mat="Wood")
    # the warm wooden frame between the legs
    for x in (-w / 2 + 0.25, w / 2 - 0.25):
        p.box((0.36, l - 1.0, 0.36), (x, 0, h - 0.13), color="warmwood", mat="Wood")
    for y in (-l / 2 + 0.25, l / 2 - 0.25):
        p.box((w - 1.0, 0.36, 0.36), (0, y, h - 0.13), color="warmwood", mat="Wood")
    # the straw seat with a diagonal weave
    p.box((w - 0.7, l - 0.7, 0.1), (0, 0, h - 0.06), color="straw", mat="Fabric")
    weave(p, (w - 0.8) / 2, (l - 0.8) / 2, h + 0.01, 0.75, "wheat")


@prop("Milestone", "desi", "A roadside milestone; the game writes the distance on it")
def milestone(p):
    # a cream stone base, a whitewashed stone with a rosy band and a yellow top
    p.box((2.0, 1.3, 0.3), (0, 0, 0.15), color="cream", mat="Concrete")
    p.box((1.6, 0.9, 2.4), (0, 0, 1.5), color="whitewash", mat="Concrete")
    p.box((1.64, 0.94, 0.25), (0, 0, 0.55), color="rosebrick", mat="Concrete")
    # a little thinner than the stone, so only its top half shows: a round yellow top
    p.cyl(0.8, 0.84, (0, 0, 2.7), (90, 0, 0), color="yellow", mat="Concrete", verts=16)
    p.anchor("Face", (0, -0.46, 1.6))


@prop("Matka", "desi", "Clay water pots on a wooden stand")
def matka(p):
    # a sturdy stand of warm wood with a shelf and cross braces
    p.box((3.8, 1.5, 0.3), (0, 0, 1.65), color="warmwood", mat="WoodPlanks")
    for x in (-1.65, 1.65):
        for y in (-0.5, 0.5):
            p.box((0.35, 0.35, 1.5), (x, y, 0.75), color="wood", mat="Wood")
    p.box((3.3, 1.0, 0.2), (0, 0, 0.45), color="warmwood", mat="WoodPlanks")
    # three clay pots with cream painted bands and wooden lids
    for i, x in enumerate((-1.15, 0, 1.15)):
        clay = "clay" if i != 1 else "terracotta"
        p.ball(0.66, (x, 0, 2.4), color=clay, mat="Slate", segments=12, rings=8)
        p.cyl(0.68, 0.14, (x, 0, 2.45), color="cream", mat="SmoothPlastic", verts=12)
        p.cyl(0.3, 0.38, (x, 0, 3.12), color="claydark", mat="Slate", verts=10)
        p.cyl(0.4, 0.12, (x, 0, 3.36), color="warmwood", mat="Wood", verts=10)
    # a steel lota on the shelf
    p.cyl(0.25, 0.4, (0.9, 0, 0.75), color="steel", mat="Metal", verts=10)


@prop("TubeWell", "desi", "A hand pump with a trough")
def tubewell(p):
    # a brick platform with a cream kerb
    p.box((4, 4, 0.45), (0, 0.4, 0.22), color="rosebrick", mat="Brick")
    p.box((4.2, 4.2, 0.15), (0, 0.4, 0.5), color="cream", mat="Concrete")
    # the teal hand pump with a cream cap
    p.cyl(0.38, 3.0, (0, 0.8, 2.05), color="dhabateal", mat="Metal", verts=12)
    p.cyl(0.5, 0.3, (0, 0.8, 0.7), color="dhabateal", mat="Metal", verts=12)
    p.ball(0.48, (0, 0.8, 3.6), color="cream", mat="Metal")
    p.rod((0, 0.8, 3.4), (0, 2.6, 4.1), 0.13, "darkmetal", "Metal")
    p.rod((0, 0.8, 2.6), (0, -0.3, 2.3), 0.15, "dhabateal", "Metal")
    # a cream stone trough of water and a steel bucket
    p.box((2.2, 1.2, 0.7), (0, -1.0, 0.85), color="cream", mat="Concrete")
    p.box((1.9, 0.9, 0.1), (0, -1.0, 1.16), color="water", mat="Glass", flags=NOCOLLIDE)
    p.cyl(0.42, 0.6, (1.45, -0.4, 0.85), color="steel", mat="Metal", verts=12)


@prop("ChaiDhaba", "desi", "A roadside tea stall with a tin roof; the game writes CHAI on its sign")
def dhaba(p):
    # a little cousin of the Chowk's Chai Dhaba
    p.box((12, 9, 0.3), (0, 0, 0.15), color="stone", mat="Concrete")
    # the brick counter at the back with a band of diamonds
    p.box((10, 1.6, 2.8), (0, 3.3, 1.7), color="rosebrick", mat="Brick")
    style.diamonds(p, -5, 5, 2.44, 2.2, height=0.8)
    p.box((10.4, 2.0, 0.25), (0, 3.2, 3.22), color="cream", mat="Concrete")
    # chunky warm wood posts and a tin roof with a cream ridge
    # (the roof slopes down to the front, so the front posts are shorter)
    for x in (-5.6, 5.6):
        for y, height in ((-4.1, 7.7), (4.1, 8.5)):
            style.post(p, x, y, height, 0.55)
    p.box((13, 10, 0.25), (0, 0, 8.25), (6, 0, 0), color="tin", mat="Metal")
    for i in range(-6, 7, 2):  # the ribs of the tin sheets
        p.box((0.25, 10, 0.12), (i, 0, 8.42), (6, 0, 0), "metal", "Metal", style.D)
    p.box((13.2, 0.5, 0.4), (0, 4.7, 8.85), None, "cream", "SmoothPlastic", style.D)
    # the teal scalloped awning on the front
    style.awning(p, -6.3, 6.3, -4.1, -5.9, 7.6, 6.7, colors=("dhabateal", "cream2"), stripes=7)
    style.bulbs(p, -5.2, 5.2, -4.3, 6.2, 6)
    # the kettle, glasses of chai and a jar of rusks
    p.box((1.4, 1.1, 0.7), (-3, 3.2, 3.7), color="darkmetal", mat="Metal")
    p.cyl(0.6, 0.7, (-3, 3.2, 4.4), None, "steel", "Metal", verts=12)
    p.ball(0.55, (-3, 3.2, 4.8), "steel", "Metal")
    p.rod((-3.5, 3.2, 4.5), (-4.2, 3.2, 5.0), 0.12, "steel", "Metal", style.D)
    for i in range(5):
        p.cyl(0.18, 0.45, (0.4 + i * 0.6, 3.0, 3.57), None, "chai", "Glass", style.D, verts=8)
    p.box((1.8, 1.0, 1.4), (3.5, 3.4, 4.05), color="glass", mat="Glass", flags=GLASS | NOCOLLIDE)
    # the sign on the roof
    sign = style.signboard(p, 0, -4.5, 9.6, 6.0, 1.6)
    p.anchor("Sign", sign)
    for x in (-2.6, 2.6):
        p.box((0.3, 0.3, 1.4), (x, -4.3, 8.6), None, "warmwood", "Wood", style.D)
    # benches
    for x in (-3.2, 3.2):
        p.box((4.6, 1.0, 0.3), (x, -1.8, 1.3), color="warmwood", mat="WoodPlanks")
        for dx in (-1.9, 1.9):
            p.box((0.35, 0.8, 1.15), (x + dx, -1.8, 0.58), color="wood", mat="Wood")
    p.cyl(0.9, 0.12, (0, -1.8, 1.75), color="dhabateal", mat="Metal", verts=12, flags=NOCOLLIDE)


def cart_base(p, length, width, height, body, trim, wheel_radius=1.0):
    """A wooden market cart: a body on two wheels with a front leg."""
    p.box((length, width, height), (0, 0, wheel_radius + 0.4 + height / 2), None, body, "WoodPlanks")
    p.box((length + 0.2, width + 0.2, 0.25), (0, 0, wheel_radius + 0.4 + height + 0.12), None, trim, "WoodPlanks")
    wheel(p, wheel_radius, (-(length / 2 + 0.25), 0.3, wheel_radius), 0.35)
    wheel(p, wheel_radius, (length / 2 + 0.25, 0.3, wheel_radius), 0.35)
    p.rod((0, -width / 2, wheel_radius + 0.4), (0, -width / 2, 0), 0.16, "wood", "Wood")
    return wheel_radius + 0.4 + height + 0.25


def canopy(p, length, width, top, z, colors, stripes=5):
    """Four posts and a striped canopy with a scalloped front edge over a cart."""
    for x in (-length / 2 + 0.2, length / 2 - 0.2):
        for y in (-width / 2 + 0.2, width / 2 - 0.2):
            style.post(p, x, y, top - z, 0.25, z0=z)
    style.awning(p, -length / 2 - 0.3, length / 2 + 0.3, width / 2 + 0.3, -width / 2 - 0.5, top + 0.5, top - 0.2,
                 colors=colors, stripes=stripes)


@prop("FruitStall", "desi", "A fruit cart with an umbrella")
def fruit_stall(p):
    top = cart_base(p, 5.2, 3.2, 0.9, "warmwood", "cream")
    fruit = [("orange", (-1.6, -0.6)), ("red", (0, -0.6)), ("yellow", (1.6, -0.6)), ("mango", (-1.6, 0.7)),
             ("leaflight", (0, 0.7)), ("red", (1.6, 0.7))]
    for color, (x, y) in fruit:
        p.box((1.4, 1.1, 0.5), (x, y, top + 0.25), color="lightwood", mat="WoodPlanks")
        for k in range(3):
            p.ball(0.33, (x - 0.38 + k * 0.38, y + (0.15 if k == 1 else -0.1), top + 0.68), color=color,
                   mat="SmoothPlastic", flags=NOCOLLIDE, segments=8, rings=6)
    canopy(p, 5.2, 3.2, 6.2, top, ("red", "cream2"))


@prop("PakoraStall", "desi", "A pakora and samosa stall with a big kadhai")
def pakora_stall(p):
    # a brick-fronted counter with a band of diamonds
    p.box((4.8, 2.6, 2.4), (0, 0, 1.2), color="rosebrick", mat="Brick")
    style.diamonds(p, -2.4, 2.4, -1.36, 1.5, height=0.7)
    p.box((5.1, 2.9, 0.25), (0, 0, 2.52), color="cream", mat="Concrete")
    # the kadhai of hot oil on its stove
    p.box((1.4, 1.4, 0.5), (-1.2, 0.2, 2.9), color="darkmetal", mat="Metal")
    p.cyl(0.95, 0.45, (-1.2, 0.2, 3.38), color="black", mat="Metal", verts=14)
    p.cyl(0.8, 0.05, (-1.2, 0.2, 3.6), color="orange", mat="SmoothPlastic", flags=NOCOLLIDE, verts=14)
    # a tray of pakoras and samosas
    p.box((1.9, 1.3, 0.12), (1.0, 0.0, 2.71), color="steel", mat="Metal")
    for i in range(6):
        p.ball(0.22, (0.45 + (i % 3) * 0.55, -0.3 + (i // 3) * 0.5, 2.92), "pakora", "SmoothPlastic", NOCOLLIDE)
    for i in range(3):
        p.box((0.45, 0.45, 0.32), (0.45 + i * 0.55, 0.42, 2.95), (0, 0, 45), "samosa", "SmoothPlastic", NOCOLLIDE)
    canopy(p, 4.8, 2.6, 5.8, 2.65, ("yellow", "ochre"))


@prop("GolaCart", "desi", "A gola ganda (shaved ice) cart with syrup bottles")
def gola_cart(p):
    top = cart_base(p, 4.2, 2.4, 1.6, "dhabateal", "cream", 0.9)
    style.diamonds(p, -2.1, 2.1, -1.26, 2.1, height=0.6, band="yellow", colors=("pink", "red"))
    # a block of ice and a row of syrup bottles
    p.box((1.1, 1.1, 1.0), (-1.2, 0.3, top + 0.5), color="ice", mat="Glass", flags=GLASS)
    for i, color in enumerate(("red", "yellow", "green", "pink", "blue", "orange")):
        p.cyl(0.16, 0.9, (0.0 + i * 0.35, 0.5, top + 0.45), color=color, mat="Glass", verts=8, flags=NOCOLLIDE)
    # gola sticks ready to go
    for i, color in enumerate(("red", "orange", "pink")):
        p.ball(0.3, (-0.2 + i * 0.6, -0.6, top + 0.55), color, "SmoothPlastic", NOCOLLIDE)
    canopy(p, 4.2, 2.4, 5.6, top, ("pink", "cream2"))


def side_diamonds(p, x, y0, y1, z, height=0.7, band="dhabateal", colors=("gold", "red")):
    """A band of diamonds on a side face (looking along +x or -x)."""
    p.box((0.12, y1 - y0, height), (x, (y0 + y1) / 2, z), None, band, "SmoothPlastic", NOCOLLIDE)
    size, step = height * 0.62, height * 1.9
    n = max(1, int((y1 - y0 - size) / step) + 1)
    start = (y0 + y1) / 2 - (n - 1) * step / 2
    out = 0.03 if x > 0 else -0.03
    for i in range(n):
        p.box((0.14, size, size), (x + out, start + i * step, z), (45, 0, 0), colors[i % len(colors)],
              "SmoothPlastic", NOCOLLIDE)


@prop("TruckArt", "desi", "A painted Bedford truck with its wooden crown")
def truck(p):
    p.box((5.6, 18, 0.7), (0, 0.5, 1.7), color="darkmetal", mat="Metal")
    # hood, cab and windscreen
    p.box((5.0, 3.0, 2.2), (0, -8.6, 3.0), color="green", mat="SmoothPlastic")
    p.box((6.2, 3.8, 3.8), (0, -5.4, 3.9), color="yellow", mat="SmoothPlastic")
    p.box((6.3, 3.9, 0.4), (0, -5.4, 3.2), color="red", mat="SmoothPlastic")
    p.box((5.2, 0.15, 1.5), (0, -7.33, 4.8), color="skyblue", mat="Glass")
    for x in (-3.15, 3.15):
        p.box((0.15, 1.6, 1.3), (x, -5.8, 4.7), color="skyblue", mat="Glass")
    p.box((5.6, 0.6, 1.0), (0, -10.3, 2.2), color="red", mat="Metal")
    for x in (-1.9, 1.9):
        p.ball(0.45, (x, -10.15, 3.1), color="bulb", mat="Neon", flags=NOCOLLIDE)
    # the jingling chains along the bumper
    for i in range(12):
        p.box((0.14, 0.14, 0.9), (-2.6 + i * 0.47, -10.65, 1.4), None, "gold", "Metal", NOCOLLIDE)
    # the famous wooden crown over the cab, with paint, a band of diamonds and mirrors
    p.box((6.6, 0.7, 3.2), (0, -6.9, 7.4), color="red", mat="WoodPlanks")
    p.box((5.6, 0.75, 2.2), (0, -6.95, 7.6), color="green", mat="WoodPlanks")
    style.diamonds(p, -2.6, 2.6, -7.38, 7.6, height=0.8, band="yellow", colors=("pink", "blue"))
    p.box((7.2, 0.8, 0.4), (0, -6.9, 9.1), color="gold", mat="Metal")
    for x, color in zip((-3.0, -1.5, 0, 1.5, 3.0), ("pink", "blue", "pink", "blue", "pink")):
        p.ball(0.32, (x, -7.3, 9.4), color=color, mat="SmoothPlastic", flags=NOCOLLIDE)
    for x in (-3.6, 3.6):
        p.cyl(0.5, 0.2, (x, -7.3, 7.6), (90, 0, 0), color="glass", mat="Glass", verts=10, flags=NOCOLLIDE)
    # the cargo body, painted panels on every side with cream rails
    p.box((6.6, 13.2, 0.4), (0, 2.8, 2.25), color="warmwood", mat="WoodPlanks")
    stripes = ("red", "yellow", "green", "blue")
    for x in (-3.2, 3.2):
        p.box((0.25, 13.2, 3.6), (x, 2.8, 4.25), color="orange", mat="WoodPlanks")
        for k, color in enumerate(stripes):
            p.box((0.1, 12.6, 0.45), (x * 1.02, 2.8, 2.85 + k * 0.6), color=color, mat="SmoothPlastic",
                  flags=NOCOLLIDE)
        side_diamonds(p, x * 1.035, -3.2, 8.8, 5.25, height=0.8)
        p.box((0.4, 13.4, 0.3), (x, 2.8, 6.2), None, "cream", "WoodPlanks")
    p.box((6.6, 0.25, 3.6), (0, 9.3, 4.25), color="blue", mat="WoodPlanks")
    for k, color in enumerate(("yellow", "pink", "green")):
        p.box((5.4, 0.1, 0.6), (0, 9.45, 3.2 + k * 1.0), color=color, mat="SmoothPlastic", flags=NOCOLLIDE)
    p.box((6.6, 0.25, 3.6), (0, -3.6, 4.25), color="maroon", mat="WoodPlanks")
    # wheels and mud flaps
    for y in (-8.5, 4.0, 6.8):
        for x in (-2.7, 2.7):
            wheel(p, 1.35, (x, y, 1.35), 0.8)
    for x in (-2.7, 2.7):
        p.box((1.4, 0.12, 1.4), (x, 8.4, 1.0), color="black", mat="Fabric", flags=NOCOLLIDE)


@prop("Rickshaw", "desi", "An auto rickshaw")
def rickshaw(p):
    # green below, yellow on top, like the rickshaw in the reference picture
    p.box((3.8, 5.6, 0.6), (0, 0.6, 1.3), color="rickshawgreen", mat="SmoothPlastic")
    p.box((3.85, 5.65, 0.25), (0, 0.6, 1.65), color="cream", mat="SmoothPlastic")
    p.box((1.6, 1.6, 2.8), (0, -3.0, 2.6), color="rickshawgreen", mat="SmoothPlastic")
    p.box((1.5, 0.15, 1.3), (0, -3.82, 3.6), color="skyblue", mat="Glass")
    p.ball(0.3, (0, -3.85, 2.3), "bulb", "Neon", NOCOLLIDE)
    p.rod((-1.0, -2.7, 3.9), (1.0, -2.7, 3.9), 0.1, "black", "Metal")
    p.box((3.6, 1.6, 1.4), (0, 2.4, 2.3), color="black", mat="Fabric")
    p.box((3.8, 0.3, 2.2), (0, 3.3, 3.0), color="yellow", mat="SmoothPlastic")
    p.box((3.4, 0.12, 0.5), (0, 3.48, 2.6), color="dhabateal", mat="SmoothPlastic", flags=NOCOLLIDE)
    p.box((4.3, 5.5, 0.45), (0, 0.6, 5.65), color="yellow", mat="Fabric")
    p.box((4.4, 5.6, 0.2), (0, 0.6, 5.35), color="rickshawgreen", mat="Fabric")
    for x in (-1.9, 1.9):
        for y in (-1.9, 3.2):
            p.rod((x, y, 1.6), (x, y, 5.4), 0.1, "black", "Metal")
        p.box((0.1, 4.2, 0.35), (x * 1.05, 0.9, 1.9), color="yellow", mat="SmoothPlastic", flags=NOCOLLIDE)
    wheel(p, 0.85, (0, -3.4, 0.85), 0.4)
    wheel(p, 0.85, (-1.95, 2.2, 0.85), 0.4)
    wheel(p, 0.85, (1.95, 2.2, 0.85), 0.4)


@prop("TractorTrolley", "desi", "A red tractor pulling a trolley of hay")
def tractor(p):
    p.box((2.4, 4.2, 2.2), (0, -6.2, 2.8), color="red", mat="SmoothPlastic")
    p.box((2.2, 0.2, 1.4), (0, -8.35, 2.8), color="cream", mat="Metal")
    for k in range(4):
        p.box((1.8, 0.22, 0.14), (0, -8.42, 2.3 + k * 0.33), None, "darkmetal", "Metal", NOCOLLIDE)
    p.box((3.0, 2.8, 2.6), (0, -3.0, 3.0), color="red", mat="SmoothPlastic")
    p.box((1.2, 1.0, 1.4), (0, -1.2, 4.6), color="black", mat="Fabric")
    p.rod((0, -2.2, 4.0), (0, -2.8, 5.4), 0.1, "black", "Metal")
    p.cyl(0.55, 0.12, (0, -2.85, 5.45), (30, 0, 0), color="black", mat="Metal", verts=10)
    p.rod((0.8, -6.8, 3.9), (0.8, -6.8, 6.0), 0.15, "darkmetal", "Metal")
    wheel(p, 2.2, (-2.2, -2.2, 2.2), 1.2)
    wheel(p, 2.2, (2.2, -2.2, 2.2), 1.2)
    wheel(p, 1.1, (-1.5, -6.8, 1.1), 0.6)
    wheel(p, 1.1, (1.5, -6.8, 1.1), 0.6)
    for x in (-2.2, 2.2):
        p.box((1.5, 3.2, 0.25), (x, -2.2, 4.6), color="red", mat="SmoothPlastic")
    p.rod((0, 0.2, 1.4), (0, 2.6, 1.4), 0.15, "darkmetal", "Metal")
    # the trolley: warm wood with blue sides, cream rails and a band of diamonds
    p.box((5.6, 9.0, 0.4), (0, 7.2, 2.6), color="warmwood", mat="WoodPlanks")
    for x in (-2.7, 2.7):
        p.box((0.25, 9.0, 1.6), (x, 7.2, 3.6), color="blue", mat="WoodPlanks")
        side_diamonds(p, x * 1.04, 3.2, 11.2, 3.6, height=0.6, band="yellow", colors=("red", "dhabateal"))
        p.box((0.35, 9.2, 0.25), (x, 7.2, 4.5), None, "cream", "WoodPlanks")
    for y in (2.8, 11.6):
        p.box((5.6, 0.25, 1.6), (0, y, 3.6), color="blue", mat="WoodPlanks")
    wheel(p, 1.3, (-3.0, 7.2, 1.3), 0.7)
    wheel(p, 1.3, (3.0, 7.2, 1.3), 0.7)
    # a load of square hay bales (blocks, so the parts version looks the same)
    for i, (x, y, z) in enumerate(((-1.3, 5.0, 3.4), (1.3, 5.0, 3.4), (-1.3, 9.4, 3.4), (1.3, 9.4, 3.4),
                                   (0, 7.2, 4.9), (-1.3, 7.2, 3.4), (1.3, 7.2, 3.4))):
        p.box((2.5, 2.1, 1.5), (x, y, z), (0, 0, 4 if i % 2 else -3), "hay", "Grass")
        p.box((2.55, 0.12, 1.52), (x, y, z), (0, 0, 4 if i % 2 else -3), "wheat", "Fabric", NOCOLLIDE)


@prop("BusStop", "desi", "A bus stop shelter with a bench")
def bus_stop(p):
    p.box((7.4, 3.2, 0.3), (0, 0, 0.15), color="cream", mat="Concrete")
    p.box((7.0, 0.3, 4.6), (0, 1.3, 2.6), color="dhabateal", mat="SmoothPlastic")
    style.diamonds(p, -3.5, 3.5, 1.13, 4.3, height=0.6, band="yellow")
    p.box((7.0, 0.32, 1.0), (0, 1.3, 1.0), color="cream", mat="SmoothPlastic")
    for x in (-3.4, 3.4):
        style.post(p, x, -1.3, 4.6, 0.35)
        style.post(p, x, 1.3, 5.0, 0.35)
    style.awning(p, -3.8, 3.8, 1.6, -1.8, 5.2, 4.6, colors=("dhabateal", "cream2"), stripes=6)
    p.box((5.2, 1.0, 0.3), (0, 0.5, 1.6), color="warmwood", mat="WoodPlanks")
    for x in (-2.2, 2.2):
        p.box((0.3, 0.8, 1.3), (x, 0.5, 0.95), color="wood", mat="Wood")
    p.rod((4.4, -0.8, 0), (4.4, -0.8, 5.6), 0.1, "darkmetal", "Metal")
    p.cyl(0.9, 0.15, (4.4, -0.8, 5.9), (90, 0, 0), color="red", mat="SmoothPlastic", verts=16)
    p.cyl(0.65, 0.17, (4.4, -0.8, 5.9), (90, 0, 0), color="white", mat="SmoothPlastic", verts=16,
          flags=NOCOLLIDE)
    p.anchor("Sign", (4.4, -0.9, 5.9))


@prop("Signboard", "desi", "A teal sign on wooden posts; the game writes on it")
def signboard(p):
    for x in (-2.4, 2.4):
        style.post(p, x, 0.2, 6.6, 0.35)
    style.signboard(p, 0, 0.05, 5.0, 5.6, 2.6)
    p.box((6.6, 0.6, 0.3), (0, 0.15, 6.75), None, "rosebrick", "WoodPlanks", NOCOLLIDE)
    p.anchor("Face", (0, -0.11, 5.0))


@prop("Tandoor", "desi", "A clay tandoor oven")
def tandoor(p):
    p.box((2.9, 2.9, 0.35), (0, 0, 0.17), color="rosebrick", mat="Brick")
    p.box((3.0, 3.0, 0.12), (0, 0, 0.4), color="cream", mat="Concrete")
    p.cyl(1.2, 1.7, (0, 0, 1.3), color="clay", mat="Slate", verts=14)
    p.cyl(1.23, 0.22, (0, 0, 1.6), color="cream", mat="SmoothPlastic", verts=14)
    p.cyl(1.0, 0.18, (0, 0, 2.18), color="claydark", mat="Slate", verts=14)
    p.cyl(0.8, 0.2, (0, 0, 2.2), color="flame", mat="Neon", verts=12, flags=NOCOLLIDE)


@prop("Haystack", "desi", "A round haystack with a pole")
def haystack(p):
    # a round pile, narrowing in steps, tied with rope
    for radius, height, z, color in ((2.7, 2.2, 1.1, "hay"), (2.3, 1.4, 2.9, "wheat"), (1.6, 1.1, 4.1, "hay"),
                                     (0.9, 0.8, 5.0, "wheat")):
        p.cyl(radius, height, (0, 0, z), None, color, "Grass", verts=10)
    for radius, z in ((2.75, 1.6), (2.35, 3.0)):
        p.cyl(radius, 0.18, (0, 0, z), None, "rope", "Fabric", NOCOLLIDE, verts=10)
    p.rod((0, 0, 4.5), (0.3, 0.2, 7.0), 0.14, "wood", "Wood", NOCOLLIDE)


@prop("MudHut", "desi", "A village mud house with a flat roof and a ladder")
def mud_hut(p):
    p.box((8, 7, 4.5), (0, 0, 2.25), color="mud", mat="Slate")
    p.box((8.05, 7.05, 0.6), (0, 0, 0.3), color="mudlight", mat="Slate")
    p.box((8.6, 7.6, 0.4), (0, 0, 4.7), color="mudlight", mat="Slate")
    # a parapet with little battlements
    for sx, sy, px, py in ((8.6, 0.4, 0, -3.6), (8.6, 0.4, 0, 3.6), (0.4, 6.8, -4.1, 0), (0.4, 6.8, 4.1, 0)):
        p.box((sx, sy, 0.5), (px, py, 5.15), color="mudlight", mat="Slate")
    for x in (-3.6, -1.2, 1.2, 3.6):
        p.box((0.9, 0.42, 0.6), (x, -3.6, 5.7), None, "mudlight", "Slate")
    # a warm wood door in a cream frame, a window with teal shutters
    p.box((2.4, 0.2, 3.6), (-1.5, -3.53, 1.8), color="cream", mat="Concrete", flags=NOCOLLIDE)
    p.box((1.8, 0.25, 3.2), (-1.5, -3.56, 1.6), color="warmwood", mat="WoodPlanks")
    p.box((1.8, 0.2, 1.5), (2.0, -3.53, 2.8), color="cream", mat="Concrete", flags=NOCOLLIDE)
    for half in (-1, 1):
        p.box((0.65, 0.25, 1.1), (2.0 + half * 0.36, -3.56, 2.8), color="dhabateal", mat="WoodPlanks")
    # whitewashed diamonds painted on the wall
    for k in range(3):
        p.box((0.55, 0.12, 0.55), (-3.0 + k * 1.2, -3.52, 4.0), (0, 45, 0), "whitewash", "SmoothPlastic", NOCOLLIDE)
        p.box((0.55, 0.12, 0.55), (1.0 + k * 1.2, -3.52, 4.0), (0, 45, 0), "whitewash", "SmoothPlastic", NOCOLLIDE)
    # the ladder up to the roof
    for y in (-0.5, 0.5):
        p.rod((4.6, y, 0), (4.3, y, 5.4), 0.12, "warmwood", "Wood")
    for k in range(5):
        p.box((0.14, 1.1, 0.14), (4.55 - k * 0.06, 0, 0.9 + k * 1.0), color="warmwood", mat="Wood")


@prop("WaterTank", "desi", "The village water tank on stilts; treasure sits on its lid")
def water_tank(p):
    # cream concrete stilts with brick braces
    for x in (-3, 3):
        for y in (-3, 3):
            p.box((0.9, 0.9, 16), (x, y, 8), color="cream", mat="Concrete")
    for z in (5, 11):
        p.box((6.8, 0.35, 0.4), (0, -3, z), color="rosebrick", mat="Brick")
        p.box((6.8, 0.35, 0.4), (0, 3, z), color="rosebrick", mat="Brick")
        p.box((0.35, 6.8, 0.4), (-3, 0, z), color="rosebrick", mat="Brick")
        p.box((0.35, 6.8, 0.4), (3, 0, z), color="rosebrick", mat="Brick")
    # the tank: cream with a teal band, a gold stripe and a brick rim
    p.cyl(4.5, 6, (0, 0, 19), color="cream", mat="Concrete", verts=16)
    p.cyl(4.55, 1.4, (0, 0, 19.3), color="dhabateal", mat="SmoothPlastic", verts=16)
    p.cyl(4.58, 0.25, (0, 0, 19.3), color="gold", mat="SmoothPlastic", verts=16)
    p.cyl(4.6, 0.6, (0, 0, 16.3), color="rosebrick", mat="Brick", verts=16)
    p.cyl(4.7, 0.4, (0, 0, 22.2), color="rosebrick", mat="Brick", verts=16)
    for x in (-0.5, 0.5):
        p.box((0.12, 0.12, 16), (x, -3.5, 8), color="darkmetal", mat="Metal", flags=NOCOLLIDE)
    for k in range(10):
        p.box((1.1, 0.1, 0.1), (0, -3.5, 1.2 + k * 1.5), color="darkmetal", mat="Metal", flags=NOCOLLIDE)
    p.anchor("Top", (0, 0, 22.4))
    p.anchor("TopStand", (2.6, 0, 22.6))
    p.anchor("Base", (0, -7, 0))


def beach_hut(p, wall, roof):
    for x in (-3, 3):
        for y in (-2.5, 2.5):
            p.box((0.45, 0.45, 1.6), (x, y, 0.8), color="warmwood", mat="Wood")
    p.box((7, 6.4, 0.3), (0, -0.3, 1.65), color="warmwood", mat="WoodPlanks")
    p.box((6, 5, 4), (0, 0.5, 3.8), color=wall, mat="WoodPlanks")
    # cream corner boards, a door in a cream frame and a shuttered window
    for x in (-3.0, 3.0):
        p.box((0.35, 5.1, 4.0), (x, 0.5, 3.8), None, "cream", "WoodPlanks")
    p.box((1.9, 0.2, 3.0), (-1.2, -2.05, 3.3), None, "cream", "WoodPlanks", NOCOLLIDE)
    p.box((1.4, 0.25, 2.6), (-1.2, -2.08, 3.1), None, "warmwood", "WoodPlanks")
    p.box((1.6, 0.2, 1.4), (1.4, -2.05, 4.0), None, "cream", "WoodPlanks", NOCOLLIDE)
    for half in (-1, 1):
        p.box((0.6, 0.25, 1.1), (1.4 + half * 0.34, -2.08, 4.0), None, wall if wall != "dhabateal" else "cream",
              "WoodPlanks")
    # a little striped awning over the door
    style.awning(p, -2.4, 0.0, -2.0, -3.1, 5.2, 4.75, colors=(roof, "cream2"), stripes=3)
    p.hip_roof((0, 0.5, 5.8), 6, 5, pitch=28, thickness=0.3, overhang=0.6, color=roof, mat="WoodPlanks")
    for k in range(3):
        p.box((1.6, 0.6, 0.3), (-1.2, -3.3 - k * 0.6, 1.3 - k * 0.45), color="warmwood", mat="WoodPlanks")
    for x in (-3.3, 3.3):
        p.box((0.18, 6.0, 0.18), (x, -0.3, 2.6), color="cream", mat="Wood", flags=NOCOLLIDE)


@prop("BeachHutTeal", "desi", "A beach hut on short stilts")
def beach_hut_teal(p):
    beach_hut(p, "dhabateal", "red")


@prop("BeachHutPink", "desi", "A beach hut on short stilts")
def beach_hut_pink(p):
    beach_hut(p, "pink", "dhabateal")


@prop("BeachHutYellow", "desi", "A beach hut on short stilts")
def beach_hut_yellow(p):
    beach_hut(p, "yellow", "red")


def hull(p, length, width, depth, color, trim):
    p.box((width * 0.7, length * 0.86, 0.5), (0, 0, 0.25), color=color, mat="WoodPlanks")
    for side in (-1, 1):
        p.box((0.35, length * 0.9, depth), (side * width * 0.42, 0, depth / 2 + 0.1), (0, side * 14, 0),
              color=color, mat="WoodPlanks")
        p.box((0.12, length * 0.88, 0.35), (side * width * 0.48, 0, depth - 0.1), (0, side * 14, 0),
              color=trim, mat="SmoothPlastic", flags=NOCOLLIDE)
        p.box((0.35, length * 0.22, depth), (side * width * 0.2, -length * 0.5, depth / 2 + 0.1),
              (0, side * 10, side * -32), color=color, mat="WoodPlanks")
    p.box((width * 0.8, 0.35, depth), (0, length * 0.45, depth / 2 + 0.1), color=color, mat="WoodPlanks")


def hull_diamonds(p, length, width, depth, colors):
    """A row of diamonds painted along both sides of a hull, just under the trim."""
    for side in (-1, 1):
        x = side * (width * 0.42 + depth * 0.2)
        for i in range(-3, 4):
            p.box((0.12, depth * 0.3, depth * 0.3), (x, i * length * 0.1, depth * 0.62), (45, side * 14, 0),
                  colors[i % len(colors)], "SmoothPlastic", NOCOLLIDE)


@prop("FishingBoat", "desi", "A colourful fishing boat")
def fishing_boat(p):
    hull(p, 16, 5, 2.4, "blue", "yellow")
    hull_diamonds(p, 16, 5, 2.4, ("yellow", "red", "cream"))
    p.box((3.0, 4.0, 2.4), (0, 3.2, 2.6), color="cream", mat="WoodPlanks")
    p.box((3.1, 4.1, 0.4), (0, 3.2, 3.9), color="red", mat="WoodPlanks")
    p.box((3.05, 0.1, 0.8), (0, 1.15, 2.9), color="skyblue", mat="Glass", flags=NOCOLLIDE)
    p.rod((0, -2.5, 0.4), (0, -2.5, 10.5), 0.16, "warmwood", "Wood")
    p.rod((0, -2.5, 6.0), (0, 1.2, 6.0), 0.1, "warmwood", "Wood", NOCOLLIDE)
    p.rope((0, -2.5, 10.4), (0, 6.5, 2.6), 0.6, 0.05, "rope", 6)
    for i, color in enumerate(("red", "yellow", "green", "pink", "orange")):
        p.box((0.06, 0.5, 0.45), (0, -1.5 + i * 1.5, 9.6 - i * 1.4), (45, 0, 0), color, "Fabric", NOCOLLIDE)
    p.box((4.8, 0.2, 0.6), (0, -6.7, 1.9), (0, 0, 0), color="red", mat="SmoothPlastic", flags=NOCOLLIDE)


@prop("RowBoat", "desi", "A small rowing boat with oars")
def row_boat(p):
    hull(p, 8, 3.2, 1.4, "red", "cream")
    hull_diamonds(p, 8, 3.2, 1.4, ("cream", "yellow"))
    for y in (-1.2, 1.6):
        p.box((2.4, 0.6, 0.18), (0, y, 1.0), color="warmwood", mat="WoodPlanks")
    for side in (-1, 1):
        p.rod((side * 0.9, 0.2, 1.1), (side * 3.0, -1.5, 0.6), 0.08, "warmwood", "Wood", NOCOLLIDE)
        p.box((0.15, 1.0, 0.45), (side * 3.0, -1.6, 0.58), (0, 0, side * 50), color="warmwood", mat="Wood",
              flags=NOCOLLIDE)


@prop("NetRack", "desi", "Fishing nets drying on poles")
def net_rack(p):
    for x in (-3.2, 3.2):
        style.post(p, x, 0, 6.2, 0.35)
    p.box((7.2, 0.3, 0.3), (0, 0, 5.85), None, "warmwood", "Wood")
    p.box((6.2, 0.08, 3.8), (0, 0, 3.8), color="dhabateal", mat="Fabric", flags=NOCOLLIDE)
    p.box((6.2, 0.1, 0.2), (0, -0.02, 5.6), color="cream", mat="Fabric", flags=NOCOLLIDE)
    for k in range(7):
        p.ball(0.2, (-2.7 + k * 0.9, -0.05, 1.95), color="orange", mat="SmoothPlastic", flags=NOCOLLIDE,
               segments=8, rings=5)


@prop("DesertTent", "desi", "A striped tent with a rug and cushions")
def desert_tent(p):
    # a rug with a band of diamonds
    p.box((7, 7, 0.1), (0, 0, 0.05), color="red", mat="Fabric")
    p.box((5.6, 5.6, 0.11), (0, 0, 0.06), color="yellow", mat="Fabric", flags=NOCOLLIDE)
    for i in range(5):
        p.box((0.6, 0.6, 0.12), (-2.0 + i * 1.0, -2.4, 0.07), (0, 0, 45), ("dhabateal", "red")[i % 2], "Fabric",
              NOCOLLIDE)
    p.rod((0, 0, 0), (0, 0, 6.2), 0.16, "warmwood", "Wood")
    # four sides leaning in to the top of the pole, each made of bands that get
    # narrower towards the top, so the sides meet in a point and look striped
    slant = math.hypot(3.5, 6.2)
    tilt = math.degrees(math.atan2(3.5, 6.2))
    bands = 6
    for k, color in enumerate(("red", "orange", "red", "orange")):
        a = k * 90
        rad = math.radians(a)
        for j in range(bands):
            f = (j + 0.5) / bands
            r = 3.5 * (1 - f)
            width = 7.0 * (1 - f)
            p.box((width, 0.15, slant / bands + 0.05), (r * math.sin(rad), -r * math.cos(rad), 6.2 * f), (-tilt, 0, a),
                  color if j % 2 == 0 else "cream2", "Fabric")
    for k in range(3):
        p.box((1.2, 0.8, 0.5), (-1.6 + k * 1.6, 2.0, 0.3), color=("blue", "dhabateal", "purple")[k], mat="Fabric")
    p.ball(0.5, (2.2, -2.4, 0.5), color="clay", mat="Slate")


def parasol(p, pos, height, radius, colors, panels=8, droop=16):
    """A striped umbrella made of tilted panels round a pole (blocks, so the parts version keeps its shape)."""
    x, y, _ = pos
    p.rod((x, y, 0), (x, y, height + 0.3), 0.1, "warmwood", "Wood")
    width = 2 * radius * math.sin(math.pi / panels) + 0.1
    for k in range(panels):
        a = math.radians(k * 360 / panels)
        r = radius * 0.5
        cx, cy = x + math.sin(a) * r, y - math.cos(a) * r
        cz = height - math.sin(math.radians(droop)) * r
        p.box((width, radius, 0.14), (cx, cy, cz + (0.02 if k % 2 else 0)), (-droop, 0, k * 360 / panels),
              colors[k % len(colors)],
              "Fabric", NOCOLLIDE)
    p.ball(0.25, (x, y, height + 0.35), colors[0], "SmoothPlastic", NOCOLLIDE)


@prop("BeachUmbrella", "desi", "A beach umbrella with a deck chair")
def beach_umbrella(p):
    parasol(p, (0, 0, 0), 5.5, 3.4, ("pink", "cream2"), panels=12)
    # a deck chair: warm wood frame, striped canvas
    for k, color in enumerate(("blue", "cream2", "blue")):
        p.box((0.6, 3.2, 0.15), (1.2 + k * 0.6, -1.2, 0.9), (-20, 0, 0), color=color, mat="Fabric")
        p.box((0.6, 0.15, 1.6), (1.2 + k * 0.6, 0.4, 1.5), (-20, 0, 0), color=color, mat="Fabric")
    for x in (1.0, 2.6):
        p.rod((x, -2.6, 0), (x, 0.5, 2.0), 0.09, "warmwood", "Wood", NOCOLLIDE)


@prop("Lamppost", "desi", "A lamp post that lights up")
def lamppost(p):
    # a cream base, a dark pole and a lantern with a warm bulb
    p.box((1.0, 1.0, 0.7), (0, 0, 0.35), color="cream", mat="Concrete")
    p.box((0.8, 0.8, 0.2), (0, 0, 0.8), color="rosebrick", mat="Concrete")
    p.cyl(0.2, 6.8, (0, 0, 4.2), color="darkmetal", mat="Metal", verts=10)
    p.rod((0, 0, 7.0), (0, -1.2, 7.3), 0.1, "darkmetal", "Metal", NOCOLLIDE)
    p.box((0.9, 0.9, 1.0), (0, -1.3, 6.8), color="glass", mat="Glass", flags=GLASS | NOCOLLIDE)
    p.ball(0.36, (0, -1.3, 6.8), color="bulb", mat="Neon", flags=LIGHT | NOCOLLIDE)
    for dx in (-0.45, 0.45):
        for dy in (-0.45, 0.45):
            p.box((0.1, 0.1, 1.0), (dx, -1.3 + dy, 6.8), None, "darkmetal", "Metal", NOCOLLIDE)
    p.box((1.2, 1.2, 0.2), (0, -1.3, 7.4), None, "dhabateal", "Metal", NOCOLLIDE)
    p.box((0.6, 0.6, 0.25), (0, -1.3, 7.6), None, "dhabateal", "Metal", NOCOLLIDE)


@prop("KiteLine", "desi", "Bamboo poles with a string of patang kites")
def kite_line(p):
    for x in (-6, 6):
        p.rod((x, 0, 0), (x, 0, 10), 0.18, "bamboo", "Wood")
    points = p.rope((-6, 0, 9.8), (6, 0, 9.8), 1.2, 0.04, "white", 8)
    kites = (("red", "yellow"), ("yellow", "dhabateal"), ("green", "pink"), ("pink", "yellow"), ("blue", "orange"))
    for k, (outer, inner) in enumerate(kites):
        q = points[k + 2]
        # a patang in two colours with a little tail
        p.box((1.3, 0.06, 1.3), (q.x, q.y - 0.1, q.z - 0.9), (0, 45, 0), color=outer, mat="Fabric", flags=NOCOLLIDE)
        p.box((0.6, 0.08, 0.6), (q.x, q.y - 0.12, q.z - 0.9), (0, 45, 0), color=inner, mat="Fabric", flags=NOCOLLIDE)
        p.box((0.12, 0.05, 1.2), (q.x, q.y - 0.1, q.z - 2.1), None, inner, "Fabric", NOCOLLIDE)


@prop("Bench", "desi", "A wooden bench")
def bench(p):
    p.box((4.6, 1.3, 0.3), (0, 0, 1.3), color="warmwood", mat="WoodPlanks")
    p.box((4.6, 0.25, 1.0), (0, 0.6, 2.05), (-10, 0, 0), color="warmwood", mat="WoodPlanks")
    # legs and armrests set in from the ends, so no faces line up (they would flicker)
    for x in (-1.95, 1.95):
        p.box((0.4, 1.1, 1.2), (x, 0, 0.6), color="wood", mat="Wood")
        p.box((0.36, 1.4, 0.25), (x, -0.02, 1.95), color="wood", mat="Wood")
        p.box((0.26, 0.26, 0.55), (x, -0.42, 1.68), color="wood", mat="Wood")


@prop("CricketStumps", "desi", "Stumps, bails and a bat for a game of street cricket")
def cricket(p):
    for y in (0, -18):
        for x in (-0.35, 0, 0.35):
            p.rod((x, y, 0), (x, y, 2.2), 0.07, "cream", "Wood")
        p.box((0.9, 0.1, 0.1), (0, y, 2.27), color="warmwood", mat="Wood", flags=NOCOLLIDE)
    p.box((0.5, 0.15, 2.4), (1.4, 0.2, 1.1), (0, 0, 15), color="warmwood", mat="Wood", flags=NOCOLLIDE)
    p.rod((1.4, 0.2, 2.3), (1.45, 0.2, 3.1), 0.08, "black", "Fabric", NOCOLLIDE)
    p.ball(0.2, (0.6, -1.0, 0.2), color="red", mat="SmoothPlastic", flags=NOCOLLIDE)
    # the pitch, with white creases at both ends
    p.box((2.4, 19.4, 0.04), (0, -9, 0.02), color="sandlight", mat="Concrete", flags=NOCOLLIDE)
    for y in (-1.2, -16.8):
        p.box((2.4, 0.12, 0.05), (0, y, 0.04), color="white", mat="Concrete", flags=NOCOLLIDE)
