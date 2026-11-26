class_name IsleModel
extends RefCounted
## Pure layout + forage rules of Gull Isle (E13), a wobbly island in the sea south-east of Halden Harbour, reached only
## by ferry. World cells (homestead chunk = 0..63). Beach finds wash up each morning; a storm washes up more.

const CENTER := Vector2(284.0, 160.0)
const RX := 17.0
const RY := 12.0
const RECT := Rect2i(261, 145, 44, 31)
const JETTY := Rect2i(261, 159, 10, 3)       # x 261..270, y 159..161: planks out to deep water on the west side
const POST_CELL := Vector2i(266, 159)        # isle ferry post
const LANDING := Vector2i(264, 160)          # where you step off
const CAIRN_CELL := Vector2i(292, 155)       # grandmother's star cairn
const SPOTS := 8
const STORM_EXTRA := 4
const STORM_RAIN := 0.8
const CAIRN_REWARD := "pearl"

static func radius_at(angle: float) -> float:
	return 1.0 + 0.10 * sin(angle * 3.0) + 0.06 * sin(angle * 5.0 + 1.0)

static func depth(c: Vector2i) -> float:
	## 0 at the centre, 1 at the coast, above 1 is sea.
	var d := Vector2((c.x - CENTER.x) / RX, (c.y - CENTER.y) / RY)
	return d.length() / radius_at(d.angle())

static func is_jetty(c: Vector2i) -> bool:
	return JETTY.has_point(c)

static func is_island(c: Vector2i) -> bool:
	return RECT.has_point(c) and depth(c) <= 1.0

static func is_land(c: Vector2i) -> bool:
	return RECT.has_point(c) and (is_jetty(c) or depth(c) <= 1.0)

static func is_beach(c: Vector2i) -> bool:
	return is_island(c) and not is_jetty(c) and depth(c) > 0.76

static func is_shallows(c: Vector2i) -> bool:
	## Pale water ring around the coast.
	return RECT.grow(4).has_point(c) and depth(c) <= 1.28

static func is_clear(c: Vector2i) -> bool:
	## No trees or rocks here: the jetty approach, the cairn and the beach.
	return is_jetty(c) or is_beach(c) or Vector2(c - CAIRN_CELL).length() <= 2.5 or Vector2(c - LANDING).length() <= 6.0

static func decor() -> Array:
	## {kind, frame (isle_props.png), cell}
	return [
		{"kind": "ferry_post", "frame": 4, "cell": POST_CELL},
		{"kind": "cairn", "frame": 5, "cell": CAIRN_CELL},
		{"kind": "rowboat", "frame": 6, "cell": Vector2i(279, 169)},
		{"kind": "tidepool", "frame": 7, "cell": Vector2i(296, 164)},
		{"kind": "tidepool", "frame": 7, "cell": Vector2i(283, 150)},
	]

static func beach_cells() -> Array:
	var taken := {}
	for p in decor():
		taken[p["cell"]] = true
	var out: Array = []
	for y in range(RECT.position.y, RECT.end.y):
		for x in range(RECT.position.x, RECT.end.x):
			var c := Vector2i(x, y)
			if is_beach(c) and not taken.has(c) and depth(c) < 0.95:
				out.append(c)
	return out

static func item_for(roll: float) -> String:
	if roll < 0.45:
		return "shell"
	if roll < 0.75:
		return "kelp"
	if roll < 0.95:
		return "sea_glass"
	return "pearl"

static func frame_for(item: String) -> int:
	return int({"shell": 0, "sea_glass": 1, "kelp": 2, "pearl": 3}.get(item, 0))

static func forage(day: int, stormy_yesterday: bool) -> Array:
	## Deterministic beach finds for a day: {cell, item}.
	var cells := beach_cells()
	var rng := RandomNumberGenerator.new()
	rng.seed = day * 31337 + 7
	var n := mini(SPOTS + (STORM_EXTRA if stormy_yesterday else 0), cells.size())
	var out: Array = []
	for i in n:
		var j := rng.randi_range(0, cells.size() - 1)
		var c: Vector2i = cells[j]
		cells.remove_at(j)
		out.append({"cell": c, "item": item_for(rng.randf())})
	return out
