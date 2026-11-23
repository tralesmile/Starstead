class_name CrowMath
extends RefCounted
## Dawn crow flock: a few crows lift off the fields in the first minutes of the day and flap away over the trees.

const COUNT := 5
const WINDOW := 24.0   # game minutes after 06:00 the flock is in the air

static func age(minutes: float) -> float:
	## 0..1 through the flight, -1 when no flock is up (after the window or at night).
	if minutes < 0.0 or minutes >= WINDOW:
		return -1.0
	return minutes / WINDOW

static func pos(i: int, a: float) -> Vector2:
	## Offset from the player: starts low on the ground nearby, climbs up-right, spreading out; each bird its own lane.
	var lane := float(i) - float(COUNT - 1) * 0.5
	var start := Vector2(-50.0 + lane * 14.0, 30.0 + fposmod(float(i) * 37.0, 20.0))
	var dir := Vector2(1.0, -0.55 - 0.08 * lane).normalized()
	var dist := a * 360.0 * (0.9 + 0.05 * float(i))
	return start + dir * dist + Vector2(0.0, sin(a * 18.0 + float(i)) * 4.0)

static func alpha(a: float) -> float:
	## Fully visible, fading over the last 20% of the flight.
	return clampf((1.0 - a) / 0.2, 0.0, 1.0)

static func frame(i: int, t: float) -> int:
	## Wing frame 0..3 (sheet of four 16px frames), each bird out of step.
	return int(fposmod(t * 9.0 + float(i) * 0.7, 4.0))

# ---- crows perched on ripe crops (daytime, uncovered by a scarecrow) ----
const PERCH_START := 60.0    # minutes after 06:00 (07:00)
const PERCH_END := 600.0     # 16:00
const PERCH_MAX := 3
const STARTLE_DIST := 72.0   # px: walk closer and they flap off
const FLEE_TIME := 2.2

static func perch_window(minutes: float) -> bool:
	return minutes >= PERCH_START and minutes < PERCH_END

static func _roll(cell: Vector2i, day: int) -> float:
	return fposmod(float(hash(Vector3i(cell.x, cell.y, day * 13 + 7))) * 0.0001, 1.0)

## Up to PERCH_MAX ripe cells today's crows sit on, deterministic per day.
static func perch_cells(ripe: Array, day: int) -> Array:
	var cells := ripe.duplicate()
	cells.sort_custom(func(a, b): return _roll(a, day) < _roll(b, day))
	return cells.slice(0, PERCH_MAX)

static func startled(player_px: Vector2, crow_px: Vector2) -> bool:
	return player_px.distance_to(crow_px) < STARTLE_DIST

## Offset of a startled crow t seconds after the scare: lifts, flaps away from the player (dir -1/1).
static func flee_offset(i: int, t: float, away: Vector2) -> Vector2:
	var d := away.normalized() if away.length() > 0.01 else Vector2.RIGHT
	var k := minf(t, FLEE_TIME)
	return d * (k * 110.0) + Vector2(0.0, -k * 70.0 - k * k * 10.0) + Vector2(0.0, sin(k * 20.0 + float(i)) * 2.0)

static func flee_alpha(t: float) -> float:
	return clampf((FLEE_TIME - t) / 0.6, 0.0, 1.0)

## Head dip 0..2 px while pecking the crop (a quick peck every ~1.3 s, each bird out of step).
static func peck(i: int, t: float) -> float:
	var p := fposmod(t * 0.77 + float(i) * 0.37, 1.0)
	return 2.0 * maxf(0.0, sin(p * 18.0)) if p < 0.17 else 0.0
