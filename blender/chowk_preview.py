"""Renders a preview picture of the Chowk (docs/chowk-preview.jpg).

    python blender/chowk_preview.py

It puts the Blender props where MapBuilder.luau puts them in the game, and
rebuilds the things the game makes from code (the havelis, the shop stalls,
the fountain) from the same measurements. The trees are shown as the game
builds them from parts (faceted blocks); the other props show their mesh
version, which has a few small details the parts version leaves out. Use it to
check the look against docs/reference-chowk.jpg.
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
HAVELI_OUT = os.path.join(ROOT, "docs", "haveli-preview.jpg")
SPAWN_OUT = os.path.join(ROOT, "docs", "spawn-preview.jpg")
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


def place(name, pos, yaw, scale=1.0, z=0.0, parts=False):
    """Places a prop. With parts=True it shows the pieces the game builds from
    parts instead of the mesh-only ones."""
    global count
    count += 1
    category, fn = REGISTRY[name]
    prop = kit.Prop(f"{name}_{count}", category)
    fn(prop)
    if parts:
        for obj in prop.pieces:
            if obj["rbx_flags"] & kit.PARTSONLY:
                obj.hide_render = False
            elif obj["rbx_shape"] == "Mesh" and obj["rbx_fallback"] in ("", "None"):
                obj.hide_render = True
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


def paving(obj, color, mortar, scale=0.22):
    """Gives a piece a brick pattern, like Roblox's Brick material does in the game."""
    mat = bpy.data.materials.new("Paving")
    mat.use_nodes = True
    nodes, links = mat.node_tree.nodes, mat.node_tree.links
    bsdf = nodes.get("Principled BSDF")
    bsdf.inputs["Roughness"].default_value = 0.9
    brick = nodes.new("ShaderNodeTexBrick")
    coords = nodes.new("ShaderNodeTexCoord")
    mapping = nodes.new("ShaderNodeMapping")
    mapping.inputs["Scale"].default_value = (scale, scale, scale)
    links.new(coords.outputs["Object"], mapping.inputs["Vector"])
    links.new(mapping.outputs["Vector"], brick.inputs["Vector"])

    def linear(rgb, k=1.0):
        return tuple(kit.srgb_to_linear(min(255, c * k)) for c in rgb) + (1,)

    brick.inputs["Color1"].default_value = linear(color)
    brick.inputs["Color2"].default_value = linear(color, 0.93)
    brick.inputs["Mortar"].default_value = linear(mortar)
    brick.inputs["Mortar Size"].default_value = 0.012
    links.new(brick.outputs["Color"], bsdf.inputs["Base Color"])
    obj.data.materials.clear()
    obj.data.materials.append(mat)


def flat_color(obj, rgb):
    mat = bpy.data.materials.new("Flat")
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = tuple(kit.srgb_to_linear(c) for c in rgb) + (1,)
    bsdf.inputs["Roughness"].default_value = 0.9
    obj.data.materials.clear()
    obj.data.materials.append(mat)


TERRACOTTA, TERRACOTTA_LIGHT, MORTAR = (198, 110, 82), (226, 142, 108), (160, 86, 66)
HOUSES = ("ChowkHouseCream", "ChowkHouseBrick", "ChowkHouseOchre", "ChowkHousePeach")


def haveli(name, pos, yaw, trim="mughal", accent="yellow"):
    """A haveli as the game builds it (Blender's -Y is the front, facing the Chowk)."""
    h = kit.Prop(name, "zone")
    W, D, FLOOR, WALL, UPPER, DECK_FRONT, DOOR_W, DOOR_H = 72, 52, 0.4, 12, 9, -6, 14, 9
    hw, hd = W / 2, D / 2
    front = -hd + 0.5
    deck_y = FLOOR + WALL
    face = front - 0.55
    seg = (W - DOOR_W) / 2
    h.box((W, D, FLOOR), (0, 0, FLOOR / 2), None, "cream")
    # red brick ground floor, with the door gap in the front wall
    for x in (-(DOOR_W / 2 + seg / 2), DOOR_W / 2 + seg / 2):
        h.box((seg, 1, WALL), (x, front, FLOOR + WALL / 2), None, "rosebrick", "Brick")
    h.box((DOOR_W, 1, WALL - DOOR_H), (0, front, FLOOR + DOOR_H + (WALL - DOOR_H) / 2), None, "rosebrick", "Brick")
    for x in (-hw + 0.5, hw - 0.5):
        h.box((1, D, WALL), (x, 0, FLOOR + WALL / 2), None, "rosebrick", "Brick")
    h.box((W, 1, WALL), (0, hd - 0.5, FLOOR + WALL / 2), None, "rosebrick", "Brick")
    # the cream upper floor, set back behind the courtyard
    deck_depth = hd - DECK_FRONT
    h.box((W - 2, deck_depth, 1), (0, DECK_FRONT + deck_depth / 2, deck_y - 0.5), None, "cream")
    h.box((W, 1, UPPER), (0, hd - 0.5, deck_y + UPPER / 2), None, "haveliupper")
    for x in (-hw + 0.5, hw - 0.5):
        h.box((1, deck_depth, UPPER), (x, DECK_FRONT + deck_depth / 2, deck_y + UPPER / 2), None, "haveliupper")
    # the facade: plinth, teal band with diamonds, door, windows, awnings
    for x in (-(DOOR_W / 2 + seg / 2), DOOR_W / 2 + seg / 2):
        h.box((seg, 0.3, 1.2), (x, face, FLOOR + 0.6), None, "cream")
    h.box((W, 0.3, 1.4), (0, face, FLOOR + WALL - 0.9), None, "dhabateal")
    for x in range(-33, 34, 6):
        h.box((0.9, 0.35, 0.9), (x, face - 0.05, FLOOR + WALL - 0.9), (0, 45, 0), "gold")
    h.box((DOOR_W + 3, 0.6, 1.2), (0, face - 0.1, FLOOR + DOOR_H + 0.6), None, "cream")
    h.box((1.6, 0.7, 1.8), (0, face - 0.2, FLOOR + DOOR_H + 0.9), None, "cream")
    for side in (-1, 1):
        h.box((3.4, 0.3, DOOR_H - 0.6), (side * (DOOR_W / 2 + 2.6), face - 0.1, FLOOR + (DOOR_H - 0.6) / 2), None,
              "dhabateal", "WoodPlanks")
        h.cyl(0.9, WALL + 1, (side * DOOR_W / 2, front - 0.2, FLOOR + (WALL + 1) / 2), None, trim, verts=12)
    for x in (-29, -18, 18, 29):
        h.box((4.2, 0.3, 4.2), (x, face, FLOOR + 4.6), None, "cream")
        for half in (-1, 1):
            h.box((1.6, 0.35, 3.4), (x + half * 0.9, face - 0.05, FLOOR + 4.6), None, "dhabateal", "WoodPlanks")
        h.box((4.8, 0.9, 0.4), (x, face - 0.3, FLOOR + 2.4), None, "cream")
        for k in range(1, 6):
            h.box((1.2, 2.6, 0.2), (x - 3 + k * 1.2 - 0.6, face - 1.15, FLOOR + 7.6), (22, 0, 0),
                  trim if k % 2 == 1 else "cream2", "Fabric")
    # the cream upper storey on the front: arched windows, a balcony, battlements, the sign
    bottom, top_front = FLOOR + WALL + 1, deck_y + UPPER
    sign_y = bottom + 3.6
    h.box((W, 2.4, 1), (0, front - 0.5, FLOOR + WALL + 0.5), None, "cream")
    h.box((W, 1, top_front - bottom), (0, front, (bottom + top_front) / 2), None, "haveliupper")
    for side in (-1, 1):
        for x in (17, 24, 31):
            h.box((3.4, 0.2, 3.6), (side * x, face + 0.1, bottom + 2.8), None, "maroon")
            h.cyl(1.7, 0.2, (side * x, face + 0.1, bottom + 4.6), (90, 0, 0), "maroon", verts=16)
        h.box((22, 0.35, 0.35), (side * 24.5, front - 1.3, bottom + 1.4), None, "cream")
        for k in range(11):
            h.box((0.35, 0.35, 1.2), (side * (14 + k * 2.1), front - 1.3, bottom + 0.65), None, "cream")
    h.box((W + 0.6, 1.6, 0.6), (0, front - 0.1, top_front - 0.3), None, "cream")
    for x in range(-34, 35, 4):
        h.box((2, 1.2, 1.6), (x, front, top_front + 0.8), None, "rosebrick", "Brick")
    h.box((24.8, 0.4, 4.4), (0, front - 0.7, sign_y), None, "cream")
    h.box((24, 0.6, 3.6), (0, front - 1.05, sign_y), None, "dhabateal")
    # the arcade of cream arches along the balcony, and its battlements
    top = deck_y + UPPER
    pillars = (-27.6, -17.8, -8, 1.8, 11.6, 21.4, 31.2)
    for x in pillars:
        h.box((1.4, 1.4, UPPER - 2), (x, DECK_FRONT, deck_y + (UPPER - 2) / 2), None, "cream")
    h.box((W - 1, 1.4, 2), (0, DECK_FRONT, top - 1), None, "cream")
    for a, b in zip(pillars, pillars[1:]):
        for edge in (a + 0.7, b - 0.7):
            h.box((2.4, 1.3, 2.4), (edge, DECK_FRONT, top - 2), (0, 45, 0), "cream")
    h.box((W - 30, 0.6, 3), (3, DECK_FRONT, deck_y + 1.5), None, "cream")
    for x in [-34 + 4.5 * k for k in range(16)]:
        h.box((2, 1.2, 1.6), (x, DECK_FRONT, top + 1.8), None, "haveliupper")
    # corner towers with cream caps and domes
    for cx, cz in ((-1, -1), (1, -1), (-1, 1), (1, 1)):
        height = WALL + 3 if cz < 0 else WALL + UPPER + 3
        x, y = cx * hw, cz * hd
        h.cyl(2, height, (x, y, FLOOR + height / 2), None, trim, verts=16)
        h.cyl(2.5, 0.8, (x, y, FLOOR + height - 0.2), None, "cream", verts=16)
        h.ball(2.3, (x, y, FLOOR + height + 0.8), accent)
    h.transform(1.0, (0, 0, yaw))
    build.move(h, Vector((pos.x, pos.y, 0)))
    sign_front = Vector((math.sin(math.radians(yaw)), -math.cos(math.radians(yaw)), 0))
    text("Ali ki Haveli", Vector((pos.x, pos.y, FLOOR + WALL + 1 + 3.6)) + sign_front * (hd + 0.86), yaw, 2.0,
         "yellow")


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
    flat_color(s.cyl(96, 0.2, (0, 0, 0.1), None, "peach", verts=64), (236, 210, 186))
    s.cyl(72.5, 0.45, (0, 0, 0.225), None, "cream", verts=64)
    paving(s.cyl(70, 0.6, (0, 0, 0.3), None, "terracotta", verts=64), TERRACOTTA, MORTAR)
    rings = ((60, TERRACOTTA_LIGHT), (56, TERRACOTTA), (36, TERRACOTTA_LIGHT), (32, TERRACOTTA))
    for i, (radius, color) in enumerate(rings):
        height = 0.62 + i * 0.02
        paving(s.cyl(radius, height, (0, 0, height / 2), None, "terracotta", verts=64), color, MORTAR)
    s.cyl(17, 0.7, (0, 0, 0.35), None, "cream", verts=48)
    for angle in (-90, 0, 90, 180):
        a, b = polar(angle, 66), polar(angle, 290)
        paving(s.beam(a + Vector((0, 0, 0.15)), b + Vector((0, 0, 0.15)), 16, 0.3, "terracotta", "Brick"), TERRACOTTA,
               MORTAR)
    for i in range(72):  # the Mandi lane
        p0, p1 = polar(i * 5, 100), polar(i * 5 + 5, 100)
        s.beam(p0 + Vector((0, 0, 0.1)), p1 + Vector((0, 0, 0.1)), 8, 0.2, "clay" if i % 2 else "rosebrick", "Brick")
    # the fountain: a low cream basin, a pedestal and bowl, a little pyramid on top
    s.cyl(13, 2.4, (0, 0, plaza_top + 1.2), None, "cream", verts=40)
    for k in range(24):  # the raised rim of stones
        a = math.radians(k * 15)
        p = polar(k * 15, 12.6)
        s.box((1, 2 * math.pi * 13.1 / 24 + 0.2, 0.7), (p.x, p.y, plaza_top + 2.75), (0, 0, -k * 15), "cream")
    s.cyl(12.2, 0.3, (0, 0, plaza_top + 2.45), None, "skyblue", verts=40)
    s.cyl(1.3, 3.4, (0, 0, plaza_top + 4.1), None, "cream", verts=16)
    s.cyl(3, 1, (0, 0, plaza_top + 6), None, "cream", verts=24)
    s.cyl(2.5, 0.3, (0, 0, plaza_top + 6.15), None, "skyblue", verts=24)
    s.box((1.5, 1.5, 1.4), (0, 0, plaza_top + 7), None, "cream")
    s.box((1.3, 1.3, 1.3), (0, 0, plaza_top + 7.7), (45, 35.26, 0), "cream")
    # the shop stalls (built from code in MapBuilder.shopStall)
    stalls = (("BECHO", "green"), ("GEAR SHOP", "blue"), ("RADAR WALA", "purple"))
    for k, (title, color) in enumerate(stalls):
        pos = polar(45 * k + 22.5, 50)
        yaw = yaw_to(pos)
        stall = kit.Prop(f"Stall{k}", "zone")
        stall.box((12, 4, 3.5), (0, 0, 1.75), None, "rosebrick", "Brick")
        stall.box((12.5, 4.5, 0.3), (0, 0, 3.65), None, "cream")
        stall.box((12.05, 0.2, 0.9), (0, -2.05, 2.4), None, "gold")
        for j in range(7):
            stall.box((0.6, 0.25, 0.6), (-5.1 + j * 1.7, -2.12, 2.4), (0, 45, 0), "dhabateal" if j % 2 == 0 else "red")
        for x in (-5.6, 5.6):
            stall.box((0.6, 0.6, 12.6), (x, -1.6, 6.3), None, "warmwood", "Wood")
            stall.box((0.6, 0.6, 9), (x, 1.6, 4.5), None, "warmwood", "Wood")
        stall.box((12, 0.5, 0.5), (0, -1.6, 8.8), None, "warmwood", "Wood")
        for j in range(6):
            stripe = color if j % 2 == 0 else "cream2"
            stall.box((2.2, 6, 0.3), (-5.5 + j * 2.2, -0.6, 9.6), (14, 0, 0), stripe, "Fabric")
        stall.box((13.2, 0.15, 0.7), (0, -3.62, 8.6), None, color, "Fabric")
        for j in range(12):
            stall.cyl(0.55, 0.12, (-6.05 + j * 1.1, -3.52, 8.25), (90, 0, 0), color if j % 2 == 0 else "cream2",
                      "Fabric", verts=12)
        stall.box((10, 0.12, 0.12), (0, -2.6, 8.38), None, "black")
        for j in range(5):
            stall.ball(0.3, (-4.4 + j * 2.2, -2.6, 8.0), "bulb", "Neon")
        for side in (-1, 1):  # crates of fruit
            stall.box((2.2, 1.8, 1.4), (side * 7.6, -1, 0.7), None, "lightwood", "WoodPlanks")
            for f in range(3):
                stall.ball(0.35, (side * 7.6 - 0.6 + f * 0.6, -1 + (f % 2) * 0.3, 1.55),
                           "red" if (f + side) % 2 == 0 else "yellow")
        stall.box((11.8, 0.3, 3), (0, -1.45, 11.4), None, "cream")
        stall.box((11, 0.4, 2.2), (0, -1.7, 11.4), None, color)
        stall.transform(1.0, (0, 0, yaw))
        build.move(stall, Vector((pos.x, pos.y, plaza_top)))
        front = Vector((math.sin(math.radians(yaw)), -math.cos(math.radians(yaw)), 0))
        text(title, Vector((pos.x, pos.y, plaza_top + 11.4)) + front * 1.92, yaw, 1.1)
    # the dhaba, charpai, trees, gates, rickshaws and the fruit cart
    dhaba_at = polar(337.5, 54)
    dhaba_yaw = yaw_to(dhaba_at)
    dhaba = place("ChowkDhaba", dhaba_at, dhaba_yaw, z=plaza_top)
    sign = dhaba.anchors["Sign"] + Vector((dhaba_at.x, dhaba_at.y, plaza_top))
    front = Vector((math.sin(math.radians(dhaba_yaw)), -math.cos(math.radians(dhaba_yaw)), 0))
    text("CHAI DHABA", sign + front * 0.08, dhaba_yaw, 1.8)
    right = Vector((front.y, -front.x, 0))
    charpai_at = dhaba_at + right * 13 + front * 5
    place("Charpai", charpai_at, dhaba_yaw + 75, z=plaza_top)
    # the bazaar houses: two in front of every haveli, with a walkway between them
    house_spots = []
    for k in range(1, 9):
        angle = -67.5 + 45 * (k - 1)
        a = math.radians(angle)
        across = Vector((-math.sin(a), -math.cos(a), 0))
        for side in (-1, 1):
            pos = polar(angle, 86) + across * side * 9.5
            place(HOUSES[(2 * k + (side + 1) // 2) % 4], pos, yaw_to(polar(angle, 86)), z=0.2)
            house_spots.append(pos)
    for k, angle in enumerate((-45, 45, 135, 225), start=1):  # and one each side of every alley
        a = math.radians(angle)
        across = Vector((-math.sin(a), -math.cos(a), 0))
        for side in (-1, 1):
            pos = polar(angle, 86) + across * side * 12.5
            place(HOUSES[(2 * k + (side + 1) // 2 + 1) % 4], pos, yaw_to(polar(angle, 86)), z=0.2)
            house_spots.append(pos)
    for k, (angle, name) in enumerate(((-90, "PUNJAB"), (0, "SINDH"), (90, "THAR"), (180, "KPK"))):
        gate_at = polar(angle, 80)
        gate_yaw = yaw_to(gate_at)
        gate = place("ChowkGate", gate_at, gate_yaw)
        gate_front = Vector((math.sin(math.radians(gate_yaw)), -math.cos(math.radians(gate_yaw)), 0))
        gate_right = Vector((gate_front.y, -gate_front.x, 0))
        for side in (-1, 1):  # string lights down to the nearest rooftops
            start = gate_at + gate_right * side * 15 + Vector((0, 0, 24.6))
            near = min((h for h in house_spots if (h - gate_at).dot(gate_right) * side > 0),
                       key=lambda h: (h - start).length)
            end = near + Vector((0, 0, 14.6))
            def sag(t):
                return start.lerp(end, t) - Vector((0, 0, 10 * t * (1 - t)))

            for n in range(9):
                s.rod(sag(n / 9) + Vector((0, 0, 0.45)), sag((n + 1) / 9) + Vector((0, 0, 0.45)), 0.06, "black",
                      "SmoothPlastic", verts=4)
            for n in range(1, 9):
                s.ball(0.4, sag(n / 9), "bulb", "Neon")
        text(name, gate.anchors["Sign"] + gate_at + gate_front * 0.08, gate_yaw, 1.6)
        for side in (-1, 1):
            place("PlanterTree", polar(angle + side * 12, 64), k * 50 + side * 70, z=plaza_top, parts=True)
    place("Rickshaw", polar(28, 30), 40, z=plaza_top)
    place("Rickshaw", polar(150, 29), -70, z=plaza_top)
    fruit_at = polar(236, 60)
    place("FruitStall", fruit_at, yaw_to(fruit_at), z=plaza_top)
    # warm string lights and their poles
    ring = []
    for i in range(72):
        p = polar(i * 5, 68)
        z = 9 - (0 if (i + 1) % 6 == 0 else 0.6)
        s.ball(0.4, (p.x, p.y, z), "bulb", "Neon")
        ring.append(Vector((p.x, p.y, z + 0.45)))
    for i, point in enumerate(ring):
        s.rod(point, ring[(i + 1) % len(ring)], 0.06, "black", "SmoothPlastic", verts=4)
    for k in range(16):
        p = polar(11.25 + 22.5 * k, 68)
        s.box((0.5, 0.5, 9), (p.x, p.y, 4.5), None, "darkwood", "Wood")
    # the havelis, with the facade MapBuilder.buildHaveli gives them (in the
    # free Mughal Marble theme: red-orange towers and awnings, gold domes)
    for i in range(8):
        pos = polar(-67.5 + 45 * i, 150)
        haveli(f"Haveli{i}", pos, yaw_to(pos))
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
    cam_data.lens = 21
    cam_data.clip_end = 2000
    cam = bpy.data.objects.new("ChowkCam", cam_data)
    eye = Vector((6, -22, 7))
    target = Vector((-80, -5, 10))
    # a warm afternoon sun and a deeper blue sky, like the game's lighting
    sun = bpy.data.objects["Sun"]
    sun.data.energy = 4.2
    sun.data.color = (1.0, 0.93, 0.8)
    sun.rotation_euler = (math.radians(52), math.radians(8), math.radians(150))
    scene.world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.32, 0.58, 0.95, 1)
    scene.world.node_tree.nodes["Background"].inputs["Strength"].default_value = 1.0
    try:
        scene.view_settings.look = "Medium High Contrast"
    except TypeError:
        pass
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

    # a second picture: a haveli, seen from the walkway between the bazaar houses
    eye = polar(-67.5, 93) + Vector((0, 0, 8))
    target = polar(-67.5, 150) + Vector((0, 0, 13))
    cam.location = eye
    cam.rotation_euler = (target - eye).to_track_quat("-Z", "Y").to_euler()
    cam_data.lens = 15
    scene.render.filepath = HAVELI_OUT
    bpy.ops.render.render(write_still=True)
    print("wrote", HAVELI_OUT)

    # a third: what a player sees when they appear in the Chowk (Havelis.chowkSpawn),
    # from just behind and above their head, facing the Chai Dhaba
    spot = polar(337.5, 32)
    toward = (dhaba_at - spot).normalized()
    eye = spot - toward * 9 + Vector((0, 0, 7.5))
    target = dhaba_at + Vector((0, 0, 5))
    cam.location = eye
    cam.rotation_euler = (target - eye).to_track_quat("-Z", "Y").to_euler()
    cam_data.lens = 22
    scene.render.filepath = SPAWN_OUT
    bpy.ops.render.render(write_still=True)
    print("wrote", SPAWN_OUT)


if __name__ == "__main__":
    main()
