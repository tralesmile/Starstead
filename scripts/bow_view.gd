class_name BowView
extends Node2D
## The bow in play (a child of World): hold the tool button to draw, release to loose. Arrows fly with BowMath
## (drag + storm wind), hit wild animals, stick in trees, walls or the ground, and can be walked over to take back.

signal message(msg: String)

const STUCK_SECONDS := 45.0
const PICK_RADIUS := 18.0

var player: Player
var animals: AnimalView
var solid_cb := Callable()   # (cell) -> bool: trees, rocks and walls stop arrows
var rain := 0.0
var day := 1
var drawing := false
var held_t := 0.0
var aim := Vector2.DOWN
var cd := 0.0
var flying: Array = []   # BowMath arrow dicts
var stuck: Array = []    # {pos, angle, t}
var tex: Texture2D = load("res://assets/sprites/arrow.png")
var rng := RandomNumberGenerator.new()

func _init() -> void:
	z_index = 12
	rng.randomize()

func press() -> bool:
	## Start drawing. False when there is nothing to nock or the last shot is still recovering.
	if drawing or cd > 0.0:
		return false
	if GameState.bag.count("arrow") < 1:
		message.emit("No arrows - craft them with C (wood + fibre)")
		return false
	if not GameState.energy.can_use("bow"):
		message.emit("Too tired")
		return false
	drawing = true
	held_t = 0.0
	return true

func release() -> bool:
	if not drawing:
		return false
	var power := BowMath.draw_power(held_t)
	cancel()
	if not BowMath.can_loose(power) or GameState.bag.count("arrow") < 1:
		return false
	GameState.bag.remove("arrow", 1)
	GameState.energy.spend("bow")
	loose(power)
	return true

func loose(power: float) -> void:
	flying.append(BowMath.launch(player.position, aim, power))
	cd = BowMath.COOLDOWN
	player.shake(0.6 + power, 0.08)

func cancel() -> void:
	drawing = false
	held_t = 0.0
	player.aim_slow = 1.0

func _process(delta: float) -> void:
	cd = maxf(0.0, cd - delta)
	if drawing:
		held_t += delta
		player.aim_slow = PlayerMath.draw_slow(BowMath.draw_power(held_t))
		player.held_tool = "hand"   # the drawn bow is painted here, turned to the aim
	var wind := BowMath.wind_accel(rain, PlayerMath.wind_angle(day))
	for i in range(flying.size() - 1, -1, -1):
		var a: Dictionary = flying[i]
		var from: Vector2 = a["pos"]
		var nx := BowMath.step(a, wind, delta)
		var to: Vector2 = nx["pos"]
		if animals != null and animals.shot(from, to, float(nx["dmg"])):
			if BowMath.recoverable(true, rng.randf()):
				GameState.bag.add("arrow", 1)   # pulled from the game
			flying.remove_at(i)
			continue
		var blocked := solid_cb.is_valid() and bool(solid_cb.call(Vector2i(floori(to.x / 32.0), floori(to.y / 32.0)))) and float(nx["flown"]) > 20.0
		if blocked or bool(nx["done"]):
			if BowMath.recoverable(false, rng.randf()):
				stuck.append({"pos": from if blocked else to, "angle": (nx["vel"] as Vector2).angle(), "t": STUCK_SECONDS})
			flying.remove_at(i)
			continue
		flying[i] = nx
	for i in range(stuck.size() - 1, -1, -1):
		stuck[i]["t"] = float(stuck[i]["t"]) - delta
		if (stuck[i]["pos"] as Vector2).distance_to(player.position) < PICK_RADIUS and float(stuck[i]["t"]) < STUCK_SECONDS - 0.6:
			GameState.bag.add("arrow", 1)
			stuck.remove_at(i)
		elif float(stuck[i]["t"]) <= 0.0:
			stuck.remove_at(i)
	queue_redraw()

func _draw() -> void:
	for s in stuck:
		var p: Vector2 = s["pos"]
		draw_set_transform(p + Vector2(0, -3), float(s["angle"]), Vector2.ONE)
		# only the shaft and fletching show: the head is buried
		draw_texture_rect_region(tex, Rect2(-8, -2.5, 11, 5), Rect2(0, 0, 11, 5), Color(1, 1, 1, clampf(float(s["t"]) / 5.0, 0.0, 1.0)))
	for a in flying:
		var p2: Vector2 = a["pos"]
		var ang: float = (a["vel"] as Vector2).angle()
		draw_set_transform(p2, ang, Vector2.ONE)
		draw_rect(Rect2(-7, -0.5, 14, 1), Color(0.05, 0.08, 0.04, 0.35))   # ground shadow
		var up := p2 + Vector2(0, -BowMath.lift(a))
		draw_set_transform(up, ang, Vector2.ONE)
		draw_line(Vector2(-22, 0), Vector2(-8, 0), Color(1, 1, 1, 0.28), 1.0)   # speed streak
		draw_texture(tex, Vector2(-8, -2.5))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if drawing and player != null:
		var power := BowMath.draw_power(held_t)
		var o := player.position + Vector2(0, -14)
		var col := Color(1.0, 0.85, 0.25) if power >= 1.0 else (Color(0.95, 0.95, 0.9) if BowMath.can_loose(power) else Color(0.7, 0.7, 0.7, 0.6))
		var d := aim.normalized()
		_draw_bow(player.position + Vector2(0, -17) + d * 10.0, d, power)
		for k in range(1, 2 + int(power * 6.0)):   # aim dots reach further as the draw grows
			draw_rect(Rect2((o + d * (14.0 + k * 9.0)).round() - Vector2(1, 1), Vector2(2, 2)), Color(col, 0.85 - k * 0.07))
		draw_rect(Rect2(player.position + Vector2(-11, -52), Vector2(22, 4)), Color(0, 0, 0, 0.6))
		draw_rect(Rect2(player.position + Vector2(-10, -51), Vector2(20.0 * power, 2)), col)

func _draw_bow(c: Vector2, d: Vector2, power: float) -> void:
	## The bow turned to the aim: limbs bend more and the string and nocked arrow come back as the draw grows.
	var side := d.orthogonal()
	var bend := 3.0 + 2.0 * power
	var pts := PackedVector2Array()
	for k in 9:
		var u := float(k) / 4.0 - 1.0   # -1..1 along the limbs
		pts.append(c + side * u * (11.0 - 1.5 * power) + d * (bend * (1.0 - u * u) - bend * 0.5))
	var nock := c - d * (bend * 0.5 + 6.0 * power)
	draw_polyline(PackedVector2Array([pts[0], nock, pts[8]]), Color(0.95, 0.93, 0.85), 1.0)
	draw_polyline(pts, Color(0.16, 0.1, 0.05), 4.0)
	draw_polyline(pts, Color(0.72, 0.48, 0.24), 2.0)
	draw_set_transform(nock, d.angle(), Vector2.ONE)
	draw_texture(tex, Vector2(0, -2.5))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
