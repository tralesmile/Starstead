class_name SfxSynth
extends RefCounted
## Pure procedural sound effects (no audio assets): 16-bit mono 22050 Hz one-shots and seamless ambience loops,
## deterministic per name + variant, plus the rules for footsteps and ambience levels. No autoload use.

const RATE := 22050
const SILENT_DB := -60.0

const NAMES: Array[String] = [
	"step_grass", "step_path", "step_wood", "step_snow", "step_wet", "chop", "tree_fall", "mine", "hoe",
	"water_pour", "splash", "pickup", "coin", "bow_draw", "bow_twang", "bow_perfect", "arrow_hit", "swing",
	"hit", "ui_open", "ui_close", "error", "ship_horn", "ball_kick", "ball_post", "whistle", "crowd_cheer",
	"door_open", "door_close", "reel_click", "line_snap"]
const LOOPS: Array[String] = ["amb_rain", "amb_wind", "amb_birds", "amb_crickets", "amb_waves"]

# ---------------------------------------------------------------- public

static func samples(name: String, variant: int = 0) -> PackedByteArray:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(name) + variant * 7919
	if name in LOOPS:
		return _pack(_loop(name, rng))
	if not (name in NAMES):
		return PackedByteArray()
	return _pack(_one_shot(name, rng, variant))

static func stream(name: String, variant: int = 0) -> AudioStreamWAV:
	## null for an unknown name.
	var data := samples(name, variant)
	if data.is_empty():
		return null
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = data
	if name in LOOPS:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = data.size() / 2
	return w

static func footstep_name(tile: int, season: int, indoors: bool, rain: float, on_wood: bool = false) -> String:
	if indoors or on_wood:
		return "step_wood"
	if WorldGen.is_water(tile):
		return "step_wet"
	if WorldGen.is_road(tile):
		return "step_path"
	if season % 4 == 3:
		return "step_snow"
	if rain > 0.3:
		return "step_wet"
	if tile >= WorldGen.DIRT and tile < WorldGen.DIRT + 3:
		return "step_path"
	return "step_grass"

static func ambience_levels(rain: float, hour: float, season: int, indoors: bool, near_water: float, underground: bool = false) -> Dictionary:
	## Target loudness 0..1 for every loop. hour is 0..24 (values past midnight wrap).
	var out := {}
	for k in LOOPS:
		out[k] = 0.0
	if underground:
		return out
	var r := clampf(rain, 0.0, 1.0)
	var h := fposmod(hour, 24.0)
	var s := posmod(season, 4)
	var winter := s == 3

	out["amb_rain"] = r * (0.35 if indoors else 1.0)

	var wind := 0.15 + clampf((r - 0.6) / 0.4, 0.0, 1.0) * 0.55 + (0.1 if r > 0.6 else 0.0) + (0.25 if winter else 0.0)
	out["amb_wind"] = clampf(wind, 0.0, 1.0) * (0.25 if indoors else 1.0)

	if r <= 0.05:
		var day := smoothstep(5.0, 7.0, h) * (1.0 - smoothstep(18.0, 20.0, h))
		var dawn := 1.0 - 0.3 * smoothstep(8.0, 11.0, h)   # the dawn chorus is the loudest
		out["amb_birds"] = day * dawn * (0.25 if winter else 1.0) * (0.2 if indoors else 1.0)

	var night := maxf(smoothstep(18.5, 20.5, h), 1.0 - smoothstep(4.0, 6.0, h))
	var warm: float = [0.6, 1.0, 0.4, 0.0][s]
	out["amb_crickets"] = night * warm * clampf(1.0 - r * 3.0, 0.0, 1.0) * (0.25 if indoors else 1.0)

	out["amb_waves"] = clampf(near_water, 0.0, 1.0) * (0.2 if indoors else 1.0)
	return out

static func volume_db(level: float) -> float:
	if level <= 0.01:
		return SILENT_DB
	return maxf(SILENT_DB, linear_to_db(minf(level, 1.0)))

# ---------------------------------------------------------------- building blocks

static func _buf(seconds: float) -> PackedFloat32Array:
	var b := PackedFloat32Array()
	b.resize(int(seconds * RATE))
	return b

static func _noise(b: PackedFloat32Array, rng: RandomNumberGenerator, at: float, dur: float, amp: float,
		lo: float, hi: float, attack: float = 0.002, curve: float = 3.0) -> void:
	## Band-limited noise burst: one-pole low-pass at coefficient lo (0..1), minus a slower one at hi (0 = no high-pass).
	## Envelope: linear attack, then (1 - t)^curve decay.
	var start := int(at * RATE)
	var n := mini(int(dur * RATE), b.size() - start)
	var na := maxi(1, int(attack * RATE))
	var a := 0.0
	var c := 0.0
	for i in n:
		a += lo * (rng.randf() * 2.0 - 1.0 - a)
		c += hi * (a - c)
		var env := float(i) / na if i < na else pow(1.0 - float(i - na) / maxi(1, n - na), curve)
		b[start + i] += (a - c) * amp * env

static func _tone(b: PackedFloat32Array, at: float, dur: float, f0: float, f1: float, amp: float,
		attack: float = 0.002, curve: float = 3.0, wrap: bool = false) -> void:
	## Sine gliding from f0 to f1 with the same envelope as _noise. wrap = write circularly (for loops).
	var size := b.size()
	var start := int(at * RATE)
	var n := int(dur * RATE)
	if not wrap:
		n = mini(n, size - start)
	var na := maxi(1, int(attack * RATE))
	var phase := 0.0
	for i in n:
		phase += TAU * lerpf(f0, f1, float(i) / n) / RATE
		var env := float(i) / na if i < na else pow(1.0 - float(i - na) / maxi(1, n - na), curve)
		var j := (start + i) % size
		b[j] += sin(phase) * amp * env

static func _finish(b: PackedFloat32Array, peak: float) -> PackedFloat32Array:
	## Removes DC, normalises to the target peak and fades both ends so one-shots never click.
	var n := b.size()
	var mean := 0.0
	for v in b:
		mean += v
	mean /= maxi(1, n)
	var top := 0.0001
	for i in n:
		b[i] -= mean
		top = maxf(top, absf(b[i]))
	var g := peak / top
	for i in n:
		b[i] *= g
	var fin := mini(n, int(0.002 * RATE))
	var fout := mini(n, int(0.008 * RATE))
	for i in fin:
		b[i] *= float(i) / fin
	for i in fout:
		b[n - 1 - i] *= float(i) / fout
	return b

static func _pack(b: PackedFloat32Array) -> PackedByteArray:
	var out := PackedByteArray()
	out.resize(b.size() * 2)
	for i in b.size():
		out.encode_s16(i * 2, int(clampf(b[i], -1.0, 1.0) * 32000.0))
	return out

# ---------------------------------------------------------------- one-shots

static func _one_shot(name: String, rng: RandomNumberGenerator, variant: int) -> PackedFloat32Array:
	var k := 1.0 + rng.randf_range(-0.08, 0.08) + 0.04 * (variant % 3 - 1)  # per-variant pitch colour
	var b: PackedFloat32Array
	var peak := 0.7
	match name:
		"step_grass":
			b = _buf(0.13)
			_noise(b, rng, 0.0, 0.12, 1.0, 0.35 * k, 0.08, 0.015, 2.5)
			peak = 0.4
		"step_path":
			b = _buf(0.10)
			_noise(b, rng, 0.0, 0.06, 1.0, 0.55 * k, 0.15, 0.002, 3.0)
			_noise(b, rng, 0.03, 0.06, 0.5, 0.7, 0.3, 0.002, 3.0)
			_tone(b, 0.0, 0.05, 140.0 * k, 80.0, 0.2)
			peak = 0.4
		"step_wood":
			b = _buf(0.12)
			_tone(b, 0.0, 0.11, 190.0 * k, 160.0 * k, 0.8, 0.002, 4.0)
			_tone(b, 0.0, 0.05, 430.0 * k, 400.0 * k, 0.3)
			_noise(b, rng, 0.0, 0.025, 0.5, 0.4, 0.05)
			peak = 0.45
		"step_snow":
			b = _buf(0.18)
			for i in 6:  # crunch: a cluster of tiny grains
				_noise(b, rng, i * 0.022 + rng.randf() * 0.008, 0.045, rng.randf_range(0.5, 1.0), 0.45 * k, 0.1, 0.006, 2.0)
			peak = 0.4
		"step_wet":
			b = _buf(0.17)
			_noise(b, rng, 0.0, 0.14, 1.0, 0.25 * k, 0.04, 0.012, 2.0)
			_noise(b, rng, 0.02, 0.10, 0.4, 0.8, 0.4, 0.005, 3.0)
			_tone(b, 0.03, 0.06, 320.0 * k, 620.0 * k, 0.18, 0.01, 2.0)
			peak = 0.42
		"chop":
			b = _buf(0.22)
			_noise(b, rng, 0.0, 0.05, 1.0, 0.6 * k, 0.05, 0.001, 3.0)
			_tone(b, 0.0, 0.20, 175.0 * k, 120.0 * k, 0.8, 0.001, 4.0)
			_tone(b, 0.0, 0.09, 520.0 * k, 470.0 * k, 0.3, 0.001, 3.0)
			peak = 0.75
		"tree_fall":
			b = _buf(1.4)
			for i in 9:  # cracking fibres, speeding up
				var t := 0.55 * (1.0 - pow(1.0 - i / 9.0, 1.6))
				_noise(b, rng, t, 0.035, 0.3 + 0.04 * i, 0.7, 0.2, 0.001, 3.0)
			_noise(b, rng, 0.2, 0.65, 0.35, 0.2, 0.03, 0.5, 1.5)  # leaves rushing
			_noise(b, rng, 0.82, 0.55, 1.0, 0.07, 0.003, 0.004, 3.0)  # crash
			_noise(b, rng, 0.82, 0.4, 0.4, 0.5, 0.1, 0.004, 3.0)
			_tone(b, 0.82, 0.45, 85.0, 40.0, 0.8, 0.004, 3.0)
			peak = 0.8
		"mine":
			b = _buf(0.28)
			_noise(b, rng, 0.0, 0.04, 0.9, 0.85, 0.3, 0.001, 3.0)
			_tone(b, 0.0, 0.26, 1850.0 * k, 1840.0 * k, 0.4, 0.001, 4.0)
			_tone(b, 0.0, 0.16, 2930.0 * k, 2920.0 * k, 0.22, 0.001, 4.0)
			_tone(b, 0.0, 0.08, 210.0 * k, 130.0, 0.5)
			_noise(b, rng, 0.07, 0.12, 0.25, 0.5, 0.2, 0.002, 2.0)  # rubble
		"door_open":
			b = _buf(0.34)
			_noise(b, rng, 0.0, 0.015, 0.8, 0.45, 0.1, 0.001, 3.0)    # latch
			_tone(b, 0.03, 0.28, 210.0 * k, 330.0 * k, 0.25, 0.05, 1.5)  # hinge creak
			_tone(b, 0.05, 0.22, 423.0 * k, 668.0 * k, 0.1, 0.05, 1.5)
			peak = 0.35
		"door_close":
			b = _buf(0.24)
			_tone(b, 0.0, 0.2, 130.0 * k, 70.0, 0.9, 0.002, 3.0)       # leaf meets frame
			_noise(b, rng, 0.0, 0.05, 0.6, 0.3, 0.05, 0.001, 3.0)
			_noise(b, rng, 0.07, 0.015, 0.5, 0.5, 0.12, 0.001, 3.0)    # latch drops
			peak = 0.45
		"reel_click":
			b = _buf(0.04)
			_noise(b, rng, 0.0, 0.012, 0.8, 0.6, 0.2, 0.001, 2.0)
			_tone(b, 0.0, 0.03, 1500.0 * k, 1200.0 * k, 0.35, 0.001, 3.0)
			peak = 0.28
		"line_snap":
			b = _buf(0.3)
			_tone(b, 0.0, 0.26, 900.0 * k, 180.0, 0.6, 0.001, 3.0)
			_noise(b, rng, 0.0, 0.03, 0.9, 0.6, 0.2, 0.001, 3.0)
			peak = 0.5
		"hoe":
			b = _buf(0.24)
			_tone(b, 0.0, 0.12, 120.0 * k, 65.0, 0.8, 0.002, 3.0)
			_noise(b, rng, 0.0, 0.08, 0.8, 0.3, 0.03)
			_noise(b, rng, 0.05, 0.18, 0.45, 0.5, 0.12, 0.03, 2.0)  # scraped soil
			peak = 0.65
		"water_pour":
			b = _buf(0.8)
			_noise(b, rng, 0.0, 0.78, 0.55, 0.5, 0.12, 0.12, 1.2)
			for i in 26:
				var f := rng.randf_range(500.0, 1400.0)
				_tone(b, 0.04 + i * 0.026 + rng.randf() * 0.015, 0.035, f, f * 1.5, rng.randf_range(0.08, 0.22), 0.008, 2.0)
			peak = 0.5
		"splash":
			b = _buf(0.6)
			_noise(b, rng, 0.0, 0.45, 1.0, 0.4, 0.04, 0.006, 3.0)
			_noise(b, rng, 0.03, 0.35, 0.4, 0.85, 0.35, 0.02, 2.0)
			_tone(b, 0.0, 0.14, 260.0, 90.0, 0.5, 0.003, 2.0)
			for i in 7:
				var f := rng.randf_range(700.0, 1600.0)
				_tone(b, 0.18 + rng.randf() * 0.34, 0.04, f, f * 1.4, 0.12, 0.006, 2.0)
		"ball_kick":
			b = _buf(0.14)
			_tone(b, 0.0, 0.12, 190.0 * k, 70.0, 0.9, 0.001, 3.0)
			_noise(b, rng, 0.0, 0.035, 0.7, 0.5 * k, 0.08, 0.001, 3.0)
			peak = 0.65
		"ball_post":
			b = _buf(0.45)
			_tone(b, 0.0, 0.43, 610.0 * k, 600.0 * k, 0.6, 0.001, 4.0)
			_tone(b, 0.0, 0.25, 1470.0 * k, 1455.0 * k, 0.3, 0.001, 4.0)
			_noise(b, rng, 0.0, 0.02, 0.6, 0.7, 0.2, 0.001, 3.0)
			peak = 0.6
		"whistle":
			b = _buf(0.55)
			for i in 12:   # the pea rattling: short alternating pips
				var f := 2350.0 if i % 2 == 0 else 2520.0
				_tone(b, i * 0.042, 0.05, f * k, f * k, 0.6, 0.006, 0.6)
			peak = 0.4
		"crowd_cheer":
			b = _buf(1.6)
			_noise(b, rng, 0.0, 1.55, 1.0, 0.22, 0.03, 0.25, 1.4)
			_noise(b, rng, 0.1, 1.3, 0.5, 0.4, 0.1, 0.4, 1.6)
			for i in 14:
				var f := rng.randf_range(330.0, 760.0)
				_tone(b, rng.randf_range(0.05, 0.9), rng.randf_range(0.2, 0.5), f, f * rng.randf_range(1.05, 1.3), 0.06, 0.08, 1.5)
			peak = 0.6
		"pickup":
			b = _buf(0.12)
			_tone(b, 0.0, 0.11, 520.0 * k, 1040.0 * k, 0.8, 0.006, 2.0)
			peak = 0.45
		"coin":
			b = _buf(0.38)
			_tone(b, 0.0, 0.09, 988.0, 988.0, 0.6, 0.002, 1.5)
			_tone(b, 0.07, 0.30, 1319.0, 1319.0, 0.7, 0.002, 3.0)
			_tone(b, 0.07, 0.20, 2637.0, 2637.0, 0.2, 0.002, 3.0)
			peak = 0.5
		"bow_draw":
			b = _buf(0.5)
			var t := 0.01
			while t < 0.44:  # creaking limbs: ticks that get closer together
				_noise(b, rng, t, 0.018, 0.3 + t, 0.25, 0.04, 0.002, 2.0)
				_tone(b, t, 0.02, 230.0 + 300.0 * t, 250.0 + 300.0 * t, 0.2 + 0.3 * t, 0.003, 2.0)
				t += lerpf(0.055, 0.022, t / 0.44)
			peak = 0.35
		"bow_twang":
			b = _buf(0.36)
			_tone(b, 0.0, 0.34, 215.0 * k, 196.0 * k, 0.8, 0.001, 3.0)
			_tone(b, 0.0, 0.22, 431.0 * k, 392.0 * k, 0.4, 0.001, 3.0)
			_tone(b, 0.0, 0.12, 647.0 * k, 590.0 * k, 0.25, 0.001, 3.0)
			_noise(b, rng, 0.0, 0.12, 0.4, 0.5, 0.15, 0.001, 3.0)
			peak = 0.65
		"bow_perfect":
			b = _buf(0.55)
			var notes := [880.0, 1108.7, 1318.5, 1760.0]
			for i in notes.size():
				_tone(b, i * 0.055, 0.35, notes[i], notes[i], 0.4, 0.004, 3.0)
			peak = 0.5
		"arrow_hit":
			b = _buf(0.2)
			_noise(b, rng, 0.0, 0.03, 1.0, 0.5, 0.1, 0.001, 2.0)
			_tone(b, 0.0, 0.12, 160.0 * k, 90.0, 0.8, 0.001, 3.0)
			_tone(b, 0.015, 0.17, 340.0 * k, 310.0 * k, 0.2, 0.004, 3.0)  # shaft quiver
		"swing":
			b = _buf(0.22)
			_noise(b, rng, 0.0, 0.21, 0.6, 0.12, 0.03, 0.09, 1.5)
			_noise(b, rng, 0.04, 0.15, 0.4, 0.35, 0.1, 0.07, 1.5)
			peak = 0.4
		"hit":
			b = _buf(0.18)
			_tone(b, 0.0, 0.16, 150.0 * k, 55.0, 0.9, 0.001, 2.5)
			_noise(b, rng, 0.0, 0.07, 0.8, 0.35, 0.02, 0.001, 3.0)
			peak = 0.75
		"ui_open":
			b = _buf(0.13)
			_tone(b, 0.0, 0.06, 523.0, 523.0, 0.7, 0.004, 1.5)
			_tone(b, 0.05, 0.075, 784.0, 784.0, 0.7, 0.004, 2.0)
			peak = 0.3
		"ui_close":
			b = _buf(0.13)
			_tone(b, 0.0, 0.06, 784.0, 784.0, 0.7, 0.004, 1.5)
			_tone(b, 0.05, 0.075, 523.0, 523.0, 0.7, 0.004, 2.0)
			peak = 0.3
		"error":
			b = _buf(0.26)
			for at in [0.0, 0.12]:
				_tone(b, at, 0.10, 165.0, 160.0, 0.7, 0.006, 0.7)
				_tone(b, at, 0.10, 495.0, 480.0, 0.2, 0.006, 0.7)
			peak = 0.4
		"ship_horn":
			b = _buf(1.8)
			for f in [110.0, 138.6, 220.0, 331.0, 441.0]:
				var amp: float = 55.0 / f + 0.08
				_tone(b, 0.0, 1.78, f, f * 0.995, amp, 0.15, 0.45)
			peak = 0.7
	return _finish(b, peak)

# ---------------------------------------------------------------- loops

static func _crossfade(raw: PackedFloat32Array, n: int) -> PackedFloat32Array:
	## Equal-power blend of the tail (samples past n) into the head, so sample n-1 flows straight into sample 0.
	var f := raw.size() - n
	var out := raw.slice(0, n)
	for i in f:
		var a := float(i) / f * PI * 0.5
		out[i] = raw[i] * sin(a) + raw[n + i] * cos(a)
	return out

static func _bed(rng: RandomNumberGenerator, seconds: float, lo: float, hi: float) -> PackedFloat32Array:
	## Seamless band-limited noise of the given length.
	var n := int(seconds * RATE)
	var raw := _buf(seconds + 0.4)
	var a := 0.0
	var c := 0.0
	for i in range(-500, raw.size()):  # negative indices warm the filters up
		a += lo * (rng.randf() * 2.0 - 1.0 - a)
		c += hi * (a - c)
		if i >= 0:
			raw[i] = a - c
	return _crossfade(raw, n)

static func _scale(b: PackedFloat32Array, peak: float) -> PackedFloat32Array:
	var top := 0.0001
	for v in b:
		top = maxf(top, absf(v))
	var g := peak / top
	for i in b.size():
		b[i] *= g
	return b

static func _loop(name: String, rng: RandomNumberGenerator) -> PackedFloat32Array:
	## Modulations use whole cycles per loop and chirps are written circularly, so nothing breaks at the seam.
	var b: PackedFloat32Array
	match name:
		"amb_rain":
			b = _bed(rng, 3.0, 0.5, 0.06)
			for i in 90:  # separate drops
				var f := rng.randf_range(900.0, 2600.0)
				_tone(b, rng.randf() * 3.0, 0.012, f, f * 0.8, rng.randf_range(0.05, 0.2), 0.001, 2.0, true)
			return _scale(b, 0.5)
		"amb_wind":
			b = _bed(rng, 4.0, 0.05, 0.006)
			var n := b.size()
			for i in n:
				var p := TAU * float(i) / n
				b[i] *= 0.65 + 0.25 * sin(p) + 0.1 * sin(3.0 * p + 1.3)
			return _scale(b, 0.5)
		"amb_waves":
			b = _bed(rng, 5.0, 0.14, 0.01)
			var n := b.size()
			for i in n:
				var w := 0.5 - 0.5 * cos(TAU * 2.0 * float(i) / n)  # two swells per loop
				b[i] *= 0.15 + 0.85 * w * w
			return _scale(b, 0.5)
		"amb_birds":
			b = _buf(6.0)
			for call_i in 6:  # sparse phrases from different "birds"
				var t := call_i + rng.randf() * 0.6
				var base := rng.randf_range(2200.0, 4200.0)
				var amp := rng.randf_range(0.4, 1.0)
				var rise := rng.randf_range(0.75, 1.35)
				for note in rng.randi_range(2, 5):
					var f := base * rng.randf_range(0.9, 1.1)
					var d := rng.randf_range(0.04, 0.09)
					_tone(b, t, d, f, f * rise, amp, 0.012, 1.5, true)
					t += d + rng.randf_range(0.02, 0.07)
			return _scale(b, 0.35)
		"amb_crickets":
			b = _buf(4.0)
			for chirp in 7:  # one near cricket in triplets
				var t := chirp * 4.0 / 7.0 + rng.randf() * 0.05
				for pulse in 3:
					_tone(b, t + pulse * 0.045, 0.028, 4300.0, 4300.0, 1.0, 0.008, 1.0, true)
			for chirp in 5:  # a quieter, farther one
				var t := 0.3 + chirp * 0.8 + rng.randf() * 0.08
				for pulse in 4:
					_tone(b, t + pulse * 0.035, 0.022, 3750.0, 3750.0, 0.4, 0.006, 1.0, true)
			return _scale(b, 0.3)
	return _buf(0.0)
