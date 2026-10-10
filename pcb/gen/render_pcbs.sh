#!/bin/sh
# Renders both boards, top and bottom, into pcb/renders/, and their layouts
# and schematics (rollino-*-layout.png, rollino-*-schematic.pdf) into their
# projects (needs KiCad 8, Blender 3.x and ImageMagick). Run after route.py.
set -e
cd "$(dirname "$0")/.."
KICAD_CLI=${KICAD_CLI:-/Applications/KiCad/KiCad.app/Contents/MacOS/kicad-cli}
BLENDER=${BLENDER:-/Applications/Blender.app/Contents/MacOS/Blender}
export KICAD8_3DMODEL_DIR=${KICAD8_3DMODEL_DIR:-/Applications/KiCad/KiCad.app/Contents/SharedSupport/3dmodels}
tmp=$(mktemp -d)
mkdir -p renders
for b in sensor base; do
  "$KICAD_CLI" pcb export vrml --units mm -f -o "$tmp/$b.wrl" "$b/rollino-$b.kicad_pcb" > /dev/null
  "$BLENDER" -b -P gen/render.py -- "$tmp/$b.wrl" "renders/$b" > /dev/null
  "$KICAD_CLI" pcb export svg --layers B.Cu,F.Cu,F.Silkscreen,Edge.Cuts --exclude-drawing-sheet --page-size-mode 2 \
    -o "$tmp/$b.svg" "$b/rollino-$b.kicad_pcb" > /dev/null
  magick -density 600 "$tmp/$b.svg" -background white -flatten -resize 960x -bordercolor white -border 20 "$b/rollino-$b-layout.png"
  "$KICAD_CLI" sch export pdf -o "$b/rollino-$b-schematic.pdf" "$b/rollino-$b.kicad_sch" > /dev/null
done
magick \( renders/base-top.png renders/base-bottom.png +append \) \
       \( renders/sensor-top.png renders/sensor-bottom.png +append \) -append -resize 1800x renders/pcbs.png
rm -rf "$tmp"
echo "rendered to $(pwd)/renders"
