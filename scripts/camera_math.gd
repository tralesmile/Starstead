class_name CameraMath
extends RefCounted
## Pure camera helpers: look-ahead offset in the walking direction (whole pixels) and soft world limits.

const LOOK := 14.0        # px ahead at full speed
const SMOOTH := 5.0       # 1/s

static func look_target(vel: Vector2, max_speed: float, look: float = LOOK) -> Vector2:
	if max_speed <= 0.0:
		return Vector2.ZERO
	return (vel / max_speed).limit_length(1.0) * look

static func ease_offset(cur: Vector2, target: Vector2, delta: float) -> Vector2:
	return cur.lerp(target, 1.0 - exp(-SMOOTH * delta))

static func snap(v: Vector2) -> Vector2:
	return v.round()

static func clamp_to_world(center: Vector2, half_view: Vector2, world_px: Vector2) -> Vector2:
	## Keep the view inside [0, world_px]; if the view is larger than the world, centre it.
	var out := center
	for a in 2:
		if half_view[a] * 2.0 >= world_px[a]:
			out[a] = world_px[a] * 0.5
		else:
			out[a] = clampf(center[a], half_view[a], world_px[a] - half_view[a])
	return out
