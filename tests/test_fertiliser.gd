extends BaseTest

func _farm() -> FarmModel:
	return FarmModel.new(DataDB.load_json("crops"))

func test_fertilise_lasts_one_harvest() -> void:
	var f := _farm()
	var c := Vector2i(3, 3)
	check(not f.fertilise(c), "needs tilled soil")
	f.till(c)
	check(f.fertilise(c))
	check(not f.fertilise(c), "once is enough")
	check_eq(f.fert_bonus(c), FarmModel.FERT_BONUS)
	check(f.plant(c, "turnip_seed", 0))
	f.soil[c].age = 99
	check(not f.harvest(c).is_empty())
	check_eq(f.fert_bonus(c), FarmModel.FERT_BONUS, "still counts for this harvest's quality roll")
	check(f.plant(c, "turnip_seed", 0))
	check_eq(f.fert_bonus(c), 0.0, "used up at the next planting")

func test_fertiliser_saves() -> void:
	var f := _farm()
	f.till(Vector2i(1, 1))
	f.fertilise(Vector2i(1, 1))
	var g := _farm()
	g.from_array(f.to_array())
	check_eq(g.fert_bonus(Vector2i(1, 1)), FarmModel.FERT_BONUS)
	var old := _farm()
	old.from_array([{"x": 2, "y": 2, "watered": false, "crop": "", "age": 0}])
	check_eq(old.fert_bonus(Vector2i(2, 2)), 0.0, "old saves load")

func test_fertiliser_raises_gold() -> void:
	var gold_plain := 0
	var gold_fert := 0
	for i in 1000:
		var r := i / 1000.0
		if QualityMath.roll(2, r) == 2:
			gold_plain += 1
		if QualityMath.roll(2, r, FarmModel.FERT_BONUS) == 2:
			gold_fert += 1
	check(gold_fert > gold_plain + 100)

func test_craft_item_recipe() -> void:
	var bag := Inventory.new()
	var owned: Array = ToolKit.start()
	var r: Dictionary = DataDB.load_json("crafting")["fertiliser"]
	check_eq(ToolKit.craft(owned, r, bag), "Missing materials")
	bag.add("hay", 4)
	bag.add("fibre", 2)
	check_eq(ToolKit.craft(owned, r, bag), "")
	check_eq(ToolKit.craft(owned, r, bag), "", "repeatable")
	check_eq(bag.count("fertiliser"), 6)
	check_eq(bag.count("hay"), 0)
	check(not ("fertiliser" in owned), "not a tool")

func test_tool_use_fertilises() -> void:
	var f := _farm()
	var bag := Inventory.new()
	f.till(Vector2i(0, 0))
	check_eq(ToolUse.apply("fertiliser", Vector2i(0, 0), f, bag, 0), "No fertiliser (craft it: C)")
	bag.add("fertiliser", 1)
	check_eq(ToolUse.apply("fertiliser", Vector2i(0, 0), f, bag, 0), "Fertilised")
	check_eq(bag.count("fertiliser"), 0)
