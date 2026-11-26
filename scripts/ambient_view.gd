class_name AmbientView
extends Node2D
## Fireflies at night, drifting leaves by day, dust puffs on footsteps. Whole-pixel squares, no textures.

const FIREFLIES := 14
const LEAVES := 8
var player: Player
var animals: AnimalView   # wild and tame critters breathe steam in the cold too
var t := 0.0
var crow_tex: Texture2D = load("res://assets/sprites/crow.png")
var _perch: Array = []     # ripe cells with a perched crow
var _perch_t := 99.0
var _fled := {}            # cell -> seconds since the crow was startled
var _fled_day := -1
var rain := 0.0   # current rain 0..1, set by main (cloud shadows vanish under overcast)

func _ready() -> void:
	z_index = 40

func puff(at: Vector2, amount: int = 3, spread: float = 60.0, tint: Color = Color(0.8, 0.7, 0.55, 0.55)) -> void:
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
	p.color = tint
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
	var cold := AmbientMath.breath_cold(GameState.clock.season(), mins)
	var age := AmbientMath.breath_age(t)
	if cold > 0.05 and age >= 0.0 and not player.indoors:
		var fx: float = {PlayerMath.Facing.LEFT: -1.0, PlayerMath.Facing.RIGHT: 1.0}.get(player.facing, 0.0)
		var mouth := c + Vector2(fx * 5.0, -28.0 if player.facing != PlayerMath.Facing.UP else -30.0)
		for i in 3:
			var bp := AmbientMath.breath_puff(age, i)
			var sz := roundf(bp.z)
			var fade := (1.0 - clampf(age - 0.12 * float(i), 0.0, 1.0)) * cold
			var o := Vector2(bp.x * (fx if fx != 0.0 else 0.0), bp.y).round()
			draw_rect(Rect2(mouth + o - Vector2(sz, sz) * 0.5, Vector2(sz, sz)), Color(0.93, 0.97, 1.0, 0.8 * fade) * unlit)
	if cold > 0.15 and animals != null and not player.indoors:
		var ci := 0
		for cr in animals.critters:
			ci += 1
			var node: Node2D = cr["node"]
			if node == null or node.position.distance_to(c) > 340.0:
				continue
			var big: float = 1.0 if cr["id"] in ["cow", "horse", "deer", "boar"] else 0.6
			var aa := AmbientMath.animal_breath_age(t, ci, big)
			if aa < 0.0:
				continue
			var sp: Sprite2D = cr["sprite"]
			var dirx := -1.0 if sp.flip_h else 1.0
			var mp: Vector2 = node.position + Vector2(dirx * 9.0 * big, -14.0 * big)
			var bsz := AmbientMath.animal_breath_size(big, aa)
			for k in 2:
				var ak := clampf(aa - 0.15 * float(k), 0.0, 1.0)
				draw_rect(Rect2((mp + Vector2(dirx * ak * 7.0, -ak * 5.0)).round() - Vector2(bsz, bsz) * 0.5, Vector2(bsz, bsz)), Color(0.93, 0.97, 1.0, 0.7 * (1.0 - ak) * cold) * unlit)
	var ca := CrowMath.age(mins)
	if ca >= 0.0 and rain < 0.6 and not player.indoors:
		for i in CrowMath.COUNT:
			var cp := (c + CrowMath.pos(i, ca)).round()
			var fr := CrowMath.frame(i, t)
			draw_rect(Rect2(cp + Vector2(-4, 10), Vector2(8, 2)), Color(0, 0, 0, 0.12 * CrowMath.alpha(ca)))   # ground shadow
			draw_texture_rect_region(crow_tex, Rect2(cp - Vector2(8, 8), Vector2(16, 16)), Rect2(fr * 16, 0, 16, 16), Color(1, 1, 1, CrowMath.alpha(ca)))
	_draw_perched_crows(c, mins, t)
	var storm := WeatherMath.tree_wind(rain, 0.0).y
	if storm > 0.05 and not player.indoors:
		var wa := PlayerMath.wind_angle(GameState.clock.day)
		var down := Vector2.from_angle(wa)
		for i in int(AmbientMath.GALE_LEAVES * storm):
			var gp := (c + AmbientMath.gale_leaf(i, t, wa)).round()
			var flat := int(t * 9.0 + i) % 2 == 0   # tumbling: flips between a flat and an upright leaf
			var lc := Color(0.72, 0.84, 0.26) if i % 3 else Color(0.95, 0.68, 0.2)
			draw_line(gp - down * 7.0, gp, Color(lc, 0.3), 1.0)
			# a two-step leaf with a darker spine, tilting one way then the other as it tumbles
			var tilt := Vector2(2, 1) if flat else Vector2(1, 2)
			draw_rect(Rect2(gp, Vector2(3, 2)), lc.lightened(0.35))
			draw_rect(Rect2(gp + tilt, Vector2(2, 2) if flat else Vector2(1, 2)), lc)
			draw_rect(Rect2(gp + tilt * 2.0, Vector2(1, 1)), lc.darkened(0.35))
	if night < 0.5:
		for i in LEAVES:
			var p := (c + AmbientMath.leaf_pos(i, t)).round()
			draw_rect(Rect2(p, Vector2(2, 1)), Color(0.55, 0.65, 0.2, 0.8 * (1.0 - night * 2.0)))

func _draw_perched_crows(c: Vector2, mins: float, tt: float) -> void:
	if GameState.clock.day != _fled_day:
		_fled.clear()
		_fled_day = GameState.clock.day
	var d := get_process_delta_time()
	_perch_t += d
	if not CrowMath.perch_window(mins) or rain > 0.6 or player.indoors:
		return
	if _perch_t > 0.6:
		_perch_t = 0.0
		var ripe: Array = []
		var farm := GameState.farm
		for cell in farm.soil:
			if Vector2(cell * 32).distance_to(c) < 420.0 and farm.is_ripe(cell) and not farm.scared(cell):
				ripe.append(cell)
		_perch = CrowMath.perch_cells(ripe, GameState.clock.day)
	var i := 0
	for cell in _perch:
		var base := (Vector2(cell) + Vector2(0.5, 0.55)) * 32.0
		i += 1
		if not _fled.has(cell) and CrowMath.startled(c, base):
			_fled[cell] = 0.0
		if _fled.has(cell):
			_fled[cell] += d
			var ft: float = _fled[cell]
			if ft >= CrowMath.FLEE_TIME:
				continue
			var cp := (base + CrowMath.flee_offset(i, ft, base - c)).round()
			var a := CrowMath.flee_alpha(ft)
			draw_rect(Rect2(base + Vector2(-4, 4), Vector2(8, 2)), Color(0, 0, 0, 0.1 * a))
			draw_texture_rect_region(crow_tex, Rect2(cp - Vector2(8, 8), Vector2(16, 16)), Rect2(CrowMath.frame(i, tt) * 16, 0, 16, 16), Color(1, 1, 1, a))
			continue
		var dip := roundf(CrowMath.peck(i, tt))
		var p := base.round()
		draw_rect(Rect2(p + Vector2(-4, 3), Vector2(9, 2)), Color(0, 0, 0, 0.18))      # shadow on the crop row
		draw_rect(Rect2(p + Vector2(-4, -4), Vector2(8, 6)), Color(0.08, 0.08, 0.12))  # body
		draw_rect(Rect2(p + Vector2(-5, -3), Vector2(3, 3)), Color(0.14, 0.14, 0.2))   # wing sheen
		draw_rect(Rect2(p + Vector2(3, -6 + dip), Vector2(4, 4)), Color(0.08, 0.08, 0.12))   # head
		draw_rect(Rect2(p + Vector2(7, -5 + dip), Vector2(3, 2)), Color(0.9, 0.65, 0.2))    # beak
		draw_rect(Rect2(p + Vector2(5, -5 + dip), Vector2(1, 1)), Color(0.9, 0.9, 0.9))      # eye
