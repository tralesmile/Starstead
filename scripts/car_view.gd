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
var _skid_t := 0.0
var _smoke: CPUParticles2D
signal toast(msg: String)
signal crime(kind: String, pos: Vector2)

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
		var r := VehicleMath.step(vel, heading, th, st, hb, delta)
		vel = (r["vel"] as Vector2).limit_length(VehicleMath.speed_cap(health))
		heading = r["heading"]
	else:
		vel = vel.move_toward(Vector2.ZERO, 200.0 * delta)
	velocity = vel
	move_and_slide()
	if get_slide_collision_count() > 0:
		var dmg := VehicleMath.crash_damage(vel.length())
		if dmg > 0.0:
			health = maxf(0.0, health - dmg)
			toast.emit("Crash! Car health %d%%" % int(health))
			if dmg >= 8.0 and driving:
				crime.emit("hit_and_run", position)
		vel *= 0.4  # bump
	rotation = heading
	sprite.rotation = 0.0
	if driving:
		player.position = position
		player.ext_velocity = vel
	else:
		player.ext_velocity = Vector2.ZERO
	var skid := driving and VehicleMath.is_skidding(vel, heading)
	_smoke.emitting = skid
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
				m.modulate = Color(1, 1, 1, 0.7)
				world.add_child(m)
				var tw := m.create_tween()
				tw.tween_property(m, "modulate:a", 0.0, 6.0)
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
