class_name KeyLegend
extends RefCounted
## Pure content of the small bottom-right "keys" legend: what the main keys do right now (on foot, driving, riding, indoors).
## F1 toggles it. Rebinding later only needs the key labels in one place.

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
	match mode:
		"car":
			return [["WASD", "Steer"], ["F", "Handbrake"], ["E", "Get out"], ["L", "Race laps"], ["M", "Map"], ["F1", "Hide keys"]]
		"mount":
			return [["WASD", "Ride"], ["Shift", "Gallop"], ["E", "Dismount"], ["M", "Map"], ["F1", "Hide keys"]]
		"indoors":
			return [["WASD", "Walk"], ["Ctrl", "Sneak"], ["E", "Use / talk"], ["Tab", "Bag"], ["F1", "Hide keys"]]
		_:
			return [["WASD", "Walk"], ["Shift", "Sprint"], ["E", "Use / talk"], ["F", "Tool"], ["1-0", "Hotbar"], ["Tab", "Bag"], ["C", "Craft"], ["K", "Quests"], ["M", "Map"], ["F1", "Hide keys"]]

## Width in px of the widest row at a given char width (for the panel).
static func panel_width(mode: String, char_w: float = 5.0) -> float:
	var w := 0
	for r in rows(mode):
		w = maxi(w, String(r[0]).length() + String(r[1]).length() + 2)
	return float(w) * char_w + 14.0
