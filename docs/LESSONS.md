# Lessons (mistakes and guards, read at the start of each run)

- Godot 4.3 direct download: https://github.com/godotengine/godot/releases/download/4.3-stable/Godot_v4.3-stable_linux.x86_64.zip works via curl. Run tests: `~/bin/godot --headless --path . -s tests/run_tests.gd` (run `--import` first on a fresh clone).
- After adding a new `class_name` script run `godot --headless --path . --import` BEFORE tests, else "identifier not declared" errors. The runner (-s mode) cannot compile scripts referencing autoloads (GameState): keep testable logic in pure classes (PlayerMath, HudText, DayNight) and keep autoload use in nodes.
- Screenshots: `tools/screenshot.sh` (xvfb + --write-movie) writes /tmp/mv*.png; view with Read. `-s` script screenshots do not work (autoloads missing).
- JSON numbers load as floats: `int in json_array` is false in Godot; compare with int(x) in a loop.
