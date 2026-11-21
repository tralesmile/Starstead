extends RefCounted
class_name AnimalModel
## Pure animal logic: approach/taming progress, tamed state, daily production, riding, save/load.

var animals: Dictionary
var gear_defs: Dictionary
var cfg: Dictionary

func _init(data: Dictionary) -> void:
	animals = data.get("animals", {})
	gear_defs = data.get("gear", {})
	cfg = data.get("tame", {})

func trust_max() -> float:
	return float(cfg.get("trust_max", 100))

# --- approach / taming: progress = {"id": String, "trust": float} ---
func new_approach(id: String) -> Dictionary:
	return {"id": id, "trust": 0.0}

## Feed an item to a wild animal; raises trust (scaled by difficulty) if it is a liked item.
func feed_wild(p: Dictionary, item: String) -> bool:
	var a: Dictionary = animals.get(p["id"], {})
	if a.is_empty() or not (item in a.get("feed", [])):
		return false
	var gain := float(cfg.get("feed_trust", 25)) / maxf(0.1, float(a["tame_difficulty"]))
	p["trust"] = minf(trust_max(), float(p["trust"]) + gain)
	return true

func decay(p: Dictionary, dt: float) -> void:
	p["trust"] = maxf(0.0, float(p["trust"]) - float(cfg.get("decay_per_sec", 2.0)) * dt)

func is_tamed(p: Dictionary) -> bool:
	return float(p["trust"]) >= trust_max()

## Returns the tamed state dict once trust is full, else {}.
func tame(p: Dictionary) -> Dictionary:
	if not is_tamed(p):
		return {}
	return {"id": p["id"], "trust": trust_max(), "hunger": 0.0, "gear": {}}

# --- tamed animals ---
func feed(st: Dictionary, item: String) -> bool:
	var a: Dictionary = animals.get(st["id"], {})
	if not (item in a.get("feed", [])):
		return false
	st["hunger"] = 0.0
	return true

# --- bond (friendship) ---
const BOND_MAX := 100
const PET_GAIN := 4
const FEED_GAIN := 3
const BOND_BONUS_AT := 50   # from here on there is a chance of a double yield

func bond(st: Dictionary) -> int:
	return int(st.get("bond", 0))

const PEN_GAIN := 1   # bond per day for an animal kept inside a closed pen

func pen_bonus(st: Dictionary, enclosed: bool) -> void:
	## Animals told to stay inside a sealed pen (BuildModel.is_enclosed) feel safe: a little extra bond each day.
	if enclosed and bool(st.get("stay", false)):
		st["bond"] = mini(BOND_MAX, bond(st) + PEN_GAIN)

func can_pet(st: Dictionary, day: int) -> bool:
	return int(st.get("pet_day", -1)) != day

func pet(st: Dictionary, day: int) -> bool:
	## One pat a day raises the bond; returns false if already petted today.
	if not can_pet(st, day):
		return false
	st["pet_day"] = day
	st["bond"] = mini(BOND_MAX, bond(st) + PET_GAIN)
	return true

func bond_tier(st: Dictionary) -> String:
	var b := bond(st)
	return "devoted" if b >= 80 else ("friendly" if b >= BOND_BONUS_AT else ("warming up" if b >= 20 else "wary"))

static func bonus_roll(bond_v: int, day: int, salt: int) -> bool:
	## Deterministic per (day, animal): chance of a double yield = (bond-50)/100 above 50 (0..50%).
	if bond_v < BOND_BONUS_AT:
		return false
	var h := absi((day * 73856093) ^ (salt * 19349663)) % 100
	return h < bond_v - BOND_BONUS_AT

func is_fed(st: Dictionary) -> bool:
	return float(st["hunger"]) < float(cfg.get("hunger_max", 100))

## Advance one day: hunger rises; fed animals (before the rise) produce. Returns {item: count}.
func day_tick(st: Dictionary, day: int = 0, salt: int = 0) -> Dictionary:
	var out := {}
	var a: Dictionary = animals.get(st["id"], {})
	var res: Dictionary = a.get("resource", {})
	var fed := is_fed(st)
	st["hunger"] = minf(float(cfg.get("hunger_max", 100)), float(st["hunger"]) + float(cfg.get("hunger_per_day", 50)))
	var days := int(res.get("days", 0))
	var item := String(res.get("item", ""))
	if fed and item != "" and days > 0:
		st["days_fed"] = int(st.get("days_fed", 0)) + 1
		if int(st["days_fed"]) >= days:
			st["days_fed"] = 0
			out[item] = 2 if bonus_roll(bond(st), day, salt) else 1
	return out

# --- gear / riding ---
func equip(st: Dictionary, item: String) -> bool:
	var g: Dictionary = gear_defs.get(item, {})
	if g.is_empty():
		return false
	var slot := String(g["slot"])
	if not (slot in animals.get(st["id"], {}).get("gear_slots", [])):
		return false
	st["gear"][slot] = item
	return true

func unequip(st: Dictionary, slot: String) -> String:
	var it := String(st["gear"].get(slot, ""))
	st["gear"].erase(slot)
	return it

func gear_total(st: Dictionary, stat: String) -> float:
	var t := 0.0
	for slot in st["gear"]:
		t += float(gear_defs.get(st["gear"][slot], {}).get(stat, 0.0))
	return t

func is_rideable(st: Dictionary) -> bool:
	return bool(animals.get(st["id"], {}).get("rideable", false))

## Ride speed; 0 if not rideable.
func ride_speed(st: Dictionary) -> float:
	var a: Dictionary = animals.get(st["id"], {})
	if not bool(a.get("rideable", false)):
		return 0.0
	return float(a["wild_speed"]) * float(a["ride_speed_mult"]) * (1.0 + gear_total(st, "speed"))

# --- save / load ---
func serialize(sts: Array) -> String:
	return JSON.stringify(sts)

func deserialize(s: String) -> Array:
	var out := []
	var j := JSON.new()
	if j.parse(s) != OK:
		return out
	var v = j.data
	if v is Array:
		for st in v:
			if st is Dictionary and st.has("id"):
				st["trust"] = float(st.get("trust", 0))
				st["hunger"] = float(st.get("hunger", 0))
				st["gear"] = st.get("gear", {})
				st["bond"] = int(st.get("bond", 0))
				out.append(st)
	return out

# --- in-play helpers (pure) ---
const RIDE_REF := 135.0  # px/s: ride speed that equals the player's sprint (90 * 1.5)

## Multiplier applied to the player's speed while riding (0 ride speed = no change).
static func ride_mult(ride_spd: float) -> float:
	return 1.0 if ride_spd <= 0.0 else clampf(ride_spd / RIDE_REF, 1.0, 2.5)

## Wild animals bolt when you come close unless they already trust you (trust 0..1).
static func asleep(hour: float, wild: bool) -> bool:
	## Penned and tamed animals bed down between 21:00 and 05:00 (wild ones keep roaming).
	return not wild and (hour >= 21.0 or hour < 5.0)

static func should_flee(dist: float, trust_frac: float, scare: float = 1.0) -> bool:
	return dist < lerpf(90.0, 30.0, clampf(trust_frac, 0.0, 1.0)) * scare and trust_frac < 0.6

static func flee_dir(animal: Vector2, threat: Vector2) -> Vector2:
	var d := animal - threat
	return Vector2.DOWN if d.length() < 0.001 else d.normalized()

## Tamed animals trail the owner at a loose distance; returns the step toward `owner` (zero when close).
static func follow_step(pos: Vector2, owner: Vector2, spd: float, dt: float, gap: float = 36.0) -> Vector2:
	var d := owner - pos
	if d.length() <= gap:
		return Vector2.ZERO
	return d.normalized() * minf(spd * dt, d.length() - gap)

const PEN_RADIUS := 56.0

## Where a parked (staying) animal wanders next: a short hop that never leaves PEN_RADIUS around its home spot.
static func pen_target(home: Vector2, pos: Vector2, angle: float, dist: float) -> Vector2:
	var t := pos + Vector2(cos(angle), sin(angle)) * dist
	var off := t - home
	if off.length() > PEN_RADIUS:
		t = home + off.normalized() * PEN_RADIUS
	return t

## First gear item the player carries that fits an empty slot of this animal ("" if none). have = {item_id: count}.
func next_gear(st: Dictionary, have: Dictionary) -> String:
	var ids := gear_defs.keys()
	ids.sort()
	for id in ids:
		if int(have.get(id, 0)) < 1:
			continue
		var slot := String(gear_defs[id]["slot"])
		if slot in animals.get(st["id"], {}).get("gear_slots", []) and not st["gear"].has(slot):
			return id
	return ""

static func wild_ok(c: Vector2i) -> bool:
	## Wild animals keep out of paved places (Port Halden streets, the circuit, the harbour quay).
	return not CityModel.in_rect(c) and not CircuitModel.in_rect(c) and not HarbourModel.is_quay(c) and not VanceYard.in_rect(c)
