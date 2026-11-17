class_name WeatherMath
extends RefCounted
## Pure weather helpers. Deterministic per (seed, day): same day always gives the same sky.

static func rain_chance(season: int) -> float:
	## 0 spring,1 summer,2 autumn,3 winter (rain stays rain for now).
	return [0.30, 0.15, 0.35, 0.20][clampi(season, 0, 3)]

static func rain_for_day(world_seed: int, day: int, season: int) -> float:
	## 0 = clear, else rain intensity 0.3..1.0
	var h := hash(Vector2i(world_seed, day)) & 0xFFFF
	var r := float(h) / 65535.0
	if r >= rain_chance(season):
		return 0.0
	return 0.3 + 0.7 * (r / rain_chance(season))

static func rain_now(intensity: float, minutes: float) -> float:
	## Rain fades in/out over 40 game minutes at start/end of a window 09:00-18:00 (minutes since 06:00: 180..720).
	if intensity <= 0.0:
		return 0.0
	var a := clampf((minutes - 180.0) / 40.0, 0.0, 1.0)
	var b := clampf((720.0 - minutes) / 40.0, 0.0, 1.0)
	return intensity * minf(a, b)

static func darken(rain: float) -> Color:
	## Multiply onto the day tint: overcast greys the world.
	var k := 1.0 - 0.28 * rain
	return Color(k, k, 1.0 - 0.18 * rain)

static func drop_pos(i: int, t: float, speed: float = 260.0) -> Vector2:
	## Raindrop i position in a 360x280 box (origin top-left), wraps vertically; slanted.
	var x := fposmod(float(i) * 37.7 + t * 40.0 * 0.0, 360.0)
	var y := fposmod(float(i) * 61.3 + t * speed, 280.0)
	return Vector2(fposmod(x - y * 0.18, 360.0), y)

static func ripple(i: int, t: float, period: float = 1.1) -> Dictionary:
	## Rain ripple i: {pos (in the 360x280 box), age 0..1}. Respawns at a new spot every cycle.
	var u := t / period + float(i) * 0.37
	var cycle := floori(u)
	var h := hash(Vector2i(i, cycle))
	var x := float(h & 0xFFF) / 4095.0 * 360.0
	var y := float((h >> 12) & 0xFFF) / 4095.0 * 280.0
	return {"pos": Vector2(x, y), "age": u - float(cycle)}

static func ripple_radius(age: float, max_r: float = 7.0) -> float:
	return 1.0 + (max_r - 1.0) * clampf(age, 0.0, 1.0)

static func ripple_alpha(age: float) -> float:
	return 0.6 * (1.0 - clampf(age, 0.0, 1.0))

static func fog_for_day(world_seed: int, day: int, season: int, rain: float) -> float:
	## Morning fog 0..0.7 on some clear autumn/spring days; never on rainy days.
	if rain > 0.0:
		return 0.0
	var h := hash(Vector2i(world_seed + 77, day)) & 0xFFFF
	var r := float(h) / 65535.0
	var chance: float = [0.15, 0.05, 0.3, 0.2][clampi(season, 0, 3)]
	return 0.0 if r >= chance else 0.3 + 0.4 * (r / chance)

static func fog_now(strength: float, minutes: float) -> float:
	## Thickest at dawn (minutes since 06:00 = 0), burns off by 10:00 (240).
	return strength * clampf(1.0 - minutes / 240.0, 0.0, 1.0)

static func is_storm(rain: float) -> bool:
	return rain >= 0.8

static func lightning_flash(world_seed: int, day: int, t: float, rain_now_v: float) -> float:
	## 0..1 flash brightness at game-real time t (seconds). One bolt every ~14 s slot (double flicker),
	## only in a storm. Deterministic per (seed, day, slot).
	if not is_storm(rain_now_v):
		return 0.0
	var slot_len := 14.0
	var slot := floori(t / slot_len)
	var h := hash(Vector2i(world_seed + slot, day)) & 0xFFFF
	var start := (float(h) / 65535.0) * (slot_len - 2.0)
	var u := t - float(slot) * slot_len - start
	if u < 0.0 or u > 0.6:
		return 0.0
	# bright strike, short gap, softer re-strike, then decay
	if u < 0.08:
		return 1.0
	if u < 0.16:
		return 0.15
	if u < 0.26:
		return 0.7
	return 0.7 * clampf(1.0 - (u - 0.26) / 0.34, 0.0, 1.0)

static func thunder_delay(world_seed: int, day: int, t: float) -> float:
	## Seconds between flash and thunder (distance 0.5..3 s), for a future audio hook / screen rumble.
	var h := hash(Vector2i(world_seed + 9, day + floori(t / 14.0))) & 0xFF
	return 0.5 + 2.5 * float(h) / 255.0
