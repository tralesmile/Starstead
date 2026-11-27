class_name GarageModel
extends RefCounted
## Pure garage prices: repairs, fuel and paint. All return the cost in money (0 = nothing to do).

const FUEL_PRICE := 1.5     # money per fuel unit
const REPAIR_PRICE := 6     # money per 1 hp
const PAINT_PRICE := 60
const PAINTS := [
	{"name": "Factory red", "color": Color(1, 1, 1)},
	{"name": "Midnight blue", "color": Color(0.55, 0.65, 1.2)},
	{"name": "Lime", "color": Color(0.8, 1.3, 0.5)},
	{"name": "Sunny yellow", "color": Color(1.3, 1.2, 0.4)},
	{"name": "Graphite", "color": Color(0.6, 0.6, 0.66)},
]

static func repair_cost(health: float, health_max: float) -> int:
	return int(ceil(maxf(health_max - health, 0.0) * REPAIR_PRICE))

static func discounted(cost: int, mult: float) -> int:
	## Repair price in your own garage; a job that costs something never becomes free.
	return 0 if cost <= 0 else maxi(1, int(ceil(cost * clampf(mult, 0.0, 1.0))))

static func fuel_cost(fuel: float, fuel_max: float) -> int:
	return int(ceil(maxf(fuel_max - fuel, 0.0) * FUEL_PRICE))

static func pay(money: int, cost: int) -> int:
	## New balance, or -1 when you cannot afford it or there is nothing to buy.
	if cost <= 0 or cost > money:
		return -1
	return money - cost

static func next_paint(i: int) -> int:
	return (i + 1) % PAINTS.size()
