class_name ShiftGame
extends RefCounted
## Job mini-game: the shift's performance score (0..1) scales the pay between x0.7 and x1.3. Pure rules, no nodes.
## Kinds: "timing" (stop a sweeping marker in the zone), "sequence" (repeat arrow keys in order, against a clock),
## "balance" (hold a drifting needle inside the zone with left/right). Higher ranks get wider zones and more patience.

const TIMING_ROUNDS := 5
const SEQ_ROUNDS := 4
const BALANCE_TIME := 8.0
const PAY_MIN := 0.7
const PAY_MAX := 1.3
const PERFECT := 0.9

var kind := "timing"
var rank := 0
var seed_v := 1
var rounds := 5
var round_i := 0
var scores: Array[float] = []
var done := false
var t := 0.0          # seconds inside the current round
var center := 0.5     # timing: zone centre 0..1
var half := 0.15      # timing zone half-width, balance zone half-width
var seq: Array[int] = []
var seq_i := 0
var seq_limit := 4.0
var needle := 0.0     # balance: -1..1
var vel := 0.0
var in_zone := 0.0
var last_hit := -1.0  # timing: score of the last press (for feedback), -1 none yet
var flash := 0.0      # seconds since the last press/wrong key (view feedback)
var flash_ok := true

func _init(k: String = "timing", rank_idx: int = 0, seed_value: int = 1) -> void:
	kind = k if k in ["timing", "sequence", "balance"] else "timing"
	rank = clampi(rank_idx, 0, 2)
	seed_v = seed_value
	match kind:
		"timing": rounds = TIMING_ROUNDS
		"sequence": rounds = SEQ_ROUNDS
		_: rounds = 1
	_start_round()

# ---- pure helpers (tested) ----
## Triangle wave 0..1..0 with period 2 in t.
static func tri(x: float) -> float:
	var p := fposmod(x, 2.0)
	return p if p <= 1.0 else 2.0 - p

static func timing_score(pos: float, c: float, h: float) -> float:
	var d := absf(pos - c)
	if d <= h * 0.35:
		return 1.0
	if d <= h:
		return 0.6
	return 0.0

static func multiplier(score: float) -> float:
	return PAY_MIN + (PAY_MAX - PAY_MIN) * clampf(score, 0.0, 1.0)

static func grade_of(score: float) -> String:
	if score >= PERFECT:
		return "Perfect!"
	if score >= 0.7:
		return "Great"
	if score >= 0.45:
		return "Fine"
	return "Sloppy"

## Slow wandering push on the balance needle, different per seed, never zero for long.
static func drift_at(time: float, s: int) -> float:
	var p := float(s % 97) * 0.37
	return 0.9 * sin(time * 1.3 + p) + 0.5 * sin(time * 2.9 + p * 1.7)

## One physics step of the balance needle. input -1/0/1. Returns {needle, vel}; the walls stop it dead.
static func balance_step(n: float, v: float, input: float, drift: float, dt: float) -> Dictionary:
	v += (drift * 0.8 + input * 3.2) * dt
	v *= maxf(0.0, 1.0 - 1.6 * dt)
	n += v * dt
	if absf(n) >= 1.0:
		n = clampf(n, -1.0, 1.0)
		v = 0.0
	return {"needle": n, "vel": v}

static func seq_length(rank_idx: int, round_idx: int) -> int:
	return 3 + round_idx + (1 if rank_idx >= 2 else 0)

static func timing_speed(round_idx: int) -> float:
	return 0.7 + 0.22 * float(round_idx)

## Marker position 0..1 for the current round time.
func marker() -> float:
	return tri(t * timing_speed(round_i))

# ---- play ----
func _rng_int(salt: int, n: int) -> int:
	return int(absi(hash(Vector3i(seed_v, round_i * 31 + salt, rank))) % n)

func _start_round() -> void:
	t = 0.0
	match kind:
		"timing":
			half = 0.15 + 0.03 * float(rank)
			center = 0.2 + 0.6 * float(_rng_int(1, 100)) / 99.0
		"sequence":
			seq.clear()
			for i in seq_length(rank, round_i):
				seq.append(_rng_int(10 + i, 4))
			seq_i = 0
			seq_limit = 2.2 + 0.7 * float(seq.size()) + 0.4 * float(rank)
		"balance":
			half = 0.3 + 0.05 * float(rank)
			needle = 0.0
			vel = 0.0
			in_zone = 0.0

func _finish_round(s: float) -> void:
	scores.append(clampf(s, 0.0, 1.0))
	round_i += 1
	if round_i >= rounds:
		done = true
	else:
		_start_round()

## Advance the clock (seconds). `input` is -1/0/1 for balance (held keys).
func step(dt: float, input: float = 0.0) -> void:
	if done:
		return
	t += dt
	flash += dt
	match kind:
		"timing":
			if t > 6.0:
				last_hit = 0.0
				flash = 0.0
				flash_ok = false
				_finish_round(0.0)
		"sequence":
			if t > seq_limit:
				_finish_round(float(seq_i) / float(seq.size()) * 0.8)
		"balance":
			var r := balance_step(needle, vel, input, drift_at(t, seed_v), dt)
			needle = r["needle"]
			vel = r["vel"]
			if absf(needle) <= half:
				in_zone += dt
			if t >= BALANCE_TIME:
				_finish_round(in_zone / BALANCE_TIME)

## Space/E in a timing round.
func press_action() -> void:
	if done or kind != "timing":
		return
	var s := timing_score(marker(), center, half)
	last_hit = s
	flash = 0.0
	flash_ok = s > 0.0
	_finish_round(s)

## Arrow direction 0 up, 1 right, 2 down, 3 left in a sequence round.
func press_dir(d: int) -> void:
	if done or kind != "sequence":
		return
	flash = 0.0
	if d == seq[seq_i]:
		flash_ok = true
		seq_i += 1
		if seq_i >= seq.size():
			_finish_round(1.0 - maxf(0.0, t - seq_limit * 0.5) / seq_limit * 0.3)
	else:
		flash_ok = false
		_finish_round(float(seq_i) / float(seq.size()) * 0.5)

func score() -> float:
	if scores.is_empty():
		return 0.0
	var s := 0.0
	for x in scores:
		s += x
	return s / float(scores.size())

func result() -> Dictionary:
	var s := score()
	return {"score": s, "mult": multiplier(s), "grade": grade_of(s), "perfect": s >= PERFECT, "bonus_xp": 5 if s >= PERFECT else 0}

## Title/hint per kind and job id for the overlay.
static func title_for(job_id: String, k: String) -> String:
	match job_id:
		"farmhand": return "Hoe the rows - stop the marker in the green"
		"chef": return "Chop - stop the knife in the green"
		"builder": return "Hammer - stop the marker in the green"
		"miner": return "Swing the pick - stop the marker in the green"
		"delivery_driver": return "Hold the van steady - LEFT / RIGHT"
		"police_officer": return "Steady your aim - LEFT / RIGHT"
		"astronaut": return "Hold the capsule level - LEFT / RIGHT"
		"mechanic": return "Wrench the bolts - repeat the arrows"
		"rocket_tech": return "Wire the panel - repeat the arrows"
		"doctor": return "Run the checks - repeat the arrows"
		"pit_crew": return "Wheel gun - stop the marker in the green"
		"groundskeeper": return "Mow straight stripes - LEFT / RIGHT"
		"sparring_partner": return "Call the combos - repeat the arrows"
	return {"timing": "Stop the marker in the green", "sequence": "Repeat the arrows", "balance": "Keep the needle in the green"}[k]
