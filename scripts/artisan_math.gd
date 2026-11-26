class_name ArtisanMath
extends RefCounted
## Pure motion of the machine effects: the ready bubble's bob and the working steam puffs.

const PUFF_LIFE := 1.6

static func bubble_bob(t: float, phase: float) -> float:
	return sin(t * 3.2 + phase) * 2.0

static func puff_age(t: float, phase: float, i: int) -> float:
	## 0..1 life of puff i; the three puffs are spread evenly through one life.
	return fposmod(t / PUFF_LIFE + phase + i / 3.0, 1.0)

static func puff(t: float, phase: float, i: int) -> Vector3:
	## x, y offset (rises, drifts) and radius (grows) of puff i.
	var a := puff_age(t, phase, i)
	return Vector3(sin(a * TAU + i) * 3.0, -18.0 * a, 1.5 + 2.5 * a)

static func puff_alpha(t: float, phase: float, i: int) -> float:
	var a := puff_age(t, phase, i)
	return 0.55 * minf(a * 5.0, 1.0) * (1.0 - a)
