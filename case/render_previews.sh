#!/bin/sh
# Renders the OpenSCAD previews in renders/ (all but exploded.png, which
# render_exploded.sh makes). Run after changing the case.
set -e
cd "$(dirname "$0")"
OPENSCAD=${OPENSCAD:-/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD}
# --camera: centre x,y,z, rotation about x,y,z (gimbal), distance
render() {  # name part size camera projection [extra -D]
  "$OPENSCAD" --enable=manifold -o "renders/$1.png" -D "part=\"$2\"" ${6:+-D "$6"} --imgsize "$3" \
    --camera "$4" --projection "$5" --colorscheme Tomorrow rollino.scad 2> /dev/null
}
render assembly assembly 1400,1000 0,-6,16,55,0,25,280 p
render hardware_front hardware 1400,1000 0,-6,16,60,0,25,250 p
render hardware_back hardware 1400,1000 0,4,20,65,0,200,240 p
render hardware_side hardware 1400,800 0,-8,18,82,0,90,215 p
# sections, looking straight at the cut: through the right sensor, and
# front to back through the electronics pod
render section_sensor section 1400,800 0,0,24,90,0,225,170 o section_az=135
render section_mcu section 1400,800 0,-8,24,90,0,90,170 o section_az=0
echo "rendered to $(pwd)/renders"
