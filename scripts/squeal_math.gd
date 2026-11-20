class_name SquealMath
extends RefCounted
## Pure rules for tyre squeal: loudness and pitch from sideways slip, speed and the surface (asphalt squeals,
## paths hiss, grass is nearly silent, rain muffles) plus a procedural looping noise buffer (no audio assets).

const RATE := 22050
const SILENT_DB := -60.0

static func level(slip: float, speed: float, tile: int, sdf: float, rain: float = 0.0) -> float:
	## 0..1 loudness.
	if sdf < 0.9 or speed < 40.0:
		return 0.0
	var s := clampf((absf(slip) - 45.0) / 140.0, 0.0, 1.0)
	var surf := 1.0 if tile == WorldGen.ASPHALT else (0.5 if WorldGen.is_road(tile) else 0.12)
	return s * surf * (1.0 - 0.35 * clampf(rain, 0.0, 1.0))

static func volume_db(lv: float) -> float:
	if lv <= 0.01:
		return SILENT_DB
	return lerpf(-28.0, -6.0, clampf(lv, 0.0, 1.0))

static func pitch(speed: float) -> float:
	return clampf(0.8 + speed / 500.0, 0.8, 1.5)

static func loop_samples(n: int = 4410, seed_v: int = 7) -> PackedByteArray:
	## 16-bit mono looping noise, band-limited by a one-pole low-pass plus a faint 1.9 kHz tone for a squeal edge.
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	var out := PackedByteArray()
	out.resize(n * 2)
	var lp := 0.0
	for i in n:
		lp += 0.35 * (rng.randf_range(-1.0, 1.0) - lp)
		var tone := sin(TAU * 1900.0 * float(i) / RATE) * 0.18
		var v := clampf((lp * 1.6 + tone) * 0.6, -1.0, 1.0)
		var iv := int(v * 32000.0)
		out[i * 2] = iv & 0xFF
		out[i * 2 + 1] = (iv >> 8) & 0xFF
	return out
