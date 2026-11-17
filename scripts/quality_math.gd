class_name QualityMath
extends RefCounted
## Crop quality (Stardew-style normal/silver/gold). Quality items are separate ids ("turnip_silver") that share the base icon.

const SUFFIX := ["", "_silver", "_gold"]

static func roll(farming_level: int, r: float, fert: float = 0.0) -> int:
	## 0 normal, 1 silver, 2 gold. r in 0..1. Gold: 2%/level (+fert); silver: 8% + 3%/level.
	var gold := 0.02 * float(farming_level) + fert
	var silver := 0.08 + 0.03 * float(farming_level)
	if r < gold:
		return 2
	if r < gold + silver:
		return 1
	return 0

static func variant(id: String, q: int) -> String:
	return id + SUFFIX[clampi(q, 0, 2)]

static func base_id(id: String) -> String:
	for s in ["_silver", "_gold"]:
		if id.ends_with(s):
			return id.trim_suffix(s)
	return id

static func count_any(inv: Inventory, id: String) -> int:
	return inv.count(id) + inv.count(id + "_silver") + inv.count(id + "_gold")

static func remove_any(inv: Inventory, id: String, n: int) -> bool:
	## Takes plain ones first so the good ones are kept for selling.
	if count_any(inv, id) < n:
		return false
	for s in SUFFIX:
		var take := mini(n, inv.count(id + s))
		if take > 0:
			inv.remove(id + s, take)
			n -= take
	return true
