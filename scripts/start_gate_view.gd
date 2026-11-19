extends Node2D
## Chequered start strip drawn on the ground (horizontal across a road, or vertical).

var vertical := false

func _draw() -> void:
	var cells := 12
	for i in cells:
		for j in 2:
			var c := Color(0.95, 0.95, 0.95) if (i + j) % 2 == 0 else Color(0.1, 0.1, 0.12)
			var o := Vector2(-3 + j * 6, -36 + i * 6) if not vertical else Vector2(-36 + i * 6, -3 + j * 6)
			draw_rect(Rect2(o, Vector2(6, 6)), c)
	var f := ThemeDB.fallback_font
	draw_string(f, Vector2(-14, -42) if not vertical else Vector2(-14, -10), "START", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(1, 0.9, 0.3))
