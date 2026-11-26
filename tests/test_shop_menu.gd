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
		check(bool(items[x.id].get("buy", false)))
	for i in e.size():
		if e[i].id == "turnip_seed":
			m.cursor = i
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

func test_buy_wood_uses_buy_price() -> void:
	var items = DataDB.load_json("items")
	var inv := _inv()
	check_eq(Shop.buy_price(items, "wood"), 12)
	check_eq(Shop.buy(inv, items, "wood", 2, 100), 76)
	check_eq(inv.count("wood"), 2)
	var m := ShopMenu.new(items)
	m.switch_tab()
	var ids := []
	for x in m.entries(inv):
		ids.append(x.id)
	check("wood" in ids and "turnip_seed" in ids)

func test_long_list_scrolls_and_keeps_the_cursor_visible() -> void:
	var total := 29
	for cursor in total:
		var top := ShopMenu.first_row(cursor, total)
		check(cursor >= top and cursor < top + ShopMenu.ROWS, "cursor %d visible" % cursor)
		check(top >= 0 and top + ShopMenu.ROWS <= total, "window inside the list")
	check_eq(ShopMenu.first_row(3, 5), 0)

func test_shop_rows_fit_the_screen() -> void:
	check(61.0 + ShopMenu.ROWS * ShopMenu.ROW_H + 30.0 <= ShopMenu.BOX.size.y)
	check(ShopMenu.BOX.end.y + 6.0 <= 360.0)
