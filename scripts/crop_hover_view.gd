class_name CropHoverView
extends Node2D
## Small label and stage bar above the crop under the mouse cursor (reads CursorView.cell).

var cursor: CursorView

func setup(c: CursorView) -> CropHoverView:
	cursor = c
	z_index = 40
	return self

func _process(_d: float) -> void:
	queue_redraw()

func _draw() -> void:
	if cursor == null or not cursor.active:
		return
	var farm: FarmModel = GameState.farm
	var inf := CropInfo.info(farm.soil, farm.crops, cursor.cell)
	if inf.is_empty():
		return
	var msg := CropInfo.text(inf)
	var font := ThemeDB.fallback_font
	var w := font.get_string_size(msg, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x + 8.0
	var o := Vector2(cursor.cell) * 32.0 + Vector2(16.0 - w / 2.0, -22.0)
	draw_rect(Rect2(o, Vector2(w, 16)), Color(0.08, 0.06, 0.04, 0.85))
	draw_string(font, o + Vector2(4, 11), msg, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1, 0.95, 0.8))
	if String(inf.crop) != "":
		var bar := Rect2(o + Vector2(0, 16), Vector2(w, 3))
		draw_rect(bar, Color(0.15, 0.1, 0.06, 0.9))
		var col := Color(0.95, 0.8, 0.25) if inf.ripe else Color(0.45, 0.8, 0.35)
		draw_rect(Rect2(bar.position, Vector2(w * float(inf.fraction), 3)), col)
