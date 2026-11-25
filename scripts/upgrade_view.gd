class_name UpgradeView
extends CanvasLayer
## Town Hall builder: buy the next tier of a farmhouse upgrade (click a row or press its number).

signal closed
signal bought(name: String)
var canvas: Control
var msg := ""
const ORIGIN := Vector2(150, 70)
const ROW := 44.0

func _init() -> void:
	layer = 9
	canvas = Control.new()
	canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.draw.connect(_draw_all)
	add_child(canvas)
	visible = false

func open() -> void:
	visible = true
	msg = ""

func close() -> void:
	visible = false
	closed.emit()

func _process(_d: float) -> void:
	if visible:
		canvas.size = get_viewport().get_visible_rect().size
		canvas.queue_redraw()

func _try(i: int) -> void:
	var h: HomeUpgrades = GameState.home
	var ids := h.ids()
	if i < 0 or i >= ids.size():
		return
	var id: String = ids[i]
	var r := h.buy(id, GameState.money)
	if r["ok"]:
		GameState.money = r["cash"]
		GameState.bag.ensure_size(h.bag_slots())
		GameState.bump("home_upgrades")
		msg = "Built: %s tier %d" % [h.defs[id]["name"], r["level"]]
		bought.emit(String(h.defs[id]["name"]))
	elif r["why"] == "maxed":
		msg = "Fully built"
	else:
		msg = "Needs $%d" % h.next_cost(id)

func handle(e: InputEvent) -> bool:
	if not visible:
		return false
	if e.is_action_pressed("pause") or e.is_action_pressed("inventory") or e.is_action_pressed("interact"):
		close()
		return true
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		var p := canvas.get_local_mouse_position() - ORIGIN
		if p.x >= 0.0 and p.x < 340.0 and p.y >= 0.0:
			_try(int(p.y / ROW))
	elif e is InputEventKey and e.pressed and not e.echo:
		var k := TargetMath.key_slot(e.keycode)
		if k >= 0:
			_try(k)
	return true

func _draw_all() -> void:
	var font := ThemeDB.fallback_font
	var h: HomeUpgrades = GameState.home
	var ids := h.ids()
	var panel := Rect2(ORIGIN - Vector2(10, 34), Vector2(360, 66.0 + ids.size() * ROW))
	canvas.draw_rect(panel.grow(2), Color(0.16, 0.1, 0.06))
	canvas.draw_rect(panel, Color(0.36, 0.24, 0.14, 0.97))
	canvas.draw_string(font, ORIGIN + Vector2(0, -16), "Halden Builders: farmhouse upgrades   Cash $%d" % GameState.money, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 0.95, 0.7))
	var hover := int((canvas.get_local_mouse_position() - ORIGIN).y / ROW) if canvas.get_local_mouse_position().x > ORIGIN.x else -1
	for i in ids.size():
		var id: String = ids[i]
		var y := ORIGIN.y + i * ROW
		var why := h.can_buy(id, GameState.money)
		canvas.draw_rect(Rect2(ORIGIN.x, y, 340, ROW - 3), Color(0.3, 0.2, 0.12, 0.95) if i != hover else Color(0.42, 0.29, 0.17, 0.95))
		canvas.draw_string(font, Vector2(ORIGIN.x + 8, y + 15), "%d. %s" % [i + 1, h.label(id)], HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1, 1, 1))
		canvas.draw_string(font, Vector2(ORIGIN.x + 8, y + 29), String(h.defs[id]["desc"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.85, 0.8, 0.7))
		var tag := "BUILT" if why == "maxed" else "$%d" % h.next_cost(id)
		canvas.draw_string(font, Vector2(ORIGIN.x + 280, y + 22), tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.6, 0.9, 0.6) if why == "" else (Color(0.7, 0.7, 0.7) if why == "maxed" else Color(0.95, 0.55, 0.5)))
	canvas.draw_string(font, ORIGIN + Vector2(0, 14 + ids.size() * ROW), msg if msg != "" else "Click an upgrade or press its number.   E / Esc: leave", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1, 1, 0.8))
