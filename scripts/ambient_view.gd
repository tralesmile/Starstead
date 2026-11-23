class_name AmbientView
extends Node2D
## Fireflies at night, drifting leaves by day, dust puffs on footsteps. Whole-pixel squares, no textures.

const FIREFLIES := 14
const LEAVES := 8
var player: Player
var t := 0.0
var rain := 0.0   # current rain 0..1, set by main (cloud shadows vanish under overcast)

func _ready() -> void:
	z_index = 40

func puff(at: Vector2, amount: int = 3, spread: float = 60.0) -> void:
	var p := CPUParticles2D.new()
	p.position = at + Vector2(0, -1)
	p.emitting = true
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = amount
	p.lifetime = 0.35
	p.direction = Vector2(0, -1)
	p.spread = spread
	p.initial_velocity_min = 6.0
	p.initial_velocity_max = 14.0
	p.gravity = Vector2(0, -8)
	p.scale_amount_min = 1.0
	p.scale_amount_max = 2.0
	p.color = Color(0.8, 0.7, 0.55, 0.55)
	add_child(p)
	get_tree().create_timer(0.8).timeout.connect(p.queue_free)

func _process(d: float) -> void:
	t += d
	queue_redraw()

func _draw() -> void:
	if player == null:
		return
	var mins: float = GameState.clock.minutes
	var night := AmbientMath.night_factor(mins)
	var c := player.position.round()
	var tint := DayNight.tint(mins)
	var unlit := Color(1.0 / maxf(tint.r, 0.2), 1.0 / maxf(tint.g, 0.2), 1.0 / maxf(tint.b, 0.2))  # cancel the night tint so the glow stays bright
	var cs := CloudMath.strength(mins, rain, GameState.clock.season())
	if cs > 0.02:
		for i in CloudMath.COUNT:
			var cp := CloudMath.pos(i, t, c)
			var cr := CloudMath.radius(i)
			for band in 3:   # stepped soft edge: three nested ellipses
				var f := 1.0 - 0.28 * float(band)
				draw_colored_polygon(CloudMath.ellipse(cp, cr * f), Color(0.05, 0.1, 0.18, 0.07 * cs))
	if night > 0.05:
		for i in FIREFLIES:
			var g := AmbientMath.firefly_glow(i, t) * night
			if g < 0.05:
				continue
			var p := (c + AmbientMath.firefly_pos(i, t)).round()
			draw_rect(Rect2(p - Vector2(2, 2), Vector2(5, 5)), Color(1.0, 0.95, 0.4, 0.3 * g) * unlit)
			draw_rect(Rect2(p - Vector2(1, 1), Vector2(3, 3)), Color(1.0, 0.98, 0.6, 0.5 + 0.5 * g) * unlit)
	if night < 0.5:
		for i in LEAVES:
			var p := (c + AmbientMath.leaf_pos(i, t)).round()
			draw_rect(Rect2(p, Vector2(2, 1)), Color(0.55, 0.65, 0.2, 0.8 * (1.0 - night * 2.0)))
