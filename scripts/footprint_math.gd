class_name FootprintMath
extends RefCounted
## Footprints on dirt: alternate left/right of the walking line, spaced by distance, fading with age.

const SPACING := 9.0
const LIFE := 12.0   # real seconds until gone
const SIDE := 2.5

static func due(dist_since_last: float) -> bool:
	return dist_since_last >= SPACING

static func print_pos(pos: Vector2, dir: Vector2, step_index: int) -> Vector2:
	var d := dir.normalized() if dir.length() > 0.01 else Vector2.DOWN
	var side := Vector2(-d.y, d.x) * (SIDE if step_index % 2 == 0 else -SIDE)
	return (pos + side).round()

static func alpha(age: float) -> float:
	return clampf(1.0 - age / LIFE, 0.0, 1.0) * 0.45
