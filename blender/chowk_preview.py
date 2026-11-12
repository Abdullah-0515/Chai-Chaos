"""Renders a preview picture of the Chowk (docs/chowk-preview.jpg).

    python blender/chowk_preview.py

It puts the Blender props where MapBuilder.luau puts them in the game, with
simple stand-ins for the things the game builds from code (the shop stalls,
the fountain, the havelis). It shows the mesh version of the props; built from
parts in the game, tree tops are round balls and the smallest details are left
out. Use it to check the look against docs/reference-chowk.jpg.
"""

import math
import os
import sys

import bpy
from mathutils import Vector

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, HERE)

import kit  # noqa: E402
import build  # noqa: E402  (registers every prop)

OUT = os.path.join(ROOT, "docs", "chowk-preview.jpg")
REGISTRY = {name: (category, fn) for name, category, _note, fn in kit.REGISTRY}
count = 0


def polar(angle, r):
    """A spot on the map (degrees from +X towards +Z, like Biomes.polar) in Blender's x, y."""
    a = math.radians(angle)
    return Vector((-math.cos(a) * r, math.sin(a) * r, 0))


def yaw_to(pos, target=(0, 0, 0)):
    """The turn (degrees about Z) that makes a prop at `pos` face `target`."""
    d = Vector(target) - Vector(pos)
    return math.degrees(math.atan2(d.x, -d.y))


def place(name, pos, yaw, scale=1.0, z=0.0):
    global count
    count += 1
    category, fn = REGISTRY[name]
    prop = kit.Prop(f"{name}_{count}", category)
    fn(prop)
    prop.transform(scale, (0, 0, yaw))
    build.move(prop, Vector((pos[0], pos[1], z)))
    return prop


def text(body, pos, yaw, size, color="cream"):
    curve = bpy.data.curves.new(body, "FONT")
    curve.body = body
    curve.size = size
    curve.align_x = "CENTER"
    curve.align_y = "CENTER"
    obj = bpy.data.objects.new("Text_" + body, curve)
    obj.location = pos
    obj.rotation_euler = (math.radians(90), 0, math.radians(yaw))
    curve.materials.append(kit.special_material(color, False, False))
    bpy.context.scene.collection.objects.link(obj)


def main():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    palette = os.path.join(ROOT, "assets", "props", "palette.png")
    kit.write_palette_png(palette)
    kit.Prop.palette_path = palette
    ground = build.setup_render()
    ground.location.z = -0.05
    scene = bpy.context.scene
    plaza_top = 0.6

    s = kit.Prop("ChowkScene", "zone")
    # the ground: pavement round the plaza, terracotta paving, brick roads
    s.cyl(130, 0.1, (0, 0, 0.0), None, "plaster", verts=64)
    s.cyl(72.5, 0.45, (0, 0, 0.225), None, "cream", verts=64)
    s.cyl(70, 0.6, (0, 0, 0.3), None, "terracotta", verts=64)
    for angle in (-90, 0, 90, 180):
        a, b = polar(angle, 66), polar(angle, 290)
        s.beam(a + Vector((0, 0, 0.15)), b + Vector((0, 0, 0.15)), 16, 0.3, "terracotta", "Brick")
    for i in range(72):  # the Mandi lane
        p0, p1 = polar(i * 5, 100), polar(i * 5 + 5, 100)
        s.beam(p0 + Vector((0, 0, 0.1)), p1 + Vector((0, 0, 0.1)), 8, 0.2, "clay" if i % 2 else "rosebrick", "Brick")
    # the fountain
    for height, radius, base in ((2, 13, 0), (1.6, 7, 2.4), (1.2, 3, 4.6)):
        s.cyl(radius, height, (0, 0, plaza_top + base + height / 2), None, "cream", verts=32)
        s.cyl(radius - 0.75, 0.3, (0, 0, plaza_top + base + height + 0.05), None, "water", verts=32)
    s.ball(1.2, (0, 0, plaza_top + 6.8), "cream")
    # the shop stalls (built from code in the game)
    stalls = (("BECHO", "green"), ("GEAR SHOP", "blue"), ("RADAR WALA", "purple"))
    for k, (title, color) in enumerate(stalls):
        pos = polar(45 * k + 22.5, 50)
        yaw = yaw_to(pos)
        stall = kit.Prop(f"Stall{k}", "zone")
        stall.box((12, 4, 3.5), (0, 0, 1.75), None, "rosebrick", "Brick")
        stall.box((12.5, 4.5, 0.3), (0, 0, 3.65), None, "cream")
        for x in (-5.6, 5.6):
            stall.box((0.6, 0.6, 9), (x, 1.6, 4.5), None, "darkwood", "Wood")
        for i in range(4):
            stall.box((13.5 / 4, 6.5, 0.5), (-5 + i * 3.375, 0.4, 9.2), (12, 0, 0), color if i % 2 == 0 else "white")
        stall.box((11, 0.4, 2.2), (0, -2.6, 10.8), None, "black")
        stall.transform(1.0, (0, 0, yaw))
        build.move(stall, Vector((pos.x, pos.y, plaza_top)))
    # the dhaba, charpai, statue, trees, gates, rickshaws and the fruit cart
    dhaba_at = polar(337.5, 54)
    dhaba_yaw = yaw_to(dhaba_at)
    dhaba = place("ChowkDhaba", dhaba_at, dhaba_yaw, z=plaza_top)
    sign = dhaba.anchors["Sign"] + Vector((dhaba_at.x, dhaba_at.y, plaza_top))
    front = Vector((math.sin(math.radians(dhaba_yaw)), -math.cos(math.radians(dhaba_yaw)), 0))
    text("CHAI DHABA", sign + front * 0.08, dhaba_yaw, 2.1)
    right = Vector((front.y, -front.x, 0))
    charpai_at = dhaba_at + right * 13 + front * 5
    place("Charpai", charpai_at, dhaba_yaw + 75, z=plaza_top)
    statue_at = polar(325, 19.5)
    s.cyl(4.5, 1.0, (statue_at.x, statue_at.y, plaza_top + 0.5), None, "white", verts=32)
    place("SamosaSupremo", statue_at, yaw_to(statue_at) + 180, scale=1.7, z=plaza_top + 1.0)
    for k, (angle, name) in enumerate(((-90, "PUNJAB"), (0, "SINDH"), (90, "THAR"), (180, "KPK"))):
        gate_at = polar(angle, 80)
        gate_yaw = yaw_to(gate_at)
        gate = place("ChowkGate", gate_at, gate_yaw)
        gate_front = Vector((math.sin(math.radians(gate_yaw)), -math.cos(math.radians(gate_yaw)), 0))
        text(name, gate.anchors["Sign"] + gate_at + gate_front * 0.08, gate_yaw, 1.6)
        for side in (-1, 1):
            place("PlanterTree", polar(angle + side * 12, 64), k * 50 + side * 70, z=plaza_top)
    place("Rickshaw", polar(28, 30), 40, z=plaza_top)
    place("Rickshaw", polar(150, 29), -70, z=plaza_top)
    fruit_at = polar(236, 60)
    place("FruitStall", fruit_at, yaw_to(fruit_at), z=plaza_top)
    # warm string lights and their poles
    for i in range(72):
        p = polar(i * 5, 68)
        s.ball(0.4, (p.x, p.y, 9 - (0 if (i + 1) % 6 == 0 else 0.6)), "bulb", "Neon")
    for k in range(16):
        p = polar(11.25 + 22.5 * k, 68)
        s.box((0.5, 0.5, 9), (p.x, p.y, 4.5), None, "darkwood", "Wood")
    # the havelis (stand-ins: in the game each player's haveli has its own theme)
    for i in range(8):
        pos = polar(-67.5 + 45 * i, 150)
        house = kit.Prop(f"Haveli{i}", "zone")
        house.box((72, 52, 12.4), (0, 0, 6.2), None, "plaster")
        house.box((72, 30, 9), (0, 10, 16.9), None, "rosebrick" if i % 2 else "cream", "Brick")
        house.box((14, 1.2, 9), (0, -26, 4.5), None, "darkwood")
        for x in range(-30, 31, 12):
            house.box((6, 0.6, 5), (x, -5.2, 16.5), None, "maroon")
        house.transform(1.0, (0, 0, yaw_to(pos)))
        build.move(house, Vector((pos.x, pos.y, 0)))
    # the kite
    kite = kit.Prop("Kite", "zone")
    for sx, sz, color in ((-1, 1, "pink"), (1, 1, "yellow"), (-1, -1, "orange"), (1, -1, "magenta")):
        kite.box((3, 0.15, 3), (sx * 1.5, 0, sz * 1.5), None, color, "Fabric")
    kite.transform(1.0, (25, 45, -35))
    kite_at = Vector((-62, -38, 40))
    build.move(kite, kite_at)
    s.rod(sign + Vector((0, 0, 1.5)), kite_at, 0.05, "white", "Fabric")

    # the camera: standing in the Chowk, looking past the dhaba at the Sindh arch
    cam_data = bpy.data.cameras.new("ChowkCam")
    cam_data.lens = 20
    cam_data.clip_end = 2000
    cam = bpy.data.objects.new("ChowkCam", cam_data)
    eye = Vector((8, -24, 8))
    target = Vector((-80, -4, 11))
    cam.location = eye
    cam.rotation_euler = (target - eye).to_track_quat("-Z", "Y").to_euler()
    scene.collection.objects.link(cam)
    scene.camera = cam
    scene.render.resolution_x = 1600
    scene.render.resolution_y = 900
    scene.cycles.samples = 48
    scene.render.image_settings.file_format = "JPEG"
    scene.render.image_settings.quality = 90
    scene.render.filepath = OUT
    bpy.ops.render.render(write_still=True)
    print("wrote", OUT)


if __name__ == "__main__":
    main()
