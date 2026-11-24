class_name Player
extends CharacterBody2D
## Top-down 8-way player with 4-direction facing, placeholder walk cycle and follow camera.

var facing: int = PlayerMath.Facing.DOWN
var speed_mult := 1.0  # >1 while riding
var sneaking := false  # Ctrl held: slow and quiet (wild animals spook from half the distance)
var sprinting := false
var zoom_step := TargetMath.DEFAULT_STEP     # user zoom step 1..4 (TargetMath.ZOOMS)
var indoors := false   # inside a room or the mine: no shore slowdown, no water reflection
var focus: Variant = null   # Vector2: room centre while indoors (camera leans toward it)
var zoom_bias := 0     # -1 while driving/riding
var rain := 0.0   # current rain 0..1 (set by main): muddy ground
var sprite: Sprite2D
var camera: Camera2D
var _t := 0.0
var tool_t := 0.0
var gen: WorldGen = null      # set by main: terrain speed lookup
var move_v := Vector2.ZERO    # input-driven velocity (knockback is added on top)
var knock := Vector2.ZERO
var squash_left := 0.0
var shake_left := 0.0
var shake_total := 0.2
var shake_amp := 1.0
var _last_frame := 0
var held: Sprite2D
var refl: Sprite2D
var held_tool := ""   # set by main when a tool is used
var swing_total := 0.18
var cam_focus := Vector2.ZERO  # dead-zone camera focus (world px)
var ext_velocity := Vector2.ZERO  # set by the car while driving so the camera can look ahead
var look := Vector2.ZERO     # eased look-ahead (camera offset), snapped to whole pixels when applied
signal footstep
signal skid(amount: int)
var _sprint := 1.0
var _sprint_lvl := 0.0
var _punch := 0.0
var _base_zoom := 0.0
var _skid_cd := 0.0
var _idle_t := 0.0     # seconds standing still: the dead-zone camera drifts back to centre after a moment

func _ready() -> void:
	sprite = Sprite2D.new()
	sprite.texture = load("res://assets/sprites/player_hd.png")
	sprite.hframes = 8
	sprite.vframes = 4
	sprite.offset = Vector2(0, -22)  # feet (y=46 of the 48px frame) on the body origin
	add_child(sprite)
	var sh := World.make_shadow(20)
	sh.scale = Vector2(0.6, 0.7)
	add_child(sh)
	refl = Sprite2D.new()
	refl.texture = sprite.texture
	refl.hframes = 8
	refl.vframes = 4
	refl.flip_v = true
	refl.offset = Vector2(0, 22 - 2)
	refl.modulate = Color(0.45, 0.68, 0.74, 0.34)
	refl.z_index = -6
	refl.visible = false
	add_child(refl)
	held = Sprite2D.new()
	held.texture = load("res://assets/sprites/held_tools.png")
	held.hframes = 8
	held.visible = false
	held.centered = true
	add_child(held)
	var cs := CollisionShape2D.new()
	var r := CapsuleShape2D.new()  # rounded feet collider: slides around tree trunks instead of snagging
	r.radius = 5.0
	r.height = 14.0
	cs.shape = r
	cs.rotation = PI / 2.0
	add_child(cs)
	camera = Camera2D.new()
	camera.zoom = Vector2.ONE * TargetMath.zoom_value(zoom_step)
	for a in OS.get_cmdline_user_args():  # screenshot helper: -- --zoom=1 --at=x,y (tiles)
		if a.begins_with("--zoom="):
			camera.zoom = Vector2.ONE * float(a.substr(7))
			zoom_step = TargetMath.step_for_zoom(float(a.substr(7)))
			zoom_bias = 0
		elif a.begins_with("--at="):
			var xy := a.substr(5).split(",")
			position = Vector2(float(xy[0]), float(xy[1])) * 32.0
	camera.limit_left = int(ChunkGrid.world_rect_px().position.x)
	camera.limit_top = int(ChunkGrid.world_rect_px().position.y)
	camera.limit_right = int(ChunkGrid.world_rect_px().end.x)
	camera.limit_bottom = int(ChunkGrid.world_rect_px().end.y)
	camera.position_smoothing_enabled = false  # integer pixel snap: no sub-pixel camera
	add_child(camera)

func _physics_process(delta: float) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var mult := 1.0
	var grip := 1.0
	if gen != null and not indoors:
		var c := Vector2i(floori(position.x / 32.0), floori(position.y / 32.0))
		var on_path := WorldGen.is_road(gen.tile_at(c.x, c.y))
		mult = PlayerMath.terrain_factor(gen.sdf_at(c.x, c.y), on_path) * PlayerMath.wet_speed(rain, on_path)
		grip = PlayerMath.wet_grip(rain, on_path) * PlayerMath.snow_grip(GameState.clock.season(), on_path)
		mult *= PlayerMath.snow_speed(GameState.clock.season(), on_path)
	grip *= PlayerMath.ride_grip(speed_mult) * PlayerMath.load_grip(GameState.bag.fill_fraction())
	var sp_t := PlayerMath.sprint_mult(Input.is_action_pressed("sprint"), input.length() > 0.1, GameState.energy.value)
	if sp_t > 1.0:
		GameState.energy.value = maxf(GameState.energy.value - PlayerMath.sprint_cost(delta), 0.0)
	_sprint = PlayerMath.sprint_ease(_sprint, sp_t, delta)
	sprinting = sp_t > 1.0
	sneaking = Input.is_action_pressed("sneak") and not sprinting
	var sp := _sprint
	_skid_cd -= delta
	if _skid_cd <= 0.0 and PlayerMath.is_skid(move_v, input):
		skid.emit(PlayerMath.skid_dust_amount(move_v.length()))
		_skid_cd = 0.25
	move_v = PlayerMath.accelerate(move_v, input, delta, PlayerMath.SPEED * mult * sp * PlayerMath.sneak_mult(sneaking) * PlayerMath.boots_mult(GameState.bag.count("leather_boots")) * PlayerMath.tired_mult(GameState.energy.value) * PlayerMath.load_mult(GameState.bag.fill_fraction()) * speed_mult * PlayerMath.swing_slow(tool_t, PlayerMath.tool_plant(held_tool)), grip)
	knock = HitMath.decay(knock, delta)
	velocity = move_v + knock
	facing = PlayerMath.facing_for(input, facing)  # face where the stick points, even while braking
	move_and_slide()
	var moving := velocity.length() > 8.0
	_t = _t + delta if moving else 0.0
	tool_t -= delta
	if squash_left > 0.0:
		squash_left = maxf(squash_left - delta, 0.0)
	sprite.scale = HitMath.squash(squash_left, 0.22)
	var col := PlayerMath.TOOL_FRAME if tool_t > 0.0 else PlayerMath.walk_frame_hd(_t, moving)
	sprite.frame = facing * 8 + col
	if moving and tool_t <= 0.0:
		if PlayerMath.footstep_due(_last_frame, col):
			footstep.emit()
	_last_frame = col
	_update_held()
	refl.visible = false if indoors else refl.visible
	if gen != null and not indoors:
		var rc := Vector2i(floori(position.x / 32.0), floori(position.y / 32.0))
		refl.visible = gen.sdf_at(rc.x, rc.y + 1) < -0.2 or (rc in gen.dock) or gen.sdf_at(rc.x, rc.y) < 0.0
		refl.frame = sprite.frame
		refl.scale = sprite.scale
	var cam_v := move_v + ext_velocity
	look = CameraMath.ease_offset(look, CameraMath.look_vec(cam_v), delta)
	var sh := Vector2.ZERO
	if shake_left > 0.0:
		shake_left -= delta
		sh = HitMath.shake_offset(shake_left, shake_total, shake_amp, _t + shake_left)
	var pull := Vector2.ZERO
	if focus != null:
		pull = ((focus as Vector2) - position) * 0.75
	if cam_focus == Vector2.ZERO or cam_focus.distance_to(position) > 200.0:
		cam_focus = position  # first frame / teleport (doors, car exit)
	cam_focus = CameraMath.deadzone(cam_focus, position, CameraMath.box_for_speed(cam_v.length()))
	_idle_t = 0.0 if cam_v.length() > 8.0 else _idle_t + delta
	cam_focus = CameraMath.recenter(cam_focus, position, _idle_t, delta)
	camera.offset = CameraMath.snap(look + pull + (cam_focus - position)) + sh
	var zt := TargetMath.zoom_value(TargetMath.effective_zoom(zoom_step, zoom_bias))
	if _base_zoom <= 0.0:
		_base_zoom = camera.zoom.x   # start from the zoom set in _ready (or a --zoom= flag)
	if absf(_base_zoom - zt) > 0.01:
		_base_zoom = move_toward(_base_zoom, zt, delta * 8.0)  # quick glide between zoom steps
	# sprint zoom punch: a quick kick out when the sprint starts, then a slight hold while running
	var lvl := CameraMath.sprint_level(_sprint, PlayerMath.SPRINT_MULT)
	if CameraMath.sprint_starts(_sprint_lvl, lvl):
		_punch = 1.0
	_sprint_lvl = lvl
	_punch = CameraMath.punch_decay(_punch, delta)
	camera.zoom = Vector2.ONE * _base_zoom * CameraMath.sprint_zoom(lvl, _punch)
	# rendering is pixel-snapped by the project setting; the body keeps sub-pixel position for smooth accel

func shake(amp: float = 1.0, secs: float = 0.15) -> void:
	shake_amp = amp
	shake_total = secs
	shake_left = secs

func push(from: Vector2, force: float = 1.0) -> void:
	knock = HitMath.knockback(from, position, force)

func swing() -> void:
	## Show the tool pose briefly (called by main when a tool is used).
	tool_t = 0.18
	squash_left = 0.22

func _update_held() -> void:
	var f := ToolUse.held_frame(held_tool)
	if tool_t <= 0.0 or f < 0:
		held.visible = false
		return
	held.visible = true
	held.frame = f
	var dir := {PlayerMath.Facing.DOWN: Vector2(7, -12), PlayerMath.Facing.UP: Vector2(-7, -26), PlayerMath.Facing.LEFT: Vector2(-10, -17), PlayerMath.Facing.RIGHT: Vector2(10, -17)}
	held.position = dir[facing]
	held.flip_h = facing == PlayerMath.Facing.LEFT
	held.z_index = -1 if facing == PlayerMath.Facing.UP else 1
	var a := HitMath.hoe_angle(tool_t, swing_total) if held_tool == "hoe" else HitMath.swing_angle(tool_t, swing_total)
	held.rotation = -a if held.flip_h else a
