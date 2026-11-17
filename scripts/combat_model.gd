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
