class_name Shop
extends RefCounted
## Pure shop logic: sell items at items.json price, buy seeds/tools. Returns new money (or -1 on failure).

const BUY_MARKUP := 1.0
const SELL_RATE := 1.0

static func mult(planets: Dictionary, world: String, kind: String, id: String) -> float:
	## Interplanetary trade hook (DESIGN differentiator 1): per-world multiplier, item override else default.
	var m: Dictionary = planets.get(world, {}).get(kind, {})
	return float(m.get(id, m.get("default", 1.0)))

static func sell_price(items: Dictionary, id: String, planets: Dictionary = {}, world: String = "earth") -> int:
	return int(round(items[id].price * SELL_RATE * mult(planets, world, "sell_mult", id)))

static func sell(inv: Inventory, items: Dictionary, id: String, n: int, money: int, planets: Dictionary = {}, world: String = "earth") -> int:
	if not items.has(id) or not inv.remove(id, n):
		return -1
	return money + sell_price(items, id, planets, world) * n

static func buy(inv: Inventory, items: Dictionary, id: String, n: int, money: int, planets: Dictionary = {}, world: String = "earth") -> int:
	if not items.has(id):
		return -1
	var cost := buy_price(items, id, planets, world) * n
	if cost > money or inv.add(id, n) > 0:
		return -1
	return money - cost

static func buy_price(items: Dictionary, id: String, planets: Dictionary = {}, world: String = "earth") -> int:
	## Explicit buy_price wins (e.g. wood is dearer to buy than to sell); else price * markup.
	var it: Dictionary = items[id]
	var base: float = float(it.get("buy_price", int(it.price * BUY_MARKUP)))
	return int(round(base * mult(planets, world, "buy_mult", id)))
