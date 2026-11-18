extends BaseTest

func test_cave_connected_and_sized() -> void:
	var m := CaveModel.generate(1)
	check(m.floor_cells.size() > 400, "big enough %d" % m.floor_cells.size())
	check(m.is_floor(m.entrance))
	check(m.reachable_all(), "every free floor cell reachable")
	for c in m.floor_cells:
		check(c.x >= 2 and c.x <= CaveModel.W - 3 and c.y >= 2 and c.y <= CaveModel.H - 3, "inside grid")

func test_ores_depth_and_respawn() -> void:
	var m := CaveModel.generate(1)
	check(m.ores.size() >= 12, "ores %d" % m.ores.size())
	var kinds := {}
	for c in m.ores:
		kinds[m.ores[c]["kind"]] = true
		check(Vector2(c - m.entrance).length() >= 6.0, "no ore at the door")
	check(kinds.has("copper") and kinds.has("coal"), "copper and coal present")
	var m2 := CaveModel.generate(2)
	check(m.floor_cells.size() == m2.floor_cells.size(), "layout fixed")
	check(m.ores.keys() != m2.ores.keys(), "ore changes by day")
	check_eq(CaveModel.generate(1).ores.keys(), m.ores.keys(), "deterministic")

func test_ore_kind_by_depth() -> void:
	var m := CaveModel.new()
	check_eq(m.ore_kind_for(m.entrance + Vector2i(0, -3), 0.1), "copper")
	check_eq(m.ore_kind_for(m.entrance + Vector2i(0, -30), 0.1), "iron")

func test_hit_ore_breaks() -> void:
	var m := CaveModel.generate(1)
	var c: Vector2i = m.ores.keys()[0]
	var kind: String = m.ores[c]["kind"]
	var hp: int = CaveModel.ORE_HP[kind]
	check_eq(m.hit_ore(Vector2i(-5, -5), 1), {})
	var res := {}
	for i in hp:
		res = m.hit_ore(c, 1)
	check(res.has("id"), "broke after hp hits")
	check(not m.ores.has(c))
	check_eq(res["id"], CaveModel.ORE_DROP[kind][0])
	var c2: Vector2i = m.ores.keys()[0]
	check_eq(m.hit_ore(c2, 99).has("id"), true, "strong pick one-shots")

func test_torches_on_walls_spaced() -> void:
	var m := CaveModel.generate(1)
	check(m.torches.size() >= 3)
	for t in m.torches:
		check(not m.is_floor(t))
		check(m.is_floor(t + Vector2i(0, 1)))

func test_bat_chases_and_bites() -> void:
	var b := CaveModel.new_bat(Vector2(0, 0))
	var target := Vector2(100, 0)
	for i in 120:
		CaveModel.bat_step(b, target, 1.0 / 60.0)
	check((b["pos"] as Vector2).x > 40.0, "moved toward the player")
	var far := CaveModel.new_bat(Vector2(0, 0))
	CaveModel.bat_step(far, Vector2(900, 0), 0.5)
	check_eq((far["pos"] as Vector2).length() < 1.0, true, "sleeps when far")
	var near := CaveModel.new_bat(Vector2(5, 0))
	check_eq(CaveModel.bat_bite(near, Vector2.ZERO), 5.0)
	check_eq(CaveModel.bat_bite(near, Vector2.ZERO), 0.0, "cooldown")
	near["cd"] = 0.0
	near["down"] = 2.0
	check_eq(CaveModel.bat_bite(near, Vector2.ZERO), 0.0, "knocked out")

func test_smelting_recipes() -> void:
	var rec: Dictionary = DataDB.load_json("smelting")
	var inv := Inventory.new(10, {})
	inv.add("copper_ore", 2)
	inv.add("coal", 1)
	check(CookModel.cook(inv, rec["copper_bar"]))
	check_eq(inv.count("copper_bar"), 1)
	check(not CookModel.can_cook(inv, rec["iron_bar"]))

func test_cave_mouth_in_highlands() -> void:
	var r := RoadNet.new(1)
	check(r.cave_mouth.x != RoadNet.NO_CELL, "mouth placed")
	var ch := ChunkGrid.chunk_of_cell(r.cave_mouth)
	var reg := ChunkGrid.region_of(ch, DataDB.load_json("regions"))
	check_eq(String(reg.get("id", "")), "highlands")

func test_workshop_has_furnace() -> void:
	var l := InteriorModel.layout("workshop")
	var a := InteriorModel.action_near(l, Vector2(5.5 * 32.0, 1.5 * 32.0), ["smelt", "garage"])
	check_eq(String(a.get("action", "")), "smelt")
	var g := InteriorModel.action_near(l, Vector2(2.5 * 32.0, 2.2 * 32.0), ["smelt", "garage"])
	check_eq(String(g.get("action", "")), "garage")
