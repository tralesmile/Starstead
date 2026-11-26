class_name WorldHints
extends RefCounted
## Gathers what is in front of the player and asks HintModel what to say. Kept out of main.gd.

static var _items: Dictionary = {}

static func _name(id: String) -> String:
	if _items.is_empty():
		_items = DataDB.load_json("items")
	return String(_items.get(id, {}).get("name", id)).to_lower()

static func text(m) -> String:
	var ctx := {"held": m.hotbar.current()}
	var p: Vector2 = m.player.position
	# 1) an item lying close by
	var best := 70.0
	for d in m.drops_view.drops:
		var dist := (d["node"] as Node2D).position.distance_to(p)
		if dist < best:
			best = dist
			ctx["drop_name"] = _name(String(d["id"]))
			ctx["bag_full"] = not m.drops_view._room(d["id"])
	if ctx.has("drop_name"):
		return HintModel.for_context(ctx)
	var cell: Vector2i = m._target_cell()
	var nodes: ResourceNodes = GameState.nodes
	if nodes.nodes.has(cell):
		var n: Dictionary = nodes.nodes[cell]
		ctx["node_kind"] = n.kind
		ctx["node_hp"] = n.hp
		ctx["stump_days"] = n.stump_days
		return HintModel.for_context(ctx)
	var own := Vector2i(floori(p.x / 32.0), floori(p.y / 32.0))
	var farm: FarmModel = GameState.farm
	for c in [cell, own]:
		if farm.is_ripe(c):
			ctx["ripe_name"] = String(farm.soil[c].crop).replace("_", " ")
			return HintModel.for_context(ctx)
	if farm.soil.has(cell):
		var s: Dictionary = farm.soil[cell]
		if farm.weeds.has(cell):
			ctx["weed"] = true
		elif s.crop != "":
			ctx["crop_name"] = String(s.crop).replace("_", " ")
			ctx["days_left"] = maxi(1, int(farm.crops[s.crop].grow_days) - int(s.age))
			ctx["watered"] = bool(s.watered)
		else:
			ctx["tilled"] = true
		return HintModel.for_context(ctx)
	if farm.weeds.has(cell):
		ctx["weed"] = true
		return HintModel.for_context(ctx)
	if m._water_cell_ahead(2) != Vector2i(-1, -1):
		ctx["water"] = true
		ctx["has_rod"] = "rod" in GameState.tools_owned
	return HintModel.for_context(ctx)
