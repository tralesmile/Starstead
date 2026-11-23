class_name PrintView
extends Node2D
## Wet footprints (PrintMath): small pale wet ovals behind you on paved ground while it rains.

var player: Node2D
var prints: Array = []
var steps := 0

func setup(p: Node2D) -> void:
	player = p
	z_index = 1
	p.footstep.connect(_on_step)

func _on_step() -> void:
	var c := Vector2i(floori(player.position.x / 32.0), floori(player.position.y / 32.0))
	var paved := PrintMath.paved_cell(c)
	var snowy := PrintMath.snow(GameState.clock.season(), paved)
	if not snowy and not PrintMath.wet(player.rain, paved):
		return
	steps += 1
	var pr := {"pos": player.position + Vector2(0, -2) + PrintMath.offset(steps, player.facing), "age": 0.0}
	if snowy:
		pr["snow"] = true
		pr["life"] = PrintMath.SNOW_LIFE
	prints.append(pr)

var _demo_done := false

func _process(delta: float) -> void:
	if not _demo_done and "--prints-demo" in OS.get_cmdline_user_args() and Engine.get_process_frames() > 2:
		_demo_done = true   # screen check: a fresh trail behind wherever the player was placed
		for i in 14:
			steps += 1
			var d := {"pos": player.position + Vector2(-10.0 * (14 - i), 0) + PrintMath.offset(steps, PlayerMath.Facing.RIGHT), "age": 0.3 * (14 - i) * 0.25}
			if GameState.clock.season() == 3:
				d["snow"] = true
				d["life"] = PrintMath.SNOW_LIFE
			prints.append(d)
	if prints.is_empty():
		return
	prints = PrintMath.prune(prints, delta)
	queue_redraw()

func _draw() -> void:
	for p in prints:
		if p.has("snow"):
			var a := PrintMath.snow_alpha(float(p["age"]))
			draw_set_transform(p["pos"], 0.0, Vector2(0.75, 1.2))
			draw_circle(Vector2(0, 0.6), 2.6, Color(1, 1, 1, a * 0.7))          # lit rim below the dent
			draw_circle(Vector2.ZERO, 2.9, Color(0.30, 0.40, 0.58, minf(a * 1.5, 0.85)))   # blue-grey dent
			continue
		draw_set_transform(p["pos"], 0.0, Vector2(0.7, 1.1))
		draw_circle(Vector2.ZERO, 2.6, Color(0.72, 0.82, 0.95, PrintMath.alpha(float(p["age"])) * 1.8))
