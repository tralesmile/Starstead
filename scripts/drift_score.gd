class_name DriftScore
extends RefCounted
## Circuit drift scoring: sliding sideways fast builds points (multiplier grows with drift time); a clean exit banks them, a crash loses them.

const MIN_SLIP := 60.0
const MIN_SPEED := 100.0
const MIN_BANK_TIME := 0.8

var score := 0.0
var t := 0.0

func drifting(slip: float, speed: float) -> bool:
	return absf(slip) > MIN_SLIP and speed > MIN_SPEED

static func multiplier(drift_t: float) -> float:
	return 1.0 + minf(drift_t, 4.0) * 0.5

func step(slip: float, speed: float, delta: float) -> int:
	## Advance one frame. Returns points banked this frame (0 unless a long enough drift just ended).
	if drifting(slip, speed):
		t += delta
		score += absf(slip) * 0.1 * (speed / 100.0) * multiplier(t) * delta
		return 0
	var banked := int(score) if t >= MIN_BANK_TIME else 0
	score = 0.0
	t = 0.0
	return banked

func crash() -> void:
	score = 0.0
	t = 0.0

static func pit_cap(in_pit: bool) -> float:
	## Pit lane / infield speed limit as a fraction of top speed.
	return 0.35 if in_pit else 1.0
