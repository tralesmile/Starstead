class_name MusicSynth
extends RefCounted
## Procedural background music, no audio assets: short composed loops (pad chords, bass, plucked melody, soft drums
## for the boss) per mood, deterministic per mood + variant. compose() gives notes, render() gives 16-bit PCM.
## Note tails wrap round to the start, so every loop joins without a seam. Pure and thread safe.

const RATE := 16000
const BARS := 8
const BEATS := 4
const PEAK := 0.8
const MAJOR := [0, 2, 4, 5, 7, 9, 11]
const MINOR := [0, 2, 3, 5, 7, 8, 10]
const DORIAN := [0, 2, 3, 5, 7, 9, 10]
const LYDIAN := [0, 2, 4, 6, 7, 9, 11]
## root = MIDI note of the key, prog = chord degrees (0-based) per bar, density = chance of a note on a weak half beat
const MOODS := {
	"spring": {"root": 60, "scale": MAJOR, "bpm": 92, "prog": [0, 4, 5, 3, 0, 4, 3, 0], "density": 0.45, "drums": false},
	"summer": {"root": 62, "scale": MAJOR, "bpm": 104, "prog": [0, 3, 0, 4, 5, 3, 4, 0], "density": 0.55, "drums": false},
	"autumn": {"root": 57, "scale": DORIAN, "bpm": 82, "prog": [0, 3, 0, 6, 0, 3, 6, 0], "density": 0.38, "drums": false},
	"winter": {"root": 65, "scale": LYDIAN, "bpm": 72, "prog": [0, 1, 0, 4, 5, 1, 4, 0], "density": 0.25, "drums": false},
	"night": {"root": 57, "scale": MINOR, "bpm": 62, "prog": [0, 5, 3, 4, 0, 5, 6, 0], "density": 0.18, "drums": false},
	"mine": {"root": 50, "scale": MINOR, "bpm": 66, "prog": [0, 0, 5, 5, 3, 3, 4, 0], "density": 0.12, "drums": false},
	"boss": {"root": 52, "scale": MINOR, "bpm": 132, "prog": [0, 0, 5, 6, 0, 0, 3, 4], "density": 0.6, "drums": true},
}
## Moods that keep playing; the others leave quiet gaps so the world's own sounds can breathe.
const CONSTANT := ["boss", "title"]
const PLAYS_BEFORE_REST := 2
const REST_SECS := 45.0

static func recipe(mood: String) -> Dictionary:
	return MOODS.get("spring" if mood == "title" else mood, MOODS["spring"])

static func mood_for(season: int, hour: float, underground: bool, boss_fight: bool, on_title: bool) -> String:
	if on_title:
		return "title"
	if boss_fight:
		return "boss"
	if underground:
		return "mine"
	var h := fposmod(hour, 24.0)
	if h >= 19.5 or h < 5.5:
		return "night"
	return ["spring", "summer", "autumn", "winter"][posmod(season, 4)]

## MIDI pitch of a scale step (steps run on past the octave, negative ones below it).
static func degree_pitch(r: Dictionary, step: int) -> int:
	var scale: Array = r["scale"]
	return int(r["root"]) + 12 * floori(step / 7.0) + int(scale[posmod(step, 7)])

static func chord_steps(degree: int) -> Array:
	return [degree, degree + 2, degree + 4]

static func loop_seconds(mood: String) -> float:
	return BARS * BEATS * 60.0 / float(recipe(mood)["bpm"])

static func compose(mood: String, variant: int = 0) -> Array:
	## Notes {voice: pad|bass|lead|kick|hat, beat, len (beats), pitch (MIDI), step (scale step), gain}.
	var r := recipe(mood)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(mood) + variant * 6151
	var out: Array = []
	var motif: Array = []          # bars 1-2 of the tune: {beat, len, rel (chord tone or passing offset)}
	for bar in 2:
		motif.append(_phrase(rng, float(r["density"])))
	var last := 9
	for bar in BARS:
		var deg: int = r["prog"][bar]
		var at := float(bar * BEATS)
		for s in chord_steps(deg):
			out.append(_note(r, "pad", at, BEATS * 1.1, s, 0.11))
		out.append(_note(r, "bass", at, 1.8, deg - 7, 0.22))
		out.append(_note(r, "bass", at + 2.0, 1.5, deg - 7 + (4 if bar % 2 == 1 else 0), 0.17))
		# the tune: motif, motif, motif again, then an answer that comes home
		var cells: Array = motif[bar % 2] if bar < 6 else _phrase(rng, float(r["density"]) * 0.7)
		for c in cells:
			var strong := is_zero_approx(fposmod(float(c["beat"]), 2.0))
			var step := _near_chord_tone(deg, last + int(c["move"])) if strong else clampi(last + int(c["move"]), 5, 15)
			if bar == BARS - 1 and c == cells[-1]:
				step = 7   # end on the key note
			last = step
			out.append(_note(r, "lead", at + float(c["beat"]), float(c["len"]), step, 0.2 if strong else 0.15))
		if r["drums"]:
			for b in BEATS:
				out.append(_note(r, "kick", at + b, 0.4, 0, 0.3 if b % 2 == 0 else 0.18))
				out.append(_note(r, "hat", at + b + 0.5, 0.15, 0, 0.07))
	return out

static func _phrase(rng: RandomNumberGenerator, density: float) -> Array:
	var cells: Array = []
	var beat := 0.0
	while beat < BEATS - 0.01:
		var downbeat := is_zero_approx(fposmod(beat, 2.0))
		if downbeat or rng.randf() < density:
			var length: float = [0.5, 1.0, 1.0, 1.5][rng.randi() % 4]
			length = minf(length, BEATS - beat)
			cells.append({"beat": beat, "len": length, "move": [-2, -1, -1, 1, 1, 2][rng.randi() % 6]})
			beat += length
		else:
			beat += 0.5
	return cells

static func _near_chord_tone(degree: int, want: int) -> int:
	## The chord tone closest to `want`, kept in the melody's register (steps 5..15).
	var best := 7
	var best_d := 999
	for s in range(5, 16):
		if posmod(s - degree, 7) in [0, 2, 4] and absi(s - want) < best_d:
			best = s
			best_d = absi(s - want)
	return best

static func _note(r: Dictionary, voice: String, beat: float, length: float, step: int, gain: float) -> Dictionary:
	return {"voice": voice, "beat": beat, "len": length, "step": step, "pitch": degree_pitch(r, step), "gain": gain}

static func midi_hz(pitch: int) -> float:
	return 440.0 * pow(2.0, (pitch - 69) / 12.0)

static func mix(mood: String, variant: int = 0) -> PackedFloat32Array:
	var spb := 60.0 / float(recipe(mood)["bpm"])
	var total := int(round(loop_seconds(mood) * RATE))
	var buf := PackedFloat32Array()
	buf.resize(total)
	var noise := RandomNumberGenerator.new()
	noise.seed = hash(mood) + 77
	for n in compose(mood, variant):
		var voice: String = n["voice"]
		var start := int(float(n["beat"]) * spb * RATE)
		var held := float(n["len"]) * spb
		var tail: float = {"pad": 0.5, "bass": 0.12, "lead": 0.35, "kick": 0.02, "hat": 0.01}[voice]
		var attack: float = {"pad": 0.35, "bass": 0.02, "lead": 0.008, "kick": 0.002, "hat": 0.001}[voice]
		var count := int((held + tail) * RATE)
		var hz := midi_hz(n["pitch"])
		var gain := float(n["gain"])
		var phase := 0.0
		for i in count:
			var t := float(i) / RATE
			var env := minf(t / attack, 1.0)
			if t > held:
				env *= 1.0 - (t - held) / tail
			var s := 0.0
			match voice:
				"pad":
					phase += hz / RATE
					s = sin(phase * TAU) + 0.25 * sin(phase * TAU * 2.003)
				"bass":
					phase += hz / RATE
					s = sin(phase * TAU) + 0.15 * sin(phase * TAU * 2.0)
					env *= exp(-t * 1.2)
				"lead":
					phase += hz / RATE
					s = absf(fposmod(phase, 1.0) * 4.0 - 2.0) - 1.0   # triangle
					s += 0.2 * sin(phase * TAU * 3.0) * exp(-t * 9.0)
					env *= exp(-t * 2.4)
				"kick":
					phase += (50.0 + 90.0 * exp(-t * 30.0)) / RATE
					s = sin(phase * TAU)
					env *= exp(-t * 12.0)
				"hat":
					s = noise.randf_range(-1.0, 1.0)
					env *= exp(-t * 40.0)
			var j := (start + i) % total
			buf[j] += s * env * gain
	var top := 0.0
	for v in buf:
		top = maxf(top, absf(v))
	if top > PEAK:
		for i in total:
			buf[i] *= PEAK / top
	return buf

static func render(mood: String, variant: int = 0) -> PackedByteArray:
	var buf := mix(mood, variant)
	var data := PackedByteArray()
	data.resize(buf.size() * 2)
	for i in buf.size():
		data.encode_s16(i * 2, int(clampf(buf[i], -1.0, 1.0) * 32767.0))
	return data

static func stream(data: PackedByteArray) -> AudioStreamWAV:
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = data
	w.loop_mode = AudioStreamWAV.LOOP_FORWARD
	w.loop_begin = 0
	w.loop_end = data.size() / 2
	return w
