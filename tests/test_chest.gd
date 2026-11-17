extends BaseTest

func test_quick_move_whole_stack() -> void:
	var a := Inventory.new(5, {"wood": 99})
	var b := Inventory.new(5, {"wood": 99})
	a.add("wood", 40)
	check_eq(ChestModel.quick_move(a, b, 0), 40)
	check_eq(a.count("wood"), 0)
	check_eq(b.count("wood"), 40)

func test_quick_move_merges_and_keeps_leftover_when_full() -> void:
	var a := Inventory.new(3, {"wood": 99})
	var b := Inventory.new(1, {"wood": 99})
	a.add("wood", 60)
	b.add("wood", 80)
	check_eq(ChestModel.quick_move(a, b, 0), 19)
	check_eq(a.count("wood"), 41)
	check_eq(b.count("wood"), 99)

func test_move_all_of_item() -> void:
	var a := Inventory.new(4, {"egg": 5})
	var b := Inventory.new(4, {"egg": 5})
	a.add("egg", 12)
	check_eq(ChestModel.move_all_of(a, b, "egg"), 12)
	check_eq(a.count("egg"), 0)
	check_eq(ChestModel.quick_move(a, b, 3), 0)
