class_name AmbientMath
extends RefCounted
## Pure helpers for ambient particles: how dark it is, firefly paths, falling-leaf paths.

static func night_factor(minutes: float) -> float:
	## 0 in daylight, 1 deep night (ramps 18:00-21:00, fades 04:00-05:30 in game minutes since 06:00).
	if minutes < 720.0:
		return 0.0
	return clampf((minutes - 720.0) / 180.0, 0.0, 1.0)

static func firefly_pos(i: int, t: float, radius: float = 150.0) -> Vector2:
	## Slow wandering loop around the origin (player); distinct phase per firefly i.
	var a := float(i) * 2.399963  # golden angle spreads them evenly
	var r := radius * (0.35 + 0.65 * fposmod(float(i) * 0.618034, 1.0))
	var w := 0.25 + 0.05 * float(i % 5)
	return (Vector2(cos(a + t * w), sin(a * 1.3 + t * w * 0.8)) * r).limit_length(r) + Vector2(sin(t * 0.7 + a) * 6.0, cos(t * 0.9 + a) * 6.0)

static func firefly_glow(i: int, t: float) -> float:
	## 0..1 blink, each with its own rhythm.
	return clampf(0.5 + 0.7 * sin(t * (1.2 + 0.17 * float(i % 4)) + float(i) * 1.7), 0.0, 1.0)

static func leaf_pos(i: int, t: float, wind: float = 1.0) -> Vector2:
	## Leaf falling top to bottom of a 300px column with sideways sway; wraps.
	var fall := fposmod(t * (14.0 + float(i % 4) * 3.0) + float(i) * 47.0, 300.0)
	var x: float = fposmod(float(i) * 53.0, 300.0) - 150.0 + sin(t * 1.3 + float(i)) * 18.0 * wind + fall * 0.2 * wind
	return Vector2(x, fall - 170.0)

static func step_puffs(season: int, sprinting: bool) -> int:
	## Dust bits kicked up by a footstep: more when sprinting, and a snow spray in winter.
	var n := 3
	if sprinting:
		n += 2
	if season % 4 == 3:
		n += 3
	return n

const BREATH_PERIOD := 2.6
const BREATH_LIFE := 1.0

static func breath_cold(season: int, minutes: float) -> float:
	## How visible your breath is 0..1: winter always (strongest at night), autumn mornings and late evenings, spring dawn.
	var night := night_factor(minutes)
	match season % 4:
		3: return clampf(0.7 + 0.3 * night, 0.0, 1.0)
		2: return clampf(0.55 - minutes / 330.0, 0.0, 0.55) + 0.3 * night
		0: return clampf(0.35 - minutes / 250.0, 0.0, 0.35)
	return 0.0

static func breath_age(t: float) -> float:
	## 0..1 through the visible exhale of the current breath, -1 between breaths.
	var k := fposmod(t, BREATH_PERIOD)
	return k / BREATH_LIFE if k < BREATH_LIFE else -1.0

static func breath_puff(age: float, i: int) -> Vector3:
	## Puff i of 3 as (dx, dy rise, size px): drifts forward and up, grows, the later ones trail behind.
	var a := clampf(age - 0.12 * float(i), 0.0, 1.0)
	return Vector3(a * (6.0 + 3.0 * float(i)), -a * 7.0, 2.0 + a * (3.0 + float(i)))
