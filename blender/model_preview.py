"""Renders a close-up picture of models, as the game builds them from parts.

    python blender/model_preview.py Charpai Matka TubeWell
    python blender/model_preview.py --category=desi

writes docs/models/<Name>.jpg for each one.

The game builds every prop out of Roblox parts (blocks, cylinders and balls)
unless you import the meshes, so these pictures show that version: mesh-only
pieces become their part stand-ins (a cone becomes a cylinder, a lumpy blob a
ball), and pieces that only exist in the mesh are left out.
"""

import math
import os
import sys

import bpy  # noqa: I001 (bpy must come first: it makes bmesh importable)
import bmesh
from mathutils import Vector

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, HERE)

import kit  # noqa: E402
import build  # noqa: E402  (registers every prop)

OUT = os.path.join(ROOT, "docs", "models")
REGISTRY = {name: (category, fn) for name, category, _note, fn in kit.REGISTRY}
GROUND = (214, 190, 150)


def stand_in(obj):
    """The parts version of a mesh-only piece: a block, cylinder or ball in its place."""
    fallback = obj["rbx_fallback"]
    center, size = kit._local_bounds(obj)
    fs = Vector(obj["rbx_fallback_scale"])
    size = Vector((size.x * fs.x, size.y * fs.y, size.z * fs.z))
    bm = bmesh.new()
    if fallback == "Block":
        bmesh.ops.create_cube(bm, size=1.0)
        bmesh.ops.scale(bm, vec=size, verts=bm.verts)
    elif fallback in ("Cylinder", "Disc"):
        d = max(size.x, size.y)
        bmesh.ops.create_cone(bm, cap_ends=True, segments=16, radius1=d / 2, radius2=d / 2, depth=size.z)
    elif fallback == "Ball":
        bmesh.ops.create_uvsphere(bm, u_segments=16, v_segments=10, radius=max(size) / 2)
    else:
        bm.free()
        return None
    bmesh.ops.translate(bm, vec=center, verts=bm.verts)
    mesh = bpy.data.meshes.new(obj.name + "_part")
    bm.to_mesh(mesh)
    bm.free()
    for poly in mesh.polygons:
        poly.use_smooth = False
    # the same palette cell as the mesh piece
    uv = mesh.uv_layers.new()
    u, v = obj.data.uv_layers[0].data[0].uv if obj.data.uv_layers else (0.5, 0.5)
    for loop in uv.data:
        loop.uv = (u, v)
    new = bpy.data.objects.new(obj.name + "_part", mesh)
    new.rotation_mode = "QUATERNION"
    new.rotation_quaternion = obj.rotation_quaternion
    new.location = obj.location
    for mat in obj.data.materials:
        new.data.materials.append(mat)
    obj.users_collection[0].objects.link(new)
    return new


def as_parts(prop):
    """Shows the prop the way the game builds it from parts."""
    shown = []
    for obj in list(prop.pieces):
        flags = obj["rbx_flags"]
        if flags & kit.PARTSONLY:
            obj.hide_render = False
            shown.append(obj)
        elif obj["rbx_shape"] == "Mesh":
            obj.hide_render = True
            part = stand_in(obj)
            if part:
                shown.append(part)
        else:
            shown.append(obj)
    return shown


def flat_material(rgb):
    mat = bpy.data.materials.new("Ground")
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = tuple(kit.srgb_to_linear(c) for c in rgb) + (1,)
    bsdf.inputs["Roughness"].default_value = 0.95
    return mat


def render(name):
    category, fn = REGISTRY[name]
    bpy.ops.wm.read_factory_settings(use_empty=True)
    kit._materials.clear()
    palette = os.path.join(ROOT, "assets", "props", "palette.png")
    kit.write_palette_png(palette)
    kit.Prop.palette_path = palette
    ground = build.setup_render()
    ground.data.materials.clear()
    ground.data.materials.append(flat_material(GROUND))
    scene = bpy.context.scene
    sun = bpy.data.objects["Sun"]
    sun.data.energy = 3.0
    sun.data.color = (1.0, 0.94, 0.82)
    sun.rotation_euler = (math.radians(48), math.radians(6), math.radians(-30))
    scene.world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.36, 0.6, 0.95, 1)
    try:
        scene.view_settings.look = "Medium High Contrast"
    except TypeError:
        pass

    prop = kit.Prop(name, category)
    fn(prop)
    pieces = as_parts(prop)
    bpy.context.view_layer.update()
    corners = []
    for obj in pieces:
        corners.extend(obj.matrix_world @ v.co for v in obj.data.vertices)
    lo = Vector((min(c.x for c in corners), min(c.y for c in corners), min(c.z for c in corners)))
    hi = Vector((max(c.x for c in corners), max(c.y for c in corners), max(c.z for c in corners)))
    center = (lo + hi) / 2
    # the floor goes under the lowest piece (bridges hang below their ends, stilts reach into water)
    ground.location.z = min(ground.location.z, lo.z)
    radius = max((c - center).length for c in corners)

    cam_data = bpy.data.cameras.new("ModelCam")
    cam_data.lens = 50
    cam = bpy.data.objects.new("ModelCam", cam_data)
    scene.collection.objects.link(cam)
    # three-quarters from the front (the front is -Y), a little from above
    view = Vector((-0.55, -1.0, 0.5)).normalized()
    fov = 2 * math.atan(36 / 2 / cam_data.lens) * 0.62
    distance = radius / math.sin(fov / 2)
    cam.location = center + view * distance
    cam.rotation_euler = (-view).to_track_quat("-Z", "Y").to_euler()
    cam_data.clip_end = distance * 4
    scene.camera = cam

    scene.render.resolution_x = 1000
    scene.render.resolution_y = 700
    scene.cycles.samples = 32
    scene.render.image_settings.file_format = "JPEG"
    scene.render.image_settings.quality = 85
    path = os.path.join(OUT, f"{name}.jpg")
    scene.render.filepath = path
    bpy.ops.render.render(write_still=True)
    print("wrote", path)


def main():
    os.makedirs(OUT, exist_ok=True)
    names = []
    for arg in sys.argv[1:]:
        if arg.startswith("--category="):
            wanted = arg.split("=", 1)[1]
            names.extend(n for n, (c, _) in REGISTRY.items() if c == wanted)
        else:
            names.append(arg)
    for name in names:
        render(name)


if __name__ == "__main__":
    main()
