#!/bin/sh
# Renders the assembled and the exploded view, renders/assembled.png and
# renders/exploded.png, in Blender, with KiCad's 3D models of the boards
# (needs OpenSCAD, KiCad 8, Blender 3.x and ImageMagick). Run after changing
# the case or the boards.
set -e
cd "$(dirname "$0")"
OPENSCAD=${OPENSCAD:-/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD}
KICAD_CLI=${KICAD_CLI:-/Applications/KiCad/KiCad.app/Contents/MacOS/kicad-cli}
BLENDER=${BLENDER:-/Applications/Blender.app/Contents/MacOS/Blender}
export KICAD8_3DMODEL_DIR=${KICAD8_3DMODEL_DIR:-/Applications/KiCad/KiCad.app/Contents/SharedSupport/3dmodels}
tmp=$(mktemp -d)
# both boards have their origin (generate.py's *_ORIGIN) at 150, 100 mm
for b in sensor base; do
  "$KICAD_CLI" pcb export vrml --units mm --user-origin 150x100mm -f -o "$tmp/$b.wrl" "../pcb/$b/rollino-$b.kicad_pcb" > /dev/null
done
# view, how far apart its pieces are pulled (explode_d), image size
render() {
  d="$tmp/$1"
  mkdir "$d"
  cp "$tmp/sensor.wrl" "$tmp/base.wrl" "$d"
  "$OPENSCAD" --enable=manifold -o "$d/rollino.echo" -D 'part="none"' -D "explode_d=$2" rollino.scad 2> /dev/null
  for p in body cover ball supports screws pouch pcm leads; do
    "$OPENSCAD" --enable=manifold -o "$d/$p.stl" -D 'part="exploded"' -D "explode_only=\"$p\"" -D "explode_d=$2" rollino.scad 2> /dev/null
  done
  "$BLENDER" -b -P render_exploded.py -- "$d" "$d/$1.png" "$3" > /dev/null
  magick "$d/$1.png" -background '#f8f8f8' -flatten "renders/$1.png"
  echo "rendered $(pwd)/renders/$1.png"
}
render assembled 0 1400x1100
render exploded 25 1200x1400
rm -rf "$tmp"
