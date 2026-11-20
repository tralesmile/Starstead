class_name CityFolk
extends RefCounted
## Pure rules for Port Halden pedestrians (E9): where people may walk (sidewalks, plazas, zebra crossings,
## never open asphalt), the places they head for (shop doors, benches, plaza), how many are out at each
## hour, how long they linger, and routes between cells. CityFolkView spawns and moves the sprites.

const AREA := Rect2i(166, -22, 53, 59)     # CityModel.RECT plus the avenue down to the spine road
const CENTER := Vector2i(192, 3)
const ACTIVE_RADIUS := 44.0                 # cells: folk exist only while the player is this close
const SPEED := 30.0                         # px/s, a stroll (player walks ~80)
const COP_SPEED := 26.0

static func blocked_cells() -> Dictionary:
	## Street furniture and the fountain basin stand in the way.
	var out := {}
	for p in CityModel.props():
		var c: Vector2i = p["cell"]
		out[c] = true
		if String(p["kind"]) == "fountain":
			for dx in range(-1, 2):
				for dy in range(-1, 1):
					out[c + Vector2i(dx, dy)] = true
	for b in CityModel.buildings():
		for c in CityModel.building_cells(b):
			out[c] = true
	return out

static func walkable(c: Vector2i, blocked: Dictionary = {}) -> bool:
	if blocked.has(c) or not AREA.has_point(c):
		return false
	return CityModel.is_sidewalk(c) or CityModel.zebra(c) != 0

static func spots() -> Array:
	## Destinations: {cell, kind}. kind door = idles at a shop door, bench = sits a while, plaza = looks around.
	var out: Array = []
	for b in CityModel.buildings():
		out.append({"cell": b["door"], "kind": "door", "id": b["id"]})
	for p in CityModel.props():
		if String(p["kind"]) == "bench":
			out.append({"cell": p["cell"] + Vector2i(0, 1), "kind": "bench"})
	for p in CityModel.PLAZAS:
		var r: Rect2i = p
		out.append({"cell": r.position + Vector2i(r.size.x / 2, r.size.y - 1), "kind": "plaza"})
	return out

static func density(hour: float) -> int:
	## How many pedestrians are out (cops not included).
	var h := fposmod(hour, 24.0)
	if h < 5.0:
		return 2
	if h < 7.0:
		return 6
	if h < 10.0:
		return 12
	if h < 17.0:
		return 16
	if h < 21.0:
		return 12
	return 5

static func cop_count(hour: float) -> int:
	var h := fposmod(hour, 24.0)
	return 2 if h >= 7.0 and h < 22.0 else 1

static func dwell(kind: String, roll: float) -> float:
	## Seconds spent at a spot; roll in 0..1.
	match kind:
		"door":
			return lerpf(3.0, 7.0, roll)
		"bench":
			return lerpf(8.0, 16.0, roll)
		"plaza":
			return lerpf(2.0, 6.0, roll)
	return 0.0

static func active(player_cell: Vector2i) -> bool:
	return Vector2(player_cell - CENTER).length() <= ACTIVE_RADIUS

static func build_grid(blocked: Dictionary) -> AStarGrid2D:
	var g := AStarGrid2D.new()
	g.region = AREA
	g.cell_size = Vector2(32, 32)
	g.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	g.update()
	for y in range(AREA.position.y, AREA.end.y):
		for x in range(AREA.position.x, AREA.end.x):
			var c := Vector2i(x, y)
			if not walkable(c, blocked):
				g.set_point_solid(c, true)
	return g

static func route(g: AStarGrid2D, from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	if not g.is_in_boundsv(from) or not g.is_in_boundsv(to) or g.is_point_solid(from) or g.is_point_solid(to):
		return out
	for c in g.get_id_path(from, to):
		out.append(c)
	return out

static func cell_px(c: Vector2i, lane: float = 0.0) -> Vector2:
	## Pixel centre of a cell, nudged sideways by lane (-1..1) so walkers do not all walk the same line.
	return (Vector2(c) + Vector2(0.5 + lane * 0.25, 0.55 + lane * 0.2)) * 32.0

const WITNESS_RADIUS := 7.0 * 32.0   # px: pedestrians this close see a crime and report it
const PANIC_RADIUS := 9.0 * 32.0     # px: everyone this close runs for a door
const PANIC_SPEED := 2.2             # x walking speed
const SCREAM_SECS := 4.0             # how long a panicked walker keeps running before calming down

static func witnesses(positions: Array, crime: Vector2) -> int:
	var n := 0
	for p in positions:
		if (p as Vector2).distance_to(crime) <= WITNESS_RADIUS:
			n += 1
	return n

static func panics(pos: Vector2, crime: Vector2) -> bool:
	return pos.distance_to(crime) <= PANIC_RADIUS

static func flee_spot(doors: Array, from: Vector2i, crime: Vector2i) -> Vector2i:
	## The door to run to: far from the crime, not too far from where you stand, and not past the crime.
	var best := from
	var best_score := -INF
	for d in doors:
		var c: Vector2i = d["cell"] if d is Dictionary else d
		var away := Vector2(c - crime).length()
		var walk := Vector2(c - from).length()
		var toward := Vector2(c - from).dot(Vector2(crime - from))
		var score := away - 0.5 * walk - (1000.0 if toward > 0.0 and walk > 1.0 else 0.0)
		if score > best_score:
			best_score = score
			best = c
	return best
