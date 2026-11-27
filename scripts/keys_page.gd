class_name KeysPage
extends RefCounted
## The Controls page (pause menu and title screen): pick an action, press its new key. Rules are in KeyBinds.

const PANEL := Rect2(100, 40, 440, 280)
const PER_COL := 7
const ROW_H := 21.0
const RESET := 13   # item ids after the actions
const BACK := 14
const COUNT := 15
const FIXED := ["Fixed: Esc pause   F1 key list   1-0 hotbar   +/- zoom   N mute",
	"Arrows walk   Space use   I bag   B build (Q R H X)   G gear   T swipe",
	"P perk   L laps   R race reset   S sort bag   Shift+E / Shift+click"]

var sel := 0
var waiting := false   # the next key press goes to the selected action
var note := ""
var bad := false

func open() -> void:
	sel = 0
	waiting = false
	note = ""
	bad = false

static func item_rect(i: int) -> Rect2:
	if i >= RESET:
		return Rect2(PANEL.position + Vector2(12 + (i - RESET) * 212, 34 + PER_COL * ROW_H + 4), Vector2(204, ROW_H - 2))
	return Rect2(PANEL.position + Vector2(12 + (i / PER_COL) * 212, 30 + (i % PER_COL) * ROW_H), Vector2(204, ROW_H - 2))

static func item_at(p: Vector2) -> int:
	for i in COUNT:
		if item_rect(i).has_point(p):
			return i
	return -1

func _set_binds(chosen: Dictionary) -> void:
	KeyBinds.apply(chosen)
	if KeyBinds.persist:
		KeyBinds.store(chosen)

func _activate() -> bool:
	## Returns true when the page should close.
	bad = false
	if sel == BACK:
		return true
	if sel == RESET:
		_set_binds(KeyBinds.defaults())
		note = "Keys reset to defaults"
	else:
		waiting = true
		note = "Press a new key for %s (Esc cancels)" % KeyBinds.LIST[sel][1]
	return false

## mouse is in screen coordinates. Returns true when the page should close.
func handle(e: InputEvent, mouse: Vector2) -> bool:
	var key: bool = e is InputEventKey and e.pressed and not e.echo
	var click: bool = e is InputEventMouseButton and e.pressed
	if waiting:
		if key:
			waiting = false
			if e.keycode == KEY_ESCAPE:
				bad = false
				note = "Unchanged"
			else:
				var r := KeyBinds.rebind(KeyBinds.binds(), KeyBinds.LIST[sel][0], e.keycode)
				bad = not r["ok"]
				note = r["msg"]
				if r["ok"]:
					_set_binds(r["binds"])
		elif click or (e is InputEventJoypadButton and e.pressed):
			waiting = false
			bad = false
			note = "Unchanged"
		return false
	if e.is_action_pressed("pause"):
		return true
	# the arrows and Enter are checked first: they never move, so a strange layout cannot trap you here
	if key and e.keycode in [KEY_ENTER, KEY_KP_ENTER]:
		return _activate()
	if e.is_action_pressed("move_up", true):
		sel = posmod(sel - 1, COUNT)
	elif e.is_action_pressed("move_down", true):
		sel = posmod(sel + 1, COUNT)
	elif e.is_action_pressed("move_left") or e.is_action_pressed("move_right"):
		if sel >= RESET:
			sel = BACK if sel == RESET else RESET
		else:
			sel = mini(sel + PER_COL, RESET - 1) if sel < PER_COL else sel - PER_COL
	elif e.is_action_pressed("interact"):
		return _activate()
	elif e is InputEventMouseMotion:
		var h := item_at(mouse)
		if h >= 0:
			sel = h
	elif click and e.button_index == MOUSE_BUTTON_LEFT:
		var i := item_at(mouse)
		if i >= 0:
			sel = i
			return _activate()
	return false

func draw(c: CanvasItem) -> void:
	WoodUI.panel(c, PANEL, "Controls", WoodUI.Trim.IRON)
	WoodUI.plank_note(c, PANEL, "Pick an action, then press a key")
	for i in COUNT:
		var r := item_rect(i)
		WoodUI.row(c, r, i == sel, true)
		if i >= RESET:
			WoodUI.text(c, r.position + Vector2(0, 14), "Reset to defaults" if i == RESET else "Back  (Esc)", 11, WoodUI.INK, r.size.x, HORIZONTAL_ALIGNMENT_CENTER)
			continue
		var asking := waiting and i == sel
		WoodUI.text(c, r.position + Vector2(8, 14), KeyBinds.LIST[i][1], 11, WoodUI.INK, 130)
		WoodUI.text(c, r.position + Vector2(138, 14), "press..." if asking else KeyBinds.label(KeyBinds.LIST[i][0]), 11, WoodUI.BAD if asking else WoodUI.PRICE, 58, HORIZONTAL_ALIGNMENT_RIGHT)
	var y := item_rect(RESET).end.y
	WoodUI.text(c, Vector2(PANEL.position.x, y + 15), note, 10, WoodUI.BAD if bad else WoodUI.GOOD, PANEL.size.x, HORIZONTAL_ALIGNMENT_CENTER)
	for i in FIXED.size():
		WoodUI.text(c, Vector2(PANEL.position.x, y + 32 + i * 13), FIXED[i], 9, WoodUI.INK_SOFT, PANEL.size.x, HORIZONTAL_ALIGNMENT_CENTER)
