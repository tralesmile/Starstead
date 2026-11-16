class_name FarmView
extends Node2D
## Draws tilled soil, watering and crop growth stages (placeholder rects) from FarmModel.

func _process(_d: float) -> void:
	queue_redraw()

func _draw() -> void:
	var farm: FarmModel = GameState.farm
	for cell in farm.soil:
		var s = farm.soil[cell]
		var r := Rect2(Vector2(cell) * 32.0, Vector2(32, 32))
		draw_rect(r, Color(0.32, 0.2, 0.12) if s.watered else Color(0.5, 0.33, 0.2))
		draw_rect(r.grow(-2), Color(0, 0, 0, 0.15), false, 1.0)
		if s.crop != "":
			var total := float(farm.crops[s.crop].grow_days)
			var t := clampf(s.age / total, 0.0, 1.0)
			var h := 4.0 + 20.0 * t
			var col := Color(0.4, 0.8, 0.3) if t < 1.0 else Color(0.95, 0.75, 0.2)
			draw_rect(Rect2(r.position + Vector2(16 - 3, 28 - h), Vector2(6, h)), col)
