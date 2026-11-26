class_name HoopMatch
extends RefCounted
## Pure 3-on-3 half-court street game on top of HoopBall: dribbling, passing, a release-timed jump shot with
## distance accuracy, contests, blocks, steals, rebounds, the take-it-back rule, 2s and 3s, first to 21 or the
## time limit (a tie goes to next basket). Team 0 is yours. Deterministic for a seed.

const TICK := 1.0 / 60.0
const TARGET := 21
const TIME_LIMIT := 180.0
const SHOT_CLOCK := 14.0
const RUN := 80.0
const SPRINT := 112.0
const ACCEL := 560.0
const REACH := 12.0            # ground reach for a loose ball
const HAND_Z := 36.0           # standing reach height
const JUMP_V := 150.0
const JUMP_G := 430.0
const METER_TIME := 0.9        # seconds for the release meter to fill
const SWEET := 0.70            # perfect release point on the meter
const PERFECT := 0.055         # half width of the perfect window
const MISS_SPAN := 0.33        # this far from SWEET the timing is worthless
const RELEASE_Z := 40.0
const PASS_SPEED := 240.0
const STEAL_RANGE := 19.0
const STEAL_COOLDOWN := 0.9
const BLOCK_RANGE := 22.0
const CHECK_PAUSE := 1.1
const SCORE_PAUSE := 1.7

var ball := HoopBall.new()
var players: Array = []       # dictionaries, see _player()
var owner := -1
var score := [0, 0]
var clock := 0.0              # seconds of live play
var shot_clock := SHOT_CLOCK
var pause := CHECK_PAUSE
var finished := false
var overtime := false
var selected := 0             # the team-0 player you control
var tier := [2, 2]
var auto := false             # true: the AI plays team 0 too (balance tests, demos)
var events: Array = []        # drained by the view
var offense := 0              # team with (or last with) clean possession
var must_clear := false       # after a change of possession the ball has to go beyond the arc
var shot_info: Dictionary = {}   # the shot in the air: team, shooter, points
var last_release: Dictionary = {}   # {"player", "quality", "meter", "contest", "chance", "points"} for the view
var pass_to := -1
var stats := {"fga": [0, 0], "fgm": [0, 0], "tpa": [0, 0], "tpm": [0, 0], "reb": [0, 0], "oreb": [0, 0],
	"stl": [0, 0], "blk": [0, 0], "to": [0, 0]}
var rng := RandomNumberGenerator.new()
var _carry := 0.0
var _pending: Dictionary = {}
var _switch_lock := 0.0
var _spot_t := 0.0
var _spots := [[1, 2, 0], [1, 2, 0]]
var _dribble := 0.0
var loose_t := 0.0           # a ball nobody can reach (stuck on the iron) gets re-checked

func _init(tier_home: int = 2, tier_away: int = 2, seed_value: int = 1, first_ball: int = 0) -> void:
	tier = [tier_home, tier_away]
	rng.seed = seed_value
	for team in 2:
		for i in 3:
			players.append(_player(team, i))
	check_ball(first_ball)

func _player(team: int, role: int) -> Dictionary:
	return {"team": team, "role": role, "pos": Vector2.ZERO, "vel": Vector2.ZERO, "face": Vector2.DOWN, "z": 0.0, "vz": 0.0,
		"lock": 0.0, "stun": 0.0, "steal_cd": 0.0, "meter": -1.0, "aim": SWEET, "hold": 0.0, "run": 0.0, "stamina": 1.0,
		"throw": 0.0, "react": -1.0}

# ---------------------------------------------------------------- pure rules

static func timing_quality(meter: float) -> float:
	## 1.0 inside the perfect window, falling to 0 MISS_SPAN away from the sweet spot.
	var off := absf(meter - SWEET)
	if off <= PERFECT:
		return 1.0
	return clampf(1.0 - (off - PERFECT) / (MISS_SPAN - PERFECT), 0.0, 1.0) * 0.85

static func distance_chance(dist: float) -> float:
	## Open-look accuracy with decent timing, by ground distance to the rim.
	var pts := [[0.0, 0.88], [36.0, 0.84], [80.0, 0.64], [150.0, 0.50], [185.0, 0.38], [240.0, 0.14], [300.0, 0.03]]
	for i in range(1, pts.size()):
		if dist <= pts[i][0]:
			var k: float = (dist - pts[i - 1][0]) / (pts[i][0] - pts[i - 1][0])
			return lerpf(pts[i - 1][1], pts[i][1], k)
	return 0.02

static func shot_chance(dist: float, quality: float, contest: float, skill: int) -> float:
	var p := distance_chance(dist) * lerpf(0.22, 1.22, clampf(quality, 0.0, 1.0))
	p *= 1.0 - 0.55 * clampf(contest, 0.0, 1.0)
	p *= 0.91 + 0.035 * float(clampi(skill, 0, 4))
	return clampf(p, 0.02, 0.97)

static func speed_scale(t: int) -> float:
	return 0.94 + 0.024 * float(clampi(t, 0, 4))

static func steal_chance(skill: int, handler_skill: int, shielding: bool) -> float:
	var p := 0.20 + 0.035 * float(skill - handler_skill)
	if shielding:
		p *= 0.4     # the handler's body is between the thief and the ball
	return clampf(p, 0.03, 0.4)

func contest_on(i: int) -> float:
	## 0 wide open .. 1 smothered: the nearest opponent counts, more if between shooter and rim or off his feet.
	var me: Dictionary = players[i]
	var best := 0.0
	var to_rim := (HoopBall.RIM - (me["pos"] as Vector2)).normalized()
	for p in players:
		if int(p["team"]) == int(me["team"]) or float(p["stun"]) > 0.0:
			continue
		var rel: Vector2 = (p["pos"] as Vector2) - (me["pos"] as Vector2)
		var near := clampf(1.0 - (rel.length() - 12.0) / 32.0, 0.0, 1.0)
		var front := 0.5 + 0.5 * clampf(rel.normalized().dot(to_rim) + 0.3, 0.0, 1.0)
		var up := 1.25 if float(p["z"]) > 5.0 else 0.85
		best = maxf(best, near * front * up)
	return clampf(best, 0.0, 1.0)

func openness(i: int) -> float:
	var d := 80.0
	for p in players:
		if int(p["team"]) != int(players[i]["team"]):
			d = minf(d, (p["pos"] as Vector2).distance_to(players[i]["pos"]))
	return d

func shot_value(i: int) -> float:
	## Expected points of a decently timed shot from where player i stands.
	var pos: Vector2 = players[i]["pos"]
	var pts := 3.0 if HoopBall.is_three(pos) else 2.0
	return pts * shot_chance(pos.distance_to(HoopBall.RIM), 0.75, contest_on(i), tier[int(players[i]["team"])])

func time_left() -> float:
	return maxf(0.0, TIME_LIMIT - clock)

func result() -> int:
	return signi(int(score[0]) - int(score[1]))

# ---------------------------------------------------------------- set pieces

## Dead ball: `team` checks it in at the top of the arc.
func check_ball(team: int) -> void:
	var spots := [Vector2(220, 205), Vector2(92, 128), Vector2(348, 128)]
	for i in players.size():
		var p: Dictionary = players[i]
		var role := int(p["role"])
		var mine := int(p["team"]) == team
		p["pos"] = spots[role] if mine else (spots[role] as Vector2).lerp(HoopBall.RIM, 0.2 if role == 0 else 0.25)
		for k in ["z", "vz", "lock", "stun", "steal_cd", "hold", "throw"]:
			p[k] = 0.0
		p["meter"] = -1.0
		p["react"] = -1.0
		p["vel"] = Vector2.ZERO
		p["face"] = Vector2.UP if mine else Vector2.DOWN
	owner = team * 3
	offense = team
	must_clear = false
	shot_info = {}
	pass_to = -1
	shot_clock = SHOT_CLOCK
	loose_t = 0.0
	selected = 0
	_switch_lock = 0.6
	_spot_t = 2.0
	ball.reset(players[owner]["pos"])

func _gain(i: int) -> void:
	## Player i takes the ball out of the air or off an opponent.
	var team := int(players[i]["team"])
	if team != offense:
		must_clear = true
		shot_clock = SHOT_CLOCK
	offense = team
	owner = i
	loose_t = 0.0
	players[i]["hold"] = 0.0
	players[i]["meter"] = -1.0
	ball.shot = false
	shot_info = {}
	pass_to = -1
	if team == 0:
		selected = int(players[i]["role"])
	elif not auto:
		selected = int(players[i]["role"])   # you start on his marker
	_switch_lock = 0.35

# ---------------------------------------------------------------- loop

## `input`: {"move": Vector2, "sprint": bool} held, plus one-shots "shoot" (Space down: wind up, or jump),
## "release" (Space up), "pass" (pass / steal / call for it), "switch". One-shots wait until a tick really runs.
func update(dt: float, input: Dictionary = {}) -> void:
	for k in ["shoot", "release", "pass", "switch"]:
		if input.get(k, false):
			_pending[k] = true
	_carry += minf(dt, 0.25)
	while _carry >= TICK - 0.00001:
		_carry -= TICK
		var now := {"move": input.get("move", Vector2.ZERO), "sprint": input.get("sprint", false)}
		var held_back := false
		if _pending.has("shoot") and _pending.has("release"):   # a tap inside one frame: release a tick later
			held_back = true
			_pending.erase("release")
		now.merge(_pending, true)
		_pending = {}
		if held_back:
			_pending["release"] = true
		_tick(TICK, now)

func _tick(dt: float, input: Dictionary) -> void:
	if finished:
		return
	if pause > 0.0:
		pause -= dt
		if owner >= 0:
			_carry_ball(dt)
		else:
			ball.step(dt)
			if pause <= 0.0:
				check_ball(1 - offense)
				pause = CHECK_PAUSE * 0.6
		return
	clock += dt
	if clock >= TIME_LIMIT and not overtime and owner >= 0 and float(players[owner]["meter"]) < 0.0:
		_buzzer()
		if finished:
			return
	_switch_lock = maxf(0.0, _switch_lock - dt)
	_spot_t -= dt
	if _spot_t <= 0.0:
		_spot_t = rng.randf_range(1.4, 2.8)
		for team in 2:
			var a := rng.randi() % 5
			_spots[team] = [a, (a + 1 + rng.randi() % 2) % 5, (a + 3 + rng.randi() % 2) % 5]
	if not auto:
		_pick_selected(bool(input.get("switch", false)))
	var chasers := _chasers() if owner < 0 else []
	for i in players.size():
		var p: Dictionary = players[i]
		for k in ["lock", "stun", "steal_cd", "throw"]:
			p[k] = maxf(0.0, float(p[k]) - dt)
		if float(p["z"]) > 0.0 or float(p["vz"]) > 0.0:
			p["z"] = float(p["z"]) + float(p["vz"]) * dt
			p["vz"] = float(p["vz"]) - JUMP_G * dt
			if float(p["z"]) <= 0.0:
				p["z"] = 0.0
				p["vz"] = 0.0
		if float(p["meter"]) >= 0.0:
			_winding_up(i, input, dt)
		elif float(p["stun"]) > 0.0:
			_steer(p, Vector2.ZERO, 0.0, dt)
		elif int(p["team"]) == 0 and int(p["role"]) == selected and not auto:
			_human(i, input, dt)
		else:
			_ai(i, chasers, dt)
		p["pos"] = ((p["pos"] as Vector2) + (p["vel"] as Vector2) * dt).clamp(Vector2(7, 12), HoopBall.COURT - Vector2(7, 5))
		p["run"] = float(p["run"]) + (p["vel"] as Vector2).length() * dt
	_separate()
	if owner >= 0:
		_carry_ball(dt)
		if must_clear and HoopBall.is_three(players[owner]["pos"]):
			must_clear = false
			events.append("cleared")
		shot_clock -= dt
		if shot_clock <= 0.0 and float(players[owner]["meter"]) < 0.0:
			_violation()
	else:
		_step_loose(dt)

func _buzzer() -> void:
	if int(score[0]) == int(score[1]):
		overtime = true
		events.append("overtime")
	else:
		finished = true
		events.append("full")

func _violation() -> void:
	stats["to"][offense] += 1
	events.append("violation")
	check_ball(1 - offense)
	pause = CHECK_PAUSE

func _carry_ball(dt: float) -> void:
	var p: Dictionary = players[owner]
	var face: Vector2 = p["face"]
	var side := Vector2(8, 0) if face.x >= 0.0 else Vector2(-8, 0)
	ball.pos = (p["pos"] as Vector2) + side + face * 3.0
	ball.vel = p["vel"]
	ball.vz = 0.0
	if float(p["meter"]) >= 0.0:
		ball.pos = (p["pos"] as Vector2) + Vector2(side.x * 0.5, 0.5)
		ball.z = float(p["z"]) + 34.0
		return
	var before := _dribble
	_dribble += dt * (7.5 + (p["vel"] as Vector2).length() * 0.045)
	ball.z = HoopBall.RADIUS + absf(sin(_dribble)) * 15.0
	ball.spin += dt * 30.0
	if floorf(_dribble / PI) != floorf(before / PI) and pause <= 0.0:
		events.append("dribble")

func _step_loose(dt: float) -> void:
	loose_t += dt
	if loose_t > 5.0:
		loose_t = 0.0
		events.append("jumpball")
		check_ball(1 - offense)
		pause = CHECK_PAUSE
		return
	var ev := ball.step(dt)
	if ev == "score":
		_score()
		return
	if ev != "":
		events.append(ev)
		if pass_to >= 0:
			pass_to = -1
	if not ball.shot:
		_collect()
	if owner < 0 and ball.touched_iron:
		shot_clock = SHOT_CLOCK
	if owner < 0 and clock >= TIME_LIMIT and not overtime and ev == "floor":
		_buzzer()

func _score() -> void:
	if shot_info.is_empty():
		return     # a stray pass or tip dropping through does not count
	var team := int(shot_info["team"])
	var pts := int(shot_info["points"])
	score[team] += pts
	stats["fgm"][team] += 1
	if pts == 3:
		stats["tpm"][team] += 1
	events.append("score%d" % team)
	shot_info = {}
	offense = team
	pause = SCORE_PAUSE
	owner = -1
	for p in players:
		p["vel"] = Vector2.ZERO
		p["meter"] = -1.0
	if int(score[team]) >= TARGET or overtime or clock >= TIME_LIMIT and int(score[0]) != int(score[1]):
		finished = true
		events.append("full")

func _collect() -> void:
	var best := -1
	var bd := INF
	for i in players.size():
		var p: Dictionary = players[i]
		if float(p["lock"]) > 0.0 or float(p["stun"]) > 0.0:
			continue
		var d := (p["pos"] as Vector2).distance_to(ball.pos)
		var reach := REACH
		if pass_to >= 0:   # a thrown ball: the target has sure hands, a defender needs to be right in the lane
			if i == pass_to:
				reach = REACH + 5.0
			elif int(p["team"]) != offense:
				reach = 7.0
		if d < reach and ball.z <= HAND_Z + float(p["z"]) and d - float(p["z"]) * 0.2 < bd:
			bd = d - float(p["z"]) * 0.2
			best = i
	if best < 0:
		return
	var team := int(players[best]["team"])
	if ball.touched_iron:
		stats["reb"][team] += 1
		if team == offense:
			stats["oreb"][team] += 1
		events.append("rebound%d" % team)
		ball.touched_iron = false
		_gain(best)
		must_clear = true       # every board gets taken back out, whoever grabs it
		return
	if pass_to >= 0 and team != offense:
		stats["stl"][team] += 1
		stats["to"][offense] += 1
		events.append("intercept")
	elif pass_to >= 0:
		events.append("catch")
	_gain(best)

# ---------------------------------------------------------------- actions

func jump(i: int) -> void:
	var p: Dictionary = players[i]
	if float(p["z"]) <= 0.0 and float(p["stun"]) <= 0.0:
		p["vz"] = JUMP_V
		p["z"] = 0.1
		events.append("jump")

func start_shot(i: int) -> bool:
	if owner != i or float(players[i]["meter"]) >= 0.0:
		return false
	if must_clear:
		events.append("clear_first")
		return false
	var p: Dictionary = players[i]
	p["meter"] = 0.0
	p["vel"] = (p["vel"] as Vector2) * 0.35
	p["face"] = (HoopBall.RIM - (p["pos"] as Vector2)).normalized()
	jump(i)
	return true

func _winding_up(i: int, input: Dictionary, dt: float) -> void:
	var p: Dictionary = players[i]
	_steer(p, Vector2.ZERO, 0.0, dt)
	p["meter"] = float(p["meter"]) + dt / METER_TIME
	var human := int(p["team"]) == 0 and int(p["role"]) == selected and not auto
	var let_go := (human and bool(input.get("release", false))) or (not human and float(p["meter"]) >= float(p["aim"]))
	if let_go or float(p["meter"]) >= 1.0:
		release_shot(i, minf(1.0, float(p["meter"])))

## The ball leaves player i's hands with the meter at `meter`.
func release_shot(i: int, meter: float) -> void:
	var p: Dictionary = players[i]
	var team := int(p["team"])
	var from: Vector2 = p["pos"]
	var dist := from.distance_to(HoopBall.RIM)
	var quality := timing_quality(meter)
	var contest := contest_on(i)
	var chance := shot_chance(dist, quality, contest, tier[team])
	var points := 3 if HoopBall.is_three(from) else 2
	p["meter"] = -1.0
	p["lock"] = 0.35
	p["throw"] = 0.4
	owner = -1
	pass_to = -1
	stats["fga"][team] += 1
	if points == 3:
		stats["tpa"][team] += 1
	last_release = {"player": i, "quality": quality, "meter": meter, "contest": contest, "chance": chance, "points": points}
	var z0 := RELEASE_Z + minf(float(p["z"]), 18.0)
	ball.pos = from
	ball.z = z0
	var blocker := _blocker(i)
	if blocker >= 0:
		stats["blk"][team ^ 1] += 1
		players[blocker]["throw"] = 0.3
		var away := (from - HoopBall.RIM).normalized().rotated(rng.randf_range(-1.2, 1.2))
		ball.launch(Vector3(away.x * 110.0, away.y * 110.0, rng.randf_range(20.0, 90.0)))
		shot_info = {}
		players[blocker]["lock"] = 0.25
		events.append("block")
		return
	var target := HoopBall.RIM
	if rng.randf() >= chance:
		# a miss: aim off the middle; worse releases miss by more (front iron, back board or air ball)
		var off := rng.randf_range(9.0, 13.0 + 12.0 * (1.0 - quality))
		var line := (HoopBall.RIM - from).normalized() if dist > 4.0 else Vector2.UP
		target += line.rotated((PI if rng.randf() < 0.55 else 0.0) + rng.randf_range(-1.1, 1.1)) * off
	else:
		target += Vector2.from_angle(rng.randf() * TAU) * rng.randf() * 1.0
	ball.launch(HoopBall.launch_velocity(from, z0, target, HoopBall.RIM_Z, HoopBall.flight_time(dist)), true)
	shot_info = {"team": team, "shooter": i, "points": points}
	events.append("perfect" if quality >= 1.0 else "shot")

func _blocker(shooter: int) -> int:
	## A defender in the air right on top of the shooter may get a hand to it.
	var me: Dictionary = players[shooter]
	var to_rim := (HoopBall.RIM - (me["pos"] as Vector2)).normalized()
	for i in players.size():
		var p: Dictionary = players[i]
		if int(p["team"]) == int(me["team"]) or float(p["z"]) < 7.0:
			continue
		var rel: Vector2 = (p["pos"] as Vector2) - (me["pos"] as Vector2)
		if rel.length() > BLOCK_RANGE:
			continue
		var odds := 0.20 if rel.normalized().dot(to_rim) > 0.2 else 0.06
		if float(p["z"]) + 4.0 < float(me["z"]):
			odds *= 0.5
		if rng.randf() < odds:
			return i
	return -1

func try_steal(i: int) -> bool:
	var p: Dictionary = players[i]
	if owner < 0 or int(players[owner]["team"]) == int(p["team"]) or float(p["steal_cd"]) > 0.0:
		return false
	p["steal_cd"] = STEAL_COOLDOWN
	p["throw"] = 0.2
	var h: Dictionary = players[owner]
	var rel: Vector2 = (p["pos"] as Vector2) - (h["pos"] as Vector2)
	if rel.length() > STEAL_RANGE or float(h["meter"]) >= 0.0:
		p["stun"] = 0.3
		return false
	var shielding := rel.normalized().dot(h["face"]) < -0.35
	if rng.randf() >= steal_chance(tier[int(p["team"])], tier[int(h["team"])], shielding):
		p["stun"] = 0.38      # reached and got nothing: beaten for a moment
		return false
	stats["stl"][int(p["team"])] += 1
	stats["to"][int(h["team"])] += 1
	h["stun"] = 0.45
	h["lock"] = 0.6
	events.append("steal")
	_gain(i)
	return true

func pass_target(i: int, aim: Vector2) -> int:
	## The teammate you point at, else the best placed one.
	var best := -1
	var bs := -INF
	for k in players.size():
		if k == i or int(players[k]["team"]) != int(players[i]["team"]):
			continue
		var rel: Vector2 = (players[k]["pos"] as Vector2) - (players[i]["pos"] as Vector2)
		var s := rel.normalized().dot(aim.normalized()) * 100.0 if aim.length() > 0.2 else openness(k) + shot_value(k) * 20.0
		if s > bs:
			bs = s
			best = k
	return best

func pass_ball(i: int, to: int) -> void:
	if owner != i or to < 0 or float(players[i]["meter"]) >= 0.0:
		return
	var p: Dictionary = players[i]
	var from: Vector2 = p["pos"]
	var r: Dictionary = players[to]
	var secs := maxf(0.16, from.distance_to(r["pos"]) / PASS_SPEED)
	var aim: Vector2 = (r["pos"] as Vector2) + (r["vel"] as Vector2) * secs * 0.7
	owner = -1
	p["lock"] = 0.35
	p["throw"] = 0.25
	p["face"] = (aim - from).normalized()
	ball.pos = from
	ball.z = 26.0
	ball.launch(HoopBall.launch_velocity(from, 26.0, aim, 24.0, secs))
	pass_to = to
	shot_info = {}
	events.append("pass")

# ---------------------------------------------------------------- control

func _pick_selected(manual: bool) -> void:
	if owner >= 0 and int(players[owner]["team"]) == 0:
		selected = int(players[owner]["role"])
		return
	if not manual and not (owner < 0 and _switch_lock <= 0.0 and float(players[selected]["z"]) <= 0.0):
		return
	if not manual and pass_to >= 0 and offense == 0:
		selected = int(players[pass_to]["role"])
		return
	var order := [0, 1, 2]
	var at := ball.pos if owner < 0 else players[owner]["pos"] as Vector2
	order.sort_custom(func(a, b): return (players[a]["pos"] as Vector2).distance_squared_to(at) < (players[b]["pos"] as Vector2).distance_squared_to(at))
	selected = order[(order.find(selected) + 1) % 3] if manual else order[0]
	_switch_lock = 1.0 if manual else 0.5

func _human(i: int, input: Dictionary, dt: float) -> void:
	var p: Dictionary = players[i]
	var move: Vector2 = input.get("move", Vector2.ZERO)
	var sprint := bool(input.get("sprint", false)) and float(p["stamina"]) > 0.05 and move != Vector2.ZERO
	p["stamina"] = clampf(float(p["stamina"]) + (-0.3 if sprint else 0.18) * dt, 0.0, 1.0)
	var top := (SPRINT if sprint else RUN) * speed_scale(tier[0]) * (0.92 if owner == i else 1.0)
	_steer(p, move.limit_length(1.0), top if float(p["z"]) <= 0.0 else top * 0.4, dt)
	if input.get("shoot", false):
		if owner == i:
			start_shot(i)
		else:
			jump(i)
	if input.get("pass", false):
		if owner == i:
			pass_ball(i, pass_target(i, move))
		elif owner >= 0 and int(players[owner]["team"]) == 1:
			try_steal(i)
		elif owner >= 0:
			pass_ball(owner, i)   # call for it

func _steer(p: Dictionary, dir: Vector2, top: float, dt: float) -> void:
	p["vel"] = (p["vel"] as Vector2).move_toward(dir * top, ACCEL * dt)
	if dir.length() > 0.2:
		p["face"] = dir.normalized()

func _go(p: Dictionary, to: Vector2, top: float, dt: float) -> void:
	var d := to - (p["pos"] as Vector2)
	_steer(p, d.normalized() if d.length() > 3.0 else Vector2.ZERO, top * clampf(d.length() / 16.0, 0.35, 1.0), dt)

func _chasers() -> Array:
	## The two players of each side closest to where the ball is coming down.
	var at := ball.predict_landing()
	var out: Array = []
	for team in 2:
		var ids := [team * 3, team * 3 + 1, team * 3 + 2]
		ids.sort_custom(func(a, b): return (players[a]["pos"] as Vector2).distance_squared_to(at) < (players[b]["pos"] as Vector2).distance_squared_to(at))
		out.append(ids[0])
		out.append(ids[1])
	return out

func _ai(i: int, chasers: Array, dt: float) -> void:
	var p: Dictionary = players[i]
	var team := int(p["team"])
	var skill: int = tier[team]
	var top := RUN * speed_scale(skill)
	if float(p["z"]) > 0.0:
		_steer(p, Vector2.ZERO, 0.0, dt * 0.35)   # no changing course in mid air
		return
	if owner < 0:
		_ai_loose(i, chasers, top, dt)
	elif owner == i:
		_ai_handler(i, top * 0.94, dt)
	elif int(players[owner]["team"]) == team:
		var spots := [Vector2(220, 200), Vector2(66, 150), Vector2(374, 150), Vector2(42, 58), Vector2(398, 58)]
		var spot: Vector2 = spots[int(_spots[team][int(p["role"])])]
		if must_clear:
			spot = spot.lerp(HoopBall.RIM, 0.12)
		_go(p, spot, top * 0.85, dt)
		if p["vel"] == Vector2.ZERO:
			p["face"] = ((players[owner]["pos"] as Vector2) - (p["pos"] as Vector2)).normalized()
	else:
		_ai_defend(i, top, dt)

func _ai_loose(i: int, chasers: Array, top: float, dt: float) -> void:
	var p: Dictionary = players[i]
	var to_ball := (p["pos"] as Vector2).distance_to(ball.pos)
	if pass_to == i:
		_go(p, ball.pos + ball.vel * 0.12, top, dt)
	elif chasers.has(i) and (pass_to < 0 or int(p["team"]) != offense):
		var goal := ball.predict_landing()
		if ball.shot:    # box out under the rim while it is in the air
			goal = HoopBall.RIM + Vector2((int(p["role"]) - 1) * 26.0, 28.0 + int(p["team"]) * 8.0)
		_go(p, goal, top * 1.12, dt)
		# go up for it when it is falling just above standing reach
		if not ball.shot and to_ball < 20.0 and ball.vz < 0.0 and ball.z > HAND_Z and ball.z < HAND_Z + 30.0:
			if rng.randf() < (2.0 + 1.5 * tier[int(p["team"])]) * dt:
				jump(i)
	else:
		_go(p, (p["pos"] as Vector2).lerp(Vector2(220, 130), 0.15), top * 0.5, dt)

func _ai_defend(i: int, top: float, dt: float) -> void:
	var p: Dictionary = players[i]
	var team := int(p["team"])
	var skill: int = tier[team]
	var mark: Dictionary = players[(1 - team) * 3 + int(p["role"])]
	var on_ball: bool = int(mark["role"]) == int(players[owner]["role"])
	var to_rim := (HoopBall.RIM - (mark["pos"] as Vector2)).normalized()
	var gap := (17.0 - skill) if on_ball else 34.0
	var spot: Vector2 = (mark["pos"] as Vector2) + to_rim * gap
	if not on_ball:
		spot = spot.lerp(players[owner]["pos"], 0.12)   # sag towards the ball
	_go(p, spot, top * 0.96, dt)
	if (p["vel"] as Vector2).length() < 12.0:
		p["face"] = ((mark["pos"] as Vector2) - (p["pos"] as Vector2)).normalized()
	var h: Dictionary = players[owner]
	var d := (p["pos"] as Vector2).distance_to(h["pos"])
	if float(h["meter"]) >= 0.0 and d < 28.0:
		if float(p["react"]) < 0.0:   # one decision per shot: bite or stay down, after a reaction delay
			p["react"] = rng.randf_range(0.28, 0.6) - 0.04 * skill if rng.randf() < 0.45 + 0.1 * skill else 99.0
		elif float(h["meter"]) * METER_TIME >= float(p["react"]):
			jump(i)
			p["react"] = 99.0
	else:
		p["react"] = -1.0
		if d < STEAL_RANGE - 2.0 and float(h["hold"]) > 0.5 and rng.randf() < (0.22 + 0.1 * skill) * dt:
			try_steal(i)

func _ai_handler(i: int, top: float, dt: float) -> void:
	var p: Dictionary = players[i]
	var team := int(p["team"])
	var skill: int = tier[team]
	p["hold"] = float(p["hold"]) + dt
	var pos: Vector2 = p["pos"]
	var dist := pos.distance_to(HoopBall.RIM)
	var contest := contest_on(i)
	var mate := -1
	var mv := 0.0
	for k in range(team * 3, team * 3 + 3):
		if k != i and _lane_clear(i, k):
			var v := shot_value(k) + openness(k) * 0.004
			if v > mv:
				mv = v
				mate = k
	if must_clear:
		var out := HoopBall.RIM + (pos - HoopBall.RIM).normalized() * (HoopBall.ARC + 16.0)
		if (pos - HoopBall.RIM).y < 40.0:
			out = HoopBall.RIM + Vector2(signf(pos.x - 220.0 + 0.1) * 0.5, 0.87) * (HoopBall.ARC + 16.0)
		_go(p, out + _avoid(i) * 22.0, top, dt)
		if contest > 0.45 and mate >= 0 and float(p["hold"]) > 0.4 and rng.randf() < 1.6 * dt:
			pass_ball(i, mate)
		return
	var mine := shot_value(i)
	var want := maxf(0.72, 1.02 - maxf(0.0, float(p["hold"]) - 2.0) * 0.2)
	if shot_clock < 2.0 or (float(p["hold"]) > 0.3 and mine >= want and rng.randf() < (2.0 + mine * 2.0) * dt):
		if start_shot(i):
			var wobble := 0.145 - 0.015 * skill
			p["aim"] = clampf(SWEET + rng.randfn(0.0, wobble), 0.3, 0.98)
		return
	if float(p["hold"]) > 0.6 and mate >= 0 and (mv > mine + 0.25 or contest > 0.6 or float(p["hold"]) > 3.5):
		if rng.randf() < (1.2 + 0.2 * skill) * dt:
			pass_ball(i, mate)
			return
	# otherwise drive: at the rim, bending round whoever is in the way
	var goal := HoopBall.RIM + Vector2(0, 24) if dist > 40.0 else pos
	_go(p, goal + _avoid(i) * 40.0, top, dt)

func _avoid(i: int) -> Vector2:
	var push := Vector2.ZERO
	var pos: Vector2 = players[i]["pos"]
	for p in players:
		if int(p["team"]) != int(players[i]["team"]):
			var rel: Vector2 = pos - (p["pos"] as Vector2)
			if rel.length() < 36.0:
				var n := rel.normalized()
				push += (n + n.orthogonal() * (1.0 if i % 2 == 0 else -1.0)) * (1.0 - rel.length() / 36.0)
	return push

func _lane_clear(a: int, b: int) -> bool:
	var from: Vector2 = players[a]["pos"]
	var to: Vector2 = players[b]["pos"]
	for p in players:
		if int(p["team"]) != int(players[a]["team"]):
			var near := Geometry2D.get_closest_point_to_segment(p["pos"], from, to)
			if near.distance_to(p["pos"]) < 11.0:
				return false
	return true

func _separate() -> void:
	for a in players.size():
		for b in range(a + 1, players.size()):
			var rel: Vector2 = (players[b]["pos"] as Vector2) - (players[a]["pos"] as Vector2)
			var d := rel.length()
			if d < 11.0:
				var n := rel / d if d > 0.01 else Vector2.RIGHT
				var push := n * (11.0 - d) * 0.5
				players[a]["pos"] = (players[a]["pos"] as Vector2) - push
				players[b]["pos"] = (players[b]["pos"] as Vector2) + push
