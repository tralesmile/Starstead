class_name WelcomeView
extends CanvasLayer
## Welcome-back card shown when a save was loaded: E/Enter continues, N twice starts a new farm.

signal continued
signal new_game

var active := false
var armed := false   # N pressed once: the next N wipes
var line := ""
var _c: Control

func _init() -> void:
	layer = 70
	_c = Control.new()
	_c.draw.connect(_on_draw)
	_c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_c)
	visible = false

func open(summary: String) -> void:
	line = summary
	armed = false
	active = true
	visible = true
	_c.queue_redraw()

func close() -> void:
	active = false
	visible = false

func handle_key(e: InputEvent) -> bool:
	## While open the card swallows every key and click.
	if not active:
		return false
	if e is InputEventKey and e.pressed and not e.echo:
		if e.keycode in [KEY_E, KEY_ENTER, KEY_KP_ENTER, KEY_ESCAPE]:
			close()
			continued.emit()
		elif e.keycode == KEY_N:
			if armed:
				close()
				new_game.emit()
			else:
				armed = true
				_c.queue_redraw()
		else:
			armed = false
			_c.queue_redraw()
	return true

## _input (not _unhandled_input) so no other node (car, jobs, hotbar, map) sees keys under the card.
func _input(e: InputEvent) -> void:
	if active and (e is InputEventKey or e is InputEventMouseButton or e is InputEventAction):
		get_viewport().set_input_as_handled()   # first: "new game" reloads the scene and takes this node out of the tree
		handle_key(e)

func _on_draw() -> void:
	_c.draw_rect(Rect2(0, 0, 640, 360), Color(0.04, 0.03, 0.06, 0.55))
	var r := Rect2(170, 112, 300, 128)
	WoodUI.panel(_c, r, "Welcome back to Starstead")
	WoodUI.text(_c, Vector2(170, 158), line, 13, WoodUI.INK, 300, HORIZONTAL_ALIGNMENT_CENTER)
	WoodUI.text(_c, Vector2(170, 192), "E / Enter  -  continue", 12, WoodUI.GOOD, 300, HORIZONTAL_ALIGNMENT_CENTER)
	var warn := "Press N again to erase this farm" if armed else "N  -  start a new farm"
	WoodUI.text(_c, Vector2(170, 218), warn, 11, WoodUI.BAD if armed else WoodUI.INK_SOFT, 300, HORIZONTAL_ALIGNMENT_CENTER)
