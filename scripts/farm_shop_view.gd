class_name FarmShopView
extends CanvasLayer
## The counter of your own Farm Shop: left your sellable goods, right the shelves. Click (or Enter / F) moves one,
## Shift moves the whole stack; arrows choose; E / Esc closes. Rules and layout live in FarmShopModel.

signal closed
var canvas: Control
var items: Dictionary = DataDB.load_json("items")
var icons: Dictionary = DataDB.load_json("item_icons")
var item_tex: Texture2D = load("res://assets/sprites/items.png")
var rules: Dictionary = DataDB.load_json("rooms")["shop"]
var menu: ShopMenu
var shelves := 1
var col := 0
var cursor := [0, 0]
var msg := ""

func _init() -> void:
	layer = 9
	menu = ShopMenu.new(items)
	menu.planets = DataDB.load_json("planets")
	canvas = Control.new()
	canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	canvas.draw.connect(_draw_all)
	add_child(canvas)
	visible = false

static func price_menu(m: ShopMenu, market: MarketModel, day: int) -> ShopMenu:
	## The stall's price rules (bonuses included) against `market`.
	m.world = GameState.world
	m.market = market
	m.day = day
	m.rep_honest = GameState.rep_honest
	m.sell_bonus = GameState.home.sell_mult()
	m.perks = GameState.perks
	return m

func open(shelf_count: int) -> void:
	shelves = shelf_count
	price_menu(menu, GameState.market, GameState.clock.day)
	col = 0
	cursor = [0, 0]
	msg = ""
	visible = true

func close() -> void:
	visible = false
	closed.emit()

func ids(c: int) -> Array:
	var out := []
	if c == 0:
		for s in GameState.bag.slots:
			if s != null and FarmShopModel.allowed(items, s.id) and not s.id in out:
				out.append(s.id)
	else:
		out = GameState.farm_shop.stock.keys()
	out.sort()
	return out

func transfer(c: int, i: int, all: bool) -> void:
	var list := ids(c)
	if i < 0 or i >= list.size():
		return
	var id: String = list[i]
	var shop: FarmShopModel = GameState.farm_shop
	if c == 0:
		var n := shop.add(items, GameState.bag, id, GameState.bag.count(id) if all else 1, int(rules.stock_cap))
		msg = "Shelved %d %s" % [n, items[id].name] if n > 0 else "The shelves are full (%d)" % int(rules.stock_cap)
	else:
		var n := shop.take(GameState.bag, id, int(shop.stock.get(id, 0)) if all else 1)
		msg = "Took back %d %s" % [n, items[id].name] if n > 0 else "Your bag is full"

func _row_at(p: Vector2) -> Vector2i:
	for c in 2:
		var first := ShopMenu.first_row(cursor[c], ids(c).size(), FarmShopModel.ROWS)
		for i in FarmShopModel.ROWS:
			if FarmShopModel.row_rect(c, i).has_point(p) and first + i < ids(c).size():
				return Vector2i(c, first + i)
	return Vector2i(-1, -1)

func handle(e: InputEvent) -> void:
	if e.is_action_pressed("pause") or e.is_action_pressed("interact") or e.is_action_pressed("inventory"):
		close()
		return
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		var at := _row_at(canvas.get_local_mouse_position())
		if at.x >= 0:
			col = at.x
			cursor[col] = at.y
			transfer(col, at.y, e.shift_pressed)
	elif e.is_action_pressed("move_left") or e.is_action_pressed("move_right"):
		col = 1 - col
	elif e.is_action_pressed("move_up", true) or e.is_action_pressed("move_down", true):
		var n := ids(col).size()
		cursor[col] = 0 if n == 0 else posmod(cursor[col] + (-1 if e.is_action_pressed("move_up", true) else 1), n)
	elif e.is_action_pressed("use_tool") or (e is InputEventKey and e.pressed and not e.echo and (e.keycode == KEY_ENTER or e.keycode == KEY_KP_ENTER)):
		transfer(col, cursor[col], e is InputEventWithModifiers and e.shift_pressed)

func _process(_d: float) -> void:
	if visible:
		canvas.size = get_viewport().get_visible_rect().size
		canvas.queue_redraw()

func _tonight() -> Dictionary:
	## What the customers would pay tonight, worked out on copies so nothing changes.
	var trial: FarmShopModel = GameState.farm_shop.copy()
	var market := MarketModel.new()
	market.sold = GameState.market.sold.duplicate()
	return trial.sell_night(price_menu(ShopMenu.new(items), market, GameState.clock.day), rules, shelves)

func _draw_all() -> void:
	WoodUI.panel(canvas, FarmShopModel.BOX, "Your Farm Shop", WoodUI.Trim.GINGHAM)
	WoodUI.plank_note(canvas, FarmShopModel.BOX, "$%d" % GameState.money)
	var shop: FarmShopModel = GameState.farm_shop
	var heads := ["Your bag (what customers buy)", "On the shelves  %d/%d" % [shop.total(), int(rules.stock_cap)]]
	var hover := _row_at(canvas.get_local_mouse_position())
	for c in 2:
		WoodUI.text(canvas, Vector2(FarmShopModel.COL_X[c], FarmShopModel.LIST_Y - 8), heads[c], 11)
		var list := ids(c)
		var first := ShopMenu.first_row(cursor[c], list.size(), FarmShopModel.ROWS)
		for i in mini(FarmShopModel.ROWS, list.size() - first):
			var id: String = list[first + i]
			var r := FarmShopModel.row_rect(c, i)
			WoodUI.row(canvas, r, hover == Vector2i(c, first + i) or (col == c and cursor[c] == first + i), true)
			canvas.draw_texture_rect_region(item_tex, Rect2(r.position + Vector2(3, 2), Vector2(16, 16)), Rect2(int(icons.get(id, 0)) * 16, 0, 16, 16))
			var n: int = GameState.bag.count(id) if c == 0 else int(shop.stock[id])
			WoodUI.text(canvas, r.position + Vector2(24, 14), "%s x%d" % [items[id].name, n], 10, WoodUI.INK, r.size.x - 72)
			WoodUI.text(canvas, r.position + Vector2(0, 14), "$%d" % FarmShopModel.unit_price(menu, id, float(rules.premium)), 10, WoodUI.PRICE, r.size.x - 5, HORIZONTAL_ALIGNMENT_RIGHT)
		if list.is_empty():
			WoodUI.text(canvas, Vector2(FarmShopModel.COL_X[c] + 4, FarmShopModel.LIST_Y + 16), "Nothing to sell in your bag" if c == 0 else "The shelves are empty", 10, WoodUI.INK_SOFT)
		if list.size() > FarmShopModel.ROWS:
			WoodUI.text(canvas, Vector2(FarmShopModel.COL_X[c], FarmShopModel.LIST_Y - 8), "%d-%d of %d" % [first + 1, first + FarmShopModel.ROWS, list.size()], 9, WoodUI.INK_SOFT, FarmShopModel.COL_W, HORIZONTAL_ALIGNMENT_RIGHT)
	var t := _tonight()
	var y := FarmShopModel.LIST_Y + FarmShopModel.ROWS * FarmShopModel.ROW_H
	WoodUI.text(canvas, Vector2(70, y + 11), "Tonight: up to %d sales (%d bought by day). Expected: %d for $%d" % [FarmShopModel.quota_left(rules, shelves, shop.day_sold), shop.day_sold, t.units, t.money], 10, WoodUI.GOOD, 500)
	WoodUI.text(canvas, Vector2(70, y + 24), msg if msg != "" else "%d%% over the stall price. Shoppers call by day, the rest at night. More shelves, more custom." % roundi((float(rules.premium) - 1.0) * 100.0), 10, WoodUI.INK, 500)
	WoodUI.text(canvas, Vector2(70, y + 36), "Click / F / Enter: move one (Shift: stack)   Arrows: choose   E / Esc: close", 9, WoodUI.INK_SOFT, 500)
