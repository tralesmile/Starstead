class_name LighthouseMath
extends RefCounted
## Pure rules for the Halden lighthouse beam: a slow sweep, seen after dusk, thicker and paler in rain or fog.

const PERIOD := 9.0        # seconds per full turn
const LENGTH := 300.0
const HALF_WIDTH := 0.11   # radians

static func angle(t: float) -> float:
	return fposmod(t / PERIOD, 1.0) * TAU

static func strength(lamp: float, haze: float) -> float:
	## 0 by day; a beam shows more in wet air (it needs something to light up).
	return clampf(lamp, 0.0, 1.0) * lerpf(0.22, 0.38, clampf(haze, 0.0, 1.0))

static func beam(a: float, length: float = LENGTH, half: float = HALF_WIDTH) -> PackedVector2Array:
	## A triangle from the lamp room, squashed vertically for the 3/4 view.
	var squash := Vector2(1.0, 0.6)
	return PackedVector2Array([Vector2.ZERO, Vector2.from_angle(a - half) * length * squash, Vector2.from_angle(a + half) * length * squash])
