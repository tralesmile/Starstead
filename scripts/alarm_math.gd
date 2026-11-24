class_name AlarmMath
extends RefCounted
## Pure alarm flash math: a red pulse over a room while the siren runs, fading out in the last second.

const DURATION := 6.0
const RATE := 7.0   # rad/s, about 1.1 flashes per second

static func pulse(t: float, duration: float = DURATION) -> float:
	## Overlay alpha 0..0.28 at time t since the alarm went off; 0 outside [0, duration].
	if t < 0.0 or t > duration:
		return 0.0
	var s := maxf(sin(t * RATE), 0.0)
	var fade := clampf((duration - t) / 1.0, 0.0, 1.0)
	return 0.28 * s * s * fade

static func ringing(t: float, duration: float = DURATION) -> bool:
	return t >= 0.0 and t <= duration

static func shake(t: float, duration: float = DURATION) -> float:
	## Small screen shake amplitude (px) on the first half second as the siren blares.
	if t < 0.0 or t > 0.5:
		return 0.0
	return 2.0 * (1.0 - t / 0.5)
