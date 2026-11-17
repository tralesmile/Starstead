extends BaseTest

func _inv() -> Inventory:
	return Inventory.new(12, {"wood": 10, "stone": 10})

func test_swap_moves_and_swaps() -> void:
	var inv := _inv()
	inv.slots[0] = {"id": "wood", "n": 3}
	inv.slots[5] = {"id": "stone", "n": 2}
	inv.swap(0, 5)
	check_eq(inv.slots[0].id, "stone")
	check_eq(inv.slots[5].id, "wood")
	inv.swap(5, 7)
	check(inv.slots[5] == null)
	check_eq(inv.slots[7].n, 3)

func test_swap_merges_same_item_up_to_limit() -> void:
	var inv := _inv()
	inv.slots[0] = {"id": "wood", "n": 8}
	inv.slots[1] = {"id": "wood", "n": 6}
	inv.swap(0, 1)
	check_eq(inv.slots[1].n, 10)
	check_eq(inv.slots[0].n, 4)

func test_trash_and_sort() -> void:
	var inv := _inv()
	inv.slots[3] = {"id": "stone", "n": 4}
	inv.slots[9] = {"id": "wood", "n": 7}
	inv.slots[10] = {"id": "wood", "n": 6}
	var t = inv.trash(3)
	check_eq(t.id, "stone")
	check(inv.slots[3] == null)
	inv.sort()
	check_eq(inv.slots[0].id, "wood")
	check_eq(inv.slots[0].n, 10)
	check_eq(inv.slots[1].n, 3)
	check(inv.slots[2] == null)
	check_eq(inv.count("wood"), 13)

func test_slot_at() -> void:
	var o := Vector2(100, 50)
	check_eq(Inventory.slot_at(Vector2(101, 51), o, 24.0, 10, 30), 0)
	check_eq(Inventory.slot_at(Vector2(100 + 24 * 3 + 2, 50 + 24 * 1 + 2), o, 24.0, 10, 30), 13)
	check_eq(Inventory.slot_at(Vector2(90, 60), o, 24.0, 10, 30), -1)
	check_eq(Inventory.slot_at(Vector2(100 + 24 * 10 + 1, 60), o, 24.0, 10, 30), -1)
	check_eq(Inventory.slot_at(Vector2(110, 50 + 24 * 3 + 1), o, 24.0, 10, 30), -1)
