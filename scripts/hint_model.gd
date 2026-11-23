class_name HintModel
extends RefCounted
## Pure "what can I do here?" text for the prompt line: trees, stumps, rocks, drops, crops, soil, weeds and water.
## The caller fills a context dictionary; empty string = nothing worth saying.

const NAMES := {"axe": "Axe", "pickaxe": "Pickaxe", "hoe": "Hoe", "scythe": "Scythe", "rod": "Fishing Rod", "watering_can": "Watering Can"}

## Hotbar key label for a tool (1-9, 0 for the tenth slot), "" if unknown.
static func key_of(tool: String) -> String:
	var i := ToolUse.TOOLS.find(tool)
	if i < 0:
		return ""
	return str((i + 1) % 10)

static func equip(tool: String, then: String) -> String:
	return "Equip the %s (key %s) %s" % [NAMES.get(tool, tool), key_of(tool), then]

## ctx keys (all optional): held, node_kind ("tree"/"rock"), node_hp, stump_days, drop_name, bag_full,
## ripe_name, crop_name, days_left, watered, tilled, weed, water.
static func for_context(ctx: Dictionary) -> String:
	var held := String(ctx.get("held", ""))
	if ctx.has("drop_name"):
		if bool(ctx.get("bag_full", false)):
			return "Bag full: free a slot (Tab) to pick up %s" % ctx["drop_name"]
		return "Walk over the %s to pick it up" % ctx["drop_name"]
	var kind := String(ctx.get("node_kind", ""))
	if kind != "":
		var stump := int(ctx.get("stump_days", 0))
		if stump > 0:
			return "Chopped stump: a new tree grows in %d day%s" % [stump, "" if stump == 1 else "s"]
		var tool := "axe" if kind == "tree" else "pickaxe"
		var what := "tree" if kind == "tree" else "rock"
		var yields := "logs" if kind == "tree" else "stone"
		if held != tool:
			return equip(tool, "to break this %s for %s" % [what, yields])
		var hp := int(ctx.get("node_hp", 0))
		return "F / Click: hit the %s (%d hit%s left) - %s drop and fly to you" % [what, hp, "" if hp == 1 else "s", yields]
	if ctx.has("ripe_name"):
		return "E: Harvest %s" % ctx["ripe_name"]
	if ctx.has("crop_name"):
		var d := int(ctx.get("days_left", 0))
		var s := "%s: ripe in %d day%s" % [ctx["crop_name"], d, "" if d == 1 else "s"]
		if not bool(ctx.get("watered", true)):
			s += " - water it (Watering Can, key %s)" % key_of("watering_can")
		return s
	if bool(ctx.get("weed", false)):
		return "F / Click with the Scythe (key %s) to cut the weeds" % key_of("scythe") if held != "scythe" else "F / Click: cut the weeds"
	if bool(ctx.get("tilled", false)):
		return "Tilled soil: pick a seed packet (key 3) and click to plant"
	if bool(ctx.get("water", false)):
		return "Hold F with the Fishing Rod (key %s) to cast a line" % key_of("rod") if held != "rod" else "Hold F to cast, release to throw"
	return ""
