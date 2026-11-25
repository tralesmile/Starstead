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
const ORIGIN := Vector2(150, 50)
const ROW := 30.0

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
	var panel := Rect2(ORIGIN - Vector2(10, 34), Vector2(360, 66.0 + rows.size() * ROW))
	canvas.draw_rect(panel.grow(2), Color(0.06, 0.12, 0.22))
	canvas.draw_rect(panel, Color(0.12, 0.24, 0.42, 0.97))
	canvas.draw_string(font, ORIGIN + Vector2(0, -16), "Bus stop: %s   (next bus in %d min)" % [here_name, wait_min], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 0.95, 0.7))
	var hover := int((canvas.get_local_mouse_position() - ORIGIN).y / ROW) if canvas.get_local_mouse_position().x > ORIGIN.x else -1
	for i in rows.size():
		var r: Dictionary = rows[i]
		var y := ORIGIN.y + i * ROW
		var ok := bool(r["ok"])
		canvas.draw_rect(Rect2(ORIGIN.x, y, 340, ROW - 3), Color(0.18, 0.32, 0.52, 0.95) if i != hover else Color(0.26, 0.44, 0.68, 0.95))
		canvas.draw_string(font, Vector2(ORIGIN.x + 8, y + 13), "%d. %s" % [(i + 1) % 10, r["name"]], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1, 1, 1) if ok else Color(0.7, 0.7, 0.75))
		var right := "$%d   %d min" % [r["fare"], int(r["minutes"]) + wait_min] if ok else String(r["why"])
		canvas.draw_string(font, Vector2(ORIGIN.x + 8, y + 25), right, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.75, 0.95, 0.7) if ok else Color(0.95, 0.6, 0.55))
	canvas.draw_string(font, ORIGIN + Vector2(0, 14 + rows.size() * ROW), msg if msg != "" else "Fares by distance. Buses every 30 min, 06:00-23:00.   E / Esc: leave", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1, 1, 0.8))
