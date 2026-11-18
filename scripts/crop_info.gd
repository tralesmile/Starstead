class_name CropInfo
extends RefCounted
## Pure hover info for a farm cell: days left, growth fraction, watered state, tooltip text.

static func info(soil: Dictionary, crops: Dictionary, cell: Vector2i) -> Dictionary:
	## {} when the cell is not tilled; otherwise {crop, days_left, total, fraction, ripe, watered}.
	if not soil.has(cell):
		return {}
	var s: Dictionary = soil[cell]
	var out := {"crop": "", "days_left": 0, "total": 0, "fraction": 0.0, "ripe": false, "watered": bool(s.get("watered", false))}
	var id := String(s.get("crop", ""))
	if id == "" or not crops.has(id):
		return out
	var total := maxi(1, int(crops[id].grow_days))
	var age := clampi(int(s.get("age", 0)), 0, total)
	out.crop = id
	out.total = total
	out.days_left = total - age
	out.fraction = float(age) / float(total)
	out.ripe = age >= total
	return out

static func text(i: Dictionary) -> String:
	if i.is_empty():
		return ""
	var wet := "watered" if i.watered else "dry"
	if String(i.crop) == "":
		return "Tilled soil (%s)" % wet
	var name := String(i.crop).capitalize()
	if i.ripe:
		return "%s: ready to harvest" % name
	var d := int(i.days_left)
	return "%s: %d day%s left (%s)" % [name, d, "" if d == 1 else "s", wet]
