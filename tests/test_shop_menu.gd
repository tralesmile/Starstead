extends BaseTest

func _inv() -> Inventory:
	return Inventory.new(10, {"turnip": 99, "turnip_seed": 99, "wood": 99})

func test_sell_tab_lists_carried() -> void:
	var items = DataDB.load_json("items")
	var inv := _inv()
	inv.add("wood", 4)
	inv.add("turnip", 2)
	var m := ShopMenu.new(items)
	var e := m.entries(inv)
	check_eq(e.size(), 2)
	check_eq(e[0].id, "turnip")
	var r := m.confirm(inv, 100)
	check_eq(r.money, 124)
	check_eq(inv.count("turnip"), 1)

func test_buy_tab_seeds_only() -> void:
	var items = DataDB.load_json("items")
	var inv := _inv()
	var m := ShopMenu.new(items)
	m.switch_tab()
	var e := m.entries(inv)
	check(e.size() >= 1)
	for x in e:
		check(String(x.id).ends_with("_seed"))
	var r := m.confirm(inv, 100)
	check_eq(r.money, 90)
	check_eq(inv.count("turnip_seed"), 1)
	var poor := m.confirm(inv, 3)
	check_eq(poor.money, 3)
	check_eq(poor.msg, "Cannot afford")

func test_empty_and_cursor_wrap() -> void:
	var items = DataDB.load_json("items")
	var inv := _inv()
	var m := ShopMenu.new(items)
	check_eq(m.confirm(inv, 5).msg, "Nothing here")
	inv.add("wood", 1)
	inv.add("turnip", 1)
	m.move(-1, inv)
	check_eq(m.cursor, 1)
	m.move(1, inv)
	check_eq(m.cursor, 0)

func test_interactables() -> void:
	var r := Interactables.new()
	r.add(Vector2i(3, 4), "shop", "Shop")
	check_eq(r.at(Vector2i(3, 4)).kind, "shop")
	check(r.at(Vector2i(0, 0)).is_empty())
	check_eq(r.near(Vector2(100, 130), Vector2i(3, 4)).kind, "shop")
	check_eq(r.near(Vector2(3.5 * 32, 4.5 * 32), Vector2i(9, 9)).kind, "shop")
