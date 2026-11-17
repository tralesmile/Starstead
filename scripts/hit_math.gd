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
