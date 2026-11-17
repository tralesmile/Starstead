extends BaseTest

func _farm() -> FarmModel:
	var f := FarmModel.new({"turnip": {"seed": "turnip_seed", "grow_days": 4, "season": [0], "yield": 1}})
	for x in 20:
		f.till(Vector2i(x, 0))
	return f

func test_weeds_only_on_fallow_soil_and_capped() -> void:
	var f := _farm()
	f.plant(Vector2i(0, 0), "turnip_seed", 0)
	var total := 0
	for d in 30:
		f.spawn_weeds(d)
	check(not f.weeds.has(Vector2i(0, 0)))
	check(f.weeds.size() <= 10)
	check(f.weeds.size() > 0)

func test_weeds_deterministic() -> void:
	var a := _farm()
	var b := _farm()
	a.spawn_weeds(5)
	b.spawn_weeds(5)
	check_eq(a.weeds_to_array(), b.weeds_to_array())

func test_weed_blocks_planting_until_cut() -> void:
	var f := _farm()
	f.weeds[Vector2i(3, 0)] = 0
	check(not f.plant(Vector2i(3, 0), "turnip_seed", 0))
	check(f.cut_weed(Vector2i(3, 0)))
	check(not f.cut_weed(Vector2i(3, 0)))
	check(f.plant(Vector2i(3, 0), "turnip_seed", 0))

func test_scythe_drops_fibre() -> void:
	var f := _farm()
	f.weeds[Vector2i(2, 0)] = 1
	var inv := Inventory.new(30, {"fibre": 99})
	check_eq(ToolUse.apply("scythe", Vector2i(2, 0), f, inv, 0), "Cut weeds")
	check(inv.count("fibre") >= 1)
	check_eq(ToolUse.apply("scythe", Vector2i(2, 0), f, inv, 0), "")

func test_weeds_save_roundtrip() -> void:
	var f := _farm()
	f.weeds[Vector2i(4, 0)] = 2
	var g := _farm()
	g.weeds_from_array(f.weeds_to_array())
	check_eq(g.weeds[Vector2i(4, 0)], 2)
