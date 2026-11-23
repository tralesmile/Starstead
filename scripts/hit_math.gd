class_name HitMath
extends RefCounted
## Pure knockback + hit-stop math (combat, tool hits, vehicle bumps reuse it).

const KNOCK_SPEED := 220.0   # initial push speed at full force
const KNOCK_DECAY := 900.0   # px/s^2 braking of the push
const HITSTOP_BASE := 0.04   # seconds of freeze on a light hit
const HITSTOP_MAX := 0.12

static func knockback(from: Vector2, to: Vector2, force: float = 1.0) -> Vector2:
	## Velocity pushing `to` away from `from`; zero distance pushes straight down (never NaN).
	var d := to - from
	if d.length() < 0.001:
		d = Vector2.DOWN
	return d.normalized() * KNOCK_SPEED * maxf(force, 0.0)

static func decay(v: Vector2, delta: float) -> Vector2:
	return v.move_toward(Vector2.ZERO, KNOCK_DECAY * delta)

static func hitstop(force: float) -> float:
	## Heavier hits freeze longer (tree chop feels weightier than a hoe tap), capped.
	return clampf(HITSTOP_BASE * (0.5 + force), 0.0, HITSTOP_MAX)

static func shake_offset(t_left: float, total: float, amp: float, phase: float) -> Vector2:
	## Whole-pixel camera shake that fades out; zero when finished.
	if t_left <= 0.0 or total <= 0.0:
		return Vector2.ZERO
	var k := t_left / total
	return Vector2(roundf(sin(phase * 91.0) * amp * k), roundf(cos(phase * 57.0) * amp * k))

static func squash(t_left: float, total: float, strength: float = 0.25) -> Vector2:
	## Sprite scale for squash/stretch on a hit: starts squashed (wide, short), springs
	## back with one small overshoot, ends at exactly (1,1).
	if t_left <= 0.0 or total <= 0.0:
		return Vector2.ONE
	var k := 1.0 - t_left / total
	var a := strength * (1.0 - k) * cos(k * PI * 1.5)
	return Vector2(1.0 + a, 1.0 - a)

static func swing_angle(t_left: float, total: float) -> float:
	## Held-tool sweep in radians: from raised (-1.0) through the strike (+0.9) as the swing ends; 0 when idle.
	if t_left <= 0.0 or total <= 0.0:
		return 0.0
	var k := 1.0 - t_left / total
	return lerpf(-1.0, 0.9, k * k)

static func hoe_angle(t_left: float, total: float) -> float:
	## Hoe dig: lift high (-1.5), a fast chop into the soil (+1.1), then a short drag-back that breaks the clod (+0.55).
	if t_left <= 0.0 or total <= 0.0:
		return 0.0
	var k := 1.0 - t_left / total
	if k < 0.3:
		return lerpf(-1.0, -1.5, k / 0.3)
	if k < 0.55:
		var u := (k - 0.3) / 0.25
		return lerpf(-1.5, 1.1, u * u)
	return lerpf(1.1, 0.55, (k - 0.55) / 0.45)

static func clod_velocity(i: int, n: int, facing_dir: Vector2) -> Vector2:
	## Initial velocity of clod i of n flicked away from the player in a fan around the facing direction.
	var base := facing_dir.normalized() if facing_dir.length() > 0.01 else Vector2.DOWN
	var t := 0.5 if n <= 1 else float(i) / float(n - 1)
	var ang := lerpf(-0.7, 0.7, t)
	return base.rotated(ang) * (40.0 + 14.0 * float(i % 3))
