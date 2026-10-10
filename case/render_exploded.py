"""Renders the exploded view (renders/exploded.png) in Blender (3.x): the
case's pieces as OpenSCAD exports them, with KiCad's 3D models of the boards
in place of the model's plain green ones. render_exploded.sh does the
exports and runs this:

  blender -b -P case/render_exploded.py -- export_dir out.png

export_dir has the pieces (<piece>.stl), the boards (sensor.wrl, base.wrl,
exported with the board's origin as the user origin) and rollino.echo, the
model's echo output with the boards' placements.
"""

import json
import math
import os
import re
import sys

import bpy
from mathutils import Matrix, Vector

argv = sys.argv[sys.argv.index("--") + 1:]
src, out = argv[0], argv[1]

echo = open(os.path.join(src, "rollino.echo")).read()
place = json.loads(re.search(r'ECHO: "EXPLODED (\{.*\})"', echo).group(1).replace('\\"', '"'))

bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene


def srgb(h):
    """'#rrggbb' as linear RGBA."""
    return tuple(((int(h[i:i + 2], 16) / 255.0) ** 2.2) for i in (1, 3, 5)) + (1.0,)


def material(name, colour, roughness=0.5, metallic=0.0):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = srgb(colour)
    b.inputs["Roughness"].default_value = roughness
    b.inputs["Metallic"].default_value = metallic
    return m


PIECES = [  # piece, colour, roughness, metallic
    ("body", "#d8d4cc", 0.6, 0), ("cover", "#b8b4ac", 0.6, 0), ("ball", "#b22222", 0.25, 0),
    ("supports", "#f4f4f4", 0.2, 0), ("screws", "#696969", 0.35, 1), ("pouch", "#c0c0c0", 0.3, 1),
    ("pcm", "#d4a017", 0.5, 0), ("leads", "#8b1a1a", 0.5, 0)]

for name, colour, rough, metal in PIECES:
    bpy.ops.import_mesh.stl(filepath=os.path.join(src, name + ".stl"))
    o = bpy.context.selected_objects[0]
    o.data.materials.append(material(name, colour, rough, metal))
    # smooth curved surfaces, crisp edges
    for p in o.data.polygons:
        p.use_smooth = True
    o.data.use_auto_smooth = True
    o.data.auto_smooth_angle = math.radians(35)

# KiCad's VRML comes into Blender as (-x, up from the board's mid-plane,
# -y) of the board's KiCad frame: turn that into the model's board frame
# (x, -y, z up from the board's top face) before placing it
TO_BOARD = Matrix(((-1, 0, 0, 0), (0, 0, 1, 0), (0, 1, 0, -0.8), (0, 0, 0, 1)))


def board(wrl, matrix):
    before = set(bpy.context.scene.objects)
    bpy.ops.import_scene.x3d(filepath=wrl)
    root = bpy.data.objects.new(os.path.basename(wrl), None)
    scene.collection.objects.link(root)
    for o in set(bpy.context.scene.objects) - before:
        if o.parent is None and o is not root:
            o.parent = root
        if o.type == "MESH":
            for m in o.data.materials:
                if m and m.use_nodes:
                    b = m.node_tree.nodes.get("Principled BSDF")
                    if b:
                        b.inputs["Roughness"].default_value = 0.45
    root.matrix_world = Matrix(matrix) @ TO_BOARD


for m in place["sensor"]:
    board(os.path.join(src, "sensor.wrl"), m)
board(os.path.join(src, "base.wrl"), place["base"])

# frame everything from the front right, a little above
bpy.context.view_layer.update()
meshes = [o for o in scene.objects if o.type == "MESH"]
pts = [o.matrix_world @ Vector(c) for o in meshes for c in o.bound_box]
lo = Vector([min(p[i] for p in pts) for i in range(3)])
hi = Vector([max(p[i] for p in pts) for i in range(3)])
centre, size = (lo + hi) / 2, (hi - lo).length

scene.render.engine = "CYCLES"
scene.cycles.samples = 96
scene.cycles.use_denoising = True
scene.render.resolution_x, scene.render.resolution_y = 1200, 1400
# (the background goes on afterwards: under Filmic it would come out grey)
scene.render.film_transparent = True
world = bpy.data.worlds.new("world")
scene.world = world
world.use_nodes = True
world.node_tree.nodes["Background"].inputs[0].default_value = (0.93, 0.93, 0.92, 1)
world.node_tree.nodes["Background"].inputs[1].default_value = 0.8

for name, rot, energy in (("key", (math.radians(35), 0, math.radians(20)), 4.0),
                          ("fill", (math.radians(-60), 0, math.radians(-140)), 1.2),
                          ("under", (math.radians(160), 0, math.radians(30)), 0.8)):
    light = bpy.data.lights.new(name, "SUN")
    light.energy = energy
    light.angle = math.radians(8)
    lo_ = bpy.data.objects.new(name, light)
    lo_.rotation_euler = rot
    scene.collection.objects.link(lo_)

cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
cam.data.lens = 85
scene.collection.objects.link(cam)
scene.camera = cam
view = Vector((0.75, -1.0, 0.55)).normalized()
cam.location = centre + view * size * 2.6
cam.rotation_euler = (-view).to_track_quat("-Z", "Y").to_euler()
scene.render.filepath = out
bpy.ops.render.render(write_still=True)
