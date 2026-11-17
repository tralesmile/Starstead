extends BaseTest

func test_starter_axe_power_one() -> void:
	check_eq(ToolUse.axe_power(Inventory.new(), {"axe_iron": {"power": 3}}), 1)

func test_best_axe_wins_and_chops_faster() -> void:
	var inv := Inventory.new(30, {"axe_copper": 1, "axe_iron": 1})
	var axes := {"axe_copper": {"power": 2}, "axe_iron": {"power": 3}}
	inv.add("axe_copper")
	check_eq(ToolUse.axe_power(inv, axes), 2)
	inv.add("axe_iron")
	check_eq(ToolUse.axe_power(inv, axes), 3)

func test_axe_data_and_icons_exist() -> void:
	var axes: Dictionary = DataDB.load_json("axes") if false else {}
	var f := FileAccess.open("res://data/axes.json", FileAccess.READ)
	var d = JSON.parse_string(f.get_as_text())
	for id in d:
		check(JSON.parse_string(FileAccess.open("res://data/items.json", FileAccess.READ).get_as_text()).has(id))
		check(JSON.parse_string(FileAccess.open("res://data/item_icons.json", FileAccess.READ).get_as_text()).has(id))

func test_upgrades_only_apply_to_their_own_tool() -> void:
	var inv := Inventory.new(30, {"pickaxe_iron": 1})
	inv.add("pickaxe_iron")
	var t := {"axe_iron": {"power": 3}, "pickaxe_iron": {"power": 3}}
	check_eq(ToolUse.axe_power(inv, t, "axe"), 1)
	check_eq(ToolUse.axe_power(inv, t, "pickaxe"), 3)
