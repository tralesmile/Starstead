class_name DockFoam
extends Node2D
## Pulsing foam rings around the dock posts where they enter the water (positions in dock-sprite pixels).

const POSTS := [Vector2(8, 61), Vector2(48, 61), Vector2(88, 61)]

func _process(_d: float) -> void:
	queue_redraw()

func _draw() -> void:
	var t := Time.get_ticks_msec() / 1000.0
	for i in POSTS.size():
		var k := fposmod(t * 0.5 + float(i) * 0.31, 1.0)
		var rx := roundf(5.0 + 6.0 * k)
		var ry := roundf(2.0 + 2.5 * k)
		var a := (1.0 - k) * 0.55
		_ring(POSTS[i], rx, ry, Color(0.92, 0.97, 1.0, a))
		_ring(POSTS[i], 5.0, 2.0, Color(0.92, 0.97, 1.0, 0.35))  # steady foam collar

func _ring(c: Vector2, rx: float, ry: float, col: Color) -> void:
	var n := 20
	var prev := c + Vector2(rx, 0)
	for i in range(1, n + 1):
		var a := TAU * float(i) / float(n)
		var p := c + Vector2(roundf(cos(a) * rx), roundf(sin(a) * ry))
		draw_line(prev, p, col, 1.0)
		prev = p
