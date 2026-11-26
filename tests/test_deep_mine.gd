extends BaseTest

func test_silver_and_gold_only_deep() -> void:
	var shallow := {}
	for f in [1, 2]:
		var m := CaveModel.generate(3, f)
		for c in m.ores:
			shallow[m.ores[c]["kind"]] = true
	check(not shallow.has("silver") and not shallow.has("gold"), "none near the surface")
	var deep := {}
	for day in 6:
		for f in [4, 5]:
			var m := CaveModel.generate(day + 1, f)
			for c in m.ores:
				deep[m.ores[c]["kind"]] = true
			check(m.reachable_all(), "veins never wall anything off")
	check(deep.has("silver") and deep.has("gold"), "silver and gold deeper down")

func test_ore_grows_in_veins() -> void:
	var touching := 0
	var total := 0
	for day in 5:
		var m := CaveModel.generate(day + 1, 1)
		for c in m.ores:
			total += 1
			for o in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				if m.ores.has(c + o) and m.ores[c + o]["kind"] == m.ores[c]["kind"]:
					touching += 1
					break
	check(float(touching) / total > 0.5, "most ore sits beside its own kind: %d/%d" % [touching, total])

func test_boss_floor_is_a_clear_hall() -> void:
	var m := CaveModel.generate(1, CaveModel.BOSS_FLOOR)
	check(m.is_boss_floor() and not m.has_ladder_down())
	check(m.is_floor(m.boss_spawn()) and m.is_floor(m.entrance))
	check(m.bat_spawns.is_empty() and m.slime_spawns.is_empty() and m.crab_spawns.is_empty(), "fights alone")
	check(m.reachable_all())
	for dy in range(-4, 5):
		for dx in range(-6, 7):
			var c := CaveModel.HALL_CENTRE + Vector2i(dx, dy)
			check(m.is_floor(c) and not m.ores.has(c), "open arena at %s" % str(c))

func test_rail_runs_from_door_to_ladder() -> void:
	for f in range(1, CaveModel.BOSS_FLOOR):
		var m := CaveModel.generate(2, f)
		check(m.rail.size() >= CaveModel.RAIL_MIN, "floor %d has a track" % f)
		check(Vector2(m.rail[0] - m.entrance).length() < 4.0, "starts at the door")
		var gap: Vector2i = m.rail[m.rail.size() - 1] - m.ladder_down
		check_eq(absi(gap.x) + absi(gap.y), 2, "stops short of the ladder")
		for i in m.rail.size():
			check(m.is_floor(m.rail[i]) and not m.ores.has(m.rail[i]), "track clear")
			if i > 0:
				var d: Vector2i = m.rail[i] - m.rail[i - 1]
				check_eq(absi(d.x) + absi(d.y), 1, "unbroken")

func _line(n: int) -> PackedVector2Array:
	var cells: Array = []
	for i in n:
		cells.append(Vector2i(i, 0))
	return CartMath.points(cells)

func test_cart_rolls_downhill_and_can_be_pumped_home() -> void:
	var pts := _line(60)
	var st := {"s": 0.0, "v": 0.0}
	for i in 120:
		CartMath.step(st, pts, 0.0, false, 1.0 / 60.0)
	check(float(st["s"]) > 30.0 and float(st["v"]) > 20.0, "gravity starts it %s" % str(st))
	st = {"s": 900.0, "v": 0.0}
	for i in 240:
		CartMath.step(st, pts, -1.0, false, 1.0 / 60.0)
	check(float(st["s"]) < 700.0 and float(st["v"]) < -40.0, "pumping beats the slope %s" % str(st))

func test_cart_brake_stops_and_holds() -> void:
	var pts := _line(60)
	var st := {"s": 100.0, "v": 200.0}
	for i in 90:
		CartMath.step(st, pts, 0.0, true, 1.0 / 60.0)
	check_eq(float(st["v"]), 0.0, "stopped")
	check(float(st["s"]) < 200.0, "in under 100 px")

func test_cart_buffers_bounce_and_rest() -> void:
	var pts := _line(10)
	var st := {"s": CartMath.length(pts) - 5.0, "v": 200.0}
	var res := CartMath.step(st, pts, 0.0, false, 0.05)
	check(float(res["bump"]) > 100.0 and float(st["v"]) < 0.0, "bounced")
	for i in 900:
		CartMath.step(st, pts, 0.0, false, 1.0 / 60.0)
		check(float(st["s"]) >= 0.0 and float(st["s"]) <= CartMath.length(pts), "stays on the rails")
	check(is_equal_approx(float(st["s"]), CartMath.length(pts)), "settles at the low end")
	check_eq(float(st["v"]), 0.0, "at rest, no jitter")

func test_cart_corner_jolts_only_when_fast() -> void:
	var pts := CartMath.points([Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(2, 1), Vector2i(2, 2)])
	check(CartMath.is_corner(pts, 2) and not CartMath.is_corner(pts, 1))
	var fast := {"s": 60.0, "v": 240.0}
	check(CartMath.step(fast, pts, 0.0, false, 0.03)["jolt"], "screech")
	check(float(fast["v"]) < 200.0 and float(fast["v"]) >= CartMath.CORNER_V, "scrubbed")
	var slow := {"s": 60.0, "v": 100.0}
	check(not CartMath.step(slow, pts, 0.0, false, 0.05)["jolt"])
	check_eq(CartMath.pos_at(pts, 64.0 + 16.0), Vector2(80, 32), "position follows the bend")

func test_cart_tiles_and_pump_input() -> void:
	check_eq(CartMath.tile_frame(Vector2i(-1, 0), Vector2i(1, 0)), 0)
	check_eq(CartMath.tile_frame(Vector2i.ZERO, Vector2i(0, -1)), 1)
	check_eq(CartMath.tile_frame(Vector2i(0, -1), Vector2i(1, 0)), 2)
	check_eq(CartMath.tile_frame(Vector2i(-1, 0), Vector2i(0, -1)), 3)
	check_eq(CartMath.tile_frame(Vector2i(0, 1), Vector2i(1, 0)), 4)
	check_eq(CartMath.tile_frame(Vector2i(-1, 0), Vector2i(0, 1)), 5)
	check(CartMath.pump_from_input(Vector2(0, -1), Vector2(0, -1)) > 0.9)
	check(absf(CartMath.pump_from_input(Vector2(1, 0), Vector2(0, -1))) < 0.1)

func test_deep_recipes_and_tool_tiers_at_the_anvil() -> void:
	var smelt: Dictionary = DataDB.load_json("smelting")
	var forge: Dictionary = DataDB.load_json("forge")
	var items: Dictionary = DataDB.load_json("items")
	var icons: Dictionary = DataDB.load_json("item_icons")
	check(smelt.has("silver_bar") and smelt.has("gold_bar"))
	for id in ["axe_copper", "axe_iron", "hoe_copper", "hoe_iron", "watering_can_copper", "watering_can_iron", "pickaxe_gold", "deep_lamp"]:
		check(forge.has(id), "forgeable " + id)
		check(items.has(id) and icons.has(id), "item and icon " + id)
	var inv := Inventory.new(10, {})
	inv.add("pickaxe_gold", 1)
	check_eq(ToolUse.axe_power(inv, DataDB.load_json("pickaxes"), "pickaxe"), 4)
	check(CraftGrid.panel_rect(forge.size()).end.y <= 360.0, "anvil list fits the screen")
