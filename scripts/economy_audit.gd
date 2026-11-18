class_name EconomyAudit
extends RefCounted
## Pure balance numbers over the data/*.json files (E8). Tests assert the ladders stay sane when data changes.

static func crop_profit_per_day(crop: Dictionary, items: Dictionary, crop_id: String) -> float:
	var seed_item: Dictionary = items[String(crop.seed)]
	var seed_cost := float(seed_item.get("buy_price", seed_item.price))
	var revenue := float(items[crop_id].price) * float(crop.yield)
	return (revenue - seed_cost) / float(crop.grow_days)

static func job_per_energy(job: Dictionary, rank: int = 0) -> float:
	var mult := float(job.ranks[rank].pay_mult)
	return float(job.pay) * mult / maxf(1.0, float(job.energy))

static func upgrade_payback_days(items: Dictionary, tier_id: String, daily_gain: float) -> float:
	## Days of extra income needed to repay a tool upgrade bought at its shop price.
	return float(items[tier_id].get("buy_price", items[tier_id].price)) / maxf(0.01, daily_gain)

static func sell_buy_gap(items: Dictionary, id: String) -> float:
	## sell/buy ratio; must be < 1 or buy-then-sell is free money.
	var it: Dictionary = items[id]
	if not it.has("buy_price"):
		return 0.0
	return float(it.price) / float(it.buy_price)

static func smelt_gain(items: Dictionary, ore: String, bar: String, ore_per_bar: int, coal_per_bar: int) -> float:
	## Value added by smelting one bar (bar price minus the ore and coal burned).
	return float(items[bar].price) - float(items[ore].price) * ore_per_bar - float(items["coal"].price) * coal_per_bar

static func glut_value(base: int, units: int, id: String, day: int) -> int:
	## Total takings for selling `units` of one item in one visit, with sell pressure.
	var m := MarketModel.new()
	var total := 0
	for i in units:
		total += m.price(base, id, day)
		m.record(id, 1)
	return total
