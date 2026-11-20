class_name FarmModel
extends RefCounted
## Pure farm state: tilled soil, watering, crops growing per day tick. Cells are Vector2i.
## soil[cell] = {"watered": bool, "crop": String or "", "age": int}

var soil: Dictionary = {}
var weeds: Dictionary = {}  # cell -> variant 0..2 (only on fallow tilled soil)
var sprinklers: Dictionary = {}  # cell -> true; waters the 8 tiles around it each night
var crops: Dictionary = {}  # crops.json: crop_id -> {seed, grow_days, season, yield}

func _init(crop_data: Dictionary = {}) -> void:
	crops = crop_data

func crops_planted() -> int:
	var n := 0
	for c in soil:
		if String(soil[c]["crop"]) != "":
			n += 1
	return n

func till(cell: Vector2i) -> bool:
	if soil.has(cell):
		return false
	soil[cell] = {"watered": false, "crop": "", "age": 0}
	return true

const FERT_BONUS := 0.12   # extra gold chance at harvest (QualityMath.roll fert)

func fertilise(cell: Vector2i) -> bool:
	## Fertiliser on tilled soil lasts until the next crop there is harvested.
	if not soil.has(cell) or bool(soil[cell].get("fert", false)):
		return false
	soil[cell]["fert"] = true
	soil[cell]["fert_spent"] = false
	return true

func fert_bonus(cell: Vector2i) -> float:
	return FERT_BONUS if soil.has(cell) and bool(soil[cell].get("fert", false)) else 0.0

func crop_for_seed(seed_id: String) -> String:
	for id in crops:
		if crops[id].seed == seed_id:
			return id
	return ""

func in_season(crop_id: String, season: int) -> bool:
	for x in crops[crop_id].season:  # JSON numbers are floats; compare as int
		if int(x) == season:
			return true
	return false

func plant(cell: Vector2i, seed_id: String, season: int) -> bool:
	if weeds.has(cell):
		return false  # clear the weed first
	var id := crop_for_seed(seed_id)
	if id == "" or not soil.has(cell) or soil[cell].crop != "":
		return false
	if not in_season(id, season):
		return false
	soil[cell].crop = id
	soil[cell].age = 0
	if bool(soil[cell].get("fert_spent", false)):
		soil[cell]["fert"] = false
		soil[cell]["fert_spent"] = false
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
	## Returns {id, n} or {} if nothing ripe. Soil stays tilled. Crops with "regrow" (tomato) stay planted and ripen again.
	if not is_ripe(cell):
		return {}
	var id: String = soil[cell].crop
	var regrow := int(crops[id].get("regrow", 0))
	if regrow > 0:
		soil[cell].age = maxi(0, int(crops[id].grow_days) - regrow)   # vines keep growing: ripe again after `regrow` watered days
	else:
		soil[cell].crop = ""
		soil[cell].age = 0
	if bool(soil[cell].get("fert", false)):
		soil[cell]["fert_spent"] = true   # still counts for this harvest's quality roll; gone at the next planting
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

func place_sprinkler(cell: Vector2i) -> bool:
	if sprinklers.has(cell) or soil.has(cell) or weeds.has(cell):
		return false
	sprinklers[cell] = true
	return true

func pick_up_sprinkler(cell: Vector2i) -> bool:
	return sprinklers.erase(cell)

func sprinkle() -> int:
	## Night: every sprinkler waters the tilled cells in the 3x3 around it. Returns how many cells got water.
	var n := 0
	for c in sprinklers:
		for dx in range(-1, 2):
			for dy in range(-1, 2):
				var t: Vector2i = c + Vector2i(dx, dy)
				if soil.has(t) and not soil[t].watered:
					soil[t].watered = true
					n += 1
	return n

func sprinklers_to_array() -> Array:
	var out := []
	for c in sprinklers:
		out.append({"x": c.x, "y": c.y})
	return out

func sprinklers_from_array(a: Array) -> void:
	sprinklers = {}
	for e in a:
		sprinklers[Vector2i(int(e.x), int(e.y))] = true

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
		out.append({"x": c.x, "y": c.y, "watered": soil[c].watered, "crop": soil[c].crop, "age": soil[c].age,
			"fert": bool(soil[c].get("fert", false)), "fs": bool(soil[c].get("fert_spent", false))})
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
		soil[Vector2i(int(e.x), int(e.y))] = {"watered": bool(e.watered), "crop": str(e.crop), "age": int(e.age),
			"fert": bool(e.get("fert", false)), "fert_spent": bool(e.get("fs", false))}

## Growth frame 0..frames-1 for a crop of `age` days out of `total` (last frame = ripe, only when age >= total).
static func stage(age: int, total: int, frames: int = 5) -> int:
	if total <= 0 or age >= total:
		return frames - 1
	return clampi(int(float(age) / float(total) * float(frames - 1)), 0, frames - 2)
