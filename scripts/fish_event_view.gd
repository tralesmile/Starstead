class_name FishEventView
extends Node2D
## The sighted legendary in the water: a long dark shadow with a tail beat and rising sparkles, circling its spot.
## Bright during its hours, faint otherwise.

var spot := Vector2i(-1, -1)
var active := false   # inside its hours right now
var t := 0.0

func _init() -> void:
	z_index = -7

func show_at(cell: Vector2i) -> void:
	spot = cell
	visible = cell.x >= 0
	queue_redraw()

func _process(d: float) -> void:
	if spot.x < 0:
		return
	t += d
	queue_redraw()

func _draw() -> void:
	if spot.x < 0:
		return
	var c := Vector2(spot) * 32.0 + Vector2(16, 16)
	var p := c + FishEvents.swim(t)
	var dir := (FishEvents.swim(t + 0.1) - FishEvents.swim(t)).normalized()
	var side := dir.orthogonal()
	var a := 0.6 if active else 0.25
	var body := PackedVector2Array()
	for i in 17:
		var ang := TAU * float(i) / 16.0
		body.append(p + dir * cos(ang) * 19.0 + side * sin(ang) * 6.5)
	draw_colored_polygon(body, Color(0.02, 0.08, 0.12, a))
	var root := p - dir * 17.0
	var tail := root - dir * 11.0 + side * sin(t * 7.0) * 5.0
	draw_colored_polygon(PackedVector2Array([root, tail + side * 6.0, tail - side * 6.0]), Color(0.02, 0.08, 0.12, a))
	if not active:
		return
	for k in 7:
		var ph := fposmod(t * 0.6 + float(k) / 7.0, 1.0)
		var at := c + Vector2(sin(k * 2.4) * 28.0, cos(k * 1.7) * 11.0 - ph * 14.0)
		var gold := Color(1.0, 0.9, 0.4, sin(ph * PI))
		draw_rect(Rect2(at.round(), Vector2(2, 2)), gold)
		if ph > 0.35 and ph < 0.65:
			draw_rect(Rect2(at.round() + Vector2(-2, 0), Vector2(6, 1)), Color(gold, gold.a * 0.6))
			draw_rect(Rect2(at.round() + Vector2(0, -2), Vector2(1, 6)), Color(gold, gold.a * 0.6))
	var ph2 := fposmod(t * 0.5, 1.0)
	var ring := PackedVector2Array()
	for i in 25:
		var ang := TAU * float(i) / 24.0
		ring.append(c + Vector2(cos(ang) * (14.0 + ph2 * 30.0), sin(ang) * (6.0 + ph2 * 13.0)))
	draw_polyline(ring, Color(1.0, 0.93, 0.6, 0.55 * (1.0 - ph2)), 1.0)
