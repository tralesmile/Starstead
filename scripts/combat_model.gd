class_name CombatModel
extends RefCounted
## Pure melee rules: weapon table, swing cone test, damage/health, knock-out and recovery.
## Cartoony-gritty: hits knock people out for a while instead of killing (age-rating friendly).

const WEAPONS := {
	"fist": {"dmg": 4.0, "range": 28.0, "force": 0.6, "cooldown": 0.35},
	"club": {"dmg": 10.0, "range": 38.0, "force": 1.2, "cooldown": 0.5},
}
const MAX_HP := 30.0
const DOWN_SECONDS := 6.0
const CONE_COS := 0.35   # ~110 degree swing cone in front of the attacker

static func weapon(id: String) -> Dictionary:
	return WEAPONS.get(id, WEAPONS["fist"])

static func facing_vec(face: int) -> Vector2:
	## Same facing order as PlayerMath.Facing (DOWN, UP, LEFT, RIGHT); unknown = down.
	match face:
		PlayerMath.Facing.UP:
			return Vector2.UP
		PlayerMath.Facing.LEFT:
			return Vector2.LEFT
		PlayerMath.Facing.RIGHT:
			return Vector2.RIGHT
	return Vector2.DOWN

static func in_swing(attacker: Vector2, face: Vector2, target: Vector2, reach: float) -> bool:
	var d := target - attacker
	var len := d.length()
	if len > reach:
		return false
	if len < 0.001:
		return true
	return d.normalized().dot(face.normalized()) >= CONE_COS

static func hit(hp: float, dmg: float) -> float:
	return maxf(0.0, hp - dmg)

static func is_down(hp: float) -> bool:
	return hp <= 0.0

## Seconds left lying down; stands up with half health when it reaches 0.
static func recover(down_left: float, dt: float) -> float:
	return maxf(0.0, down_left - dt)

static func stand_hp() -> float:
	return MAX_HP * 0.5

static func crime_for(target_kind: String) -> String:
	return "assault"

static func cooldown(id: String) -> float:
	return float(weapon(id)["cooldown"])

const CAR_MIN_SPEED := 60.0

## Damage + knockback force when a moving car hits someone; zero below walking-pace bumps.
static func car_hit(speed: float) -> Dictionary:
	if speed < CAR_MIN_SPEED:
		return {"dmg": 0.0, "force": 0.0}
	return {"dmg": minf(MAX_HP, speed * 0.25), "force": clampf(speed / 150.0, 0.5, 2.5)}

# --- combo: land hits in quick succession and each one hits harder; the third is a heavy finisher ---
const COMBO_WINDOW := 0.9      # s after a landing hit during which the next swing continues the chain
const COMBO_STEP := 0.25       # +25% damage per chained hit
const COMBO_MAX := 3           # hits in a chain (the last is the finisher)

static func chain_len(combo: int, since_hit: float) -> int:
	## Hits already chained when a swing starts: 0 after a finisher or when the window ran out.
	return combo if (since_hit <= COMBO_WINDOW and combo < COMBO_MAX) else 0

static func combo_next(combo: int, since_hit: float, landed: bool) -> int:
	## Stored chain length after a swing. A miss resets it; hitting after a finisher or a late swing starts over at 1.
	if not landed:
		return 0
	return chain_len(combo, since_hit) + 1

static func combo_weapon(w: Dictionary, combo: int) -> Dictionary:
	## The weapon as modified by the chain length before this swing (0 = first hit).
	var c := clampi(combo, 0, COMBO_MAX - 1)
	var out := w.duplicate()
	out["dmg"] = float(w["dmg"]) * (1.0 + COMBO_STEP * c)
	out["force"] = float(w["force"]) * (1.0 + (0.5 if c >= COMBO_MAX - 1 else 0.0))
	return out

# --- lunge: the blow carries the body a few pixels forward on the strike frame ---
const LUNGE_PX := 5.0          # first hit of a chain
const LUNGE_STEP_PX := 2.5     # each chained hit steps in further

static func lunge_px(chain: int) -> float:
	return LUNGE_PX + LUNGE_STEP_PX * clampi(chain, 0, COMBO_MAX - 1)

static func lunge_velocity(face: Vector2, chain: int, decay: float) -> Vector2:
	## The push that slides lunge_px(chain) before `decay` (px/s per second) stops it: v = sqrt(2 * decay * d).
	return face.normalized() * sqrt(2.0 * decay * lunge_px(chain))

static func club_mult(inv: Inventory, clubs: Dictionary) -> float:
	## Best banded club in the bag scales the base club's damage (1.0 with the plain club).
	var best := 1.0
	for id in clubs:
		if inv.count(String(id)) > 0:
			best = maxf(best, float(clubs[id]["dmg_mult"]))
	return best

static func with_mult(w: Dictionary, mult: float) -> Dictionary:
	var out := w.duplicate()
	out["dmg"] = float(w["dmg"]) * mult
	return out
