extends BaseTest

func _farm() -> FarmModel:
	var f := FarmModel.new({"turnip": {"seed": "turnip_seed", "grow_days": 4, "season": 0, "yield": 1}})
	for x in range(0, 10):
		for y in range(0, 10):
			f.till(Vector2i(x, y))
			f.soil[Vector2i(x, y)].crop = "turnip"
			f.soil[Vector2i(x, y)].age = 4
	return f

func test_place_rules() -> void:
	var f := _farm()
	check(not f.place_scarecrow(Vector2i(1, 1)))
	check(f.place_scarecrow(Vector2i(20, 20)))
	check(not f.place_scarecrow(Vector2i(20, 20)))
	check(f.pick_up_scarecrow(Vector2i(20, 20)))
	check(not f.pick_up_scarecrow(Vector2i(20, 20)))

func test_crows_take_ripe_crops_but_capped() -> void:
	var f := _farm()
	var lost := 0
	for day in 12:
		lost = f.crow_raid(day)
		check(lost <= int(floor(100.0 * 0.34)))
	check(f.crops_planted() < 100)

func test_scarecrow_protects_radius() -> void:
	var f := _farm()
	f.place_scarecrow(Vector2i(5, 12))
	for day in 30:
		f.crow_raid(day)
	check(f.scared(Vector2i(5, 7)))
	check(not f.scared(Vector2i(5, 3)))
	check(f.soil[Vector2i(5, 7)].crop == "turnip")   # inside radius 6 of (5,12) -> untouched

func test_young_crops_ignored_and_save_roundtrip() -> void:
	var f := _farm()
	for c in f.soil:
		f.soil[c].age = 0
	for day in 20:
		check_eq(f.crow_raid(day), 0)
	f.place_scarecrow(Vector2i(30, 30))
	var g := FarmModel.new({})
	g.scarecrows_from_array(f.scarecrows_to_array())
	check(g.scarecrows.has(Vector2i(30, 30)))

func test_tool_use_place_and_pickup() -> void:
	var f := FarmModel.new({})
	var inv := Inventory.new()
	inv.add("scarecrow", 1)
	check(ToolUse.apply("scarecrow", Vector2i(3, 3), f, inv, 0).begins_with("Scarecrow"))
	check_eq(inv.count("scarecrow"), 0)
	check_eq(ToolUse.apply("hand", Vector2i(3, 3), f, inv, 0), "Picked up scarecrow")
	check_eq(inv.count("scarecrow"), 1)

func test_hoe_dig_arc() -> void:
	check_eq(HitMath.hoe_angle(0.0, 0.3), 0.0)
	check(HitMath.hoe_angle(0.3 * 0.8, 0.3) < -1.0)     # early: lifted high
	check(HitMath.hoe_angle(0.3 * 0.45, 0.3) > 0.4)     # mid: driven into the soil
	check(HitMath.hoe_angle(0.3 * 0.05, 0.3) < HitMath.hoe_angle(0.3 * 0.46, 0.3))
	check(HitMath.hoe_angle(0.001, 0.3) < 1.1 and HitMath.hoe_angle(0.001, 0.3) > 0.5)   # ends dragging back

func test_clods_fan_away() -> void:
	for i in 5:
		var v := HitMath.clod_velocity(i, 5, Vector2.RIGHT)
		check(v.x > 0.0, "clod %d flies away" % i)
	check(HitMath.clod_velocity(0, 5, Vector2.RIGHT).y < 0.0 and HitMath.clod_velocity(4, 5, Vector2.RIGHT).y > 0.0)
