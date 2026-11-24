class_name ReputationModel
extends RefCounted
## Pure two-reputation rules (DESIGN differentiator 4): honest tiers cheapen shops and fines, street tiers
## raise fence pay, cool heat faster, cut bribes and add lockpicking skill. Holding both (>= 30) is a "double life".

static var _cfg: Dictionary = {}

static func cfg() -> Dictionary:
	if _cfg.is_empty():
		_cfg = DataDB.load_json("reputation")
	return _cfg

static func tier(rep: int, c: Dictionary = {}) -> int:
	var th: Array = (c if not c.is_empty() else cfg())["thresholds"]
	var t := 0
	for i in th.size():
		if rep >= int(th[i]):
			t = i
	return t

static func _pick(c: Dictionary, side: String, key: String, rep: int) -> float:
	var arr: Array = c[side][key]
	return float(arr[clampi(tier(rep, c), 0, arr.size() - 1)])

static func honest_title(rep: int) -> String:
	return String(cfg()["honest_titles"][tier(rep)])

static func street_title(rep: int) -> String:
	return String(cfg()["street_titles"][tier(rep)])

static func buy_mult(honest: int) -> float:
	return _pick(cfg(), "honest", "buy_mult", honest)

static func sell_mult(honest: int) -> float:
	return _pick(cfg(), "honest", "sell_mult", honest)

static func fine_mult(honest: int) -> float:
	return _pick(cfg(), "honest", "fine_mult", honest)

static func fence_mult(street: int) -> float:
	return _pick(cfg(), "street", "fence_mult", street)

static func bribe_mult(street: int) -> float:
	return _pick(cfg(), "street", "bribe_mult", street)

static func pick_bonus(street: int) -> int:
	return int(_pick(cfg(), "street", "pick_bonus", street))

static func double_life(honest: int, street: int) -> bool:
	var m := int(cfg()["double_life_min"])
	return honest >= m and street >= m

static func decay_mult(honest: int, street: int) -> float:
	var m := _pick(cfg(), "street", "decay_mult", street)
	if double_life(honest, street):
		m *= float(cfg()["double_life_decay"])
	return m

static func dealer_open(street: int) -> bool:
	return tier(street) >= int(cfg()["dealer_min_tier"])

static func bribe_cost(stars: int, street: int) -> int:
	return int(round(float(cfg()["bribe_per_star"]) * stars * bribe_mult(street)))

static func apply_fine(fine: int, honest: int) -> int:
	return int(round(fine * fine_mult(honest)))

static func skill(street: int, has_picks: bool) -> int:
	## Lockpicking/safe skill level from street rep, tier bonus and a carried lockpick set.
	return street / 10 + pick_bonus(street) + (int(cfg()["lockpick_bonus"]) if has_picks else 0)

static func summary(honest: int, street: int) -> String:
	var s := "Honest: %s (%d)   Street: %s (%d)" % [honest_title(honest), honest, street_title(street), street]
	if double_life(honest, street):
		s += "   Double life"
	return s
