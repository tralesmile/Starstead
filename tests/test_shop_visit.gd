extends BaseTest

func _defs() -> Dictionary:
	return DataDB.load_json("build")

func _rooms() -> Dictionary:
	return DataDB.load_json("rooms")

func _rule() -> Dictionary:
	return _rooms().shop

func _menu(market: MarketModel) -> ShopMenu:
	var menu := ShopMenu.new(DataDB.load_json("items"))
	menu.market = market
	menu.day = 3
	return menu

func _shop_placed() -> Dictionary:
	## A 5x4 shop with its door in the middle of the bottom wall (2,3); counter and two shelves along the top.
	var p := {}
	for y in 4:
		for x in 5:
			var edge := x == 0 or x == 4 or y == 0 or y == 3
			p[Vector2i(x, y)] = ("door" if x == 2 and y == 3 else "wall") if edge else "floor"
	p[Vector2i(1, 1)] = "shop_counter"
	p[Vector2i(2, 1)] = "shelf"
	p[Vector2i(3, 1)] = "shelf"
	return p

func _rng(seed_n: int = 1) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = seed_n
	return r

func _land(_c: Vector2i) -> bool:
	return true

func test_opening_hours() -> void:
	check(not ShopVisit.is_open(_rule(), 8.9))
	check(ShopVisit.is_open(_rule(), 9.0))
	check(ShopVisit.is_open(_rule(), 17.9))
	check(not ShopVisit.is_open(_rule(), 18.0))
	check(not ShopVisit.is_open(_rule(), 1.0))

func test_no_shopper_without_a_finished_room_or_goods() -> void:
	var shop := FarmShopModel.new()
	var p := _shop_placed()
	var room := ShopVisit.shop_room(p, _rooms(), _defs())
	check_eq(int(room.get("shelves", -1)), 2)
	check(not ShopVisit.wants_visit(_rule(), 12.0, shop, room), "bare shelves")
	shop.stock = {"turnip": 5}
	check(ShopVisit.wants_visit(_rule(), 12.0, shop, room))
	check(not ShopVisit.wants_visit(_rule(), 7.0, shop, room), "closed")
	p.erase(Vector2i(0, 1))   # a gap in the wall
	var broken := ShopVisit.shop_room(p, _rooms(), _defs())
	check(broken.is_empty())
	check(not ShopVisit.wants_visit(_rule(), 12.0, shop, broken))
	shop.day_sold = FarmShopModel.daily_sales(_rule(), 2)
	check(not ShopVisit.wants_visit(_rule(), 12.0, shop, room), "custom used up")

func test_callers_come_now_and_then() -> void:
	var v := ShopVisit.new()
	var rng := _rng()
	var times := []
	var clock := 0
	while clock < 540:   # nine opening hours, minute by minute
		clock += 1
		if v.tick(_rule(), 1.0, true, rng):
			times.append(clock)
	check(times.size() >= 3 and times.size() <= 9, str(times))
	check(times[0] >= int(_rule().first_visit_min[0]))
	for i in range(1, times.size()):
		check(times[i] - times[i - 1] >= int(_rule().visit_gap_min[0]), str(times))
	check(not v.tick(_rule(), 500.0, false, rng))
	check_eq(v.next_in, -1.0)
	check(not v.tick(_rule(), 0.0, true, rng), "a stopped clock brings nobody")

func test_buy_takes_one_unit_and_presses_the_market() -> void:
	var shop := FarmShopModel.new()
	shop.stock = {"turnip": 2}
	var market := MarketModel.new()
	var price := FarmShopModel.unit_price(_menu(MarketModel.new()), "turnip", float(_rule().premium))
	var sale := ShopVisit.buy(shop, _menu(market), _rule(), 1)
	check_eq(sale.id, "turnip")
	check_eq(sale.money, price)
	check_eq(shop.total(), 1)
	check_eq(shop.day_sold, 1)
	check_eq(int(market.sold.turnip), 1)
	ShopVisit.buy(shop, _menu(market), _rule(), 1)
	check(ShopVisit.buy(shop, _menu(market), _rule(), 1).is_empty(), "shelves bare")

func test_day_visits_never_add_income() -> void:
	## Any number of day sales, then the night: same units, same money, same shelves as a night alone.
	var stock := {"turnip": 14, "egg": 9, "cheese": 3, "pumpkin": 6}
	var night := FarmShopModel.new()
	night.stock = stock.duplicate()
	var m1 := MarketModel.new()
	var want := night.sell_night(_menu(m1), _rule(), 2)
	for by_day in [1, 3, 7, 16, 40]:
		var shop := FarmShopModel.new()
		shop.stock = stock.duplicate()
		var market := MarketModel.new()
		var money := 0
		var units := 0
		for i in by_day:
			var s := ShopVisit.buy(shop, _menu(market), _rule(), 2)
			if not s.is_empty():
				money += int(s.money)
				units += 1
		check(units <= FarmShopModel.daily_sales(_rule(), 2))
		var rest := shop.sell_night(_menu(market), _rule(), 2)
		check_eq(units + int(rest.units), int(want.units), "units after %d" % by_day)
		check_eq(money + int(rest.money), int(want.money), "money after %d" % by_day)
		check_eq(shop.stock, night.stock)
		check_eq(market.sold, m1.sold)
		check_eq(shop.day_sold, 0, "a new day starts")

func test_quota_survives_save_and_load() -> void:
	var shop := FarmShopModel.new()
	shop.stock = {"turnip": 40}
	var quota := FarmShopModel.daily_sales(_rule(), 1)
	for i in quota:
		check(not ShopVisit.buy(shop, _menu(MarketModel.new()), _rule(), 1).is_empty())
	var back := FarmShopModel.new()
	back.from_dict(JSON.parse_string(JSON.stringify(shop.to_dict())))
	check_eq(back.day_sold, quota)
	check_eq(back.turn, "turnip")
	check_eq(back.stock, {"turnip": 40 - quota})
	check(ShopVisit.buy(back, _menu(MarketModel.new()), _rule(), 1).is_empty(), "reloading does not reset the day")
	check_eq(back.sell_night(_menu(MarketModel.new()), _rule(), 1).units, 0)
	check_eq(back.day_sold, 0)
	back.from_dict({"turnip": 2})   # an old save has no count
	check_eq(back.day_sold, 0)
	check_eq(back.total(), 2)

func test_trial_copy_changes_nothing() -> void:
	var shop := FarmShopModel.new()
	shop.stock = {"turnip": 5}
	shop.day_sold = 2
	var trial := shop.copy()
	trial.sell_night(_menu(MarketModel.new()), _rule(), 1)
	check_eq(shop.stock, {"turnip": 5})
	check_eq(shop.day_sold, 2)

func test_walk_enters_by_the_door_only() -> void:
	var placed := _shop_placed()
	var defs := _defs()
	var room := ShopVisit.shop_room(placed, _rooms(), defs)
	for s in 25:
		var p := ShopVisit.plan(placed, defs, room.flood, _land, 8, _rng(s))
		check(not p.is_empty())
		var route: Array = p.route
		check_eq(p.door, Vector2i(2, 3))
		var d := route.find(p.door)
		check(d >= 2, "starts well outside")
		check_eq(route[d - 1], Vector2i(2, 4), "up to the front step")
		check_eq(route[d + 1], Vector2i(2, 2), "then straight inside")
		check(String(placed.get(p.goods, "")) == "shelf", "goes to a shelf")
		check_eq((route[-1] - p.goods).length_squared(), 1, "stands beside it")
		for i in route.size():
			var c: Vector2i = route[i]
			if i > 0:
				check_eq((c - route[i - 1]).length_squared(), 1, "one tile at a time, no corner cutting")
			if i != d:
				check(not ShopVisit.is_wall(placed, defs, c), "through %s" % c)
				check_eq(room.flood.cells.has(c), i > d, "only inside after the door")
		check(ShopVisit.route_clear(placed, defs, route, p.door))

func test_walk_blocked_or_built_over() -> void:
	var placed := _shop_placed()
	var defs := _defs()
	var room := ShopVisit.shop_room(placed, _rooms(), defs)
	var step_only := func(c: Vector2i) -> bool: return c == Vector2i(2, 4)
	check(ShopVisit.plan(placed, defs, room.flood, step_only, 8, _rng()).is_empty(), "boxed in doorstep")
	var water := func(c: Vector2i) -> bool: return c.y != 4
	check(ShopVisit.plan(placed, defs, room.flood, water, 8, _rng()).is_empty(), "no dry doorstep")
	var p := ShopVisit.plan(placed, defs, room.flood, _land, 8, _rng())
	var built := placed.duplicate()
	built[Vector2i(2, 4)] = "fence"
	check(not ShopVisit.route_clear(built, defs, p.route, p.door))
	built = placed.duplicate()
	built[Vector2i(2, 3)] = "wall"
	check(not ShopVisit.route_clear(built, defs, p.route, p.door))

func test_new_station_rooms() -> void:
	var rooms := _rooms()
	for pair in [["kitchen", "stove", "table"], ["smithy", "anvil", "quench_tub"]]:
		var p := _shop_placed()
		p[Vector2i(1, 1)] = pair[1]
		p[Vector2i(2, 1)] = pair[2]
		p[Vector2i(3, 1)] = "floor"
		var r := RoomModel.judge(p, Vector2i(2, 2), rooms, _defs())
		check(r.valid, str(r.missing))
		check_eq(r.type, pair[0])
		check_eq(RoomModel.station_type(rooms, pair[1]), pair[0])
		p[Vector2i(2, 1)] = "floor"
		r = RoomModel.judge(p, Vector2i(2, 2), rooms, _defs())
		check(not r.valid)
		check_eq(r.type, pair[0])
		check_eq(r.missing, ["a " + String(_defs()[pair[2]].name)])

func test_every_room_has_a_sign_frame_and_art() -> void:
	var sheet: Texture2D = load("res://assets/sprites/room_signs.png")
	check_eq(sheet.get_width(), 20 * _rooms().size())
	for id in ["stove", "table", "anvil", "quench_tub"]:
		check(ResourceLoader.exists("res://assets/sprites/%s.png" % _defs()[id].sprite), id)
