#!/usr/bin/env python3
"""Routes the boards generate.py placed (fresh ones: run that first): sets the design rules, has
Freerouting route every net (round the tracks generate.py laid), takes its
routes back in, pours GND on both layers and stitches the pours together.
Run it with KiCad's own Python after generate.py:

  /Applications/KiCad/KiCad.app/Contents/Frameworks/Python.framework/Versions/Current/bin/python3 pcb/gen/route.py

A board is only saved routed if nothing is left unconnected and KiCad's DRC
(warnings included) has nothing to report; otherwise this fails.

FREEROUTING (the jar), JAVA and KICAD_CLI can point elsewhere than the defaults.
"""

import json
import math
import os
import re
import subprocess
import sys

import pcbnew

HERE = os.path.dirname(os.path.abspath(__file__))
PCB = os.path.dirname(HERE)
FREEROUTING = os.environ.get("FREEROUTING", "/Applications/freerouting-1.5.0.jar")
JAVA = os.environ.get("JAVA", "/usr/local/opt/openjdk/bin/java")
KICAD_CLI = os.environ.get("KICAD_CLI", "/Applications/KiCad/KiCad.app/Contents/MacOS/kicad-cli")

# Freerouting isn't deterministic, and which strategy finishes a board
# varies: try them in turn until one leaves nothing unconnected
STRATEGIES = [a.split() for a in os.environ.get(
    "FREEROUTING_ARGS", "-us hybrid|-us hybrid|-is random|-us global|-is sequential|").split("|")]

BOARDS = [os.path.join(PCB, "sensor", "rollino-sensor.kicad_pcb"),
          os.path.join(PCB, "base", "rollino-base.kicad_pcb")]


def rules(board, clearance=0.15):
    """0.2 mm tracks and 0.15 mm clearance (the FPC connector's 0.5 mm pitch
    needs that), 0.6/0.3 mm vias; nothing here carries much current."""
    nc = board.GetDesignSettings().m_NetSettings.m_DefaultNetClass
    nc.SetTrackWidth(pcbnew.FromMM(0.2))
    nc.SetClearance(pcbnew.FromMM(clearance))
    nc.SetViaDiameter(pcbnew.FromMM(0.6))
    nc.SetViaDrill(pcbnew.FromMM(0.3))
    ds = board.GetDesignSettings()
    ds.m_TrackMinWidth = pcbnew.FromMM(0.15)
    ds.m_ViasMinSize = pcbnew.FromMM(0.5)
    ds.m_MinThroughDrill = pcbnew.FromMM(0.3)


EDGE_KEEPOUT = 0.3


def edge_segments(board):
    """Every board edge (outline and cutouts, footprints' too) as segments."""
    shapes = [d for d in board.GetDrawings() if d.GetLayer() == pcbnew.Edge_Cuts]
    for fp in board.GetFootprints():
        shapes += [g for g in fp.GraphicalItems() if g.GetLayer() == pcbnew.Edge_Cuts]
    for sh in shapes:
        if sh.GetShape() == pcbnew.SHAPE_T_SEGMENT:
            yield sh.GetStart(), sh.GetEnd()
        elif sh.GetShape() == pcbnew.SHAPE_T_RECT:
            # (axis-aligned: none of the footprints with one are rotated)
            st, en = sh.GetStart(), sh.GetEnd()
            c = [st, pcbnew.VECTOR2I(en.x, st.y), en, pcbnew.VECTOR2I(st.x, en.y)]
            for i in range(4):
                yield c[i], c[(i + 1) % 4]


def edge_keepouts(board):
    """Freerouting doesn't know KiCad's copper-to-edge clearance: keep its
    tracks and vias out of a strip that wide along every edge."""
    w = pcbnew.FromMM(EDGE_KEEPOUT)
    zones = []
    for a, b in edge_segments(board):
        dx, dy = b.x - a.x, b.y - a.y
        n = (dx * dx + dy * dy) ** 0.5
        if n == 0:
            continue
        ux, uy = dx / n * w, dy / n * w
        z = pcbnew.ZONE(board)
        z.SetIsRuleArea(True)
        z.SetDoNotAllowTracks(True)
        z.SetDoNotAllowVias(True)
        z.SetDoNotAllowPads(False)
        z.SetDoNotAllowFootprints(False)
        z.SetDoNotAllowCopperPour(False)
        z.SetLayerSet(pcbnew.LSET(pcbnew.F_Cu).AddLayer(pcbnew.B_Cu))
        o = z.Outline()
        o.NewOutline()
        for x, y in ((a.x - ux - uy, a.y - uy + ux), (b.x + ux - uy, b.y + uy + ux),
                     (b.x + ux + uy, b.y + uy - ux), (a.x - ux + uy, a.y - uy - ux)):
            o.Append(int(x), int(y))
        board.Add(z)
        zones.append(z)
    return zones


def text_keepouts(board):
    """Keep tracks and vias off any copper text (the logo), on its layer."""
    zones = []
    for d in board.GetDrawings():
        if d.GetClass() != "PCB_TEXT" or d.GetLayer() not in (pcbnew.F_Cu, pcbnew.B_Cu):
            continue
        bb = d.GetBoundingBox()
        m = pcbnew.FromMM(0.5)
        z = pcbnew.ZONE(board)
        z.SetIsRuleArea(True)
        z.SetDoNotAllowTracks(True)
        z.SetDoNotAllowVias(True)
        z.SetDoNotAllowPads(False)
        z.SetDoNotAllowFootprints(False)
        z.SetDoNotAllowCopperPour(False)
        z.SetLayer(d.GetLayer())
        o = z.Outline()
        o.NewOutline()
        for x, y in ((bb.GetLeft() - m, bb.GetTop() - m), (bb.GetRight() + m, bb.GetTop() - m),
                     (bb.GetRight() + m, bb.GetBottom() + m), (bb.GetLeft() - m, bb.GetBottom() + m)):
            o.Append(x, y)
        board.Add(z)
        zones.append(z)
    return zones


def gnd_pour(board):
    """GND on both layers over the whole board (the board edge clips it).
    Every piece of it is kept for now, joined to ground or not: stitch()
    ties them together and drops what's still loose."""
    gnd = board.FindNet("GND")
    bb = board.GetBoardEdgesBoundingBox()
    for layer in (pcbnew.F_Cu, pcbnew.B_Cu):
        z = pcbnew.ZONE(board)
        z.SetLayer(layer)
        z.SetNet(gnd)
        z.SetLocalClearance(pcbnew.FromMM(0.25))
        z.SetMinThickness(pcbnew.FromMM(0.2))
        z.SetPadConnection(pcbnew.ZONE_CONNECTION_FULL)
        z.SetIslandRemovalMode(pcbnew.ISLAND_REMOVAL_MODE_NEVER)
        z.SetIsRuleArea(False)
        outline = z.Outline()
        outline.NewOutline()
        for x, y in ((bb.GetLeft(), bb.GetTop()), (bb.GetRight(), bb.GetTop()),
                     (bb.GetRight(), bb.GetBottom()), (bb.GetLeft(), bb.GetBottom())):
            outline.Append(x, y)
        board.Add(z)
    pcbnew.ZONE_FILLER(board).Fill(board.Zones())


STITCH_PITCH = 4.0


def stitch(board):
    """GND vias on a grid wherever both pours are solid, clear of the parts
    and the logo, so each layer's pour is tied to the other's all over: a
    piece with no pad of its own (most of the base board's left half) is
    grounded through the other layer's. Then the pours are filled again
    without the pieces that still aren't."""
    pours = [z for z in board.Zones() if not z.GetIsRuleArea()]
    fills = [z.GetFilledPolysList(z.GetLayer()) for z in pours]
    boxes = [fp.GetBoundingBox(False, False) for fp in board.GetFootprints()]
    boxes += [d.GetBoundingBox() for d in board.GetDrawings()
              if d.GetClass() == "PCB_TEXT" and d.GetLayer() in (pcbnew.F_Cu, pcbnew.B_Cu)]
    for bb in boxes:
        bb.Inflate(pcbnew.FromMM(0.6))
    # a via's own copper and as much again round it must be pour
    ring = [(0, 0)] + [(pcbnew.FromMM(0.6 * c), pcbnew.FromMM(0.6 * s))
                       for c, s in ((1, 0), (0.7, 0.7), (0, 1), (-0.7, 0.7), (-1, 0), (-0.7, -0.7), (0, -1), (0.7, -0.7))]
    # (and not on top of a via that's in the pour already)
    there = [t.GetPosition() for t in board.GetTracks() if t.GetClass() == "PCB_VIA"]
    bb = board.GetBoardEdgesBoundingBox()
    step = pcbnew.FromMM(STITCH_PITCH)
    n = 0
    for x in range(bb.GetLeft() + step // 2, bb.GetRight(), step):
        for y in range(bb.GetTop() + step // 2, bb.GetBottom(), step):
            if any(b.Contains(pcbnew.VECTOR2I(x, y)) for b in boxes):
                continue
            if any(math.hypot(x - p.x, y - p.y) < pcbnew.FromMM(1.5) for p in there):
                continue
            if all(f.Contains(pcbnew.VECTOR2I(x + dx, y + dy)) for f in fills for dx, dy in ring):
                v = pcbnew.PCB_VIA(board)
                v.SetPosition(pcbnew.VECTOR2I(x, y))
                v.SetViaType(pcbnew.VIATYPE_THROUGH)
                v.SetLayerPair(pcbnew.F_Cu, pcbnew.B_Cu)
                v.SetWidth(pcbnew.FromMM(0.6))
                v.SetDrill(pcbnew.FromMM(0.3))
                v.SetNet(board.FindNet("GND"))
                board.Add(v)
                n += 1
    for z in pours:
        z.SetIslandRemovalMode(pcbnew.ISLAND_REMOVAL_MODE_ALWAYS)
    pcbnew.ZONE_FILLER(board).Fill(board.Zones())
    return n


def near(p, a, b):
    """How far p is from segment a-b, and how far along it (0 to 1)."""
    dx, dy = b.x - a.x, b.y - a.y
    n = dx * dx + dy * dy
    t = max(0.0, min(1.0, ((p.x - a.x) * dx + (p.y - a.y) * dy) / n)) if n else 0.0
    return math.hypot(p.x - a.x - t * dx, p.y - a.y - t * dy), t


def idle_vias(board):
    """Removes vias with copper of their net on one layer only (one of
    generate.py's that Freerouting found no use for, or one the pour doesn't
    reach on one side); how many there were."""
    fills = [(z.GetLayer(), z.GetNetCode(), z.GetFilledPolysList(z.GetLayer()))
             for z in board.Zones() if not z.GetIsRuleArea()]
    pads = [pad for fp in board.GetFootprints() for pad in fp.Pads()]
    tracks = [t for t in board.GetTracks() if t.GetClass() != "PCB_VIA"]
    idle = []
    for v in [t for t in board.GetTracks() if t.GetClass() == "PCB_VIA"]:
        p, net = v.GetPosition(), v.GetNetCode()
        sides = [any(t.GetLayer() == layer and t.GetNetCode() == net and
                     near(p, t.GetStart(), t.GetEnd())[0] < v.GetWidth() / 2 for t in tracks) or
                 any(pad.GetNetCode() == net and pad.IsOnLayer(layer) and pad.HitTest(p) for pad in pads) or
                 any(l == layer and n == net and f.Contains(p) for l, n, f in fills)
                 for layer in (pcbnew.F_Cu, pcbnew.B_Cu)]
        if not all(sides):
            idle.append(v)
    for v in idle:
        board.Delete(v)
    return len(idle)


def trim(board):
    """Cuts back track ends that lead nowhere: what's left of generate.py's
    stubs beyond where Freerouting joined them."""
    pads = [pad for fp in board.GetFootprints() for pad in fp.Pads()]
    cut = 0
    while True:
        tracks = [t for t in board.GetTracks() if t.GetClass() != "PCB_VIA"]
        vias = [t for t in board.GetTracks() if t.GetClass() == "PCB_VIA"]
        for t in tracks:
            net, a, b = t.GetNetCode(), t.GetStart(), t.GetEnd()
            # where along it other copper of its net joins: pads, vias and other tracks' ends
            joins = [near(pad.GetPosition(), a, b)[1] for pad in pads
                     if pad.GetNetCode() == net and pad.IsOnLayer(t.GetLayer()) and
                     (pad.HitTest(a) or pad.HitTest(b) or near(pad.GetPosition(), a, b)[0] < t.GetWidth() / 2)]
            joins += [near(v.GetPosition(), a, b)[1] for v in vias
                      if v.GetNetCode() == net and near(v.GetPosition(), a, b)[0] < v.GetWidth() / 2]
            for o in tracks:
                if o is not t and o.GetNetCode() == net and o.GetLayer() == t.GetLayer():
                    joins += [u for d, u in (near(q, a, b) for q in (o.GetStart(), o.GetEnd())) if d < t.GetWidth() / 2]
                    # (and its own ends on the other's length)
                    joins += [u for u, q in ((0.0, a), (1.0, b)) if near(q, o.GetStart(), o.GetEnd())[0] < o.GetWidth() / 2]
            lo, hi = (min(joins), max(joins)) if joins else (0.5, 0.5)
            if hi - lo < 1e-6:                      # joined at one point or none: all of it is tail
                board.Delete(t)
            elif lo > 1e-6 or hi < 1 - 1e-6:
                t.SetStart(pcbnew.VECTOR2I(int(a.x + lo * (b.x - a.x)), int(a.y + lo * (b.y - a.y))))
                t.SetEnd(pcbnew.VECTOR2I(int(a.x + hi * (b.x - a.x)), int(a.y + hi * (b.y - a.y))))
            else:
                continue
            cut += 1
            break
        else:
            return cut


def drc(path):
    """KiCad's own check of the saved board, against its schematic too: True
    if it has nothing to report."""
    report = os.path.splitext(path)[0] + "-drc.json"
    subprocess.run([KICAD_CLI, "pcb", "drc", "--schematic-parity", "--severity-all", "--format", "json",
                    "-o", report, path], capture_output=True)
    with open(report) as f:
        found = json.load(f)
    os.remove(report)
    found = sorted({v["type"] + ": " + v["description"] for kind in ("violations", "unconnected_items", "schematic_parity")
                    for v in found.get(kind, [])})
    print("   DRC:", "; ".join(found) or "nothing to report")
    return not found


def route_once(path, args):
    board = pcbnew.LoadBoard(path)
    # (generate.py's locked tracks and its rule areas stay: Freerouting
    # routes round them)
    areas = list(board.Zones())
    if any(not t.IsLocked() for t in board.GetTracks()) or any(not z.GetIsRuleArea() for z in areas):
        sys.exit(path + " is already routed: run generate.py again first")
    # a hair more clearance for Freerouting, whose rounding on the angled
    # connectors otherwise lands a few um under KiCad's rule
    rules(board, 0.16)
    # an area that only keeps the pours out would be exported as one that
    # keeps tracks out too: leave those out while Freerouting is at it
    pour_only = [z for z in areas if not (z.GetDoNotAllowTracks() or z.GetDoNotAllowVias())]
    for z in pour_only:
        board.Remove(z)
    keepouts = edge_keepouts(board) + text_keepouts(board)
    base = os.path.splitext(path)[0]
    dsn, ses = base + ".dsn", base + ".ses"
    if not pcbnew.ExportSpecctraDSN(board, dsn):
        sys.exit("couldn't export " + dsn)
    # Freerouting can't start a track from a fine-pitch pad that's at an odd
    # angle (it leaves such a connector unconnected), though it will end one
    # on a track: for those footprints generate.py lays a stub out of each
    # pad, and here the pads are left out of the nets Freerouting sees, so it
    # joins up the stubs instead
    odd = [fp.GetReference() for fp in board.GetFootprints() if fp.GetOrientationDegrees() % 45]
    if odd:
        text = open(dsn).read()
        text = re.sub(r"\(pins [^)]*\)", lambda m: re.sub(r" (?:%s)-[\w@]+" % "|".join(odd), "", m.group(0)), text)
        open(dsn, "w").write(text)
    subprocess.run([JAVA, "-jar", FREEROUTING, "-de", dsn, "-do", ses, "-mp", "100"] + args,
                   check=True, capture_output=True)
    if not pcbnew.ImportSpecctraSES(board, ses):
        sys.exit("couldn't import " + ses)
    for f in (dsn, ses):
        os.remove(f)
    rules(board)
    for z in keepouts:
        board.Remove(z)
    for z in pour_only:
        board.Add(z)
    return board


def route(path):
    """True if the board came out whole and clean."""
    fresh = open(path).read()
    for args in STRATEGIES:
        board = route_once(path, args)
        trim(board)
        gnd_pour(board)
        vias = stitch(board)
        # (taking an idle via out can leave the track to it going nowhere,
        # and the other way round)
        idle = gone = idle_vias(board)
        while gone:
            trim(board)
            pcbnew.ZONE_FILLER(board).Fill(board.Zones())
            gone = idle_vias(board)
            idle += gone
        board.BuildConnectivity()
        left = board.GetConnectivity().GetUnconnectedCount(False)
        print(path, args or "(defaults)", "-", left, "unconnected")
        if left:
            continue
        board.Save(path)
        print("routed", path, "-", len(board.GetTracks()), "tracks and vias, about", vias - idle, "of them stitching the pours")
        if drc(path):
            return True
        # (as generate.py left it, for the next try)
        open(path, "w").write(fresh)
    print("NOT ROUTED:", path, "- left as generate.py wrote it")
    return False


if __name__ == "__main__":
    if not all([route(b) for b in sys.argv[1:] or BOARDS]):
        sys.exit(1)
