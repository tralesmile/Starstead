class_name CursorView
extends Node2D
## Tile cursor under the mouse: yellow when in reach, faint white when too far.

var cell := Vector2i.ZERO
var reach := false
var active := false

func _process(_d: float) -> void:
	visible = active
	queue_redraw()

func _draw() -> void:
	var col := Color(1.0, 0.85, 0.2, 0.95) if reach else Color(1, 1, 1, 0.35)
	var o := Vector2(cell) * 32.0
	var w := 1.0
	draw_rect(Rect2(o + Vector2(1, 1), Vector2(30, 30)), col, false, w)
	for k in [Vector2(0, 0), Vector2(26, 0), Vector2(0, 26), Vector2(26, 26)]:
		draw_rect(Rect2(o + k, Vector2(6, 6)), col, false, w)
