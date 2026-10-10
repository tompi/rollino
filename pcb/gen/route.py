#!/usr/bin/env python3
"""Routes the boards generate.py placed (fresh ones: run that first): sets the design rules, has
Freerouting route every net, takes its routes back in and pours GND on both
layers. Run it with KiCad's own Python after generate.py:

  /Applications/KiCad/KiCad.app/Contents/Frameworks/Python.framework/Versions/Current/bin/python3 pcb/gen/route.py

FREEROUTING (the jar) and JAVA can point elsewhere than the defaults.
"""

import os
import subprocess
import sys

import pcbnew

HERE = os.path.dirname(os.path.abspath(__file__))
PCB = os.path.dirname(HERE)
FREEROUTING = os.environ.get("FREEROUTING", "/Applications/freerouting-1.5.0.jar")
JAVA = os.environ.get("JAVA", "/usr/local/opt/openjdk/bin/java")

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
    """GND on both layers over the whole board (the board edge clips it)."""
    gnd = board.FindNet("GND")
    bb = board.GetBoardEdgesBoundingBox()
    for layer in (pcbnew.F_Cu, pcbnew.B_Cu):
        z = pcbnew.ZONE(board)
        z.SetLayer(layer)
        z.SetNet(gnd)
        z.SetLocalClearance(pcbnew.FromMM(0.25))
        z.SetMinThickness(pcbnew.FromMM(0.2))
        z.SetPadConnection(pcbnew.ZONE_CONNECTION_FULL)
        z.SetIslandRemovalMode(pcbnew.ISLAND_REMOVAL_MODE_ALWAYS)
        z.SetIsRuleArea(False)
        outline = z.Outline()
        outline.NewOutline()
        for x, y in ((bb.GetLeft(), bb.GetTop()), (bb.GetRight(), bb.GetTop()),
                     (bb.GetRight(), bb.GetBottom()), (bb.GetLeft(), bb.GetBottom())):
            outline.Append(x, y)
        board.Add(z)
    pcbnew.ZONE_FILLER(board).Fill(board.Zones())


def route_once(path, args):
    board = pcbnew.LoadBoard(path)
    # (generate.py's few locked tracks stay: Freerouting routes round them)
    if any(not t.IsLocked() for t in board.GetTracks()) or board.GetAreaCount():
        sys.exit(path + " is already routed: run generate.py again first")
    # a hair more clearance for Freerouting, whose rounding on the angled
    # connectors otherwise lands a few um under KiCad's rule
    rules(board, 0.16)
    keepouts = edge_keepouts(board) + text_keepouts(board)
    base = os.path.splitext(path)[0]
    dsn, ses = base + ".dsn", base + ".ses"
    if not pcbnew.ExportSpecctraDSN(board, dsn):
        sys.exit("couldn't export " + dsn)
    subprocess.run([JAVA, "-jar", FREEROUTING, "-de", dsn, "-do", ses, "-mp", "100"] + args,
                   check=True, capture_output=True)
    if not pcbnew.ImportSpecctraSES(board, ses):
        sys.exit("couldn't import " + ses)
    for f in (dsn, ses):
        os.remove(f)
    rules(board)
    for z in keepouts:
        board.Remove(z)
    board.BuildConnectivity()
    return board, board.GetConnectivity().GetUnconnectedCount(False)


def route(path):
    for args in STRATEGIES:
        board, left = route_once(path, args)
        print(path, args or "(defaults)", "-", left, "unconnected")
        if left == 0:
            break
    gnd_pour(board)
    board.Save(path)
    print("routed", path, "-", len(board.GetTracks()), "tracks and vias")


if __name__ == "__main__":
    for b in sys.argv[1:] or BOARDS:
        route(b)
