#!/bin/sh
# Renders both boards, top and bottom, into pcb/renders/ (needs KiCad 8,
# Blender 3.x and ImageMagick). Run after route.py.
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
done
magick \( renders/base-top.png renders/base-bottom.png +append \) \
       \( renders/sensor-top.png renders/sensor-bottom.png +append \) -append -resize 1800x renders/pcbs.png
rm -rf "$tmp"
echo "rendered to $(pwd)/renders"
