class_name LeapMath
extends RefCounted
## Pure arc for a caught fish leaping from the bobber into the player's arms (Stardew-style catch juice).

const MIN_T := 0.45
const MAX_T := 0.9
const HEIGHT := 46.0      # px above the straight line at the top of the arc

static func duration(from: Vector2, to: Vector2) -> float:
	return clampf(0.35 + from.distance_to(to) / 500.0, MIN_T, MAX_T)

static func pos(from: Vector2, to: Vector2, t: float, height: float = HEIGHT) -> Vector2:
	## Straight line from -> to plus a parabolic lift (0 at both ends, `height` at t = 0.5).
	var k := clampf(t, 0.0, 1.0)
	return from.lerp(to, k) + Vector2(0, -4.0 * height * k * (1.0 - k))

static func spin(t: float, dir: float) -> float:
	## The fish flips 1.5 turns on the way, tail first; dir = sign of the horizontal travel.
	return clampf(t, 0.0, 1.0) * TAU * 1.5 * (1.0 if dir >= 0.0 else -1.0)

static func landing_squash(t_after: float) -> Vector2:
	## A quick flop when it lands: wide and flat, settling back in 0.2 s.
	var k := clampf(t_after / 0.2, 0.0, 1.0)
	var s := (1.0 - k) * 0.35
	return Vector2(1.0 + s, 1.0 - s)
