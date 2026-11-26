class_name HoopView
extends CanvasLayer
## Halden streetball (rules in HoopMatch / HoopBall / HoopLadder): a full-screen half court with the ladder
## before and after. WASD run, Shift sprint, Space: hold and let go in the green to shoot / jump,
## E: pass, steal or call for the ball, Tab swaps defender, Esc twice forfeits.

signal closed
signal message(msg: String)
signal sound(name: String)

enum State { LOBBY, PLAY, RESULT }

const ORIGIN := Vector2(100, 112)     # screen position of the court's top-left corner
const FRAME := Vector2(24, 34)
const SOUNDS := {"dribble": "step_wood", "rim": "ball_post", "board": "step_wood", "pass": "ball_kick",
	"block": "hit", "steal": "hit", "score0": "crowd_cheer", "score1": "ball_kick", "violation": "whistle",
	"overtime": "whistle", "full": "whistle", "jumpball": "whistle"}
const CALLS := {"block": ["BLOCKED!", 0.9], "steal": ["STEAL!", 0.9], "intercept": ["PICKED OFF!", 0.9],
	"violation": ["SHOT CLOCK", 1.2], "jumpball": ["CHECK BALL", 1.0], "overtime": ["TIED - next basket wins", 2.0]}

var canvas: Control
var state: int = State.LOBBY
var game: HoopMatch
var rival := 1
var t := 0.0
var forfeit_t := 0.0
var banner := ""
var banner_t := 0.0
var feedback := ""             # release timing call over the shooter
var feedback_col := Color.WHITE
var feedback_t := 0.0
var feedback_at := Vector2.ZERO
var net_swing := 0.0
var rim_shake := 0.0
var shake := 0.0
var confetti: Array = []       # {pos, vel, col, age}
var trail: Array = []
var last_result := ""
var block_reason := ""
var _release: Dictionary = {}  # one-shot presses waiting for the next update
var _tex: Texture2D = load("res://assets/sprites/bball_players.png")
var _ball_tex: Texture2D = load("res://assets/sprites/bball_ball.png")
var _court_tex: Texture2D = load("res://assets/sprites/bball_court.png")
var _back_tex: Texture2D = load("res://assets/sprites/bball_backdrop.png")

func _init() -> void:
	layer = 60
	canvas = Control.new()
	canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	canvas.draw.connect(_draw_all)
	add_child(canvas)
	visible = false

func open() -> bool:
	block_reason = _blocked()
	state = State.LOBBY
	rival = GameState.hoops.rival()
	game = null
	last_result = ""
	banner_t = 0.0
	feedback_t = 0.0
	confetti = []
	visible = true
	return true

func _blocked() -> String:
	return GameState.hoops.can_play(GameState.clock.day, GameState.money, GameState.energy.value, 6.0 + GameState.clock.minutes / 60.0)

func close() -> void:
	visible = false
	closed.emit()

func tip_off(seed_value: int = -1) -> void:
	GameState.money -= HoopLadder.MATCH_FEE
	GameState.energy.value -= HoopLadder.ENERGY_COST
	var ladder: HoopLadder = GameState.hoops
	rival = ladder.rival()
	game = HoopMatch.new(ladder.tier_of(0), ladder.tier_of(rival), seed_value if seed_value >= 0 else randi())
	state = State.PLAY
	forfeit_t = 0.0
	confetti = []
	trail = []
	_release = {}
	_show("FIRST TO %d - your ball" % HoopMatch.TARGET, 1.6)
	sound.emit("whistle")

func _show(text: String, secs: float) -> void:
	banner = text
	banner_t = secs

func handle(e: InputEvent) -> void:
	if not visible or not (e is InputEventKey):
		return
	var key: int = e.keycode
	if state == State.PLAY:
		if key == KEY_SPACE:
			if e.pressed and not e.echo:
				_release["shoot"] = true
			elif not e.pressed:
				_release["release"] = true
		elif e.pressed and not e.echo:
			if key == KEY_E:
				_release["pass"] = true
			elif key == KEY_TAB:
				_release["switch"] = true
			elif key == KEY_ESCAPE:
				if forfeit_t > 0.0:
					_end_match(true)
				else:
					forfeit_t = 2.0
					_show("Esc again to forfeit", 2.0)
		return
	if not e.pressed or e.echo:
		return
	if state == State.LOBBY:
		if key == KEY_ESCAPE or key == KEY_E:
			close()
		elif key == KEY_SPACE:
			block_reason = _blocked()
			if block_reason == "":
				tip_off()
			else:
				sound.emit("error")
	elif key == KEY_ESCAPE or key == KEY_E:
		close()

func _input_for_tick() -> Dictionary:
	var inp := {"move": Input.get_vector("move_left", "move_right", "move_up", "move_down"), "sprint": Input.is_action_pressed("sprint")}
	inp.merge(_release)
	_release = {}   # HoopMatch keeps them until a tick really runs
	return inp

func _process(delta: float) -> void:
	if not visible:
		return
	t += delta
	banner_t = maxf(0.0, banner_t - delta)
	feedback_t = maxf(0.0, feedback_t - delta)
	forfeit_t = maxf(0.0, forfeit_t - delta)
	net_swing = maxf(0.0, net_swing - delta)
	rim_shake = maxf(0.0, rim_shake - delta * 9.0)
	shake = maxf(0.0, shake - delta * 14.0)
	for c in confetti:
		c["age"] = float(c["age"]) + delta
		c["vel"] = (c["vel"] as Vector2) * exp(-1.8 * delta) + Vector2(0, 90) * delta
		c["pos"] = (c["pos"] as Vector2) + (c["vel"] as Vector2) * delta
	confetti = confetti.filter(func(c): return float(c["age"]) < 1.8)
	if state == State.PLAY:
		game.update(delta, _input_for_tick())
		_drain_events()
		if game.owner < 0 and game.ball.shot:
			trail.append(_screen(game.ball.pos, game.ball.z))
			if trail.size() > 8:
				trail.pop_front()
		elif not trail.is_empty():
			trail.pop_front()
		if game.finished:
			_end_match(false)
	canvas.size = get_viewport().get_visible_rect().size
	canvas.queue_redraw()

func _drain_events() -> void:
	for ev: String in game.events:
		if SOUNDS.has(ev):
			sound.emit(SOUNDS[ev])
		if CALLS.has(ev):
			_show(CALLS[ev][0], CALLS[ev][1])
		match ev:
			"shot", "perfect":
				_call_release()
			"rim":
				rim_shake = 2.5
			"board":
				rim_shake = maxf(rim_shake, 1.2)
			"score0", "score1":
				var mine := ev == "score0"
				var pts := int(game.last_release.get("points", 2))
				_show(("+%d  BUCKET!" if mine else "+%d  they score") % pts, HoopMatch.SCORE_PAUSE)
				net_swing = 0.7
				shake = 3.0 if mine else 1.0
				_burst(_screen(HoopBall.RIM, HoopBall.RIM_Z - 10.0), mine, 46 if pts == 3 else 28)
			"clear_first":
				_show("Take it back past the arc first", 1.2)
				sound.emit("error")
	game.events.clear()

func _call_release() -> void:
	## Timing and pressure of your own team's release, floated over the shooter.
	var r: Dictionary = game.last_release
	var p: Dictionary = game.players[int(r["player"])]
	if int(p["team"]) != 0:
		return
	var m := float(r["meter"])
	if float(r["quality"]) >= 1.0:
		feedback = "PERFECT"
		feedback_col = Color(0.55, 1.0, 0.45)
	elif float(r["quality"]) > 0.55:
		feedback = "good"
		feedback_col = Color(1.0, 0.95, 0.55)
	else:
		feedback = "early" if m < HoopMatch.SWEET else "late"
		feedback_col = Color(1.0, 0.62, 0.4)
	if float(r["contest"]) > 0.45:
		feedback += " - contested"
	feedback_at = _screen(p["pos"], 52.0)
	feedback_t = 1.1

func _burst(at: Vector2, mine: bool, n: int) -> void:
	var cols := [Color("f4c542"), Color("ff7a22"), Color("fff3c4")] if mine else [Color("c9c9c9"), Color("8a8a8a")]
	for i in (n if mine else n / 3):
		confetti.append({"pos": at, "vel": Vector2.from_angle(randf() * TAU) * randf_range(30.0, 140.0) - Vector2(0, 40), "col": cols[i % cols.size()], "age": randf() * 0.3})

func _end_match(forfeited: bool) -> void:
	var mine := 0 if forfeited else int(game.score[0])
	var theirs := HoopMatch.TARGET if forfeited else int(game.score[1])
	var r: Dictionary = GameState.hoops.record(mine, theirs, GameState.clock.day)
	GameState.money += int(r["pay"])
	GameState.clock.minutes = minf(GameState.clock.minutes + HoopLadder.MATCH_MINUTES, float(GameClock.DAY_LENGTH_MIN) - 1.0)
	GameState.bump("bball_matches")
	if bool(r["won"]):
		GameState.bump("bball_wins")
		GameState.rep_street += 3 if bool(r["crown"]) else 1
	last_result = ("Forfeit. " if forfeited else "") + String(r["text"])
	state = State.RESULT
	banner_t = 0.0
	feedback_t = 0.0
	trail = []
	message.emit(last_result)

# ---------------------------------------------------------------- drawing

func _screen(p: Vector2, z: float = 0.0) -> Vector2:
	return ORIGIN + p - Vector2(0, z)

func _text(at: Vector2, s: String, size: int = 11, col: Color = Color.WHITE, width: float = -1.0, align: int = HORIZONTAL_ALIGNMENT_LEFT) -> void:
	var font := ThemeDB.fallback_font
	canvas.draw_string_outline(font, at, s, align, width, size, 4, Color(0.1, 0.06, 0.03))
	canvas.draw_string(font, at, s, align, width, size, col)

func _ellipse(at: Vector2, r: Vector2, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 14:
		pts.append(at + Vector2(cos(TAU * i / 14.0) * r.x, sin(TAU * i / 14.0) * r.y))
	canvas.draw_colored_polygon(pts, col)

func _draw_all() -> void:
	canvas.draw_rect(Rect2(Vector2.ZERO, canvas.size), Color(0.13, 0.12, 0.16))
	var off := (Vector2(sin(t * 71.0), cos(t * 57.0)) * shake).round()
	canvas.draw_set_transform(off)
	canvas.draw_texture(_back_tex, Vector2.ZERO)
	canvas.draw_texture(_court_tex, ORIGIN)
	if game != null and state == State.PLAY and game.owner >= 0 and game.must_clear:
		canvas.draw_arc(ORIGIN + HoopBall.RIM, HoopBall.ARC, 0.0, PI, 64, Color(1.0, 0.86, 0.2, 0.55 + 0.35 * sin(t * 7.0)), 3.0)
	_draw_hoop_back()
	if game != null and state != State.LOBBY:
		_draw_actors()
	else:
		_draw_hoop_front()
	canvas.draw_set_transform(Vector2.ZERO)
	for c in confetti:
		canvas.draw_rect(Rect2((c["pos"] as Vector2).round(), Vector2(3, 2)), Color(c["col"], clampf(1.8 - float(c["age"]), 0.0, 1.0)))
	match state:
		State.LOBBY:
			_draw_panel("Halden Streetball  -  3 on 3")
		State.RESULT:
			_draw_panel(last_result)
		State.PLAY:
			_draw_scoreboard()
			if feedback_t > 0.0:
				_text(feedback_at + Vector2(-80, -(1.1 - feedback_t) * 12.0), feedback, 12, feedback_col, 160, HORIZONTAL_ALIGNMENT_CENTER)
			if banner_t > 0.0:
				_text(Vector2(0, 232), banner, 24 if banner.contains("BUCKET") else 17, Color(1, 0.9, 0.35), 640, HORIZONTAL_ALIGNMENT_CENTER)
			_text(Vector2(0, 358), "WASD run  Shift sprint  Space: hold, let go in green = shoot / tap = jump  E pass, steal, call  Tab swap  Esc quit", 9, Color(0.95, 0.93, 0.85), 640, HORIZONTAL_ALIGNMENT_CENTER)

func _draw_hoop_back() -> void:
	var left := ORIGIN.x + HoopBall.RIM.x - HoopBall.BOARD_HALF
	var top := ORIGIN.y + HoopBall.BOARD_Y - HoopBall.BOARD_Z1
	var h := HoopBall.BOARD_Z1 - HoopBall.BOARD_Z0
	var mid := ORIGIN.x + HoopBall.RIM.x
	_ellipse(ORIGIN + Vector2(HoopBall.RIM.x, 8), Vector2(14, 4), Color(0, 0, 0, 0.3))
	canvas.draw_rect(Rect2(mid - 4, top + 8, 8, ORIGIN.y + 8 - top - 8), Color(0.13, 0.08, 0.04))
	canvas.draw_rect(Rect2(mid - 3, top + 8, 6, ORIGIN.y + 8 - top - 9), Color("8c93a0"))
	canvas.draw_rect(Rect2(mid - 5, ORIGIN.y - 18, 10, 24), Color("c8322e"))
	var shift := Vector2(0, sin(t * 60.0) * rim_shake * 0.6).round()
	canvas.draw_rect(Rect2(left - 2, top - 2, HoopBall.BOARD_HALF * 2 + 4, h + 4).abs(), Color(0.13, 0.08, 0.04))
	canvas.draw_rect(Rect2(Vector2(left, top) + shift, Vector2(HoopBall.BOARD_HALF * 2, h)), Color("efe9d6"))
	canvas.draw_rect(Rect2(Vector2(left + 2, top + 2) + shift, Vector2(HoopBall.BOARD_HALF * 2 - 4, h - 4)), Color("d23232"), false, 1.0)
	canvas.draw_rect(Rect2(Vector2(mid - 10, top + h - 18) + shift, Vector2(20, 14)), Color("d23232"), false, 2.0)
	_rim_arc(PI, TAU)

func _rim_centre() -> Vector2:
	return _screen(HoopBall.RIM, HoopBall.RIM_Z) + Vector2(0, sin(t * 60.0) * rim_shake).round()

func _rim_arc(from: float, to: float) -> void:
	var c := _rim_centre()
	var pts := PackedVector2Array()
	for i in 13:
		var a := lerpf(from, to, i / 12.0)
		pts.append(c + Vector2(cos(a) * (HoopBall.RIM_R + 1.0), sin(a) * 5.0))
	canvas.draw_polyline(pts, Color(0.16, 0.07, 0.02), 4.0)
	canvas.draw_polyline(pts, Color("ff7a22"), 2.0)

func _draw_hoop_front() -> void:
	var c := _rim_centre()
	var swing := sin(net_swing * 30.0) * net_swing * 5.0
	var drop := 15.0 + (4.0 * sin(clampf(net_swing / 0.7, 0.0, 1.0) * PI) if net_swing > 0.0 else 0.0)
	var white := Color(0.96, 0.96, 0.98, 0.9)
	for i in 6:
		var x := -HoopBall.RIM_R + i * HoopBall.RIM_R * 0.4
		var next := -HoopBall.RIM_R + (i + 1) * HoopBall.RIM_R * 0.4
		var low := c + Vector2(x * 0.5 + swing, drop)
		canvas.draw_line(c + Vector2(x, 4), low, white, 1.0)
		if i < 5:
			canvas.draw_line(c + Vector2(next, 4), low, white, 1.0)
	canvas.draw_line(c + Vector2(-7 + swing * 0.5, drop * 0.62), c + Vector2(7 + swing * 0.5, drop * 0.62), white, 1.0)
	_rim_arc(0.0, PI)

func _frame_for(p: Dictionary, i: int) -> Array:
	## [column, flip]
	var face: Vector2 = p["face"]
	if float(p["z"]) > 2.0 or float(p["throw"]) > 0.0:
		return [9 if face.y < -0.2 else 10, false]
	var speed := (p["vel"] as Vector2).length()
	var step := int(float(p["run"]) / 8.0)
	if speed > 10.0:
		if absf(face.y) > 0.8:
			return [(5 if face.y > 0.0 else 7) + step % 2, false]
		return [1 + step % 4, face.x < 0.0]
	if face.y < -0.55:
		return [7 + (int(t * 3.0 + i) % 2 if game.owner == i else 0), false]
	return [0, false]

func _draw_actors() -> void:
	var order := range(game.players.size())
	order.sort_custom(func(a, b): return game.players[a]["pos"].y < game.players[b]["pos"].y)
	var b := game.ball
	var held := game.owner >= 0
	var near_rim := b.pos.distance_to(HoopBall.RIM) < HoopBall.RIM_R + 8.0 and b.pos.y > HoopBall.BOARD_Y
	var behind_net := near_rim and b.z < HoopBall.RIM_Z + 2.0 and b.z > HoopBall.RIM_Z - 22.0 and not held
	for i in order:   # shadows and your marker go under everybody
		var at := _screen(game.players[i]["pos"]).round()
		var air := clampf(1.0 - float(game.players[i]["z"]) / 60.0, 0.5, 1.0)
		_ellipse(at + Vector2(0, 1), Vector2(8, 3) * air, Color(0, 0, 0, 0.32))
		if int(game.players[i]["team"]) == 0 and int(game.players[i]["role"]) == game.selected:
			canvas.draw_arc(at + Vector2(0, 1), 10.0, 0.0, TAU, 20, Color(1, 0.9, 0.25), 2.0)
	var lift := b.z
	_ellipse(_screen(b.pos) + Vector2(0, 2), Vector2(5, 2.4) * clampf(1.0 - lift / 160.0, 0.4, 1.0), Color(0, 0, 0, 0.35))
	var hoop_done := false
	var ball_done := false
	for i in order:
		var p: Dictionary = game.players[i]
		if not ball_done and not behind_net and b.z < 40.0 and (p["pos"] as Vector2).y > b.pos.y:
			_draw_ball()
			ball_done = true
		if not hoop_done and (p["pos"] as Vector2).y > HoopBall.RIM.y + 8.0:
			if behind_net:
				_draw_ball()
				ball_done = true
			_draw_hoop_front()
			hoop_done = true
		var at := _screen(p["pos"]).round()
		var club: int = 0 if int(p["team"]) == 0 else rival
		var fr := _frame_for(p, i)
		var src := Rect2(int(fr[0]) * FRAME.x, (club * 3 + int(p["role"])) * FRAME.y, FRAME.x, FRAME.y)
		var up := float(p["z"]) * 0.65
		canvas.draw_texture_rect_region(_tex, Rect2(at - Vector2(12, 32 + roundf(up)), Vector2(-FRAME.x if fr[1] else FRAME.x, FRAME.y)), src)
		if float(p["stun"]) > 0.0:
			for k in 3:
				canvas.draw_circle(at + Vector2(cos(t * 9.0 + k * 2.1) * 7.0, -36.0 + sin(t * 9.0 + k * 2.1) * 2.0), 1.2, Color(1, 0.95, 0.4))
	if not hoop_done:
		if behind_net:
			_draw_ball()
			ball_done = true
		_draw_hoop_front()
	if not ball_done:
		_draw_ball()
	_draw_markers()

func _draw_markers() -> void:
	var i := game.selected
	var p: Dictionary = game.players[i]
	var at := _screen(p["pos"]).round()
	var head := at - Vector2(0, 40 + float(p["z"]) * 0.65 + (6.0 if game.owner == i else 0.0))
	canvas.draw_colored_polygon(PackedVector2Array([head + Vector2(-4, -3), head + Vector2(4, -3), head + Vector2(0, 2)]), Color(1, 0.9, 0.25))
	if state != State.PLAY:
		return
	if float(p["stamina"]) < 0.98:
		canvas.draw_rect(Rect2(at + Vector2(-10, 5), Vector2(20, 3)), Color(0, 0, 0, 0.5))
		canvas.draw_rect(Rect2(at + Vector2(-10, 5), Vector2(20.0 * float(p["stamina"]), 3)), Color(0.4, 0.85, 1.0))
	if game.owner == i and float(p["meter"]) < 0.0:
		var tag := "TAKE IT BACK" if game.must_clear else ("3 PT" if HoopBall.is_three(p["pos"]) else "2 PT")
		_text(at + Vector2(-50, 16), tag, 9, Color(1.0, 0.8, 0.3) if game.must_clear else Color(0.9, 0.97, 1.0), 100, HORIZONTAL_ALIGNMENT_CENTER)
	if float(p["meter"]) >= 0.0:   # the release meter: let go with the needle in the green
		var h := 44.0
		var bar := Rect2((at + Vector2(16, -50)).round(), Vector2(8, h))
		canvas.draw_rect(bar.grow(2), Color(0.1, 0.06, 0.03))
		canvas.draw_rect(bar, Color(0.28, 0.22, 0.18))
		var y_of := func(m: float) -> float: return bar.end.y - h * m
		var wide := 0.15
		canvas.draw_rect(Rect2(bar.position.x, y_of.call(HoopMatch.SWEET + wide), 8, h * wide * 2.0), Color(0.95, 0.76, 0.2))
		canvas.draw_rect(Rect2(bar.position.x, y_of.call(HoopMatch.SWEET + HoopMatch.PERFECT), 8, h * HoopMatch.PERFECT * 2.0), Color(0.3, 0.95, 0.35))
		var fill := h * clampf(float(p["meter"]), 0.0, 1.0)
		canvas.draw_rect(Rect2(bar.position.x, bar.end.y - fill, 8, fill), Color(1.0, 0.97, 0.85, 0.28))
		var ny: float = y_of.call(clampf(float(p["meter"]), 0.0, 1.0))
		canvas.draw_rect(Rect2(bar.position.x - 3, roundf(ny) - 1, 14, 3), Color(0.1, 0.06, 0.03))
		canvas.draw_rect(Rect2(bar.position.x - 2, roundf(ny), 12, 1), Color.WHITE)

func _draw_ball() -> void:
	for i in trail.size():
		canvas.draw_circle(trail[i], 1.0 + 2.0 * i / maxf(1.0, trail.size()), Color(1.0, 0.6, 0.25, 0.05 + 0.04 * i))
	var frame := int(game.ball.spin / 5.0) % 4
	var held_up := 0.0
	if game.owner >= 0 and float(game.players[game.owner]["meter"]) >= 0.0:
		held_up = -float(game.players[game.owner]["z"]) * 0.35
	canvas.draw_texture_rect_region(_ball_tex, Rect2((_screen(game.ball.pos, game.ball.z + held_up) - Vector2(5.5, 5.5)).round(), Vector2(11, 11)), Rect2(frame * 11, 0, 11, 11))

func _draw_scoreboard() -> void:
	var box := Rect2(112, 8, 416, 34)
	WoodUI.panel(canvas, box, "", WoodUI.Trim.EMBER)
	WoodUI.text(canvas, Vector2(118, 23), HoopLadder.CREWS[0], 11, WoodUI.CREAM, 144, HORIZONTAL_ALIGNMENT_RIGHT)
	WoodUI.text(canvas, Vector2(378, 23), HoopLadder.CREWS[rival], 11, WoodUI.CREAM, 144)
	for k in 2:   # chalk score tiles
		var tile := Rect2(268 + k * 56, 9, 48, 20)
		canvas.draw_rect(tile.grow(1), WoodUI.OUTLINE)
		canvas.draw_rect(tile, Color(0.12, 0.16, 0.14))
		WoodUI.text(canvas, Vector2(tile.position.x, 25), str(game.score[k]), 17, Color(1, 0.88, 0.4) if k == 0 else Color(0.86, 0.93, 1.0), 48, HORIZONTAL_ALIGNMENT_CENTER)
	var left := int(ceilf(game.time_left()))
	var clock := "NEXT BASKET WINS" if game.overtime else "TIME %d:%02d" % [left / 60, left % 60]
	WoodUI.text(canvas, Vector2(120, 40), clock, 10, WoodUI.INK)
	WoodUI.text(canvas, Vector2(112, 40), "first to %d" % HoopMatch.TARGET, 10, WoodUI.INK_SOFT, 416, HORIZONTAL_ALIGNMENT_CENTER)
	var mine := game.offense == 0
	WoodUI.text(canvas, Vector2(370, 40), "%s ball  %d" % ["YOUR" if mine else "THEIR", int(ceilf(maxf(0.0, game.shot_clock)))], 10, WoodUI.BAD if game.shot_clock < 4.0 else WoodUI.INK, 150, HORIZONTAL_ALIGNMENT_RIGHT)

func _draw_panel(head: String) -> void:
	var ladder: HoopLadder = GameState.hoops
	var box := Rect2(135, 70, 370, 232)
	WoodUI.panel(canvas, box, head, WoodUI.Trim.EMBER)
	WoodUI.text(canvas, Vector2(150, 112), "Crew ladder", 11, WoodUI.INK_SOFT)
	WoodUI.text(canvas, Vector2(380, 112), "skill", 10, WoodUI.INK_SOFT)
	for n in 3:   # top rung first
		var rung := 2 - n
		var r := Rect2(148, 118 + n * 21, 344, 19)
		var here := state == State.LOBBY and rung == ladder.rung
		WoodUI.row(canvas, r, here, rung <= ladder.rung)
		var mark := "beaten" if rung < ladder.rung else ("NEXT" if rung == ladder.rung else "locked")
		WoodUI.text(canvas, r.position + Vector2(8, 14), "%d.  %s" % [rung + 1, HoopLadder.CREWS[rung + 1]], 11)
		WoodUI.text(canvas, Vector2(380, r.position.y + 14), "*".repeat(ladder.tier_of(rung + 1)), 12)
		WoodUI.text(canvas, r.position + Vector2(0, 14), mark, 10, WoodUI.GOOD if rung < ladder.rung else WoodUI.INK_SOFT, r.size.x - 8, HORIZONTAL_ALIGNMENT_RIGHT)
	WoodUI.text(canvas, Vector2(150, 196), "Record %d-%d    Crowns %d    Best win by %d" % [ladder.wins, ladder.losses, ladder.crowns, ladder.best_margin], 10)
	if state == State.LOBBY:
		var bonus := " (with the $%d crown bonus)" % HoopLadder.CROWN_PAY if ladder.rung == 2 else ""
		WoodUI.text(canvas, Vector2(150, 215), "Win $%d%s" % [ladder.prize(), bonus], 11, WoodUI.PRICE)
		WoodUI.text(canvas, Vector2(150, 231), "Court fee $%d, %d energy. One money game a day." % [HoopLadder.MATCH_FEE, HoopLadder.ENERGY_COST], 10)
		WoodUI.text(canvas, Vector2(150, 249), "2s inside the arc, 3s outside. First to %d or %d minutes." % [HoopMatch.TARGET, int(HoopMatch.TIME_LIMIT / 60.0)], 10, WoodUI.INK_SOFT)
		WoodUI.text(canvas, Vector2(150, 263), "After a rebound or steal, take it back past the arc.", 10, WoodUI.INK_SOFT)
		var foot := "Space: check ball      Esc: leave" if block_reason == "" else block_reason + "      Esc: leave"
		WoodUI.text(canvas, Vector2(135, 291), foot, 11, WoodUI.GOOD if block_reason == "" else WoodUI.BAD, 370, HORIZONTAL_ALIGNMENT_CENTER)
	else:
		if game != null:
			var s: Dictionary = game.stats
			for k in 2:
				WoodUI.text(canvas, Vector2(150, 220 + k * 17), "%s:  %d/%d shots, %d/%d threes, %d boards, %d steals, %d blocks" % ["You" if k == 0 else "Them", s["fgm"][k], s["fga"][k], s["tpm"][k], s["tpa"][k], s["reb"][k], s["stl"][k], s["blk"][k]], 10)
		WoodUI.text(canvas, Vector2(135, 291), "E / Esc: leave the court", 11, WoodUI.GOOD, 370, HORIZONTAL_ALIGNMENT_CENTER)
