extends BaseTest

func test_sell_and_buy() -> void:
	var items = DataDB.load_json("items")
	var inv := Inventory.new(5, {"turnip": 99, "turnip_seed": 99})
	inv.add("turnip", 3)
	var m := Shop.sell(inv, items, "turnip", 2, 100)
	check_eq(m, 148)
	check_eq(Shop.sell(inv, items, "turnip", 5, m), -1, "cannot oversell")
	check_eq(inv.count("turnip"), 1)
	m = Shop.buy(inv, items, "turnip_seed", 3, m)
	check_eq(m, 118)
	check_eq(inv.count("turnip_seed"), 3)
	check_eq(Shop.buy(inv, items, "turnip_seed", 100, 118), -1, "too poor")
	check_eq(Shop.buy(inv, items, "nope", 1, 999), -1)
