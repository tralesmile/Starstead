class_name PrintMath
extends RefCounted
## Pure rules for wet footprints on paved ground: only when it rains (or you just waded) and the ground is paved
## (city, circuit, quay, yard). Prints alternate left/right of the walking line and fade out.

const LIFE := 6.0       # s a print stays visible
const MAX := 56
const SIDE := 3.0       # px left/right of the track

static func wet(rain: float, paved: bool) -> bool:
	return paved and rain > 0.15

const SNOW_LIFE := 22.0   # s a boot track stays in fresh winter snow

static func snow(season: int, paved: bool) -> bool:
	## Winter ground outside the paved city is covered in snow: it keeps your tracks.
	return season % 4 == 3 and not paved

static func life_of(p: Dictionary) -> float:
	return float(p.get("life", LIFE))

static func snow_alpha(age: float) -> float:
	## Tracks stay crisp for a few seconds, then soften as the wind fills them in.
	var life := SNOW_LIFE
	if age >= life:
		return 0.0
	return 0.55 * (1.0 - smoothstep(0.35, 1.0, age / life))

static func paved_cell(c: Vector2i) -> bool:
	return CityModel.in_rect(c) or CircuitModel.in_rect(c) or HarbourModel.is_quay(c) or VanceYard.in_rect(c)

static func offset(step_idx: int, facing: int) -> Vector2:
	## Foot offset for the nth step. Facing: PlayerMath.Facing (DOWN, LEFT, RIGHT, UP order not assumed:
	## horizontal facings offset vertically, vertical facings offset horizontally).
	var s := SIDE if step_idx % 2 == 0 else -SIDE
	if facing == PlayerMath.Facing.LEFT or facing == PlayerMath.Facing.RIGHT:
		return Vector2(0, s)
	return Vector2(s, 0)

static func alpha(age: float) -> float:
	if age >= LIFE:
		return 0.0
	return 0.45 * (1.0 - age / LIFE)

static func prune(prints: Array, dt: float) -> Array:
	## Ages every print ({pos, age}) and drops dead ones; keeps at most MAX of the newest.
	var out: Array = []
	for p in prints:
		p["age"] = float(p["age"]) + dt
		if float(p["age"]) < life_of(p):
			out.append(p)
	while out.size() > MAX:
		out.pop_front()
	return out
