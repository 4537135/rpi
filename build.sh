#!/usr/bin/env bash
# Re-export every STL and render. Usage: ./build.sh [case ...]   (default: all)
set -euo pipefail
cd "$(dirname "$0")"
OPENSCAD=${OPENSCAD:-openscad}
command -v "$OPENSCAD" >/dev/null || OPENSCAD="/c/Program Files/OpenSCAD/openscad.exe"
mkdir -p stl renders

stl() {  # stl <file.scad> <out-name> [-D ...]
  local src=$1 out=$2; shift 2
  echo "stl/$out.stl"
  "$OPENSCAD" -q -o "stl/$out.stl" "$@" "$src"
}
png() {  # png <file.scad> <out-name> <camera rx,ry,rz> [-D ...]
  local src=$1 out=$2 rot=$3; shift 3
  "$OPENSCAD" -q -o "renders/$out.png" --imgsize=1600,1200 --viewall --autocenter \
    --camera=0,0,0,$rot,0 --colorscheme=Tomorrow "$@" "$src"
}

aio() {
  for s in 5 7; do
    for p in bezel shell fin_left fin_right; do stl aio.scad "aio-${s}in-$p" -D "screen=\"$s\"" -D "part=\"$p\""; done
    png aio.scad "aio-${s}in-front" 70,0,25 -D "screen=\"$s\""
    png aio.scad "aio-${s}in-back" 65,0,215 -D "screen=\"$s\""
  done
  png aio.scad aio-7in-exploded 75,0,60 -D 'explode=45'
}
cube() {
  for p in shell front back sled; do stl cube.scad "cube-$p" -D "part=\"$p\""; done
  "$OPENSCAD" -q -o stl/cube-window.svg -D 'part="window_2d"' cube.scad
  png cube.scad cube-front 70,0,35
  png cube.scad cube-ports 70,0,300
}
showcase() {
  for p in base top; do stl showcase.scad "showcase-$p" -D "part=\"$p\""; done
  for p in front side; do "$OPENSCAD" -q -o "stl/showcase-panel-$p.svg" -D "part=\"panel_$p\"" showcase.scad; done
  png showcase.scad showcase-front 70,0,35
  png showcase.scad showcase-back 65,0,215
}
deck() {
  for p in base plate lid bezel handle hinge_pin; do stl deck.scad "deck-$p" -D "part=\"$p\""; done
  png deck.scad deck-open 60,0,30
  png deck.scad deck-closed 60,0,30 -D 'open_angle=0'
}

cases=("$@")
[ ${#cases[@]} -eq 0 ] && cases=(aio cube showcase deck)
for c in "${cases[@]}"; do "$c"; done
