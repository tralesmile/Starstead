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

func test_planet_prices() -> void:
	var items = DataDB.load_json("items")
	var planets = DataDB.load_json("planets")
	check_eq(Shop.sell_price(items, "turnip"), 24)
	check_eq(Shop.sell_price(items, "turnip", planets, "earth"), 24)
	check(Shop.sell_price(items, "turnip", planets, "moon") > 24 * 2, "moon pays more for crops")
	check(Shop.sell_price(items, "stone", planets, "moon") < 4, "stone cheap on moon")
	check(Shop.buy_price(items, "wood", planets, "moon") > Shop.buy_price(items, "wood", planets, "earth"))
	var inv := Inventory.new(5, {"turnip": 99})
	inv.add("turnip", 1)
	check_eq(Shop.sell(inv, items, "turnip", 1, 0, planets, "moon"), Shop.sell_price(items, "turnip", planets, "moon"))
