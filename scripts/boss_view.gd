class_name BossView
extends Node2D
## The Stone Warden in the mine hall: sprite, warning ring, falling rocks and the health bar. Rules are in BossModel.

signal hurt_player(amount: float, from: Vector2, force: float)
signal defeated(pos: Vector2)
signal shake(amp: float, secs: float)
signal sound(name: String, gain: float, pitch: float)
signal message(msg: String)
signal prop_hit(cell: Vector2i, kind: String)

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
var boulder_node: Node2D      # y-sorted in the world like `body`: the held or rolling boulder
var boulder_sprite: Sprite2D
var boulder_shadow: Node2D
var _step_frame := 0          # last walking frame, to catch each footfall
var _quake_left := 0.0        # a big shake is playing: footfalls must not replace it
var _told_aim := false
var _told_punish := false

const BOULDER_FRAMES := 16

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
	model.solid = cm.is_solid
	model.grid_origin = CaveView.ORIGIN
	model.props = boulder_props(cm, CaveView.ORIGIN)
	boulder_node = Node2D.new()
	boulder_shadow = World.make_shadow(22.0)
	boulder_shadow.position = Vector2(0, 2)
	boulder_node.add_child(boulder_shadow)
	boulder_sprite = Sprite2D.new()
	boulder_sprite.texture = load("res://assets/sprites/cave_boulder.png")
	boulder_sprite.hframes = BOULDER_FRAMES
	boulder_node.add_child(boulder_sprite)
	boulder_node.visible = false
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

static func boulder_props(cm: CaveModel, origin: Vector2) -> Array:
	var out: Array = []
	for item in HallDecor.layout(cm):
		if item["solid"]:
			out.append({"kind": item["kind"], "cell": item["cell"], "rect": BossModel.prop_rect(item["cell"], origin)})
	return out

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
		boulder_node.visible = false
		_quake(2.5, 0.5)
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
				_quake(1.2, 0.4)
			"aim":
				sound.emit("bow_draw", 1.0, 0.35)
				if not _told_aim:
					_told_aim = true
					message.emit("The Warden heaves up a boulder! Step out of its lane")
			"throw":
				_quake(1.4, 0.18)
				_dust(e["at"], 10)
				sound.emit("tree_fall", 0.7, 1.3)
			"bounce":
				_dust(e["at"], 7)
				_quake(1.0, 0.1)
				sound.emit("mine", 0.8, 0.65)
			"prop_hit":
				prop_hit.emit(e["cell"], e["kind"])
				var brazier: bool = e["kind"] == "brazier"
				_dust(e["at"], 8 if brazier else 18)
				_quake(0.9 if brazier else 1.8, 0.14)
				sound.emit("chop" if brazier else "mine", 0.9, 0.7 if brazier else 0.55)
			"boulder_hit":
				var heading := (e["vel"] as Vector2).normalized()
				hurt_player.emit(float(e["damage"]), player.position - heading * 8.0, float(e["force"]))
				_quake(2.0, 0.18)
			"shatter":
				_dust(e["at"], 28)
				_shards(e["at"])
				_quake(1.6, 0.2)
				sound.emit("mine", 1.0, 0.45)
				if not _told_punish:
					_told_punish = true
					message.emit("The boulder breaks apart and the Warden is spent. Rush in and strike!")
			"windup":
				sound.emit("bow_draw", 0.9, 0.45)
			"slam":
				slam_pos = e["at"]
				slam_ring = 1.0
				_quake(2.0, 0.22)
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
				_quake(1.8, 0.5)

func _quake(amp: float, secs: float) -> void:
	_quake_left = secs
	shake.emit(amp, secs)

## A thud each time the walk cycle changes foot: a puff of dust, and a tiny shake that fades with distance.
func _footfall() -> void:
	if model.state != "walk" or model.vel.length() < 12.0:
		_step_frame = 0
		return
	var f := sprite.frame
	if _step_frame != 0 and f != _step_frame:
		var foot := model.pos + Vector2(-13.0 if f == 1 else 13.0, 1.0)
		_puff(foot, 7 if model.enraged else 4)
		var amp := BossModel.step_amp(model.pos.distance_to(player.position), model.enraged)
		if amp > 0.0 and _quake_left <= 0.0:
			shake.emit(amp, BossModel.STEP_SHAKE_TIME)
	_step_frame = f

func _puff(at: Vector2, n: int) -> void:
	var p := CPUParticles2D.new()
	p.position = at
	p.one_shot = true
	p.emitting = true
	p.explosiveness = 1.0
	p.amount = n
	p.lifetime = 0.4
	p.direction = Vector2(0, -1)
	p.spread = 85.0
	p.initial_velocity_min = 12.0
	p.initial_velocity_max = 34.0
	p.gravity = Vector2(0, 70)
	p.scale_amount_min = 1.0
	p.scale_amount_max = 2.0
	p.color = Color(0.66, 0.59, 0.5, 0.8)
	add_child(p)
	get_tree().create_timer(0.8).timeout.connect(p.queue_free)

## Chunks of stone thrown out when the boulder breaks.
func _shards(at: Vector2) -> void:
	var p := CPUParticles2D.new()
	p.position = at + Vector2(0, -8)
	p.one_shot = true
	p.emitting = true
	p.explosiveness = 1.0
	p.amount = 12
	p.lifetime = 0.55
	p.direction = Vector2(0, -1)
	p.spread = 180.0
	p.initial_velocity_min = 60.0
	p.initial_velocity_max = 150.0
	p.gravity = Vector2(0, 320)
	p.scale_amount_min = 3.0
	p.scale_amount_max = 5.0
	p.color = Color(0.42, 0.37, 0.34)
	add_child(p)
	get_tree().create_timer(1.0).timeout.connect(p.queue_free)

func _place_boulder() -> void:
	var held := model.state == "aim"
	boulder_node.visible = held or not model.boulder.is_empty()
	if held:   # hoisted overhead, swelling into view; sorted just in front of the Warden
		var k := clampf(model.aim_progress() * 2.5, 0.0, 1.0)
		boulder_node.position = model.pos + Vector2(0, 1)
		boulder_sprite.position = Vector2(0, roundf(lerpf(-30.0, -66.0, k)))
		boulder_sprite.frame = 0
		boulder_shadow.visible = false
	elif not model.boulder.is_empty():
		boulder_node.position = model.boulder["pos"]
		boulder_sprite.position = Vector2(0, -9)
		boulder_sprite.frame = BossModel.roll_frame(float(model.boulder["spin"]), BOULDER_FRAMES)
		boulder_shadow.visible = true

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
	_quake_left = maxf(0.0, _quake_left - d)
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
	elif model.state == "aim" and absf(model.aim_dir.x) > 0.1:
		sprite.flip_h = model.aim_dir.x < 0.0
	sprite.modulate = Color(1.0 + flash, 1.0 + flash, 1.0 + flash, sprite.modulate.a)
	_footfall()
	_place()
	_place_boulder()
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

## The boulder's warning: a straight amber lane with marching chevrons (the slam is a red ring). It follows the
## player with dashed edges, then locks: solid, bright edges. The short tail shows where it will rebound.
func _draw_lane() -> void:
	if model.state != "aim":
		return
	var pts := BossModel.trace_lane(model.throw_origin(), model.aim_dir, model.solid, model.grid_origin, 440.0, 56.0, model.props)
	var from := pts[0]
	var to := pts[1]
	var length := from.distance_to(to)
	if length < 1.0:
		return
	var dir := (to - from) / length
	var side := dir.orthogonal() * BossModel.BOULDER_HIT_R
	var locked := model.aim_locked()
	var k := model.aim_progress()
	var edge := Color(1.0, 0.95, 0.55, 1.0) if locked else Color(1.0, 0.8, 0.2, 0.75)
	draw_colored_polygon(PackedVector2Array([from + side, to + side, to - side, from - side]), Color(1.0, 0.78, 0.1, 0.3 if locked else 0.1 + 0.1 * k))
	for s in [side, -side]:
		if locked:
			draw_line(from + s, to + s, edge, 2.0)
		else:
			draw_dashed_line(from + s, to + s, edge, 1.0, 6.0)
	var x := fposmod(t * (90.0 if locked else 45.0), 26.0) + 8.0
	while x < length:
		var tip := from + dir * x
		draw_polyline(PackedVector2Array([tip - dir * 7.0 + side * 0.55, tip, tip - dir * 7.0 - side * 0.55]), edge, 2.0)
		x += 26.0
	if pts.size() > 2 and to.distance_to(pts[2]) > 1.0:
		draw_dashed_line(to, pts[2], Color(1.0, 0.8, 0.2, 0.6), 2.0, 4.0)

func _draw() -> void:
	_draw_lane()
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
	var panel := BossBarLayout.panel(bar.size)   # low on the screen, clear of the prompt and hotbar
	var on_screen: Rect2 = body.get_global_transform_with_canvas() * Rect2(-30, -66, 60, 70)
	bar.modulate.a = move_toward(bar.modulate.a, BossBarLayout.alpha_for(panel, on_screen), 0.15)
	var w := panel.size.x - 12.0
	var o := panel.position + Vector2(6, 16)
	bar.draw_rect(panel, Color(0.12, 0.08, 0.06, 0.82))
	bar.draw_string(ThemeDB.fallback_font, o + Vector2(0, -5),"STONE WARDEN" + ("  (enraged)" if model.enraged else ""), HORIZONTAL_ALIGNMENT_CENTER, w, 11, Color(1.0, 0.88, 0.62))
	bar.draw_rect(Rect2(o, Vector2(w, 9)), Color(0.25, 0.14, 0.12))
	bar.draw_rect(Rect2(o, Vector2(w * shown_hp, 9)), Color(0.95, 0.85, 0.55))
	bar.draw_rect(Rect2(o, Vector2(w * model.hp / model.max_hp, 9)), Color(0.85, 0.28, 0.18) if not model.enraged else Color(1.0, 0.45, 0.1))
