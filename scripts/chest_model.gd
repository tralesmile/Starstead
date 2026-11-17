class_name ChestModel
extends RefCounted
## Pure helpers for moving stacks between the bag and a storage chest.

static func quick_move(from: Inventory, to: Inventory, idx: int) -> int:
	## Move the whole stack in slot idx of `from` into `to` (merging, then free slots). Returns how many moved;
	## whatever does not fit stays in the source slot.
	if idx < 0 or idx >= from.slots.size() or from.slots[idx] == null:
		return 0
	var s: Dictionary = from.slots[idx]
	var left := to.add(String(s["id"]), int(s["n"]))
	var moved := int(s["n"]) - left
	if left <= 0:
		from.slots[idx] = null
	else:
		s["n"] = left
	return moved

static func move_all_of(from: Inventory, to: Inventory, id: String) -> int:
	## Shift-click style: every stack of one item type.
	var total := 0
	for i in from.slots.size():
		if from.slots[i] != null and from.slots[i]["id"] == id:
			total += quick_move(from, to, i)
	return total
