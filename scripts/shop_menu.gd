class_name ShopMenu
extends RefCounted
## Pure shop menu state: SELL tab lists what you carry, BUY tab lists seeds. Cursor + confirm use Shop.

enum Tab { SELL, BUY }

var tab: int = Tab.SELL
var cursor := 0
var items: Dictionary

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
			out.append({"id": id, "name": items[id].name, "price": int(items[id].price), "count": n})
		elif tab == Tab.BUY and bool(items[id].get("buy", false)):
			out.append({"id": id, "name": items[id].name, "price": Shop.buy_price(items, id), "count": n})
	return out

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
	var m := Shop.sell(inv, items, id, 1, money) if tab == Tab.SELL else Shop.buy(inv, items, id, 1, money)
	if m < 0:
		return {"money": money, "msg": "Cannot afford" if tab == Tab.BUY else "Cannot sell"}
	cursor = clampi(cursor, 0, maxi(entries(inv).size() - 1, 0))
	var verb := "Sold " if tab == Tab.SELL else "Bought "
	return {"money": m, "msg": verb + String(items[id].name)}
