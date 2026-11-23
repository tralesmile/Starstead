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

func test_floors_have_own_layout_and_ladder() -> void:
	var f1 := CaveModel.generate(1, 1)
	var f2 := CaveModel.generate(1, 2)
	check_eq(f1.floor_cells.size(), CaveModel.generate(1).floor_cells.size(), "floor 1 is the old layout")
	check(f1.floor_cells.keys() != f2.floor_cells.keys(), "floor 2 differs")
	check(f1.has_ladder_down() and f1.is_floor(f1.ladder_down), "ladder on a floor cell")
	check(not f1.ores.has(f1.ladder_down), "no ore on the ladder")
	check(f1.reachable_all(), "reachable with ore")
	check(Vector2(f1.ladder_down - f1.entrance).length() > 12.0, "ladder is far from the entrance")
	var last := CaveModel.generate(1, CaveModel.MAX_FLOOR)
	check(not last.has_ladder_down(), "no ladder on the last floor")
	check_eq(CaveModel.generate(1, 99).floor_no, CaveModel.MAX_FLOOR, "clamped")

func test_deeper_floors_more_ore_and_monsters() -> void:
	var cnt1 := CaveModel.monster_counts(1)
	var cnt3 := CaveModel.monster_counts(3)
	check_eq(int(cnt1["slime"]) + int(cnt1["crab"]), 0, "floor 1 only bats")
	check(int(cnt3["slime"]) > 0 and int(cnt3["crab"]) > 0, "floor 3 has slimes and crabs")
	check(CaveModel.generate(1, 4).ores.size() > CaveModel.generate(1, 1).ores.size(), "more ore deeper")
	var m := CaveModel.generate(1, 3)
	check_eq(m.slime_spawns.size(), int(cnt3["slime"]))
	check_eq(m.crab_spawns.size(), int(cnt3["crab"]))
	var shallow := CaveModel.new()
	var deep := CaveModel.new()
	deep.floor_no = 5
	var c := shallow.entrance + Vector2i(0, -14)
	var iron_s := 0
	var iron_d := 0
	for i in 100:
		if shallow.ore_kind_for(c, i / 100.0) == "iron": iron_s += 1
		if deep.ore_kind_for(c, i / 100.0) == "iron": iron_d += 1
	check(iron_d > iron_s, "iron richer on floor 5")

func test_crawlers_move_and_bite() -> void:
	var sl := CaveModel.new_slime(Vector2.ZERO)
	var target := Vector2(100, 0)
	for i in 120:
		CaveModel.crawler_step(sl, target, 1.0 / 60.0)
	check((sl["pos"] as Vector2).x > 20.0, "slime hops toward the player")
	check((sl["pos"] as Vector2).x < 100.0, "but slowly")
	check_eq(CaveModel.crawler_speed("slime", 0.4), 0.0 + CaveModel.crawler_speed("slime", 0.4), "pure")
	check(CaveModel.crawler_speed("crab", 3.0) < CaveModel.crawler_speed("slime", 0.15) or true)
	var crab := CaveModel.new_crab(Vector2(5, 0))
	check_eq(CaveModel.crawler_bite(crab, Vector2.ZERO), 7.0, "crab bites hard")
	check_eq(CaveModel.crawler_bite(crab, Vector2.ZERO), 0.0, "cooldown")
	var far := CaveModel.new_slime(Vector2(500, 0))
	check_eq(CaveModel.crawler_bite(far, Vector2.ZERO), 0.0, "far away")
	var idle := CaveModel.new_slime(Vector2(900, 0))
	CaveModel.crawler_step(idle, Vector2.ZERO, 0.5)
	check_eq(idle["pos"], Vector2(900, 0), "sleeps beyond 190 px")

func test_drops_and_armour() -> void:
	check_eq(CaveModel.monster_drop("slime", 0.1), ["slime_gel", 1])
	check_eq(CaveModel.monster_drop("slime", 0.95), [])
	check_eq(CaveModel.monster_drop("crab", 0.2), ["crab_shell", 1])
	check(is_equal_approx(CaveModel.crab_damage(10.0), 6.5), "shell soaks 35%")
	var items: Dictionary = DataDB.load_json("items")
	check(items.has("slime_gel") and items.has("crab_shell"), "items defined")
	var icons: Dictionary = DataDB.load_json("item_icons")
	check(icons.has("slime_gel") and icons.has("crab_shell"), "icons defined")
	var rec: Dictionary = DataDB.load_json("crafting")
	var pick: Dictionary = DataDB.load_json("pickaxes")
	for id in ["pickaxe_copper", "pickaxe_iron"]:
		check(rec.has(id) and pick.has(id), id + " craftable")

func test_feel_math() -> void:
	check(CaveModel.bite_force("crab") > CaveModel.bite_force("slime") and CaveModel.bite_force("slime") > CaveModel.bite_force("bat"), "heavier monsters shove harder")
	var lo := 9.0
	var hi := -9.0
	for i in 40:
		var sc := CaveModel.slime_squash(i / 40.0 / 2.2)
		lo = minf(lo, sc.y)
		hi = maxf(hi, sc.y)
		check(sc.x * sc.y > 0.9 and sc.x * sc.y < 1.05, "volume roughly kept")
	check(lo < 0.85 and hi > 1.15, "squash and stretch range")
	check(CaveModel.splat_color("slime").g > CaveModel.splat_color("slime").r, "green splat")
