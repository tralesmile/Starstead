class_name ShadowMath
extends RefCounted
## Sun-driven drop shadows: long and leaning west at dawn, short at noon, long and leaning east at dusk.

const DAY_MIN := 780.0  # minutes since 06:00 when the sun sets (19:00)

static func sun_angle(minutes: float) -> float:
	## 0 at sunrise (east) -> PI/2 noon -> PI at sunset (west); clamped outside daylight.
	return clampf(minutes / DAY_MIN, 0.0, 1.0) * PI

static func length_factor(minutes: float) -> float:
	## 1 at noon, grows toward the horizon, capped at 3.
	return clampf(1.0 / maxf(sin(sun_angle(minutes)), 0.01), 1.0, 3.0)

static func offset_x(minutes: float, scale_px: float = 4.0) -> float:
	## Whole-pixel sideways shift: negative (west) in the morning, positive (east) in the evening.
	return roundf(-cos(sun_angle(minutes)) * minf(length_factor(minutes), 2.4) * scale_px)

static func stretch(minutes: float) -> float:
	## Horizontal stretch of the oval: 1.0 at noon up to 1.7 at the horizon.
	return 1.0 + 0.7 * clampf((length_factor(minutes) - 1.0) / 2.0, 0.0, 1.0)

static func strength(minutes: float) -> float:
	## Shadow opacity multiplier: full in daylight, fades out at night (no sun, ambient only).
	return clampf(1.0 - (minutes - 700.0) / 140.0, 0.25, 1.0) if minutes > 700.0 else 1.0
