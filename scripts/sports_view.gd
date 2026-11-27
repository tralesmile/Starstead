class_name SportsView
extends CanvasLayer
## Sports Hall + pitch mini-games (rules in SportsModel): basketball free throws, football penalties, boxing bouts.
## Space acts (stop the meter, jab), Left/Right dodge in the ring, Esc leaves (forfeits the round in progress).

signal closed
signal message(msg: String)

var canvas: Control
var mode := ""
var t := 0.0
var phase := 0            # hoops/penalty: 0 meter running, 9 showing result; penalty: 0 aim, 1 power
var pause_t := 0.0
var idx := 0
var results: Array = []
var aim := 0.5
var keeper := 1
var last_text := ""
var finished := false
var rng := RandomNumberGenerator.new()
# boxing
var you_hp := 40
var opp := 30
var tier := 0
var rounds := 0
var tele := 0
var tele_t := 0.0
var wait_t := 0.0
var window := 0.9
const BOX := Rect2(90, 80, 460, 200)

func _init() -> void:
	layer = 9
	canvas = Control.new()
	canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.draw.connect(_draw_all)
	add_child(canvas)
	visible = false
	rng.randomize()

func open(m: String) -> bool:
	mode = m
	t = 0.0
	phase = 0
	idx = 0
	results = []
	finished = false
	last_text = ""
	pause_t = 0.0
	if m == "boxing":
		if GameState.money < SportsModel.BOUT_FEE:
			message.emit("The ring entry fee is $%d" % SportsModel.BOUT_FEE)
			return false
		GameState.money -= SportsModel.BOUT_FEE
		tier = mini(3, int(GameState.sport_best.get("bouts_won", 0)) / 2)
		you_hp = 40
		opp = SportsModel.opp_hp(tier)
		rounds = 0
		window = SportsModel.bout_window(tier) + JobModel.new(DataDB.load_json("jobs")).ring_bonus(GameState.job_xp)
		tele = 0
		wait_t = rng.randf_range(0.8, 1.6)
		last_text = "Gloves up! Dodge the telegraphed punch (Left/Right) or jab (Space)"
	visible = true
	return true

func close() -> void:
	visible = false
	closed.emit()

func _process(d: float) -> void:
	if not visible:
		return
	canvas.size = get_viewport().get_visible_rect().size
	t += d
	if pause_t > 0.0:
		pause_t -= d
		if pause_t <= 0.0 and not finished:
			_next()
	elif mode == "boxing" and not finished:
		_box_tick(d)
	canvas.queue_redraw()

func _next() -> void:
	phase = 0
	if mode == "hoops" and idx >= SportsModel.SHOTS:
		_finish()
	elif mode == "penalty" and idx >= SportsModel.KICKS:
		_finish()

func handle(e: InputEvent) -> bool:
	if not visible:
		return false
	if e is InputEventKey and e.pressed and not e.echo:
		if e.keycode == KEY_ESCAPE or (finished and e.is_action_pressed("interact")):
			close()
			return true
		if pause_t > 0.0 or finished:
			return true
		match mode:
			"hoops":
				if e.keycode == KEY_SPACE:
					_shoot()
			"penalty":
				if e.keycode == KEY_SPACE:
					_kick()
			"boxing":
				if e.is_action_pressed("move_left"):
					_punch(-1)
				elif e.is_action_pressed("move_right"):
					_punch(1)
				elif e.keycode == KEY_SPACE:
					_punch(2)
		return true
	return false

func _shoot() -> void:
	var ok := SportsModel.hoop_made(SportsModel.meter(t), rng.randf(), SportsModel.hoop_width(int(GameState.sport_best.get("hoops", 0))))
	results.append(ok)
	idx += 1
	last_text = "SWISH!" if ok else "Off the rim"
	pause_t = 0.6
	t = 0.0

func _kick() -> void:
	if phase == 0:
		aim = SportsModel.meter(t, 1.2)
		phase = 1
		t = 0.0
		return
	var power := SportsModel.meter(t, 1.6)
	keeper = SportsModel.keeper_zone(rng.randf())
	var r := SportsModel.penalty(aim, power, keeper)
	results.append(r == "goal")
	idx += 1
	last_text = {"goal": "GOAL!", "saved": "Saved by the keeper", "miss": "Over the bar"}[r]
	phase = 9
	pause_t = 0.9
	t = 0.0

func _box_tick(d: float) -> void:
	if tele == 0:
		wait_t -= d
		if wait_t <= 0.0:
			tele = 1 if rng.randf() < 0.5 else -1
			tele_t = 0.0
	else:
		tele_t += d
		if tele_t > window:
			_punch(0)

func _punch(action: int) -> void:
	if tele == 0:
		return   # too early: ignored
	var r := SportsModel.exchange(tele, action, tele_t, window)
	you_hp -= int(r["you"])
	opp -= int(r["opp"])
	rounds += 1
	last_text = String(r["text"])
	tele = 0
	wait_t = rng.randf_range(0.7, 1.5)
	var over := SportsModel.bout_over(you_hp, opp, rounds)
	if over != "":
		_finish(over)

func _finish(result: String = "") -> void:
	finished = true
	var best: Dictionary = GameState.sport_best
	if mode == "hoops":
		var made := results.count(true)
		var pay := SportsModel.hoop_payout(results)
		GameState.money += pay
		if made > int(best.get("hoops", 0)):
			best["hoops"] = made
		last_text = "%d / %d made. +$%d  (%s to leave)" % [made, SportsModel.SHOTS, pay, KeyBinds.label("interact")]
	elif mode == "penalty":
		var goals := results.count(true)
		var pay2 := goals * SportsModel.GOAL_PAY
		GameState.money += pay2
		if goals > int(best.get("penalty", 0)):
			best["penalty"] = goals
		last_text = "%d / %d goals. +$%d  (%s to leave)" % [goals, SportsModel.KICKS, pay2, KeyBinds.label("interact")]
	elif mode == "boxing":
		if result == "win":
			var prize := SportsModel.bout_prize(tier)
			GameState.money += prize
			best["bouts_won"] = int(best.get("bouts_won", 0)) + 1
			GameState.bump("bouts")
			last_text = "KO! You win +$%d  (%s to leave)" % [prize, KeyBinds.label("interact")]
		else:
			last_text = "You lose the bout  (%s to leave)" % KeyBinds.label("interact")
	message.emit(last_text.replace("  (%s to leave)" % KeyBinds.label("interact"), ""))

func _draw_meter(x: float, y: float, w: float, v: float, zone_c: float, zone_w: float) -> void:
	canvas.draw_rect(Rect2(x - 1, y - 1, w + 2, 18), Color(0.1, 0.06, 0.04))
	canvas.draw_rect(Rect2(x, y, w, 16), Color(0.25, 0.18, 0.12))
	if zone_w > 0.0:
		canvas.draw_rect(Rect2(x + (zone_c - zone_w) * w, y, zone_w * 2.0 * w, 16), Color(0.3, 0.75, 0.35))
	canvas.draw_rect(Rect2(x + v * w - 2, y - 4, 4, 24), Color(1, 0.9, 0.3))

func _draw_all() -> void:
	var font := ThemeDB.fallback_font
	canvas.draw_rect(BOX.grow(2), Color(0.08, 0.1, 0.18))
	canvas.draw_rect(BOX, Color(0.16, 0.22, 0.38, 0.97))
	var o := BOX.position + Vector2(16, 24)
	var title: String = {"hoops": "Free throws", "penalty": "Penalty shootout", "boxing": "Boxing bout"}.get(mode, "")
	canvas.draw_string(font, o, "%s    Esc: leave" % title, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1, 0.95, 0.7))
	if mode == "hoops":
		var made := results.count(true)
		canvas.draw_string(font, o + Vector2(0, 28), "Shot %d / %d     made %d     Space: shoot in the green" % [mini(idx + 1, SportsModel.SHOTS), SportsModel.SHOTS, made], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.WHITE)
		_draw_meter(o.x, o.y + 50, 368, SportsModel.meter(t), 0.5, SportsModel.hoop_width(int(GameState.sport_best.get("hoops", 0))))
	elif mode == "penalty":
		var goals := results.count(true)
		canvas.draw_string(font, o + Vector2(0, 28), "Kick %d / %d     goals %d     Space: %s" % [mini(idx + 1, SportsModel.KICKS), SportsModel.KICKS, goals, "pick the corner" if phase == 0 else "set the power (hard but not too hard)"], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.WHITE)
		if phase == 0:
			_draw_meter(o.x, o.y + 50, 368, SportsModel.meter(t, 1.2), 0.0, 0.0)
			for i in 3:
				canvas.draw_rect(Rect2(o.x + i * 122, o.y + 70, 122, 3), Color(1, 1, 1, 0.5))
		elif phase == 1:
			canvas.draw_string(font, o + Vector2(0, 44), "Aim: %s" % ["left", "middle", "right"][SportsModel.zone_of(aim)], HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.8, 0.9, 1))
			_draw_meter(o.x, o.y + 50, 368, SportsModel.meter(t, 1.6), 0.0, 0.0)
			canvas.draw_rect(Rect2(o.x + 0.8 * 368, o.y + 50, 0.14 * 368, 16), Color(0.3, 0.75, 0.35, 0.6))
		else:
			canvas.draw_rect(Rect2(o.x + 130, o.y + 50, 110, 40), Color(0.9, 0.9, 0.95, 0.5))
			canvas.draw_rect(Rect2(o.x + 130 + keeper * 40, o.y + 62, 30, 24), Color(1, 0.6, 0.2))
			canvas.draw_circle(o + Vector2(130 + SportsModel.zone_of(aim) * 40 + 15, 60), 5, Color.WHITE)
	elif mode == "boxing":
		canvas.draw_string(font, o + Vector2(0, 28), "You", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.WHITE)
		canvas.draw_rect(Rect2(o.x + 40, o.y + 18, 140.0 * maxf(0.0, float(you_hp)) / 40.0, 10), Color(0.35, 0.8, 0.4))
		canvas.draw_string(font, o + Vector2(200, 28), "Opponent (tier %d)" % tier, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.WHITE)
		canvas.draw_rect(Rect2(o.x + 300, o.y + 18, 70.0 * maxf(0.0, float(opp)) / float(SportsModel.opp_hp(tier)), 10), Color(0.85, 0.35, 0.3))
		var msg := "Guard up..." if tele == 0 else ("<<  PUNCH LEFT" if tele < 0 else "PUNCH RIGHT  >>")
		canvas.draw_string(font, o + Vector2(80, 80), msg, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(1, 0.5, 0.3) if tele != 0 else Color(0.8, 0.85, 1))
		if tele != 0:
			canvas.draw_rect(Rect2(o.x + 60, o.y + 96, 240.0 * clampf(1.0 - tele_t / window, 0.0, 1.0), 6), Color(1, 0.9, 0.3))
		canvas.draw_string(font, o + Vector2(0, 126), "Round %d / %d    Left/Right: dodge that way   Space: jab" % [rounds + 1, SportsModel.ROUND_MAX], HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.8, 0.9, 1))
	canvas.draw_string(font, o + Vector2(0, 160), last_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 1, 0.7))
