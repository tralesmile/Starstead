class_name CityModel
extends RefCounted
## Pure layout of Port Halden (docs/EARTH_MAP.md E3), world cells (homestead chunk = 0..63).
## The city sits where chunks (5,3) (6,3) (5,4) (6,4) meet. It forces land, paints asphalt streets with
## sidewalks and plazas, and lists 12 buildings + street furniture. All buildings face south: the cell
## below the footprint is a sidewalk cell (the door cell).

const RECT := Rect2i(166, -22, 53, 51)          # x 166..218, y -22..28 forced to land
const AVENUE := Rect2i(191, -22, 3, 59)         # N-S avenue x 191..193 down to the main spine road (y ~29..35)
const SIDEWALK_X := [190, 194]
const STREETS := [Rect2i(166, -1, 53, 3), Rect2i(166, -13, 53, 3), Rect2i(166, 12, 53, 3)]  # E-W asphalt
const PLAZAS := [Rect2i(176, 3, 13, 6), Rect2i(196, 3, 13, 6)]
const SPAWN := Vector2i(192, 3)                 # a good place to arrive (demo flag, fast travel later)

static func in_rect(c: Vector2i) -> bool:
	return RECT.has_point(c) or AVENUE.grow_individual(1, 0, 1, 0).has_point(c)

static func is_asphalt(c: Vector2i) -> bool:
	if AVENUE.has_point(c):
		return true
	for s in STREETS:
		if s.has_point(c):
			return true
	return false

static func is_sidewalk(c: Vector2i) -> bool:
	if is_asphalt(c) or not in_rect(c):
		return false
	for s in STREETS:
		if s.grow_individual(0, 1, 0, 1).has_point(c):
			return true
	if c.x in SIDEWALK_X and c.y >= RECT.position.y and c.y <= 36:
		return true
	for p in PLAZAS:
		if p.has_point(c):
			return true
	return false

static func zebra(c: Vector2i) -> int:
	## Pedestrian crossings on asphalt: 1 = bars running north-south (across the avenue, just north of each street),
	## 2 = bars running east-west (across a street, beside the avenue). 0 elsewhere.
	if not is_asphalt(c):
		return 0
	for s in STREETS:
		if AVENUE.has_point(c) and c.y == s.position.y - 1:
			return 1
		if s.has_point(c) and not AVENUE.has_point(c) and (c.x in [188, 189, 195, 196]):
			return 2
	return 0

static func lane(c: Vector2i) -> int:
	## Painted centre line: 1 = east-west dashes (street centre rows), 2 = north-south dashes (avenue centre column), 0 none.
	if not is_asphalt(c):
		return 0
	if c.x == 192:
		for s in STREETS:
			if c.y >= s.position.y and c.y < s.end.y:
				return 0   # no line through the crossings
		return 2
	for s in STREETS:
		if c.y == s.position.y + 1 and not AVENUE.has_point(c):
			return 1
	return 0

static func tile_kind(c: Vector2i) -> String:
	## "asphalt" | "sidewalk" | "" (grass park / land).
	if is_asphalt(c):
		return "asphalt"
	if is_sidewalk(c):
		return "sidewalk"
	return ""

static func _b(id: String, sprite: String, x: int, y: int, w: int, door_px: int, name: String, kind: String) -> Dictionary:
	return {"id": id, "sprite": sprite, "cell": Vector2i(x, y), "w": w, "door": Vector2i(x + door_px / 32, y + 2), "name": name, "door_px": door_px, "kind": kind}

static func buildings() -> Array:
	return [
		_b("city_shop", "shop_building", 168, -4, 4, 64, "General store", "shop"),
		_b("city_police", "police_building", 174, -4, 4, 64, "Police station", "police"),
		_b("city_cafe", "cafe_building", 180, -4, 3, 32, "Cafe", "cafe"),
		_b("city_bank", "bank_building", 185, -4, 5, 64, "Halden Bank", "bank"),
		_b("city_hospital", "hospital_building", 196, -4, 5, 64, "Hospital", "hospital"),
		_b("city_garage", "garage_building", 202, -4, 4, 32, "Garage", "garage"),
		_b("city_apt_a", "apartment_a", 207, -4, 3, 32, "Apartments A", "apartment"),
		_b("city_hall", "town_hall", 184, -16, 5, 64, "Town hall", "hall"),
		_b("city_apt_b", "apartment_b", 197, -16, 3, 32, "Apartments B", "apartment"),
		_b("city_house1", "house", 170, 9, 3, 48, "Townhouse 1", "apartment"),
		_b("city_house2", "house", 178, 9, 3, 48, "Townhouse 2", "apartment"),
		_b("city_house3", "house", 201, 9, 3, 48, "Townhouse 3", "apartment"),
	]

static func props() -> Array:
	## Street furniture: {kind, cell}. Lamps stand on sidewalks (never on the avenue), benches in plazas.
	var out: Array = []
	var x := 170
	while x <= 216:
		if x < 189 or x > 195:
			out.append({"kind": "lamp", "cell": Vector2i(x, 2)})
		x += 8
	for p in [Vector2i(178, 4), Vector2i(186, 4), Vector2i(198, 4), Vector2i(206, 4)]:
		out.append({"kind": "bench", "cell": p})
	out.append({"kind": "fountain", "cell": Vector2i(202, 6)})
	return out

static func building_cells(b: Dictionary) -> Array[Vector2i]:
	var r: Array[Vector2i] = []
	for dy in 2:
		for dx in int(b["w"]):
			r.append(b["cell"] + Vector2i(dx, dy))
	return r

static func kind_of(building_id: String) -> String:
	for b in buildings():
		if b["id"] == building_id:
			return String(b["kind"])
	return ""
