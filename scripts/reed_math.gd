class_name ReedMath
extends RefCounted
## Pure math for reeds/grass parting around a walker. Returns whole-pixel push of the plant top.

static func bend(plant: Vector2, walker: Vector2, radius: float = 22.0, max_px: float = 5.0) -> float:
	## Signed horizontal push (px): away from the walker, strongest when close; 0 outside radius.
	var d := plant - walker
	var l := d.length()
	if l >= radius:
		return 0.0
	var k := 1.0 - l / radius
	var dir := 1.0 if d.x >= 0.0 else -1.0
	return roundf(dir * max_px * k)

static func ease_to(cur: float, target: float, dt: float, rate: float = 10.0) -> float:
	## Springy return: exponential approach, snaps to target when close.
	var n: float = lerpf(cur, target, clampf(rate * dt, 0.0, 1.0))
	return target if absf(n - target) < 0.05 else n
