class_name IsleState
extends RefCounted
## Saved Gull Isle progress: which of today's beach finds are taken, and whether the star cairn has been read.

var day := -1
var picked: Array = []   # "x,y" keys taken today
var cairn := false

static func key(c: Vector2i) -> String:
	return "%d,%d" % [c.x, c.y]

func remaining(today: int, spots: Array) -> Array:
	if today != day:
		return spots.duplicate()
	var out: Array = []
	for s in spots:
		if not (key(s["cell"]) in picked):
			out.append(s)
	return out

func pick(today: int, c: Vector2i) -> void:
	if today != day:
		day = today
		picked.clear()
	if not (key(c) in picked):
		picked.append(key(c))

func read_cairn() -> bool:
	## True only the first time (that is when the keepsake is handed over).
	if cairn:
		return false
	cairn = true
	return true

func to_dict() -> Dictionary:
	return {"day": day, "picked": picked.duplicate(), "cairn": cairn}

func from_dict(d: Dictionary) -> void:
	day = int(d.get("day", -1))
	picked = []
	for k in d.get("picked", []):
		picked.append(str(k))
	cairn = bool(d.get("cairn", false))
