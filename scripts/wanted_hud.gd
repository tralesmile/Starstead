class_name WantedHud
extends Control
## GTA-2-style wanted meter (owner 2026-11-18: the text stars looked bad): dark badge at the top right,
## five drawn stars that fill with heat, a red/blue siren strip while a cop sees you, hidden at 0 stars.

var heat := 0.0
var seen := false
var _t := 0.0

func _process(delta: float) -> void:
	_t += delta
	visible = heat > 0.0
	if visible:
		queue_redraw()

func _draw() -> void:
	if heat <= 0.0:
		return
	var panel := Rect2(0, 0, 124, 34)
	draw_rect(panel.grow(2), Color(0.05, 0.05, 0.08, 0.95))
	draw_rect(panel, Color(0.12, 0.13, 0.2, 0.92))
	var phase := WantedMath.siren_phase(_t, seen)
	draw_rect(Rect2(0, 0, 62, 3), Color(0.9, 0.15, 0.15) if phase == 1 else Color(0.25, 0.1, 0.12))
	draw_rect(Rect2(62, 0, 62, 3), Color(0.2, 0.4, 1.0) if phase == 2 else Color(0.1, 0.14, 0.28))
	draw_string(ThemeDB.fallback_font, Vector2(8, 15), "WANTED", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.85, 0.88, 1.0))
	for i in 5:
		var c := Vector2(14 + i * 22, 25)
		var fill := WantedMath.star_fill(heat, i)
		draw_colored_polygon(WantedMath.star_points(c, 8.0), Color(0.22, 0.22, 0.3))
		if fill > 0.0:
			var pulse := 1.0 if fill < 1.0 else 0.85 + 0.15 * sin(_t * 6.0)
			draw_colored_polygon(WantedMath.star_points(c, 3.0 + 5.0 * fill), Color(1.0, 0.84, 0.2) * pulse)
