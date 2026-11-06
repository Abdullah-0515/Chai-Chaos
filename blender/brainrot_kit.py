"""Helpers for the chunky, cute brainrot characters: big eyes, smiles,
moustaches, stubby arms and legs, crowns and caps.

Characters face -Y (front) and stand on z = 0. Sizes are in studs.
"""

import math

from mathutils import Euler, Quaternion, Vector

from kit import EYE, NOCOLLIDE, _rotation

D = NOCOLLIDE  # brainrots never collide, so every piece can skip collisions


class Frame:
    """A local coordinate frame: build part of a character upright, then tilt it."""

    def __init__(self, origin=(0, 0, 0), rot=(0, 0, 0)):
        self.o = Vector(origin)
        self.q = Euler([math.radians(a) for a in rot], "XYZ").to_quaternion()

    def p(self, x, y, z):
        return tuple(self.o + self.q @ Vector((x, y, z)))

    def r(self, rot=None):
        return self.q @ _rotation(rot)


WORLD = Frame()


def eyes(p, x, y, z, spacing, r, pupil="black", look=(0.0, 0.0), f=WORLD, single=False):
    """Two big cartoon eyes on a face whose front surface is at y."""
    for side in ((0,) if single else (-1, 1)):
        ex = x + side * spacing / 2
        p.ball(r, f.p(ex, y, z), "white", "SmoothPlastic", D | EYE, segments=12, rings=8)
        p.ball(r * 0.56, f.p(ex + look[0] * r * 0.25, y - r * 0.62, z + look[1] * r * 0.25), pupil, "SmoothPlastic",
               D | EYE, segments=10, rings=6)
        p.ball(r * 0.2, f.p(ex - r * 0.2, y - r * 1.08, z + r * 0.28), "white", "SmoothPlastic", D | EYE,
               segments=6, rings=4)


def brows(p, x, y, z, spacing, r, color="black", tilt=18, f=WORLD):
    """Eyebrows above the eyes. Positive tilt looks determined, negative looks worried."""
    for side in (-1, 1):
        p.box((r * 1.3, 0.12, r * 0.28), f.p(x + side * spacing / 2, y - r * 0.6, z + r * 1.25),
              f.r((0, side * -tilt, 0)), color, "SmoothPlastic", D)


def smile(p, x, y, z, w, color="black", f=WORLD, open_mouth=False, tongue="pink"):
    """A smile on a face whose front surface is at y."""
    if open_mouth:
        p.ball(w * 0.32, f.p(x, y + w * 0.12, z), color, "SmoothPlastic", D, segments=10, rings=6)
        p.ball(w * 0.16, f.p(x, y - w * 0.12, z - w * 0.12), tongue, "SmoothPlastic", D, segments=8, rings=5)
        return
    t = w * 0.12
    p.box((w * 0.45, t, t), f.p(x, y, z), f.r(), color, "SmoothPlastic", D)
    for side in (-1, 1):
        p.box((w * 0.35, t, t), f.p(x + side * w * 0.36, y, z + w * 0.08), f.r((0, side * -28, 0)), color,
              "SmoothPlastic", D)


def blush(p, x, y, z, spacing, r=0.22, color="blush", f=WORLD):
    for side in (-1, 1):
        p.cyl(r, 0.05, f.p(x + side * spacing / 2, y, z), f.r((90, 0, 0)), color, "SmoothPlastic", D, verts=10)


def moustache(p, x, y, z, w, color="black", f=WORLD, curl=True, thick=0.28):
    """A curly moustache centred on (x, y, z), w wide."""
    for side in (-1, 1):
        p.box((w * 0.5, thick, thick), f.p(x + side * w * 0.24, y, z - thick * 0.2), f.r((0, side * 14, 0)), color,
              "SmoothPlastic", D)
        if curl:
            p.ball(thick * 0.75, f.p(x + side * w * 0.5, y, z + thick * 0.35), color, "SmoothPlastic", D,
                   segments=8, rings=5)


def leg(p, x, y, height, r, color, foot=None, foot_len=None, f=WORLD):
    """A stubby leg from the ground up, with a rounded foot."""
    p.cyl(r, height, f.p(x, y, height / 2), f.r(), color, "SmoothPlastic", D, verts=10)
    fl = foot_len or r * 2.6
    p.box((r * 2.1, fl, r * 1.1), f.p(x, y - fl * 0.25, r * 0.55), f.r(), foot or color, "SmoothPlastic", D)


def arm(p, a, b, r, color, hand=None, hand_r=None, f=WORLD):
    """An arm from shoulder a to hand b (points in the frame)."""
    pa, pb = f.p(*a), f.p(*b)
    p.rod(pa, pb, r, color, "SmoothPlastic", D, verts=8)
    p.ball(hand_r or r * 1.4, pb, hand or color, "SmoothPlastic", D, segments=8, rings=5)


def crown(p, x, y, z, r, color="gold", gem="red", points=5, f=WORLD):
    """A little crown standing on (x, y, z)."""
    p.cyl(r, r * 0.55, f.p(x, y, z + r * 0.27), f.r(), color, "Metal", D, verts=12)
    for i in range(points):
        a = i * 2 * math.pi / points + math.pi / 2
        px, py = x + math.cos(a) * r * 0.88, y + math.sin(a) * r * 0.88
        p.box((r * 0.42, r * 0.42, r * 0.42), f.p(px, py, z + r * 0.7), f.r((45, 45, math.degrees(a))), color,
              "Metal", D)
    p.ball(r * 0.22, f.p(x, y - r * 0.95, z + r * 0.3), gem, "SmoothPlastic", D, segments=8, rings=5)


def cap(p, x, y, z, r, color, brim=None, backwards=False, f=WORLD):
    """A baseball-style cap sitting on top of a head at height z."""
    p.ball(r, f.p(x, y, z), color, "Fabric", D, segments=12, rings=6)
    p.box((r * 1.6, r * 0.6, r * 0.5), f.p(x, y, z - r * 0.45), f.r(), color, "Fabric", D)  # fills the dome's base
    by = y + (r * 1.1 if backwards else -r * 1.1)
    p.box((r * 1.4, r * 1.2, r * 0.14), f.p(x, by, z - r * 0.6), f.r(), brim or color, "Fabric", D)


def puffs(p, points, r, color="steam", seed=0, f=WORLD):
    """Little puffs of steam or smoke."""
    for i, pt in enumerate(points):
        p.blob(r * (1 - i * 0.12), f.p(*pt), (1, 1, 0.9), color, "SmoothPlastic", D, seed=seed + i, jitter=0.2,
               fallback="Ball")


def wing(p, root, side, length, width, color, f=WORLD, angle=30, flags=D, mat="SmoothPlastic", style="feather"):
    """A wing sticking out sideways and up from root: fanned feathers, or a bat wing for dragons."""
    x, y, z = root
    if style == "bat":
        for k, (lf, wf) in enumerate(((1.0, 1.0), (0.7, 0.75))):
            p.box((length * lf, width * wf * 0.35, width * wf),
                  f.p(x + side * length * lf / 2, y + k * 0.15, z + k * 0.25), f.r((0, side * -angle, 0)), color, mat,
                  flags)
        return
    for k in range(4):  # each feather a little shorter and pointing a little lower
        tilt = angle - k * 17
        lf = 1.0 - k * 0.16
        t = math.radians(tilt)
        L = length * lf
        p.box((L, 0.12, width * 0.36), f.p(x + side * math.cos(t) * L / 2, y + k * 0.05, z + math.sin(t) * L / 2),
              f.r((0, side * -tilt, 0)), color, mat, flags)
    p.ball(width * 0.3, f.p(x, y, z), color, mat, flags, segments=8, rings=5)


def rope_ring(p, x, y, z, r, color="rope", count=10, size=0.14, f=WORLD):
    """A ring of little beads (garlands, rope coils)."""
    for i in range(count):
        a = i * 2 * math.pi / count
        p.ball(size, f.p(x + math.cos(a) * r, y + math.sin(a) * r, z), color, "SmoothPlastic", D, segments=6,
               rings=4)
