class_name WelcomeView
extends CanvasLayer
## Title screen over the live world: Continue / New farm (two presses) or Start, volume, sound, controls, quit.
## Rules and layout are in TitleModel.

signal continued
signal new_game
signal quit_game
signal sound_toggled
signal volume_nudged(dir: int)

var active := false
var armed := false      # "New farm" pressed once: the next press wipes
var has_save := true
var line := ""
var sel := 0
var volume := PauseModel.VOLUME_STEPS
var muted := false
var show_keys := false
var t := 0.0
var _c: Control

func _init() -> void:
	layer = 70
	_c = Control.new()
	_c.draw.connect(_on_draw)
	_c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_c)
	visible = false

## summary is the save's one-line description, or "" when there is no save yet.
func open(summary: String) -> void:
	line = summary
	has_save = summary != ""
	armed = false
	show_keys = false
	sel = 0
	active = true
	visible = true
	_c.queue_redraw()

func close() -> void:
	active = false
	visible = false

func rows() -> Array:
	return TitleModel.rows(has_save)

func activate(i: int) -> void:
	var id: String = rows()[i]
	if id != "new":
		armed = false
	match id:
		"continue", "start":
			close()
			continued.emit()
		"new":
			if armed:
				close()
				new_game.emit()
			else:
				armed = true
		"volume":
			volume_nudged.emit(1 if volume < PauseModel.VOLUME_STEPS else -PauseModel.VOLUME_STEPS)
		"sound":
			sound_toggled.emit()
		"keys":
			show_keys = true
		"quit":
			quit_game.emit()
	_c.queue_redraw()

func _move(dir: int) -> void:
	sel = PauseModel.move(sel, dir, rows().size())
	armed = false

func handle_key(e: InputEvent) -> bool:
	## While open the title swallows every key and click.
	if not active:
		return false
	var count := rows().size()
	var key: bool = e is InputEventKey and e.pressed and not e.echo
	var click: bool = e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT
	if show_keys:
		if key or click or (e is InputEventJoypadButton and e.pressed):
			show_keys = false
	elif e.is_action_pressed("move_up") or (key and e.keycode == KEY_UP):
		_move(-1)
	elif e.is_action_pressed("move_down") or (key and e.keycode == KEY_DOWN):
		_move(1)
	elif rows()[sel] == "volume" and (e.is_action_pressed("move_left") or e.is_action_pressed("move_right")):
		volume_nudged.emit(-1 if e.is_action_pressed("move_left") else 1)
	elif e.is_action_pressed("interact") or (key and e.keycode in [KEY_E, KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]):
		activate(sel)
	elif e is InputEventMouseMotion:
		var h := TitleModel.row_at(_c.get_local_mouse_position(), count)
		if h >= 0 and h != sel:
			sel = h
			armed = false
	elif click:
		var i := TitleModel.row_at(_c.get_local_mouse_position(), count)
		if i >= 0:
			sel = i
			if rows()[i] == "volume":
				var left: bool = _c.get_local_mouse_position().x < TitleModel.row_rect(i, count).get_center().x
				volume_nudged.emit(-1 if left else 1)
			else:
				activate(i)
	_c.queue_redraw()
	return true

## _input (not _unhandled_input) so no other node (car, jobs, hotbar, map) sees keys under the title.
func _input(e: InputEvent) -> void:
	if active and (e is InputEventKey or e is InputEventMouse or e is InputEventAction or e is InputEventJoypadButton):
		get_viewport().set_input_as_handled()   # first: "new farm" reloads the scene and takes this node out of the tree
		handle_key(e)

func _process(delta: float) -> void:
	if active:
		t += delta
		_c.queue_redraw()

func _on_draw() -> void:
	# a dusk veil: darkest at the top so the stars and logo read, the farm stays visible below
	for i in 12:
		_c.draw_rect(Rect2(0, i * 30, 640, 30), Color(0.05, 0.05, 0.14, lerpf(0.82, 0.30, i / 11.0)))
	for i in 46:
		var at := Vector2((i * 137 + 29) % 640, (i * 61 + 7) % 112)
		var k := TitleModel.twinkle(i, t)
		_c.draw_rect(Rect2(at, Vector2(2, 2)), Color(1.0, 0.97, 0.85, 0.25 + 0.7 * k))
		if i % 9 == 0 and k > 0.75:
			_c.draw_rect(Rect2(at + Vector2(-2, 0), Vector2(6, 2)), Color(1.0, 0.97, 0.85, 0.5))
			_c.draw_rect(Rect2(at + Vector2(0, -2), Vector2(2, 6)), Color(1.0, 0.97, 0.85, 0.5))
	# the Moon, where the story is headed
	_c.draw_circle(Vector2(566, 54), 22.0, Color(0.93, 0.92, 0.82))
	for crater in [Vector3(558, 46, 5), Vector3(574, 60, 4), Vector3(560, 66, 2.5), Vector3(577, 45, 2)]:
		_c.draw_circle(Vector2(crater.x, crater.y), crater.z, Color(0.78, 0.76, 0.68))
	_draw_logo("STARSTEAD", 38.0)
	_c.draw_string_outline(ThemeDB.fallback_font, Vector2(0, 104), "A farm, a town, and a long road to the Moon", HORIZONTAL_ALIGNMENT_CENTER, 640, 11, 4, WoodUI.OUTLINE)
	_c.draw_string(ThemeDB.fallback_font, Vector2(0, 104), "A farm, a town, and a long road to the Moon", HORIZONTAL_ALIGNMENT_CENTER, 640, 11, WoodUI.CREAM)
	if show_keys:
		PauseView.draw_controls(_c)
		return
	var ids := rows()
	var r := TitleModel.panel_rect(ids.size())
	WoodUI.panel(_c, r, "Welcome back" if has_save else "A new farm")
	for i in ids.size():
		var rr := TitleModel.row_rect(i, ids.size())
		WoodUI.row(_c, rr, i == sel, true)
		var warn: bool = ids[i] == "new" and armed
		WoodUI.text(_c, rr.position + Vector2(0, 14), TitleModel.label(ids[i], volume, muted, armed), 12, WoodUI.BAD if warn else WoodUI.INK, rr.size.x, HORIZONTAL_ALIGNMENT_CENTER)
	WoodUI.text(_c, Vector2(r.position.x, r.end.y - 22), line if has_save else "Grandmother left you the keys.", 11, WoodUI.GOOD, r.size.x, HORIZONTAL_ALIGNMENT_CENTER)
	WoodUI.text(_c, Vector2(r.position.x, r.end.y - 7), "W/S choose   -   E / Enter / click", 9, WoodUI.INK_SOFT, r.size.x, HORIZONTAL_ALIGNMENT_CENTER)

func _draw_logo(word: String, y: float) -> void:
	var px := TitleModel.LOGO_PX
	var x0 := floorf((640.0 - TitleModel.logo_width(word)) * 0.5)
	var cells := TitleModel.logo_cells(word)
	for pass_i in 3:   # outline, drop shadow, face
		for c in cells:
			var at := Vector2(x0 + c.x * px, y + c.y * px + TitleModel.bob(c.x / 6, t))
			if pass_i == 0:
				_c.draw_rect(Rect2(at - Vector2(2, 2), Vector2(px + 4, px + 7)), WoodUI.OUTLINE)
			elif pass_i == 1:
				_c.draw_rect(Rect2(at + Vector2(0, 3), Vector2(px, px)), Color(0.55, 0.29, 0.08))
			else:
				var gold := Color(1.0, 0.93, 0.55).lerp(Color(0.95, 0.62, 0.18), c.y / 6.0)
				_c.draw_rect(Rect2(at, Vector2(px, px)), gold)
				_c.draw_rect(Rect2(at, Vector2(px, 1)), Color(1, 1, 0.88, 0.65))
