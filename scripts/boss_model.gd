extends RefCounted
class_name BossModel
## The mine boss 'Stone Warden': a top-down fight in pixel space (32 px tiles). Pure rules, no nodes.
## step() drives it and returns events; the view draws from the fields, telegraph() and frame().
## `timer` is the seconds spent in the current state (in "walk": how long it has been chasing).

const MAX_HP := 260.0
const WAKE_DIST := 170.0
const WALK_SPEED := 40.0
const RAGE_SPEED := 58.0
const ACCEL := 120.0            # px/s^2
const WINDUP_DIST := 90.0
const CHASE_LIMIT := 4.0
const WINDUP_TIME := 0.9
const RAGE_WINDUP_TIME := 0.7
const SLAM_REACH := 96.0
const SLAM_RADIUS := 48.0
const SLAM_DAMAGE := 14.0
const SLAM_TIME := 0.2
const RECOVER_TIME := 1.4
const RAGE_RECOVER_TIME := 1.1
const HIDE_FACTOR := 0.4        # damage that gets through the stone hide outside "recover"
const ROCK_COUNT := 4
const ROCK_RADIUS := 22.0
const ROCK_DAMAGE := 8.0
const ROCK_MIN_T := 0.8
const ROCK_MAX_T := 1.6
const ROCK_MIN_SPREAD := 36.0
const ROCK_MAX_SPREAD := 90.0
const RESPAWN_DAYS := 7
# Boulder throw: the answer to a player who keeps their distance
const THROW_MIN_DIST := 140.0
const THROW_MAX_DIST := 420.0
const FAR_TIME := 1.5           # seconds at range before it reaches for a boulder
const RAGE_FAR_TIME := 1.1
const THROW_COOLDOWN := 5.0     # counted from the shatter
const AIM_TIME := 1.1
const RAGE_AIM_TIME := 0.9
const AIM_LOCK := 0.5           # the last part of the aim: the lane stops following
const RAGE_AIM_LOCK := 0.45
const THROW_POSE_TIME := 0.35
const BOULDER_R := 10.0
const BOULDER_SPEED := 230.0
const RAGE_BOULDER_SPEED := 265.0
const BOULDER_FRICTION := 55.0  # px/s^2 of rolling resistance
const BOULDER_RESTITUTION := 0.78
const BOULDER_MAX_BOUNCES := 3  # the last of these breaks it
const BOULDER_MIN_SPEED := 70.0
const BOULDER_MAX_AGE := 6.0
const BOULDER_BOUNCE_V := 25.0  # softer contacts (grazes) do not count as a bounce
const BOULDER_SPAWN := 24.0
const BOULDER_HIT_R := 17.0     # boulder plus the player's feet
const BOULDER_DAMAGE := 12.0    # at BOULDER_SPEED
const BOULDER_FORCE_PER_SPEED := 0.0075   # knockback force per px/s
const BOULDER_HIT_KEEP := 0.6   # speed left after bowling the player over
const BOULDER_SUBSTEP := 4.0    # most px moved between collision checks
const PUNISH_TIME := 2.3        # "recover" after a shatter: long enough to run in from range
const RAGE_PUNISH_TIME := 1.9
const TILE := 32.0
# Footstep thuds
const STEP_AMP := 1.1
const RAGE_STEP_AMP := 1.6
const STEP_NEAR := 56.0
const STEP_FAR := 230.0
const RAGE_STEP_FAR := 280.0
const STEP_MIN_AMP := 0.6       # weaker shakes are dropped (they would round away or only flicker)
const STEP_SHAKE_TIME := 0.07

var pos := Vector2.ZERO
var vel := Vector2.ZERO
var hp := MAX_HP
var max_hp := MAX_HP
var state := "sleep"
var timer := 0.0
var slam_at := Vector2.ZERO
var rocks: Array = []           # {pos, t: seconds until impact, done}; a done rock is dropped on the next step
var enraged := false
var _windup_len := WINDUP_TIME  # locked at windup start, so enraging never shortens a visible warning
var _wake_pending := false
var _enrage_told := false
var solid := Callable()         # (cell: Vector2i) -> bool, e.g. CaveModel.is_solid; unset = open ground
var grid_origin := Vector2.ZERO # world position of cell (0, 0)
var boulder: Dictionary = {}    # see new_boulder(); empty when none is rolling
var aim_dir := Vector2.DOWN
var far_t := 0.0                # how long the player has been keeping their distance
var throw_cd := 0.0
var _aim_len := AIM_TIME
var _aim_lock := AIM_LOCK
var _punish := false            # this "recover" follows a shattered boulder

static func new_boss(at: Vector2) -> BossModel:
	var b := BossModel.new()
	b.pos = at
	return b

func step(player: Vector2, dt: float, rng: RandomNumberGenerator) -> Array:
	var events: Array = []
	if state == "dead":
		return events
	if _wake_pending:
		_wake_pending = false
		events.append({"type": "wake"})
	if enraged and not _enrage_told:
		_enrage_told = true
		events.append({"type": "enrage"})
	_step_rocks(player, dt, events)
	if boulder.is_empty():
		throw_cd = maxf(0.0, throw_cd - dt)
	if state == "sleep":
		if pos.distance_to(player) <= WAKE_DIST:
			_enter("walk")
			events.append({"type": "wake"})
		return events
	timer += dt
	match state:
		"walk":
			var to := player - pos
			var speed := RAGE_SPEED if enraged else WALK_SPEED
			vel = vel.move_toward(to.normalized() * speed, ACCEL * dt)
			pos += vel * dt
			var dist := pos.distance_to(player)
			if dist >= THROW_MIN_DIST and dist <= THROW_MAX_DIST:
				far_t += dt
			else:
				far_t = maxf(0.0, far_t - dt * 2.0)
			if dist > WINDUP_DIST and throw_cd <= 0.0 and far_t >= (RAGE_FAR_TIME if enraged else FAR_TIME):
				start_aim(player)
				events.append({"type": "aim", "dir": aim_dir})
			elif dist <= WINDUP_DIST or timer >= CHASE_LIMIT:
				_enter("windup")
				_windup_len = RAGE_WINDUP_TIME if enraged else WINDUP_TIME
				slam_at = pos + (player - pos).limit_length(SLAM_REACH)
				events.append({"type": "windup", "at": slam_at})
		"windup":
			if timer >= _windup_len:
				_enter("slam")
				var hit := player.distance_to(slam_at) <= SLAM_RADIUS
				events.append({"type": "slam", "at": slam_at, "hit": hit, "damage": SLAM_DAMAGE if hit else 0.0})
				if enraged:
					events.append({"type": "rockfall", "at": _drop_rocks(player, rng)})
		"slam":
			if timer >= SLAM_TIME:
				_enter("recover")
		"recover":
			if timer >= recover_time():
				_enter("walk")
		"aim":
			if timer < _aim_len - _aim_lock:
				aim_dir = _toward(player)
			if timer >= _aim_len:
				_enter("throw")
				var speed := RAGE_BOULDER_SPEED if enraged else BOULDER_SPEED
				boulder = new_boulder(throw_origin(), aim_dir * speed)
				events.append({"type": "throw", "at": boulder["pos"]})
		"throw":
			_step_thrown(player, dt, events)
	return events

## Hurts the boss. Full damage while it recovers, otherwise the stone hide soaks most of it.
func take_hit(damage: float) -> Dictionary:
	if state == "dead" or damage <= 0.0:
		return {"dealt": 0.0, "dead": state == "dead"}
	var dealt := minf(damage if state == "recover" else damage * HIDE_FACTOR, hp)
	hp -= dealt
	if state == "sleep":
		_enter("walk")
		_wake_pending = true
	if hp <= 0.001:
		hp = 0.0
		_enter("dead")
		rocks.clear()
		boulder = {}
		return {"dealt": dealt, "dead": true}
	if hp <= max_hp * 0.5:
		enraged = true
	return {"dealt": dealt, "dead": false}

## 0..1 through the windup (0 in every other state), for drawing the warning ring at slam_at.
func telegraph() -> float:
	if state != "windup":
		return 0.0
	return clampf(timer / _windup_len, 0.0, 1.0)

func start_aim(player: Vector2) -> void:
	_enter("aim")
	_aim_len = RAGE_AIM_TIME if enraged else AIM_TIME
	_aim_lock = RAGE_AIM_LOCK if enraged else AIM_LOCK
	aim_dir = _toward(player)

## 0..1 through the boulder aim (0 in every other state), for drawing the warning lane.
func aim_progress() -> float:
	if state != "aim":
		return 0.0
	return clampf(timer / _aim_len, 0.0, 1.0)

## True once the lane has stopped following: time to get out of it.
func aim_locked() -> bool:
	return state == "aim" and timer >= _aim_len - _aim_lock

## Where a boulder thrown along aim_dir starts: in front of the Warden, or at its feet when a wall is there.
func throw_origin() -> Vector2:
	var at := pos + aim_dir * BOULDER_SPAWN
	return at if wall_contact(at, BOULDER_R, solid, grid_origin).is_empty() else pos

func recover_time() -> float:
	if _punish:
		return RAGE_PUNISH_TIME if enraged else PUNISH_TIME
	return RAGE_RECOVER_TIME if enraged else RECOVER_TIME

static func new_boulder(at: Vector2, velocity: Vector2) -> Dictionary:
	## spin is the signed angle turned (clockwise when rolling to the right); rolled is the distance covered.
	return {"pos": at, "vel": velocity, "rolled": 0.0, "spin": 0.0, "bounces": 0, "age": 0.0, "hit": false}

static func wall_contact(at: Vector2, radius: float, is_solid: Callable, origin: Vector2) -> Dictionary:
	## Deepest overlap of a circle with the solid tiles: {normal (out of the wall), depth}; {} when clear.
	var best := {}
	if not is_solid.is_valid():
		return best
	var local := at - origin
	for cy in range(floori((local.y - radius) / TILE), floori((local.y + radius) / TILE) + 1):
		for cx in range(floori((local.x - radius) / TILE), floori((local.x + radius) / TILE) + 1):
			if not is_solid.call(Vector2i(cx, cy)):
				continue
			var lo := Vector2(cx, cy) * TILE
			var off := local - local.clamp(lo, lo + Vector2(TILE, TILE))
			var d := off.length()
			var n := Vector2.ZERO
			var depth := 0.0
			if d > 0.001:
				if d >= radius - 0.001:
					continue
				n = off / d
				depth = radius - d
			else:   # the centre is on or in the tile: leave by the nearest face
				var faces := [[local.x - lo.x, Vector2.LEFT], [lo.x + TILE - local.x, Vector2.RIGHT],
					[local.y - lo.y, Vector2.UP], [lo.y + TILE - local.y, Vector2.DOWN]]
				var near: Array = []
				for f in faces:
					var beyond: Vector2i = Vector2i(cx, cy) + Vector2i(f[1])
					if not is_solid.call(beyond) and (near.is_empty() or float(f[0]) < float(near[0])):
						near = f
				if near.is_empty():
					continue
				n = near[1]
				depth = radius + float(near[0])
			if best.is_empty() or depth > float(best["depth"]):
				best = {"normal": n, "depth": depth}
	return best

static func bounce_velocity(v: Vector2, normal: Vector2, restitution: float) -> Vector2:
	## The part going into the wall comes back scaled by restitution; the part along the wall is kept.
	var into := v.dot(normal)
	if into >= 0.0:
		return v
	return v - normal * into * (1.0 + restitution)

static func boulder_step(b: Dictionary, dt: float, is_solid: Callable, origin: Vector2) -> Dictionary:
	## Rolls the boulder: rolling friction, wall bounces. Returns {bounced, impact: speed into the wall, shatter}.
	var res := {"bounced": false, "impact": 0.0, "shatter": false}
	var n := maxi(1, ceili((b["vel"] as Vector2).length() * dt / BOULDER_SUBSTEP))
	var h := dt / n
	for i in n:
		var v: Vector2 = b["vel"]
		v = v.move_toward(Vector2.ZERO, BOULDER_FRICTION * h)
		var from: Vector2 = b["pos"]
		var at := from + v * h
		var hardest := 0.0
		for pass_no in 3:   # a corner can touch two walls at once
			var c := wall_contact(at, BOULDER_R, is_solid, origin)
			if c.is_empty():
				break
			var normal: Vector2 = c["normal"]
			at += normal * float(c["depth"])
			hardest = maxf(hardest, -v.dot(normal))
			v = bounce_velocity(v, normal, BOULDER_RESTITUTION)
		var moved := from.distance_to(at)
		b["pos"] = at
		b["vel"] = v
		b["rolled"] = float(b["rolled"]) + moved
		b["spin"] = float(b["spin"]) + moved / BOULDER_R * (-1.0 if v.x < 0.0 else 1.0)
		b["age"] = float(b["age"]) + h
		if hardest >= BOULDER_BOUNCE_V:
			b["bounces"] = int(b["bounces"]) + 1
			res["bounced"] = true
			res["impact"] = maxf(float(res["impact"]), hardest)
		if int(b["bounces"]) >= BOULDER_MAX_BOUNCES or v.length() < BOULDER_MIN_SPEED or float(b["age"]) >= BOULDER_MAX_AGE:
			res["shatter"] = true
			break
	return res

static func knock_force(speed: float) -> float:
	return maxf(0.0, speed) * BOULDER_FORCE_PER_SPEED

static func boulder_damage(speed: float) -> float:
	return BOULDER_DAMAGE * clampf(speed / BOULDER_SPEED, 0.0, 1.2)

static func trace_lane(from: Vector2, dir: Vector2, is_solid: Callable, origin: Vector2, max_len := 440.0, stub := 56.0) -> PackedVector2Array:
	## The warning lane: [start, first wall (or full reach)], plus a short third point showing the rebound.
	var d := dir.normalized()
	var at := from
	var gone := 0.0
	while gone < max_len:
		var nxt := at + d * BOULDER_SUBSTEP
		var c := wall_contact(nxt, BOULDER_R, is_solid, origin)
		if not c.is_empty() and d.dot(c["normal"]) < 0.0:
			var out := bounce_velocity(d, c["normal"], BOULDER_RESTITUTION).normalized()
			var tail := 0.0
			while tail < stub and wall_contact(at + out * (tail + BOULDER_SUBSTEP), BOULDER_R - 1.0, is_solid, origin).is_empty():
				tail += BOULDER_SUBSTEP
			return PackedVector2Array([from, at, at + out * tail])
		at = nxt
		gone += BOULDER_SUBSTEP
	return PackedVector2Array([from, at])

static func roll_frame(spin: float, frames: int) -> int:
	## Which of `frames` evenly turned sprites shows this angle.
	return posmod(floori(spin / TAU * frames + 0.5), frames)

static func step_amp(dist: float, enraged_now: bool) -> float:
	## Camera shake (px) of one Warden footfall felt `dist` px away: full when close, fading to nothing.
	var reach := RAGE_STEP_FAR if enraged_now else STEP_FAR
	var k := 1.0 - clampf((dist - STEP_NEAR) / (reach - STEP_NEAR), 0.0, 1.0)
	var amp := (RAGE_STEP_AMP if enraged_now else STEP_AMP) * k
	return amp if amp >= STEP_MIN_AMP else 0.0

func _toward(player: Vector2) -> Vector2:
	var to := player - pos
	return to.normalized() if to.length() > 0.001 else Vector2.DOWN

func _step_thrown(player: Vector2, dt: float, events: Array) -> void:
	if boulder.is_empty():
		_enter("walk")
		return
	var n := maxi(1, ceili((boulder["vel"] as Vector2).length() * dt / BOULDER_SUBSTEP))
	for i in n:
		var res := boulder_step(boulder, dt / n, solid, grid_origin)
		var at: Vector2 = boulder["pos"]
		var v: Vector2 = boulder["vel"]
		if res["bounced"]:
			events.append({"type": "bounce", "at": at, "impact": res["impact"]})
		if not boulder["hit"] and at.distance_to(player) <= BOULDER_HIT_R:
			boulder["hit"] = true
			events.append({"type": "boulder_hit", "at": at, "hit": true, "vel": v, "damage": boulder_damage(v.length()), "force": knock_force(v.length())})
			boulder["vel"] = v * BOULDER_HIT_KEEP
		if res["shatter"]:
			events.append({"type": "shatter", "at": at})
			boulder = {}
			throw_cd = THROW_COOLDOWN
			_enter("recover")
			_punish = true
			return

## Frame of the 6-frame sprite: 0 asleep, 1/2 walking, 3 windup, 4 slam, 5 recover (also the dead pose).
func frame(anim_t: float) -> int:
	match state:
		"sleep":
			return 0
		"walk":
			return 1 + posmod(int(floor(anim_t * (6.0 if enraged else 4.0))), 2)
		"windup":
			return 3
		"slam":
			return 4
		"aim":
			return 3
		"throw":
			return 4 if timer < THROW_POSE_TIME else 1
	return 5

static func loot(rng: RandomNumberGenerator) -> Array:
	return [["warden_core", 1], ["gold_ore", rng.randi_range(3, 5)], ["silver_ore", rng.randi_range(4, 6)]]

static func can_respawn(last_kill_day: int, day: int) -> bool:
	return last_kill_day < 0 or day - last_kill_day >= RESPAWN_DAYS

func _enter(next: String) -> void:
	state = next
	timer = 0.0
	vel = Vector2.ZERO
	far_t = 0.0
	_punish = false

func _step_rocks(player: Vector2, dt: float, events: Array) -> void:
	rocks = rocks.filter(func(r: Dictionary) -> bool: return not r["done"])
	for r in rocks:
		r["t"] = float(r["t"]) - dt
		if r["t"] <= 0.0:
			r["done"] = true
			var hit := player.distance_to(r["pos"]) <= ROCK_RADIUS
			events.append({"type": "rock_land", "at": r["pos"], "hit": hit, "damage": ROCK_DAMAGE if hit else 0.0})

## One rock on the player and the rest spread around them. Returns the impact points.
func _drop_rocks(player: Vector2, rng: RandomNumberGenerator) -> Array:
	var spots: Array = [player]
	var base := rng.randf() * TAU
	for i in ROCK_COUNT - 1:
		var a := base + TAU * i / (ROCK_COUNT - 1) + rng.randf_range(-0.5, 0.5)
		spots.append(player + Vector2.from_angle(a) * rng.randf_range(ROCK_MIN_SPREAD, ROCK_MAX_SPREAD))
	for p in spots:
		rocks.append({"pos": p, "t": rng.randf_range(ROCK_MIN_T, ROCK_MAX_T), "done": false})
	return spots
