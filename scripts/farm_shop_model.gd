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
var day_sold := 0   # of today's customer quota, already bought by day shoppers (saved with the stock)
var turn := ""      # item the last customer took; the next one takes the next kind

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

static func quota_left(type: Dictionary, shelves: int, sold: int) -> int:
	return maxi(daily_sales(type, shelves) - sold, 0)

func next_id() -> String:
	## Customers take one of each kind in turn: the first kind after the last one taken, else round again.
	var ids := stock.keys()
	ids.sort()
	for id in ids:
		if String(id) > turn:
			return id
	return "" if ids.is_empty() else String(ids[0])

func sell_one(menu: ShopMenu, premium: float) -> Dictionary:
	## One customer buys one unit: {"id", "money"}, or {} from empty shelves. Does not touch the quota.
	var id := next_id()
	if id == "":
		return {}
	var money := unit_price(menu, id, premium)
	if menu.market != null:
		menu.market.record(id, 1)
	stock[id] = int(stock[id]) - 1
	if stock[id] <= 0:
		stock.erase(id)
	turn = id
	return {"id": id, "money": money}

func sell_night(menu: ShopMenu, type: Dictionary, shelves: int) -> Dictionary:
	## The rest of the day's quota (less what day shoppers bought) shops now; then a new day starts.
	var left := quota_left(type, shelves, day_sold)
	var money := 0
	var units := 0
	while left > 0 and not stock.is_empty():
		money += int(sell_one(menu, float(type.premium)).money)
		units += 1
		left -= 1
	new_day()
	return {"money": money, "units": units}

func new_day() -> void:
	day_sold = 0
	turn = ""

func copy() -> FarmShopModel:
	var out := FarmShopModel.new()
	out.stock = stock.duplicate()
	out.day_sold = day_sold
	out.turn = turn
	return out

func to_dict() -> Dictionary:
	var out := stock.duplicate()
	if day_sold > 0:   # keys with "_" are not goods
		out["_day_sold"] = day_sold
		out["_turn"] = turn
	return out

func from_dict(d: Dictionary) -> void:
	stock = {}
	day_sold = maxi(int(d.get("_day_sold", 0)), 0)
	turn = str(d.get("_turn", ""))
	for k in d:
		if not str(k).begins_with("_") and int(d[k]) > 0:
			stock[str(k)] = int(d[k])
