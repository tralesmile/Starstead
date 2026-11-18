class_name MarketModel
extends RefCounted
## Sell pressure + daily demand (E8). The first FREE_UNITS of an item sell at full price each day,
## every extra unit lowers the price by STEP down to FLOOR, and half of the glut is forgotten overnight.
## A small deterministic daily demand wobble (+-DEMAND_SWING) makes some days better for some goods.

const FREE_UNITS := 4
const STEP := 0.03
const FLOOR := 0.55
const DEMAND_SWING := 0.08
const OVERNIGHT_KEEP := 0.25   # fraction of today's glut that is still remembered tomorrow

var sold: Dictionary = {}   # item id -> units sold today

static func pressure(units_sold: int) -> float:
	return maxf(FLOOR, 1.0 - STEP * maxi(0, units_sold - FREE_UNITS))

static func demand(id: String, day: int) -> float:
	## Deterministic in [1-SWING, 1+SWING], stepped in 2% slices so prices stay readable.
	var h: int = absi(hash(id + ":" + str(day))) % 9
	return 1.0 + (float(h - 4) / 4.0) * DEMAND_SWING

func factor(id: String, day: int) -> float:
	return pressure(int(sold.get(id, 0))) * demand(id, day)

func price(base: int, id: String, day: int) -> int:
	return maxi(1, int(round(base * factor(id, day))))

func record(id: String, n: int = 1) -> void:
	sold[id] = int(sold.get(id, 0)) + n

func new_day() -> void:
	var out := {}
	for k in sold:
		var left := int(floor(float(sold[k]) * OVERNIGHT_KEEP))
		if left > 0:
			out[k] = left
	sold = out

func trend(id: String, day: int) -> String:
	## Short tag for the shop list: "+" good day, "-" glut or poor demand.
	var f := factor(id, day)
	if f >= 1.04:
		return "+"
	if f <= 0.96:
		return "-"
	return ""

func to_dict() -> Dictionary:
	return sold.duplicate()

func from_dict(d: Dictionary) -> void:
	sold = {}
	for k in d:
		sold[str(k)] = int(d[k])
