#!/bin/bash
# Renders N frames under xvfb into $SHOT_DIR/mv*.png (default /tmp) and prints the last one.
# Usage: tools/screenshot.sh [frames] [-- --zoom=1 --at=x,y]    Parallel callers must set their own SHOT_DIR.
F=${1:-30}; shift
D=${SHOT_DIR:-/tmp}
mkdir -p "$D"
rm -f "$D"/mv*.png
xvfb-run -a -s "-screen 0 1280x720x24" ~/bin/godot --path . --rendering-driver opengl3 --write-movie "$D/mv.png" --fixed-fps 10 --quit-after $F "$@" 2>&1 | grep -E "SCRIPT|SHADER ERROR"
ls "$D"/mv*.png | tail -1
