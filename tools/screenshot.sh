#!/bin/bash
# Renders N frames under xvfb into /tmp/mv*.png and prints the last one. Usage: tools/screenshot.sh [frames] [-- --zoom=1 --at=x,y]
F=${1:-30}; shift
rm -f /tmp/mv*.png
xvfb-run -a -s "-screen 0 1280x720x24" ~/bin/godot --path . --rendering-driver opengl3 --write-movie /tmp/mv.png --fixed-fps 10 --quit-after $F "$@" 2>&1 | grep -E "SCRIPT|SHADER ERROR"
ls /tmp/mv*.png | tail -1
