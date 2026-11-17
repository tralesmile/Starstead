class_name MountMath
extends RefCounted
## Mount stamina: galloping drains it, resting or walking recovers it. When it hits zero the mount is winded
## and only trots until it has caught its breath (hysteresis so it does not flicker).

const DRAIN := 0.12      # per second at full gallop (about 8 s of sprinting)
const REGEN := 0.18      # per second when slow or standing
const WINDED_UNTIL := 0.35   # stamina needed to gallop again after being winded
const GALLOP_SPEED := 110.0   # px/s above which the mount counts as galloping

static func step(stamina: float, speed: float, dt: float) -> float:
	if speed > GALLOP_SPEED:
		return maxf(stamina - DRAIN * dt, 0.0)
	return minf(stamina + REGEN * dt, 1.0)

static func winded(stamina: float, was_winded: bool) -> bool:
	if stamina <= 0.0:
		return true
	if was_winded and stamina < WINDED_UNTIL:
		return true
	return false

static func speed_scale(is_winded: bool, mult: float) -> float:
	## Winded mounts trot at 1.1x walking speed instead of their gallop multiplier.
	return minf(mult, 1.1) if is_winded else mult
