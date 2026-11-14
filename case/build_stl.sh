#!/bin/sh
# Exports the printable parts of the case to STL (in stl/, or $1), then runs
# the clearance checks that should come out empty (fpc_check, usb_check) and
# fails if one doesn't. wall_check is left out: it takes hours.
# Used by .github/workflows/case.yml; runs locally too.
set -e
cd "$(dirname "$0")"
OPENSCAD=${OPENSCAD:-$(command -v openscad || echo /Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD)}
out=${1:-stl}
mkdir -p "$out"
# the Manifold backend: --backend in newer builds, an experimental feature before
if "$OPENSCAD" --help 2>&1 | grep -q -- --backend; then fast="--backend=manifold"; else fast="--enable=manifold"; fi

export_part() {  # part file
  echo "exporting $1"
  "$OPENSCAD" $fast -o "$out/$2" -D "part=\"$1\"" rollino.scad
}
export_part body rollino-body.stl
export_part base_cover rollino-base-cover.stl
export_part sensor_cover rollino-sensor-cover-print-two.stl

fail=0
for check in fpc_check usb_check; do
  log=$("$OPENSCAD" $fast -o "$out/.$check.stl" -D "part=\"$check\"" rollino.scad 2>&1) || true
  rm -f "$out/.$check.stl"
  if echo "$log" | grep -q "Current top level object is empty"; then
    echo "$check: empty, good"
  else
    echo "$check: NOT EMPTY - something's in the way"
    echo "$log" | tail -5
    fail=1
  fi
done
exit $fail
