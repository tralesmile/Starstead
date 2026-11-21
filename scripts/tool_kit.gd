class_name ToolKit
extends RefCounted
## Which hotbar tools you own. A new game starts with the hoe, the axe, seeds and bare hands; the rest is crafted from wood (C).
## Old saves without a tool list own everything.

const STARTER := ["hoe", "axe", "hand"]
const ALWAYS := ["turnip_seed", "sprinkler", "crab_pot", "fertiliser", "hand"]   # seeds and placeables are gated by the bag count instead

static func start() -> Array:
	return STARTER.duplicate()

static func owns(owned: Array, tool: String) -> bool:
	return tool in owned or tool in ALWAYS or tool.ends_with("_seed") or tool == ""

static func craft(owned: Array, recipe: Dictionary, bag: Inventory) -> String:
	## "" on success (wood spent, tool added); otherwise the reason.
	var tool := String(recipe["makes"])
	if bool(recipe.get("item", false)):   # repeatable item recipe (fertiliser): goes into the bag
		if int(recipe.get("limit", 0)) > 0 and bag.count(tool) >= int(recipe["limit"]):
			return "You already have it"
		if not CookModel.can_cook(bag, recipe):
			return "Missing materials"
		for id in recipe["needs"]:
			bag.remove(id, int(recipe["needs"][id]))
		bag.add(tool, int(recipe.get("count", 1)))
		return ""
	if tool in owned:
		return "You already have it"
	if not CookModel.can_cook(bag, recipe):
		return "Missing materials"
	for id in recipe["needs"]:
		bag.remove(id, int(recipe["needs"][id]))
	owned.append(tool)
	return ""

static func all_tools() -> Array:
	return ToolUse.TOOLS.duplicate()
