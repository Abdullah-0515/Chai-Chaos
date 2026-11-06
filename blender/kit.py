"""Low-poly modeling kit for the Chai Chaos props.

Every prop is built from simple pieces:

* box, cyl and ball map straight onto Roblox parts (Block, Cylinder, Ball),
  so the game can build the prop out of parts with no import at all.
* blob, cone and rock are "mesh only" pieces that look better as a mesh.
  As parts they turn into a simpler fallback shape (or are left out).

Units are studs. Each prop stands on the ground at the origin and faces -Y
(Blender's front view), which becomes -Z (the front) in Roblox.

Colours come from one small palette texture, so the whole set of meshes uses
a single texture in Roblox.
"""

import math
import struct
import zlib

import bmesh
import bpy
from mathutils import Euler, Matrix, Quaternion, Vector

# Piece flags (also used by Props.luau)
NOCOLLIDE = 1  # players walk through it (leaves, flowers, ropes)
KEEP = 2  # always a Roblox part, never merged into the mesh (neon, glass)
GLASS = 4  # see-through
LIGHT = 8  # gives off light (a PointLight in Roblox)
NOSHADOW = 16
PARTSONLY = 32  # only in the parts version (the mesh has a nicer shape instead)

# fmt: off
PALETTE = [
    ("wood", (150, 100, 60)), ("darkwood", (100, 65, 40)), ("lightwood", (190, 145, 95)), ("bamboo", (200, 175, 95)),
    ("thatch", (190, 155, 85)), ("straw", (225, 195, 110)), ("hay", (235, 205, 105)), ("mud", (165, 120, 80)),
    ("mudlight", (195, 155, 110)), ("brick", (175, 85, 60)), ("whitewash", (240, 235, 220)), ("plaster", (225, 205, 170)),
    ("sandstone", (215, 165, 105)), ("sandlight", (235, 205, 150)), ("stone", (150, 145, 140)), ("darkstone", (95, 92, 90)),
    ("slate", (85, 95, 110)), ("snow", (245, 248, 255)), ("ice", (190, 225, 245)), ("leaf", (70, 150, 60)),
    ("leafdark", (40, 105, 50)), ("leaflight", (120, 185, 75)), ("leafyellow", (175, 190, 70)), ("palmleaf", (60, 170, 80)),
    ("wheat", (226, 186, 72)), ("sarson", (250, 220, 40)), ("sugarcane", (110, 170, 70)), ("reed", (150, 140, 80)),
    ("cattail", (110, 70, 40)), ("flowerpink", (255, 110, 160)), ("floweryellow", (255, 215, 60)), ("flowerpurple", (165, 110, 240)),
    ("flowerwhite", (250, 250, 250)), ("red", (220, 50, 50)), ("orange", (250, 140, 40)), ("yellow", (255, 205, 40)),
    ("green", (40, 160, 80)), ("blue", (50, 110, 220)), ("teal", (30, 170, 170)), ("pink", (255, 105, 180)),
    ("purple", (140, 70, 200)), ("white", (250, 250, 250)), ("black", (35, 35, 40)), ("metal", (160, 165, 170)),
    ("darkmetal", (80, 85, 90)), ("tin", (175, 180, 185)), ("rust", (160, 90, 60)), ("glass", (180, 220, 255)),
    ("saltpink", (255, 170, 200)), ("saltwhite", (255, 230, 240)), ("crystal", (255, 120, 180)), ("water", (70, 150, 220)),
    ("rope", (200, 175, 130)), ("clay", (190, 105, 65)), ("claydark", (150, 80, 50)), ("gold", (240, 190, 60)),
    ("cream", (250, 235, 200)), ("skyblue", (120, 190, 255)), ("maroon", (130, 30, 50)), ("tyre", (40, 40, 45)),
    ("canvas", (225, 215, 185)), ("coconut", (120, 80, 45)), ("mango", (250, 180, 40)), ("grass", (95, 165, 70)),
]
# fmt: on
COLOR_INDEX = {name: i for i, (name, _) in enumerate(PALETTE)}
GRID = 8
CELL_PX = 32

# Blender (x, y, z) -> Roblox (-x, z, y): Z up becomes Y up, front (-Y) becomes front (-Z).
TO_ROBLOX = Matrix(((-1, 0, 0), (0, 0, 1), (0, 1, 0)))


def srgb_to_linear(c):
    c = c / 255
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def write_palette_png(path):
    """The palette texture: an 8x8 grid of solid colour cells."""
    size = GRID * CELL_PX
    rows = []
    for py in range(size):
        row = bytearray([0])
        for px in range(size):
            cell = (py // CELL_PX) * GRID + (px // CELL_PX)
            rgb = PALETTE[cell][1] if cell < len(PALETTE) else (255, 0, 255)
            row += bytes(rgb)
        rows.append(bytes(row))
    raw = b"".join(rows)

    def chunk(kind, data):
        body = kind + data
        return struct.pack(">I", len(data)) + body + struct.pack(">I", zlib.crc32(body) & 0xFFFFFFFF)

    png = b"\x89PNG\r\n\x1a\n"
    png += chunk(b"IHDR", struct.pack(">IIBBBBB", size, size, 8, 2, 0, 0, 0))
    png += chunk(b"IDAT", zlib.compress(raw, 9))
    png += chunk(b"IEND", b"")
    with open(path, "wb") as f:
        f.write(png)


def cell_uv(color):
    i = COLOR_INDEX[color]
    col, row = i % GRID, i // GRID
    # image rows go top to bottom, UV v goes bottom to top
    return ((col + 0.5) / GRID, 1 - (row + 0.5) / GRID)


_materials = {}


def palette_material(palette_path):
    if "palette" not in _materials:
        mat = bpy.data.materials.new("Palette")
        mat.use_nodes = True
        nodes = mat.node_tree.nodes
        bsdf = nodes.get("Principled BSDF")
        bsdf.inputs["Roughness"].default_value = 0.85
        tex = nodes.new("ShaderNodeTexImage")
        tex.image = bpy.data.images.load(palette_path)
        tex.interpolation = "Closest"
        mat.node_tree.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
        _materials["palette"] = mat
    return _materials["palette"]


def special_material(color, glow, glass):
    key = (color, glow, glass)
    if key not in _materials:
        r, g, b = (srgb_to_linear(c) for c in dict(PALETTE)[color])
        mat = bpy.data.materials.new(f"{color}{'Glow' if glow else ''}{'Glass' if glass else ''}")
        mat.use_nodes = True
        bsdf = mat.node_tree.nodes.get("Principled BSDF")
        bsdf.inputs["Base Color"].default_value = (r, g, b, 1)
        if glow:
            bsdf.inputs["Emission Color"].default_value = (r, g, b, 1)
            bsdf.inputs["Emission Strength"].default_value = 3.0
        if glass:
            bsdf.inputs["Alpha"].default_value = 0.45
        _materials[key] = mat
    return _materials[key]


def _rotation(rot):
    if rot is None:
        return Quaternion()
    if isinstance(rot, Quaternion):
        return rot
    return Euler([math.radians(a) for a in rot], "XYZ").to_quaternion()


def aim(direction):
    """A rotation that points a piece's Z axis along `direction`."""
    d = Vector(direction)
    if d.length < 1e-6:
        return Quaternion()
    return Vector((0, 0, 1)).rotation_difference(d.normalized())


REGISTRY = []


def prop(name, category, note=""):
    """Decorator: registers a function that models one prop. The function gets a fresh Prop."""

    def register(fn):
        REGISTRY.append((name, category, note, fn))
        return fn

    return register


class Prop:
    """One prop: a collection of pieces, anchors and some info for the game."""

    palette_path = None

    def __init__(self, name, category, note=""):
        self.name = name
        self.category = category
        self.note = note
        self.coll = bpy.data.collections.new(name)
        bpy.context.scene.collection.children.link(self.coll)
        self.pieces = []
        self.anchors = {}
        self._count = 0

    # ------------------------------------------------------------------ pieces
    def _finish(self, bm, pos, rot, color, mat, flags, shape, fallback=None, fallback_scale=(1, 1, 1)):
        self._count += 1
        name = f"{self.name}_{self._count:03d}"
        uv = bm.loops.layers.uv.verify()
        u, v = cell_uv(color)
        for face in bm.faces:
            face.smooth = False
            for loop in face.loops:
                loop[uv].uv = (u, v)
        mesh = bpy.data.meshes.new(name)
        bm.to_mesh(mesh)
        bm.free()
        obj = bpy.data.objects.new(name, mesh)
        obj.rotation_mode = "QUATERNION"
        obj.rotation_quaternion = _rotation(rot)
        obj.location = Vector(pos)
        glow = mat == "Neon"
        glass = bool(flags & GLASS)
        if glow or glass:
            flags |= KEEP
            obj.data.materials.append(special_material(color, glow, glass))
        else:
            obj.data.materials.append(palette_material(Prop.palette_path))
        obj["rbx_shape"] = shape
        obj["rbx_fallback"] = fallback or ""
        obj["rbx_fallback_scale"] = list(fallback_scale)
        obj["rbx_color"] = color
        obj["rbx_material"] = mat
        obj["rbx_flags"] = flags
        if flags & PARTSONLY:
            obj.hide_render = True  # the previews show the mesh version
        self.coll.objects.link(obj)
        self.pieces.append(obj)
        return obj

    def box(self, size, pos, rot=None, color="wood", mat="SmoothPlastic", flags=0):
        bm = bmesh.new()
        bmesh.ops.create_cube(bm, size=1.0)
        bmesh.ops.scale(bm, vec=Vector(size), verts=bm.verts)
        return self._finish(bm, pos, rot, color, mat, flags, "Block")

    def cyl(self, radius, length, pos, rot=None, color="wood", mat="SmoothPlastic", flags=0, verts=12):
        """A cylinder along its Z axis (upright unless rotated)."""
        bm = bmesh.new()
        bmesh.ops.create_cone(bm, cap_ends=True, segments=verts, radius1=radius, radius2=radius, depth=length)
        return self._finish(bm, pos, rot, color, mat, flags, "Cylinder")

    def ball(self, radius, pos, color="wood", mat="SmoothPlastic", flags=0, segments=10, rings=6):
        bm = bmesh.new()
        bmesh.ops.create_uvsphere(bm, u_segments=segments, v_segments=rings, radius=radius)
        return self._finish(bm, pos, None, color, mat, flags, "Ball")

    def cone(self, radius, length, pos, rot=None, color="leaf", mat="SmoothPlastic", flags=0, verts=8, top=0.0,
             fallback="Cylinder", fallback_scale=(0.7, 0.7, 1)):
        """A cone or frustum along Z. Mesh only; as parts it becomes a narrower cylinder."""
        bm = bmesh.new()
        bmesh.ops.create_cone(bm, cap_ends=True, segments=verts, radius1=radius, radius2=top, depth=length)
        return self._finish(bm, pos, rot, color, mat, flags, "Mesh", fallback, fallback_scale)

    def blob(self, radius, pos, scale=(1, 1, 1), color="leaf", mat="Grass", flags=NOCOLLIDE, seed=0, jitter=0.18,
             subdiv=1, fallback=None, rot=None):
        """A lumpy low-poly ball (tree canopies, bushes, rocks). Mesh only."""
        bm = bmesh.new()
        bmesh.ops.create_icosphere(bm, subdivisions=subdiv, radius=radius)
        state = seed * 9301 + 49297
        for vert in bm.verts:
            state = (state * 1103515245 + 12345) % 2147483648
            k = 1 + jitter * ((state / 2147483648) * 2 - 1)
            vert.co = Vector((vert.co.x * scale[0] * k, vert.co.y * scale[1] * k, vert.co.z * scale[2] * k))
        if fallback is None:
            flat = scale[2] < 0.75 * min(scale[0], scale[1])
            tall = scale[2] > 1.4 * max(scale[0], scale[1])
            fallback = "Disc" if flat else "Cylinder" if tall else "Ball"
        return self._finish(bm, pos, rot, color, mat, flags, "Mesh", fallback)

    def rock(self, radius, pos, scale=(1, 1, 0.75), color="stone", seed=0, flags=0, mat="Slate"):
        return self.blob(radius, pos, scale, color, mat, flags, seed, jitter=0.3, subdiv=1, fallback="Ball")

    def poly(self, verts, faces, pos, color, mat="SmoothPlastic", flags=0, rot=None):
        """Any closed shape from vertices and faces. Mesh only (no parts version)."""
        bm = bmesh.new()
        made = [bm.verts.new(v) for v in verts]
        for f in faces:
            bm.faces.new([made[i] for i in f])
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
        return self._finish(bm, pos, rot, color, mat, flags, "Mesh", "None")

    def detail(self, size, pos, rot=None, color="leaf", mat="SmoothPlastic", flags=NOCOLLIDE):
        """A small box that only exists in the mesh (left out of the parts version)."""
        bm = bmesh.new()
        bmesh.ops.create_cube(bm, size=1.0)
        bmesh.ops.scale(bm, vec=Vector(size), verts=bm.verts)
        return self._finish(bm, pos, rot, color, mat, flags, "Mesh", "None")

    # ------------------------------------------------------------ helpers
    def rod(self, p0, p1, radius, color="wood", mat="Wood", flags=0, verts=8):
        """A cylinder from p0 to p1."""
        p0, p1 = Vector(p0), Vector(p1)
        return self.cyl(radius, (p1 - p0).length, (p0 + p1) / 2, aim(p1 - p0), color, mat, flags, verts)

    def beam(self, p0, p1, width, height, color="wood", mat="Wood", flags=0):
        """A plank from p0 to p1: its length along the line, its width kept level."""
        p0, p1 = Vector(p0), Vector(p1)
        d = p1 - p0
        yaw = math.atan2(-d.x, d.y)
        pitch = math.atan2(d.z, math.hypot(d.x, d.y))
        rot = (math.degrees(pitch), 0, math.degrees(yaw))
        return self.box((width, d.length, height), (p0 + p1) / 2, rot, color, mat, flags)

    def rope(self, p0, p1, sag, radius=0.12, color="rope", segments=8, flags=NOCOLLIDE):
        """A hanging rope from p0 to p1 that sags in the middle. Returns the points."""
        p0, p1 = Vector(p0), Vector(p1)
        points = []
        for i in range(segments + 1):
            t = i / segments
            p = p0.lerp(p1, t)
            p.z -= sag * 4 * t * (1 - t)
            points.append(p)
        for a, b in zip(points, points[1:]):
            self.rod(a, b, radius, color, "Fabric", flags, verts=6)
        return points

    def ring(self, radius, height, pos, count, size, color="wood", mat="Wood", flags=0, start=0.0):
        """`count` boxes around a vertical ring (crenellations, fence posts)."""
        for i in range(count):
            a = start + i * 2 * math.pi / count
            p = (pos[0] + math.cos(a) * radius, pos[1] + math.sin(a) * radius, pos[2] + height)
            self.box(size, p, (0, 0, math.degrees(a)), color, mat, flags)

    def hip_roof(self, center, width, depth, pitch=30, thickness=0.4, overhang=0.8, color="thatch",
                 mat="Fabric", flags=0):
        """A hip roof over a width x depth building. `center` is the middle of the eaves.
        The mesh is a proper hip roof; the parts version is two slabs with stepped ends."""
        cx, cy, z = center
        t = math.radians(pitch)
        hw, hd = width / 2 + overhang, depth / 2 + overhang
        rise = hd * math.tan(t)
        ridge = max(hw - hd, 0.0)
        if ridge > 1e-3:
            verts = [(-hw, -hd, 0), (hw, -hd, 0), (hw, hd, 0), (-hw, hd, 0), (-ridge, 0, rise), (ridge, 0, rise)]
            faces = [(0, 3, 2, 1), (0, 1, 5, 4), (2, 3, 4, 5), (1, 2, 5), (3, 0, 4)]
        else:
            verts = [(-hw, -hd, 0), (hw, -hd, 0), (hw, hd, 0), (-hw, hd, 0), (0, 0, rise)]
            faces = [(0, 3, 2, 1), (0, 1, 4), (1, 2, 4), (2, 3, 4), (3, 0, 4)]
        self.poly(verts, faces, (cx, cy, z), color, mat, flags | NOCOLLIDE)
        # parts version: a gable roof, closed with stepped ends
        length = hd / math.cos(t)
        for sign in (-1, 1):
            self.box((2 * hw, length, thickness), (cx, cy + sign * hd / 2, z + rise / 2), (-sign * pitch, 0, 0),
                     color, mat, flags | PARTSONLY)
            for k in range(3):
                h = rise / 3
                d = 2 * hd * (1 - (k + 0.5) / 3) * 0.95
                self.box((0.3, d, h), (cx + sign * (width / 2), cy, z + h * (k + 0.5) - 0.05), None, color, mat,
                         flags | PARTSONLY | NOCOLLIDE)
        return z + rise

    def anchor(self, name, pos):
        """A named point the game can use (where a chest sits, where you climb from)."""
        self.anchors[name] = Vector(pos)


# ---------------------------------------------------------------------------
# Exporting
# ---------------------------------------------------------------------------
def _roblox_vec(v):
    return TO_ROBLOX @ Vector(v)


def _local_bounds(obj):
    xs = [v.co.x for v in obj.data.vertices]
    ys = [v.co.y for v in obj.data.vertices]
    zs = [v.co.z for v in obj.data.vertices]
    lo = Vector((min(xs), min(ys), min(zs)))
    hi = Vector((max(xs), max(ys), max(zs)))
    return (lo + hi) / 2, hi - lo


def _rotation_matrix(obj):
    return obj.rotation_quaternion.to_matrix()


def part_spec(obj):
    """The Roblox part for one piece, or None if it has no parts version."""
    shape = obj["rbx_shape"]
    fallback = obj["rbx_fallback"]
    if shape == "Mesh":
        if fallback in ("", "None"):
            return None
        shape = fallback
    center, size = _local_bounds(obj)
    fs = Vector(obj["rbx_fallback_scale"])
    size = Vector((size.x * fs.x, size.y * fs.y, size.z * fs.z))
    rot_b = _rotation_matrix(obj)
    world = obj.location + rot_b @ center
    rot_r = TO_ROBLOX @ rot_b @ TO_ROBLOX.transposed()
    if shape == "Block":
        rsize = (size.x, size.z, size.y)
    elif shape in ("Cylinder", "Disc"):
        # Roblox cylinders run along their X axis; ours run along Z
        rot_r = rot_r @ Matrix(((0, -1, 0), (1, 0, 0), (0, 0, 1)))
        diameter = max(size.x, size.y)
        rsize = (size.z, diameter, diameter)
        shape = "Cylinder"
    elif shape == "Ball":
        d = max(size)
        rsize = (d, d, d)
    else:
        raise ValueError(f"unknown shape {shape} on {obj.name}")
    q = rot_r.to_quaternion()
    return {
        "shape": shape[0],  # B, C or L (ball)
        "pos": tuple(_roblox_vec(world)),
        "size": rsize,
        "quat": (q.x, q.y, q.z, q.w),
        "color": COLOR_INDEX[obj["rbx_color"]],
        "material": obj["rbx_material"],
        "flags": obj["rbx_flags"],
    }


def joined_mesh(prop):
    """Joins every non-KEEP piece of a prop into one mesh object (for the FBX).
    Returns (object, roblox_center, roblox_size, triangles) or None."""
    pieces = [o for o in prop.pieces if not (o["rbx_flags"] & (KEEP | PARTSONLY))]
    if not pieces:
        return None
    bm = bmesh.new()
    for obj in pieces:
        temp = bmesh.new()
        temp.from_mesh(obj.data)
        matrix = Matrix.Translation(obj.location) @ obj.rotation_quaternion.to_matrix().to_4x4()
        bmesh.ops.transform(temp, matrix=matrix, verts=temp.verts)
        mesh = bpy.data.meshes.new("tmp")
        temp.to_mesh(mesh)
        temp.free()
        bm.from_mesh(mesh)
        bpy.data.meshes.remove(mesh)
    bmesh.ops.triangulate(bm, faces=bm.faces)
    triangles = len(bm.faces)
    mesh = bpy.data.meshes.new(prop.name)
    bm.to_mesh(mesh)
    bm.free()
    mesh.materials.append(palette_material(Prop.palette_path))
    obj = bpy.data.objects.new(prop.name, mesh)
    xs = [v.co.x for v in mesh.vertices]
    ys = [v.co.y for v in mesh.vertices]
    zs = [v.co.z for v in mesh.vertices]
    lo = Vector((min(xs), min(ys), min(zs)))
    hi = Vector((max(xs), max(ys), max(zs)))
    center_b = (lo + hi) / 2
    size_b = hi - lo
    return obj, tuple(_roblox_vec(center_b)), (size_b.x, size_b.z, size_b.y), triangles


def bounds_roblox(prop):
    """The whole prop's size and centre in Roblox axes (from its parts)."""
    lo = Vector((1e9, 1e9, 1e9))
    hi = Vector((-1e9, -1e9, -1e9))
    for obj in prop.pieces:
        m = Matrix.Translation(obj.location) @ obj.rotation_quaternion.to_matrix().to_4x4()
        for v in obj.data.vertices:
            w = m @ v.co
            lo = Vector((min(lo.x, w.x), min(lo.y, w.y), min(lo.z, w.z)))
            hi = Vector((max(hi.x, w.x), max(hi.y, w.y), max(hi.z, w.z)))
    size_b = hi - lo
    return tuple(_roblox_vec((lo + hi) / 2)), (size_b.x, size_b.z, size_b.y)
