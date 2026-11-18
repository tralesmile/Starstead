class_name CircuitDecals
extends Node2D
## Ground decals for the Halden circuit: red/white rumble kerbs on the track edge and the chequered start line.

func _draw() -> void:
	var r := CircuitModel.RECT
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			var c := Vector2i(x, y)
			if CircuitModel.is_kerb(c):
				_kerb(c)
	# chequered line across the track at the start (two columns of 8x8 squares)
	var top := CircuitModel.start_px().y - CircuitModel.HALF_W * 32.0
	var x0 := CircuitModel.start_px().x - 8.0
	for row in int(CircuitModel.HALF_W * 2.0 * 4.0):
		for col in 2:
			var white := (row + col) % 2 == 0
			draw_rect(Rect2(x0 + col * 8.0, top + row * 8.0, 8, 8), Color(0.95, 0.95, 0.95) if white else Color(0.1, 0.1, 0.12))

func _kerb(c: Vector2i) -> void:
	## A 6px strip on each side of the cell that borders grass, alternating red/white every 16px.
	var base := Vector2(c) * 32.0
	var alt := (c.x + c.y) % 2 == 0
	for o in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		if CircuitModel.is_track(c + o):
			continue
		for h in 2:
			var col := Color(0.85, 0.2, 0.2) if (h == 0) == alt else Color(0.94, 0.94, 0.92)
			if o.x != 0:
				draw_rect(Rect2(base.x + (26.0 if o.x > 0 else 0.0), base.y + h * 16.0, 6, 16), col)
			else:
				draw_rect(Rect2(base.x + h * 16.0, base.y + (26.0 if o.y > 0 else 0.0), 16, 6), col)
