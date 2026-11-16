#!/bin/bash
# Renders N frames of the game under xvfb into /tmp/mv*.png (view the last one). Usage: tools/screenshot.sh [frames]
rm -f /tmp/mv*.png
xvfb-run -a -s "-screen 0 1280x720x24" ~/bin/godot --path . --rendering-driver opengl3 --write-movie /tmp/mv.png --fixed-fps 10 --quit-after ${1:-30} 2>&1 | grep SCRIPT
ls /tmp/mv*.png | tail -1
