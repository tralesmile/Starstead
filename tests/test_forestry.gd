extends BaseTest

func _model() -> Forestry:
	return Forestry.new(DataDB.load_json("forestry"))

func test_drops_by_kind_and_roll() -> void:
	var f := _model()
	var d := f.fell_drops("oak", 0.0, 0.0)
	check_eq(d[0].id, "acorn")
	check_eq(d[1].id, "sap")
	check_eq(f.fell_drops("pine", 0.0, 0.99), [{"id": "pine_cone", "n": 1}])
	check(f.fell_drops("oak", 0.99, 0.99).is_empty(), "unlucky tree sheds nothing extra")
	check_eq(int(f.fell_drops("oak", 0.99, 0.4)[0].n), 2, "sometimes two sap")

func test_plant_rules() -> void:
	var f := _model()
	check(Forestry.can_plant(0, 3.0, false))
	check(not Forestry.can_plant(WorldGen.PATH, 3.0, false), "not on paths")
	check(not Forestry.can_plant(0, 0.5, false), "not at the water's edge")
	check(not Forestry.can_plant(0, 3.0, true), "not on something")
	var c := Vector2i(3, 3)
	check(not f.plant(c, "wood"), "wood is not a seed")
	check(f.plant(c, "acorn"))
	check(not f.plant(c, "pine_cone"), "cell taken")

func test_sapling_grows_into_choppable_tree() -> void:
	var f := _model()
	var n := ResourceNodes.new()
	var c := Vector2i(3, 3)
	f.plant(c, "pine_cone")
	check_eq(Forestry.stage(0, f.grow_days()), 0)
	check_eq(Forestry.stage(f.grow_days() - 1, f.grow_days()), 2)
	for i in f.grow_days() - 1:
		check_eq(f.next_day(n), 0)
	check(not n.is_solid(c), "sapling does not block")
	check_eq(f.next_day(n), 1)
	check_eq(String(f.grown[c]), "pine")
	check(n.is_solid(c) and not f.saplings.has(c))
	for i in 4:
		n.hit(c, "axe")
	check_eq(n.hit(c, "axe").id, "wood")

func test_blocked_sapling_waits() -> void:
	var f := _model()
	var n := ResourceNodes.new()
	var c := Vector2i(1, 1)
	f.plant(c, "acorn")
	for i in f.grow_days() + 2:
		f.next_day(n, func(_x: Vector2i) -> bool: return true)
	check(f.saplings.has(c) and not n.nodes.has(c))
	check_eq(f.next_day(n), 1)

func test_save_roundtrip_keeps_saplings_trees_and_damage() -> void:
	var f := _model()
	var n := ResourceNodes.new()
	f.plant(Vector2i(1, 1), "acorn")
	f.next_day(n)
	f.grown[Vector2i(2, 2)] = "oak"
	f.register(n)
	n.hit(Vector2i(2, 2), "axe", 2)
	var d = JSON.parse_string(JSON.stringify({"f": f.to_dict(), "n": n.to_array()}))
	var f2 := _model()
	var n2 := ResourceNodes.new()
	n2.from_array(d.n)
	f2.from_dict(d.f)
	f2.register(n2)
	check_eq(int(f2.saplings[Vector2i(1, 1)].age), 1)
	check_eq(String(f2.grown[Vector2i(2, 2)]), "oak")
	check_eq(int(n2.nodes[Vector2i(2, 2)].hp), 3)

func test_big_stump_needs_copper_axe() -> void:
	var n := ResourceNodes.new()
	var c := Vector2i(4, 4)
	n.add("big_stump", c)
	check(n.hit(c, "axe", 1).has("blocked"), "starter axe bounces off")
	check_eq(int(n.nodes[c].hp), ResourceNodes.HP["big_stump"], "no damage")
	var got := {}
	for i in 4:
		got = n.hit(c, "axe", 2)
	check_eq(got.id, "hardwood")
	check(not n.is_solid(c))
	var n2 := ResourceNodes.new()
	n2.from_array(JSON.parse_string(JSON.stringify(n.to_array())))
	n2.add("big_stump", c)
	check_eq(int(n2.nodes[c].stump_days), 7, "longer regrow survives a save")
	for i in 7:
		n2.next_day()
	check(n2.is_solid(c))

func test_too_tough_costs_no_energy_and_copper_axe_works() -> void:
	var n := ResourceNodes.new()
	var c := Vector2i(4, 4)
	n.add("big_stump", c)
	var bag := Inventory.new()
	var e := Energy.new()
	var before := e.value
	var axes: Dictionary = DataDB.load_json("axes")
	check_eq(ToolUse.apply("axe", c, FarmModel.new(), bag, 0, null, n, e, null, axes), ToolUse.TOO_TOUGH)
	check_eq(e.value, before)
	bag.add("axe_copper")
	check_eq(ToolUse.apply("axe", c, FarmModel.new(), bag, 0, null, n, e, null, axes), "Hit")

func test_hints() -> void:
	check(HintModel.for_context({"node_kind": "big_stump", "held": "axe", "axe_power": 1}).contains("copper axe"))
	check(HintModel.for_context({"node_kind": "big_stump", "held": "axe", "axe_power": 2, "node_hp": 8}).contains("chop"))
	check(HintModel.for_context({"sapling_days": 1}).contains("1 day"))

func test_items_icons_slot_and_recipe() -> void:
	var items: Dictionary = DataDB.load_json("items")
	var icons: Dictionary = DataDB.load_json("item_icons")
	for id in ["acorn", "pine_cone", "sap", "hardwood"]:
		check(items.has(id) and icons.has(id) and int(items[id].price) > 0, id)
	for id in DataDB.load_json("forestry")["seeds"].values():
		check(ToolKit.owns([], id), id)
	var r: Dictionary = DataDB.load_json("crafting")["sap_fertiliser"]
	var bag := Inventory.new()
	bag.add("sap", 2)
	bag.add("fibre", 1)
	check_eq(ToolKit.craft([], r, bag), "")
	check_eq(bag.count("fertiliser"), 4)
