class_name Shop
extends RefCounted
## Pure shop logic: sell items at items.json price, buy seeds/tools. Returns new money (or -1 on failure).

const BUY_MARKUP := 1.0
const SELL_RATE := 1.0

static func sell(inv: Inventory, items: Dictionary, id: String, n: int, money: int) -> int:
	if not items.has(id) or not inv.remove(id, n):
		return -1
	return money + int(items[id].price * SELL_RATE) * n

static func buy(inv: Inventory, items: Dictionary, id: String, n: int, money: int) -> int:
	if not items.has(id):
		return -1
	var cost := int(items[id].price * BUY_MARKUP) * n
	if cost > money or inv.add(id, n) > 0:
		return -1
	return money - cost
