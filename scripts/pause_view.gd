class_name PauseView
extends CanvasLayer
## Esc pause menu: freezes the whole tree, and offers save, volume, sound, controls, leaving a building and quit.
## It runs while the tree is paused and takes every key and click while open.

signal chosen(id: String)   # "save", "sound", "leave", "quit" (resume and volume are handled here)

var active := false
var sel := 0
var volume := PauseModel.VOLUME_STEPS
var muted := false
var leave_place := ""
var note := ""
var show_keys := false
var persist_volume := true
var _c: Control

func _init() -> void:
	layer = 80
	process_mode = Node.PROCESS_MODE_ALWAYS
	_c = Control.new()
	_c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_c.draw.connect(_on_draw)
	add_child(_c)
	visible = false

func apply_volume() -> void:
	AudioServer.set_bus_volume_db(0, PauseModel.volume_db(volume))

func open(place: String, is_muted: bool) -> void:
	leave_place = place
	muted = is_muted
	sel = 0
	note = ""
	show_keys = false
	active = true
	visible = true
	if is_inside_tree():
		get_tree().paused = true
	_c.queue_redraw()

func close() -> void:
	active = false
	visible = false
	if is_inside_tree():
		get_tree().paused = false

func _rows() -> Array:
	return PauseModel.rows(leave_place)

func activate(i: int) -> void:
	var id: String = _rows()[i]
	match id:
		"resume":
			close()
		"volume":
			_nudge(1 if volume < PauseModel.VOLUME_STEPS else -PauseModel.VOLUME_STEPS)
		"keys":
			show_keys = true
		"leave":
			close()
			chosen.emit(id)
		_:
			chosen.emit(id)
	_c.queue_redraw()

func _nudge(dir: int) -> void:
	volume = PauseModel.step_volume(volume, dir)
	apply_volume()
	if persist_volume:
		PauseModel.store_volume(volume)

func handle_key(e: InputEvent) -> bool:
	if not active:
		return false
	var count := _rows().size()
	var back := e.is_action_pressed("pause")
	if show_keys:
		if back or (e is InputEventKey and e.pressed and not e.echo) or (e is InputEventMouseButton and e.pressed) or (e is InputEventJoypadButton and e.pressed):
			show_keys = false
	elif back:
		close()
	elif e.is_action_pressed("move_up"):
		sel = PauseModel.move(sel, -1, count)
	elif e.is_action_pressed("move_down"):
		sel = PauseModel.move(sel, 1, count)
	elif e.is_action_pressed("move_left") and _rows()[sel] == "volume":
		_nudge(-1)
	elif e.is_action_pressed("move_right") and _rows()[sel] == "volume":
		_nudge(1)
	elif e.is_action_pressed("interact") or (e is InputEventKey and e.pressed and not e.echo and e.keycode in [KEY_ENTER, KEY_KP_ENTER]):
		activate(sel)
	elif e is InputEventMouseMotion:
		var h := PauseModel.row_at(_c.get_local_mouse_position(), count)
		if h >= 0:
			sel = h
	elif e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		var i := PauseModel.row_at(_c.get_local_mouse_position(), count)
		if i >= 0:
			sel = i
			if _rows()[i] == "volume":
				var left: bool = _c.get_local_mouse_position().x < PauseModel.row_rect(i, count).get_center().x
				_nudge(-1 if left else 1)
			else:
				activate(i)
	_c.queue_redraw()
	return true

## _input so nothing else (car, jobs, hotbar, map) sees keys under the menu.
func _input(e: InputEvent) -> void:
	if active and (e is InputEventKey or e is InputEventMouse or e is InputEventAction or e is InputEventJoypadButton):
		get_viewport().set_input_as_handled()
		handle_key(e)

func _on_draw() -> void:
	_c.draw_rect(Rect2(Vector2.ZERO, PauseModel.SCREEN), Color(0.04, 0.03, 0.06, 0.55))
	if show_keys:
		var rows := KeyLegend.rows("foot")
		var extra := [["F", "Handbrake (car)"], ["G", "Gear / load cart"], ["N", "Mute"]]
		var all: Array = rows + extra
		var k := Rect2(130, 52, 380, 40.0 + ceili(all.size() / 2.0) * 20.0 + 20.0)
		WoodUI.panel(_c, k, "Controls", WoodUI.Trim.IRON)
		var half := ceili(all.size() / 2.0)
		for i in all.size():
			var at := k.position + Vector2(16 + (i / half) * 184, 44 + (i % half) * 20)
			WoodUI.text(_c, at, String(all[i][0]), 11, WoodUI.PRICE, 56)
			WoodUI.text(_c, at + Vector2(60, 0), String(all[i][1]), 11, WoodUI.INK, 118)
		WoodUI.text(_c, Vector2(k.position.x, k.end.y - 8), "Any key to go back", 10, WoodUI.INK_SOFT, k.size.x, HORIZONTAL_ALIGNMENT_CENTER)
		return
	var ids := _rows()
	var r := PauseModel.panel_rect(ids.size())
	WoodUI.panel(_c, r, "Paused")
	for i in ids.size():
		var rr := PauseModel.row_rect(i, ids.size())
		WoodUI.row(_c, rr, i == sel, true)
		WoodUI.text(_c, rr.position + Vector2(0, 15), PauseModel.label(ids[i], volume, muted, leave_place), 12, WoodUI.INK, rr.size.x, HORIZONTAL_ALIGNMENT_CENTER)
	var foot := note if note != "" else "Esc  -  back to the game"
	WoodUI.text(_c, Vector2(r.position.x, r.end.y - 8), foot, 10, WoodUI.GOOD if note != "" else WoodUI.INK_SOFT, r.size.x, HORIZONTAL_ALIGNMENT_CENTER)
