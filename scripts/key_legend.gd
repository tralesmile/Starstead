class_name KeyLegend
extends RefCounted
## Pure content of the small bottom-right "keys" legend: what the main keys do right now (on foot, driving, riding, indoors).
## F1 toggles it. Key labels follow the player's bindings (KeyBinds).

const MODES := ["foot", "car", "mount", "indoors"]

static func mode_for(driving: bool, riding: bool, indoors: bool) -> String:
	if driving:
		return "car"
	if riding:
		return "mount"
	if indoors:
		return "indoors"
	return "foot"

## Rows of [key, action] for a mode (the same few keys always come first so the eye learns them).
static func rows(mode: String) -> Array:
	var move := KeyBinds.move_label()
	var use := KeyBinds.label("interact")
	var tool := KeyBinds.label("use_tool")
	var map := [KeyBinds.label("map"), "Map"]
	match mode:
		"car":
			return [[move, "Steer"], [tool, "Handbrake"], [use, "Get out"], ["L", "Race laps"], map, ["F1", "Hide keys"]]
		"mount":
			return [[move, "Ride"], [KeyBinds.label("sprint"), "Gallop"], [use, "Dismount"], map, ["F1", "Hide keys"]]
		"indoors":
			return [[move, "Walk"], [KeyBinds.label("sneak"), "Sneak"], [use, "Use / talk"], [KeyBinds.label("inventory"), "Bag"], ["F1", "Hide keys"]]
		_:
			return [[move, "Walk"], [KeyBinds.label("sprint"), "Sprint"], [KeyBinds.label("sneak"), "Sneak"], [use, "Use / talk"], [tool + "/Click", "Tool"], ["1-0", "Hotbar"], [KeyBinds.label("inventory"), "Bag"], [KeyBinds.label("craft"), "Craft"], [KeyBinds.label("journal"), "Fish log"], [KeyBinds.label("quests"), "Quests"], map, ["+/-", "Zoom"], ["Esc", "Pause"], ["F1", "Hide keys"]]

## Width in px of the widest row at a given char width (for the panel).
static func panel_width(mode: String, char_w: float = 5.0) -> float:
	var w := 0
	for r in rows(mode):
		w = maxi(w, String(r[0]).length() + String(r[1]).length() + 2)
	return float(w) * char_w + 14.0
