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
