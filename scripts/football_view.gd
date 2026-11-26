class_name FootballView
extends CanvasLayer
## Halden Sunday League match day (rules in FootballMatch / FootballLeague / FootballBall): a full-screen pitch
## with the table before and after. WASD run, Shift sprint, Space tap = pass or slide tackle, hold = shot,
## Q / E bend the shot, Tab swaps player, Esc twice forfeits.

signal closed
signal message(msg: String)
signal sound(name: String)

enum State { LOBBY, PLAY, RESULT }

const ORIGIN := Vector2(60, 74)       # screen position of the pitch's top-left corner
const FRAME := Vector2(24, 32)
const SOUNDS := {"kick": "ball_kick", "post": "ball_post", "wall": "step_wood", "tackle": "hit", "save": "ball_kick",
	"goal0": "crowd_cheer", "goal1": "whistle", "half": "whistle", "full": "whistle"}

var canvas: Control
var state: int = State.LOBBY
var game: FootballMatch
var rival := 1
var t := 0.0
var space_held := -1.0       # seconds Space has been held, -1 when up
var forfeit_t := 0.0
var banner := ""
var banner_t := 0.0
var shake := 0.0
var confetti: Array = []     # {pos, vel, col, age}
var trail: Array = []        # recent ball screen positions for fast shots
var last_result := ""
var block_reason := ""
var rain := 0.0              # today's rain, set by Main before kick-off
var wet := 0.0
var _tackle_queued := false
var _switch_queued := false
var _tex: Texture2D = load("res://assets/sprites/football_players.png")
var _ball_tex: Texture2D = load("res://assets/sprites/football_ball.png")
var _goal_tex: Texture2D = load("res://assets/sprites/football_goal.png")
var _crowd_tex: Texture2D = load("res://assets/sprites/football_crowd.png")

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
	var league: FootballLeague = GameState.football
	if league.season_done() and league.last_day != GameState.clock.day:
		league.start_next_season()
	block_reason = _blocked()
	state = State.LOBBY
	rival = league.opponent() if not league.season_done() else -1
	last_result = ""
	visible = true
	return true

func _blocked() -> String:
	return GameState.football.can_play(GameState.clock.day, GameState.money, GameState.energy.value, 6.0 + GameState.clock.minutes / 60.0)

func close() -> void:
	visible = false
	closed.emit()

func kick_off(seed_value: int = -1) -> void:
	var league: FootballLeague = GameState.football
	if league.season_done():
		league.start_next_season()
	GameState.money -= FootballLeague.MATCH_FEE
	GameState.energy.value -= FootballLeague.ENERGY_COST
	rival = league.opponent()
	game = FootballMatch.new(league.tier_of(0), league.tier_of(rival), seed_value if seed_value >= 0 else randi())
	wet = clampf((rain - 0.2) / 0.6, 0.0, 1.0)
	game.ball.wet = wet
	state = State.PLAY
	space_held = -1.0
	forfeit_t = 0.0
	confetti = []
	trail = []
	_show("KICK OFF - wet pitch, the ball skids" if wet > 0.3 else "KICK OFF", 1.6)
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
				if game.owner == game.selected:
					space_held = 0.0
				else:
					_tackle_queued = true
			elif not e.pressed and space_held >= 0.0:
				_release_kick()
		elif e.pressed and not e.echo:
			if key == KEY_TAB:
				_switch_queued = true
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
				kick_off()
			else:
				sound.emit("error")
	elif key == KEY_ESCAPE or key == KEY_E:
		close()

var _release: Dictionary = {}

func _release_kick() -> void:
	if space_held < FootballMatch.TAP_TIME:
		_release = {"pass": true}
	else:
		_release = {"shoot": space_held - FootballMatch.TAP_TIME}
	space_held = -1.0

func _input_for_tick() -> Dictionary:
	var inp := {
		"move": Input.get_vector("move_left", "move_right", "move_up", "move_down"),
		"sprint": Input.is_action_pressed("sprint"),
		"curl": (1.0 if Input.is_key_pressed(KEY_E) else 0.0) - (1.0 if Input.is_key_pressed(KEY_Q) else 0.0),
	}
	inp.merge(_release)
	_release = {}
	if _tackle_queued:
		inp["tackle"] = true
		_tackle_queued = false
	if _switch_queued:
		inp["switch"] = true
		_switch_queued = false
	return inp

func _process(delta: float) -> void:
	if not visible:
		return
	t += delta
	banner_t = maxf(0.0, banner_t - delta)
	forfeit_t = maxf(0.0, forfeit_t - delta)
	shake = maxf(0.0, shake - delta * 14.0)
	for c in confetti:
		c["age"] = float(c["age"]) + delta
		c["vel"] = (c["vel"] as Vector2) * exp(-1.8 * delta) + Vector2(0, 90) * delta
		c["pos"] = (c["pos"] as Vector2) + (c["vel"] as Vector2) * delta
	confetti = confetti.filter(func(c): return float(c["age"]) < 2.0)
	if state == State.PLAY:
		if space_held >= 0.0:
			space_held += delta
			if game.owner != game.selected:
				space_held = -1.0
		game.update(delta, _input_for_tick())
		_drain_events()
		if game.ball.vel.length() > 220.0 and game.owner < 0:
			trail.append(_to_screen(game.ball.pos) - Vector2(0, game.ball.z))
			if trail.size() > 7:
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
		match ev:
			"goal0", "goal1":
				var mine := ev == "goal0"
				_show("GOAL!" if mine else "They score", FootballMatch.CELEBRATE)
				shake = 5.0 if mine else 2.5
				trail = []
				_burst(Vector2(ORIGIN.x + (FootballBall.FIELD.x if mine else 0.0), ORIGIN.y + FootballBall.FIELD.y * 0.5), mine)
			"post":
				shake = maxf(shake, 2.0)
			"save":
				_show("Saved!", 0.7)
			"half":
				_show("HALF TIME", FootballMatch.CELEBRATE)
	game.events.clear()

func _burst(at: Vector2, mine: bool) -> void:
	var cols := [Color("f4c542"), Color("2b3a67"), Color("fff3c4")] if mine else [Color("c9c9c9"), Color("8a8a8a")]
	for i in (60 if mine else 20):
		var a := randf() * TAU
		confetti.append({"pos": at, "vel": Vector2.from_angle(a) * randf_range(40.0, 170.0) - Vector2(0, 60), "col": cols[i % cols.size()], "age": randf() * 0.4})

func _end_match(forfeited: bool) -> void:
	var mine := 0 if forfeited else int(game.score[0])
	var theirs := 3 if forfeited else int(game.score[1])
	var r: Dictionary = GameState.football.record(mine, theirs, GameState.clock.day)
	GameState.money += int(r["pay"])
	GameState.clock.minutes = minf(GameState.clock.minutes + FootballLeague.MATCH_MINUTES, float(GameClock.DAY_LENGTH_MIN) - 1.0)
	GameState.bump("football_matches")
	if mine > theirs:
		GameState.bump("football_wins")
		GameState.rep_honest += 3 if bool(r["champion"]) else 1
	last_result = ("Forfeit. " if forfeited else "") + String(r["text"])
	state = State.RESULT
	space_held = -1.0
	banner_t = 0.0
	message.emit(last_result)

# ---------------------------------------------------------------- drawing

func _to_screen(p: Vector2) -> Vector2:
	return ORIGIN + p

func _text(at: Vector2, s: String, size: int = 11, col: Color = Color.WHITE, width: float = -1.0, align: int = HORIZONTAL_ALIGNMENT_LEFT) -> void:
	var font := ThemeDB.fallback_font
	canvas.draw_string_outline(font, at, s, align, width, size, 4, Color(0.1, 0.06, 0.03))
	canvas.draw_string(font, at, s, align, width, size, col)

func _draw_all() -> void:
	canvas.draw_rect(Rect2(Vector2.ZERO, canvas.size), Color(0.1, 0.13, 0.1))
	var off := Vector2(sin(t * 71.0), cos(t * 57.0)) * shake
	canvas.draw_set_transform(off.round())
	_draw_pitch()
	if game != null and state != State.LOBBY:
		_draw_actors()
		if wet > 0.05:
			_draw_rain()
	canvas.draw_set_transform(Vector2.ZERO)
	for c in confetti:
		canvas.draw_rect(Rect2((c["pos"] as Vector2).round(), Vector2(3, 2)), Color(c["col"], clampf(2.0 - float(c["age"]), 0.0, 1.0)))
	match state:
		State.LOBBY:
			_draw_panel("Halden Sunday League   -   season %d" % GameState.football.season)
		State.RESULT:
			_draw_panel(last_result)
		State.PLAY:
			_draw_scoreboard()
			if banner_t > 0.0:
				var big := 28 if banner.begins_with("GOAL") else 18
				_text(Vector2(0, 190), banner, big, Color(1, 0.9, 0.35), 640, HORIZONTAL_ALIGNMENT_CENTER)
			_text(Vector2(0, 354), "WASD run  Shift sprint  Space: tap = pass / tackle, hold = shoot  Q/E bend  Tab swap  Esc forfeit", 10, Color(0.9, 0.95, 0.85), 640, HORIZONTAL_ALIGNMENT_CENTER)

func _draw_pitch() -> void:
	var f := FootballBall.FIELD
	var crowd_frame := 1 if banner_t > 0.0 and banner.begins_with("GOAL") and fmod(t, 0.3) < 0.15 else 0
	for x in [0, 320]:
		canvas.draw_texture_rect_region(_crowd_tex, Rect2(x, 40, 320, 24), Rect2(0, crowd_frame * 24, 320, 24))
		canvas.draw_texture_rect_region(_crowd_tex, Rect2(x, 322, 320, 24), Rect2(0, (1 - crowd_frame if crowd_frame == 1 else 0) * 24, 320, 24))
	canvas.draw_rect(Rect2(0, 64, 640, 258), Color("3f7a34"))
	for i in 10:   # mown stripes
		canvas.draw_rect(Rect2(ORIGIN.x + i * f.x / 10.0, ORIGIN.y, f.x / 10.0, f.y), Color("559a3f") if i % 2 == 0 else Color("4d8f39"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 40
	for i in 240:   # grass flecks so the turf is not flat
		var p := ORIGIN + Vector2(rng.randf() * f.x, rng.randf() * f.y)
		canvas.draw_rect(Rect2(p.floor(), Vector2(1, 2)), Color(0.75, 0.92, 0.45, 0.28) if i % 2 == 0 else Color(0.15, 0.32, 0.12, 0.3))
	for side in 2:   # worn goalmouths
		var gx := ORIGIN.x + (14.0 if side == 0 else f.x - 14.0)
		for i in 90:
			var p := Vector2(gx, ORIGIN.y + f.y * 0.5) + Vector2(rng.randfn(0.0, 7.0), rng.randfn(0.0, 17.0))
			canvas.draw_rect(Rect2(p.floor(), Vector2(2, 1)), Color(0.55, 0.4, 0.22, 0.5))
	var line := Color(0.95, 0.97, 0.9, 0.85)
	canvas.draw_rect(Rect2(ORIGIN, f), line, false, 2.0)
	canvas.draw_line(ORIGIN + Vector2(f.x * 0.5, 0), ORIGIN + Vector2(f.x * 0.5, f.y), line, 2.0)
	canvas.draw_arc(ORIGIN + f * 0.5, 34.0, 0.0, TAU, 48, line, 2.0)
	canvas.draw_circle(ORIGIN + f * 0.5, 2.5, line)
	canvas.draw_rect(Rect2(ORIGIN + Vector2(0, f.y * 0.5 - 66), Vector2(62, 132)), line, false, 2.0)
	canvas.draw_rect(Rect2(ORIGIN + Vector2(f.x - 62, f.y * 0.5 - 66), Vector2(62, 132)), line, false, 2.0)
	var gy := ORIGIN.y + f.y * 0.5 - 48.0
	canvas.draw_texture_rect(_goal_tex, Rect2(ORIGIN.x - 26, gy, 28, 96), false)
	canvas.draw_texture_rect(_goal_tex, Rect2(ORIGIN.x + f.x + 26, gy, -28, 96), false)

func _draw_rain() -> void:
	canvas.draw_rect(Rect2(0, 64, 640, 258), Color(0.1, 0.18, 0.3, 0.16 * wet))
	for i in int(110 * wet):
		var x := fposmod(i * 97.3 + t * 70.0, 660.0) - 10.0
		var y := fposmod(i * 53.9 + t * 390.0, 290.0) + 40.0
		canvas.draw_line(Vector2(x, y), Vector2(x + 2, y + 9), Color(0.75, 0.85, 1.0, 0.45), 1.0)
	if game.ball.z < 1.0 and game.ball.vel.length() > 90.0:   # spray off a skidding ball
		var back := -game.ball.vel.normalized()
		for k in 5:
			var p := _to_screen(game.ball.pos) + back * (5.0 + k * 3.0) + Vector2(0, -k % 3 - 1)
			canvas.draw_rect(Rect2(p.floor(), Vector2(2, 1)), Color(0.85, 0.93, 1.0, 0.8 - 0.14 * k))

func _frame_for(p: Dictionary) -> Array:
	## [column, flip]
	var face: Vector2 = p["face"]
	if float(p["kick_anim"]) > 0.0 or float(p["slide"]) > 0.0:
		return [4, face.x < 0.0]
	var moving: bool = (p["vel"] as Vector2).length() > 8.0
	var step := int(float(p["run"]) / 9.0)
	if moving and face.y > 0.75:
		return [5 + step % 2, false]
	if moving and face.y < -0.75:
		return [7, step % 2 == 1]
	return [step % 4 if moving else 0, face.x < 0.0]

func _draw_actors() -> void:
	var order := range(game.players.size())
	order.sort_custom(func(a, b): return game.players[a]["pos"].y < game.players[b]["pos"].y)
	var ball_screen := _to_screen(game.ball.pos)
	var ball_done := false
	for i in order:
		var p: Dictionary = game.players[i]
		if not ball_done and (p["pos"] as Vector2).y > game.ball.pos.y:
			_draw_ball(ball_screen)
			ball_done = true
		var at := _to_screen(p["pos"]).round()
		_ellipse(at + Vector2(0, 1), Vector2(7, 3), Color(0, 0, 0, 0.28))
		if i == game.selected:
			canvas.draw_arc(at + Vector2(0, 1), 9.0, 0.0, TAU, 20, Color(1, 0.9, 0.25), 2.0)
		var club: int = 0 if int(p["team"]) == 0 else rival
		var row := 4 if int(p["role"]) == 0 else club
		var fr := _frame_for(p)
		var src := Rect2(int(fr[0]) * FRAME.x, row * FRAME.y, FRAME.x, FRAME.y)
		var tint := Color.WHITE if not (int(p["role"]) == 0 and int(p["team"]) == 1) else Color(1.0, 0.78, 0.78)
		var dest := Rect2(at - Vector2(12, 30), Vector2(-FRAME.x if fr[1] else FRAME.x, FRAME.y))
		if float(p["down"]) > 0.0 or float(p["slide"]) > 0.0:   # on the deck
			var turn := 1.25 if (p["face"] as Vector2).x < 0.0 else -1.25
			canvas.draw_set_transform(at - Vector2(0, 5), turn)
			canvas.draw_texture_rect_region(_tex, Rect2(-12, -22, dest.size.x, dest.size.y), src, tint)
			canvas.draw_set_transform(Vector2.ZERO)
			if float(p["slide"]) > 0.0:
				for k in 4:
					canvas.draw_rect(Rect2(at - (p["face"] as Vector2) * (8.0 + k * 4.0) + Vector2(0, (k % 2) * 3 - 1), Vector2(2, 2)), Color(0.7, 0.85, 0.4, 0.8 - 0.17 * k))
		else:
			canvas.draw_texture_rect_region(_tex, dest, src, tint)
		if i == game.selected:
			canvas.draw_colored_polygon(PackedVector2Array([at + Vector2(-4, -39), at + Vector2(4, -39), at + Vector2(0, -34)]), Color(1, 0.9, 0.25))
			if float(p["stamina"]) < 0.98:
				canvas.draw_rect(Rect2(at + Vector2(-10, 5), Vector2(20, 3)), Color(0, 0, 0, 0.5))
				canvas.draw_rect(Rect2(at + Vector2(-10, 5), Vector2(20.0 * float(p["stamina"]), 3)), Color(0.4, 0.85, 1.0))
	if not ball_done:
		_draw_ball(ball_screen)
	if space_held > FootballMatch.TAP_TIME:
		var k := clampf((space_held - FootballMatch.TAP_TIME) / FootballMatch.CHARGE_TIME, 0.0, 1.0)
		var at := _to_screen(game.players[game.selected]["pos"]).round()
		canvas.draw_rect(Rect2(at + Vector2(-17, -49), Vector2(34, 7)), Color(0.08, 0.05, 0.03))
		var col := Color(0.4, 0.9, 0.35) if k < 0.55 else (Color(1.0, 0.8, 0.25) if k < 0.8 else Color(1.0, 0.35, 0.25))
		canvas.draw_rect(Rect2(at + Vector2(-16, -48), Vector2(32.0 * k, 5)), col)

func _ellipse(at: Vector2, r: Vector2, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 14:
		pts.append(at + Vector2(cos(TAU * i / 14.0) * r.x, sin(TAU * i / 14.0) * r.y))
	canvas.draw_colored_polygon(pts, col)

func _draw_ball(at: Vector2) -> void:
	for i in trail.size():
		canvas.draw_circle(trail[i], 1.0 + 2.0 * i / maxf(1.0, trail.size()), Color(1, 1, 1, 0.08 + 0.05 * i))
	var lift := game.ball.z
	var shrink := clampf(1.0 - lift / 90.0, 0.45, 1.0)
	_ellipse(at + Vector2(0, 2), Vector2(4.5, 2.2) * shrink, Color(0, 0, 0, 0.35 * shrink))
	var frame := int(game.ball.roll / 5.0) % 4
	if game.ball.vel.x < 0.0:
		frame = 3 - frame
	canvas.draw_texture_rect_region(_ball_tex, Rect2((at - Vector2(5, 8 + lift)).round(), Vector2(10, 10)), Rect2(frame * 10, 0, 10, 10))

func _draw_scoreboard() -> void:
	canvas.draw_rect(Rect2(130, 6, 380, 28), Color(0.16, 0.1, 0.05))
	canvas.draw_rect(Rect2(132, 8, 376, 24), Color(0.36, 0.24, 0.13))
	_text(Vector2(136, 25), FootballLeague.CLUBS[0], 12, Color(1, 0.86, 0.35), 138, HORIZONTAL_ALIGNMENT_RIGHT)
	_text(Vector2(278, 26), "%d - %d" % [game.score[0], game.score[1]], 16, Color.WHITE, 84, HORIZONTAL_ALIGNMENT_CENTER)
	_text(Vector2(366, 25), FootballLeague.CLUBS[rival], 12, Color(0.85, 0.92, 1.0), 138)
	_text(Vector2(516, 25), "%d'" % game.minute(), 13, Color(1, 0.95, 0.75))

func _draw_panel(head: String) -> void:
	var league: FootballLeague = GameState.football
	var box := Rect2(130, 62, 380, 236)
	canvas.draw_rect(box.grow(4), Color(0.16, 0.1, 0.05))
	canvas.draw_rect(box.grow(2), Color(0.62, 0.43, 0.23))
	canvas.draw_rect(box, Color(0.25, 0.17, 0.1, 0.97))
	_text(Vector2(box.position.x, 82), head, 13, Color(1, 0.9, 0.45), box.size.x, HORIZONTAL_ALIGNMENT_CENTER)
	var cols := [146.0, 176.0, 322.0, 350.0, 378.0, 406.0, 444.0, 476.0]
	var heads := ["", "Club", "P", "W", "D", "L", "Goals", "Pts"]
	for k in heads.size():
		_text(Vector2(cols[k], 106), heads[k], 10, Color(0.85, 0.75, 0.55))
	var order := league.standings()
	for n in order.size():
		var id: int = order[n]
		var row: Array = league.table[id]
		var y := 126.0 + n * 20.0
		if id == 0:
			canvas.draw_rect(Rect2(140, y - 14, 360, 19), Color(1, 0.85, 0.3, 0.18))
		var cells := [str(n + 1), FootballLeague.CLUBS[id], str(row[0]), str(row[1]), str(row[2]), str(row[3]), "%d:%d" % [row[4], row[5]], str(FootballLeague.points(row))]
		for k in cells.size():
			_text(Vector2(cols[k], y), cells[k], 11)
	_text(Vector2(146, 214), "Titles won: %d     Champions bonus $%d" % [league.titles, FootballLeague.CHAMPION_PAY], 10, Color(0.9, 0.85, 0.7))
	if state == State.LOBBY:
		if rival >= 0:
			_text(Vector2(146, 236), "Round %d of %d:  v %s  (skill %s)" % [league.round_i + 1, FootballLeague.ROUNDS.size(), FootballLeague.CLUBS[rival], "*".repeat(league.tier_of(rival))], 11)
			_text(Vector2(146, 254), "Win $%d   Draw $%d   Referee fee $%d, %d energy" % [FootballLeague.WIN_PAY, FootballLeague.DRAW_PAY, FootballLeague.MATCH_FEE, FootballLeague.ENERGY_COST], 10)
		var foot := "Space: kick off      Esc: leave" if block_reason == "" else block_reason + "      Esc: leave"
		_text(Vector2(box.position.x, 284), foot, 11, Color(0.75, 1.0, 0.65) if block_reason == "" else Color(1.0, 0.7, 0.55), box.size.x, HORIZONTAL_ALIGNMENT_CENTER)
	else:
		_text(Vector2(box.position.x, 284), "E / Esc: leave the pitch", 11, Color(0.75, 1.0, 0.65), box.size.x, HORIZONTAL_ALIGNMENT_CENTER)
