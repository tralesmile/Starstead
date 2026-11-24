extends BaseTest

func test_open_and_closed() -> void:
	check(ShopHours.is_open("city_shop", 12.0))
	check(not ShopHours.is_open("city_shop", 7.9))
	check(not ShopHours.is_open("city_shop", 20.0))
	check(not ShopHours.is_open("city_bank", 18.0))

func test_always_open_buildings() -> void:
	for id in ["city_police", "city_hospital", "farmhouse", "workshop", "barn"]:
		check(ShopHours.is_open(id, 3.0))
		check_eq(ShopHours.alarm_chance(id), 0.0)

func test_hours_are_sane() -> void:
	for id in ["city_shop", "city_cafe", "city_bank", "city_garage", "city_hall", "circ_pit", "circ_hall"]:
		check(ShopHours.has_hours(id))
		var e: Dictionary = ShopHours.cfg()[id]
		check(float(e["open"]) < float(e["close"]))
		check(int(e["till"][0]) <= int(e["till"][1]))

func test_pick_chance_skill_and_lock() -> void:
	check(ShopHours.pick_chance("city_bank", 0) < ShopHours.pick_chance("city_cafe", 0))
	check(ShopHours.pick_chance("city_shop", 8) > ShopHours.pick_chance("city_shop", 0))
	check(ShopHours.pick_chance("city_bank", 0) >= 0.05)
	check(ShopHours.pick_chance("city_cafe", 99) <= 0.9)

func test_bank_is_the_big_risky_score() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4
	check(ShopHours.alarm_chance("city_bank") > ShopHours.alarm_chance("city_shop"))
	for i in 20:
		var c := ShopHours.till_cash("city_bank", rng)
		check(c >= 300 and c <= 650)
	check_eq(ShopHours.till_cash("city_police", rng), 0)

func test_counter_turns_into_till() -> void:
	check_eq(ShopHours.counter_action("city_shop", "shop", 23.0), "till")
	check_eq(ShopHours.counter_action("city_shop", "shop", 12.0), "shop")
	check_eq(ShopHours.counter_action("city_hospital", "heal", 3.0), "heal")
	check_eq(ShopHours.counter_action("city_bank", "bank", 3.0), "till")
	check_eq(ShopHours.counter_action("city_garage", "garage", 3.0), "garage")   # lift/workbench stay usable

func test_daily_state() -> void:
	var s := {}
	check(not ShopHours.broken_in(s, "city_shop", 3))
	ShopHours.mark(s, "city_shop", "in", 3)
	check(ShopHours.broken_in(s, "city_shop", 3))
	check(not ShopHours.broken_in(s, "city_shop", 4))
	check(ShopHours.till_ready(s, "city_shop", 3))
	ShopHours.mark(s, "city_shop", "till", 3)
	check(not ShopHours.till_ready(s, "city_shop", 3))
	check(ShopHours.till_ready(s, "city_shop", 4))
