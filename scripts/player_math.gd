class_name PlayerMath
extends RefCounted
## Pure movement/facing math (unit-tested without scenes).

enum Facing { DOWN, LEFT, UP, RIGHT }  # matches rows of assets/sprites/player.png
const SPEED := 90.0
const ACCEL := 900.0     # px/s^2: reaches full speed in 0.1 s
const FRICTION := 1200.0 # px/s^2: stops in 0.075 s, no ice-skating
const WALK_FPS := 10.0
const TOOL_FRAME := 7    # column of the tool-swing pose in player_hd.png

static func velocity(input: Vector2, speed: float = SPEED) -> Vector2:
	## 8-way: diagonal is normalized so it is not faster.
	return input.limit_length(1.0) * speed

static func facing_for(v: Vector2, current: int) -> int:
	if v.length() < 0.01:
		return current
	if absf(v.x) > absf(v.y):
		return Facing.RIGHT if v.x > 0 else Facing.LEFT
	if absf(v.y) > absf(v.x):
		return Facing.DOWN if v.y > 0 else Facing.UP
	return current  # pure diagonal keeps previous facing (no flicker)

static func walk_frame(t: float, moving: bool) -> int:
	## Frames 0,1,2 -> idle(0), step(1), idle-ish(2) cycle at ~8 fps.
	if not moving:
		return 0
	return [1, 0, 2, 0][int(t * 8.0) % 4]

static func facing_tile(pos: Vector2, facing: int, tile: int = 32) -> Vector2i:
	var dir: Vector2i = [Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1), Vector2i(1, 0)][facing]
	return Vector2i(floori(pos.x / tile), floori(pos.y / tile)) + dir

static func accelerate(v: Vector2, input: Vector2, delta: float, speed: float = SPEED) -> Vector2:
	## Smooth start/stop: move toward the target velocity with ACCEL, brake with FRICTION.
	var target := velocity(input, speed)
	var rate := ACCEL if target.length() > 0.01 else FRICTION
	return v.move_toward(target, rate * delta)

static func walk_frame_hd(t: float, moving: bool) -> int:
	## player_hd.png: column 0 idle, 1-6 walk cycle.
	if not moving:
		return 0
	return 1 + int(t * WALK_FPS) % 6
