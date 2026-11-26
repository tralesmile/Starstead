extends BaseTest

func test_tree_hints_depend_on_the_tool_in_hand() -> void:
	var t := HintModel.for_context({"held": "hand", "node_kind": "tree", "node_hp": 5})
	check(t.contains("Equip the Axe (key 5)") and t.contains("logs"), t)
	var u := HintModel.for_context({"held": "axe", "node_kind": "tree", "node_hp": 2})
	check(u.contains("hit the tree (2 hits left)"), u)
	check(HintModel.for_context({"held": "axe", "node_kind": "tree", "node_hp": 1}).contains("1 hit left"), "singular")

func test_stump_rock_drop_and_bag() -> void:
	check(HintModel.for_context({"node_kind": "tree", "stump_days": 3}).contains("grows in 3 days"), "stump")
	check(HintModel.for_context({"held": "hand", "node_kind": "rock", "node_hp": 3}).contains("Pickaxe (key 6)"), "rock tool")
	check(HintModel.for_context({"drop_name": "wood"}).contains("Walk over the wood"), "drop")
	check(HintModel.for_context({"drop_name": "wood", "bag_full": true}).contains("Bag full"), "full bag")

func test_farm_and_water_hints() -> void:
	check(HintModel.for_context({"ripe_name": "turnip"}) == "E: Harvest turnip", "harvest")
	check(HintModel.for_context({"crop_name": "tomato", "days_left": 2, "watered": false}).contains("water it"), "water nudge")
	check(HintModel.for_context({"tilled": true}).contains("plant"), "tilled")
	check(HintModel.for_context({"weed": true, "held": "hand"}).contains("Scythe (key 9)"), "weeds")
	check(HintModel.for_context({"water": true, "held": "hand"}).contains("Fishing Rod (key 7)"), "water")
	check(HintModel.for_context({}) == "", "nothing to say")

func test_no_rod_means_craft_one_first() -> void:
	var s := HintModel.for_context({"water": true, "held": "hoe", "has_rod": false})
	check(s.contains("craft") and s.contains("(C)"), s)
	check(not s.contains("key 7"), s)
