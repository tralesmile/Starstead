class_name RobberyModel
extends RefCounted
## Pure house-robbery model: locks, seeded loot, lockpicking, noise meter, wake-up, NPC memory, save/load.
## No autoloads. Randomness comes from a RandomNumberGenerator passed in (seeded by the caller for tests).

var cfg: Dictionary
var houses: Dictionary = {}   ## id -> state dict
var noise: float = 0.0

func _init(data: Dictionary = {}) -> void:
	cfg = data if not data.is_empty() else DataDB.load_json("loot")

static func _hash(s: String) -> int:
	var h := 5381
	for i in s.length():
		h = (h * 33 + s.unicode_at(i)) & 0x7fffffff
	return h

func house(id: String) -> Dictionary:
	## Creates (deterministically, seeded by id) on first access.
	if not houses.has(id):
		houses[id] = _seed_house(id)
	return houses[id]

func _seed_house(id: String) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = _hash(id)
	var lk: Dictionary = cfg["lock"]
	var locked := rng.randf() < float(lk["initial_locked_chance"])
	var level := 0
	if locked:
		level = rng.randi_range(1, int(lk["initial_level_max"]))
	var cnt: Array = cfg["loot_count"]
	var n := rng.randi_range(int(cnt[0]), int(cnt[1]))
	var ids: Array = cfg["items"].keys()
	ids.sort()
	var total := 0
	for k in ids:
		total += int(cfg["items"][k]["weight"])
	var loot: Array = []
	for i in n:
		var roll := rng.randi_range(1, total)
		for k in ids:
			roll -= int(cfg["items"][k]["weight"])
			if roll <= 0:
				loot.append(k)
				break
	return {"locked": locked, "lock_level": level, "loot": loot, "looted": false,
		"robberies": 0, "dog": false, "grudge": false}

func pick_chance(lock_level: int, skill: int) -> float:
	var lk: Dictionary = cfg["lock"]
	var c := float(lk["base_chance"]) - float(lk["per_level"]) * lock_level + float(lk["per_skill"]) * skill
	return clampf(c, float(lk["min"]), float(lk["max"]))

func attempt_pick(id: String, skill: int, rng: RandomNumberGenerator) -> bool:
	## Unlocks on success. Both outcomes make noise (failure more).
	var h := house(id)
	if not h["locked"]:
		return true
	var ok := rng.randf() < pick_chance(int(h["lock_level"]), skill)
	add_noise(float(cfg["noise"]["pick_burst" if ok else "fail_burst"]) * _noise_mult(id))
	if ok:
		h["locked"] = false
	return ok

func _noise_mult(id: String) -> float:
	return float(cfg["memory"]["dog_noise_mult"]) if house(id)["dog"] else 1.0

func add_noise(amount: float) -> void:
	noise = clampf(noise + amount, 0.0, float(cfg["noise"]["max"]))

func tick(id: String, dt: float, looting: bool, running: bool) -> void:
	## Noise rises while looting/running, otherwise decays.
	var n: Dictionary = cfg["noise"]
	var rate := 0.0
	if looting:
		rate += float(n["loot_rate"])
	if running:
		rate += float(n["run_rate"])
	if rate > 0.0:
		add_noise(rate * dt * _noise_mult(id))
	else:
		noise = maxf(noise - float(n["decay"]) * dt, 0.0)

func residents_awake() -> bool:
	return noise > float(cfg["noise"]["wake_threshold"])

func loot_item(id: String) -> String:
	## Takes the next loot item (and its noise burst); "" when empty/locked. Marks looted when emptied.
	var h := house(id)
	if h["locked"] or h["loot"].is_empty():
		return ""
	var item: String = h["loot"].pop_back()
	add_noise(float(cfg["items"][item]["noise"]) * _noise_mult(id))
	if h["loot"].is_empty():
		h["looted"] = true
	return item

func loot_value(item: String) -> int:
	return int(cfg["items"].get(item, {}).get("value", 0))

func remaining_value(id: String) -> int:
	var t := 0
	for it in house(id)["loot"]:
		t += loot_value(it)
	return t

func heat_after(heat: float, kind: String = "robbery") -> float:
	## Witnessed only if residents woke (and the house has a resident view of you).
	return WantedMath.add(heat, kind, residents_awake())

func finish_robbery(id: String, rng: RandomNumberGenerator) -> void:
	## NPC memory: tighter lock, maybe a dog after repeated robberies, resident holds a grudge.
	var h := house(id)
	h["robberies"] += 1
	h["lock_level"] = mini(int(h["lock_level"]) + 1, int(cfg["lock"]["max_level"]))
	h["locked"] = true
	h["grudge"] = true
	if int(h["robberies"]) >= int(cfg["memory"]["dog_after_robberies"]) and not h["dog"]:
		h["dog"] = rng.randf() < float(cfg["memory"]["dog_chance"])

func serialize() -> Dictionary:
	return {"noise": noise, "houses": houses.duplicate(true)}

func deserialize(d: Dictionary) -> void:
	noise = float(d.get("noise", 0.0))
	houses = {}
	var src: Dictionary = d.get("houses", {})
	for id in src:
		var s: Dictionary = src[id]
		houses[id] = {"locked": bool(s.get("locked", false)), "lock_level": int(s.get("lock_level", 0)),
			"loot": Array(s.get("loot", [])), "looted": bool(s.get("looted", false)),
			"robberies": int(s.get("robberies", 0)), "dog": bool(s.get("dog", false)), "grudge": bool(s.get("grudge", false))}
