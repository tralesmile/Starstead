class_name Player
extends CharacterBody2D
## Top-down 8-way player with 4-direction facing, placeholder walk cycle and follow camera.

var facing: int = PlayerMath.Facing.DOWN
var sprite: Sprite2D
var camera: Camera2D
var _t := 0.0
var tool_t := 0.0

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
	camera.position_smoothing_enabled = false  # integer pixel snap: no sub-pixel camera
	add_child(camera)

func _physics_process(delta: float) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = PlayerMath.accelerate(velocity, input, delta)
	facing = PlayerMath.facing_for(input, facing)  # face where the stick points, even while braking
	move_and_slide()
	var moving := velocity.length() > 8.0
	_t = _t + delta if moving else 0.0
	tool_t -= delta
	var col := PlayerMath.TOOL_FRAME if tool_t > 0.0 else PlayerMath.walk_frame_hd(_t, moving)
	sprite.frame = facing * 8 + col
	# rendering is pixel-snapped by the project setting; the body keeps sub-pixel position for smooth accel

func swing() -> void:
	## Show the tool pose briefly (called by main when a tool is used).
	tool_t = 0.18
