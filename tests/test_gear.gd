extends BaseTest

func test_vests_soften_damage_best_counts() -> void:
	var b := Inventory.new()
	check(is_equal_approx(GearModel.soften(b, 10.0), 10.0), "no vest")
	b.add("copper_vest", 1)
	check(is_equal_approx(GearModel.soften(b, 10.0), 8.5), "copper")
	b.add("iron_vest", 1)
	check(is_equal_approx(GearModel.soften(b, 10.0), 7.0), "iron beats copper")

func test_car_parts_scale() -> void:
	var b := Inventory.new()
	check(GearModel.top_speed_mult(b) == 1.0 and GearModel.grip_mult(b) == 1.0 and GearModel.crash_mult(b) == 1.0, "stock car")
	b.add("engine_kit", 1)
	b.add("grip_tyres", 1)
	b.add("bumper_guard", 1)
	check(GearModel.top_speed_mult(b) > 1.1 and GearModel.grip_mult(b) > 1.1 and GearModel.crash_mult(b) < 0.7, "tuned car")

func test_engine_kit_raises_the_top_speed_clamp() -> void:
	var v := Vector2.RIGHT * 299.0
	var stock := VehicleMath.step(v, 0.0, 1.0, 0.0, false, 0.2)
	var kit := VehicleMath.step(v, 0.0, 1.0, 0.0, false, 0.2, 1.0, GearModel.ENGINE_KIT_SPEED)
	check((stock["vel"] as Vector2).length() <= VehicleMath.MAX_SPEED + 0.01, "stock clamped")
	check((kit["vel"] as Vector2).length() > VehicleMath.MAX_SPEED + 3.0, "kit goes faster")

func test_engine_smoke_only_when_battered() -> void:
	check(GearModel.smoke_rate(100.0) == 0.0 and GearModel.smoke_rate(60.0) == 0.0, "healthy: none")
	check(GearModel.smoke_rate(30.0) > 0.0 and GearModel.smoke_rate(5.0) > GearModel.smoke_rate(30.0), "more as health drops")
	check(GearModel.smoke_alpha(0.0) > GearModel.smoke_alpha(50.0), "thicker when worse")

func test_forge_recipes_are_valid_and_craftable() -> void:
	var r: Dictionary = DataDB.load_json("forge")
	var items: Dictionary = DataDB.load_json("items")
	for id in r:
		check(items.has(r[id]["makes"]), id + " is an item")
		for n in r[id]["needs"]:
			check(items.has(n), id + " needs real item " + n)
	var b := Inventory.new()
	var owned := []
	check(ToolKit.craft(owned, r["bumper_guard"], b) != "", "missing bars refused")
	b.add("iron_bar", 3)
	check(ToolKit.craft(owned, r["bumper_guard"], b) == "", "forged")
	check(b.count("bumper_guard") == 1 and b.count("iron_bar") == 0, "bars spent")
	b.add("iron_bar", 3)
	check(ToolKit.craft(owned, r["bumper_guard"], b) == "You already have it", "one only")

func test_sparks_fan_up_and_fall() -> void:
	for i in 14:
		check(GearModel.spark_velocity(i, 14).y < 0.0, "spark %d goes up" % i)
	var v := GearModel.spark_velocity(3, 14)
	check(GearModel.spark_pos(Vector2.ZERO, v, 0.6).y > v.y * 0.6, "gravity bends the arc down")
