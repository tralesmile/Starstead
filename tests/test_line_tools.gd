extends BaseTest

func test_line_cells_follow_facing() -> void:
	check_eq(LineMath.cells(Vector2i(5, 5), PlayerMath.Facing.RIGHT, 3), [Vector2i(5, 5), Vector2i(6, 5), Vector2i(7, 5)])
	check_eq(LineMath.cells(Vector2i(5, 5), PlayerMath.Facing.UP, 2), [Vector2i(5, 5), Vector2i(5, 4)])
	check_eq(LineMath.cells(Vector2i(0, 0), PlayerMath.Facing.DOWN, 0).size(), 1)

func test_can_capacity_from_bag() -> void:
	var inv := Inventory.new(30, {"watering_can_iron": 1})
	var t := {"watering_can_copper": {"capacity": 40}, "watering_can_iron": {"capacity": 60}}
	check_eq(LineMath.capacity_for(20, inv, t), 20)
	inv.add("watering_can_iron")
	check_eq(LineMath.capacity_for(20, inv, t), 60)

func test_set_capacity_keeps_water() -> void:
	var c := WaterCan.new()
	c.level = 5
	c.set_capacity(40)
	check_eq(c.capacity, 40)
	check_eq(c.level, 25)

func test_hoe_and_can_data_and_icons() -> void:
	var items = JSON.parse_string(FileAccess.open("res://data/items.json", FileAccess.READ).get_as_text())
	var icons = JSON.parse_string(FileAccess.open("res://data/item_icons.json", FileAccess.READ).get_as_text())
	for f in ["hoes", "cans"]:
		var d = JSON.parse_string(FileAccess.open("res://data/%s.json" % f, FileAccess.READ).get_as_text())
		for id in d:
			check(items.has(id))
			check(icons.has(id))

func test_hoe_upgrade_power() -> void:
	var inv := Inventory.new(30, {"hoe_copper": 1})
	inv.add("hoe_copper")
	check_eq(ToolUse.axe_power(inv, {"hoe_copper": {"power": 2}}, "hoe"), 2)
	check_eq(ToolUse.axe_power(inv, {"hoe_copper": {"power": 2}}, "watering_can"), 1)
