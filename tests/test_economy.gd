extends BaseTest

func test_pressure_curve() -> void:
	check_eq(MarketModel.pressure(0), 1.0)
	check_eq(MarketModel.pressure(MarketModel.FREE_UNITS), 1.0, "free units at full price")
	check(MarketModel.pressure(MarketModel.FREE_UNITS + 5) < 0.9)
	check_eq(MarketModel.pressure(500), MarketModel.FLOOR, "never below the floor")

func test_demand_deterministic_and_bounded() -> void:
	for d in range(1, 40):
		var f := MarketModel.demand("turnip", d)
		check(f >= 1.0 - MarketModel.DEMAND_SWING - 0.001 and f <= 1.0 + MarketModel.DEMAND_SWING + 0.001, "bounded")
		check_eq(f, MarketModel.demand("turnip", d), "deterministic")
	var seen := {}
	for d in range(1, 40):
		seen[MarketModel.demand("carp", d)] = true
	check(seen.size() >= 3, "demand varies across days")

func test_record_and_overnight_recovery() -> void:
	var m := MarketModel.new()
	m.record("turnip", 20)
	var before := m.factor("turnip", 1)
	m.new_day()
	check_eq(int(m.sold["turnip"]), 5, "quarter of the glut remembered")
	m.new_day()
	m.new_day()
	check(not m.sold.has("turnip"), "forgotten after three days")
	check(MarketModel.pressure(5) > MarketModel.pressure(20))
	check(before < 1.0)

func test_save_roundtrip() -> void:
	var m := MarketModel.new()
	m.record("milk", 7)
	var m2 := MarketModel.new()
	m2.from_dict(JSON.parse_string(JSON.stringify(m.to_dict())))
	check_eq(int(m2.sold["milk"]), 7)

func test_shop_menu_uses_market() -> void:
	var items = DataDB.load_json("items")
	var inv := Inventory.new(5, {"turnip": 99})
	inv.add("turnip", 12)
	var menu := ShopMenu.new(items)
	menu.market = MarketModel.new()
	menu.day = 1
	var money := 0
	var first := 0
	for i in 12:
		var before := money
		var r := menu.confirm(inv, money)
		money = r.money
		if i == 0:
			first = money - before
		if i == 11:
			check(money - before < first, "12th turnip sells for less than the first")
	check_eq(int(menu.market.sold["turnip"]), 12)
	var plain := ShopMenu.new(items)
	var inv2 := Inventory.new(5, {"turnip": 99})
	inv2.add("turnip", 1)
	check_eq(plain.confirm(inv2, 0).money, 24, "no market = base price")

func test_glut_is_worse_than_spreading() -> void:
	var one_day := EconomyAudit.glut_value(24, 30, "turnip", 1)
	check(one_day < 24 * 30, "dumping 30 at once pays less than list price")
	check(one_day > 24 * 30 * 0.6, "but not a punishment")

func test_crop_ladder() -> void:
	var items = DataDB.load_json("items")
	var crops = DataDB.load_json("crops")
	var lo := 1e9
	var hi := -1e9
	for id in crops:
		var p := EconomyAudit.crop_profit_per_day(crops[id], items, id)
		check(p > 2.0, "%s earns more than seeds cost" % id)
		lo = minf(lo, p)
		hi = maxf(hi, p)
	check(hi / lo < 3.0, "no crop is more than 3x better than another per day")

func test_job_ladder() -> void:
	var jobs = DataDB.load_json("jobs")
	for id in jobs:
		var prev := 0.0
		for r in jobs[id].ranks.size():
			var v := EconomyAudit.job_per_energy(jobs[id], r)
			check(v > prev, "%s rank %d pays more per energy" % [id, r])
			prev = v
		check(EconomyAudit.job_per_energy(jobs[id]) >= 1.0, "%s pays at least $1 per energy" % id)
		check(EconomyAudit.job_per_energy(jobs[id], jobs[id].ranks.size() - 1) <= 6.0, "%s top rank not absurd" % id)

func test_no_buy_sell_exploit() -> void:
	var items = DataDB.load_json("items")
	for id in items:
		if items[id].has("buy_price"):
			check(EconomyAudit.sell_buy_gap(items, id) < 1.0, "%s sells for less than it buys for" % id)

func test_tool_tiers_priced_in_order() -> void:
	var items = DataDB.load_json("items")
	for tool in ["axe", "pickaxe", "hoe", "watering_can"]:
		var c: int = items[tool + "_copper"].buy_price
		var i: int = items[tool + "_iron"].buy_price
		check(i > c, "%s iron dearer than copper" % tool)
		check(i <= 3 * c, "%s iron not absurdly dear" % tool)

func test_smelting_adds_value() -> void:
	var items = DataDB.load_json("items")
	check(EconomyAudit.smelt_gain(items, "copper_ore", "copper_bar", 2, 1) > 0.0)
	check(EconomyAudit.smelt_gain(items, "iron_ore", "iron_bar", 2, 1) > EconomyAudit.smelt_gain(items, "copper_ore", "copper_bar", 2, 1))

func test_fish_ladder() -> void:
	var fish = DataDB.load_json("fish")
	var items = DataDB.load_json("items")
	for id in fish:
		check_eq(int(items[id].price), int(fish[id].price), "%s price matches items.json" % id)
	check(int(fish.perch.price) > int(fish.minnow.price))
	check(int(fish.pike.price) > int(fish.carp.price))
	check(int(fish.golden_koi.price) > int(fish.pike.price))
