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

static func deadzone(cam: Vector2, target: Vector2, half_box: Vector2) -> Vector2:
	## Camera focus stays put while the target is inside a small box around it; it only moves
	## by the amount the target pushes past the box edge (Stardew/Terraria-style free zone).
	var d := target - cam
	var out := cam
	for a in 2:
		if d[a] > half_box[a]:
			out[a] = target[a] - half_box[a]
		elif d[a] < -half_box[a]:
			out[a] = target[a] + half_box[a]
	return out

const FAST_LOOK_MAX := 56.0   # px ahead at car top speed

static func look_for_speed(speed: float) -> float:
	## Look-ahead grows with speed beyond walking so you see the road coming in a car (14 px walking, up to 56 px at 300 px/s).
	if speed <= PlayerMath.SPEED:
		return LOOK * clampf(speed / PlayerMath.SPEED, 0.0, 1.0)
	return minf(LOOK + (speed - PlayerMath.SPEED) / 210.0 * (FAST_LOOK_MAX - LOOK), FAST_LOOK_MAX)

static func box_for_speed(speed: float) -> Vector2:
	## Dead-zone half box shrinks as you speed up so the camera never lags behind a fast vehicle (10x7 walking -> 2x1).
	var k := clampf((speed - PlayerMath.SPEED) / 150.0, 0.0, 1.0)
	return Vector2(lerpf(10.0, 2.0, k), lerpf(7.0, 1.0, k)).round()

static func look_vec(vel: Vector2) -> Vector2:
	return vel.normalized() * look_for_speed(vel.length()) if vel.length() > 0.01 else Vector2.ZERO

const RECENTER_DELAY := 0.35   # s standing still before the camera drifts back onto the player
const RECENTER_RATE := 3.5     # 1/s

static func recenter(focus: Vector2, target: Vector2, idle_t: float, delta: float) -> Vector2:
	## The dead-zone camera leaves you off-centre after a walk; once you stand still it eases back so the
	## character sits in the middle again (Stardew keeps you centred). Stops exactly on the target.
	if idle_t < RECENTER_DELAY or focus == target:
		return focus
	var k := 1.0 - exp(-RECENTER_RATE * delta)
	var out := focus.lerp(target, k)
	return target if out.distance_to(target) < 0.5 else out
