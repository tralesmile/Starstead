extends BaseTest

func test_stack_and_overflow() -> void:
	var inv := Inventory.new(2, {"wood": 10})
	check_eq(inv.add("wood", 15), 0)
	check_eq(inv.count("wood"), 15)
	check_eq(inv.slots[0].n, 10)
	check_eq(inv.add("wood", 10), 5, "overflow leftover")
	check_eq(inv.count("wood"), 20)

func test_remove() -> void:
	var inv := Inventory.new(3, {"stone": 5})
	inv.add("stone", 8)
	check(not inv.remove("stone", 9), "cannot remove more than held")
	check(inv.remove("stone", 6))
	check_eq(inv.count("stone"), 2)
	check(inv.remove("stone", 2))
	check(inv.slots[0] == null and inv.slots[1] == null, "emptied slots freed")

func test_inventory_roundtrip() -> void:
	var inv := Inventory.new(4)
	inv.add("egg", 3)
	var b := Inventory.new(4)
	b.from_array(JSON.parse_string(JSON.stringify(inv.to_array())))
	check_eq(b.count("egg"), 3)

func _farm() -> FarmModel:
	return FarmModel.new(DataDB.load_json("crops"))

func test_crop_lifecycle() -> void:
	var f := _farm()
	var c := Vector2i(3, 4)
	check(not f.plant(c, "turnip_seed", 0), "needs tilled soil")
	check(f.till(c) and not f.till(c), "till once")
	check(f.plant(c, "turnip_seed", 0))
	check(not f.plant(c, "turnip_seed", 0), "occupied")
	for i in 4:
		f.next_day()  # unwatered: no growth
	check(not f.is_ripe(c), "unwatered does not grow")
	for i in 4:
		f.water(c)
		f.next_day()
	check(f.is_ripe(c))
	var h := f.harvest(c)
	check_eq(h.id, "turnip")
	check(not f.is_ripe(c) and f.soil.has(c), "soil stays tilled")

func test_farm_roundtrip() -> void:
	var f := _farm()
	f.till(Vector2i(1, 1))
	f.plant(Vector2i(1, 1), "turnip_seed", 1)
	var g := _farm()
	g.from_array(JSON.parse_string(JSON.stringify(f.to_array())))
	check_eq(g.soil[Vector2i(1, 1)].crop, "turnip")

func test_tomato_regrows() -> void:
	var f := FarmModel.new(DataDB.load_json("crops"))
	var c := Vector2i(3, 3)
	f.till(c)
	check(f.plant(c, "tomato_seed", 1))
	for i in 6:
		f.water(c)
		f.next_day()
	check(f.is_ripe(c))
	var h := f.harvest(c)
	check_eq(h["id"], "tomato")
	check_eq(f.soil[c].crop, "tomato", "vine stays planted")
	check(not f.is_ripe(c))
	for i in 3:
		f.water(c)
		f.next_day()
	check(f.is_ripe(c), "ripe again after 3 watered days")
	f.till(Vector2i(4, 4))
	f.plant(Vector2i(4, 4), "turnip_seed", 1)
	for i in 4:
		f.water(Vector2i(4, 4))
		f.next_day()
	f.harvest(Vector2i(4, 4))
	check_eq(f.soil[Vector2i(4, 4)].crop, "", "turnip is one-shot")
