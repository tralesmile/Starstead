class_name Player
extends CharacterBody2D
## Top-down 8-way player with 4-direction facing, placeholder walk cycle and follow camera.

var facing: int = PlayerMath.Facing.DOWN
var sprite: Sprite2D
var camera: Camera2D
var _t := 0.0

func _ready() -> void:
	sprite = Sprite2D.new()
	sprite.texture = load("res://assets/sprites/player.png")
	sprite.hframes = 3
	sprite.vframes = 4
	sprite.offset = Vector2(0, -12)
	add_child(sprite)
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(14, 8)
	cs.shape = r
	add_child(cs)
	camera = Camera2D.new()
	camera.position_smoothing_enabled = false  # integer pixel snap: no sub-pixel camera
	add_child(camera)

func _physics_process(delta: float) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = PlayerMath.velocity(input)
	facing = PlayerMath.facing_for(velocity, facing)
	move_and_slide()
	_t += delta if velocity != Vector2.ZERO else 0.0
	sprite.frame = facing * 3 + PlayerMath.walk_frame(_t, velocity != Vector2.ZERO)
	position = position.round()  # pixel snap
