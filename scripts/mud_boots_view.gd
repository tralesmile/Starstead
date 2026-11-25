class_name MudBootsView
extends Node2D
## Mud splashes on the player's boots and shins (PlayerMath.mud_specks): the rain-soaked grass now shows on the character.

const MUD := Color(0.30, 0.20, 0.11)
const MUD_LIGHT := Color(0.42, 0.29, 0.16)
var load := 0.0:
	set(v):
		if absf(v - load) > 0.01 or (v < 0.05) != (load < 0.05):
			load = v
			queue_redraw()

func _draw() -> void:
	for s in PlayerMath.mud_specks(load):
		var w: int = s["w"]
		var r := Rect2(float(s["x"]), float(s["y"]), float(w), float(w))
		draw_rect(r, Color(MUD, float(s["a"])))
		draw_rect(Rect2(r.position, Vector2(1, 1)), Color(MUD_LIGHT, float(s["a"]) * 0.8))
