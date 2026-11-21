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

static func accelerate(v: Vector2, input: Vector2, delta: float, speed: float = SPEED, grip: float = 1.0) -> Vector2:
	## Smooth start/stop: move toward the target velocity with ACCEL, brake with FRICTION. grip < 1 = slippery.
	var target := velocity(input, speed)
	var rate := (ACCEL if target.length() > 0.01 else FRICTION) * grip
	return v.move_toward(target, rate * delta)

static func walk_frame_hd(t: float, moving: bool) -> int:
	## player_hd.png: column 0 idle, 1-6 walk cycle.
	if not moving:
		return 0
	return 1 + int(t * WALK_FPS) % 6

const WET_BANK_FACTOR := 0.8   # squelching along the water's edge
const PATH_FACTOR := 1.1       # packed dirt paths are quicker

static func terrain_factor(sdf: float, on_path: bool) -> float:
	## Speed multiplier from the ground under the feet. sdf >= 0 is land; the first tile of
	## land next to the water is wet. Water itself is blocked by collision, so this never
	## needs a deep-water case.
	if sdf < 0.0:
		return 0.6  # wading (dock gaps, future shallow ford)
	if sdf < 0.9:
		return WET_BANK_FACTOR
	return PATH_FACTOR if on_path else 1.0

static func footstep_due(prev_frame: int, frame: int) -> bool:
	## A footfall lands when the walk cycle enters frame 2 or 5 (feet pass the body) from another frame.
	return frame != prev_frame and (frame == 2 or frame == 5)

static func wet_grip(rain: float, on_path: bool) -> float:
	## Rain turns dirt paths to mud: slower to start and slower to stop (a little slide). Grass keeps more grip.
	var k := 0.45 if on_path else 0.25
	return 1.0 - k * clampf(rain, 0.0, 1.0)

static func wet_speed(rain: float, on_path: bool) -> float:
	## Mud also drags: paths lose their speed bonus in heavy rain.
	return 1.0 - (0.12 if on_path else 0.04) * clampf(rain, 0.0, 1.0)

const SPRINT_MULT := 1.45
const SPRINT_DRAIN := 3.0   # energy per second

static func sprint_mult(wants: bool, moving: bool, energy: float) -> float:
	## Sprint only while moving with at least 1 energy left.
	return SPRINT_MULT if (wants and moving and energy >= 1.0) else 1.0

static func sprint_cost(dt: float) -> float:
	return SPRINT_DRAIN * dt

## Grip while riding a faster mount: the faster, the more it slides and the wider it turns (1.0 = on foot).
static func ride_grip(speed_mult: float) -> float:
	return clampf(1.0 - (speed_mult - 1.0) * 0.6, 0.45, 1.0)

const SPRINT_RAMP_UP := 2.6    # multiplier units/s: ~0.17 s from walk to full sprint
const SPRINT_RAMP_DOWN := 3.6  # eases back a little faster than it builds

static func sprint_ease(cur: float, target: float, dt: float) -> float:
	## Sprint builds up and winds down instead of snapping (inertia of effort).
	var rate := SPRINT_RAMP_UP if target > cur else SPRINT_RAMP_DOWN
	return move_toward(cur, target, rate * dt)

const SKID_MIN_SPEED := 55.0

static func is_skid(v: Vector2, input: Vector2) -> bool:
	## A hard reversal (input roughly opposite to a fast current velocity) kicks up dust.
	if v.length() < SKID_MIN_SPEED or input.length() < 0.5:
		return false
	return v.normalized().dot(input.normalized()) < -0.35

static func skid_dust_amount(speed: float) -> int:
	## Particle count grows with the speed being shed (3..8).
	return clampi(2 + int(speed / 30.0), 3, 8)

## Speed factor while a tool swing is playing: you plant your feet (0.35x) and ease back to full speed over the last 0.06 s.
static func swing_slow(tool_left: float, floor_mult: float = 0.35) -> float:
	if tool_left <= 0.0:
		return 1.0
	return lerpf(1.0, floor_mult, clampf(tool_left / 0.06, 0.0, 1.0))

## How hard a tool plants your feet: heavy tools (axe, pickaxe, club) stop you, medium (hoe, scythe) slow you, light ones barely do.
static func tool_plant(tool: String) -> float:
	match tool:
		"axe", "pickaxe", "club":
			return 0.35
		"hoe", "scythe":
			return 0.55
		"watering_can", "rod", "hand", "":
			return 0.85
	if tool.begins_with("axe") or tool.begins_with("pickaxe"):
		return 0.35
	return 0.7

const SNEAK_MULT := 0.55

static func sneak_mult(wants: bool, moving_or_not: bool = true) -> float:
	## Holding Ctrl crouches: slower, but wild animals notice you from half as far (HuntModel.scare_scale).
	return SNEAK_MULT if wants and moving_or_not else 1.0

const BOOTS_MULT := 1.08

static func boots_mult(boots_in_bag: int) -> float:
	## Carrying leather boots (crafted from hide) is a flat +8% walking speed.
	return BOOTS_MULT if boots_in_bag > 0 else 1.0
