"""Renders the whole world from above, exactly as the game builds it.

    tests/run.sh worlddump > /tmp/world.txt
    python blender/world_preview.py /tmp/world.txt

writes docs/world-from-above.jpg (the whole map, straight down, with the zone
names on it) and docs/town-from-above.jpg (a bird's-eye view of the Chowk, the
havelis and the bazaar).

tests/worlddump.luau runs the real game scripts on the test engine and prints
every visible part (props are built from parts, as in the game without
imported meshes) and every terrain fill. This script turns the parts into one
mesh, paints the terrain onto the ground in Roblox's default terrain colours,
raises the hills and renders it with Cycles.
"""

import math
import os
import shutil
import subprocess
import sys

import bpy
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
DOCS = os.path.join(ROOT, "docs")

GROUND_Y = 1.0
EXTENT = 800  # studs from the middle to the edge of the picture
PX_PER_STUD = 2

# Roblox's default terrain colours (nothing in the game changes them)
TERRAIN = {
    "Asphalt": (115, 123, 107), "Basalt": (30, 30, 37), "Brick": (138, 86, 62), "Cobblestone": (132, 123, 90),
    "Concrete": (127, 102, 63), "CrackedLava": (232, 156, 74), "Glacier": (101, 176, 234),
    "Grass": (106, 127, 63), "Ground": (102, 92, 59), "Ice": (129, 194, 224), "LeafyGrass": (115, 132, 74),
    "Limestone": (206, 173, 148), "Mud": (58, 46, 36), "Pavement": (148, 148, 140), "Rock": (102, 108, 111),
    "Salt": (198, 189, 181), "Sand": (143, 126, 95), "Sandstone": (137, 90, 71), "Slate": (63, 127, 107),
    "Snow": (195, 199, 218), "WoodPlanks": (139, 109, 79), "Water": (38, 110, 132),
}


def srgb_to_linear(c):
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def to_blender(x, y, z):
    """Roblox (x, y up, z) to Blender (x, y, z up)."""
    return (x, -z, y)


def read(path):
    parts, fills, labels = [], [], []
    with open(path) as f:
        for line in f:
            bits = line.split()
            if not bits:
                continue
            if bits[0] == "P" and bits[1] != "Terrain":
                nums = [float(v) for v in bits[3:19]]
                parts.append((bits[2], nums, bits[19]))
            elif bits[0] == "T":
                fills.append((bits[1], bits[2], [float(v) for v in bits[3:11]]))
            elif bits[0] == "L":
                labels.append((float(bits[1]), float(bits[2]), int(bits[3]), " ".join(bits[4:])))
    return parts, fills, labels


# ------------------------------------------------------------------ terrain
def ground_image(fills):
    """The terrain seen from above, as an image the size of the picture."""
    size = 2 * EXTENT * PX_PER_STUD
    img = np.zeros((size, size, 3), dtype=np.float32)
    img[:] = np.array(TERRAIN["Grass"]) / 255

    def to_px(v):
        return int(round((v + EXTENT) * PX_PER_STUD))

    yy, xx = np.mgrid[0:size, 0:size]
    for kind, mat, (x, y, z, sx, sy, sz, radius, height) in fills:
        if mat == "Air" or mat not in TERRAIN:
            continue
        color = np.array(TERRAIN[mat]) / 255
        if kind == "Block":
            if y + sy / 2 < GROUND_Y - 1.5:
                continue
            x0, x1 = to_px(x - sx / 2), to_px(x + sx / 2)
            z0, z1 = to_px(z - sz / 2), to_px(z + sz / 2)
            img[max(z0, 0):max(z1, 0), max(x0, 0):max(x1, 0)] = color
        elif kind == "Cylinder":
            if y + height / 2 < GROUND_Y - 2.5:
                continue
            cx, cz, r = to_px(x), to_px(z), radius * PX_PER_STUD
            x0, x1, z0, z1 = max(cx - int(r) - 1, 0), min(cx + int(r) + 2, size), max(cz - int(r) - 1, 0), min(
                cz + int(r) + 2, size)
            if x0 >= x1 or z0 >= z1:
                continue
            sub = (xx[z0:z1, x0:x1] - cx) ** 2 + (yy[z0:z1, x0:x1] - cz) ** 2 < r * r
            img[z0:z1, x0:x1][sub] = color
    # a little texture so big areas do not look flat
    rng = np.random.default_rng(7)
    img *= 1 + rng.normal(0, 0.035, (size, size, 1)).astype(np.float32)
    return np.clip(img, 0, 1)


def ground_object(fills):
    pixels = ground_image(fills)
    size = pixels.shape[0]
    image = bpy.data.images.new("Ground", size, size, alpha=False)
    rgba = np.ones((size, size, 4), dtype=np.float32)
    rgba[:, :, :3] = pixels[::-1]  # images start at the bottom row; row 0 of ours is z = -EXTENT (the top)
    image.pixels.foreach_set(rgba.ravel())
    image.colorspace_settings.name = "sRGB"
    mesh = bpy.data.meshes.new("Ground")
    e = EXTENT
    mesh.from_pydata([(-e, -e, GROUND_Y - 0.05), (e, -e, GROUND_Y - 0.05), (e, e, GROUND_Y - 0.05),
                      (-e, e, GROUND_Y - 0.05)], [], [(0, 1, 2, 3)])
    uv = mesh.uv_layers.new()
    for loop, co in zip(uv.data, ((0, 0), (1, 0), (1, 1), (0, 1))):
        loop.uv = co
    mat = bpy.data.materials.new("Ground")
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    bsdf = nodes.get("Principled BSDF")
    bsdf.inputs["Roughness"].default_value = 1.0
    tex = nodes.new("ShaderNodeTexImage")
    tex.image = image
    tex.interpolation = "Closest"
    mat.node_tree.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    mesh.materials.append(mat)
    obj = bpy.data.objects.new("Ground", mesh)
    bpy.context.scene.collection.objects.link(obj)

    # beyond the picture: plain grass
    outer = bpy.data.meshes.new("Outer")
    outer.from_pydata([(-6000, -6000, GROUND_Y - 0.2), (6000, -6000, GROUND_Y - 0.2), (6000, 6000, GROUND_Y - 0.2),
                       (-6000, 6000, GROUND_Y - 0.2)], [], [(0, 1, 2, 3)])
    grass = bpy.data.materials.new("Grass")
    grass.use_nodes = True
    grass.node_tree.nodes.get("Principled BSDF").inputs["Base Color"].default_value = tuple(
        srgb_to_linear(c / 255) for c in TERRAIN["Grass"]) + (1,)
    outer.materials.append(grass)
    o = bpy.data.objects.new("Outer", outer)
    bpy.context.scene.collection.objects.link(o)


# -------------------------------------------------------------------- parts
def templates():
    """Unit shapes centred on the origin: a cube, a cylinder along X, a ball."""
    cube_v = np.array([(x, y, z) for x in (-0.5, 0.5) for y in (-0.5, 0.5) for z in (-0.5, 0.5)])
    cube_f = [(0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1), (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3)]
    n = 14
    cyl_v = []
    for x in (-0.5, 0.5):
        for i in range(n):
            a = 2 * math.pi * i / n
            cyl_v.append((x, 0.5 * math.cos(a), 0.5 * math.sin(a)))
    cyl_f = [(i, (i + 1) % n, n + (i + 1) % n, n + i) for i in range(n)]
    cyl_f += [tuple(range(n - 1, -1, -1)), tuple(range(n, 2 * n))]
    rings, segs = 6, 10
    ball_v = [(0, 0, -0.5)]
    for r in range(1, rings):
        t = math.pi * r / rings - math.pi / 2
        for s in range(segs):
            a = 2 * math.pi * s / segs
            ball_v.append((0.5 * math.cos(t) * math.cos(a), 0.5 * math.cos(t) * math.sin(a), 0.5 * math.sin(t)))
    ball_v.append((0, 0, 0.5))
    top = len(ball_v) - 1
    ball_f = [(0, 1 + (s + 1) % segs, 1 + s) for s in range(segs)]
    for r in range(rings - 2):
        b = 1 + r * segs
        for s in range(segs):
            ball_f.append((b + s, b + (s + 1) % segs, b + segs + (s + 1) % segs, b + segs + s))
    b = 1 + (rings - 2) * segs
    ball_f += [(b + s, b + (s + 1) % segs, top) for s in range(segs)]
    return {"Block": (cube_v, cube_f), "Cylinder": (np.array(cyl_v), cyl_f), "Ball": (np.array(ball_v), ball_f)}


class MeshBuilder:
    def __init__(self, name):
        self.name = name
        self.verts, self.faces, self.colors = [], [], []
        self.count = 0

    def add(self, template, matrix, offset, color):
        tv, tf = template
        world = tv @ matrix.T + offset
        # Roblox to Blender axes
        world = np.stack([world[:, 0], -world[:, 2], world[:, 1]], axis=1)
        self.verts.append(world)
        for face in tf:
            self.faces.append(tuple(i + self.count for i in face))
            self.colors.append(color)
        self.count += len(tv)

    def build(self, material):
        if not self.verts:
            return None
        verts = np.concatenate(self.verts)
        mesh = bpy.data.meshes.new(self.name)
        mesh.from_pydata(verts.tolist(), [], self.faces)
        attr = mesh.color_attributes.new("Col", "FLOAT_COLOR", "FACE")
        flat = np.array([(*c, 1.0) for c in self.colors], dtype=np.float32)
        attr.data.foreach_set("color", flat.ravel())
        mesh.materials.append(material)
        obj = bpy.data.objects.new(self.name, mesh)
        bpy.context.scene.collection.objects.link(obj)
        return obj


def color_material(name, emission=0.0, alpha=1.0):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    bsdf = nodes.get("Principled BSDF")
    bsdf.inputs["Roughness"].default_value = 0.75
    attr = nodes.new("ShaderNodeAttribute")
    attr.attribute_name = "Col"
    mat.node_tree.links.new(attr.outputs["Color"], bsdf.inputs["Base Color"])
    if emission:
        mat.node_tree.links.new(attr.outputs["Color"], bsdf.inputs["Emission Color"])
        bsdf.inputs["Emission Strength"].default_value = emission
    if alpha < 1:
        bsdf.inputs["Alpha"].default_value = alpha
    return mat


def add_parts(parts):
    shapes = templates()
    solid, neon, clear = MeshBuilder("Solid"), MeshBuilder("Neon"), MeshBuilder("Clear")
    for shape, nums, material in parts:
        x, y, z, sx, sy, sz, rx, ry, rz, ux, uy, uz, r, g, b, transparency = nums
        right, up = np.array((rx, ry, rz)), np.array((ux, uy, uz))
        back = np.cross(right, up)
        rot = np.stack([right, up, back], axis=1)
        if shape == "Cylinder":
            d = min(sy, sz)
            scale = np.diag((sx, d, d))
            template = shapes["Cylinder"]
        elif shape == "Ball":
            d = min(sx, sy, sz)
            scale = np.diag((d, d, d))
            template = shapes["Ball"]
        else:
            scale = np.diag((sx, sy, sz))
            template = shapes["Block"]
        color = tuple(srgb_to_linear(c) for c in (r, g, b))
        target = neon if material == "Neon" else clear if transparency > 0.3 else solid
        target.add(template, rot @ scale, np.array((x, y, z)), color)
    solid.build(color_material("Solid"))
    neon.build(color_material("Neon", emission=2.5))
    clear.build(color_material("Clear", alpha=0.45))


def add_hills(fills):
    shapes = templates()
    hills = MeshBuilder("Hills")
    for kind, mat, (x, y, z, *_rest) in fills:
        if kind != "Ball" or mat not in TERRAIN:
            continue
        radius = _rest[3]
        d = radius * 2
        color = tuple(srgb_to_linear(c / 255) for c in TERRAIN[mat])
        hills.add(shapes["Ball"], np.diag((d, d, d)), np.array((x, y, z)), color)
    hills.build(color_material("Hills"))


# ------------------------------------------------------------------ render
def setup():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.use_denoising = True
    scene.view_settings.view_transform = "Standard"
    try:
        scene.view_settings.look = "Medium High Contrast"
    except TypeError:
        pass
    world = bpy.data.worlds.new("Sky")
    world.use_nodes = True
    bg = world.node_tree.nodes.get("Background")
    bg.inputs["Color"].default_value = (0.55, 0.75, 0.95, 1)
    bg.inputs["Strength"].default_value = 0.8
    scene.world = world
    sun_data = bpy.data.lights.new("Sun", "SUN")
    sun_data.energy = 3.4
    sun_data.angle = math.radians(4)
    sun_data.color = (1.0, 0.95, 0.85)
    sun = bpy.data.objects.new("Sun", sun_data)
    sun.rotation_euler = (math.radians(38), math.radians(0), math.radians(-40))
    scene.collection.objects.link(sun)
    return scene


def camera(scene, name, location, target, ortho=None, lens=35):
    data = bpy.data.cameras.new(name)
    if ortho:
        data.type = "ORTHO"
        data.ortho_scale = ortho
    else:
        data.lens = lens
    data.clip_end = 20000
    cam = bpy.data.objects.new(name, data)
    scene.collection.objects.link(cam)
    cam.location = location
    direction = np.array(target) - np.array(location)
    from mathutils import Vector

    cam.rotation_euler = Vector(direction).to_track_quat("-Z", "Y").to_euler()
    scene.camera = cam
    return cam


def render(scene, path, width, height, samples):
    scene.render.resolution_x = width
    scene.render.resolution_y = height
    scene.render.resolution_percentage = 100
    scene.cycles.samples = samples
    scene.render.image_settings.file_format = "JPEG"
    scene.render.image_settings.quality = 88
    scene.render.filepath = path
    bpy.ops.render.render(write_still=True)
    print("wrote", path)


def label(path, labels, width):
    """Writes the zone and region names on the map picture (needs ImageMagick)."""
    tool = shutil.which("magick") or shutil.which("convert")
    if not tool:
        print("ImageMagick not found: the map has no names on it")
        return
    scale = width / (2 * EXTENT)
    args = [tool, path]
    for x, z, size, text in labels:
        px, py = (x + EXTENT) * scale, (z + EXTENT) * scale
        points = 30 if size == 1 else 34
        fill = "white" if size == 1 else "#ffe9b0"
        args += ["-gravity", "NorthWest", "-font", "DejaVu-Sans-Bold", "-pointsize", str(points),
                 "-stroke", "#2a1a10", "-strokewidth", "6", "-fill", fill,
                 "-annotate", f"+{px - len(text) * points * 0.33:.0f}+{py - points * 0.6:.0f}", text,
                 "-stroke", "none", "-annotate", f"+{px - len(text) * points * 0.33:.0f}+{py - points * 0.6:.0f}",
                 text]
    args.append(path)
    subprocess.run(args, check=True)
    print("labelled", path)


def main():
    path = sys.argv[-1]
    parts, fills, labels = read(path)
    print(f"{len(parts)} parts, {len(fills)} terrain fills")
    scene = setup()
    ground_object(fills)
    add_hills(fills)
    add_parts(parts)

    # the whole world, straight down
    camera(scene, "Map", to_blender(0, 3000, 0), to_blender(0, 0, 0.001), ortho=2 * EXTENT)
    world_path = os.path.join(DOCS, "world-from-above.jpg")
    render(scene, world_path, 2400, 2400, 24)
    label(world_path, labels, 2400)

    # the Chowk, the havelis and the bazaar from a bird's-eye view
    camera(scene, "Town", to_blender(0, 330, 360), to_blender(0, 0, 25), lens=30)
    render(scene, os.path.join(DOCS, "town-from-above.jpg"), 2000, 1250, 32)


if __name__ == "__main__":
    main()
