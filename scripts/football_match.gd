class_name FootballMatch
extends RefCounted
## Pure 4-a-side match (3 outfield + a keeper each) on top of FootballBall: dribbling, passing, charged and
## curled shots, tackles, simple team AI, two halves. Team 0 (you) attacks right. Deterministic for a seed.

const HALF_TIME := 60.0
const TICK := 1.0 / 60.0
const RUN := 82.0
const SPRINT := 118.0
const KEEPER_SPEED := 62.0
const ACCEL := 520.0
const REACH := 10.0
const KEEPER_REACH := 12.0
const CONTROL_SPEED := 250.0    # a ball faster than this cannot be trapped by an outfield player
const KICK_LOCK := 0.35
const TACKLE_TIME := 0.28
const TACKLE_SPEED := 175.0
const TACKLE_DOWN := 0.55
const CHARGE_TIME := 0.8
const TAP_TIME := 0.18
const SHOT_MIN := 210.0
const SHOT_MAX := 400.0
const CELEBRATE := 2.2

var ball := FootballBall.new()
var players: Array = []       # dictionaries, see _player()
var owner := -1
var score := [0, 0]
var half := 1
var clock := 0.0              # seconds played in this half
var pause := 1.2              # kick-off / celebration freeze
var finished := false
var selected := 2             # the team-0 player you control
var tier := [1, 1]
var auto := false             # true: the AI plays team 0 too (balance tests, demos)
var events: Array = []        # drained by the view: "kick", "goal0", "goal1", "post", "wall", "tackle", "save", "half", "full"
var last_touch := -1
var stats := {"shots": [0, 0], "saves": [0, 0]}
var rng := RandomNumberGenerator.new()
var _carry := 0.0
var _pending: Dictionary = {}
var _contest := 0.0
var _switch_lock := 0.0
var _kickoff_team := 0

func _init(tier_home: int = 1, tier_away: int = 1, seed_value: int = 1) -> void:
	tier = [tier_home, tier_away]
	rng.seed = seed_value
	for team in 2:
		for i in 4:
			players.append(_player(team, i))
	kickoff(0)

func _player(team: int, role: int) -> Dictionary:
	return {"team": team, "role": role, "pos": Vector2.ZERO, "vel": Vector2.ZERO, "face": Vector2(1 if team == 0 else -1, 0),
		"lock": 0.0, "slide": 0.0, "down": 0.0, "kick_anim": 0.0, "hold": 0.0, "stamina": 1.0, "run": 0.0}

static func keeper_index(team: int) -> int:
	return team * 4

## Team-relative formation spot (as if attacking right). role 0 keeper, 1 back, 2 and 3 wingers.
static func home_spot(role: int) -> Vector2:
	var f := FootballBall.FIELD
	match role:
		0: return Vector2(10.0, f.y * 0.5)
		1: return Vector2(f.x * 0.22, f.y * 0.5)
		2: return Vector2(f.x * 0.42, f.y * 0.25)
		_: return Vector2(f.x * 0.42, f.y * 0.75)

static func mirror(p: Vector2, team: int) -> Vector2:
	return p if team == 0 else Vector2(FootballBall.FIELD.x - p.x, p.y)

static func goal_of(team: int) -> Vector2:
	## Centre of the goal that `team` attacks.
	return Vector2(FootballBall.FIELD.x if team == 0 else 0.0, FootballBall.FIELD.y * 0.5)

static func speed_scale(t: int) -> float:
	return 0.91 + 0.035 * float(clampi(t, 0, 4))

static func shot_speed(charge: float) -> float:
	return lerpf(SHOT_MIN, SHOT_MAX, clampf(charge / CHARGE_TIME, 0.0, 1.0))

static func shot_lift(charge: float) -> float:
	## Gentle shots stay down, overhit ones sail over the bar.
	var k := clampf(charge / CHARGE_TIME, 0.0, 1.0)
	if k < 0.55:
		return 0.0
	return lerpf(0.0, 175.0, (k - 0.55) / 0.45)

func kickoff(team: int) -> void:
	_kickoff_team = team
	var c := FootballBall.FIELD * 0.5
	for p in players:
		p["pos"] = mirror(home_spot(int(p["role"])), int(p["team"]))
		p["vel"] = Vector2.ZERO
		p["face"] = Vector2(1 if int(p["team"]) == 0 else -1, 0)
		p["lock"] = 0.0
		p["slide"] = 0.0
		p["down"] = 0.0
		p["hold"] = 0.0
	var taker := team * 4 + 2
	players[taker]["pos"] = c + Vector2(-8 if team == 0 else 8, 0)
	ball.reset(c)
	owner = taker
	last_touch = taker
	_contest = 0.0
	_switch_lock = 0.0
	selected = 2

func time_left() -> float:
	return maxf(0.0, HALF_TIME - clock)

## Match minute as shown on the scoreboard (0..90).
func minute() -> int:
	return int(45.0 * float(half - 1) + 45.0 * clampf(clock / HALF_TIME, 0.0, 1.0))

func result() -> int:
	## +1 you win, 0 draw, -1 loss.
	return signi(int(score[0]) - int(score[1]))

## Advances the match. `input`: {"move": Vector2, "sprint": bool, "shoot": float charge or -1, "pass": bool,
## "tackle": bool, "curl": float -1..1, "switch": bool}. One-shot actions are applied on the first tick only.
func update(dt: float, input: Dictionary = {}) -> void:
	for k in ["shoot", "pass", "tackle", "switch"]:
		if input.has(k):
			_pending[k] = input[k]
			if k == "shoot":
				_pending["curl"] = input.get("curl", 0.0)
	_carry += minf(dt, 0.25)
	while _carry >= TICK - 0.00001:
		_carry -= TICK
		var now := {"move": input.get("move", Vector2.ZERO), "sprint": input.get("sprint", false)}
		now.merge(_pending, true)   # a press waits here until a tick really runs (fast displays have empty frames)
		_pending = {}
		_tick(TICK, now)

func _tick(dt: float, input: Dictionary) -> void:
	if finished:
		return
	if pause > 0.0:
		pause -= dt
		if pause <= 0.0 and _kickoff_team >= 0:
			pause = 0.0
		return
	clock += dt
	if clock >= HALF_TIME:
		if half == 1:
			half = 2
			clock = 0.0
			kickoff(1)
			pause = CELEBRATE
			events.append("half")
		else:
			finished = true
			events.append("full")
		return
	_switch_lock = maxf(0.0, _switch_lock - dt)
	if not auto:
		_pick_selected(bool(input.get("switch", false)))
	var chasers := [_chaser(0), _chaser(1)]
	for i in players.size():
		var p: Dictionary = players[i]
		p["lock"] = maxf(0.0, float(p["lock"]) - dt)
		p["kick_anim"] = maxf(0.0, float(p["kick_anim"]) - dt)
		if float(p["down"]) > 0.0:
			p["down"] = float(p["down"]) - dt
			p["vel"] = (p["vel"] as Vector2).move_toward(Vector2.ZERO, ACCEL * dt)
		elif float(p["slide"]) > 0.0:
			p["slide"] = float(p["slide"]) - dt
			if float(p["slide"]) <= 0.0:
				p["down"] = TACKLE_DOWN if owner != i else 0.0
		elif i == selected and int(p["team"]) == 0 and not auto:
			_human(i, input, dt)
		else:
			_ai(i, int(chasers[int(p["team"])]), dt)
		p["pos"] = ((p["pos"] as Vector2) + (p["vel"] as Vector2) * dt).clamp(Vector2(4, 4), FootballBall.FIELD - Vector2(4, 4))
		p["run"] = float(p["run"]) + (p["vel"] as Vector2).length() * dt
	_separate()
	_tackles()
	if owner >= 0:
		_dribble(dt)
	else:
		_step_ball(dt)
		_collect()

func _step_ball(dt: float) -> void:
	var ev := ball.step(dt)
	if ev == "goal_left" or ev == "goal_right":
		var scorer := 1 if ev == "goal_left" else 0
		score[scorer] = int(score[scorer]) + 1
		events.append("goal%d" % scorer)
		kickoff(1 - scorer)
		pause = CELEBRATE
	elif ev != "":
		events.append(ev)

func _pick_selected(manual: bool) -> void:
	var best := -1
	var bd := INF
	if owner >= 0 and owner < 4 and owner != keeper_index(0):
		selected = owner
		return
	for i in range(1, 4):
		if manual and i == selected:
			continue
		var d: float = (players[i]["pos"] as Vector2).distance_to(ball.predict(0.25))
		if d < bd:
			bd = d
			best = i
	if manual:
		selected = best
		_switch_lock = 1.2
	elif _switch_lock <= 0.0 and best != selected:
		var cur: float = (players[selected]["pos"] as Vector2).distance_to(ball.predict(0.25))
		if bd < cur - 30.0:     # hysteresis: do not flicker between two team-mates
			selected = best
			_switch_lock = 0.4

func _chaser(team: int) -> int:
	## The team's outfield player who presses the ball; the human's player counts for team 0.
	var best := -1
	var bd := INF
	for i in range(team * 4 + 1, team * 4 + 4):
		if team == 0 and not auto and i == selected:
			continue
		if float(players[i]["down"]) > 0.0:
			continue
		var d: float = (players[i]["pos"] as Vector2).distance_to(ball.predict(0.3))
		if d < bd:
			bd = d
			best = i
	return best

func _steer(p: Dictionary, want: Vector2, top: float, dt: float) -> void:
	p["vel"] = (p["vel"] as Vector2).move_toward(want.limit_length(1.0) * top, ACCEL * dt)
	if want.length() > 0.1:
		p["face"] = want.normalized()

func _human(i: int, input: Dictionary, dt: float) -> void:
	var p: Dictionary = players[i]
	var move: Vector2 = input.get("move", Vector2.ZERO)
	var sprinting := bool(input.get("sprint", false)) and float(p["stamina"]) > 0.05 and move.length() > 0.1
	p["stamina"] = clampf(float(p["stamina"]) + (-0.28 if sprinting else 0.16) * dt, 0.0, 1.0)
	var top := (SPRINT if sprinting else RUN) * (0.9 if owner == i else 1.0)
	_steer(p, move, top, dt)
	if owner == i:
		if bool(input.get("pass", false)):
			pass_ball(i, move)
		elif float(input.get("shoot", -1.0)) >= 0.0:
			shoot(i, float(input["shoot"]), move, float(input.get("curl", 0.0)))
	elif bool(input.get("tackle", false)) or bool(input.get("pass", false)):
		tackle(i)

func tackle(i: int) -> void:
	var p: Dictionary = players[i]
	if float(p["slide"]) > 0.0 or float(p["down"]) > 0.0:
		return
	var dir: Vector2 = p["face"]
	if p["pos"].distance_to(ball.pos) < 50.0:
		dir = (ball.pos - (p["pos"] as Vector2)).normalized()
	p["slide"] = TACKLE_TIME
	p["vel"] = dir * TACKLE_SPEED
	p["face"] = dir

func shoot(i: int, charge: float, aim: Vector2, curl_in: float = 0.0) -> void:
	## Aims at the goal; up/down on the stick picks the corner, curl bends it back toward the middle.
	var p: Dictionary = players[i]
	var team := int(p["team"])
	var target := goal_of(team) + Vector2(0, clampf(aim.y, -1.0, 1.0) * (FootballBall.GOAL_HALF - 9.0))
	var dir := (target - ball.pos).normalized()
	if absf(curl_in) > 0.05:
		dir = dir.rotated(-0.16 * curl_in)
	dir = dir.rotated(rng.randf_range(-1.0, 1.0) * (0.09 - 0.018 * float(clampi(int(tier[team]), 0, 4))))
	ball.kick(dir, shot_speed(charge), shot_lift(charge), 0.75 * curl_in)
	stats["shots"][team] += 1
	_release(i)

func pass_target(i: int, aim: Vector2) -> int:
	## The team-mate best lined up with the stick (or facing), preferring open and forward ones.
	var p: Dictionary = players[i]
	var team := int(p["team"])
	var look: Vector2 = aim if aim.length() > 0.1 else p["face"]
	var best := -1
	var bs := -INF
	for j in range(team * 4 + 1, team * 4 + 4):
		if j == i:
			continue
		var to: Vector2 = (players[j]["pos"] as Vector2) - (p["pos"] as Vector2)
		var s := look.normalized().dot(to.normalized()) * 2.0 - to.length() / 400.0 + minf(_pressure(j), 80.0) / 80.0
		if s > bs:
			bs = s
			best = j
	return best

func pass_ball(i: int, aim: Vector2) -> void:
	var j := pass_target(i, aim)
	if j < 0:
		return
	var lead: Vector2 = (players[j]["pos"] as Vector2) + (players[j]["vel"] as Vector2) * 0.35
	var to := lead - ball.pos
	ball.kick(to.normalized(), FootballBall.pass_speed(to.length()))
	_release(i)
	if int(players[i]["team"]) == 0 and j != keeper_index(0):
		selected = j
		_switch_lock = 0.7

func _release(i: int) -> void:
	owner = -1
	last_touch = i
	players[i]["lock"] = KICK_LOCK
	players[i]["kick_anim"] = 0.22
	events.append("kick")

func _pressure(i: int) -> float:
	## Distance from player i to the nearest opponent.
	var d := INF
	var team := int(players[i]["team"])
	for q in players:
		if int(q["team"]) != team:
			d = minf(d, (q["pos"] as Vector2).distance_to(players[i]["pos"]))
	return d

func _ai(i: int, chaser: int, dt: float) -> void:
	var p: Dictionary = players[i]
	var team := int(p["team"])
	var scale := speed_scale(int(tier[team]))
	var pos: Vector2 = p["pos"]
	var attack := 1.0 if team == 0 else -1.0
	if int(p["role"]) == 0:
		_keeper(i, scale, dt)
		return
	if owner == i:
		p["hold"] = float(p["hold"]) + dt
		var goal := goal_of(team)
		var dist := pos.distance_to(goal)
		var in_range := dist < 135.0 + rng.randf() * 20.0 and absf(pos.y - goal.y) < 90.0
		if in_range and float(p["hold"]) > 0.3 - 0.04 * float(tier[team]):
			var gk: Vector2 = players[keeper_index(1 - team)]["pos"]
			var corner := -1.0 if gk.y > goal.y else 1.0   # away from the keeper
			shoot(i, rng.randf_range(0.2, 0.62), Vector2(attack, corner * rng.randf_range(0.5, 1.0)), 0.0)
			return
		if _pressure(i) < 24.0 and float(p["hold"]) > 0.45:
			var j := pass_target(i, Vector2(attack, 0))
			if j >= 0 and _pressure(j) > 30.0:
				pass_ball(i, (players[j]["pos"] as Vector2) - pos)
				return
		# dribble at goal, swerving round the nearest opponent ahead
		var want := (goal + Vector2(-attack * 70.0, (pos.y - goal.y) * 0.35) - pos).normalized()
		for q in players:
			if int(q["team"]) != team:
				var off: Vector2 = (q["pos"] as Vector2) - pos
				if off.length() < 45.0 and off.x * attack > 0.0:
					want.y += -1.0 if off.y > 0.0 else 1.0
		_steer(p, want, RUN * 0.9 * scale, dt)
		return
	p["hold"] = 0.0
	if i == chaser and (owner < 0 or int(players[owner]["team"]) != team):
		var target := ball.predict(0.2)
		_steer(p, target - pos, (RUN + 6.0) * scale, dt)
		if owner >= 0 and owner != keeper_index(1 - team) and pos.distance_to(ball.pos) < 28.0 and float(p["lock"]) <= 0.0:
			if rng.randf() < (0.35 + 0.2 * float(tier[team])) * dt:
				tackle(i)
		return
	var spot := home_spot(int(p["role"]))
	var bx := ball.pos.x if team == 0 else FootballBall.FIELD.x - ball.pos.x
	var attacking := owner >= 0 and int(players[owner]["team"]) == team
	var push := (bx - FootballBall.FIELD.x * 0.5) * 0.55 + (90.0 if attacking else -20.0)
	if int(p["role"]) == 1:
		push *= 0.6
	spot.x = clampf(spot.x + push, 30.0, FootballBall.FIELD.x - 80.0)
	spot.y = lerpf(spot.y, ball.pos.y, 0.25)
	var to := mirror(spot, team) - pos
	_steer(p, to / 24.0, RUN * 0.92 * scale, dt)

func _keeper(i: int, scale: float, dt: float) -> void:
	var p: Dictionary = players[i]
	var team := int(p["team"])
	if owner == i:
		p["hold"] = float(p["hold"]) + dt
		p["vel"] = Vector2.ZERO
		if float(p["hold"]) > 0.8:
			pass_ball(i, Vector2(1 if team == 0 else -1, 0))
		return
	p["hold"] = 0.0
	var own_x := 0.0 if team == 0 else FootballBall.FIELD.x
	var inward := 1.0 if team == 0 else -1.0
	var ty := ball.pos.y
	if ball.vel.x * inward < -60.0:   # a shot coming: go where it will cross the keeper's line
		var tx: float = (p["pos"] as Vector2).x
		var eta := (tx - ball.pos.x) / ball.vel.x
		if eta > 0.0 and eta < 1.2:
			ty = ball.pos.y + ball.vel.y * eta
	ty = clampf(ty, FootballBall.mouth_top() + 6.0, FootballBall.mouth_bottom() - 6.0)
	var out := 10.0
	if owner < 0 and ball.vel.length() < 90.0 and absf(ball.pos.x - own_x) < 60.0 and absf(ball.pos.y - FootballBall.FIELD.y * 0.5) < 70.0:
		_steer(p, ball.pos - (p["pos"] as Vector2), KEEPER_SPEED * scale, dt)   # come and claim a loose ball
		return
	var to := Vector2(own_x + inward * out, ty) - (p["pos"] as Vector2)
	_steer(p, to / 6.0, KEEPER_SPEED * scale, dt)

func _separate() -> void:
	for i in players.size():
		for j in range(i + 1, players.size()):
			var off: Vector2 = (players[j]["pos"] as Vector2) - (players[i]["pos"] as Vector2)
			var d := off.length()
			if d < 9.0 and d > 0.001:
				var push := off / d * (9.0 - d) * 0.5
				players[i]["pos"] -= push
				players[j]["pos"] += push

func _tackles() -> void:
	if owner < 0 or owner == keeper_index(0) or owner == keeper_index(1):
		_contest = 0.0
		return
	var carrier: Dictionary = players[owner]
	var touching := -1
	for i in players.size():
		var q: Dictionary = players[i]
		if int(q["team"]) == int(carrier["team"]) or float(q["down"]) > 0.0 or float(q["lock"]) > 0.0:
			continue
		var d: float = (q["pos"] as Vector2).distance_to(ball.pos)
		if float(q["slide"]) > 0.0 and d < REACH + 3.0:
			# a clean slide wins it and knocks the carrier over
			carrier["down"] = TACKLE_DOWN
			carrier["lock"] = TACKLE_DOWN
			ball.kick(q["face"], 120.0)
			owner = -1
			last_touch = i
			_contest = 0.0
			events.append("tackle")
			return
		if d < REACH - 2.0:
			touching = i
	if touching >= 0:
		_contest += TICK
		if _contest > 0.3:   # shoulder to shoulder: the ball squirts loose
			var away := (ball.pos - (carrier["pos"] as Vector2)).rotated(rng.randf_range(-1.2, 1.2))
			ball.kick(away, 95.0)
			carrier["lock"] = KICK_LOCK
			owner = -1
			_contest = 0.0
			events.append("tackle")
	else:
		_contest = 0.0

func _dribble(dt: float) -> void:
	var p: Dictionary = players[owner]
	var face: Vector2 = p["face"]
	var speed: float = (p["vel"] as Vector2).length()
	# the ball is nudged ahead in touches: further out the faster you run
	var touch := 7.0 + 4.0 * clampf(speed / SPRINT, 0.0, 1.0) * (0.5 + 0.5 * sin(float(p["run"]) * 0.28))
	var want: Vector2 = (p["pos"] as Vector2) + face * touch
	var before := ball.pos
	ball.pos = ball.pos.lerp(want, clampf(18.0 * dt, 0.0, 1.0)).clamp(Vector2(4, 4), FootballBall.FIELD - Vector2(4, 4))
	ball.vel = p["vel"]
	ball.roll += before.distance_to(ball.pos)
	ball.z = 0.0
	ball.vz = 0.0
	ball.curl = 0.0

func _collect() -> void:
	var best := -1
	var bd := INF
	for i in players.size():
		var p: Dictionary = players[i]
		if float(p["lock"]) > 0.0 or float(p["down"]) > 0.0:
			continue
		var keeper := int(p["role"]) == 0
		var reach := KEEPER_REACH if keeper else REACH
		if keeper and float(p["slide"]) <= 0.0:
			reach += 0.6 * float(tier[int(p["team"])])
		if ball.z > (FootballBall.BAR_Z if keeper else 11.0):
			continue
		var d: float = (p["pos"] as Vector2).distance_to(ball.pos)
		if d < reach and d < bd:
			bd = d
			best = i
	if best < 0:
		return
	var q: Dictionary = players[best]
	var team := int(q["team"])
	var speed := ball.vel.length()
	var shot_at_keeper := int(q["role"]) == 0 and last_touch >= 0 and int(players[last_touch]["team"]) != team and speed > 150.0
	if shot_at_keeper:
		stats["saves"][team] += 1
		events.append("save")
		if speed > 300.0:   # too hot to hold: parried back out
			var inward := 1.0 if team == 0 else -1.0
			ball.kick(Vector2(inward, rng.randf_range(-1.0, 1.0)), 140.0)
			q["lock"] = KICK_LOCK
			last_touch = best
			return
	elif int(q["role"]) != 0 and speed > CONTROL_SPEED:
		var n: Vector2 = (ball.pos - (q["pos"] as Vector2)).normalized()   # it cannons off the shins
		if ball.vel.dot(n) < 0.0:
			ball.vel = ball.vel.bounce(n) * 0.45
			last_touch = best
		return
	owner = best
	last_touch = best
	q["hold"] = 0.0
	_contest = 0.0
