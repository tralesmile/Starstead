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
