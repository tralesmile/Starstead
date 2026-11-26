extends BaseTest

func _fly(a: Dictionary, wind: Vector2) -> Dictionary:
	var s := a
	for i in 400:
		s = BowMath.step(s, wind, 1.0 / 60.0)
		if s["done"]:
			break
	return s

func test_draw_scales_speed_reach_damage() -> void:
	check(not BowMath.can_loose(BowMath.draw_power(0.1)))
	check(BowMath.can_loose(BowMath.draw_power(0.3)))
	check_eq(BowMath.draw_power(5.0), 1.0)
	check(BowMath.speed(1.0) > BowMath.speed(0.5))
	check(BowMath.reach(1.0) > BowMath.reach(0.5))
	check(BowMath.damage(1.0) > BowMath.damage(0.5))

func test_calm_flight_stops_at_reach_in_a_straight_line() -> void:
	var s := _fly(BowMath.launch(Vector2.ZERO, Vector2.RIGHT, 1.0), Vector2.ZERO)
	check(s["done"])
	check(absf(s["pos"].x - BowMath.RANGE_MAX) < 0.5, "x %s" % s["pos"].x)
	check(absf(s["pos"].y) < 0.001)

func test_storm_pushes_arrow_downwind_but_still_aimable() -> void:
	var w := BowMath.wind_accel(1.0, PI / 2.0)
	var s := _fly(BowMath.launch(Vector2.ZERO, Vector2.RIGHT, 1.0), w)
	check(s["pos"].y > 14.0 and s["pos"].y < 64.0, "drift %s" % s["pos"].y)
	check(BowMath.wind_accel(0.0, 0.0).length() < w.length() * 0.2)

func test_drag_slows_and_step_does_not_mutate() -> void:
	var a := BowMath.launch(Vector2.ZERO, Vector2.RIGHT, 1.0)
	var b := BowMath.step(a, Vector2.ZERO, 0.1)
	check_eq(a["flown"], 0.0)
	check(b["vel"].length() < a["vel"].length())

func test_swept_hit_no_tunnelling() -> void:
	check(BowMath.hits(Vector2(0, 0), Vector2(100, 0), Vector2(50, 6)))
	check(not BowMath.hits(Vector2(0, 0), Vector2(100, 0), Vector2(50, 30)))
	check(not BowMath.hits(Vector2(0, 0), Vector2(100, 0), Vector2(140, 0)))

func test_lift_drops_at_end_and_recovery_odds() -> void:
	var a := BowMath.launch(Vector2.ZERO, Vector2.RIGHT, 1.0)
	check_eq(BowMath.lift(a), 12.0)
	a["flown"] = a["reach"]
	check(BowMath.lift(a) < 0.01)
	check(BowMath.recoverable(false, 0.6) and not BowMath.recoverable(true, 0.6))

func test_drawing_slows_the_walk() -> void:
	check(PlayerMath.draw_slow(0.0) > PlayerMath.draw_slow(1.0))
	check(PlayerMath.draw_slow(1.0) >= 0.4)

func test_slot_eight_swaps_club_and_bow() -> void:
	check_eq(ToolKit.melee_tool(0, ["club"]), "club")
	check_eq(ToolKit.melee_tool(1, ["club"]), "club")
	check_eq(ToolKit.melee_tool(1, ["club", "bow"]), "bow")
	check_eq(ToolKit.melee_tool(2, ["club", "bow"]), "club")
	check_eq(ToolKit.melee_tool(0, ["bow"]), "bow")

func test_craft_grid_fits_the_screen() -> void:
	var n: int = DataDB.load_json("crafting").size()
	var screen := Rect2(0, 0, 640, 360)
	check(screen.encloses(CraftGrid.panel_rect(n)), str(CraftGrid.panel_rect(n)))
	for i in n:
		check(screen.encloses(CraftGrid.cell_rect(i)))
		check_eq(CraftGrid.index_at(CraftGrid.cell_rect(i).get_center(), n), i)

func test_craft_bow_and_arrows() -> void:
	var bag := Inventory.new(10, {"arrow": 99, "wood": 99, "fibre": 99})
	bag.add("wood", 7)
	bag.add("fibre", 5)
	var owned := ["hoe"]
	var rec: Dictionary = DataDB.load_json("crafting")
	check_eq(ToolKit.craft(owned, rec["bow"], bag), "")
	check("bow" in owned)
	check_eq(ToolKit.craft(owned, rec["arrow"], bag), "")
	check_eq(bag.count("arrow"), 5)
