extends BaseTest

func _defs() -> Dictionary:
	return DataDB.load_json("build")

func _rooms() -> Dictionary:
	return DataDB.load_json("rooms")

func _box(w: int, h: int, inside: Array = []) -> BuildModel:
	## A w x h walled box with a door in the bottom wall, floored, `inside` pieces along the top row.
	var m := BuildModel.new(_defs())
	var bag := Inventory.new(30, {})
	for i in 5:
		bag.add("wood", 99)
		bag.add("stone", 99)
	for y in h:
		for x in w:
			var edge := x == 0 or x == w - 1 or y == 0 or y == h - 1
			m.place(Vector2i(x, y), ("door" if x == 1 and y == h - 1 else "wall") if edge else "floor", 9.0, false, bag)
	for i in inside.size():
		check_eq(m.place(Vector2i(1 + i % (w - 2), 1 + i / (w - 2)), inside[i], 9.0, false, bag), "", "place " + String(inside[i]))
	return m

func _judge(m: BuildModel, at: Vector2i = Vector2i(1, 2)) -> Dictionary:
	return RoomModel.judge(m.placed, at, _rooms(), m.defs)

func test_room_data_names_real_pieces() -> void:
	var defs := _defs()
	var rooms := _rooms()
	for t in rooms:
		check(rooms[t].needs.has(rooms[t].station), t)
		for id in rooms[t].needs:
			check(defs.has(id) and bool(defs[id].furniture) and String(defs[id].room) == t, id)
			check(id in BuildModel.PIECES, id)

func test_each_room_type() -> void:
	for pair in [["bedroom", ["bed"]], ["shop", ["shop_counter", "shelf"]], ["garage", ["workbench", "tool_rack"]]]:
		var r := _judge(_box(4, 4, pair[1]))
		check(r.valid, "%s %s" % [pair[0], r.missing])
		check_eq(r.type, pair[0])

func test_missing_things_are_named() -> void:
	var r := _judge(_box(4, 4, ["shop_counter"]))
	check(not r.valid)
	check_eq(r.name, "Farm Shop")
	check_eq(RoomModel.needs_text(r.name, r.missing), "Farm Shop needs: a Goods Shelf")
	var small := _judge(_box(4, 3, ["workbench", "tool_rack"]), Vector2i(1, 1))
	check(not small.valid and "more space (2 of 4 tiles)" in small.missing, str(small.missing))
	var empty := _judge(_box(4, 4))
	check(empty.flood.enclosed and empty.type == "" and not empty.valid)

func test_no_door_and_open_wall() -> void:
	var m := _box(4, 4, ["bed"])
	m.placed[Vector2i(1, 3)] = "wall"
	var s := RoomModel.station_check(m.placed, Vector2i(1, 1), "bedroom", _rooms(), m.defs)
	check_eq(s.missing, ["a door"])
	m.placed.erase(Vector2i(0, 1))
	s = RoomModel.station_check(m.placed, Vector2i(1, 1), "bedroom", _rooms(), m.defs)
	check(not s.ok and "walls closed all the way round" in s.missing)

func test_fence_is_not_a_wall() -> void:
	var m := _box(4, 4, ["bed"])
	m.placed[Vector2i(0, 1)] = "fence"
	check(not _judge(m).flood.enclosed)

func test_furniture_does_not_plug_a_gap() -> void:
	var m := _box(4, 4)
	m.placed[Vector2i(0, 1)] = "shelf"
	check(not m.is_enclosed(Vector2i(1, 1)))

func test_find_rooms_once_each() -> void:
	var m := _box(5, 4, ["shop_counter", "shelf", "shelf"])
	var found := RoomModel.find_rooms(m.placed, _rooms(), m.defs)
	check_eq(found.size(), 1)
	check_eq(int(found[0].flood.count.shelf), 2)

func test_furniture_on_floor_save_and_demolish() -> void:
	var m := _box(4, 4, ["bed"])
	var c := Vector2i(1, 1)
	check_eq(m.under.get(c), "floor")
	var back := BuildModel.new(_defs())
	back.from_dict(JSON.parse_string(JSON.stringify(m.to_dict())))
	check_eq(back.placed.get(c), "bed")
	check_eq(back.under.get(c), "floor")
	var bag := Inventory.new(30, {})
	check(back.remove_piece(c, bag))
	check_eq(bag.count("wood"), 10, "half the bed back")
	check_eq(back.placed.get(c), "floor")
	check(back.under.is_empty())

func test_furniture_never_stacks() -> void:
	var m := _box(4, 4, ["bed"])
	var bag := Inventory.new(30, {})
	bag.add("wood", 99)
	check_eq(m.check(Vector2i(1, 1), "shelf", 9.0, false, bag), "Occupied")
	check_eq(m.check(Vector2i(0, 0), "shelf", 9.0, false, bag), "Occupied")

func _items() -> Dictionary:
	return DataDB.load_json("items")

func _menu(market: MarketModel) -> ShopMenu:
	var menu := ShopMenu.new(_items())
	menu.market = market
	menu.day = 3
	return menu

func test_shop_never_sells_what_you_can_buy() -> void:
	var items := _items()
	for id in items:
		if items[id].get("buy", false) or items[id].has("buy_price"):
			check(not FarmShopModel.allowed(items, id), id)
	check(FarmShopModel.allowed(items, "turnip"))

func test_no_profit_from_crafting_bought_things() -> void:
	## Anything made only from bought ingredients must not out-earn their cost at the premium price.
	var items := _items()
	var premium := float(_rooms().shop.premium) * (1.0 + MarketModel.DEMAND_SWING)
	for file in ["recipes", "crafting", "smelting", "forge", "butcher"]:
		var recipes: Dictionary = DataDB.load_json(file)
		for k in recipes:
			var r: Dictionary = recipes[k]
			if not FarmShopModel.allowed(items, String(r.makes)):
				continue
			var cost := 0.0
			var all_bought := true
			for id in r.needs:
				all_bought = all_bought and items[id].has("buy_price")
				cost += float(items[id].get("buy_price", 0)) * float(r.needs[id])
			if all_bought:
				check(float(items[r.makes].price) * int(r.get("count", 1)) * premium < cost, "%s %s" % [file, k])

func test_stock_moves_and_cap() -> void:
	var shop := FarmShopModel.new()
	var bag := Inventory.new(5, {"turnip": 99, "wood": 99})
	bag.add("turnip", 50)
	bag.add("wood", 5)
	check_eq(shop.add(_items(), bag, "wood", 5, 40), 0, "buyable goods refused")
	check_eq(shop.add(_items(), bag, "turnip", 50, 40), 40)
	check_eq(shop.add(_items(), bag, "turnip", 1, 40), 0)
	check_eq(bag.count("turnip"), 10)
	check_eq(shop.take(bag, "turnip", 99), 40)
	check_eq(bag.count("turnip"), 50)
	check_eq(shop.total(), 0)
	var full := Inventory.new(1, {"turnip": 99, "egg": 99})
	full.add("egg", 1)
	shop.stock = {"turnip": 3}
	check_eq(shop.take(full, "turnip", 3), 0)
	check_eq(shop.total(), 3, "nothing lost with a full bag")

func test_night_quota_premium_and_pressure() -> void:
	var rule: Dictionary = _rooms().shop
	check_eq(FarmShopModel.daily_sales(rule, 1), 12)
	check_eq(FarmShopModel.daily_sales(rule, 9), 20, "shelf bonus is capped")
	var shop := FarmShopModel.new()
	shop.stock = {"turnip": 30}
	var market := MarketModel.new()
	var r := shop.sell_night(_menu(market), rule, 1)
	check_eq(r.units, 12)
	check_eq(shop.total(), 18)
	check_eq(int(market.sold.turnip), 12, "shop sales press the market like stall sales")
	var stall := MarketModel.new()
	var plain := 0
	for i in 12:
		plain += stall.price(24, "turnip", 3)
		stall.record("turnip")
	check(r.money > plain, "better than the stall")
	check(r.money <= int(ceil(plain * float(rule.premium))), "never more than the premium")

func test_stall_glut_carries_into_the_shop() -> void:
	var rule: Dictionary = _rooms().shop
	var fresh := FarmShopModel.new()
	fresh.stock = {"turnip": 5}
	var glutted := MarketModel.new()
	glutted.record("turnip", 40)
	var after := FarmShopModel.new()
	after.stock = {"turnip": 5}
	check(after.sell_night(_menu(glutted), rule, 1).money < fresh.sell_night(_menu(MarketModel.new()), rule, 1).money)

func test_stock_save_roundtrip() -> void:
	var a := FarmShopModel.new()
	a.stock = {"egg": 4}
	var b := FarmShopModel.new()
	b.from_dict(JSON.parse_string(JSON.stringify(a.to_dict())))
	check_eq(b.stock, {"egg": 4})
	b.from_dict({})
	check_eq(b.total(), 0)

func test_garage_discount() -> void:
	var cut := 1.0 - float(_rooms().garage.repair_discount)
	check_eq(GarageModel.discounted(100, cut), 75)
	check_eq(GarageModel.discounted(1, cut), 1)
	check_eq(GarageModel.discounted(0, cut), 0)

func test_stock_window_fits_the_screen() -> void:
	var screen := Rect2(0, 0, 640, 360)
	check(screen.encloses(FarmShopModel.BOX.grow(6)))
	for col in 2:
		for i in FarmShopModel.ROWS:
			check(FarmShopModel.BOX.encloses(FarmShopModel.row_rect(col, i)))
	check(not FarmShopModel.row_rect(0, 0).intersects(FarmShopModel.row_rect(1, 0)))
	check(FarmShopModel.LIST_Y + FarmShopModel.ROWS * FarmShopModel.ROW_H + 38.0 <= FarmShopModel.BOX.end.y, "footer inside")
