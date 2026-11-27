class_name StoryView
extends CanvasLayer
## Story glue: forwards game events to GameState.story, pays rewards, shows a banner when a beat lands, and the K quest log.

signal said(msg: String)
signal closed

var canvas: Control
var banner := ""
var banner_t := 0.0
var _poll_t := 0.0
var _was_drawing := false

func _init() -> void:
	layer = 9
	canvas = Control.new()
	canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.draw.connect(_draw_all)
	add_child(canvas)
	visible = true

func log_open() -> bool:
	return _log

var _log := false

func toggle_log() -> void:
	_log = not _log
	canvas.queue_redraw()   # without this the closed log stays painted (no redraw once idle)
	if not _log:
		closed.emit()

func event(name: String) -> void:
	_land(GameState.story.notify(name))

var _fee_seen := -1

func poll(planted: int) -> void:
	_land(GameState.story.poll({"day": GameState.clock.day, "money": GameState.money, "planted": planted, "debt_paid": GameState.debt_paid,
		"rep_honest": GameState.rep_honest, "rep_street": GameState.rep_street, "stats": GameState.stats}))
	var fee: int = GameState.story.late_fee()
	if _fee_seen >= 0 and fee > _fee_seen:
		banner = "Vance's clerk sends a note: the debt is late. A $%d fee is added (pay at the Town Hall ledger)." % (fee - _fee_seen)
		banner_t = 7.0
		said.emit(banner)
	_fee_seen = fee

func _land(steps: Array) -> void:
	for s in steps:
		var r: Dictionary = s.get("reward", {})
		var extra := ""
		if int(r.get("money", 0)) > 0:
			GameState.money += int(r["money"])
			extra = "  (+$%d)" % int(r["money"])
		banner = StoryModel.say_for(s, StoryModel.side(GameState.rep_honest, GameState.rep_street)) + extra
		banner_t = 7.0
		said.emit(banner)

func handle(e: InputEvent) -> bool:
	if e is InputEventKey and e.is_action_pressed("quests"):
		toggle_log()
		return true
	if _log and (e.is_action_pressed("pause") or e.is_action_pressed("inventory")):
		toggle_log()
		return true
	return _log and (e is InputEventKey or e is InputEventMouseButton)

func _process(delta: float) -> void:
	banner_t = maxf(0.0, banner_t - delta)
	canvas.size = get_viewport().get_visible_rect().size
	if banner_t > 0.0 or _log or _was_drawing:
		canvas.queue_redraw()
	_was_drawing = banner_t > 0.0 or _log

func _draw_all() -> void:
	var font := ThemeDB.fallback_font
	if banner_t > 0.0 and banner != "":
		var a := clampf(banner_t, 0.0, 1.0)
		var w := minf(canvas.size.x - 40.0, 520.0)
		var lines := Dialogue.wrap(banner, int(w / 5.6))
		var h := 18.0 + lines.size() * 13.0
		var r := Rect2((canvas.size.x - w) * 0.5, 44, w, h)
		canvas.draw_rect(r.grow(2), Color(0.35, 0.22, 0.08, 0.95 * a))
		canvas.draw_rect(r, Color(0.12, 0.1, 0.16, 0.93 * a))
		canvas.draw_string(font, r.position + Vector2(8, 12), "STORY", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(1.0, 0.8, 0.35, a))
		for i in lines.size():
			canvas.draw_string(font, r.position + Vector2(8, 24 + i * 13), lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1, 1, 1, a))
	if _log:
		var rows := GameState.story.log_lines(GameState.debt_paid, GameState.stats)
		var panel := Rect2(90, 24, 460, 30.0 + rows.size() * 14.0)
		canvas.draw_rect(panel.grow(2), Color(0.16, 0.1, 0.06))
		canvas.draw_rect(panel, Color(0.16, 0.18, 0.28, 0.97))
		canvas.draw_string(font, panel.position + Vector2(10, 16), "%s    %d/%d beats" % [GameState.story.current_act(), GameState.story.steps_done(), GameState.story.total_steps()], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 0.9, 0.55))
		for i in rows.size():
			var t := str(rows[i])
			var col := Color(0.7, 0.95, 0.7) if t.contains("[x]") else (Color(1, 0.95, 0.5) if t.contains("[>]") else (Color(1, 1, 1) if not t.begins_with("  ") else Color(0.75, 0.78, 0.85)))
			canvas.draw_string(font, panel.position + Vector2(10, 32 + i * 14), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, col)
		canvas.draw_string(font, panel.position + Vector2(10, panel.size.y - 16), ReputationModel.summary(GameState.rep_honest, GameState.rep_street), HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.7, 1.0, 0.8))
		canvas.draw_string(font, panel.position + Vector2(10, panel.size.y - 4), "K or Esc to close", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(1, 1, 1, 0.7))
