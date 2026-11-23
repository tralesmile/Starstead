class_name CarView
extends CharacterBody2D
## Drivable car: E near it to get in/out, arrows/WASD to drive, use_tool (Space/F) = handbrake.
## Skid marks + tyre smoke when drifting; fuel from VehicleMath. The player body rides along.

var player: Player
var world: Node2D
var sprite: Sprite2D
var heading := 0.0
var vel := Vector2.ZERO
var driving := false
var fuel := VehicleMath.FUEL_MAX
var health := VehicleMath.HEALTH_MAX
var slip := 1.0          # slipstream factor set by the race (VehicleMath.slipstream)
var _skid_t := 0.0
var _prev_cap := 1.0
var _skid_a := 0.7
var _smoke_tile := 0
var _smoke_sdf := 5.0
var night := 0.0       # 0..1 from DayNight.lamp_strength, set by main
var _smoke: CPUParticles2D
var _head: Array[PointLight2D] = []
var _tail: Array[PointLight2D] = []
var _tail_glow: Array[Sprite2D] = []
var _braking := false
static var _cone: Texture2D = null

static func cone_texture() -> Texture2D:
	## Headlight beam: a cone that widens and fades with distance, starting at the left edge of the image.
	if _cone == null:
		var w := 192
		var h := 128
		var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
		for x in w:
			var u := float(x) / w
			var half := 0.22 + 0.78 * u
			for y in h:
				var vv := absf((y - h * 0.5) / (h * 0.5))
				var a := clampf(1.0 - vv / half, 0.0, 1.0) * pow(1.0 - u, 1.3)
				img.set_pixel(x, y, Color(1, 1, 1, a))
		_cone = ImageTexture.create_from_image(img)
	return _cone
signal toast(msg: String)
signal crime(kind: String, pos: Vector2)
signal drift_banked(points: int)
signal impact(pos: Vector2, bits: int)   # wall hit: dust and debris
var drift := DriftScore.new()
var _on_circuit := false

func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	sprite = Sprite2D.new()
	sprite.texture = load("res://assets/sprites/car.png")
	sprite.offset = Vector2(0, -6)
	add_child(sprite)
	var sh := World.make_shadow(30)
	add_child(sh)
	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(24, 12)
	cs.shape = rs
	add_child(cs)
	_smoke = CPUParticles2D.new()
	_smoke.emitting = false
	_smoke.amount = 14
	_smoke.lifetime = 0.6
	_smoke.direction = Vector2(0, -1)
	_smoke.spread = 60.0
	_smoke.initial_velocity_min = 6.0
	_smoke.initial_velocity_max = 16.0
	_smoke.scale_amount_min = 1.5
	_smoke.scale_amount_max = 3.0
	_smoke.color = Color(0.85, 0.85, 0.85, 0.5)
	add_child(_smoke)
	for sy in [-4.0, 4.0]:
		var hl := PointLight2D.new()
		hl.texture = cone_texture()
		hl.offset = Vector2(96, 0)
		hl.position = Vector2(12, sy)
		hl.color = Color(1.0, 0.94, 0.75)
		hl.energy = 0.0
		hl.texture_scale = 0.6
		add_child(hl)
		_head.append(hl)
		var tl := PointLight2D.new()
		tl.texture = Lantern.light_texture()
		tl.position = Vector2(-13, sy * 1.4)
		tl.color = Color(1.0, 0.15, 0.1)
		tl.energy = 0.0
		tl.texture_scale = 0.35
		add_child(tl)
		_tail.append(tl)

func can_enter() -> bool:
	return not driving and player != null and player.position.distance_to(position) < 34.0

func enter() -> void:
	driving = true
	add_collision_exception_with(player)
	player.add_collision_exception_with(self)
	player.velocity = Vector2.ZERO
	player.move_v = Vector2.ZERO
	player.set_physics_process(false)
	player.sprite.visible = false
	toast.emit("Driving: arrows steer, F handbrake, E exit. Fuel %d%%" % int(100.0 * fuel / VehicleMath.FUEL_MAX))

func leave() -> bool:
	if vel.length() > 40.0:
		toast.emit("Slow down to get out")
		return false
	driving = false
	remove_collision_exception_with(player)
	player.remove_collision_exception_with(self)
	vel = Vector2.ZERO
	var side := VehicleMath.forward(heading).orthogonal()
	player.position = position + side * 24.0
	player.sprite.visible = true
	player.set_physics_process(true)
	return true

func _physics_process(delta: float) -> void:
	if driving:
		var th := -Input.get_axis("move_up", "move_down")
		var st := Input.get_axis("move_left", "move_right")
		var hb := Input.is_action_pressed("use_tool")
		th = VehicleMath.throttle_with_fuel(th, fuel)
		fuel = VehicleMath.fuel_after(fuel, th, delta)
		var grip_m := 1.0
		var surf := 1.0
		var g = world.gen if world != null and "gen" in world else null
		if g != null:
			var cc := Vector2i(floori(position.x / 32.0), floori(position.y / 32.0))
			var tt: int = g.tile_at(cc.x, cc.y)
			surf = VehicleMath.surface_cap(WorldGen.is_road(tt), g.sdf_at(cc.x, cc.y), player.rain, CityModel.is_sidewalk(cc) or HarbourModel.is_quay(cc))
			grip_m = VehicleMath.surface_grip(tt, g.sdf_at(cc.x, cc.y), player.rain)
			_smoke_tile = tt
			_smoke_sdf = g.sdf_at(cc.x, cc.y)
			_skid_a = VehicleMath.skid_alpha(tt, g.sdf_at(cc.x, cc.y), player.rain)
			_on_circuit = CircuitModel.on_circuit(cc)
			if CircuitModel.is_infield(cc):
				surf = minf(surf, DriftScore.pit_cap(true))   # pit lane / infield speed limit
			var kb := VehicleMath.kerb_bump(vel.length(), _prev_cap, surf)
			if float(kb["factor"]) < 1.0:
				vel *= float(kb["factor"])
				player.shake(float(kb["shake"]), 0.15)
			_prev_cap = surf
			var rb := VehicleMath.rumble(vel.length(), CircuitModel.is_kerb(cc))
			if float(rb["shake"]) > 0.0:
				grip_m *= float(rb["grip"])
				player.shake(float(rb["shake"]), 0.1)
		var r := VehicleMath.step(vel, heading, th, st, hb, delta, grip_m)
		vel = (r["vel"] as Vector2).limit_length(VehicleMath.speed_cap(health) * surf * slip)
		heading = r["heading"]
	else:
		vel = vel.move_toward(Vector2.ZERO, 200.0 * delta)
	velocity = vel
	move_and_slide()
	if get_slide_collision_count() > 0:
		var dmg := VehicleMath.crash_damage(vel.length())
		if dmg > 0.0:
			health = maxf(0.0, health - dmg)
			drift.crash()
			toast.emit("Crash! Car health %d%%" % int(health))
			if dmg >= 8.0 and driving:
				crime.emit("hit_and_run", position)
		var cn := get_slide_collision(0).get_normal()
		var bits := VehicleMath.crash_dust(vel, cn)
		if bits > 0:
			impact.emit(position - cn * 14.0, bits)
		var cr := VehicleMath.crash_response(vel, cn, heading)
		vel = cr["vel"]
		heading += float(cr["spin"])   # nose shoved off the wall, no more dead stop against it
	rotation = heading
	sprite.rotation = 0.0
	var fwd_speed := vel.dot(VehicleMath.forward(heading))
	_braking = driving and VehicleMath.is_braking(-Input.get_axis("move_up", "move_down"), fwd_speed, Input.is_action_pressed("use_tool"))
	var lv := VehicleMath.light_levels(night if driving or vel.length() > 5.0 else night * 0.0, _braking)
	for hl in _head:
		hl.energy = 1.7 * float(lv["head"])
		hl.visible = hl.energy > 0.01
	for tl in _tail:
		tl.energy = 1.2 * float(lv["tail"])
		tl.visible = tl.energy > 0.01
	if driving:
		player.position = position
		player.ext_velocity = vel
	else:
		player.ext_velocity = Vector2.ZERO
	if driving and _on_circuit:
		var pts := drift.step(VehicleMath.slip(vel, heading), vel.length(), delta)
		if pts > 0:
			drift_banked.emit(pts)
	else:
		drift.crash()
	var skid := driving and VehicleMath.is_skidding(vel, heading)
	_squeal_tick(driving, vel)
	_smoke.emitting = skid
	if skid:
		var ss := VehicleMath.smoke_style(VehicleMath.slip(vel, heading), _smoke_tile, _smoke_sdf, player.rain)
		_smoke.amount = int(ss["amount"])
		_smoke.color = ss["color"]
		_smoke.scale_amount_max = float(ss["size"])
	_smoke.position = -VehicleMath.forward(heading).rotated(-heading) * 10.0
	if skid:
		_skid_t -= delta
		if _skid_t <= 0.0 and world != null:
			_skid_t = 0.05
			for p in VehicleMath.wheel_points(position, heading):
				var m := Sprite2D.new()
				m.texture = load("res://assets/sprites/skid.png")
				m.position = p.round()
				m.z_index = -2
				m.modulate = Color(1, 1, 1, _skid_a)
				world.add_child(m)
				var tw := m.create_tween()
				tw.tween_property(m, "modulate:a", 0.0, VehicleMath.skid_life(_on_circuit, player.rain))
				tw.tween_callback(m.queue_free)

func repair(bag: Inventory) -> String:
	## Spend wood to restore health (all-or-nothing). Returns a message or "".
	var cost := VehicleMath.repair_cost(health)
	if cost == 0:
		return ""
	if not bag.remove("wood", cost):
		return "Car needs %d wood to repair" % cost
	health = VehicleMath.HEALTH_MAX
	return "Car repaired (-%d wood)" % cost

var _squeal: AudioStreamPlayer

func _squeal_tick(driving: bool, vel: Vector2) -> void:
	## Looping procedural tyre noise (SquealMath): louder on asphalt, near silent on grass, muffled in rain.
	if _squeal == null:
		var w := AudioStreamWAV.new()
		w.format = AudioStreamWAV.FORMAT_16_BITS
		w.mix_rate = SquealMath.RATE
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_end = 4410
		w.data = SquealMath.loop_samples()
		_squeal = AudioStreamPlayer.new()
		_squeal.stream = w
		_squeal.volume_db = SquealMath.SILENT_DB
		add_child(_squeal)
	var lv := 0.0
	if driving:
		lv = SquealMath.level(VehicleMath.slip(vel, heading), vel.length(), _smoke_tile, _smoke_sdf, player.rain)
	_squeal.volume_db = SquealMath.volume_db(lv)
	_squeal.pitch_scale = SquealMath.pitch(vel.length())
	if lv > 0.01 and not _squeal.playing:
		_squeal.play()
	elif lv <= 0.01 and _squeal.playing:
		_squeal.stop()
