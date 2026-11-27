class_name BankJob
extends RefCounted
## Pure rules for the Halden Bank vault job (Act 2): an 18x9-cell stealth room behind the lobby's vault door.
## A guard walks a route (vision cone, pauses and turns, hears running, investigates the last spot he saw you),
## two cameras sweep until the fuse box is pulled, the guard-room desk holds the keycard for the vault door,
## cash bags are bagged by holding E, and only walking out of the door banks them. No autoloads: tests run it.

const W := 18
const H := 9
const CELL := 32.0
const ORIGIN := Vector2(32, 38)               # room origin on the 640x360 screen
const PANEL := Rect2(26, 12, 588, 336)        # wooden window around it (frame grows 6px more)
const COOLDOWN_DAYS := 7
const NIGHT_FROM := 20.0                      # the vault wing is only unguarded enough after 20:00 ...
const NIGHT_TO := 6.0                         # ... until 6:00
const CAUGHT_FINE := 250

const WALK := 100.0
const SNEAK := 55.0
const SPRINT := 165.0
const HEAR_SPRINT := 170.0
const HEAR_WALK := 40.0

const PATROL_SPEED := 42.0
const CHASE_SPEED := 74.0
const TURN_RATE := 3.2                        # rad/s while standing
const GUARD_RANGE := 145.0
const GUARD_FOV := 1.25
const GUARD_RATE := 1.0                       # meter/s at mid range
const CAM_RATE := 0.7
const SNEAK_SEEN := 0.6                       # sneaking slows the build-up
const DECAY := 0.3
const SUSPECT_AT := 0.28
const TOUCH := 15.0
const SUSPECT_TIME := 0.9                     # stands and stares before walking over
const SEARCH_TIME := 3.0

const CARD_TIME := 1.0
const FUSE_TIME := 1.2
const DOOR_TIME := 1.0
const BAG_TIME := 1.8
const USE_RANGE := 26.0

enum Guard { PATROL, PAUSE, SUSPICIOUS, INVESTIGATE, SEARCH }

const EXIT_X := 1                                     # door back to the lobby, bottom row
const WALLS := [Rect2i(12, 0, 1, 4), Rect2i(12, 5, 1, 4), Rect2i(0, 3, 3, 1), Rect2i(5, 0, 1, 2)]
const COVER := [Rect2i(3, 5, 2, 1), Rect2i(8, 2, 1, 2), Rect2i(8, 6, 2, 1), Rect2i(15, 4, 1, 1)]
const DESK := Rect2i(1, 0, 2, 1)
const FUSE := Rect2i(11, 8, 1, 1)
const VAULT_DOOR := Rect2i(12, 4, 1, 1)
const BAGS := [
	{"cell": Vector2i(14, 1), "cash": 250},
	{"cell": Vector2i(17, 1), "cash": 300},
	{"cell": Vector2i(14, 7), "cash": 350},
	{"cell": Vector2i(17, 7), "cash": 400},
]
## guard route: spot (px), seconds he stands there, direction (rad) he turns to look while standing
const ROUTE := [
	{"pos": Vector2(208, 48), "wait": 2.2, "look": PI},
	{"pos": Vector2(344, 48), "wait": 2.0, "look": 0.4},
	{"pos": Vector2(344, 160), "wait": 2.4, "look": 0.0},
	{"pos": Vector2(208, 160), "wait": 2.6, "look": PI * 0.5},
	{"pos": Vector2(144, 144), "wait": 2.4, "look": PI},
	{"pos": Vector2(144, 112), "wait": 0.4, "look": -PI * 0.5},
]
## cameras: pivot (px), centre angle, sweep amplitude, period (s), phase, range (px), fov
const CAMS := [
	{"pos": Vector2(272, 4), "mid": 1.57, "amp": 0.85, "period": 8.0, "phase": 0.0, "range": 170.0, "fov": 0.55},
	{"pos": Vector2(512, 4), "mid": 1.57, "amp": 0.8, "period": 7.0, "phase": 2.0, "range": 190.0, "fov": 0.55},
]

var t := 0.0
var pos := Vector2.ZERO
var meter := 0.0
var cams_on := true
var has_card := false
var vault_open := false
var taken: Array = []
var hold := 0.0
var hold_id := ""
var result := ""                 # "" running, "caught", "out" (walked out), "abandon"
var seen_now := false
var moving := false

var g_pos := Vector2.ZERO
var g_face := 0.0
var g_state: int = Guard.PAUSE
var g_wp := 0                    # route index he stands at / walks to
var g_timer := 0.0
var g_last := Vector2.ZERO       # last spot he saw or heard you
var g_path: Array = []

func _init() -> void:
	reset()

func reset() -> void:
	t = 0.0
	pos = entrance()
	meter = 0.0
	cams_on = true
	has_card = false
	vault_open = false
	taken = []
	hold = 0.0
	hold_id = ""
	result = ""
	seen_now = false
	moving = false
	g_wp = 1
	g_pos = ROUTE[1]["pos"]
	g_face = float(ROUTE[1]["look"])
	g_state = Guard.PAUSE
	g_timer = float(ROUTE[1]["wait"])
	g_last = g_pos
	g_path = []

func clone() -> BankJob:
	var c := BankJob.new()
	for k in ["t", "pos", "meter", "cams_on", "has_card", "vault_open", "hold", "hold_id", "result", "seen_now", "moving", "g_pos", "g_face", "g_state", "g_wp", "g_timer", "g_last"]:
		c.set(k, get(k))
	c.taken = taken.duplicate()
	c.g_path = g_path.duplicate()
	return c

# --- entry rules ---

static func ready(last_day: int, day: int) -> bool:
	return last_day < 0 or day - last_day >= COOLDOWN_DAYS

static func days_left(last_day: int, day: int) -> int:
	return 0 if ready(last_day, day) else COOLDOWN_DAYS - (day - last_day)

static func is_night(hour: float) -> bool:
	return hour >= NIGHT_FROM or hour < NIGHT_TO

## "" when the vault wing can be entered, else what the player is told.
static func entry_block(bank_open: bool, broke_in: bool, hour: float, last_day: int, day: int) -> String:
	if bank_open or not broke_in:
		return "The vault wing is time-locked. You would have to break in after closing."
	if not is_night(hour):
		return "Cleaners are still about. The vault wing is only quiet from %d:00." % int(NIGHT_FROM)
	if not ready(last_day, day):
		return "The bank doubled its watch. Try again in %d day(s)." % days_left(last_day, day)
	return ""

static func fine_for(money: int) -> int:
	return clampi(CAUGHT_FINE, 0, maxi(money, 0))

static func total_cash(list: Array) -> int:
	var s := 0
	for i in list:
		s += int(BAGS[int(i)]["cash"])
	return s

## Cash that actually reaches your pocket: only a walk out of the door banks anything.
func banked() -> int:
	return total_cash(taken) if result == "out" else 0

# --- geometry ---

static func px(r: Rect2i) -> Rect2:
	return Rect2(Vector2(r.position) * CELL, Vector2(r.size) * CELL)

static func bag_rect(i: int) -> Rect2:
	return Rect2(Vector2(BAGS[i]["cell"]) * CELL, Vector2(CELL, CELL))

static func entrance() -> Vector2:
	return Vector2((EXIT_X + 0.5) * CELL, H * CELL - 20.0)

## Things that block walking and sight.
func blockers() -> Array[Rect2]:
	var out: Array[Rect2] = []
	for r in WALLS:
		out.append(px(r))
	for r in COVER:
		out.append(px(r))
	out.append(px(DESK))
	if not vault_open:
		out.append(px(VAULT_DOOR))
	return out

static func line_clear(a: Vector2, b: Vector2, rects: Array[Rect2]) -> bool:
	var steps := maxi(1, ceili(a.distance_to(b) / 4.0))
	for i in steps + 1:
		var p := a.lerp(b, float(i) / steps)
		for r in rects:
			if r.has_point(p):
				return false
	return true

func in_cone(from: Vector2, facing: float, rng: float, fov: float, p: Vector2) -> bool:
	var d := p - from
	if d.length() > rng:
		return false
	if absf(angle_difference(d.angle(), facing)) > fov * 0.5:
		return false
	return line_clear(from, p, blockers())

static func cam_angle(i: int, time: float) -> float:
	var c: Dictionary = CAMS[i]
	return float(c["mid"]) + float(c["amp"]) * sin(TAU * time / float(c["period"]) + float(c["phase"]))

func guard_sees(p: Vector2) -> bool:
	return in_cone(g_pos, g_face, GUARD_RANGE, GUARD_FOV, p)

func cam_sees(i: int, p: Vector2) -> bool:
	if not cams_on:
		return false
	var c: Dictionary = CAMS[i]
	return in_cone(c["pos"], cam_angle(i, t), float(c["range"]), float(c["fov"]), p)

## Length of a vision ray before a wall or the room edge stops it (for drawing the cones).
func ray_length(from: Vector2, angle: float, rng: float, rects: Array[Rect2]) -> float:
	var dir := Vector2.from_angle(angle)
	var s := 4.0
	while s < rng:
		var q := from + dir * s
		if q.x < 0.0 or q.y < 0.0 or q.x > W * CELL or q.y > H * CELL:
			return s
		for r in rects:
			if r.has_point(q):
				return s
		s += 4.0
	return rng

static func feet(p: Vector2) -> Rect2:
	return Rect2(p - Vector2(6, 4), Vector2(12, 8))

func _free(p: Vector2) -> bool:
	if p.x < 8.0 or p.x > W * CELL - 8.0 or p.y < 12.0:
		return false
	if p.y > H * CELL - 6.0 and absf(p.x - (EXIT_X + 0.5) * CELL) > 12.0:
		return false
	var f := feet(p)
	for r in blockers():
		if r.intersects(f):
			return false
	for i in BAGS.size():
		if not (i in taken) and bag_rect(i).grow(-8).intersects(f):
			return false
	return true

# --- guard path finding (grid, 4-way) ---

static func cell_of(p: Vector2) -> Vector2i:
	return Vector2i(clampi(floori(p.x / CELL), 0, W - 1), clampi(floori(p.y / CELL), 0, H - 1))

static func centre(c: Vector2i) -> Vector2:
	return (Vector2(c) + Vector2(0.5, 0.5)) * CELL

func cell_walkable(c: Vector2i) -> bool:
	if c.x < 0 or c.y < 0 or c.x >= W or c.y >= H:
		return false
	var p := centre(c)
	for r in blockers():
		if r.has_point(p):
			return false
	return true

## Waypoints (px) from a to b around walls; ends as near b as the guard can stand.
func path(a: Vector2, b: Vector2) -> Array:
	var start := cell_of(a)
	var goal := cell_of(b)
	var came := {start: start}
	var queue: Array[Vector2i] = [start]
	var head := 0
	var nearest := start
	while head < queue.size():
		var c: Vector2i = queue[head]
		head += 1
		if Vector2(c - goal).length_squared() < Vector2(nearest - goal).length_squared():
			nearest = c
		if c == goal:
			break
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = c + d
			if not came.has(n) and cell_walkable(n):
				came[n] = c
				queue.append(n)
	var out: Array = []
	var k := nearest
	while k != start:
		out.push_front(centre(k))
		k = came[k]
	if nearest == goal and cell_walkable(goal):
		if out.is_empty():
			out.append(b)
		else:
			out[out.size() - 1] = b
	return out

# --- guard brain ---

func _alert(at: Vector2) -> void:
	g_last = at
	if g_state == Guard.PATROL or g_state == Guard.PAUSE or g_state == Guard.SEARCH:
		g_state = Guard.SUSPICIOUS
		g_timer = SUSPECT_TIME

func _turn(to: float, delta: float) -> void:
	g_face = rotate_toward(g_face, to, TURN_RATE * delta)

## Follow g_path; true once it is used up.
func _walk(speed: float, delta: float) -> bool:
	var left := speed * delta
	while left > 0.0 and not g_path.is_empty():
		var to: Vector2 = g_path[0]
		var d := g_pos.distance_to(to)
		if d > 0.5:
			_turn((to - g_pos).angle(), delta * 2.0)
		if d <= left:
			g_pos = to
			g_path.pop_front()
			left -= d
		else:
			g_pos = g_pos.move_toward(to, left)
			left = 0.0
	return g_path.is_empty()

func _guard_step(delta: float) -> void:
	match g_state:
		Guard.PAUSE:
			_turn(float(ROUTE[g_wp]["look"]), delta)
			g_timer -= delta
			if g_timer <= 0.0:
				g_wp = (g_wp + 1) % ROUTE.size()
				g_path = path(g_pos, ROUTE[g_wp]["pos"])
				g_state = Guard.PATROL
		Guard.PATROL:
			if _walk(PATROL_SPEED, delta):
				g_state = Guard.PAUSE
				g_timer = float(ROUTE[g_wp]["wait"])
		Guard.SUSPICIOUS:
			_turn((g_last - g_pos).angle(), delta)
			g_timer -= delta
			if g_timer <= 0.0:
				g_state = Guard.INVESTIGATE
				g_path = path(g_pos, g_last)
		Guard.INVESTIGATE:
			if not g_path.is_empty() and (g_path.back() as Vector2).distance_to(g_last) > CELL:
				g_path = path(g_pos, g_last)
			if _walk(CHASE_SPEED, delta):
				g_state = Guard.SEARCH
				g_timer = SEARCH_TIME
		Guard.SEARCH:
			g_face = wrapf(g_face + 2.2 * delta, -PI, PI)
			g_timer -= delta
			if g_timer <= 0.0:
				g_path = path(g_pos, ROUTE[g_wp]["pos"])
				g_state = Guard.PATROL

# --- player ---

## What holding E would do right now: {id, need (seconds), label} or {}. A locked door has need 0.
func use_target() -> Dictionary:
	if not has_card and px(DESK).grow(USE_RANGE).has_point(pos) and pos.y < 3 * CELL:
		return {"id": "card", "need": CARD_TIME, "label": "Hold E: take the keycard"}
	if cams_on and px(FUSE).grow(USE_RANGE).has_point(pos) and pos.x < 12 * CELL:
		return {"id": "fuse", "need": FUSE_TIME, "label": "Hold E: pull the camera fuse"}
	if not vault_open and px(VAULT_DOOR).grow(USE_RANGE).has_point(pos):
		if has_card:
			return {"id": "door", "need": DOOR_TIME, "label": "Hold E: swipe the keycard"}
		return {"id": "locked", "need": 0.0, "label": "Locked. The keycard is on the guard desk"}
	for i in BAGS.size():
		if not (i in taken) and bag_rect(i).grow(USE_RANGE).has_point(pos):
			return {"id": "bag%d" % i, "need": BAG_TIME, "label": "Hold E: bag $%d" % int(BAGS[i]["cash"])}
	return {}

func _complete(id: String) -> void:
	match id:
		"card": has_card = true
		"fuse": cams_on = false
		"door": vault_open = true
		_:
			if id.begins_with("bag"):
				taken.append(int(id.substr(3)))

func _use_step(delta: float, using: bool) -> void:
	var u := use_target()
	if using and not u.is_empty() and float(u["need"]) > 0.0 and not moving:
		if hold_id != String(u["id"]):
			hold_id = String(u["id"])
			hold = 0.0
		hold += delta
		if hold >= float(u["need"]):
			_complete(hold_id)
			hold = 0.0
			hold_id = ""
	else:
		hold = maxf(hold - delta * 2.0, 0.0)
		if hold <= 0.0:
			hold_id = ""

func abandon() -> void:
	if result == "":
		result = "abandon"

## One frame. move is the input vector; sneak wins over sprint.
func step(delta: float, move: Vector2, sneak: bool, sprint: bool, using: bool) -> void:
	if result != "":
		return
	t += delta
	var speed := SNEAK if sneak else (SPRINT if sprint else WALK)
	var v := move.limit_length(1.0) * speed * delta
	var before := pos
	if _free(pos + Vector2(v.x, 0)):
		pos.x += v.x
	if _free(pos + Vector2(0, v.y)):
		pos.y += v.y
	moving = pos.distance_to(before) > 0.01
	if pos.y > H * CELL - 8.0 and move.y > 0.1 and absf(pos.x - (EXIT_X + 0.5) * CELL) <= 16.0:
		result = "out"
		return
	_use_step(delta, using)
	_guard_step(delta)
	if moving and not sneak:
		var reach := HEAR_SPRINT if sprint else HEAR_WALK
		if g_pos.distance_to(pos) <= reach:
			_alert(pos)
	var rate := 0.0
	var by_guard := guard_sees(pos)
	if by_guard:
		rate += GUARD_RATE * clampf(1.6 - g_pos.distance_to(pos) / GUARD_RANGE * 1.2, 0.5, 1.6)
	for i in CAMS.size():
		if cam_sees(i, pos):
			rate += CAM_RATE
	seen_now = rate > 0.0
	if seen_now:
		meter = minf(meter + rate * (SNEAK_SEEN if sneak else 1.0) * delta, 1.0)
		if meter >= SUSPECT_AT:
			_alert(pos)          # a camera radios him too
	else:
		meter = maxf(meter - DECAY * delta, 0.0)
	if meter >= 1.0 or g_pos.distance_to(pos) < TOUCH:
		meter = 1.0
		result = "caught"
