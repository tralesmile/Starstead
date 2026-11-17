class_name Player
extends CharacterBody2D
## Top-down 8-way player with 4-direction facing, placeholder walk cycle and follow camera.

var facing: int = PlayerMath.Facing.DOWN
var speed_mult := 1.0  # >1 while riding
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
var held_tool := ""   # set by main when a tool is used
var swing_total := 0.18
var look := Vector2.ZERO     # eased look-ahead (camera offset), snapped to whole pixels when applied
signal footstep

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
	held = Sprite2D.new()
	held.texture = load("res://assets/sprites/held_tools.png")
	held.hframes = 7
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
	camera.zoom = Vector2(2, 2)  # integer zoom keeps pixels crisp; closer, more detailed view
	for a in OS.get_cmdline_user_args():  # screenshot helper: -- --zoom=1 --at=x,y (tiles)
		if a.begins_with("--zoom="):
			camera.zoom = Vector2.ONE * float(a.substr(7))
		elif a.begins_with("--at="):
			var xy := a.substr(5).split(",")
			position = Vector2(float(xy[0]), float(xy[1])) * 32.0
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = 64 * 32
	camera.limit_bottom = 64 * 32
	camera.position_smoothing_enabled = false  # integer pixel snap: no sub-pixel camera
	add_child(camera)

func _physics_process(delta: float) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var mult := 1.0
	var grip := 1.0
	if gen != null:
		var c := Vector2i(floori(position.x / 32.0), floori(position.y / 32.0))
		var on_path := gen.tile_at(c.x, c.y) >= WorldGen.PATH and gen.tile_at(c.x, c.y) < WorldGen.PATH + 3
		mult = PlayerMath.terrain_factor(gen.sdf_at(c.x, c.y), on_path) * PlayerMath.wet_speed(rain, on_path)
		grip = PlayerMath.wet_grip(rain, on_path)
	var sp := PlayerMath.sprint_mult(Input.is_action_pressed("sprint"), input.length() > 0.1, GameState.energy.value)
	if sp > 1.0:
		GameState.energy.value = maxf(GameState.energy.value - PlayerMath.sprint_cost(delta), 0.0)
	move_v = PlayerMath.accelerate(move_v, input, delta, PlayerMath.SPEED * mult * sp * speed_mult, grip)
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
	look = CameraMath.ease_offset(look, CameraMath.look_target(move_v, PlayerMath.SPEED), delta)
	var sh := Vector2.ZERO
	if shake_left > 0.0:
		shake_left -= delta
		sh = HitMath.shake_offset(shake_left, shake_total, shake_amp, _t + shake_left)
	camera.offset = CameraMath.snap(look) + sh
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
	var a := HitMath.swing_angle(tool_t, swing_total)
	held.rotation = -a if held.flip_h else a
