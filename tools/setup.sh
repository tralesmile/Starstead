#!/bin/bash
# One-step environment setup for a fresh container: installs Godot 4.3 into ~/bin and imports the project.
# Idempotent: does nothing when Godot is already there. Run from anywhere: tools/setup.sh
set -e
cd "$(dirname "$0")/.."
if [ ! -x ~/bin/godot ]; then
  mkdir -p ~/bin /tmp/gd
  curl -sSL -o /tmp/gd/g.zip https://github.com/godotengine/godot/releases/download/4.3-stable/Godot_v4.3-stable_linux.x86_64.zip
  unzip -oq /tmp/gd/g.zip -d /tmp/gd
  mv /tmp/gd/Godot_v4.3-stable_linux.x86_64 ~/bin/godot
  chmod +x ~/bin/godot
fi
git checkout -q -B main origin/main 2>/dev/null || true   # fixes a detached HEAD
git pull -q --rebase 2>/dev/null || true
~/bin/godot --headless --path . --import >/dev/null 2>&1
echo "setup ok: $(~/bin/godot --version | head -1)"
