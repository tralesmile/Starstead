extends BaseTest

func test_hoe_plant_water_harvest() -> void:
	var farm := FarmModel.new(DataDB.load_json("crops"))
	var inv := Inventory.new(10)
	inv.add("turnip_seed", 2)
	var c := Vector2i(5, 5)
	check_eq(ToolUse.apply("turnip_seed", c, farm, inv, 0), "", "cannot plant before hoeing")
	check_eq(ToolUse.apply("hoe", c, farm, inv, 0), "Tilled")
	check_eq(ToolUse.apply("hoe", c, farm, inv, 0), "", "already tilled")
	check_eq(ToolUse.apply("turnip_seed", c, farm, inv, 0), "Planted")
	check_eq(inv.count("turnip_seed"), 1)
	for i in 4:
		ToolUse.apply("watering_can", c, farm, inv, 0)
		farm.next_day()
	check_eq(ToolUse.apply("hand", c, farm, inv, 0), "Harvested turnip")
	check_eq(inv.count("turnip"), 1)

func test_no_seeds_and_blocked_tiles() -> void:
	var farm := FarmModel.new(DataDB.load_json("crops"))
	var inv := Inventory.new(10)
	farm.till(Vector2i(1, 1))
	check_eq(ToolUse.apply("turnip_seed", Vector2i(1, 1), farm, inv, 0), "No seeds")
	var gen := WorldGen.new(1)
	check_eq(ToolUse.apply("hoe", Vector2i(32, 32 + 0), farm, inv, 0, gen) == "" , false if gen.tile_at(32, 32) <= 5 else true)
	var wp := Vector2i(-1, -1)  # outside = deep water
	check_eq(ToolUse.apply("hoe", wp, farm, inv, 0, gen), "")
