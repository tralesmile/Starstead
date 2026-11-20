class_name Dialogue
extends RefCounted
## Pure dialogue picker: lines live in data/npcs.json under npc["lines"] keyed by activity
## ("default" fallback). Rotates through the list so repeated talks vary.

static func pick(npc: Dictionary, activity: String, counter: int) -> String:
	var lines: Dictionary = npc.get("lines", {})
	var arr: Array = lines.get(activity, lines.get("default", []))
	if arr.is_empty():
		return "..."
	return str(arr[absi(counter) % arr.size()])

static func wrap(text: String, width: int) -> PackedStringArray:
	## Greedy word wrap by character count (pixel font is roughly fixed width at our size).
	var out := PackedStringArray()
	var cur := ""
	for w in text.split(" "):
		if cur != "" and cur.length() + 1 + w.length() > width:
			out.append(cur)
			cur = w
		else:
			cur = w if cur == "" else cur + " " + w
	if cur != "":
		out.append(cur)
	return out

static func reveal(text: String, t: float, cps: float = 40.0) -> String:
	return text.substr(0, clampi(int(t * cps), 0, text.length()))

static func gate_gossip(gates: Dictionary, done: Dictionary, counter: int) -> String:
	## Every other talk, villagers mention a road the story still keeps closed (data/gates.json "gossip").
	## Earliest gates first (sorted by id is stable; city/harbour/circuit share the first step). "" when all open.
	if counter % 2 != 0:
		return ""
	var ids: Array = gates.keys()
	ids.sort()
	var open_lines: Array = []
	for rid in ids:
		if StoryGate.lock_message(gates, str(rid), done) != "" and (gates[rid] as Dictionary).has("gossip"):
			open_lines.append(str(gates[rid]["gossip"]))
	if open_lines.is_empty():
		return ""
	return str(open_lines[(counter / 2) % open_lines.size()])
