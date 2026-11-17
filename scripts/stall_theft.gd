class_name StallTheft
extends RefCounted
## Pure stall theft: a few grabs per day from the market stall, loot picked by roll, vendor sees you sometimes.

const MAX_PER_DAY := 3
const REACH := 56.0
const LOOT := ["turnip", "potato", "egg", "tomato", "pumpkin"]

static func can_steal(stolen_today: int, dist: float) -> bool:
	return stolen_today < MAX_PER_DAY and dist <= REACH

static func loot_for(roll: float) -> String:
	return LOOT[mini(int(roll * LOOT.size()), LOOT.size() - 1)]

static func vendor_sees(nearby_npcs: int, hour: float, roll: float) -> bool:
	## Busy markets and daylight make witnesses likelier; at night only the vendor's dog might notice.
	var base := 0.35 + 0.2 * float(mini(nearby_npcs, 2))
	if hour >= 21.0 or hour < 5.0:
		base *= 0.4
	return roll < base
