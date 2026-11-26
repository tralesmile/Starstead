extends BaseTest

func test_small_game_is_free() -> void:
	var r := RangerModel.new()
	var o := r.on_kill("rabbit", 1)
	check(o["legal"])
	check_eq(r.heat, 0)

func test_poaching_fines_on_third_kill_and_resets() -> void:
	var r := RangerModel.new()
	check(not r.on_kill("deer", 1)["legal"])
	check(not r.on_kill("boar", 1)["fine_due"])
	check(r.on_kill("deer", 1)["fine_due"])
	check_eq(r.heat, 0)
	check_eq(RangerModel.fine_amount(40), 40)
	check_eq(RangerModel.fine_amount(900), RangerModel.FINE)

func test_licence_bag_limit_and_expiry() -> void:
	var r := RangerModel.new()
	var b := r.buy(1, 500)
	check(b["ok"])
	check_eq(b["cash"], 500 - RangerModel.LICENCE_COST)
	check(r.licensed(RangerModel.LICENCE_DAYS))
	check(not r.licensed(RangerModel.LICENCE_DAYS + 1))
	for i in RangerModel.BAG_LIMIT:
		check(r.on_kill("deer", 2)["legal"])
	check(not r.on_kill("deer", 2)["legal"])
	check(r.on_kill("deer", 3)["legal"], "limit resets each day")

func test_buy_needs_money_and_stacks_once() -> void:
	var r := RangerModel.new()
	check(not r.buy(1, 10)["ok"])
	check(r.buy(1, 900)["ok"])
	check(r.buy(1, 900)["ok"])
	check_eq(r.days_left(1), RangerModel.LICENCE_DAYS * 2)
	check(not r.buy(1, 900)["ok"])

func test_cooling_and_save() -> void:
	var r := RangerModel.new()
	r.on_kill("deer", 1)
	r.new_day()
	check_eq(r.heat, RangerModel.POACH_HEAT - RangerModel.NIGHT_COOL)
	var s := RangerModel.new()
	s.from_dict(r.to_dict())
	check_eq(s.heat, r.heat)
	check_eq(s.taken_day, 1)
