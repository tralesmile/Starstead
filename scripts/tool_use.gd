class_name ToolUse
extends RefCounted
## Pure tool application on a target cell. Returns a short message (empty = nothing happened).

const TOOLS := ["hoe", "watering_can", "turnip_seed", "hand", "axe", "pickaxe", "rod", "club"]

static func held_frame(tool: String) -> int:
	## Frame in assets/sprites/held_tools.png, -1 = nothing in hand (seeds, bare hands).
	return {"hoe": 0, "watering_can": 1, "axe": 2, "pickaxe": 3, "rod": 4, "club": 5}.get(tool, -1)

static func apply(tool: String, cell: Vector2i, farm: FarmModel, inv: Inventory, season: int, gen: WorldGen = null, nodes: ResourceNodes = null, energy: Energy = null, drops = null) -> String:
	if energy != null and not energy.can_use(tool):
		return "Too tired"
	var msg := _apply(tool, cell, farm, inv, season, gen, nodes, drops)
	if msg != "" and energy != null:
		energy.spend(tool)
	return msg

static func _apply(tool: String, cell: Vector2i, farm: FarmModel, inv: Inventory, season: int, gen: WorldGen, nodes: ResourceNodes, drops = null) -> String:
	match tool:
		"axe", "pickaxe":
			if nodes == null:
				return ""
			var r := nodes.hit(cell, tool)
			if r.is_empty():
				return ""
			if r.has("id"):
				_give(inv, drops, r.id, r.n)
				return "Got %d %s" % [r.n, r.id]
			return "Hit"
		"hoe":
			if gen != null and gen.tile_at(cell.x, cell.y) >= WorldGen.PATH:
				return ""  # cannot till paths or water
			return "Tilled" if farm.till(cell) else ""
		"watering_can":
			return "Watered" if farm.water(cell) else ""
		"hand":
			var h := farm.harvest(cell)
			if h.is_empty():
				return ""
			_give(inv, drops, h.id, h.n)
			return "Harvested " + h.id
		_:
			if tool.ends_with("_seed"):
				if inv.count(tool) < 1:
					return "No seeds"
				if farm.plant(cell, tool, season):
					inv.remove(tool, 1)
					return "Planted"
	return ""

## Items go to the bag directly, or into `drops` ([{id, n}]) when the caller wants them lying in the world.
static func _give(inv: Inventory, drops, id: String, n: int) -> void:
	if drops == null:
		inv.add(id, n)
	else:
		drops.append({"id": id, "n": n})
