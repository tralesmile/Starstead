class_name ShopMenu
extends RefCounted
## Pure shop menu state: SELL tab lists what you carry, BUY tab lists seeds. Cursor + confirm use Shop.

enum Tab { SELL, BUY }

var tab: int = Tab.SELL
var cursor := 0
var items: Dictionary
var planets: Dictionary = {}
var world := "earth"
var market: MarketModel = null   # optional sell pressure (E8)
var day := 1
var sell_bonus := 1.0   # root cellar (HomeUpgrades.sell_mult)
var perks: Dictionary = {}   # chosen skill perks (PerkModel.sell_mult)
var crops: Dictionary = DataDB.load_json("crops")
var fish: Dictionary = DataDB.load_json("fish")
var rep_honest := 0   # honest tier discounts and sell bonus (ReputationModel)

const ROWS := 9            # rows the shop window shows at once
const ROW_H := 19.0
const BOX := Rect2(140, 36, 360, 270)   # the window on the 640x360 screen

static func first_row(cursor: int, total: int, rows: int = ROWS) -> int:
	## Top entry of the scrolled list: keeps the cursor in view with a row of context either side.
	if total <= rows:
		return 0
	return clampi(cursor - rows / 2, 0, total - rows)

func _init(items_db: Dictionary) -> void:
	items = items_db

func entries(inv: Inventory) -> Array:
	## [{id, name, price, count}] for the current tab, sorted by id.
	var out := []
	var ids := items.keys()
	ids.sort()
	for id in ids:
		var n := inv.count(id)
		if tab == Tab.SELL and n > 0:
			out.append({"id": id, "name": items[id].name, "price": _sell_now(id), "count": n, "trend": "" if market == null else market.trend(id, day)})
		elif tab == Tab.BUY and bool(items[id].get("buy", false)):
			out.append({"id": id, "name": items[id].name, "price": _buy_now(id), "count": n})
	return out

func _sell_now(id: String) -> int:
	var base := Shop.sell_price(items, id, planets, world)
	var p := base if market == null else market.price(base, id, day)
	return int(round(p * ReputationModel.sell_mult(rep_honest) * sell_bonus * PerkModel.sell_mult(perks, id, crops, fish)))

func _buy_now(id: String) -> int:
	return int(round(Shop.buy_price(items, id, planets, world) * ReputationModel.buy_mult(rep_honest)))

func switch_tab() -> void:
	tab = Tab.BUY if tab == Tab.SELL else Tab.SELL
	cursor = 0

func move(d: int, inv: Inventory) -> void:
	var n := entries(inv).size()
	cursor = 0 if n == 0 else posmod(cursor + d, n)

func confirm(inv: Inventory, money: int) -> Dictionary:
	## Returns {"money": int, "msg": String}; money unchanged on failure.
	var e := entries(inv)
	if e.is_empty():
		return {"money": money, "msg": "Nothing here"}
	cursor = clampi(cursor, 0, e.size() - 1)
	var id: String = e[cursor].id
	var m := -1
	if tab == Tab.SELL:
		var p := _sell_now(id)
		if inv.remove(id, 1):
			m = money + p
			if market != null:
				market.record(id, 1)
	else:
		var cost := _buy_now(id)
		if cost <= money and inv.add(id, 1) == 0:
			m = money - cost
	if m < 0:
		return {"money": money, "msg": "Cannot afford" if tab == Tab.BUY else "Cannot sell"}
	cursor = clampi(cursor, 0, maxi(entries(inv).size() - 1, 0))
	var verb := "Sold " if tab == Tab.SELL else "Bought "
	return {"money": m, "msg": verb + String(items[id].name)}
