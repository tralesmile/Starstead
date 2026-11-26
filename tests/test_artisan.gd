extends BaseTest

func _model() -> ArtisanModel:
	return ArtisanModel.new(DataDB.load_json("artisan"))

func _bag(content: Dictionary) -> Inventory:
	var b := Inventory.new(30)
	for k in content:
		b.add(k, content[k])
	return b

func test_load_wait_collect() -> void:
	var m := _model()
	var b := _bag({"milk": 2})
	check_eq(m.load_machine("press", b).get("out", ""), "cheese")
	check_eq(b.count("milk"), 1)
	check(m.load_machine("press", b).is_empty(), "a full machine takes nothing")
	check_eq(m.collect("press", b), "")
	check_eq(m.day_tick(), 1)
	check_eq(m.day_tick(), 0, "ready only counts once")
	check_eq(m.collect("press", b), "cheese")
	check_eq(b.count("cheese"), 1)
	check(not m.busy("press"))

func test_jar_takes_longer_and_both_jars_work() -> void:
	var m := _model()
	var b := _bag({"turnip": 4})
	check(not m.load_machine("jar1", b).is_empty())
	check(not m.load_machine("jar2", b).is_empty())
	check_eq(b.count("turnip"), 0)
	m.day_tick()
	check(not m.ready("jar1"))
	check_eq(m.day_tick(), 2)

func test_plain_crops_used_before_quality_ones() -> void:
	var m := _model()
	var b := _bag({"turnip": 1, "turnip_silver": 1, "turnip_gold": 1})
	m.load_machine("jar1", b)
	check_eq(b.count("turnip") + b.count("turnip_silver"), 0)
	check_eq(b.count("turnip_gold"), 1)

func test_not_enough_input() -> void:
	var m := _model()
	var b := _bag({"turnip": 1})
	check(m.load_machine("jar1", b).is_empty())
	check_eq(b.count("turnip"), 1)
	check(m.load_machine("loom", b).is_empty())

func test_full_bag_keeps_the_product() -> void:
	var m := _model()
	var b := _bag({"wool": 1})
	m.load_machine("loom", b)
	m.day_tick()
	for i in b.slots.size():
		if b.slots[i] == null:
			b.slots[i] = {"id": "x%d" % i, "n": 1}
	check_eq(m.collect("loom", b), "")
	check(m.ready("loom"))

func test_prompts() -> void:
	var items: Dictionary = DataDB.load_json("items")
	var m := _model()
	check(m.prompt("press", _bag({}), items).contains("needs"))
	check(m.prompt("press", _bag({"milk": 1}), items).begins_with("E: Load"))
	m.load_machine("press", _bag({"milk": 1}))
	check(m.prompt("press", _bag({}), items).contains("1 night"))
	m.day_tick()
	check_eq(m.prompt("press", _bag({}), items), "E: Collect Cheese")

func test_every_recipe_adds_value_without_runaway() -> void:
	var items: Dictionary = DataDB.load_json("items")
	var m := _model()
	for slot in ["press", "jar1", "loom"]:
		for r in m.recipes(slot):
			var raw := float(items[r["in"]]["price"]) * int(r["count"])
			var ratio := float(items[r["out"]]["price"]) / raw
			check(ratio >= 1.4 and ratio <= 2.6, "%s -> %s ratio %.2f" % [r["in"], r["out"], ratio])

func test_save_roundtrip_drops_unknown_slots() -> void:
	var m := _model()
	m.load_machine("press", _bag({"milk": 1}))
	var d: Dictionary = JSON.parse_string(JSON.stringify(m.to_dict()))
	d["ghost"] = {"out": "cheese", "days_left": 0}
	var n := _model()
	n.from_dict(d)
	check(n.busy("press"))
	check(not n.busy("ghost"))

func test_barn_has_all_machines_and_nearest_wins() -> void:
	var l := InteriorModel.layout("barn")
	var m := _model()
	var found := 0
	for f in l["furniture"]:
		if f["action"] == "artisan":
			found += 1
			check(m.has_machine(f["id"]), f["id"])
			var front := (Vector2(f["cell"]) + Vector2(f["size"].x * 0.5, 1.4)) * 32.0
			check_eq(InteriorModel.action_near(l, front, ["artisan"]).get("id", ""), f["id"])
	check_eq(found, 4)

func test_winter_coat_and_pen() -> void:
	var a := AnimalModel.new(DataDB.load_json("animals"))
	var cow := {"id": "cow", "hunger": 0.0, "gear": {}}
	check(a.shivers(cow, true, false))
	check(not a.shivers(cow, false, false))
	check(not a.shivers(cow, true, true))
	check(not a.shivers({"id": "sheep", "gear": {}}, true, false), "sheep are woolly")
	check(not a.shivers({"id": "chicken", "gear": {}}, true, false), "no coat slot")
	check(a.day_tick(cow, 1, 0, true, false).is_empty(), "cold cow: no milk after one fed day")
	a.feed(cow, "hay")
	check_eq(a.day_tick(cow, 2, 0, true, false).get("milk", 0), 1)
	var warm := {"id": "cow", "hunger": 0.0, "gear": {"coat": "fur_coat"}}
	check_eq(a.day_tick(warm, 1, 0, true, false).get("milk", 0), 1)

func test_armour_guard() -> void:
	check_eq(AnimalModel.guard_mult(0.0), 1.0)
	check_eq(AnimalModel.guard_mult(5.0), 0.5)
	check_eq(AnimalModel.guard_mult(50.0), 0.3)

func test_machine_effects() -> void:
	for i in 40:
		var t := i * 0.13
		check(absf(ArtisanMath.bubble_bob(t, 1.0)) <= 2.0)
		var p := ArtisanMath.puff(t, 0.3, i % 3)
		check(p.y <= 0.0 and p.y >= -18.0 and p.z >= 1.5)
		check(ArtisanMath.puff_alpha(t, 0.3, i % 3) >= 0.0)

func test_menu_lists_stay_on_screen() -> void:
	for f in ["recipes", "forge", "butcher", "smelting"]:
		var n: int = DataDB.load_json(f).size()
		var panel := CraftGrid.list_panel(n).grow(6)
		check(panel.position.x >= 0.0 and panel.position.y >= 0.0 and panel.end.x <= 640.0 and panel.end.y <= 360.0, "%s menu fits" % f)
		for i in n:
			check_eq(CraftGrid.list_index_at(CraftGrid.list_rect(i, n).get_center(), n), i)
