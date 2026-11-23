extends BaseTest

func test_buy_rules() -> void:
	var b := BusinessModel.new()
	check_eq(b.can_buy(5000, 0), "rep")
	check_eq(b.can_buy(100, 5), "cash")
	var r := b.buy(2000, 5)
	check(r.ok)
	check_eq(r.cash, 800)
	check_eq(b.level, 1)
	check_eq(b.can_buy(1000, 0), "cash")   # upgrades no longer need rep
	check(b.buy(9999, 0).ok and b.buy(9999, 0).ok)
	check_eq(b.level, 3)
	check_eq(b.can_buy(99999, 9), "maxed")

func test_profit_ladder_and_determinism() -> void:
	for d in 14:
		check_eq(BusinessModel.night_profit(2, d), BusinessModel.night_profit(2, d))
		check(BusinessModel.night_profit(1, d) < BusinessModel.night_profit(3, d))
		check(BusinessModel.night_profit(2, d, true) <= BusinessModel.night_profit(2, d, false))
	check_eq(BusinessModel.night_profit(0, 3), 0)

func test_payback_is_slow_enough() -> void:
	## Deed + upgrades must take at least 20 average days to pay back so it never beats a good farm.
	var total := 0
	for lvl in [1, 2, 3]:
		total += BusinessModel.PRICES[lvl - 1]
	var avg3 := 0.0
	for d in 28:
		avg3 += BusinessModel.night_profit(3, d)
	avg3 /= 28.0
	check(float(total) / avg3 > 20.0, "payback %.1f days" % (float(total) / avg3))

func test_till_cap_collect_and_save() -> void:
	var b := BusinessModel.new()
	b.buy(5000, 5)
	for d in 40:
		b.day_tick(d)
	check(b.till <= BusinessModel.PROFIT[1] * 2 * BusinessModel.CAP_DAYS)
	var held := b.till
	var r := b.collect(100)
	check_eq(r.cash, 100 + held)
	check_eq(b.till, 0)
	var c := BusinessModel.new()
	c.from_dict(b.to_dict())
	check_eq(c.level, 1)
	check_eq(c.total_earned, b.total_earned)
