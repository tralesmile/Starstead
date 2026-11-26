class_name SaveBoot
extends RefCounted
## Pure launch rules for the save file: when to load it, and what the welcome-back card says.

## A normal launch (no flags) continues the save. Any QA/demo/screenshot flag starts a clean world so
## screens stay reproducible; --continue forces the load, --fresh always skips it.
static func should_load(args: PackedStringArray, exists: bool) -> bool:
	if not exists or "--fresh" in args:
		return false
	return args.is_empty() or "--continue" in args

static func summary(day: int, season: int, money: int) -> String:
	var names := ["Spring", "Summer", "Autumn", "Winter"]
	return "Day %d, %s  -  $%d" % [day, names[posmod(season, 4)], money]

## Keys that differ between two save dictionaries after a JSON round trip (empty = faithful restore).
static func diff_keys(a: Dictionary, b: Dictionary) -> Array:
	var na: Dictionary = JSON.parse_string(JSON.stringify(a))
	var nb: Dictionary = JSON.parse_string(JSON.stringify(b))
	var out: Array = []
	var keys := na.keys()
	for k in nb:
		if not keys.has(k):
			keys.append(k)
	for k in keys:
		if JSON.stringify(_canon(na.get(k))) != JSON.stringify(_canon(nb.get(k))):
			out.append(k)
	return out

## Lists of cells have no meaningful order, so compare them sorted.
static func _canon(v):
	if v is Dictionary:
		var d := {}
		for k in v:
			d[k] = _canon(v[k])
		return d
	if v is Array:
		var items: Array = []
		for e in v:
			items.append(_canon(e))
		if not items.is_empty() and items[0] is Dictionary and items[0].has("x"):
			items.sort_custom(func(p, q): return JSON.stringify(p) < JSON.stringify(q))
		return items
	return v
