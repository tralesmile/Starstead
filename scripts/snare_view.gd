class_name SnareView
extends Node2D
## Draws snares on the ground: frame 0 set, frame 1 sprung with the catch; a bouncing "!" when game waits.

var tex: Texture2D = load("res://assets/sprites/snare.png")
var t := 0.0

func _ready() -> void:
	z_index = -4

func _process(d: float) -> void:
	t += d
	queue_redraw()

func _draw() -> void:
	var sn: Snares = GameState.snares
	for c in sn.snares:
		var p := Vector2(c) * 32.0
		var ready := sn.is_ready(c)
		draw_texture_rect_region(tex, Rect2(p, Vector2(32, 32)), Rect2(32.0 if ready else 0.0, 0, 32, 32))
		if ready:
			var y := roundf(-3.0 - absf(sin(t * 4.0)) * 3.0)
			draw_rect(Rect2(p + Vector2(14, y), Vector2(4, 8)), Color(0.15, 0.1, 0.05))
			draw_rect(Rect2(p + Vector2(15, y + 1), Vector2(2, 4)), Color(1, 0.9, 0.3))
			draw_rect(Rect2(p + Vector2(15, y + 6), Vector2(2, 1)), Color(1, 0.9, 0.3))
