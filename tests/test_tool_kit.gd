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
	for id in recipes:
		check(String(recipes[id]["makes"]) in ToolUse.TOOLS, id)
		check(not (String(recipes[id]["makes"]) in ToolKit.STARTER))
