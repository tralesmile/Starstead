class_name GoalArrow
extends RefCounted
## Pure maths for the tutorial arrow: a gold arrow on the screen edge pointing at the current goal (first-day steps).
## kind() picks what to point at; edge_pos() keeps it inside the view; it fades out when the goal is close.

const HIDE_DIST := 110.0
const FADE_DIST := 220.0
const MARGIN := 26.0

static func kind(tilled: int, planted: int, day: int, can_owned: bool) -> String:
	## "" = no arrow (open ground: the goal text is enough), "tree", "bed"
	if day <= 1 and tilled == 0:
		return ""
	if day <= 1 and planted == 0:
		return ""
	if day <= 1 and not can_owned:
		return "tree"
	if day <= 1:
		return "bed"
	return ""

static func nearest(from: Vector2, points: Array) -> Vector2:
	var best := Vector2.INF
	var bd := INF
	for p in points:
		var d := from.distance_squared_to(p)
		if d < bd:
			bd = d
			best = p
	return best

static func alpha(dist: float) -> float:
	## 0 near the goal (you can see it), 1 when it is far; eases in between.
	return clampf((dist - HIDE_DIST) / (FADE_DIST - HIDE_DIST), 0.0, 1.0)

static func edge_pos(from: Vector2, target: Vector2, half_view: Vector2) -> Dictionary:
	## Where on screen (relative to its centre) the arrow sits, and its angle; clamped inside half_view - MARGIN.
	var d := target - from
	if d.length() < 1.0:
		return {"pos": Vector2.ZERO, "angle": 0.0}
	var lim := half_view - Vector2(MARGIN, MARGIN)
	var k := minf(lim.x / maxf(absf(d.x), 0.001), lim.y / maxf(absf(d.y), 0.001))
	k = minf(k, 1.0)
	return {"pos": d * k, "angle": d.angle()}

static func bob(t: float) -> float:
	## Gentle 3 px sway along the pointing direction.
	return sin(t * 5.0) * 3.0
