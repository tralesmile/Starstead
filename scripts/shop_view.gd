class_name ShopView
extends CanvasLayer
## Wooden shop window with item icons: W/S move, A/D switch Sell/Buy, E or F confirm, Esc closes.
## Long lists scroll (ShopMenu.first_row).

signal closed
var menu: ShopMenu
var canvas: Control
var msg := ""
var icons: Dictionary = DataDB.load_json("item_icons")
var item_tex: Texture2D = load("res://assets/sprites/items.png")
const BOX := ShopMenu.BOX
const ROW_H := ShopMenu.ROW_H
const WOOD_D := Color(0.36, 0.21, 0.10)
const WOOD := Color(0.55, 0.34, 0.17)
const WOOD_L := Color(0.73, 0.49, 0.26)
const INK := Color(0.24, 0.15, 0.08)
const PAPER := Color(0.94, 0.87, 0.68)

func _init() -> void:
	layer = 8
	menu = ShopMenu.new(DataDB.load_json("items"))
	menu.planets = DataDB.load_json("planets")
	canvas = Control.new()
	canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	canvas.draw.connect(_draw_all)
	add_child(canvas)
	visible = false

func open() -> void:
	menu.world = GameState.world
	menu.market = GameState.market
	menu.day = GameState.clock.day
	menu.rep_honest = GameState.rep_honest
	menu.sell_bonus = GameState.home.sell_mult()
	menu.perks = GameState.perks
	menu.tab = ShopMenu.Tab.SELL
	menu.cursor = 0
	msg = ""
	visible = true

func close() -> void:
	visible = false
	closed.emit()

func _unhandled_input(e: InputEvent) -> void:
	if not visible:
		return
	get_viewport().set_input_as_handled()
	if e.is_action_pressed("pause"):
		close()
	elif e.is_action_pressed("move_up", true):
		menu.move(-1, GameState.bag)
	elif e.is_action_pressed("move_down", true):
		menu.move(1, GameState.bag)
	elif e.is_action_pressed("move_left") or e.is_action_pressed("move_right"):
		menu.switch_tab()
	elif e.is_action_pressed("interact") or e.is_action_pressed("use_tool"):
		var r := menu.confirm(GameState.bag, GameState.money)
		GameState.money = r.money
		msg = r.msg

func _process(_d: float) -> void:
	if visible:
		canvas.size = get_viewport().get_visible_rect().size
		canvas.queue_redraw()

func _text(at: Vector2, s: String, size: int, col: Color, width: float = -1.0, align: int = HORIZONTAL_ALIGNMENT_LEFT) -> void:
	canvas.draw_string(ThemeDB.fallback_font, at, s, align, width, size, col)

func _draw_all() -> void:
	canvas.draw_rect(Rect2(Vector2.ZERO, canvas.size), Color(0, 0, 0, 0.35))
	canvas.draw_rect(BOX.grow(6), Color(0.13, 0.08, 0.04))
	canvas.draw_rect(BOX.grow(5), WOOD)
	canvas.draw_rect(Rect2(BOX.position - Vector2(5, 5), Vector2(BOX.size.x + 10, 2)), WOOD_L)
	canvas.draw_rect(Rect2(Vector2(BOX.position.x - 5, BOX.end.y + 3), Vector2(BOX.size.x + 10, 2)), WOOD_D)
	canvas.draw_rect(BOX, PAPER)
	# striped market awning
	for i in 18:
		var col := Color(0.76, 0.24, 0.18) if i % 2 == 0 else Color(0.96, 0.92, 0.8)
		var x := BOX.position.x + i * 20.0
		canvas.draw_rect(Rect2(x, BOX.position.y, 20, 8), col)
		canvas.draw_circle(Vector2(x + 10, BOX.position.y + 8), 5.0, col)
	_text(BOX.position + Vector2(12, 30), "Market stall", 14, INK)
	_text(BOX.position + Vector2(0, 30), "$%d" % GameState.money, 13, Color(0.45, 0.29, 0.02), BOX.size.x - 12, HORIZONTAL_ALIGNMENT_RIGHT)
	for k in 2:
		var tab := Rect2(BOX.position + Vector2(12 + k * 62, 38), Vector2(58, 17))
		var on := menu.tab == k
		canvas.draw_rect(tab, WOOD if on else PAPER.darkened(0.14))
		canvas.draw_rect(tab, WOOD_D, false, 1.0)
		_text(tab.position + Vector2(0, 13), ["SELL", "BUY"][k], 11, Color(1, 0.94, 0.72) if on else INK, tab.size.x, HORIZONTAL_ALIGNMENT_CENTER)
	var e := menu.entries(GameState.bag)
	var top := ShopMenu.first_row(menu.cursor, e.size())
	var y0 := BOX.position.y + 61.0
	if e.is_empty():
		_text(Vector2(BOX.position.x, y0 + 60), "Nothing to %s yet" % ("sell" if menu.tab == ShopMenu.Tab.SELL else "buy"), 12, INK, BOX.size.x, HORIZONTAL_ALIGNMENT_CENTER)
	for n in mini(ShopMenu.ROWS, e.size() - top):
		var it: Dictionary = e[top + n]
		var r := Rect2(BOX.position.x + 8, y0 + n * ROW_H, BOX.size.x - 16, ROW_H - 1)
		canvas.draw_rect(r, Color(0.45, 0.28, 0.1, 0.09) if (top + n) % 2 == 0 else Color(0, 0, 0, 0))
		if top + n == menu.cursor:
			canvas.draw_rect(r, Color(1.0, 0.78, 0.25, 0.55))
			canvas.draw_rect(r, WOOD_D, false, 1.0)
		canvas.draw_texture_rect_region(item_tex, Rect2(r.position + Vector2(4, 1), Vector2(16, 16)), Rect2(int(icons.get(it.id, 0)) * 16, 0, 16, 16))
		_text(r.position + Vector2(26, 13), String(it.name), 11, INK, 188)
		_text(r.position + Vector2(216, 13), "x%d" % int(it.count) if int(it.count) > 0 else "", 10, Color(0.42, 0.3, 0.18))
		var trend := str(it.get("trend", ""))
		if trend != "":
			_text(r.position + Vector2(262, 13), trend, 12, Color(0.16, 0.5, 0.14) if trend == "+" else Color(0.72, 0.18, 0.12))
		_text(r.position + Vector2(0, 13), "$%d" % int(it.price), 11, Color(0.45, 0.29, 0.02), r.size.x - 6, HORIZONTAL_ALIGNMENT_RIGHT)
	var mid := BOX.position.x + BOX.size.x * 0.5
	if top > 0:
		canvas.draw_colored_polygon(PackedVector2Array([Vector2(mid - 6, y0 - 1), Vector2(mid + 6, y0 - 1), Vector2(mid, y0 - 6)]), WOOD_D)
	if top + ShopMenu.ROWS < e.size():
		var yb := y0 + ShopMenu.ROWS * ROW_H + 1
		canvas.draw_colored_polygon(PackedVector2Array([Vector2(mid - 6, yb), Vector2(mid + 6, yb), Vector2(mid, yb + 5)]), WOOD_D)
	if not e.is_empty():
		_text(Vector2(BOX.position.x + 12, BOX.end.y - 22), "%d / %d" % [menu.cursor + 1, e.size()], 9, Color(0.42, 0.3, 0.18))
	_text(Vector2(BOX.position.x, BOX.end.y - 22), msg, 11, Color(0.3, 0.35, 0.05), BOX.size.x, HORIZONTAL_ALIGNMENT_CENTER)
	_text(Vector2(BOX.position.x, BOX.end.y - 7), "A/D tab    W/S move    E confirm    Esc close", 10, INK, BOX.size.x, HORIZONTAL_ALIGNMENT_CENTER)
