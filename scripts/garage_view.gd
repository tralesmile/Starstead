class_name GarageView
extends CanvasLayer
## Workshop workbench menu: 1 repair, 2 fill the tank, 3 repaint. Pays with money.

signal closed
var canvas: Control
var car: CarView
var msg := ""
const ORIGIN := Vector2(170, 90)

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

func _do(i: int) -> void:
	var cost := 0
	match i:
		0:
			cost = GarageModel.repair_cost(car.health, VehicleMath.HEALTH_MAX)
		1:
			cost = GarageModel.fuel_cost(car.fuel, VehicleMath.FUEL_MAX)
		2:
			cost = GarageModel.PAINT_PRICE
		_:
			return
	var left := GarageModel.pay(GameState.money, cost)
	if left < 0:
		msg = "Nothing to do" if cost <= 0 else "Not enough money ($%d)" % cost
		return
	GameState.money = left
	match i:
		0:
			car.health = VehicleMath.HEALTH_MAX
			msg = "Repaired (-$%d)" % cost
		1:
			car.fuel = VehicleMath.FUEL_MAX
			msg = "Tank full (-$%d)" % cost
		2:
			GameState.car_paint = GarageModel.next_paint(GameState.car_paint)
			car.sprite.modulate = GarageModel.PAINTS[GameState.car_paint]["color"]
			msg = "Painted %s (-$%d)" % [GarageModel.PAINTS[GameState.car_paint]["name"], cost]

func handle(e: InputEvent) -> bool:
	if not visible:
		return false
	if e.is_action_pressed("pause") or e.is_action_pressed("interact"):
		close()
		return true
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		var p := canvas.get_local_mouse_position() - ORIGIN
		if p.x >= 0.0 and p.x < 300.0 and p.y >= 0.0:
			_do(int(p.y / 34.0))
	elif e is InputEventKey and e.pressed and not e.echo:
		_do(TargetMath.key_slot(e.keycode))
	return true

func _draw_all() -> void:
	var font := ThemeDB.fallback_font
	var rows := [
		["1. Repair car", "Health %d%%" % int(car.health), GarageModel.repair_cost(car.health, VehicleMath.HEALTH_MAX)],
		["2. Fill the tank", "Fuel %d%%" % int(100.0 * car.fuel / VehicleMath.FUEL_MAX), GarageModel.fuel_cost(car.fuel, VehicleMath.FUEL_MAX)],
		["3. Repaint", "Now: %s" % GarageModel.PAINTS[GameState.car_paint]["name"], GarageModel.PAINT_PRICE],
	]
	var panel := Rect2(ORIGIN - Vector2(10, 34), Vector2(320, 34.0 * rows.size() + 76.0))
	canvas.draw_rect(panel.grow(2), Color(0.16, 0.1, 0.06))
	canvas.draw_rect(panel, Color(0.3, 0.3, 0.34, 0.97))
	canvas.draw_string(font, ORIGIN + Vector2(0, -14), "Garage   $%d" % GameState.money, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 0.95, 0.7))
	for i in rows.size():
		var y := ORIGIN.y + i * 34.0
		var cost: int = rows[i][2]
		var ok := cost > 0 and cost <= GameState.money
		canvas.draw_rect(Rect2(ORIGIN.x, y, 300, 31), Color(0.2, 0.2, 0.24, 0.95))
		canvas.draw_string(font, Vector2(ORIGIN.x + 6, y + 13), rows[i][0], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1, 1, 1) if ok else Color(0.7, 0.7, 0.7))
		canvas.draw_string(font, Vector2(ORIGIN.x + 6, y + 26), rows[i][1], HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.8, 0.9, 1))
		canvas.draw_string(font, Vector2(ORIGIN.x + 220, y + 20), "$%d" % cost if cost > 0 else "-", HORIZONTAL_ALIGNMENT_RIGHT, 70, 11, Color(0.8, 1, 0.7) if ok else Color(0.7, 0.6, 0.6))
	canvas.draw_string(font, ORIGIN + Vector2(0, 34.0 * rows.size() + 12), msg if msg != "" else "Click or press a number.   E / Esc: leave", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1, 1, 0.8))
