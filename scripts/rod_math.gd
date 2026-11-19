class_name RodMath
extends RefCounted
## Pure rod pose: the angle of the held fishing rod while charging, casting, waiting, biting and reeling.
## Angles are degrees above the horizontal, measured toward the side the player fishes on.

const LEN := 22.0
const WAIT_DEG := 52.0
const BACK_DEG := 150.0
const SWING_TIME := 0.2

static func charge_deg(power: float) -> float:
	return lerpf(75.0, BACK_DEG, clampf(power, 0.0, 1.0))

## Forward whip after release: from the back-swing to the waiting angle, with a little overshoot.
static func swing_deg(age: float) -> float:
	var k := clampf(age / SWING_TIME, 0.0, 1.0)
	var e := 1.0 - pow(1.0 - k, 3.0)
	return lerpf(BACK_DEG, WAIT_DEG, e) - sin(k * PI) * 18.0

static func hold_deg(t: float, biting: bool, reeling: bool) -> float:
	if biting:
		return WAIT_DEG - 14.0 + sin(t * 34.0) * 5.0
	if reeling:
		return WAIT_DEG + 10.0 + sin(t * 9.0) * 6.0
	return WAIT_DEG + sin(t * 1.6) * 2.0

## Rod tip in pixels for a grip point, side (+1 right, -1 left) and angle.
static func tip(grip: Vector2, side: float, deg: float, length: float = LEN) -> Vector2:
	var r := deg_to_rad(deg)
	return grip + Vector2(cos(r) * side, -sin(r)) * length

## Which way the player fishes: left when facing left or the target is to the left, else right.
static func side_for(facing_left: bool, dx: float) -> float:
	if facing_left:
		return -1.0
	if absf(dx) > 4.0:
		return signf(dx)
	return 1.0
