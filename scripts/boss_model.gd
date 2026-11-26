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
			if pos.distance_to(player) <= WINDUP_DIST or timer >= CHASE_LIMIT:
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
			if timer >= (RAGE_RECOVER_TIME if enraged else RECOVER_TIME):
				_enter("walk")
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
		return {"dealt": dealt, "dead": true}
	if hp <= max_hp * 0.5:
		enraged = true
	return {"dealt": dealt, "dead": false}

## 0..1 through the windup (0 in every other state), for drawing the warning ring at slam_at.
func telegraph() -> float:
	if state != "windup":
		return 0.0
	return clampf(timer / _windup_len, 0.0, 1.0)

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
	return 5

static func loot(rng: RandomNumberGenerator) -> Array:
	return [["warden_core", 1], ["gold_ore", rng.randi_range(3, 5)], ["silver_ore", rng.randi_range(4, 6)]]

static func can_respawn(last_kill_day: int, day: int) -> bool:
	return last_kill_day < 0 or day - last_kill_day >= RESPAWN_DAYS

func _enter(next: String) -> void:
	state = next
	timer = 0.0
	vel = Vector2.ZERO

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
