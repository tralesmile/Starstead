class_name PerkView
extends CanvasLayer
## Level-5 perk chooser: two wooden cards, press 1 / 2 or click one (permanent); Esc decides later (P reopens).

signal opened
signal closed
signal picked(skill: String, id: String)
const ARM_TIME := 0.6   # picks are ignored this long after opening, so mashed hotbar keys or tool clicks never choose
var canvas: Control
var skill := ""
var level := PerkModel.UNLOCK_LEVEL
var blocked := Callable()   # true while another window must finish first
var _armed := 0.0
var _queued := ""
var _delay := 0.0

func _init() -> void:
	layer = 62   # above the region banner and full-screen sport views
	canvas = Control.new()
	canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.draw.connect(_draw_all)
	add_child(canvas)
	visible = false

func open(sk: String, lvl: int = PerkModel.UNLOCK_LEVEL) -> void:
	_queued = ""
	skill = sk
	level = lvl
	_armed = ARM_TIME
	var was := visible
	visible = true
	canvas.queue_redraw()
	if not was:
		opened.emit()

func open_later(sk: String, lvl: int, delay: float = 1.4) -> void:
	## Lets the level-up fanfare play first.
	if visible:
		return
	_queued = sk
	level = lvl
	_delay = delay

func close() -> void:
	if not visible:
		return
	visible = false
	closed.emit()

func _process(d: float) -> void:
	if _queued != "":
		_delay -= d
		if _delay <= 0.0 and not (blocked.is_valid() and blocked.call()):
			open(_queued, level)
	if visible:
		_armed = maxf(0.0, _armed - d)
		canvas.size = get_viewport().get_visible_rect().size
		canvas.queue_redraw()

func _pick(i: int) -> void:
	var opts := PerkModel.options(skill)
	if _armed > 0.0 or i < 0 or i >= opts.size():
		return
	picked.emit(skill, String(opts[i]["id"]))

func handle_key(e: InputEvent) -> bool:
	## True when the event was consumed (the chooser is open).
	if not visible:
		return false
	if e.is_action_pressed("pause"):
		close()
	elif e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		_pick(PerkModel.card_at(canvas.get_local_mouse_position()))
	elif e is InputEventKey and e.pressed and not e.echo:
		var k := TargetMath.key_slot(e.keycode)
		if k >= 0:
			_pick(k)
	return true

func _draw_all() -> void:
	canvas.draw_rect(Rect2(Vector2.ZERO, canvas.size), Color(0, 0, 0, 0.45))
	var panel := PerkModel.PANEL
	WoodUI.panel(canvas, panel, "%s level %d! Choose a perk" % [skill.capitalize(), level], WoodUI.Trim.SAWDUST)
	var opts := PerkModel.options(skill)
	var hover := PerkModel.card_at(canvas.get_local_mouse_position())
	var font := ThemeDB.fallback_font
	for i in mini(2, opts.size()):
		var r := PerkModel.card_rect(i)
		var o := r.position
		var w := r.size.x - PerkModel.CARD_PAD * 2.0
		WoodUI.row(canvas, r, i == hover, true)
		canvas.draw_rect(r, WoodUI.WOOD_D, false, 2.0)
		canvas.draw_rect(Rect2(o + Vector2(2, 2), Vector2(r.size.x - 4, 4)), LevelFxMath.skill_color(skill))
		WoodUI.text(canvas, o + Vector2(PerkModel.CARD_PAD, PerkModel.NAME_Y), String(opts[i]["name"]), PerkModel.NAME_SIZE, WoodUI.INK, w, HORIZONTAL_ALIGNMENT_CENTER)
		canvas.draw_multiline_string(font, o + Vector2(PerkModel.CARD_PAD, PerkModel.DESC_Y), String(opts[i]["desc"]), HORIZONTAL_ALIGNMENT_CENTER, w, PerkModel.DESC_SIZE, PerkModel.DESC_LINES, WoodUI.INK_SOFT)
		var key := Rect2(o + Vector2(r.size.x * 0.5 - 50, PerkModel.PICK_Y - 13), Vector2(100, 18))
		canvas.draw_rect(key, WoodUI.WOOD_D)
		WoodUI.text(canvas, o + Vector2(PerkModel.CARD_PAD, PerkModel.PICK_Y), "Press %d" % (i + 1), PerkModel.FOOTER_SIZE, WoodUI.CREAM if _armed <= 0.0 else WoodUI.WOOD_L, w, HORIZONTAL_ALIGNMENT_CENTER)
	WoodUI.text(canvas, Vector2(panel.position.x + 8, panel.end.y - 13), PerkModel.FOOTER, PerkModel.FOOTER_SIZE, WoodUI.INK, panel.size.x - 16, HORIZONTAL_ALIGNMENT_CENTER)
