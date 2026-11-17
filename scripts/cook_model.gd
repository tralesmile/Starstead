class_name CookModel
extends RefCounted
## Pure cooking and eating: recipes turn crops/eggs/fish into dishes that restore energy.

static func can_cook(inv: Inventory, recipe: Dictionary) -> bool:
	for id in recipe["needs"]:
		if inv.count(id) < int(recipe["needs"][id]):
			return false
	return true

static func cook(inv: Inventory, recipe: Dictionary) -> bool:
	## Consumes the ingredients and adds the dish; if the bag is full nothing is consumed.
	if not can_cook(inv, recipe):
		return false
	var probe := Inventory.new(inv.slots.size(), inv.stack_limits)
	probe.slots = inv.to_array()
	for id in recipe["needs"]:
		probe.remove(id, int(recipe["needs"][id]))
	if probe.add(String(recipe["makes"]), 1) > 0:
		return false
	inv.slots = probe.slots
	return true

static func eat(inv: Inventory, items: Dictionary, energy: Energy, id: String) -> int:
	## Eats one `id`: restores its energy value (capped at MAX). Returns the energy gained, or -1 if not edible/not carried.
	var e := int(items.get(id, {}).get("energy", 0))
	if e <= 0 or inv.count(id) < 1:
		return -1
	var before := energy.value
	energy.value = minf(float(Energy.MAX), energy.value + float(e))
	inv.remove(id, 1)
	return int(round(energy.value - before))

static func ingredient_text(inv: Inventory, recipe: Dictionary) -> String:
	var parts: Array = []
	for id in recipe["needs"]:
		parts.append("%d/%d %s" % [mini(inv.count(id), int(recipe["needs"][id])), int(recipe["needs"][id]), id.replace("_", " ")])
	return ", ".join(parts)
