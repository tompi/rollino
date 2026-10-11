#!/usr/bin/env python3
"""Generates the Rollino's KiCad projects: the sensor board (two of them, the
same board) and the base board, each with its schematic.

Board outlines and the positions of everything the case cares about (the
XIAO, the FPC connectors, the screws) come from the case model, so run this
again after changing case/rollino.scad. The boards come out placed, with the
tracks that matter laid (and locked), but not otherwise routed: route.py does
that.

Run it with KiCad's own Python (it needs pcbnew), from anywhere:

  /Applications/KiCad/KiCad.app/Contents/Frameworks/Python.framework/Versions/Current/bin/python3 pcb/gen/generate.py

OPENSCAD and KICAD_SYMBOLS / KICAD_FOOTPRINTS can point somewhere else than
the macOS app defaults.
"""

import json
import math
import os
import re
import subprocess
import tempfile
import uuid

import pcbnew

HERE = os.path.dirname(os.path.abspath(__file__))
PCB = os.path.dirname(HERE)
ROOT = os.path.dirname(PCB)
LIB = os.path.join(PCB, "lib")
OPENSCAD = os.environ.get("OPENSCAD", "/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD")
KICAD_SHARE = "/Applications/KiCad/KiCad.app/Contents/SharedSupport"
KICAD_SYMBOLS = os.environ.get("KICAD_SYMBOLS", os.path.join(KICAD_SHARE, "symbols"))
KICAD_FOOTPRINTS = os.environ.get("KICAD_FOOTPRINTS", os.path.join(KICAD_SHARE, "footprints"))

# where the boards sit on their pages (mm), so nothing has negative coordinates
SENSOR_ORIGIN = (150.0, 100.0)
BASE_ORIGIN = (150.0, 100.0)


def uid():
    return str(uuid.uuid4())


# ---------------------------------------------------------------- case model

def case_geometry():
    """Board outlines (as KiCad-oriented polygons) and positions, from the case."""
    scad = os.path.join(ROOT, "case", "rollino.scad")
    out = {}
    with tempfile.TemporaryDirectory() as tmp:
        for part in ("sensor_pcb", "base_pcb"):
            svg = os.path.join(tmp, part + ".svg")
            res = subprocess.run([OPENSCAD, "-o", svg, "-D", 'part="%s"' % part, scad],
                                 capture_output=True, text=True, check=True)
            out[part] = svg_polygons(open(svg).read())
            m = re.search(r'ECHO: "KICAD (\{.*\})"', res.stderr)
            out["pos"] = json.loads(m.group(1).replace('\\"', '"'))
    return out


def svg_polygons(svg):
    """OpenSCAD's SVG paths as lists of points; its SVG already has y down,
    like KiCad."""
    polys = []
    for d in re.findall(r'<path d="([^"]*)"', svg):
        for sub in re.split(r'[Zz]', d):
            pts = []
            for x, y in re.findall(r'([-\d.e]+),([-\d.e]+)', sub):
                q = (float(x), float(y))
                # OpenSCAD repeats some points: drop zero-length segments
                if not pts or math.hypot(q[0] - pts[-1][0], q[1] - pts[-1][1]) > 1e-3:
                    pts.append(q)
            if len(pts) > 2 and math.hypot(pts[0][0] - pts[-1][0], pts[0][1] - pts[-1][1]) <= 1e-3:
                pts.pop()
            if len(pts) > 2:
                polys.append(pts)
    return polys


# ---------------------------------------------------------------- symbols

def sexpr_block(text, start):
    """The balanced (...) starting at index start."""
    depth = 0
    for i in range(start, len(text)):
        if text[i] == '(':
            depth += 1
        elif text[i] == ')':
            depth -= 1
            if depth == 0:
                return text[start:i + 1]
    raise ValueError("unbalanced")


def library_symbol(lib, name):
    """A symbol from KiCad's libraries, as embedded in a schematic
    ("lib:name"), with a derived symbol flattened onto its parent."""
    text = open(os.path.join(KICAD_SYMBOLS, lib + ".kicad_sym")).read()
    i = text.find('(symbol "%s"' % name)
    block = sexpr_block(text, i)
    ext = re.search(r'\(extends "([^"]+)"\)', block)
    if ext:
        parent = name_of = ext.group(1)
        pblock = sexpr_block(text, text.find('(symbol "%s"' % parent))
        # the child's own properties replace the parent's
        props = {m.group(1): sexpr_block(block, m.start())
                 for m in re.finditer(r'\(property "([^"]+)"', block)}
        for key, prop in props.items():
            pm = re.search(r'\(property "%s"' % re.escape(key), pblock)
            if pm:
                pblock = pblock.replace(sexpr_block(pblock, pm.start()), prop)
        block = pblock.replace('(symbol "%s_' % name_of, '(symbol "%s_' % name)
        block = block.replace('(symbol "%s"' % name_of, '(symbol "%s"' % name, 1)
    return block.replace('(symbol "%s"' % name, '(symbol "%s:%s"' % (lib, name), 1)


def custom_symbol_text(name, ref, value, footprint, description, pins, body, datasheet="~"):
    """A symbol: pins are (number, name, type, x, y, angle)."""
    pin_text = "".join(
        '\n\t\t\t(pin %s line (at %g %g %d) (length 2.54)%s'
        ' (name "%s" (effects (font (size 1.27 1.27))))'
        ' (number "%s" (effects (font (size 1.27 1.27)))))'
        % (typ, x, y, a, "", pname, num) for num, pname, typ, x, y, a in pins)
    (x0, y0), (x1, y1) = body
    return '''(symbol "%s" (pin_names (offset 1.016)) (exclude_from_sim no) (in_bom yes) (on_board yes)
		(property "Reference" "%s" (at %g %g 0) (effects (font (size 1.27 1.27)) (justify left)))
		(property "Value" "%s" (at %g %g 0) (effects (font (size 1.27 1.27)) (justify left)))
		(property "Footprint" "%s" (at 0 0 0) (effects (font (size 1.27 1.27)) hide))
		(property "Datasheet" "%s" (at 0 0 0) (effects (font (size 1.27 1.27)) hide))
		(property "Description" "%s" (at 0 0 0) (effects (font (size 1.27 1.27)) hide))
		(symbol "%s_0_1"
			(rectangle (start %g %g) (end %g %g) (stroke (width 0.254) (type default)) (fill (type background))))
		(symbol "%s_1_1"%s))''' % (
        name, ref, x0, y1 + 1.27, value, x0, y0 - 1.27, footprint, datasheet, description,
        name, x0, y1, x1, y0, name, pin_text)


PMW3610_PINS = [
    # number, name, type, x, y, angle: signals on the left, power on the right
    ("2", "SDIO", "bidirectional", -12.7, 7.62, 0),
    ("3", "SCLK", "input", -12.7, 5.08, 0),
    ("5", "NCS", "input", -12.7, 2.54, 0),
    ("8", "MOTION", "output", -12.7, 0, 0),
    ("7", "NRESET", "input", -12.7, -2.54, 0),
    ("6", "VDDIO", "power_in", -12.7, -7.62, 0),
    ("4", "NC", "no_connect", -12.7, -10.16, 0),
    ("14", "VDD", "power_in", 12.7, 7.62, 180),
    ("9", "VCP", "passive", 12.7, 5.08, 180),
    ("12", "CP", "passive", 12.7, 2.54, 180),
    ("13", "CN", "passive", 12.7, 0, 180),
    ("1", "+VCSEL", "passive", 12.7, -2.54, 180),
    ("10", "PASS_T", "passive", 12.7, -5.08, 180),
    ("15", "XYLASER", "passive", 12.7, -7.62, 180),
    ("16", "-VCSEL", "passive", 12.7, -10.16, 180),
    ("11", "GND", "power_in", 0, -15.24, 90),
]

XIAO_PINS = [
    ("1", "D0", "bidirectional", -12.7, 7.62, 0),
    ("2", "D1", "bidirectional", -12.7, 5.08, 0),
    ("3", "D2", "bidirectional", -12.7, 2.54, 0),
    ("4", "D3", "bidirectional", -12.7, 0, 0),
    ("5", "D4/SDA", "bidirectional", -12.7, -2.54, 0),
    ("6", "D5/SCL", "bidirectional", -12.7, -5.08, 0),
    ("7", "D6/TX", "bidirectional", -12.7, -7.62, 0),
    ("8", "D7/RX", "bidirectional", 12.7, -7.62, 180),
    ("9", "D8/SCK", "bidirectional", 12.7, -5.08, 180),
    ("10", "D9/MISO", "bidirectional", 12.7, -2.54, 180),
    ("11", "D10/MOSI", "bidirectional", 12.7, 0, 180),
    ("12", "3V3", "power_out", 12.7, 2.54, 180),
    ("13", "GND", "power_in", 12.7, 5.08, 180),
    ("14", "5V", "power_out", 12.7, 7.62, 180),
]


def write_symbol_library():
    syms = [
        custom_symbol_text(
            "PMW3610DM-SUDU", "U", "PMW3610DM-SUDU", "rollino:PMW3610DM-SUDU",
            "PixArt PMW3610DM-SUDU low power laser mouse sensor, 16-pin DIP; use with the LM18-LSI lens",
            PMW3610_PINS, ((-10.16, -12.7), (10.16, 10.16)),
            "https://www.epsglobal.com/Media-Library/EPSGlobal/Products/files/pixart/PMW3610DM-SUDU.pdf"),
        custom_symbol_text(
            "XIAO_nRF52840", "U", "XIAO nRF52840", "rollino:XIAO_nRF52840_upside_down",
            "Seeed Studio XIAO nRF52840, edge pads only",
            XIAO_PINS, ((-10.16, -10.16), (10.16, 10.16)),
            "https://wiki.seeedstudio.com/XIAO_BLE/"),
    ]
    with open(os.path.join(LIB, "rollino.kicad_sym"), "w") as f:
        f.write('(kicad_symbol_lib (version 20231120) (generator "rollino-gen") (generator_version "8.0")\n\t')
        f.write("\n\t".join(syms))
        f.write("\n)\n")
    return {"rollino:" + s.split('"')[1]: s for s in syms}


# ---------------------------------------------------------------- 3D models

MODELS = os.path.join(LIB, "rollino.3dshapes")
MODEL_REF = "${KIPRJMOD}/../lib/rollino.3dshapes/%s.wrl"


def wrl_shape(points, faces, color, transparency=0.0):
    """A VRML shape; points in footprint mm (y down), written in KiCad's
    model units (0.1 in, y up)."""
    pts = ",\n".join("%.4f %.4f %.4f" % (x / 2.54, -y / 2.54, z / 2.54) for x, y, z in points)
    idx = ",\n".join(", ".join(str(i) for i in f) + ", -1" for f in faces)
    return ('Shape { appearance Appearance { material Material { diffuseColor %g %g %g specularColor 0.2 0.2 0.2 '
            'shininess 0.3 transparency %g } }\n geometry IndexedFaceSet { creaseAngle 0.5 coord Coordinate { point [\n%s\n] }\n'
            ' coordIndex [\n%s\n] } }\n' % (color + (transparency, pts, idx)))


def box(x0, x1, y0, y1, z0, z1):
    pts = [(x, y, z) for z in (z0, z1) for y in (y0, y1) for x in (x0, x1)]
    faces = [(0, 2, 3, 1), (4, 5, 7, 6), (0, 1, 5, 4), (2, 6, 7, 3), (0, 4, 6, 2), (1, 3, 7, 5)]
    return pts, faces


def write_models():
    os.makedirs(MODELS, exist_ok=True)
    # PMW3610: the package on the board's top, the LM18-LSI lens under it
    # (roughly, as the case's pocket for it: 20 x 17, centred on the package)
    body = wrl_shape(*box(-8.5, 7.7, -5.45, 5.45, 0, 3.0), (0.02, 0.02, 0.02))
    lens = wrl_shape(*box(-0.4 - 10, -0.4 + 10, -8.5, 8.5, -1.6 - 4.0, -1.6), (0.7, 0.85, 0.95), 0.35)
    open(os.path.join(MODELS, "PMW3610DM-SUDU.wrl"), "w").write("#VRML V2.0 utf8\n" + body + lens)

    # XIAO nRF52840 from Seeed's model (../3d/xiao-nrf52840.stl: x from the
    # USB end's board edge, z up from its underside), turned upside down onto
    # the footprint: the USB end towards -y, the component side resting on
    # the board, its parts reaching down through the cutout
    import struct
    data = open(os.path.join(PCB, "3d", "xiao-nrf52840.stl"), "rb").read()
    n = struct.unpack("<I", data[80:84])[0]
    index, points, faces = {}, [], []
    for t in range(n):
        v = struct.unpack("<12f", data[84 + 50 * t:84 + 50 * t + 48])
        face = []
        for k in range(3):
            mx, my, mz = v[3 + 3 * k:6 + 3 * k]
            # (turned over about its long axis: the footprint's y is down, so
            # that's -my, not a mirror image of the board)
            p = (round(-my, 3), round(mx - 10.475, 3), round(1.0 - mz, 3))
            if p not in index:
                index[p] = len(points)
                points.append(p)
            face.append(index[p])
        faces.append(face)
    open(os.path.join(MODELS, "XIAO_nRF52840_upside_down.wrl"), "w").write(
        "#VRML V2.0 utf8\n" + wrl_shape(points, faces, (0.25, 0.4, 0.8)))


def model_line(name):
    return '  (model "%s" (offset (xyz 0 0 0)) (scale (xyz 1 1 1)) (rotate (xyz 0 0 0)))\n' % (MODEL_REF % name)


# ---------------------------------------------------------------- footprints

def write_footprints():
    pretty = os.path.join(LIB, "rollino.pretty")
    # PMW3610: badjeff's footprint (github.com/badjeff/pmw3610-pcb, CERN-OHL-P
    # 2.0), which has the lens cutout in Edge.Cuts; origin near the package
    # centre, optical centre at (2.988, 0)
    src = os.path.join(HERE, "PMW3610DM-SUDU_badjeff.kicad_mod")
    text = open(src).read()
    text = text.replace('(footprint "PMW3610DM-SUDU 16Pin"', '(footprint "PMW3610DM-SUDU"', 1)
    text = text.replace('(descr "PMW3610DM-SUDU special 16pin molded lead-frame DIP")',
                        '(descr "PMW3610DM-SUDU 16-pin molded lead-frame DIP, with the LM18-LSI lens cutout; '
                        'optical centre at (2.988, 0). From github.com/badjeff/pmw3610-pcb (CERN-OHL-P-2.0)")')
    text = re.sub(r'\s*\(model .*?\n\s*\)\s*\)\s*\)', '', text, flags=re.S)
    text = text.rstrip()
    assert text.endswith(")")
    text = text[:-1].rstrip() + "\n" + model_line("PMW3610DM-SUDU") + ")\n"
    open(os.path.join(pretty, "PMW3610DM-SUDU.kicad_mod"), "w").write(text)

    # XIAO nRF52840 soldered upside down by its castellated edges: Seeed's
    # SMD footprint's edge pads, mirrored across the board's long axis, and
    # only reaching in as far as the cutout for its parts allows. Origin at
    # the board's centre, USB end towards -y.
    pads = []
    for n in range(1, 15):
        if n <= 7:
            x, y = 8.65, -7.545 + (n - 1) * 2.54
        else:
            x, y = -8.65, -7.545 + (14 - n) * 2.54
        pads.append('  (pad "%d" smd roundrect (at %g %g) (size 1.9 1.6) (layers "F.Cu" "F.Paste" "F.Mask") (roundrect_rratio 0.25))' % (n, x, y))
    text = '''(footprint "XIAO_nRF52840_upside_down" (version 20240108) (generator "rollino-gen") (generator_version "8.0")
  (layer "F.Cu")
  (descr "Seeed XIAO nRF52840 soldered upside down (component side down, its parts in a cutout in this board) by its castellated edge pads; USB end towards -y. Pads from Seeed's XIAO-nRF52840-SMD footprint, mirrored.")
  (attr smd)
  (property "Reference" "REF**" (at 0 -12 0) (layer "F.SilkS") (effects (font (size 1 1) (thickness 0.15))))
  (property "Value" "XIAO nRF52840" (at 0 12 0) (layer "F.Fab") (effects (font (size 1 1) (thickness 0.15))))
  (fp_rect (start -8.9 -10.475) (end 8.9 10.475) (stroke (width 0.1) (type default)) (fill none) (layer "F.Fab"))
  (fp_rect (start -9.75 -12.2) (end 9.75 10.75) (stroke (width 0.05) (type default)) (fill none) (layer "F.CrtYd"))
  (fp_rect (start -4.5 -12.05) (end 4.5 -10.475) (stroke (width 0.1) (type default)) (fill none) (layer "F.Fab"))
  (fp_text user "USB-C" (at 0 -9 0) (layer "F.Fab") (effects (font (size 1 1) (thickness 0.15))))
  (fp_line (start -8.9 10.475) (end -7.7 10.475) (stroke (width 0.15) (type default)) (layer "F.SilkS"))
  (fp_line (start 7.7 10.475) (end 8.9 10.475) (stroke (width 0.15) (type default)) (layer "F.SilkS"))
  (fp_circle (center 10.2 -7.545) (end 10.45 -7.545) (stroke (width 0.5) (type solid)) (fill solid) (layer "F.SilkS"))
%s
%s)
''' % ("\n".join(pads), model_line("XIAO_nRF52840_upside_down"))
    open(os.path.join(pretty, "XIAO_nRF52840_upside_down.kicad_mod"), "w").write(text)


# ---------------------------------------------------------------- schematic

POWER_NETS = {"GND": "power:GND", "+3V3": "power:+3V3", "+1V8": "power:+1V8"}


class Schematic:
    """Places symbols and ties each pin to its net with a short stub and a
    label (signals) or a power symbol (supplies)."""

    def __init__(self, name, title, comments):
        self.name, self.title, self.comments = name, title, comments
        self.uuid = uid()
        self.libs = {}
        self.items = []
        self.symbols = []  # (ref, lib_id, value, footprint, uuid)
        self.power_n = 0

    def lib(self, lib_id, text=None):
        if lib_id not in self.libs:
            if text is None:
                lib, name = lib_id.split(":")
                text = library_symbol(lib, name)
            else:
                text = text.replace('(symbol "%s"' % lib_id.split(":")[1], '(symbol "%s"' % lib_id, 1)
            self.libs[lib_id] = text
        return self.libs[lib_id]

    @staticmethod
    def pin_names(text):
        return {n: name for name, n in re.findall(
            r'\(pin \w+ \w+\s*\(at [-\d.]+ [-\d.]+ \d+\).*?\(name "([^"]*)".*?\(number "([^"]+)"', text, re.S)}

    @staticmethod
    def pins_of(text):
        return [(n, float(x), float(y), int(a), t) for (t, x, y, a, n) in re.findall(
            r'\(pin (\w+) \w+\s*\(at ([-\d.]+) ([-\d.]+) (\d+)\).*?\(number "([^"]+)"', text, re.S)]

    def symbol(self, ref, lib_id, value, footprint, at, pins, rot=0, text=None, power=False, value_at=None, bom=True):
        lt = self.lib(lib_id, text)
        u = uid()
        # on the 2.54 mm grid, so pins land on the connection grid (power
        # symbols sit on stub ends, which already are)
        x, y = at if power else (round(v / 2.54) * 2.54 for v in at)
        hide = " hide" if power else ""
        # a power symbol's name reads horizontally whichever way it points
        vang, vjust = 0, ""
        if power and rot in (90, 270):
            vang = rot
        # fields: a boxed part's reference above it and value below; a
        # two-pin part's beside it
        rect = re.search(r'\(rectangle \(start ([-\d.]+) ([-\d.]+)\) \(end ([-\d.]+) ([-\d.]+)\)', lt)
        if rect and not power:
            ys = (float(rect.group(2)), float(rect.group(4)))
            ref_at, rjust = (x, y - max(ys) - 1.27), ""
            value_at = value_at or (x, y - min(ys) + 1.27)
        else:
            ref_at, rjust = (x + 2.54, y - 1.27), " (justify left)"
            if not power:
                value_at = value_at or (x + 2.54, y + 1.27)
                vjust = vjust or " (justify left)"
        props = ('(property "Reference" "%s" (at %g %g 0) (effects (font (size 1.27 1.27))%s%s))'
                 '(property "Value" "%s" (at %g %g %d) (effects (font (size 1.27 1.27))%s))'
                 '(property "Footprint" "%s" (at %g %g 0) (effects (font (size 1.27 1.27)) hide))'
                 '(property "Datasheet" "~" (at %g %g 0) (effects (font (size 1.27 1.27)) hide))') % (
            ref, *ref_at, rjust, hide, value, *(value_at or (x + 2.54, y + 1.27)), vang, vjust,
            footprint, x, y, x, y)
        pin_uuids = "".join('(pin "%s" (uuid "%s"))' % (n, uid()) for n, *_ in self.pins_of(lt))
        self.items.append(
            '(symbol (lib_id "%s") (at %g %g %d) (unit 1) (exclude_from_sim no) (in_bom %s) (on_board %s) (dnp no) (uuid "%s") %s %s'
            ' (instances (project "%s" (path "/%s" (reference "%s") (unit 1)))))' % (
                lib_id, x, y, rot, "yes" if bom and not power else "no", "no" if power else "yes", u, props, pin_uuids,
                self.name, self.uuid, ref))
        if not power:
            self.symbols.append((ref, lib_id, value, footprint, u))
        # tie each listed pin to its net
        for n, px, py, a, typ in self.pins_of(lt):
            if n not in pins or (pins[n] is None and typ == "no_connect"):
                continue
            c, s = math.cos(math.radians(rot)), math.sin(math.radians(rot))
            ex, ey = x + px * c - py * s, y - (px * s + py * c)
            ang = (a + rot) % 360  # direction the pin points, from its end into the body
            dx, dy = {0: (-1, 0), 90: (0, 1), 180: (1, 0), 270: (0, -1)}[ang]
            self.connect(pins[n], (ex, ey), (dx, dy))
        return u

    def connect(self, net, end, d, stub=2.54):
        ex, ey = end
        if net is None:
            self.items.append('(no_connect (at %g %g) (uuid "%s"))' % (ex, ey, uid()))
            return
        sx, sy = ex + d[0] * stub, ey + d[1] * stub
        self.items.append('(wire (pts (xy %g %g) (xy %g %g)) (stroke (width 0) (type default)) (uuid "%s"))' % (
            ex, ey, sx, sy, uid()))
        if net in POWER_NETS:
            self.power_symbol(net, (sx, sy), d)
        else:
            angle = {(-1, 0): 180, (1, 0): 0, (0, -1): 90, (0, 1): 270}[d]
            just = "right" if angle in (180, 270) else "left"
            self.items.append('(label "%s" (at %g %g %d) (effects (font (size 1.27 1.27)) (justify %s bottom)) (uuid "%s"))' % (
                net, sx, sy, angle, just, uid()))

    def power_symbol(self, net, at, d=None):
        """A power symbol whose body points along d (outwards from its pin);
        by default GND hangs down and supplies stand up."""
        if d is None:
            d = (0, 1) if net == "GND" else (0, -1)
        if net == "GND":  # its body points down when unrotated
            rot = {(0, 1): 0, (1, 0): 90, (0, -1): 180, (-1, 0): 270}[d]
        else:  # supplies point up
            rot = {(0, -1): 0, (-1, 0): 90, (0, 1): 180, (1, 0): 270}[d]
        self.power_n += 1
        x, y = at
        self.symbol("#PWR%02d" % self.power_n, POWER_NETS[net], net, "", at, {}, rot=rot, power=True,
                    value_at=(x + d[0] * 6.4, y + d[1] * 4.6))

    def flag(self, net, at):
        self.power_n += 1
        x, y = (round(v / 2.54) * 2.54 for v in at)
        self.symbol("#FLG%02d" % self.power_n, "power:PWR_FLAG", "PWR_FLAG", "", (x, y), {}, power=True)
        self.items.append('(wire (pts (xy %g %g) (xy %g %g)) (stroke (width 0) (type default)) (uuid "%s"))' % (
            x, y, x, y + 2.54, uid()))
        self.connect_point(net, (x, y + 2.54))

    def connect_point(self, net, at):
        if net in POWER_NETS:
            self.power_symbol(net, at)

    def text(self, s, at, size=1.27):
        self.items.append('(text "%s" (exclude_from_sim no) (at %g %g 0) (effects (font (size %g %g)) (justify left bottom)) (uuid "%s"))' % (
            s.replace('"', '\\"'), at[0], at[1], size, size, uid()))

    def write(self, path):
        comments = "".join('(comment %d "%s")' % (i + 1, c) for i, c in enumerate(self.comments))
        with open(path, "w") as f:
            f.write('(kicad_sch (version 20231120) (generator "rollino-gen") (generator_version "8.0") (uuid "%s") (paper "A4")\n' % self.uuid)
            f.write('(title_block (title "%s") (rev "1") %s)\n' % (self.title, comments))
            f.write("(lib_symbols\n%s\n)\n" % "\n".join(self.libs.values()))
            f.write("\n".join(self.items))
            f.write('\n(sheet_instances (path "/" (page "1")))\n)\n')


# ---------------------------------------------------------------- boards

class Board:
    def __init__(self, title, origin):
        self.board = pcbnew.BOARD()
        self.origin = origin
        self.nets = {}
        # 0.3 mm copper to edge: the PMW3610's pads sit that close to the
        # lens cutout in PixArt's own layout
        self.board.GetDesignSettings().m_CopperEdgeClearance = pcbnew.FromMM(0.3)
        tb = self.board.GetTitleBlock()
        tb.SetTitle(title)
        tb.SetRevision("1")

    def p(self, x, y):
        return pcbnew.VECTOR2I(pcbnew.FromMM(self.origin[0] + x), pcbnew.FromMM(self.origin[1] + y))

    def net(self, name):
        # the schematic's labels are local: their nets are "/NAME"
        if name not in POWER_NETS and not name.startswith("unconnected-"):
            name = "/" + name
        if name not in self.nets:
            n = pcbnew.NETINFO_ITEM(self.board, name)
            self.board.Add(n)
            self.nets[name] = n
        return self.nets[name]

    def outline(self, polys):
        for pts in polys:
            for a, b in zip(pts, pts[1:] + pts[:1]):
                s = pcbnew.PCB_SHAPE(self.board)
                s.SetShape(pcbnew.SHAPE_T_SEGMENT)
                s.SetStart(self.p(*a))
                s.SetEnd(self.p(*b))
                s.SetLayer(pcbnew.Edge_Cuts)
                s.SetWidth(pcbnew.FromMM(0.1))
                self.board.Add(s)

    def footprint(self, lib_id, ref, value, at, rot=0, pins=None, sym_uuid=None, pin_names=None, fab_ref=False):
        lib, name = lib_id.split(":")
        path = os.path.join(LIB, "rollino.pretty") if lib == "rollino" else os.path.join(KICAD_FOOTPRINTS, lib + ".pretty")
        fp = pcbnew.FootprintLoad(path, name)
        fp.SetFPID(pcbnew.LIB_ID(lib, name))
        fp.SetReference(ref)
        fp.SetValue(value)
        fp.SetPosition(self.p(*at))
        fp.SetOrientationDegrees(rot)
        if sym_uuid:
            fp.SetPath(pcbnew.KIID_PATH("/" + sym_uuid))
        for pad in fp.Pads():
            # connectors' mounting tabs go to GND rather than float
            num = pad.GetNumber()
            net = (pins or {}).get(num, "GND" if num == "MP" else None)
            if net:
                pad.SetNet(self.net(net))
            elif num in (pin_names or {}):
                # an unconnected pin: its own net, named as the schematic's netlist names it
                pad.SetNet(self.net("unconnected-(%s-%s-Pad%s)" % (ref, pin_names[num].replace("/", "{slash}"), num)))
        if fab_ref:  # no room for it on the silkscreen
            fp.Reference().SetLayer(pcbnew.F_Fab)
        self.board.Add(fp)
        return fp

    def track(self, net, pts, width=0.2, layer=pcbnew.F_Cu):
        """A locked track through pts (board mm), which route.py keeps."""
        for a, b in zip(pts, pts[1:]):
            t = pcbnew.PCB_TRACK(self.board)
            t.SetStart(self.p(*a))
            t.SetEnd(self.p(*b))
            t.SetWidth(pcbnew.FromMM(width))
            t.SetLayer(layer)
            t.SetNet(self.net(net))
            t.SetLocked(True)
            self.board.Add(t)

    def via(self, net, at):
        """A locked via at at (board mm), which route.py keeps."""
        v = pcbnew.PCB_VIA(self.board)
        v.SetPosition(self.p(*at))
        v.SetViaType(pcbnew.VIATYPE_THROUGH)
        v.SetLayerPair(pcbnew.F_Cu, pcbnew.B_Cu)
        v.SetWidth(pcbnew.FromMM(0.6))
        v.SetDrill(pcbnew.FromMM(0.3))
        v.SetNet(self.net(net))
        v.SetLocked(True)
        self.board.Add(v)

    def keepout(self, name, pts, layers=(pcbnew.F_Cu, pcbnew.B_Cu), tracks=False, vias=False, pour=False):
        """A rule area (board mm) that keeps tracks, vias and/or the pours out."""
        z = pcbnew.ZONE(self.board)
        z.SetIsRuleArea(True)
        z.SetZoneName(name)
        z.SetDoNotAllowTracks(tracks)
        z.SetDoNotAllowVias(vias)
        z.SetDoNotAllowCopperPour(pour)
        z.SetDoNotAllowPads(False)
        z.SetDoNotAllowFootprints(False)
        ls = pcbnew.LSET(layers[0])
        for layer in layers[1:]:
            ls.AddLayer(layer)
        z.SetLayerSet(ls)
        o = z.Outline()
        o.NewOutline()
        for x, y in pts:
            o.Append(self.p(x, y))
        self.board.Add(z)

    def pads(self, fp):
        """A footprint's pads as [(number, net name, (x, y))], board mm."""
        return [(pad.GetNumber(), pad.GetNetname(),
                 (pcbnew.ToMM(pad.GetPosition().x) - self.origin[0], pcbnew.ToMM(pad.GetPosition().y) - self.origin[1]))
                for pad in fp.Pads()]

    def text(self, s, at, size=1.0, layer=pcbnew.F_SilkS, angle=0, thickness=0.15):
        t = pcbnew.PCB_TEXT(self.board)
        t.SetText(s)
        t.SetPosition(self.p(*at))
        t.SetLayer(layer)
        t.SetTextSize(pcbnew.VECTOR2I(pcbnew.FromMM(size), pcbnew.FromMM(size)))
        t.SetTextThickness(pcbnew.FromMM(size * thickness))
        t.SetTextAngleDegrees(angle)
        t.SetMirrored(layer in (pcbnew.B_Cu, pcbnew.B_Mask, pcbnew.B_SilkS))
        self.board.Add(t)

    def save(self, path):
        self.board.Save(path)


def fpc_pins(rot, e, extra):
    """An FPC connector's pins, numbered so that each signal meets itself
    through the ribbon: the nets go in FPC_PINS order along e (the way, in
    the board's frame with y up, the ribbon's conductors run there in the
    order they run along the sensor board's +y). The pads are 1 to 6 along
    the footprint's +x, which rotation rot (KiCad's: anticlockwise, y down)
    turns to (cos, sin) in y-up terms."""
    th = math.radians(rot)
    order = FPC_PINS if math.cos(th) * e[0] + math.sin(th) * e[1] > 0 else FPC_PINS[::-1]
    pins = {str(k + 1): extra.get(n, n) for k, n in enumerate(order)}
    pins["MP"] = "GND"
    return pins


def mouth_rotation(ux, uy):
    """Footprint rotation (degrees) that turns a footprint's +y (screen)
    towards KiCad direction (ux, uy)."""
    return math.degrees(math.atan2(ux, uy))


def write_project(dirname, name):
    os.makedirs(dirname, exist_ok=True)
    pro = {"meta": {"filename": name + ".kicad_pro", "version": 1},
           "board": {"design_settings": {"defaults": {}}},
           "schematic": {"legacy_lib_dir": "", "legacy_lib_list": []}}
    json.dump(pro, open(os.path.join(dirname, name + ".kicad_pro"), "w"), indent=2)
    open(os.path.join(dirname, "sym-lib-table"), "w").write(
        '(sym_lib_table\n  (version 7)\n  (lib (name "rollino")(type "KiCad")(uri "${KIPRJMOD}/../lib/rollino.kicad_sym")(options "")(descr "Rollino parts"))\n)\n')
    open(os.path.join(dirname, "fp-lib-table"), "w").write(
        '(fp_lib_table\n  (version 7)\n  (lib (name "rollino")(type "KiCad")(uri "${KIPRJMOD}/../lib/rollino.pretty")(options "")(descr "Rollino parts"))\n)\n')


# ---------------------------------------------------------------- the boards

FPC_PINS = ["+3V3", "GND", "SCLK", "SDIO", "NCS", "MOTION"]
FPC_FP = "Connector_FFC-FPC:Hirose_FH12-6S-0.5SH_1x06-1MP_P0.50mm_Horizontal"
FPC_VALUE = "FH12-6S-0.5SH"
# with a pin for the connector's mounting tabs, which go to GND
FPC_SYMBOL = "Connector_Generic_MountingPin:Conn_01x06_MountingPin"
# the FH12's body runs from its solder tails (local y -2.5) to its mouth (4.35)
FPC_TAIL, FPC_MOUTH = -2.5, 4.35


def sensor(geo, symlib):
    s = geo["pos"]["sensor"]
    name = "rollino-sensor"
    d = os.path.join(PCB, "sensor")
    write_project(d, name)
    sch = Schematic(name, "Rollino sensor board", [
        "Two needed, the same board for both sensors.",
        "PMW3610 circuit after github.com/badjeff/pmw3610-pcb (CERN-OHL-P-2.0),",
        "with a 1 uA quiescent LDO (TPS7A0518) for the battery.",
    ])
    b = Board("Rollino sensor board", SENSOR_ORIGIN)
    b.outline(geo["sensor_pcb"])

    C0603 = "Capacitor_SMD:C_0603_1608Metric"
    R0603 = "Resistor_SMD:R_0603_1608Metric"

    def pin(n):
        """U1's pin n on the board (datasheet fig. 5): 1 to 8 along the ear's
        side, 9 to 16 back along the other."""
        return (3.18 - 1.78 * (n - 1), -5.35) if n <= 8 else (1.78 * (n - 9) - 10.17, 5.35)

    # the rows of parts either side of the chip, how far a capacitor's pads
    # are from its middle, and where along their rows C3, C8, C9 and C4 go
    TOP, BOT, PAD = -7.4, 8.1, 0.775
    c3, c8, c9, c4 = -8.7, -5.7, -2.7, (pin(12)[0] + pin(13)[0]) / 2
    parts = [
        # ref, lib_id, value, footprint, schematic position, pins, board position, rotation
        ("U1", "rollino:PMW3610DM-SUDU", "PMW3610DM-SUDU", "rollino:PMW3610DM-SUDU", (135, 115),
         {"2": "SDIO", "3": "SCLK", "5": "NCS", "8": "MOTION", "7": "NRESET", "6": "+3V3", "4": None,
          "14": "+1V8", "9": "VCP", "12": "CP", "13": "CN", "1": "VCSEL+", "10": "VCSEL+",
          "15": "VCSEL-", "16": "VCSEL-", "11": "GND"},
         (-2.988, 0), 0),
        # the case's screw boss is behind the ear (y -7.9 and beyond, x -6.9..-0.9): nothing there
        ("U2", "Regulator_Linear:TPS7A0518PDBV", "TPS7A0518PDBVR", "Package_TO_SOT_SMD:SOT-23-5", (120, 50),
         {"1": "+3V3", "3": "+3V3", "2": "GND", "4": None, "5": "+1V8"}, (0.9, -8.35), 180),
        # mouth facing off the up-slope edge, 0.5 mm in from it, where the
        # ribbon is easy to push in and latch
        ("J1", FPC_SYMBOL, FPC_VALUE, FPC_FP, (60, 110), fpc_pins(270, (0, 1), {}), (s["sc"] - s["pcb_end"] + 0.5 + FPC_MOUTH, 0), 270),
        # upright at the row's end, out of the way of the tracks to the pins
        ("R1", "Device:R", "10k", R0603, (215, 50), {"1": "+3V3", "2": "NRESET"}, (-11.4, -8.0), 270),
        # VDDIO's capacitors by pin 6 (C8 is the regulator's input capacitor
        # too), and the regulator's output capacitor against its pin
        ("C3", "Device:C", "100nF", C0603, (80, 50), {"1": "+3V3", "2": "GND"}, (c3, TOP), 180),
        ("C8", "Device:C", "1uF", C0603, (92, 50), {"1": "+3V3", "2": "GND"}, (c8, TOP), 0),
        ("C9", "Device:C", "1uF", C0603, (174, 50), {"1": "+1V8", "2": "GND"}, (c9, TOP), 180),
        # on the other side each is upright under the pin it serves, that pad
        # towards the pin and its ground along the board's edge
        ("C6", "Device:C", "10uF X7R", C0603, (200, 100), {"1": "VCP", "2": "GND"}, (-12.0, BOT), 270),
        ("C7", "Device:C", "10nF X7R", C0603, (215, 100), {"1": "VCP", "2": "GND"}, (pin(9)[0], BOT), 270),
        ("C5", "Device:C", "10nF", C0603, (215, 135), {"1": "VCSEL+", "2": "GND"}, (pin(10)[0], BOT), 270),
        # (lying under the charge pump's two pins, a pad under each)
        ("C4", "Device:C", "100nF X7R", C0603, (200, 135), {"1": "CP", "2": "CN"}, (c4, -TOP), 0),
        ("C2", "Device:C", "100nF", C0603, (162, 50), {"1": "+1V8", "2": "GND"}, (pin(14)[0], BOT), 270),
        ("C1", "Device:C", "3.3uF", C0603, (150, 50), {"1": "+1V8", "2": "GND"}, (0.5, BOT), 270),
    ]
    for ref, lib_id, value, fp, at, pins, bat, brot in parts:
        text = symlib.get(lib_id)
        u = sch.symbol(ref, lib_id, value, fp, at, pins, text=text)
        # the board's too crowded for references on its silkscreen
        b.footprint(fp, ref, value, bat, brot, pins, u, Schematic.pin_names(sch.lib(lib_id, text)), fab_ref=True)
    # U2's EN (pin 3) is boxed in by the board edge: tie it to VIN (pin 1)
    # down the gap between the package's two rows of pins, which Freerouting
    # won't use
    ux, uy = 0.9, -8.35
    b.track("+3V3", [(ux + 1.1375, uy - 0.95), (ux, uy - 0.95), (ux, uy + 0.95), (ux + 1.1375, uy + 0.95)])

    # The tracks that matter are laid here (locked: route.py keeps them) and
    # Freerouting does the rest. PixArt wants CP, CN and VCP's under 5 mm
    # long and over 20 mil wide: straight from each pin to its capacitor
    b.track("VCP", [pin(9), (pin(9)[0], BOT - PAD), (-12.0, BOT - PAD)], 0.6)
    b.track("CP", [pin(12), (pin(12)[0], 6.7), (c4 - PAD, -TOP)], 0.6)
    b.track("CN", [pin(13), (pin(13)[0], 6.7), (c4 + PAD, -TOP)], 0.6)
    b.track("VCSEL+", [pin(10), (pin(10)[0], BOT - PAD)], 0.5)
    b.track("VCSEL-", [pin(15), pin(16)], 0.5)
    # VDD's capacitors and a test pad
    b.track("+1V8", [pin(14), (pin(14)[0], BOT - PAD), (0.5, BOT - PAD), (2.4, BOT - PAD), (2.4, 7.75)], 0.5)
    # ground: from pin 11 past a test pad to a rail along the capacitors'
    # outer pads, with vias to the pour on the back
    gy = BOT + PAD
    b.track("GND", [pin(11), (pin(11)[0], gy)], 0.5)
    b.track("GND", [(-12.0, gy), (1.45, gy)], 0.4)
    for x in (-11.085, -9.28, -7.45, -2.2, -0.385, 1.45):
        b.via("GND", (x, gy))
    # 3.3 V: C3 and C8 to VDDIO (pin 6), and on round the row's far side,
    # between the regulator's pins 4 and 5, to its VIN-EN track
    b.track("+3V3", [(c3 + PAD, TOP), (c8 - PAD, TOP), (pin(6)[0], -6.45), pin(6)], 0.4)
    b.track("+3V3", [(c8 - PAD, TOP), (c8 - PAD, uy), (ux, uy)], 0.3)
    # 1.8 V: the regulator's output to C9 beside it, then on the back round
    # the lens cutout's short end to VDD (pin 14), keeping to the edge of the
    # pour rather than cutting it up
    b.track("+1V8", [(c9 + PAD, TOP), (ux - 1.1375, TOP)], 0.5)
    b.via("+1V8", (-1.19, TOP))
    b.track("+1V8", [(-1.19, TOP), (-0.89, -7.1), (4.9, -7.1), (6.5, -5.0), (6.5, 5.0), (5.2, 6.6),
                     (pin(14)[0], 6.6), pin(14)], 0.3, pcbnew.B_Cu)
    # the top row's grounds, each with a via beside it
    for pts in ([(c8 + PAD, TOP), (-4.2, TOP), (c9 - PAD, TOP)], [(c3 - PAD, TOP), (-10.3, TOP)],
                [(ux + 1.1375, uy), (3.3, uy)]):
        b.track("GND", pts, 0.4)
    for at in ((-4.2, TOP), (-10.3, TOP), (3.3, uy)):
        b.via("GND", at)
    # test pads for bringing a board up (on the fab layer: +1V8, GND)
    for i, (net, at) in enumerate([("+1V8", (2.4, 7.75)), ("GND", (pin(11)[0], 7.75))]):
        ref = "TP%d" % (i + 1)
        u = sch.symbol(ref, "Connector:TestPoint", net, "TestPoint:TestPoint_Pad_D1.0mm", (245, 100 + 35 * i), {"1": net}, bom=False)
        b.footprint("TestPoint:TestPoint_Pad_D1.0mm", ref, net, at, 0, {"1": net}, u, fab_ref=True)
    u = sch.symbol("H1", "Mechanical:MountingHole", "M2", "MountingHole:MountingHole_2.2mm_M2", (230, 50), {}, bom=False)
    b.footprint("MountingHole:MountingHole_2.2mm_M2", "H1", "M2", (s["ear"][0], -s["ear"][1]), sym_uuid=u)
    sch.flag("+3V3", (40, 30))
    sch.flag("GND", (25, 30))
    sch.text("J1 (FPC): pins numbered so each signal meets itself through the ribbon (see pcb/readme.md)", (25, 160))
    sch.text("Board frame: origin on the optical axis, x down the slope; mounted chip side out, lens towards the ball", (25, 166))
    sch.write(os.path.join(d, name + ".kicad_sch"))
    # a small logo in bare copper on the back, across the up-slope end,
    # between the edge and the lens
    lens_end = s["sc"] - 10
    for layer in (pcbnew.B_Cu, pcbnew.B_Mask):
        b.text("ROLLINO", ((s["sc"] - s["pcb_end"] + lens_end) / 2, 0), 1.5, layer, 90, 0.2)
    b.save(os.path.join(d, name + ".kicad_pcb"))


def base(geo, symlib):
    pos = geo["pos"]
    name = "rollino-base"
    d = os.path.join(PCB, "base")
    write_project(d, name)
    sch = Schematic(name, "Rollino base board", [
        "XIAO nRF52840 soldered upside down (parts through the cutout),",
        "FPC connectors to the two sensor boards, pads for optional buttons.",
    ])
    b = Board("Rollino base board", BASE_ORIGIN)
    b.outline(geo["base_pcb"])

    def kp(w):  # world x/y -> board coordinates
        return (w[0], -w[1])

    # The bus is on D4 and D5, the only pins of the XIAO's that Nordic doesn't
    # keep for low frequencies (they are away from the radio), and each
    # sensor's own lines and the buttons are on the pins of their side, so
    # only the bus and the supply cross from one side to the other
    xiao_pins = {"1": "BTN_L", "2": "BTN_M", "3": "MOTION_L", "4": None, "5": "SCLK", "6": "SDIO",
                 "7": "NCS_L", "8": "NCS_R", "9": "MOTION_R", "10": "BTN_R", "11": None,
                 "12": "+3V3", "13": "GND", "14": None}
    u = sch.symbol("U1", "rollino:XIAO_nRF52840", "XIAO nRF52840", "rollino:XIAO_nRF52840_upside_down",
                   (110, 95), xiao_pins, text=symlib["rollino:XIAO_nRF52840"])
    # USB end towards the front (board +y): the footprint's -y turned round
    xiao = b.footprint("rollino:XIAO_nRF52840_upside_down", "U1", "XIAO nRF52840", kp(pos["xiao_center"]), 180, xiao_pins, u,
                       Schematic.pin_names(symlib["rollino:XIAO_nRF52840"]))
    # The XIAO's chip antenna is at its far end, in the notch, a fraction of
    # a millimetre from this board: no pour near it (the strip of board
    # between the notch and the ball's hole, and beside the XIAO's last few
    # millimetres), and the tracks that have to cross that strip keep a
    # millimetre from the notch
    end = kp(pos["xiao_center"])[1] - 20.95 / 2
    b.keepout("antenna", [(-12, end - 7.2), (12, end - 7.2), (12, end + 4.3), (-12, end + 4.3)], pour=True)
    b.keepout("antenna", [(-10, end - 1.0), (10, end - 1.0), (10, end + 1.9), (-10, end + 1.9)], tracks=True, vias=True, pour=True)
    # With no pour on that strip, nothing but tracks joins the board's two
    # halves: the supply's are laid here rather than left to Freerouting.
    # Each goes from the XIAO's pad to a via beside it, up the right side on
    # the back, across the strip beside the keepout and down the left side.
    # The left half has no ground pad but the connector's, far up the band:
    # its pours hang on this ground track, which runs on down past the XIAO
    # with vias between the rows of pads
    # (how far out each runs down the sides and how far in it turns at 45
    # degrees on to its way across, where that is, and where it ends)
    def between(row):
        """y midway between the XIAO's rows of pads row and row + 1 (from this end)."""
        return end + 2.78 + 2.54 * (row - 0.5)

    for net, x, xi, lane, down in (("GND", 11.2, 10.4, end - 1.3, between(6)), ("+3V3", 12.0, 10.6, end - 1.9, between(3))):
        pad = next(at for num, name, at in b.pads(xiao) if name == net)
        b.track(net, [pad, (x, pad[1])], 0.3)
        b.track(net, [(x, pad[1]), (x, lane + x - xi), (xi, lane), (-xi, lane), (-x, lane + x - xi), (-x, down)],
                0.3, pcbnew.B_Cu)
        b.via(net, (x, pad[1]))
    for row in (2, 4, 6):
        b.via("GND", (-11.2, between(row)))

    # FPC connectors at the band's ends, along it, mouths facing the ribbons;
    # right sensor first
    for i, (foot, ang, e) in enumerate(pos["fpc"]):
        side = "R" if foot[0] > 0 else "L"
        ref = "J%d" % (i + 1)
        ux, uy = math.cos(math.radians(ang)), -math.sin(math.radians(ang))  # board direction of the mouth
        rot = mouth_rotation(ux, uy)
        pins = fpc_pins(rot, e, {"NCS": "NCS_" + side, "MOTION": "MOTION_" + side})
        u = sch.symbol(ref, FPC_SYMBOL, FPC_VALUE, FPC_FP, (215, 70 + 45 * i), pins)
        mid = (FPC_TAIL + FPC_MOUTH) / 2
        fx, fy = kp(foot)
        # (its reference would hang over the band's edge: the label names it)
        fp = b.footprint(FPC_FP, ref, FPC_VALUE, (fx - mid * ux, fy - mid * uy), rot, pins, u, fab_ref=True)
        # A track out of each pad's tail, fanned out to twice the pads' pitch
        # (the outer ones turning first). Freerouting can't start a track
        # from pads this close at an odd angle, and left this connector
        # unconnected: route.py has it join these up instead. They run
        # along the board's nearest axis (10 degrees off the pads') and turn
        # at 45, as its own tracks do
        tails = [(num, at) for num, net, at in b.pads(fp) if num != "MP"]
        ax, ay = (0, -math.copysign(1, uy)) if abs(uy) > abs(ux) else (-math.copysign(1, ux), 0)
        cx, cy = (sum(at[k] for num, at in tails) / len(tails) for k in (0, 1))
        for num, (px, py) in tails:
            # from just inside the pad's end; s across the fan, t along it
            px, py = px - 0.45 * ux, py - 0.45 * uy
            s = (px - cx) * -ay + (py - cy) * ax
            t0 = (px - cx) * ax + (py - cy) * ay
            turn = 2.1 - 0.6 * abs(s)                    # about 1.8, 1.5 and 1.2 down
            # (ground's ends at a via into the back's pour: by the left
            # connector that's further on, past the logo, which has none)
            far = 8.6 if pins[num] == "GND" and side == "L" else 3.3
            pts = [(cx - s * k * ay + t * ax, cy + s * k * ax + t * ay)
                   for k, t in ((1, t0), (1, turn), (2, turn + abs(s)), (2, far))]
            b.track(pins[num], pts)
            if pins[num] == "GND":
                b.via("GND", pts[-1])
        # and a via for the connector's tabs: beside the one by the ball's hole
        tab = min((at for num, net, at in b.pads(fp) if num == "MP"), key=lambda at: math.hypot(*at))
        b.track("GND", [tab, (tab[0] + 1.75 * ax, tab[1] + 1.75 * ay)], 0.3)
        b.via("GND", (tab[0] + 1.75 * ax, tab[1] + 1.75 * ay))
        # its label on the band, a little way round towards the front
        az = math.atan2(foot[0], -foot[1])
        az -= math.copysign(math.radians(15), az)
        b.text(side, kp((28.25 * math.sin(az), -28.25 * math.cos(az))), 1.2)

    # optional buttons (to GND) and a GND pad, on the band near the front
    for i, (net, az) in enumerate([("BTN_L", -35), ("BTN_M", -50), ("BTN_R", 35), ("GND", 50)]):
        ref = "TP%d" % (i + 1)
        u = sch.symbol(ref, "Connector:TestPoint", net, "TestPoint:TestPoint_Pad_D1.5mm", (60 + 20 * i, 145), {"1": net}, bom=False)
        w = (27.5 * math.sin(math.radians(az)), -27.5 * math.cos(math.radians(az)))
        b.footprint("TestPoint:TestPoint_Pad_D1.5mm", ref, net, kp(w), 0, {"1": net}, u, fab_ref=True)
        b.text(net.replace("BTN_", ""), (kp(w)[0], kp(w)[1] - 2.0), 0.8)

    for i, w in enumerate(pos["screws"]):
        u = sch.symbol("H%d" % (i + 1), "Mechanical:MountingHole", "M2", "MountingHole:MountingHole_2.2mm_M2",
                       (150 + 15 * i, 145), {}, bom=False)
        b.footprint("MountingHole:MountingHole_2.2mm_M2", "H%d" % (i + 1), "M2", kp(w), sym_uuid=u)

    sch.flag("GND", (40, 30))
    sch.text("XIAO pins as in zmk/boards/shields/rollino/rollino.overlay; NCS/MOTION _R = right sensor (J1), _L = left (J2)", (25, 175))
    sch.text("J1/J2 (FPC): 1 +3V3, 2 GND, 3 SCLK, 4 SDIO, 5 NCS, 6 MOTION - or reversed, so each signal meets itself through the ribbon", (25, 181))
    sch.text("SDIO goes to both SPI MOSI (D5) and MISO: the firmware puts them on the same pin", (25, 187))
    sch.write(os.path.join(d, name + ".kicad_sch"))
    # the logo in bare copper on the back of the band's left side, clear of
    # the screw hole below it; route.py keeps the tracks out of its way
    for layer in (pcbnew.B_Cu, pcbnew.B_Mask):
        b.text("ROLLINO", kp((-28.6, 2.6)), 2.2, layer, 90, 0.2)
    b.save(os.path.join(d, name + ".kicad_pcb"))


def main():
    geo = case_geometry()
    write_models()
    write_footprints()
    symlib = write_symbol_library()
    sensor(geo, symlib)
    base(geo, symlib)
    print("sensor and base boards written to", PCB)


if __name__ == "__main__":
    main()
