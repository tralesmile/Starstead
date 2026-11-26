class_name FishingLine
extends RefCounted
## Pure verlet rope for the fishing line: pinned at the rod tip and the bobber, sags with its slack, sways in the
## wind, snaps taut when a fish bites and settles with a damped wobble after a cast. Pixels and seconds.

const N := 14
const STEP := 1.0 / 60.0
const SAG_GRAVITY := 260.0
const DAMP := 0.93
const ITERATIONS := 14
const MAX_CATCHUP := 8      # fixed steps per frame, so a hitch cannot stall the game

var pts := PackedVector2Array()
var prev := PackedVector2Array()
var _acc := 0.0

func reset(a: Vector2, b: Vector2) -> void:
	pts.resize(N)
	for i in N:
		pts[i] = a.lerp(b, float(i) / float(N - 1))
	prev = pts.duplicate()
	_acc = 0.0

## How much longer than the straight distance the line is paid out.
static func slack_for(flying: bool, waiting: bool) -> float:
	if flying:
		return 0.10
	return 0.035 if waiting else 0.0   # a bite or a reel pulls it tight

## Sideways bobber tug while reeling: follows the fish up and down the reel track, harder when it is escaping.
static func fish_tug(fish_pos: float, progress: float, t: float) -> Vector2:
	var strain := 1.0 - clampf(progress, 0.0, 1.0)
	return Vector2((fish_pos - 0.5) * 22.0 + sin(t * 21.0) * 2.5 * strain, sin(t * 13.0) * 1.5 * strain)

## 0 = calm .. 1 = about to break: the line turns red as the catch slips away.
static func strain(progress: float) -> float:
	return clampf((0.3 - progress) / 0.3, 0.0, 1.0)

## Seconds between reel clicks: a quick ratchet while you gain on the fish, a slow one while it runs.
static func click_interval(gaining: bool) -> float:
	return 0.09 if gaining else 0.24

func step(a: Vector2, b: Vector2, slack: float, wind: float, delta: float) -> void:
	if pts.size() != N:
		reset(a, b)
	_acc = minf(_acc + delta, STEP * MAX_CATCHUP)
	while _acc >= STEP - 0.00001:
		_acc -= STEP
		_tick(a, b, slack, wind)
	pts[0] = a
	pts[N - 1] = b

func _tick(a: Vector2, b: Vector2, slack: float, wind: float) -> void:
	var g := Vector2(wind, SAG_GRAVITY if slack > 0.0 else 0.0) * STEP * STEP
	for i in range(1, N - 1):
		var p := pts[i]
		pts[i] = p + (p - prev[i]) * DAMP + g
		prev[i] = p
	pts[0] = a
	pts[N - 1] = b
	var rest := a.distance_to(b) * (1.0 + slack) / float(N - 1)
	for it in ITERATIONS:
		for i in N - 1:
			var d := pts[i + 1] - pts[i]
			var len := d.length()
			if len <= rest or len < 0.0001:
				continue   # a rope resists stretching only
			var fix := d * ((len - rest) / len)
			var wa := 0.0 if i == 0 else (1.0 if i + 1 == N - 1 else 0.5)
			if i == 0 and i + 1 == N - 1:
				continue
			pts[i] += fix * wa
			if i + 1 != N - 1:
				pts[i + 1] -= fix * (1.0 - wa)
	if slack <= 0.0:   # taut: pull the points onto the straight line quickly
		for i in range(1, N - 1):
			pts[i] = pts[i].lerp(a.lerp(b, float(i) / float(N - 1)), 0.35)

## Largest distance of the rope below the straight line between its ends (px).
func sag() -> float:
	var out := 0.0
	for i in N:
		out = maxf(out, pts[i].y - pts[0].lerp(pts[N - 1], float(i) / float(N - 1)).y)
	return out
