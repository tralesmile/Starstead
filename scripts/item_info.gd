class_name ItemInfo
extends RefCounted
## Pure item presentation helpers: rarity border colours (Stardew-style bronze/silver/gold) and plural names.

const BORDER := {
	"bronze": Color(0.80, 0.50, 0.25),
	"silver": Color(0.78, 0.84, 0.90),
	"gold": Color(1.0, 0.82, 0.2),
}

static func border_color(rarity: String) -> Color:
	return BORDER.get(rarity, Color(0, 0, 0, 0))

static func has_border(rarity: String) -> bool:
	return BORDER.has(rarity)

static func display_name(def: Dictionary, n: int) -> String:
	## "Turnip" -> "3 Turnips"; names already ending in s (Seeds) stay; "Egg" -> "Eggs"; "Wool" stays.
	var nm := String(def.get("name", "?"))
	if n <= 1:
		return nm
	if nm.ends_with("s") or nm.ends_with("Wool") or nm.ends_with("Milk") or nm.ends_with("Armour"):
		return "%d %s" % [n, nm]
	if nm.ends_with("ch") or nm.ends_with("sh") or nm.ends_with("x"):
		return "%d %ses" % [n, nm]
	return "%d %ss" % [n, nm]
