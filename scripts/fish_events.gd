class_name FishEvents
extends RefCounted
## Legendary fish sightings (data/fish_events.json): every few days one uncaught legendary is seen. Its shadow
## circles a marked spot; casting beside it during its hours gives a real chance of the bite, any rain, any depth.
## Deterministic from the day, so it needs no save data. Pure.

## The fish sighted today, or "". Candidates are uncaught legendaries in season.
static func for_day(cfg: Dictionary, table: Dictionary, day: int, season: int, caught: Array) -> String:
	var every := int(cfg.get("every", 5))
	if day < int(cfg.get("first_day", 8)) or day % every != int(cfg.get("offset", 3)):
		return ""
	var ids: Array = []
	for id in cfg.get("events", {}):
		if not table.has(id) or id in caught:
			continue
		for s in table[id].seasons:
			if int(s) == season:
				ids.append(id)
				break
	if ids.is_empty():
		return ""
	ids.sort()
	return String(ids[(day / every) % ids.size()])

static func in_hours(fish: Dictionary, hour: float) -> bool:
	var h: Array = fish.get("hours", [0, 24])
	return hour >= float(h[0]) and hour < float(h[1])

## True when a cast at `cell` reaches the shadow at `spot` at the right hour.
static func hits(cfg: Dictionary, fish: Dictionary, cell: Vector2i, spot: Vector2i, hour: float) -> bool:
	return spot.x >= 0 and in_hours(fish, hour) and Vector2(cell - spot).length() <= float(cfg.get("radius", 4))

## The water cell nearest `from` that is open water (sdf below `deep`), searched ring by ring; the deepest
## on the first ring that has any. Vector2i(-1, -1) when none within max_r.
static func find_spot(from: Vector2i, sdf: Callable, max_r: int = 40, deep: float = -1.5, min_r: int = 0) -> Vector2i:
	for r in range(min_r, max_r + 1):
		var best := Vector2i(-1, -1)
		var depth := deep
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if maxi(absi(dx), absi(dy)) != r:
					continue
				var c := from + Vector2i(dx, dy)
				var d := float(sdf.call(c))
				if d < depth:
					depth = d
					best = c
		if best.x >= 0:
			return best
	return Vector2i(-1, -1)

## Offset in px of the circling shadow at time t: a slow figure of eight.
static func swim(t: float) -> Vector2:
	return Vector2(sin(t * 0.55) * 26.0, sin(t * 1.1) * 9.0)
