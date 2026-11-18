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
- CharacterBody2D defaults to GROUNDED motion mode: vehicles need MOTION_MODE_FLOATING; a car that carries the player must add_collision_exception_with(player) both ways or it jitters/flies off.
- The test runner prints SCRIPT ERROR / parse errors yet still says 0 failed: ALWAYS run `... 2>&1 | grep -E "ERROR|FAIL|TESTS"` and fix every ERROR line. Typed `var x := [..][i]` on array literals fails to infer: annotate `var x: float`.
- ColorRect under a CanvasLayer has size 0 (anchors need a Control parent): set .size = get_viewport_rect().size, and verify overlays by pixel diff (python PIL getpixel) not by eye; pastel overlays look like 'no change'.
- Clock has no class_name (use GameState.clock.DAYS_PER_SEASON). gen_items.py now keeps old icons for ids it does not draw; new item ids go at the END of data/items.json so icon indexes stay stable. Two scheduled runs can overlap: git pull --rebase before every push and check git log for duplicate work before starting an item.
- World (and anything a test compiles) must not reference autoloads: pass things in (World.nodes_ref). A strong reference cycle between RefCounted objects (WorldGen <-> ChunkStream) prints "resources still in use at exit" and fails check.sh: use weakref on the back-pointer.
- Seams between ground-shader chunks: pad the data texture with the neighbours' edge cells (World.data_image pad=1); clamped edges show a visible line.
- A GDScript subclass that defines its own _init() must call super._init() first, or the parent never builds its nodes (SmeltView: canvas was null). Rooms/mines far from the map need Player.indoors, else the out-of-world sdf reads as deep water (shore slowdown, reflection ghost).
- A screenshot far from the feature looks like 'nothing rendered': when --at shows plain meadow, check the distance in cells (zoom 1 = 20x11 cells) before debugging; screenshot several spots around a new area.
