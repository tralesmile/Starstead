class_name StoryGate
extends RefCounted
## Story-first start (owner 2026-11-18): the world opens up region by region as story steps are done.
## data/gates.json maps a region id to {needs: story step id, msg}. Pure, tested.

static func load_gates() -> Dictionary:
	var d: Variant = DataDB.load_json("gates")
	return d if d is Dictionary else {}

static func lock_message(gates: Dictionary, region_id: String, done: Dictionary) -> String:
	## "" when the region is open, otherwise the "road closed" text.
	if not gates.has(region_id):
		return ""
	var g: Dictionary = gates[region_id]
	if done.has(str(g.get("needs", ""))):
		return ""
	return str(g.get("msg", "Not open yet."))

static func bypass(args: PackedStringArray) -> bool:
	## Demo / screenshot flags teleport into any region: they must not bounce off the gates.
	if "--gated" in args:
		return false   # screenshot of the gates with --at=
	for a in args:
		if a == "--ungate" or a.begins_with("--at=") or a.contains("-demo") or a.begins_with("--hour="):
			return true
	return false

static func open_regions(gates: Dictionary, regions: Array, done: Dictionary) -> Array:
	var out := []
	for r in regions:
		if lock_message(gates, str(r), done) == "":
			out.append(str(r))
	return out

static func bounce_velocity(vel: Vector2, from_safe: Vector2, pos: Vector2) -> Vector2:
	## Pushed back toward the last safe spot at a fraction of the speed (reads as hitting a barrier).
	var dir := (from_safe - pos).normalized()
	return dir * minf(vel.length() * 0.3, 60.0)

static func spots(roads: RoadNet, regions: Array, gates: Dictionary) -> Array:
	## Barricade spots: road cells inside a gated region that touch a cell of an ungated region.
	## Each spot is {cell, region}. Deterministic (sorted by region then cell).
	var out := []
	var ids: Array = gates.keys()
	ids.sort()
	var seen := {}
	for rid in ids:
		for r in regions:
			if str(r["id"]) != rid:
				continue
			for rect in r.get("rects", []):
				for cy in range(int(rect[1]), int(rect[3]) + 1):
					for cx in range(int(rect[0]), int(rect[2]) + 1):
						var ch := Vector2i(cx, cy)
						var org := ChunkGrid.origin_cell(ch)
						var keys: Array = roads.road_cells(ch).keys()
						keys.sort()
						for lc in keys:
							var c: Vector2i = org + (lc as Vector2i)
							if seen.has(c):
								continue
							for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
								var n: Vector2i = c + d
								var nr := ChunkGrid.region_of(ChunkGrid.chunk_of_cell(n), regions)
								if str(nr["id"]) != rid and not gates.has(str(nr["id"])):
									seen[c] = true
									out.append({"cell": c, "region": rid})
									break
	return out

## Stateful keeper: remembers the last position in an open region and says when to bounce.
class Keeper extends RefCounted:
	var gates: Dictionary = {}
	var safe: Variant = null     # Vector2 of the last spot in an open region
	var cooldown := 0.0
	var enabled := true

	func _init(g: Dictionary = {}, on: bool = true) -> void:
		gates = g
		enabled = on

	func step(pos: Vector2, region_id: String, done: Dictionary, delta: float) -> Dictionary:
		## {bounce, to, msg}: bounce=true means move the mover back to `to` and show msg (rate limited).
		cooldown = maxf(cooldown - delta, 0.0)
		var msg := StoryGate.lock_message(gates, region_id, done) if enabled else ""
		if msg == "":
			safe = pos
			return {"bounce": false}
		if safe == null:
			return {"bounce": false}   # old save inside a locked region: let them out on their own
		var show := ""
		if cooldown <= 0.0:
			show = msg
			cooldown = 3.0
		return {"bounce": true, "to": safe, "msg": show}
