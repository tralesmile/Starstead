class_name FootprintView
extends Node2D
## Dark dents on packed dirt path, drawn under characters (z below props), fading out.

var player: Player
var gen: WorldGen
var prints: Array = []  # {pos, age}
var last_pos := Vector2.ZERO
var acc := 0.0
var idx := 0

func _ready() -> void:
	z_index = -1
	z_as_relative = false

func on_path(p: Vector2) -> bool:
	var c := Vector2i(floori(p.x / 32.0), floori(p.y / 32.0))
	var t := gen.tile_at(c.x, c.y)
	return t >= WorldGen.PATH and t < WorldGen.PATH + 3

func _process(d: float) -> void:
	if player == null:
		return
	acc += player.position.distance_to(last_pos)
	var dir := player.position - last_pos
	last_pos = player.position
	if FootprintMath.due(acc) and dir.length() > 0.01 and on_path(player.position):
		acc = 0.0
		idx += 1
		prints.append({"pos": FootprintMath.print_pos(player.position + Vector2(0, 2), dir, idx), "age": 0.0})
		if prints.size() > 80:
			prints.pop_front()
	for p in prints:
		p["age"] += d
	prints = prints.filter(func(p): return FootprintMath.alpha(p["age"]) > 0.0)
	queue_redraw()

func _draw() -> void:
	for p in prints:
		draw_rect(Rect2(p["pos"], Vector2(2, 3)), Color(0.2, 0.13, 0.07, FootprintMath.alpha(p["age"])))
