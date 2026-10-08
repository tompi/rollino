"""Renders a board exported from KiCad as VRML, from above and from below.
Run with Blender (3.x):

  blender -b -P pcb/gen/render.py -- board.wrl out_prefix [tilt_degrees]

writes out_prefix-top.png and out_prefix-bottom.png. render_pcbs.sh does the
KiCad export and runs this for both boards.
"""

import math
import sys

import bpy
from mathutils import Vector

argv = sys.argv[sys.argv.index("--") + 1:]
wrl, out = argv[0], argv[1]
tilt = math.radians(float(argv[2]) if len(argv) > 2 else 35)

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.x3d(filepath=wrl)
meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]

# centre it, with its thin axis (the board's normal) up
pts = [o.matrix_world @ Vector(c) for o in meshes for c in o.bound_box]
lo = Vector([min(p[i] for p in pts) for i in range(3)])
hi = Vector([max(p[i] for p in pts) for i in range(3)])
centre, size = (lo + hi) / 2, hi - lo
up_axis = min(range(3), key=lambda i: size[i])
root = bpy.data.objects.new("board", None)
bpy.context.scene.collection.objects.link(root)
for o in meshes:
    if o.parent is None:
        o.parent = root
root.location = -centre
bpy.context.view_layer.update()
up = Vector([1 if i == up_axis else 0 for i in range(3)])
if up_axis != 2:  # lay it flat: its normal along z
    root.rotation_mode = "QUATERNION"
    root.rotation_quaternion = up.rotation_difference(Vector((0, 0, 1)))
    root.location = root.rotation_quaternion @ -centre
span = max(size[i] for i in range(3) if i != up_axis)

for o in meshes:  # smoother, less plastic-looking shading
    for m in o.data.materials:
        if m and m.use_nodes:
            b = m.node_tree.nodes.get("Principled BSDF")
            if b:
                b.inputs["Roughness"].default_value = 0.45

scene = bpy.context.scene
scene.render.engine = "CYCLES"
scene.cycles.samples = 64
scene.cycles.use_denoising = True
scene.render.resolution_x, scene.render.resolution_y = 1400, 1000
scene.render.film_transparent = False
world = bpy.data.worlds.new("world")
scene.world = world
world.use_nodes = True
world.node_tree.nodes["Background"].inputs[0].default_value = (0.93, 0.93, 0.92, 1)
world.node_tree.nodes["Background"].inputs[1].default_value = 0.9

for name, rot, energy in (("key", (math.radians(40), 0, math.radians(30)), 4.0),
                          ("fill", (math.radians(-50), 0, math.radians(-120)), 1.5)):
    light = bpy.data.lights.new(name, "SUN")
    light.energy = energy
    lo_ = bpy.data.objects.new(name, light)
    lo_.rotation_euler = rot
    scene.collection.objects.link(lo_)

cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
cam.data.lens = 85
scene.collection.objects.link(cam)
scene.camera = cam
dist = span * 3.2

for side, sgn in (("top", 1), ("bottom", -1)):
    # seen from the board's bottom edge (KiCad's +y), so it reads as in KiCad
    pos = Vector((0, dist * math.sin(tilt) * sgn, sgn * dist * math.cos(tilt)))
    cam.location = pos
    cam.rotation_euler = (-pos).to_track_quat("-Z", "Y").to_euler()
    scene.render.filepath = "%s-%s.png" % (out, side)
    bpy.ops.render.render(write_still=True)
