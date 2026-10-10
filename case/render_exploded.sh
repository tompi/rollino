#!/bin/sh
# Renders the exploded view, renders/exploded.png, in Blender, with KiCad's
# 3D models of the boards (needs OpenSCAD, KiCad 8, Blender 3.x and
# ImageMagick). Run after changing the case or the boards.
set -e
cd "$(dirname "$0")"
OPENSCAD=${OPENSCAD:-/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD}
KICAD_CLI=${KICAD_CLI:-/Applications/KiCad/KiCad.app/Contents/MacOS/kicad-cli}
BLENDER=${BLENDER:-/Applications/Blender.app/Contents/MacOS/Blender}
export KICAD8_3DMODEL_DIR=${KICAD8_3DMODEL_DIR:-/Applications/KiCad/KiCad.app/Contents/SharedSupport/3dmodels}
tmp=$(mktemp -d)
"$OPENSCAD" -o "$tmp/rollino.echo" rollino.scad 2> /dev/null
for p in body cover ball supports screws pouch pcm leads; do
  "$OPENSCAD" --enable=manifold -o "$tmp/$p.stl" -D 'part="exploded"' -D "explode_only=\"$p\"" rollino.scad 2> /dev/null
done
# both boards have their origin (generate.py's *_ORIGIN) at 150, 100 mm
for b in sensor base; do
  "$KICAD_CLI" pcb export vrml --units mm --user-origin 150x100mm -f -o "$tmp/$b.wrl" "../pcb/$b/rollino-$b.kicad_pcb" > /dev/null
done
"$BLENDER" -b -P render_exploded.py -- "$tmp" "$tmp/exploded.png" > /dev/null
magick "$tmp/exploded.png" -background '#f8f8f8' -flatten renders/exploded.png
rm -rf "$tmp"
echo "rendered $(pwd)/renders/exploded.png"
