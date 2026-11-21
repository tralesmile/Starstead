extends BaseTest

func test_start_and_owns() -> void:
	var o := ToolKit.start()
	check(ToolKit.owns(o, "hoe") and ToolKit.owns(o, "axe") and ToolKit.owns(o, "hand"), "starter tools")
	check(not ToolKit.owns(o, "rod") and not ToolKit.owns(o, "watering_can"), "rod and can must be crafted")
	check(ToolKit.owns(o, "tomato_seed") and ToolKit.owns(o, "sprinkler"), "seeds and placeables are bag-gated")

func test_craft_spends_wood() -> void:
	var bag := Inventory.new(10, {})
	var o := ToolKit.start()
	var r := {"name": "Rod", "needs": {"wood": 4}, "makes": "rod"}
	check_eq(ToolKit.craft(o, r, bag), "Missing materials")
	bag.add("wood", 5)
	check_eq(ToolKit.craft(o, r, bag), "")
	check_eq(bag.count("wood"), 1)
	check(ToolKit.owns(o, "rod"))
	check_eq(ToolKit.craft(o, r, bag), "You already have it")

func test_every_recipe_makes_a_hotbar_tool() -> void:
	var recipes: Dictionary = DataDB.load_json("crafting")
	var items: Dictionary = DataDB.load_json("items")
	for id in recipes:
		if bool(recipes[id].get("item", false)):   # item recipes (fertiliser) make a real bag item instead
			check(items.has(String(recipes[id]["makes"])), id)
			check(int(recipes[id].get("count", 1)) >= 1, id)
			continue
		check(String(recipes[id]["makes"]) in ToolUse.TOOLS, id)
		check(not (String(recipes[id]["makes"]) in ToolKit.STARTER))

func test_leather_boots_recipe_and_speed() -> void:
	var rec: Dictionary = DataDB.load_json("crafting")["leather_boots"]
	var bag := Inventory.new()
	var owned: Array = []
	check_eq(ToolKit.craft(owned, rec, bag), "Missing materials")
	bag.add("hide", 4)
	bag.add("fibre", 2)
	check_eq(ToolKit.craft(owned, rec, bag), "")
	check_eq(bag.count("leather_boots"), 1)
	bag.add("hide", 4)
	bag.add("fibre", 2)
	check_eq(ToolKit.craft(owned, rec, bag), "You already have it", "one pair only")
	check_eq(bag.count("hide"), 4, "materials kept")
	check(PlayerMath.boots_mult(1) > 1.0 and PlayerMath.boots_mult(0) == 1.0)
