class_name AmbientMath
extends RefCounted
## Pure helpers for ambient particles: how dark it is, firefly paths, falling-leaf paths.

static func night_factor(minutes: float) -> float:
	## 0 in daylight, 1 deep night (ramps 18:00-21:00, fades 04:00-05:30 in game minutes since 06:00).
	if minutes < 720.0:
		return 0.0
	return clampf((minutes - 720.0) / 180.0, 0.0, 1.0)

## Fireflies hide from rain: they thin out in a drizzle and are gone by rain 0.4.
static func firefly_amount(night: float, rain: float) -> float:
	return night * clampf(1.0 - rain / 0.4, 0.0, 1.0)

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

## Colour of the dust a footstep kicks up by ground: green flecks on grass, tan on dirt and paths, grey on asphalt, white in winter snow.
static func step_dust_color(tile: int, season: int) -> Color:
	if season % 4 == 3 and tile <= 2:
		return Color(0.93, 0.96, 1.0, 0.75)
	if tile == 11:
		return Color(0.62, 0.62, 0.66, 0.45)
	if tile <= 2:
		return Color(0.5, 0.68, 0.3, 0.6)
	return Color(0.8, 0.7, 0.55, 0.55)

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

static func animal_breath_age(t: float, idx: int, size: float) -> float:
	## Animals breathe on their own rhythm: bigger animals slower, each critter out of phase. Same -1..1 meaning as breath_age.
	var rate := clampf(1.6 - size * 0.5, 0.9, 1.6)
	return breath_age(t * rate + float(idx) * 0.77)

static func animal_breath_size(size: float, age: float) -> float:
	## Puff pixel size for an animal of relative size (0.5 rabbit .. 1.6 horse) at breath age 0..1.
	return roundf((1.5 + age * 2.5) * clampf(size, 0.6, 1.5))

const GALE_LEAVES := 26

static func gale_leaf(i: int, t: float, wind_angle: float) -> Vector2:
	## A torn leaf racing downwind across a 360x240 box around the camera (centred offset), bobbing as it tumbles.
	var dir := Vector2.from_angle(wind_angle)
	var speed := 110.0 + float(i % 5) * 28.0
	var x := fposmod(float(i) * 97.0 + dir.x * speed * t, 360.0) - 180.0
	var y := fposmod(float(i) * 53.0 + (dir.y * speed * 0.5 + 16.0) * t, 240.0) - 140.0
	return Vector2(x, y + sin(t * (5.0 + float(i % 3)) + float(i)) * 4.0)
