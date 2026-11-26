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

func total_caught() -> int:
	var n := 0
	for id in entries:
		n += int(entries[id].count)
	return n

func summary(table: Dictionary) -> String:
	return "Journal %d/%d species" % [entries.size(), table.size()]

func to_dict() -> Dictionary:
	return entries.duplicate(true)

func from_dict(d: Dictionary) -> void:
	entries = {}
	for k in d:
		entries[k] = {"count": int(d[k].get("count", 0)), "best": int(d[k].get("best", 0))}

static func rows(table: Dictionary, entries: Dictionary) -> Array:
	## One row per species for the journal screen, cheapest first: {id, name, caught, count, best, depth, seasons}.
	## Uncaught species keep their name hidden ("???") but still show where to look (depth + seasons).
	var out: Array = []
	for id in table:
		var e: Dictionary = entries.get(id, {})
		var caught := int(e.get("count", 0)) > 0
		out.append({"id": id, "name": String(table[id].name) if caught else "???", "caught": caught, "count": int(e.get("count", 0)),
			"best": int(e.get("best", 0)), "depth": String(table[id].depth), "seasons": season_text(table[id].seasons), "price": int(table[id].price)})
	out.sort_custom(func(a, b): return a["price"] < b["price"])
	return out

## Journal screen layout (640x360): two columns so the species list always fits.
const PANEL := Rect2(18, 20, 604, 316)
const ROW_H := 32.0

static func cell_rect(i: int, n: int) -> Rect2:
	var per := (n + 1) / 2
	return Rect2(PANEL.position + Vector2(8 + (i / per) * 298.0, 32 + (i % per) * ROW_H), Vector2(290, ROW_H - 3.0))

static func season_text(seasons: Array) -> String:
	var names := ["Spr", "Sum", "Aut", "Win"]
	if seasons.size() >= 4:
		return "all year"
	var parts: Array = []
	for s in seasons:
		parts.append(names[int(s) % 4])
	return "/".join(parts)
