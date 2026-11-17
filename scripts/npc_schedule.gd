class_name NpcSchedule
extends RefCounted
## Pure NPC routine helpers. Schedule entries: {from_hour, to_hour, place, activity}.
## An entry with from_hour > to_hour wraps midnight. Place "home" means npc.home.

static func _covers(e: Dictionary, h: float) -> bool:
	var f := float(e.get("from_hour", 0.0))
	var t := float(e.get("to_hour", 0.0))
	if f < t:
		return h >= f and h < t
	if f > t:
		return h >= f or h < t
	return true # f == t: whole day

static func current_entry(npc: Dictionary, hour: float) -> Dictionary:
	var h := fposmod(hour, 24.0)
	for e in npc.get("schedule", []):
		if _covers(e, h):
			return e
	return {}

static func _to_cell(v) -> Vector2i:
	if v is Vector2i:
		return v
	if v is Vector2:
		return Vector2i(int(v.x), int(v.y))
	if v is Array and v.size() >= 2:
		return Vector2i(int(v[0]), int(v[1]))
	return Vector2i.ZERO

static func target_cell(npc: Dictionary, hour: float, places: Dictionary) -> Vector2i:
	var home := _to_cell(npc.get("home", [0, 0]))
	var e := current_entry(npc, hour)
	if e.is_empty():
		return home
	var p := str(e.get("place", "home"))
	if p == "home" or not places.has(p):
		return home
	return _to_cell(places[p])

static func is_sleeping(npc: Dictionary, hour: float) -> bool:
	return str(current_entry(npc, hour).get("activity", "")) == "sleep"

static func step_toward(pos: Vector2, target: Vector2, speed: float, dt: float) -> Vector2:
	var d := target - pos
	var step := maxf(speed * dt, 0.0)
	var dist := d.length()
	if dist <= step or dist == 0.0:
		return target
	return pos + d / dist * step
