class_name ShiftGameView
extends CanvasLayer
## Overlay for the job mini-game (ShiftGame): plays one shift, then reports the result. Esc skips for normal pay.

signal finished(result: Dictionary)   # {mult, grade, score, bonus_xp, perfect, skipped}

var canvas: Control
var game: ShiftGame
var title := ""
var base_pay := 0
var _end_t := -1.0
const W := 420.0

func _init() -> void:
	layer = 10
	canvas = Control.new()
	canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.draw.connect(_draw_all)
	add_child(canvas)
	visible = false
	set_process_input(false)

func open(job_id: String, kind: String, rank_idx: int, pay: int, seed_value: int) -> void:
	game = ShiftGame.new(kind, rank_idx, seed_value)
	title = ShiftGame.title_for(job_id, kind)
	base_pay = pay
	_end_t = -1.0
	visible = true
	set_process_input(true)

func close(res: Dictionary) -> void:
	visible = false
	set_process_input(false)
	finished.emit(res)

static func key_dir(code: int) -> int:
	var arrows := [KEY_UP, KEY_RIGHT, KEY_DOWN, KEY_LEFT]
	var moves := ["move_up", "move_right", "move_down", "move_left"]
	for i in 4:
		if code == arrows[i] or code == KeyBinds.key_of(moves[i]):
			return i
	return -1

func _input(e: InputEvent) -> void:
	if not visible:
		return
	get_viewport().set_input_as_handled()
	if not (e is InputEventKey) or not e.pressed or e.echo:
		return
	if e.keycode == KEY_ESCAPE:
		close({"mult": 1.0, "grade": "Skipped", "score": 0.5, "bonus_xp": 0, "perfect": false, "skipped": true})
		return
	if game.done:
		if _end_t > 0.3:
			_finish()
		return
	if game.kind == "timing" and e.keycode in [KEY_SPACE, KeyBinds.key_of("interact"), KeyBinds.key_of("journal"), KEY_ENTER]:
		game.press_action()
	elif game.kind == "sequence":
		var d := key_dir(e.keycode)
		if d >= 0:
			game.press_dir(d)

func _finish() -> void:
	var r := game.result()
	r["skipped"] = false
	close(r)

func _process(d: float) -> void:
	if not visible:
		return
	var inp := 0.0
	if game.kind == "balance":
		inp = Input.get_axis("move_left", "move_right")
	game.step(d, inp)
	if game.done:
		_end_t = maxf(_end_t, 0.0) + d
		if _end_t > 2.2:
			_finish()
	canvas.size = get_viewport().get_visible_rect().size
	canvas.queue_redraw()

func _draw_all() -> void:
	var font := ThemeDB.fallback_font
	var vs := canvas.size
	var panel := Rect2(vs / 2.0 - Vector2(W / 2.0 + 16, 80), Vector2(W + 32, 160))
	canvas.draw_rect(Rect2(Vector2.ZERO, vs), Color(0, 0, 0, 0.35))
	canvas.draw_rect(panel.grow(2), Color(0.16, 0.1, 0.06))
	canvas.draw_rect(panel, Color(0.36, 0.24, 0.14, 0.97))
	var o := panel.position + Vector2(16, 0)
	canvas.draw_string(font, o + Vector2(0, 22), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1, 0.95, 0.7))
	_draw_pips(o + Vector2(W - 70, 8))
	var bar := Rect2(o + Vector2(0, 56), Vector2(W, 26))
	match game.kind:
		"timing": _draw_timing(bar)
		"sequence": _draw_sequence(o + Vector2(0, 40))
		_: _draw_balance(bar)
	if game.flash < 0.35 and game.kind != "balance":
		var c := Color(0.5, 1.0, 0.5, 1.0 - game.flash / 0.35) if game.flash_ok else Color(1.0, 0.4, 0.35, 1.0 - game.flash / 0.35)
		canvas.draw_rect(panel.grow(-4), Color(c.r, c.g, c.b, c.a * 0.18))
	if game.done:
		var r := game.result()
		canvas.draw_string(font, o + Vector2(0, 118), "%s  pay x%.2f = $%d" % [r["grade"], r["mult"], int(round(base_pay * float(r["mult"])))], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 0.9, 0.4))
		canvas.draw_string(font, o + Vector2(0, 140), "any key to clock out", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.9, 0.85, 0.7))
	else:
		var hint: String = {"timing": "SPACE / %s to strike" % KeyBinds.label("interact"), "sequence": "arrow keys or %s" % KeyBinds.move_label(), "balance": "hold LEFT / RIGHT"}[game.kind]
		canvas.draw_string(font, o + Vector2(0, 140), hint + "    Esc: skip (normal pay)", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.9, 0.85, 0.7))

func _draw_pips(p: Vector2) -> void:
	if game.kind == "balance":
		return
	for i in game.rounds:
		var c := Color(0.25, 0.17, 0.1)
		if i < game.scores.size():
			var s := game.scores[i]
			c = Color(0.4, 0.9, 0.4) if s >= 0.9 else (Color(0.9, 0.8, 0.3) if s > 0.0 else Color(0.85, 0.3, 0.25))
		canvas.draw_rect(Rect2(p + Vector2(i * 14, 0), Vector2(10, 10)), c)

func _draw_timing(bar: Rect2) -> void:
	canvas.draw_rect(bar, Color(0.12, 0.08, 0.05))
	var z := Rect2(bar.position + Vector2((game.center - game.half) * W, 0), Vector2(game.half * 2.0 * W, bar.size.y))
	canvas.draw_rect(z, Color(0.25, 0.55, 0.25))
	canvas.draw_rect(Rect2(bar.position + Vector2((game.center - game.half * 0.35) * W, 0), Vector2(game.half * 0.7 * W, bar.size.y)), Color(0.5, 0.9, 0.4))
	var m := game.marker() if not game.done else game.marker()
	canvas.draw_rect(Rect2(bar.position + Vector2(m * W - 2, -5), Vector2(4, bar.size.y + 10)), Color(1.0, 0.95, 0.8))

func _draw_sequence(p: Vector2) -> void:
	if game.done:
		return
	var n := game.seq.size()
	var step := minf(52.0, W / float(n))
	for i in n:
		var c := Vector2(p.x + 20 + i * step, p.y + 36)
		var col := Color(0.4, 0.9, 0.4) if i < game.seq_i else (Color(1, 0.95, 0.7) if i == game.seq_i else Color(0.6, 0.5, 0.4))
		var dir := Vector2.UP.rotated(float(game.seq[i]) * PI / 2.0)
		var perp := dir.orthogonal()
		canvas.draw_colored_polygon(PackedVector2Array([c + dir * 16.0, c - dir * 10.0 + perp * 14.0, c - dir * 10.0 - perp * 14.0]), col)
	var left := 1.0 - clampf(game.t / game.seq_limit, 0.0, 1.0)
	canvas.draw_rect(Rect2(p + Vector2(0, 76), Vector2(W, 6)), Color(0.12, 0.08, 0.05))
	canvas.draw_rect(Rect2(p + Vector2(0, 76), Vector2(W * left, 6)), Color(0.9, 0.7, 0.3) if left > 0.3 else Color(0.9, 0.35, 0.3))

func _draw_balance(bar: Rect2) -> void:
	canvas.draw_rect(bar, Color(0.12, 0.08, 0.05))
	var z := Rect2(bar.position + Vector2((0.5 - game.half * 0.5) * W, 0), Vector2(game.half * W, bar.size.y))
	canvas.draw_rect(z, Color(0.25, 0.55, 0.25))
	var x := bar.position.x + (game.needle * 0.5 + 0.5) * W
	var inside := absf(game.needle) <= game.half
	canvas.draw_rect(Rect2(Vector2(x - 2, bar.position.y - 5), Vector2(4, bar.size.y + 10)), Color(0.6, 1.0, 0.5) if inside else Color(1.0, 0.5, 0.4))
	var left := 1.0 - clampf(game.t / ShiftGame.BALANCE_TIME, 0.0, 1.0)
	canvas.draw_rect(Rect2(bar.position + Vector2(0, 40), Vector2(W, 6)), Color(0.12, 0.08, 0.05))
	canvas.draw_rect(Rect2(bar.position + Vector2(0, 40), Vector2(W * left, 6)), Color(0.9, 0.7, 0.3))
