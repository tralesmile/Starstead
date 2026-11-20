class_name VanceYard
extends RefCounted
## Pure layout of the Vance Aerospace rocket yard (docs/EARTH_MAP.md, chunk (7,2), story Act 2/3), world cells.
## A paved compound sits just north of the Vance road end (RoadNet hub ~ (288,-96)): razor-wire fence all round,
## a barrier gate in the middle of the south side (shut until the story gets you a seat: step rocket_seat),
## a half-built rocket on its launch pad, a hangar, fuel tanks and floodlights.

const RECT := Rect2i(277, -118, 23, 21)      # x 277..299, y -118..-98 (forced land, paved)
const GATE := [Vector2i(287, -98), Vector2i(288, -98), Vector2i(289, -98)]
const PAD := Rect2i(284, -114, 9, 6)          # launch pad decal, x 284..292, y -114..-109
const ROCKET := Vector2i(288, -110)           # rocket base cell (sprite stands on it)
const OPEN_STEP := "rocket_seat"

static func in_rect(c: Vector2i) -> bool:
	return RECT.has_point(c)

static func is_yard(c: Vector2i) -> bool:
	## Paved concrete inside the fence (the fence ring itself is paved too, under the panels).
	return RECT.has_point(c)

static func is_fence(c: Vector2i) -> bool:
	if not RECT.has_point(c) or c in GATE:
		return false
	return c.x == RECT.position.x or c.x == RECT.end.x - 1 or c.y == RECT.position.y or c.y == RECT.end.y - 1

static func fence_cells() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for y in range(RECT.position.y, RECT.end.y):
		for x in range(RECT.position.x, RECT.end.x):
			if is_fence(Vector2i(x, y)):
				out.append(Vector2i(x, y))
	return out

static func gate_open(done: Dictionary) -> bool:
	return done.has(OPEN_STEP)

static func props() -> Array:
	## {kind, cell}: big pieces stand on their bottom-centre cell.
	return [
		{"kind": "rocket", "cell": ROCKET},
		{"kind": "hangar", "cell": Vector2i(281, -113)},
		{"kind": "tank", "cell": Vector2i(296, -113)},
		{"kind": "tank", "cell": Vector2i(296, -109)},
		{"kind": "flood", "cell": Vector2i(279, -116)},
		{"kind": "flood", "cell": Vector2i(297, -116)},
		{"kind": "flood", "cell": Vector2i(279, -100)},
		{"kind": "flood", "cell": Vector2i(297, -100)},
		{"kind": "crates", "cell": Vector2i(282, -102)},
		{"kind": "crates", "cell": Vector2i(294, -103)},
	]

static func solid_cells() -> Dictionary:
	## Cells the player cannot walk through (fence ring, shut gate handled separately, big props).
	var out := {}
	for c in fence_cells():
		out[c] = true
	for p in props():
		out[p["cell"]] = true
	return out
