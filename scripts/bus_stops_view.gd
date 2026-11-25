class_name BusStopsView
extends Node2D
## Draws the bus shelters (procedural pixel shelter: roof, posts, bench, sign) and finds the one you stand at.

var stops: Array = []
var player: Node2D
const REACH := 2.2

func _ready() -> void:
	z_index = -2

func near() -> Dictionary:
	if player == null:
		return {}
	return BusModel.nearest_stop(stops, player.position / 32.0, REACH)

func _process(_d: float) -> void:
	queue_redraw()

func _draw() -> void:
	for s in stops:
		var p := Vector2(s["cell"]) * 32.0
		var nr := near()
		var at: bool = not nr.is_empty() and nr["id"] == s["id"]
		draw_rect(Rect2(p + Vector2(-8, 20), Vector2(56, 10)), Color(0, 0, 0, 0.22))   # shadow
		draw_rect(Rect2(p + Vector2(-2, 6), Vector2(4, 24)), Color(0.35, 0.22, 0.12))    # posts
		draw_rect(Rect2(p + Vector2(38, 6), Vector2(4, 24)), Color(0.35, 0.22, 0.12))
		draw_rect(Rect2(p + Vector2(0, 18), Vector2(40, 4)), Color(0.55, 0.38, 0.2))     # bench
		draw_rect(Rect2(p + Vector2(0, 22), Vector2(40, 2)), Color(0.3, 0.2, 0.1))
		draw_rect(Rect2(p + Vector2(0, 8), Vector2(40, 10)), Color(0.7, 0.85, 0.95, 0.25))  # glass back
		draw_rect(Rect2(p + Vector2(-6, -2), Vector2(52, 8)), Color(0.14, 0.3, 0.55))      # roof
		draw_rect(Rect2(p + Vector2(-6, -2), Vector2(52, 2)), Color(0.35, 0.55, 0.85))
		draw_rect(Rect2(p + Vector2(-6, 4), Vector2(52, 2)), Color(0.07, 0.15, 0.3))
		draw_rect(Rect2(p + Vector2(44, -14), Vector2(3, 36)), Color(0.5, 0.5, 0.55))    # sign pole
		draw_rect(Rect2(p + Vector2(38, -22), Vector2(15, 12)), Color(0.12, 0.28, 0.6))   # sign
		draw_rect(Rect2(p + Vector2(40, -20), Vector2(11, 8)), Color(1.0, 0.85, 0.2))     # bus icon
		draw_rect(Rect2(p + Vector2(41, -18), Vector2(9, 3)), Color(0.2, 0.3, 0.5))
		draw_rect(Rect2(p + Vector2(41, -14), Vector2(2, 2)), Color(0.1, 0.1, 0.1))
		draw_rect(Rect2(p + Vector2(47, -14), Vector2(2, 2)), Color(0.1, 0.1, 0.1))
		if at:
			draw_rect(Rect2(p + Vector2(-8, -4), Vector2(56, 36)), Color(1, 0.95, 0.5, 0.12))
