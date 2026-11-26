class_name BusView
extends CanvasLayer
## Bus stop menu: pick a destination (number or click); pays the fare, waits for the next bus, rides there.

signal closed
signal ride(stop: Dictionary, fare: int, minutes: int)
var canvas: Control
var rows: Array = []
var here_name := ""
var wait_min := 0
var msg := ""

func _init() -> void:
	layer = 9
	canvas = Control.new()
	canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.draw.connect(_draw_all)
	add_child(canvas)
	visible = false

func open(here_stop: Dictionary, options: Array, wait: int) -> void:
	rows = options
	here_name = String(here_stop["name"])
	wait_min = wait
	msg = ""
	visible = true

func close() -> void:
	visible = false
	closed.emit()

func _process(_d: float) -> void:
	if visible:
		canvas.size = get_viewport().get_visible_rect().size
		canvas.queue_redraw()

func _try(i: int) -> void:
	if i < 0 or i >= rows.size():
		return
	var r: Dictionary = rows[i]
	if not bool(r["ok"]):
		msg = "Cannot go there: " + String(r["why"])
		return
	visible = false
	ride.emit(r, int(r["fare"]), int(r["minutes"]) + wait_min)
	closed.emit()

func handle(e: InputEvent) -> bool:
	if not visible:
		return false
	if e.is_action_pressed("pause") or e.is_action_pressed("inventory") or e.is_action_pressed("interact"):
		close()
		return true
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		_try(WoodUI.bus_row_at(canvas.get_local_mouse_position(), rows.size()))
	elif e is InputEventKey and e.pressed and not e.echo:
		var k := TargetMath.key_slot(e.keycode)
		if k >= 0:
			_try(k)
	return true

func _draw_all() -> void:
	var panel := WoodUI.bus_window(rows.size())
	WoodUI.panel(canvas, panel, "Bus stop: %s" % here_name, WoodUI.Trim.HAZARD)
	WoodUI.plank_note(canvas, panel, "next bus in %d min" % wait_min)
	var hover := WoodUI.bus_row_at(canvas.get_local_mouse_position(), rows.size())
	for i in rows.size():
		var r: Dictionary = rows[i]
		var rr := WoodUI.bus_row_rect(i)
		var o := rr.position
		var ok := bool(r["ok"])
		WoodUI.row(canvas, rr, i == hover, ok)
		WoodUI.icon_well(canvas, Rect2(o + Vector2(3, 3), Vector2(21, 21)))
		WoodUI.text(canvas, o + Vector2(3, 18), str((i + 1) % 10), 11, WoodUI.INK if ok else WoodUI.INK_SOFT, 21, HORIZONTAL_ALIGNMENT_CENTER)
		WoodUI.text(canvas, o + Vector2(32, 18), String(r["name"]), 12, WoodUI.INK if ok else WoodUI.INK_SOFT, 178)
		if ok:
			WoodUI.text(canvas, o + Vector2(214, 18), "$%d" % r["fare"], 11, WoodUI.PRICE, 50, HORIZONTAL_ALIGNMENT_RIGHT)
			WoodUI.text(canvas, o + Vector2(268, 18), "%d min" % (int(r["minutes"]) + wait_min), 11, WoodUI.INK, rr.size.x - 276, HORIZONTAL_ALIGNMENT_RIGHT)
		else:
			WoodUI.text(canvas, o + Vector2(214, 18), String(r["why"]), 11, WoodUI.BAD, rr.size.x - 222, HORIZONTAL_ALIGNMENT_RIGHT)
	var fy := WoodUI.BUS_ORIGIN.y + rows.size() * WoodUI.BUS_ROW
	var w := WoodUI.BUS_W
	WoodUI.text(canvas, Vector2(WoodUI.BUS_ORIGIN.x, fy + 13), msg if msg != "" else "Fares by distance. Buses every 30 min, 06:00-23:00.", 10, WoodUI.BAD if msg != "" else WoodUI.INK, w, HORIZONTAL_ALIGNMENT_CENTER)
	WoodUI.text(canvas, Vector2(WoodUI.BUS_ORIGIN.x, fy + 27), "Click a stop or press its number.   E / Esc: leave", 10, WoodUI.INK_SOFT, w, HORIZONTAL_ALIGNMENT_CENTER)
