# Lessons (mistakes and guards, read at the start of each run)

- Godot 4.3 direct download: https://github.com/godotengine/godot/releases/download/4.3-stable/Godot_v4.3-stable_linux.x86_64.zip works via curl. Run tests: `~/bin/godot --headless --path . -s tests/run_tests.gd` (run `--import` first on a fresh clone).
- After adding a new `class_name` script run `godot --headless --path . --import` BEFORE tests, else "identifier not declared" errors. The runner (-s mode) cannot compile scripts referencing autoloads (GameState): keep testable logic in pure classes (PlayerMath, HudText, DayNight) and keep autoload use in nodes.
- Screenshots: `tools/screenshot.sh` (xvfb + --write-movie) writes /tmp/mv*.png; view with Read. `-s` script screenshots do not work (autoloads missing).
- JSON numbers load as floats: `int in json_array` is false in Godot; compare with int(x) in a loop.
- Shader compile errors never show in headless runs or tests: always run tools/screenshot.sh after shader edits (it greps "SHADER ERROR") and look at the frame. A blank beige screen = shader failed.
- Screenshot helper args: `tools/screenshot.sh 20 -- --zoom=1 --at=x,y` (tile coords) to inspect any spot.
- Canvas shaders: in fragment(), COLOR already includes the texture; multiplying by texture again kills outlines. Pass modulate via a varying from vertex(). `return` is not allowed in fragment().
- Nested y-sort did not merge here: put the player under the same y-sorted parent (World) as the props.
- New class_name scripts need `--import` before tests, else the test file 'cannot load'. GDScript: float % float is invalid, use fposmod. Night glow under CanvasModulate: divide colour by DayNight.tint to cancel it.
