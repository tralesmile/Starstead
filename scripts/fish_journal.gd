class_name FishJournal
extends RefCounted
## Pure record of caught fish: count and biggest size per species. Size comes from difficulty + roll.

var entries: Dictionary = {}  # id -> {count, best}

static func size_cm(base_difficulty: float, roll: float) -> int:
	## Harder fish are bigger: 10..70 cm band moved by difficulty, roll in 0..1 adds up to 30%.
	return int(round((10.0 + 60.0 * clampf(base_difficulty, 0.0, 1.0)) * (0.85 + 0.45 * clampf(roll, 0.0, 1.0))))

func record(id: String, size: int) -> bool:
	## Returns true if this is a new species or a new personal best.
	var e: Dictionary = entries.get(id, {"count": 0, "best": 0})
	var new_rec: bool = e["count"] == 0 or size > e["best"]
	e["count"] += 1
	e["best"] = maxi(e["best"], size)
	entries[id] = e
	return new_rec

func species_caught() -> int:
	return entries.size()

func summary(table: Dictionary) -> String:
	return "Journal %d/%d species" % [entries.size(), table.size()]

func to_dict() -> Dictionary:
	return entries.duplicate(true)

func from_dict(d: Dictionary) -> void:
	entries = {}
	for k in d:
		entries[k] = {"count": int(d[k].get("count", 0)), "best": int(d[k].get("best", 0))}
