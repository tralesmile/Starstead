class_name RoadTraffic
extends RefCounted
## Pure rules for ambient traffic on the open-world roads (E11): where a vehicle or hiker stands along a road
## polyline (right-hand lane), how it slows for whatever is ahead, when it honks, and how many are out by the hour.
## Roads come from RoadNet (branch polylines + the east-west spine); the view does the drawing.

const CELL := 32.0
const LANE := 15.0           # px right of the road centre line for cars
const VERGE := 26.0          # px from the centre line for walkers (the road is 64 px wide)
const STOP_GAP := 46.0       # px to the thing ahead at which a car is stopped
const FREE_GAP := 150.0      # px beyond which a car ignores it
const BAND := 24.0           # half-width of the strip ahead that counts as "in my way"
const HONK_AFTER := 2.2      # s blocked before the driver leans on the horn
const SPAWN_MIN := 420.0     # px from the player: cars appear out of sight...
const SPAWN_MAX := 640.0
const DESPAWN := 900.0       # ...and vanish once this far behind
const MAX_CARS := 6
const MAX_HIKERS := 2
const SPINE_STEP := 8

static func spine_polyline(x0: int, x1: int, y_of: Callable) -> Array:
	## The main road as waypoints in cells, every SPINE_STEP cells.
	var out: Array = []
	var x := x0
	while x <= x1:
		out.append(Vector2i(x, int(y_of.call(x))))
		x += SPINE_STEP
	return out

static func to_px(cells: Array) -> PackedVector2Array:
	## Road is 2 cells wide starting at the waypoint cell, so its centre line is one cell further on.
	var out := PackedVector2Array()
	for c in cells:
		out.append((Vector2(c) + Vector2(1.0, 1.0)) * CELL)
	return out

static func length(pts: PackedVector2Array) -> float:
	var l := 0.0
	for i in range(pts.size() - 1):
		l += pts[i].distance_to(pts[i + 1])
	return l

static func sample(pts: PackedVector2Array, dist: float) -> Dictionary:
	## {pos, dir (unit tangent along the polyline), done}; done when dist is outside [0, length].
	if pts.size() < 2:
		return {"pos": Vector2.ZERO, "dir": Vector2.RIGHT, "done": true}
	var d := maxf(dist, 0.0)
	for i in range(pts.size() - 1):
		var seg := pts[i].distance_to(pts[i + 1])
		if d <= seg or i == pts.size() - 2:
			var dir := (pts[i + 1] - pts[i]).normalized()
			var t := clampf(d / maxf(seg, 0.001), 0.0, 1.0)
			return {"pos": pts[i].lerp(pts[i + 1], t), "dir": dir, "done": dist < 0.0 or dist > length(pts)}
		d -= seg
	return {"pos": pts[pts.size() - 1], "dir": Vector2.RIGHT, "done": true}

static func lane_point(pts: PackedVector2Array, dist: float, forward: bool, offset: float = LANE) -> Dictionary:
	## Position + heading for something travelling forward (+1) or backward along the polyline, keeping right.
	var s := sample(pts, dist)
	var dir: Vector2 = s["dir"] if forward else -(s["dir"] as Vector2)
	var right := dir.rotated(PI * 0.5)
	return {"pos": (s["pos"] as Vector2) + right * offset, "heading": dir.angle(), "done": s["done"]}

static func gap_ahead(pos: Vector2, heading: float, obstacles: Array) -> float:
	## Forward distance to the nearest obstacle inside the strip in front, INF when the way is clear.
	var f := Vector2.from_angle(heading)
	var side := f.orthogonal()
	var best := INF
	for o in obstacles:
		var rel: Vector2 = (o as Vector2) - pos
		var ahead := rel.dot(f)
		if ahead > 0.0 and absf(rel.dot(side)) < BAND and ahead < best:
			best = ahead
	return best

static func follow_speed(cruise: float, gap: float) -> float:
	## Full cruise beyond FREE_GAP, dead stop inside STOP_GAP, a smooth ramp in between.
	if gap >= FREE_GAP:
		return cruise
	if gap <= STOP_GAP:
		return 0.0
	var t := (gap - STOP_GAP) / (FREE_GAP - STOP_GAP)
	return cruise * t * t * (3.0 - 2.0 * t)

static func ease_speed(cur: float, target: float, delta: float) -> float:
	## Brakes harder than it accelerates (cars stop in a few hundred px, pull away gently).
	return move_toward(cur, target, (260.0 if target < cur else 70.0) * delta)

static func honks(blocked_for: float) -> bool:
	return blocked_for >= HONK_AFTER

static func cruise_speed(seed_value: int) -> float:
	return 78.0 + float(absi(seed_value) % 9) * 7.0   # 78..134 px/s: slower than the player's car on purpose

static func hiker_speed(seed_value: int) -> float:
	return 22.0 + float(absi(seed_value) % 4) * 3.0

static func car_target(hour: float) -> int:
	if hour < 5.0 or hour >= 23.0:
		return 1
	if hour < 7.0 or hour >= 20.0:
		return 3
	if (hour >= 7.5 and hour < 9.5) or (hour >= 16.0 and hour < 18.5):
		return MAX_CARS
	return 4

static func hiker_target(hour: float) -> int:
	return MAX_HIKERS if hour >= 7.0 and hour < 19.0 else 0

static func in_view_ring(d: float, lo: float = SPAWN_MIN, hi: float = SPAWN_MAX) -> bool:
	return d >= lo and d <= hi

static func should_despawn(dist_to_player: float, dist_along: float, road_len: float) -> bool:
	return dist_to_player > DESPAWN or dist_along < -40.0 or dist_along > road_len + 40.0

static func tyre_swerve(gap: float, lateral_hint: float) -> float:
	## Small sideways nudge (px) a car makes when it has to stop close behind something: it eases left to look past.
	if gap > FREE_GAP * 0.6:
		return 0.0
	return -clampf(lateral_hint, 0.0, 1.0) * 6.0

static func hit_response(impact_speed: float, away: Vector2) -> Dictionary:
	## A traffic car struck by something moving at impact_speed (px/s): it stalls with the hazards on for a while
	## (0.6..4 s by how hard it was hit) and is shoved away from the other vehicle by up to 28 px that then eases out.
	var dir := away.normalized() if away.length() > 0.001 else Vector2.ZERO
	return {"stall": clampf(impact_speed / 70.0, 0.6, 4.0), "shove": dir * minf(impact_speed * 0.12, 28.0)}

static func shove_decay(shove: Vector2, delta: float) -> Vector2:
	return shove * exp(-3.0 * delta)
