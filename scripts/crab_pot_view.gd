class_name CrabPotView
extends Node2D
## Draws crab pots floating on the water (gentle bob) with a bouncing "!" when something is inside.

var tex: Texture2D = load("res://assets/sprites/crab_pot.png")
var t := 0.0

func _ready() -> void:
	z_index = -4

func _process(d: float) -> void:
	t += d
	queue_redraw()

func _draw() -> void:
	var pots: CrabPots = GameState.pots
	for c in pots.pots:
		var bob := roundf(sin(t * 2.0 + float(c.x + c.y)) * 1.0)
		var p := Vector2(c) * 32.0 + Vector2(0, bob)
		draw_texture_rect(tex, Rect2(p, Vector2(32, 32)), false)
		if pots.is_ready(c):
			var y := roundf(-3.0 - absf(sin(t * 4.0)) * 3.0)
			draw_rect(Rect2(p + Vector2(14, y), Vector2(4, 8)), Color(0.15, 0.1, 0.05))
			draw_rect(Rect2(p + Vector2(15, y + 1), Vector2(2, 4)), Color(1, 0.9, 0.3))
			draw_rect(Rect2(p + Vector2(15, y + 6), Vector2(2, 1)), Color(1, 0.9, 0.3))
