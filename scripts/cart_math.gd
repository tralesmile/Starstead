class_name CartMath
extends RefCounted
## Pure mine-cart physics on a rail polyline. One number for position (s, px along the track) and one for speed
## (v, px/s, positive = away from the entrance). The mine falls away from the entrance, so a parked cart that is let
## off the brake rolls deeper by itself and has to be pumped back up. Corners taken too fast screech and lose speed,
## and the sprung buffers at both ends bounce the cart back.

const SLOPE := 46.0        # px/s^2 pull toward the deep end
const ROLL := 14.0         # rolling friction
const DRAG := 0.12         # speed-proportional loss per second
const PUMP := 150.0        # pushing the handle
const BRAKE := 240.0
const MAX_V := 260.0
const CORNER_V := 150.0    # faster than this through a bend jolts
const CORNER_KEEP := 0.72
const BOUNCE := 0.3        # share of speed returned by a buffer
const BUMP_V := 60.0       # a buffer hit faster than this is felt
const STILL := 3.0

static func points(cells: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for c in cells:
		out.append(Vector2(c) * 32.0 + Vector2(16, 16))
	return out

static func length(pts: PackedVector2Array) -> float:
	return maxf(0.0, float(pts.size() - 1) * 32.0)

static func pos_at(pts: PackedVector2Array, s: float) -> Vector2:
	## Rail cells are 4-neighbours, so every segment is 32 px long.
	if pts.is_empty():
		return Vector2.ZERO
	var cs := clampf(s, 0.0, length(pts))
	var i := mini(int(cs / 32.0), pts.size() - 2)
	if i < 0:
		return pts[0]
	return pts[i].lerp(pts[i + 1], (cs - i * 32.0) / 32.0)

static func dir_at(pts: PackedVector2Array, s: float) -> Vector2:
	if pts.size() < 2:
		return Vector2.RIGHT
	var i := clampi(int(clampf(s, 0.0, length(pts)) / 32.0), 0, pts.size() - 2)
	return (pts[i + 1] - pts[i]).normalized()

static func is_corner(pts: PackedVector2Array, i: int) -> bool:
	if i <= 0 or i >= pts.size() - 1:
		return false
	return not (pts[i] - pts[i - 1]).is_equal_approx(pts[i + 1] - pts[i])

static func step(state: Dictionary, pts: PackedVector2Array, pump: float, braking: bool, dt: float) -> Dictionary:
	## state: {s, v}. pump: -1 (back to the entrance) .. 1 (deeper). Returns {"jolt": bool, "bump": speed of a buffer hit or 0}.
	var out := {"jolt": false, "bump": 0.0}
	var s := float(state["s"])
	var v := float(state["v"])
	var total := length(pts)
	var at_start := s <= 0.01
	var at_end := s >= total - 0.01
	if braking:
		v = move_toward(v, 0.0, BRAKE * dt)
	else:
		v += (SLOPE + clampf(pump, -1.0, 1.0) * PUMP) * dt
		v = move_toward(v, 0.0, ROLL * dt)
		v -= v * DRAG * dt
	v = clampf(v, -MAX_V, MAX_V)
	if (at_start and v < 0.0 and absf(v) <= BUMP_V) or (at_end and v > 0.0 and v <= BUMP_V):
		v = 0.0   # resting against a buffer
	var ns := s + v * dt
	# bends: crossing the middle of a corner cell too fast scrubs speed
	var a := minf(s, ns)
	var b := maxf(s, ns)
	for i in range(int(ceil(a / 32.0)), int(floor(b / 32.0)) + 1):
		var cs := i * 32.0
		if cs > a and cs <= b and is_corner(pts, i) and absf(v) > CORNER_V:
			v = signf(v) * maxf(CORNER_V, absf(v) * CORNER_KEEP)
			out["jolt"] = true
	if ns < 0.0 or ns > total:
		ns = clampf(ns, 0.0, total)
		if absf(v) > BUMP_V:
			out["bump"] = absf(v)
			v = -v * BOUNCE
		else:
			v = 0.0
	state["s"] = ns
	state["v"] = v
	return out

static func pump_from_input(input: Vector2, dir: Vector2) -> float:
	## Pushing the stick along the rail pumps that way, wherever the rail happens to point.
	return clampf(input.dot(dir), -1.0, 1.0)

static func tile_frame(from_dir: Vector2i, to_dir: Vector2i) -> int:
	## Frame in cave_rail.png for a cell whose neighbours lie in these two directions (a rail end passes ZERO).
	var d := [from_dir, to_dir]
	var n := Vector2i(0, -1) in d
	var s := Vector2i(0, 1) in d
	var e := Vector2i(1, 0) in d
	var w := Vector2i(-1, 0) in d
	if n and e:
		return 2
	if n and w:
		return 3
	if s and e:
		return 4
	if s and w:
		return 5
	return 1 if n or s else 0
