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
