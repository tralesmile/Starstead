class_name PourView
extends Node2D
## Draws one pour: whole-pixel drops arcing from the can to the soil, each ending in a small flat ring.

var from := Vector2.ZERO
var targets: Array[Vector2] = []
var t := 0.0
var hold := -1.0   # QA (--pour-demo): freeze at this time

static func make(spout: Vector2, at_points: Array[Vector2]) -> PourView:
	var v := PourView.new()
	v.from = spout
	v.targets = at_points
	v.z_index = 12
	return v

func _process(delta: float) -> void:
	t = hold if hold >= 0.0 else t + delta
	if t >= PourMath.duration():
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	for c in targets.size():
		for i in PourMath.DROPS_PER_CELL:
			var age := t - PourMath.birth(i)
			if age < 0.0:
				continue
			var land: Vector2 = targets[c] + PourMath.spread(i)
			if age < PourMath.FLIGHT:
				var u := age / PourMath.FLIGHT
				var p := PourMath.at(from, land, u).round()
				var tail := PourMath.at(from, land, maxf(u - 0.05, 0.0)).round()
				draw_line(tail, p, Color(0.45, 0.72, 0.96, 0.6), 1.0)
				draw_rect(Rect2(p - Vector2(1, 1), Vector2(2, 2)), Color(0.82, 0.94, 1.0))
			elif age < PourMath.FLIGHT + PourMath.RING_TIME:
				var k := (age - PourMath.FLIGHT) / PourMath.RING_TIME
				var w := roundf(1.0 + 4.0 * k)
				var col := Color(0.75, 0.9, 1.0, 0.8 * (1.0 - k))
				var q := land.round()
				draw_rect(Rect2(q + Vector2(-w, 0), Vector2(2, 1)), col)
				draw_rect(Rect2(q + Vector2(w - 1, 0), Vector2(2, 1)), col)
				if k < 0.4:
					draw_rect(Rect2(q + Vector2(0, -3), Vector2(1, 2)), col)
