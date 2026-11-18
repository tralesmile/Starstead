class_name WantedMath
extends RefCounted
## Pure wanted-level ("heat") model: crimes add heat, heat decays out of sight faster than in sight.
## Stars 0..5 derive from heat; police presence and fine scale with stars. Idea: bugnet/GTA 2 wanted meter.

const MAX_HEAT := 100.0
const STAR_STEP := 20.0        # heat per star
const DECAY_HIDDEN := 4.0      # heat/s when no cop sees you
const DECAY_SEEN := 0.5

static func crime_heat(kind: String) -> float:
	return {"trespass": 12.0, "theft": 25.0, "assault": 35.0, "car_theft": 30.0, "robbery": 45.0, "hit_and_run": 40.0, "smuggling": 20.0}.get(kind, 10.0)

static func add(heat: float, kind: String, witnessed: bool) -> float:
	## Unwitnessed crimes only add a quarter of the heat (noise/NPC memory handled elsewhere).
	var h := crime_heat(kind) * (1.0 if witnessed else 0.25)
	return clampf(heat + h, 0.0, MAX_HEAT)

static func stars(heat: float) -> int:
	return clampi(ceili(heat / STAR_STEP), 0, 5)

static func decay(heat: float, dt: float, seen: bool) -> float:
	return maxf(heat - (DECAY_SEEN if seen else DECAY_HIDDEN) * dt, 0.0)

static func police_count(star_n: int) -> int:
	return [0, 1, 2, 4, 6, 8][clampi(star_n, 0, 5)]

static func fine(star_n: int) -> int:
	## Paid on arrest; also drops honest reputation (caller).
	return 50 * star_n * star_n
