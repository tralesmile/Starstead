class_name GarageView
extends CanvasLayer
## Workshop workbench menu: 1 repair, 2 fill the tank, 3 repaint. Pays with money.

signal closed
var canvas: Control
var car: CarView
var msg := ""
var repair_mult := 1.0   # set by open()
const ORIGIN := Vector2(170, 90)

func _init() -> void:
	layer = 9
	canvas = Control.new()
	canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.draw.connect(_draw_all)
	add_child(canvas)
	visible = false

func open(mult: float = 1.0) -> void:
	repair_mult = mult   # below 1 only at the workbench of a garage you built
	visible = true
	msg = ""

func close() -> void:
	visible = false
	closed.emit()

func _process(_d: float) -> void:
	if visible:
		canvas.size = get_viewport().get_visible_rect().size
		canvas.queue_redraw()

func _repair_cost() -> int:
	return GarageModel.discounted(GarageModel.repair_cost(car.health, VehicleMath.HEALTH_MAX), repair_mult)

func _do(i: int) -> void:
	var cost := 0
	match i:
		0:
			cost = _repair_cost()
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
	var rows := [
		["1. Repair car" + ("  (%d%% off)" % roundi((1.0 - repair_mult) * 100.0) if repair_mult < 1.0 else ""), "Health %d%%" % int(car.health), _repair_cost(), car.health / VehicleMath.HEALTH_MAX],
		["2. Fill the tank", "Fuel %d%%" % int(100.0 * car.fuel / VehicleMath.FUEL_MAX), GarageModel.fuel_cost(car.fuel, VehicleMath.FUEL_MAX), car.fuel / VehicleMath.FUEL_MAX],
		["3. Repaint", "Now: %s" % GarageModel.PAINTS[GameState.car_paint]["name"], GarageModel.PAINT_PRICE, -1.0],
	]
	var panel := Rect2(ORIGIN - Vector2(10, 34), Vector2(320, 34.0 * rows.size() + 60.0))
	WoodUI.panel(canvas, panel, "Your garage" if repair_mult < 1.0 else "Garage", WoodUI.Trim.HAZARD)
	WoodUI.text(canvas, panel.position + Vector2(0, 15), "$%d" % GameState.money, 12, WoodUI.CREAM, panel.size.x - 10, HORIZONTAL_ALIGNMENT_RIGHT)
	var mouse := canvas.get_local_mouse_position() - ORIGIN
	var hover := int(mouse.y / 34.0) if mouse.x >= 0.0 and mouse.x < 300.0 and mouse.y >= 0.0 else -1
	for i in rows.size():
		var y := ORIGIN.y + i * 34.0
		var cost: int = rows[i][2]
		var ok := cost > 0 and cost <= GameState.money
		WoodUI.row(canvas, Rect2(ORIGIN.x, y, 300, 31), i == hover, ok)
		WoodUI.text(canvas, Vector2(ORIGIN.x + 6, y + 13), rows[i][0], 11, WoodUI.INK if ok else WoodUI.INK_SOFT)
		WoodUI.text(canvas, Vector2(ORIGIN.x + 6, y + 26), rows[i][1], 9, WoodUI.INK_SOFT)
		var level: float = rows[i][3]
		if level >= 0.0:   # a gauge for health and fuel
			var bar := Rect2(ORIGIN.x + 100, y + 19, 110, 7)
			canvas.draw_rect(bar.grow(1), WoodUI.WOOD_D)
			canvas.draw_rect(bar, WoodUI.PAPER.darkened(0.3))
			canvas.draw_rect(Rect2(bar.position, Vector2(bar.size.x * clampf(level, 0.0, 1.0), bar.size.y)), Color(0.85, 0.28, 0.18) if level < 0.3 else Color(0.35, 0.66, 0.22))
		else:
			canvas.draw_rect(Rect2(ORIGIN.x + 99, y + 18, 16, 9), WoodUI.WOOD_D)
			canvas.draw_rect(Rect2(ORIGIN.x + 100, y + 19, 14, 7), GarageModel.PAINTS[GameState.car_paint]["color"])
		WoodUI.text(canvas, Vector2(ORIGIN.x + 220, y + 20), "$%d" % cost if cost > 0 else "-", 11, WoodUI.PRICE if ok else (WoodUI.BAD if cost > 0 else WoodUI.INK_SOFT), 70, HORIZONTAL_ALIGNMENT_RIGHT)
	WoodUI.text(canvas, ORIGIN + Vector2(0, 34.0 * rows.size() + 16), msg if msg != "" else "Click or press a number.   E / Esc: leave", 10, WoodUI.GOOD if msg != "" else WoodUI.INK)
