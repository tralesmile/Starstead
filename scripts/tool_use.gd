class_name ToolUse
extends RefCounted
## Pure tool application on a target cell. Returns a short message (empty = nothing happened).

const TOOLS := ["hoe", "watering_can", "turnip_seed", "hand", "axe", "pickaxe"]

static func apply(tool: String, cell: Vector2i, farm: FarmModel, inv: Inventory, season: int, gen: WorldGen = null, nodes: ResourceNodes = null, energy: Energy = null) -> String:
	if energy != null and not energy.can_use(tool):
		return "Too tired"
	var msg := _apply(tool, cell, farm, inv, season, gen, nodes)
	if msg != "" and energy != null:
		energy.spend(tool)
	return msg

static func _apply(tool: String, cell: Vector2i, farm: FarmModel, inv: Inventory, season: int, gen: WorldGen, nodes: ResourceNodes) -> String:
	match tool:
		"axe", "pickaxe":
			if nodes == null:
				return ""
			var r := nodes.hit(cell, tool)
			if r.is_empty():
				return ""
			if r.has("id"):
				inv.add(r.id, r.n)
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
			inv.add(h.id, h.n)
			return "Harvested " + h.id
		_:
			if tool.ends_with("_seed"):
				if inv.count(tool) < 1:
					return "No seeds"
				if farm.plant(cell, tool, season):
					inv.remove(tool, 1)
					return "Planted"
	return ""
