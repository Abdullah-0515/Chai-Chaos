"""The drivable vehicles: motorbike, rickshaw, Pili Taxi and Phool Patti truck.

They face -Y like everything else. Anchors tell the game where things go:
  Seat          where the driver sits (the top of the seat)
  Seat1, Seat2  where friends who ride along sit
  Boot1...      where eggs ride in the boot
Panels with the PAINT flag change colour with Robux paint jobs. The game always
builds vehicles from parts, so they can be painted.
"""

from kit import GLASS, LIGHT, NOCOLLIDE, PAINT, prop

D = NOCOLLIDE  # vehicles never collide (the driver's character does)
P = NOCOLLIDE | PAINT


def wheel(p, radius, pos, width=0.5, color="tyre", hub="metal"):
    p.cyl(radius, width, pos, (0, 90, 0), color, "SmoothPlastic", D, verts=12)
    p.cyl(radius * 0.45, width + 0.08, pos, (0, 90, 0), hub, "Metal", D, verts=8)


def headlight(p, pos, radius=0.32):
    p.cyl(radius, 0.12, pos, (90, 0, 0), "bulb", "Neon", D, verts=10)


@prop("VehicleMotorbike", "vehicle", "A red motorbike with a rack for one egg")
def motorbike(p):
    wheel(p, 1.0, (0, -2.3, 1.0), 0.45)
    wheel(p, 1.0, (0, 2.1, 1.0), 0.5)
    p.rod((0, -2.3, 1.0), (0, -1.6, 3.0), 0.12, "metal", "Metal", D)  # front fork
    p.box((1.1, 2.6, 1.1), (0, -0.2, 2.0), None, "red", "SmoothPlastic", P)  # the tank and body
    p.box((0.9, 1.4, 0.7), (0, -0.9, 2.75), None, "red", "SmoothPlastic", P)
    p.box((0.95, 2.2, 0.35), (0, 0.8, 2.75), None, "black", "Fabric", D)  # seat
    p.box((0.8, 1.6, 0.6), (0, 0.3, 1.2), None, "darkmetal", "Metal", D)  # engine
    p.rod((0.45, 0.6, 1.0), (0.45, 2.6, 1.4), 0.14, "metal", "Metal", D)  # exhaust
    p.box((1.2, 0.3, 0.6), (0, -2.35, 2.05), (20, 0, 0), "red", "SmoothPlastic", P)  # mudguard
    p.rod((-0.9, -1.7, 3.3), (0.9, -1.7, 3.3), 0.08, "black", "Metal", D)  # handlebar
    headlight(p, (0, -1.95, 3.0), 0.28)
    p.box((1.6, 1.6, 0.2), (0, 2.2, 2.4), None, "darkmetal", "Metal", D)  # rack
    p.anchor("Seat", (0, 0.9, 2.95))
    p.anchor("Seat1", (0, 1.9, 2.95))
    p.anchor("Boot1", (0, 2.4, 2.5))


@prop("VehicleRickshaw", "vehicle", "A green-and-yellow auto rickshaw with room for 2 eggs and 2 friends")
def rickshaw(p):
    p.box((3.8, 5.4, 0.5), (0, 0.6, 1.3), None, "rickshawgreen", "SmoothPlastic", P)
    p.box((1.6, 1.6, 2.4), (0, -2.9, 2.6), None, "rickshawgreen", "SmoothPlastic", P)  # the nose
    p.box((1.5, 0.15, 1.1), (0, -3.72, 3.5), None, "skyblue", "Glass", D | GLASS)
    p.rod((-1.0, -2.6, 3.9), (1.0, -2.6, 3.9), 0.1, "black", "Metal", D)
    headlight(p, (0, -3.72, 2.4))
    p.box((1.1, 1.2, 0.4), (0, -1.0, 2.2), None, "black", "Fabric", D)  # driver's seat
    p.box((3.4, 1.6, 0.5), (0, 2.0, 2.1), None, "black", "Fabric", D)  # back seat
    p.box((3.4, 0.4, 1.6), (0, 2.85, 2.9), None, "black", "Fabric", D)
    p.box((3.8, 0.3, 2.0), (0, 3.3, 2.6), None, "yellow", "SmoothPlastic", P)
    p.box((4.2, 5.6, 0.3), (0, 0.4, 5.5), None, "black", "Fabric", D)  # canopy
    for x in (-1.9, 1.9):
        for y in (-2.2, 3.2):
            p.rod((x, y, 1.6), (x, y, 5.4), 0.09, "black", "Metal", D)
        p.box((0.12, 4.4, 0.4), (x * 1.04, 0.7, 1.9), None, "yellow", "SmoothPlastic", P)
    for i, color in enumerate(("red", "pink", "skyblue", "gold")):  # tassels on the canopy
        p.ball(0.16, (-1.5 + i, -2.25, 5.25), color, "SmoothPlastic", D, segments=6, rings=4)
    wheel(p, 0.85, (0, -3.2, 0.85), 0.4)
    wheel(p, 0.85, (-1.95, 2.2, 0.85), 0.4)
    wheel(p, 0.85, (1.95, 2.2, 0.85), 0.4)
    p.anchor("Seat", (0, -1.0, 2.4))
    p.anchor("Seat1", (-0.9, 2.0, 2.35))
    p.anchor("Seat2", (0.9, 2.0, 2.35))
    p.anchor("Boot1", (-0.9, 3.9, 2.0))
    p.anchor("Boot2", (0.9, 3.9, 2.0))
    p.anchor("Boot3", (0, 3.9, 3.6))
    p.anchor("Boot4", (0, 0.7, 6.4))
    p.anchor("Boot5", (-1.2, 0.7, 6.4))


@prop("VehiclePiliTaxi", "vehicle", "A yellow-and-black city taxi with room for 3 eggs and 3 friends")
def taxi(p):
    p.box((4.6, 8.6, 1.4), (0, 0, 1.6), None, "yellow", "SmoothPlastic", P)  # body
    p.box((4.2, 4.4, 1.6), (0, 0.5, 3.1), None, "yellow", "SmoothPlastic", P)  # cabin
    p.box((4.0, 4.6, 0.12), (0, 0.5, 3.95), None, "black", "SmoothPlastic", D)  # black roof stripe
    p.box((3.9, 0.12, 1.2), (0, -1.75, 3.15), (-20, 0, 0), "skyblue", "Glass", D | GLASS)  # windscreen
    p.box((3.9, 0.12, 1.1), (0, 2.75, 3.15), (18, 0, 0), "skyblue", "Glass", D | GLASS)
    for x in (-2.12, 2.12):
        p.box((0.12, 3.6, 1.0), (x, 0.5, 3.2), None, "skyblue", "Glass", D | GLASS)
        p.box((0.1, 8.2, 0.3), (x * 1.03, 0, 1.75), None, "black", "SmoothPlastic", D)  # chequered belt
    p.box((1.6, 0.6, 0.5), (0, 0.5, 4.2), None, "white", "SmoothPlastic", D)  # TAXI sign
    p.box((1.4, 0.65, 0.3), (0, 0.5, 4.2), None, "yellow", "Neon", D | LIGHT)
    for x in (-1.5, 1.5):
        headlight(p, (x, -4.32, 1.9))
        p.box((0.7, 0.1, 0.35), (x, 4.32, 1.9), None, "red", "Neon", D)
    p.box((4.7, 0.4, 0.5), (0, -4.35, 1.1), None, "metal", "Metal", D)  # bumpers
    p.box((4.7, 0.4, 0.5), (0, 4.35, 1.1), None, "metal", "Metal", D)
    p.box((1.3, 1.2, 0.5), (-0.9, -0.4, 2.55), None, "black", "Fabric", D)  # seats
    p.box((3.4, 1.4, 0.5), (0, 1.6, 2.55), None, "black", "Fabric", D)
    for y in (-2.8, 2.8):
        for x in (-2.15, 2.15):
            wheel(p, 0.9, (x, y, 0.9), 0.55)
    p.anchor("Seat", (-0.9, -0.4, 2.8))
    p.anchor("Seat1", (0.9, -0.4, 2.8))
    p.anchor("Seat2", (-1.0, 1.6, 2.8))
    p.anchor("Seat3", (1.0, 1.6, 2.8))
    for i, x in enumerate((-1.3, 0, 1.3)):
        p.anchor(f"Boot{i + 1}", (x, 3.6, 2.5))
    for i, x in enumerate((-1.3, 0, 1.3)):
        p.anchor(f"Boot{i + 4}", (x, 0.5, 4.9))


@prop("VehiclePhoolPattiTruck", "vehicle", "A painted truck with a wooden crown, room for 6 eggs and a friend")
def truck(p):
    p.box((5.4, 14, 0.7), (0, 0.8, 1.6), None, "darkmetal", "Metal", D)  # chassis
    p.box((4.8, 2.4, 2.0), (0, -6.0, 2.8), None, "green", "SmoothPlastic", P)  # hood
    p.box((5.8, 3.4, 3.6), (0, -3.2, 3.7), None, "yellow", "SmoothPlastic", P)  # cab
    p.box((5.0, 0.15, 1.4), (0, -4.93, 4.6), None, "skyblue", "Glass", D | GLASS)
    for x in (-2.95, 2.95):
        p.box((0.15, 1.6, 1.2), (x, -3.4, 4.5), None, "skyblue", "Glass", D | GLASS)
    p.box((5.4, 0.5, 0.9), (0, -7.3, 2.0), None, "red", "Metal", P)
    for x in (-1.8, 1.8):
        headlight(p, (x, -7.25, 2.9), 0.4)
    # the wooden crown over the cab
    p.box((6.2, 0.6, 2.8), (0, -4.4, 7.0), None, "red", "WoodPlanks", P)
    p.box((5.2, 0.65, 1.8), (0, -4.45, 7.2), None, "green", "WoodPlanks", P)
    p.box((6.8, 0.7, 0.4), (0, -4.4, 8.5), None, "gold", "Metal", D)
    for x, color in zip((-2.6, -1.3, 0, 1.3, 2.6), ("pink", "blue", "pink", "blue", "pink")):
        p.ball(0.3, (x, -4.75, 8.8), color, "SmoothPlastic", D, segments=6, rings=4)
    # the cargo bed with painted sides
    p.box((6.2, 8.4, 0.4), (0, 3.6, 2.15), None, "wood", "WoodPlanks", D)
    stripes = ("red", "yellow", "green", "blue")
    for x in (-3.0, 3.0):
        p.box((0.25, 8.4, 2.6), (x, 3.6, 3.6), None, "orange", "WoodPlanks", P)
        for k, color in enumerate(stripes):
            p.box((0.1, 8.0, 0.45), (x * 1.03, 3.6, 2.7 + k * 0.6), None, color, "SmoothPlastic", D)
    p.box((6.2, 0.25, 2.6), (0, 7.7, 3.6), None, "blue", "WoodPlanks", P)
    for k in range(10):  # bells along the back
        p.ball(0.18, (-2.7 + k * 0.6, 7.95, 2.2), "gold", "Metal", D, segments=6, rings=4)
    p.box((1.3, 1.2, 0.5), (-1.3, -2.8, 2.6), None, "black", "Fabric", D)  # seats
    p.box((1.3, 1.2, 0.5), (1.3, -2.8, 2.6), None, "black", "Fabric", D)
    for y in (-5.8, 4.0, 6.4):
        for x in (-2.6, 2.6):
            wheel(p, 1.2, (x, y, 1.2), 0.7)
    p.anchor("Seat", (-1.3, -2.8, 2.85))
    p.anchor("Seat1", (1.3, -2.8, 2.85))
    for i in range(9):
        p.anchor(f"Boot{i + 1}", (-1.8 + (i % 3) * 1.8, 1.4 + (i // 3) * 2.4, 3.2))
