class_name RoadNet
extends RefCounted
## Pure road planner for the Earth map. A main road ("spine") runs east-west through the homestead row;
## branches leave it to each region hub (A* on a coarse grid over the global water noise, then string-pulled).
## Output: road cells per chunk (WorldGen paints them as PATH before props are placed) and signpost spots.

const STEP := 4                        # coarse grid step in cells
const WIDTH := 2
const BRANCHES := [
	{"id": "farmland", "name": "Halden Farmland", "from_x": 84, "to": Vector2i(96, 96)},
	{"id": "highlands", "name": "Highlands", "from_x": 90, "to": Vector2i(96, -160)},
	{"id": "harbour", "name": "Halden Harbour", "from_x": 212, "to": Vector2i(224, 96)},
	{"id": "circuit", "name": "Race Circuit", "from_x": -98, "to": Vector2i(-96, 160)},
	{"id": "vance", "name": "Vance Aerospace", "from_x": 286, "to": Vector2i(288, -96)},
	{"id": "lumber", "name": "Lumber Camp", "from_x": -40, "to": Vector2i(-96, -32)},
]
const NO_CELL := -99999
const SPINE_X0 := -192
const SPINE_X1 := 319

var seed_value := 1
var _noise: FastNoiseLite
var polylines: Array = []              # per branch: Array[Vector2i] world cells (string-pulled waypoints)
var signs: Array = []                  # {cell, text}
var cells: Dictionary = {}             # chunk -> {local cell -> true}

static func spine_y(wx: int) -> int:
	return 32 + int(round(sin(wx * 0.2) * 3.0))

func _init(s: int = 1) -> void:
	seed_value = s
	_noise = FastNoiseLite.new()
	_noise.seed = s
	_noise.frequency = 0.035
	build()

func is_blocked(c: Vector2i) -> bool:
	## Water (with a margin), the homestead chunk (keeps its layout) and everything beyond the world.
	var ch := ChunkGrid.chunk_of_cell(c)
	if ch == ChunkGrid.HOME or not ChunkGrid.in_world(ch):
		return true
	return _noise.get_noise_2d(c.x, c.y) < -0.06

func _blocked_line(a: Vector2i, b: Vector2i) -> bool:
	var n := maxi(absi(b.x - a.x), absi(b.y - a.y))
	for i in range(n + 1):
		var p := Vector2(a).lerp(Vector2(b), float(i) / maxf(n, 1.0))
		for o in [Vector2i(0, 0), Vector2i(1, 1), Vector2i(-1, -1)]:
			if is_blocked(Vector2i(roundi(p.x), roundi(p.y)) + o):
				return true
	return false

func plan(from_cell: Vector2i, to: Vector2i) -> Array[Vector2i]:
	## A* over coarse cells (8 neighbours), then greedy line-of-sight smoothing. Empty when unreachable.
	var lo := Vector2i(mini(from_cell.x, to.x) - 48, mini(from_cell.y, to.y) - 48)
	var hi := Vector2i(maxi(from_cell.x, to.x) + 48, maxi(from_cell.y, to.y) + 48)
	var w := (hi.x - lo.x) / STEP + 1
	var h := (hi.y - lo.y) / STEP + 1
	var grid := AStarGrid2D.new()
	grid.region = Rect2i(0, 0, w, h)
	grid.cell_size = Vector2(1, 1)
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ALWAYS
	grid.update()
	for y in h:
		for x in w:
			var c := lo + Vector2i(x, y) * STEP
			if is_blocked(c):
				grid.set_point_solid(Vector2i(x, y))
	var a := (from_cell - lo) / STEP
	var b := (to - lo) / STEP
	grid.set_point_solid(a, false)
	grid.set_point_solid(b, false)
	var ids := grid.get_id_path(a, b)
	var out: Array[Vector2i] = []
	if ids.is_empty():
		return out
	var pts: Array[Vector2i] = []
	for id in ids:
		pts.append(lo + id * STEP)
	pts[0] = from_cell
	pts[pts.size() - 1] = to
	# string pulling
	var i := 0
	out.append(pts[0])
	while i < pts.size() - 1:
		var j := pts.size() - 1
		while j > i + 1 and _blocked_line(pts[i], pts[j]):
			j -= 1
		out.append(pts[j])
		i = j
	return out

func build() -> void:
	polylines.clear()
	signs.clear()
	cells.clear()
	for br in BRANCHES:
		var fx := int(br["from_x"])
		var start := Vector2i(fx, spine_y(fx))
		var hub: Vector2i = br["to"]
		var path: Array[Vector2i] = []
		for sh in [0, 6, -6, 12, -12, 20, -20, 30, -30, 40, -40, 50, -50, 64, -64]:  # slide the junction along the spine until the branch can reach the hub
			fx = int(br["from_x"]) + sh
			start = Vector2i(fx, spine_y(fx))
			if _sign_cell(fx).x == NO_CELL or _wet(start):
				continue
			for off in [Vector2i(0, 0), Vector2i(8, 0), Vector2i(-8, 0), Vector2i(0, -8), Vector2i(16, 0), Vector2i(-16, 0), Vector2i(0, -16), Vector2i(0, 8)]:
				hub = Vector2i(br["to"]) + off  # the hub itself may sit in a lake: nudge it to dry land
				path = plan(start, hub)
				if not path.is_empty():
					break
			if not path.is_empty():
				break
		if path.is_empty():
			continue
		polylines.append(path)
		_raster(path)
		signs.append({"cell": _sign_cell(fx), "text": "%s: %s" % [br["name"], direction_text(start, hub)]})

func _sign_cell(fx: int) -> Vector2i:
	## A dry corner next to the junction (not in or near water).
	var y := spine_y(fx)
	for o in [Vector2i(2, 3), Vector2i(2, -2), Vector2i(-2, 3), Vector2i(-2, -2), Vector2i(4, 3), Vector2i(4, -2), Vector2i(-4, 3), Vector2i(-4, -2), Vector2i(2, 5), Vector2i(2, -4)]:
		var c: Vector2i = Vector2i(fx, y) + o
		var ok := true
		for dy in range(-2, 3):
			for dx in range(-2, 3):
				if _noise.get_noise_2d(c.x + dx, c.y + dy) < 0.0:
					ok = false
		if ok and not ChunkGrid.chunk_of_cell(c) == ChunkGrid.HOME:
			return c
	return Vector2i(NO_CELL, 0)

func _wet(c: Vector2i) -> bool:
	for dy in range(-2, 4):
		for dx in range(-2, 3):
			if _noise.get_noise_2d(c.x + dx, c.y + dy) < -0.02:
				return true
	return false

static func direction_text(from_cell: Vector2i, to: Vector2i) -> String:
	var d := to - from_cell
	var dir := ""
	if absi(d.y) >= absi(d.x) * 0.5:
		dir += "South" if d.y > 0 else "North"
	if absi(d.x) >= absi(d.y) * 0.5:
		dir += "east" if (d.x > 0 and dir != "") else ("East" if d.x > 0 else ("west" if dir != "" else "West"))
	return "%s, %d steps" % [dir, int(Vector2(d).length())]

func _raster(path: Array) -> void:
	for k in range(path.size() - 1):
		var a: Vector2i = path[k]
		var b: Vector2i = path[k + 1]
		var n := maxi(absi(b.x - a.x), absi(b.y - a.y)) * 2
		for i in range(n + 1):
			var p := Vector2(a).lerp(Vector2(b), float(i) / maxf(n, 1.0))
			var base := Vector2i(roundi(p.x), roundi(p.y))
			for dy in WIDTH:
				for dx in WIDTH:
					_mark(base + Vector2i(dx, dy))

func _mark(c: Vector2i) -> void:
	var ch := ChunkGrid.chunk_of_cell(c)
	if not ChunkGrid.in_world(ch) or ch == ChunkGrid.HOME:
		return
	if not cells.has(ch):
		cells[ch] = {}
	cells[ch][ChunkGrid.local_cell(c)] = true

func road_cells(ch: Vector2i) -> Dictionary:
	return cells.get(ch, {})

func signs_in(ch: Vector2i) -> Array:
	var out: Array = []
	for s in signs:
		if ChunkGrid.chunk_of_cell(s["cell"]) == ch:
			out.append(s)
	return out
