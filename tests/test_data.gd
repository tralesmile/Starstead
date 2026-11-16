extends BaseTest

func test_items_valid() -> void:
	var items = DataDB.load_json("items")
	check(items is Dictionary and items.size() > 0)
	for id in items:
		check(items[id].has("name") and int(items[id].price) > 0, id)

func test_crops_reference_items() -> void:
	var items = DataDB.load_json("items")
	var crops = DataDB.load_json("crops")
	for id in crops:
		check(items.has(id), "crop item " + id)
		check(items.has(crops[id].seed), "seed " + crops[id].seed)
		check(int(crops[id].grow_days) > 0)
		# economy sanity: harvest must sell above seed cost
		check(int(items[id].price) > int(items[crops[id].seed].price), "profit " + id)

func test_inputs_registered() -> void:
	var s = load("res://scripts/input_setup.gd").new()
	s.register()
	for a in ["move_up", "move_down", "move_left", "move_right", "interact", "use_tool", "inventory", "pause"]:
		check(InputMap.has_action(a), a)
	s.free()
