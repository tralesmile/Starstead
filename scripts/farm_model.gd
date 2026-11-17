class_name FarmModel
extends RefCounted
## Pure farm state: tilled soil, watering, crops growing per day tick. Cells are Vector2i.
## soil[cell] = {"watered": bool, "crop": String or "", "age": int}

var soil: Dictionary = {}
var weeds: Dictionary = {}  # cell -> variant 0..2 (only on fallow tilled soil)
var crops: Dictionary = {}  # crops.json: crop_id -> {seed, grow_days, season, yield}

func _init(crop_data: Dictionary = {}) -> void:
	crops = crop_data

func till(cell: Vector2i) -> bool:
	if soil.has(cell):
		return false
	soil[cell] = {"watered": false, "crop": "", "age": 0}
	return true

func crop_for_seed(seed_id: String) -> String:
	for id in crops:
		if crops[id].seed == seed_id:
			return id
	return ""

func plant(cell: Vector2i, seed_id: String, season: int) -> bool:
	if weeds.has(cell):
		return false  # clear the weed first
	var id := crop_for_seed(seed_id)
	if id == "" or not soil.has(cell) or soil[cell].crop != "":
		return false
	var ok := false
	for x in crops[id].season:  # JSON numbers are floats; compare as int
		if int(x) == season:
			ok = true
	if not ok:
		return false
	soil[cell].crop = id
	soil[cell].age = 0
	return true

func water(cell: Vector2i) -> bool:
	if not soil.has(cell):
		return false
	soil[cell].watered = true
	return true

func rain_water() -> void:
	## Rain soaks every tilled cell (called at day end when it rained).
	for cell in soil:
		soil[cell].watered = true

func is_ripe(cell: Vector2i) -> bool:
	if not soil.has(cell) or soil[cell].crop == "":
		return false
	return soil[cell].age >= int(crops[soil[cell].crop].grow_days)

func harvest(cell: Vector2i) -> Dictionary:
	## Returns {id, n} or {} if nothing ripe. Soil stays tilled.
	if not is_ripe(cell):
		return {}
	var id: String = soil[cell].crop
	soil[cell].crop = ""
	soil[cell].age = 0
	return {"id": id, "n": int(crops[id].yield)}

const WEED_CHANCE := 0.18
const WEED_CAP_FRACTION := 0.5   # never more than half the fields at once

static func weed_roll(cell: Vector2i, day: int) -> float:
	## Deterministic 0..1 per (cell, day): same save, same weeds.
	var h := (cell.x * 73856093) ^ (cell.y * 19349663) ^ (day * 83492791)
	return float(absi(h) % 10000) / 10000.0

func spawn_weeds(day: int) -> int:
	## Fallow tilled soil (no crop) may sprout a weed overnight. Returns how many appeared.
	var made := 0
	for cell in soil:
		if soil[cell].crop != "" or weeds.has(cell):
			continue
		if weeds.size() >= int(ceil(float(soil.size()) * WEED_CAP_FRACTION)):
			break
		if weed_roll(cell, day) < WEED_CHANCE:
			weeds[cell] = int(weed_roll(cell, day + 1000) * 3.0) % 3
			made += 1
	return made

func cut_weed(cell: Vector2i) -> bool:
	return weeds.erase(cell)

func next_day() -> void:
	## Watered crops grow one day; everything dries out.
	for cell in soil:
		var s = soil[cell]
		if s.crop != "" and s.watered:
			s.age += 1
		s.watered = false

func to_array() -> Array:
	var out := []
	for c in soil:
		out.append({"x": c.x, "y": c.y, "watered": soil[c].watered, "crop": soil[c].crop, "age": soil[c].age})
	return out

func weeds_to_array() -> Array:
	var out := []
	for c in weeds:
		out.append({"x": c.x, "y": c.y, "v": weeds[c]})
	return out

func weeds_from_array(a: Array) -> void:
	weeds = {}
	for e in a:
		weeds[Vector2i(int(e.x), int(e.y))] = int(e.v)

func from_array(a: Array) -> void:
	soil = {}
	weeds = {}
	for e in a:
		soil[Vector2i(int(e.x), int(e.y))] = {"watered": bool(e.watered), "crop": str(e.crop), "age": int(e.age)}

## Growth frame 0..frames-1 for a crop of `age` days out of `total` (last frame = ripe, only when age >= total).
static func stage(age: int, total: int, frames: int = 5) -> int:
	if total <= 0 or age >= total:
		return frames - 1
	return clampi(int(float(age) / float(total) * float(frames - 1)), 0, frames - 2)
