class_name FarmShopModel
extends RefCounted
## Pure rules of the player's own Farm Shop: goods move from the bag onto the shelves, customers buy a few each night.
## A unit pays the market stall's price (same bonuses and sell pressure) times a premium, and every sale counts
## as a stall sale in MarketModel. Anything a shop sells to you is refused, so there is no buy-and-resell loop.

# Stock window layout on the 640x360 screen (here so tests can check it without GameState).
const BOX := Rect2(60, 36, 520, 288)
const ROWS := 8
const ROW_H := 23.0
const COL_W := 246.0
const LIST_Y := 96.0
const COL_X := [70.0, 324.0]   # left: your bag, right: on the shelves

var stock: Dictionary = {}   # item id -> units on the shelves

static func row_rect(col: int, i: int) -> Rect2:
	return Rect2(float(COL_X[col]), LIST_Y + i * ROW_H, COL_W, ROW_H - 2.0)

static func allowed(items: Dictionary, id: String) -> bool:
	if not items.has(id):
		return false
	var it: Dictionary = items[id]
	return int(it.price) > 0 and int(it.stack) > 1 and not bool(it.get("buy", false)) and not it.has("buy_price")

func total() -> int:
	var n := 0
	for id in stock:
		n += int(stock[id])
	return n

func add(items: Dictionary, bag: Inventory, id: String, n: int, cap: int) -> int:
	## Moves up to n units from the bag to the shelves; returns how many moved.
	if not allowed(items, id):
		return 0
	var move := mini(mini(n, bag.count(id)), cap - total())
	if move <= 0 or not bag.remove(id, move):
		return 0
	stock[id] = int(stock.get(id, 0)) + move
	return move

func take(bag: Inventory, id: String, n: int) -> int:
	## Back into the bag; whatever does not fit stays on the shelf.
	var want := mini(n, int(stock.get(id, 0)))
	if want <= 0:
		return 0
	var moved := want - bag.add(id, want)
	stock[id] = int(stock[id]) - moved
	if stock[id] <= 0:
		stock.erase(id)
	return moved

static func daily_sales(type: Dictionary, shelves: int) -> int:
	return int(type.base_sales) + int(type.sales_per_shelf) * clampi(shelves, 0, int(type.max_shelves))

static func unit_price(menu: ShopMenu, id: String, premium: float) -> int:
	return int(floor(menu._sell_now(id) * premium))

func sell_night(menu: ShopMenu, type: Dictionary, shelves: int) -> Dictionary:
	## Customers take one unit of each kind in turn until the night's quota or the shelves run out.
	var left := daily_sales(type, shelves)
	var money := 0
	var units := 0
	while left > 0 and not stock.is_empty():
		var ids := stock.keys()
		ids.sort()
		for id in ids:
			if left <= 0:
				break
			money += unit_price(menu, id, float(type.premium))
			if menu.market != null:
				menu.market.record(id, 1)
			stock[id] = int(stock[id]) - 1
			if stock[id] <= 0:
				stock.erase(id)
			units += 1
			left -= 1
	return {"money": money, "units": units}

func to_dict() -> Dictionary:
	return stock.duplicate()

func from_dict(d: Dictionary) -> void:
	stock = {}
	for k in d:
		if int(d[k]) > 0:
			stock[str(k)] = int(d[k])
