class_name ShopView
extends CanvasLayer
## Text shop window: W/S move, A/D switch Sell/Buy, E or F confirm, Esc closes.

signal closed
var menu: ShopMenu
var label: Label
var panel: ColorRect
var msg := ""

func _init() -> void:
	layer = 8
	menu = ShopMenu.new(DataDB.load_json("items"))
	panel = ColorRect.new()
	panel.color = Color(0.08, 0.06, 0.04, 0.88)
	panel.position = Vector2(150, 50)
	panel.size = Vector2(340, 250)
	add_child(panel)
	label = Label.new()
	label.position = Vector2(12, 8)
	panel.add_child(label)
	visible = false

func open() -> void:
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
	elif e.is_action_pressed("move_up"):
		menu.move(-1, GameState.bag)
	elif e.is_action_pressed("move_down"):
		menu.move(1, GameState.bag)
	elif e.is_action_pressed("move_left") or e.is_action_pressed("move_right"):
		menu.switch_tab()
	elif e.is_action_pressed("interact") or e.is_action_pressed("use_tool"):
		var r := menu.confirm(GameState.bag, GameState.money)
		GameState.money = r.money
		msg = r.msg

func _process(_d: float) -> void:
	if not visible:
		return
	var t := "SELL" if menu.tab == ShopMenu.Tab.SELL else "BUY"
	var lines := ["Market stall   [%s]   $%d" % [t, GameState.money], "A/D tab  W/S move  E confirm  Esc close", ""]
	var e := menu.entries(GameState.bag)
	if e.is_empty():
		lines.append("(nothing to %s)" % t.to_lower())
	for i in e.size():
		lines.append("%s %s  $%d  x%d" % [">" if i == menu.cursor else " ", e[i].name, e[i].price, e[i].count])
	lines.append("")
	lines.append(msg)
	label.text = "\n".join(lines)
