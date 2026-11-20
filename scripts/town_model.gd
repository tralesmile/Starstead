class_name TownModel
extends RefCounted
## Pure town layout: finds dry, free spots near each building's NPC place and returns footprints.
## Footprint = width x 2 cells; the sprite's bottom edge sits at the footprint's bottom edge.

const DEPTH := 2

static func specs() -> Array:
	## id, sprite, width in cells, which data/npcs.json place to settle near, door x in px, name
	return [
		{"id": "barn", "sprite": "barn", "w": 4, "place": "barn", "door_px": 64, "name": "Barn"},
		{"id": "workshop", "sprite": "workshop", "w": 4, "place": "workshop", "door_px": 56, "name": "Workshop"},
		{"id": "fish_hut", "sprite": "house", "w": 3, "place": "fish_hut", "door_px": 48, "name": "Fisher's house"},
		{"id": "farmhouse", "sprite": "house", "w": 3, "place": "home", "door_px": 48, "name": "Farmhouse"},
	]

static func _fits(top_left: Vector2i, w: int, ok: Callable, taken: Dictionary) -> bool:
	for dy in range(-1, DEPTH + 2):  # 1-cell margin all round, door row below must be walkable
		for dx in range(-1, w + 1):
			var c := top_left + Vector2i(dx, dy)
			if not ok.call(c) or taken.has(c):
				return false
	return true

static func layout(places: Dictionary, home: Vector2i, ok: Callable, blocked: Array = []) -> Array:
	## places: name -> [x, y]; ok(cell)->bool free dry land. Returns [{id, sprite, cell, w, door, name, door_px}].
	var out: Array = []
	var taken: Dictionary = {}
	for b in blocked:
		taken[b] = true
	for s in specs():
		var want: Vector2i = home
		if s["place"] != "home":
			var p: Array = places.get(s["place"], [32, 32])
			want = Vector2i(int(p[0]), int(p[1]))
		var found := Vector2i(-1, -1)
		for r in range(0, 30):
			for dy in range(-r, r + 1):
				for dx in range(-r, r + 1):
					if maxi(absi(dx), absi(dy)) != r:
						continue
					var c := want + Vector2i(dx, dy)
					if _fits(c, int(s["w"]), ok, taken):
						found = c
						break
				if found.x >= 0:
					break
			if found.x >= 0:
				break
		if found.x < 0:
			continue
		for dy in range(-1, DEPTH + 2):
			for dx in range(-1, int(s["w"]) + 1):
				taken[found + Vector2i(dx, dy)] = true
		var door := found + Vector2i(int(s["door_px"]) / 32, DEPTH)  # cell just south of the door
		out.append({"id": s["id"], "sprite": s["sprite"], "cell": found, "w": s["w"], "door": door, "name": s["name"], "door_px": s["door_px"]})
	return out

static func footprint_cells(b: Dictionary) -> Array[Vector2i]:
	var r: Array[Vector2i] = []
	for dy in DEPTH:
		for dx in int(b["w"]):
			r.append(b["cell"] + Vector2i(dx, dy))
	return r

static func sprite_bottom_center(b: Dictionary) -> Vector2:
	return Vector2((b["cell"].x + float(b["w"]) * 0.5) * 32.0, (b["cell"].y + DEPTH) * 32.0)

static func village_paths(buildings: Array, hub: Vector2i, walk: Callable, size: int = 64) -> Array[Vector2i]:
	## Dirt footpaths from each village door to the hub (the market stall front), routed around water, trees
	## and buildings (walk(c) = cell may carry a path). Shared stretches merge. Sorted, unique cells.
	var g := AStarGrid2D.new()
	g.region = Rect2i(0, 0, size, size)
	g.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	g.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	g.update()
	var solid := {}
	for b in buildings:
		for c in footprint_cells(b):
			solid[c] = true
	for y in size:
		for x in size:
			var c := Vector2i(x, y)
			if solid.has(c) or not walk.call(c):
				g.set_point_solid(c, true)
	var seen := {}
	for b in buildings:
		var door: Vector2i = b["door"]
		if not g.is_in_boundsv(door) or not g.is_in_boundsv(hub):
			continue
		var was_d := g.is_point_solid(door)
		var was_h := g.is_point_solid(hub)
		g.set_point_solid(door, false)
		g.set_point_solid(hub, false)
		for c in g.get_id_path(door, hub):
			seen[c] = true
		g.set_point_solid(door, was_d)
		g.set_point_solid(hub, was_h)
	var out: Array[Vector2i] = []
	for c in seen:
		out.append(c)
	out.sort()
	return out

static func paddock(barn: Dictionary, free: Callable) -> Dictionary:
	## A 5x4 fenced paddock beside the barn (east, west, lower east/west, upper east/west, behind): {fence, gate, rect} or {}.
	## The gate gap faces south, toward the village paths.
	var bc: Vector2i = barn["cell"]
	var w := int(barn["w"])
	for origin in [bc + Vector2i(w + 1, -1), bc + Vector2i(-6, -1), bc + Vector2i(w + 1, 2), bc + Vector2i(-6, 2),
			bc + Vector2i(w + 1, -4), bc + Vector2i(-6, -4), bc + Vector2i(0, -5)]:
		var r := Rect2i(origin, Vector2i(5, 4))
		var ok := true
		for y in range(r.position.y, r.end.y):
			for x in range(r.position.x, r.end.x):
				if not free.call(Vector2i(x, y)):
					ok = false
		if not ok:
			continue
		var gate := Vector2i(r.position.x + 2, r.end.y - 1)
		var fence: Array[Vector2i] = []
		for y in range(r.position.y, r.end.y):
			for x in range(r.position.x, r.end.x):
				var c := Vector2i(x, y)
				var edge := x == r.position.x or x == r.end.x - 1 or y == r.position.y or y == r.end.y - 1
				if edge and c != gate:
					fence.append(c)
		return {"fence": fence, "gate": gate, "rect": r}
	return {}
