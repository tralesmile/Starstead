class_name FloatMath
extends RefCounted
## Pure curves for floating pickup text and the level-up star burst.

const LIFE := 1.1

static func rise(t: float) -> float:
	## Pixels risen after t seconds: quick ease-out (fast start, settles), whole pixels.
	var k := clampf(t / LIFE, 0.0, 1.0)
	return roundf(26.0 * (1.0 - (1.0 - k) * (1.0 - k)))

static func alpha(t: float) -> float:
	## Fully opaque for the first 60%, then fades out.
	var k := clampf(t / LIFE, 0.0, 1.0)
	return 1.0 if k < 0.6 else clampf(1.0 - (k - 0.6) / 0.4, 0.0, 1.0)

static func stack_offset(slot: int) -> float:
	## Several pickups at once stack upward so they do not overlap.
	return -10.0 * float(slot)
