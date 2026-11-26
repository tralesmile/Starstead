class_name BossView
extends Node2D
## The Stone Warden in the mine hall: sprite, warning ring, falling rocks and the health bar. Rules are in BossModel.

signal hurt_player(amount: float, from: Vector2, force: float)
signal defeated(pos: Vector2)
signal shake(amp: float, secs: float)
signal sound(name: String, gain: float, pitch: float)
signal message(msg: String)

var model: BossModel
var body: Node2D               # y-sorted in the world; this node only draws floor warnings and rocks
var sprite: Sprite2D
var shadow: Node2D
var rock_tex: Texture2D = load("res://assets/sprites/cave_rock.png")
var bar_layer: CanvasLayer
var bar: Control
var falling: Node2D
var rng := RandomNumberGenerator.new()
var player: Player
var cave_model: CaveModel
var t := 0.0
var flash := 0.0
var shown_hp := 1.0
var slam_ring := 0.0          # fading shock ring after a slam
var slam_pos := Vector2.ZERO

func setup(at: Vector2, p: Player, cm: CaveModel) -> BossView:
	player = p
	cave_model = cm
	model = BossModel.new_boss(at)
	rng.seed = 91
	z_index = 0
	y_sort_enabled = false
	body = Node2D.new()
	shadow = World.make_shadow(44.0)
	shadow.position = Vector2(0, 2)
	body.add_child(shadow)
	sprite = Sprite2D.new()
	sprite.texture = load("res://assets/sprites/cave_warden.png")
	sprite.hframes = 6
	sprite.offset = Vector2(0, -32)
	body.add_child(sprite)
	falling = Node2D.new()
	falling.z_as_relative = false
	falling.z_index = 8
	falling.draw.connect(_draw_falling)
	add_child(falling)
	bar_layer = CanvasLayer.new()
	bar_layer.layer = 8
	bar = Control.new()
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.draw.connect(_draw_bar)
	bar_layer.add_child(bar)
	add_child(bar_layer)
	_place()
	return self

func _place() -> void:
	body.position = model.pos

func club_swing(origin: Vector2, face: Vector2, damage: float, reach: float) -> bool:
	if model.state == "dead":
		return false
	var body := model.pos + Vector2(0, -20)
	# the Warden is wide: allow for its girth on top of the weapon's reach
	var near := body - (body - origin).limit_length(22.0)
	if not CombatModel.in_swing(origin, face, near, reach):
		return false
	var res := model.take_hit(damage)
	flash = 1.0 if model.state == "recover" or res["dead"] else 0.45
	sound.emit("hit", 1.0, 0.6 if model.state == "recover" else 1.4)
	if res["dead"]:
		defeated.emit(model.pos)
		shake.emit(2.5, 0.5)
		sound.emit("tree_fall", 1.0, 0.6)
		var tw := create_tween()
		tw.tween_property(sprite, "modulate:a", 0.0, 1.2)
		tw.parallel().tween_property(shadow, "modulate:a", 0.0, 1.2)
	return true

func apply_events(events: Array) -> void:
	for e in events:
		match String(e["type"]):
			"wake":
				message.emit("The Stone Warden wakes! Dodge the ring, then strike while it is spent")
				shake.emit(1.2, 0.4)
			"windup":
				sound.emit("bow_draw", 0.9, 0.45)
			"slam":
				slam_pos = e["at"]
				slam_ring = 1.0
				shake.emit(2.0, 0.22)
				sound.emit("mine", 1.0, 0.5)
				_dust(e["at"], 20)
				if e["hit"]:
					hurt_player.emit(float(e["damage"]), model.pos, 1.6)
			"rock_land":
				_dust(e["at"], 9)
				sound.emit("mine", 0.7, 0.8)
				if e["hit"]:
					hurt_player.emit(float(e["damage"]), e["at"], 0.8)
			"enrage":
				message.emit("The Warden's core flares. The roof is coming down!")
				shake.emit(1.8, 0.5)

func _dust(at: Vector2, n: int) -> void:
	var p := CPUParticles2D.new()
	p.position = at
	p.one_shot = true
	p.emitting = true
	p.explosiveness = 0.95
	p.amount = n
	p.lifetime = 0.6
	p.direction = Vector2(0, -1)
	p.spread = 120.0
	p.initial_velocity_min = 30.0
	p.initial_velocity_max = 90.0
	p.gravity = Vector2(0, 240)
	p.scale_amount_min = 1.0
	p.scale_amount_max = 3.0
	p.color = Color(0.62, 0.55, 0.46)
	add_child(p)
	get_tree().create_timer(1.1).timeout.connect(p.queue_free)

func tick(d: float) -> void:
	t += d
	flash = maxf(0.0, flash - d * 5.0)
	slam_ring = maxf(0.0, slam_ring - d * 3.0)
	if model.state != "dead":
		var old := model.pos
		apply_events(model.step(player.position, d, rng))
		# stay on the hall floor
		var c := Vector2i(floori((model.pos.x - CaveView.ORIGIN.x) / 32.0), floori((model.pos.y - CaveView.ORIGIN.y) / 32.0))
		if not cave_model.is_floor(c) or cave_model.ores.has(c):
			model.pos = old
	sprite.frame = model.frame(t)
	if model.state == "walk" and model.vel.x != 0.0:
		sprite.flip_h = model.vel.x < 0.0
	sprite.modulate = Color(1.0 + flash, 1.0 + flash, 1.0 + flash, sprite.modulate.a)
	_place()
	shown_hp = move_toward(shown_hp, model.hp / model.max_hp, d * 0.8)
	queue_redraw()
	falling.queue_redraw()
	bar.size = get_viewport().get_visible_rect().size
	bar.queue_redraw()

func _ellipse(at: Vector2, r: float, col: Color, width: float) -> void:
	var pts := PackedVector2Array()
	for i in 29:
		var a := TAU * i / 28.0
		pts.append(at + Vector2(cos(a), sin(a)) * r)
	draw_polyline(pts, col, width)

func _draw() -> void:
	var k := model.telegraph()
	if k > 0.0:
		draw_circle(model.slam_at, BossModel.SLAM_RADIUS * k, Color(1.0, 0.25, 0.12, 0.22))
		_ellipse(model.slam_at, BossModel.SLAM_RADIUS, Color(1.0, 0.45, 0.2, 0.55 + 0.4 * k), 2.0)
	if slam_ring > 0.0:
		_ellipse(slam_pos, BossModel.SLAM_RADIUS * (1.0 + (1.0 - slam_ring) * 0.7), Color(1.0, 0.88, 0.6, slam_ring), 3.0)
	for r in model.rocks:
		var left := maxf(0.0, float(r["t"]))
		var at: Vector2 = r["pos"]
		if r["done"]:
			continue
		var grow := clampf(1.0 - left / BossModel.ROCK_MAX_T, 0.15, 1.0)
		draw_circle(at, BossModel.ROCK_RADIUS * grow, Color(0, 0, 0, 0.38))
		_ellipse(at, BossModel.ROCK_RADIUS, Color(1.0, 0.5, 0.2, 0.6), 1.0)

func _draw_falling() -> void:
	for r in model.rocks:
		var left := maxf(0.0, float(r["t"]))
		if r["done"] or left >= 0.45:
			continue
		var h := 170.0 * (1.0 - pow(1.0 - left / 0.45, 2.0))   # drops in for the last moments, speeding up
		falling.draw_texture(rock_tex, (r["pos"] as Vector2) + Vector2(-12, -18 - h))

func _draw_bar() -> void:
	if model.state == "sleep" or model.state == "dead":
		return
	var w := 300.0
	var o := Vector2((bar.size.x - w) * 0.5, 44.0)
	bar.draw_rect(Rect2(o - Vector2(6, 18), Vector2(w + 12, 34)), Color(0.12, 0.08, 0.06, 0.82))
	bar.draw_string(ThemeDB.fallback_font, o + Vector2(0, -5), "STONE WARDEN" + ("  (enraged)" if model.enraged else ""), HORIZONTAL_ALIGNMENT_CENTER, w, 11, Color(1.0, 0.88, 0.62))
	bar.draw_rect(Rect2(o, Vector2(w, 9)), Color(0.25, 0.14, 0.12))
	bar.draw_rect(Rect2(o, Vector2(w * shown_hp, 9)), Color(0.95, 0.85, 0.55))
	bar.draw_rect(Rect2(o, Vector2(w * model.hp / model.max_hp, 9)), Color(0.85, 0.28, 0.18) if not model.enraged else Color(1.0, 0.45, 0.1))
