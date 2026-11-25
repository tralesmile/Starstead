class_name GearModel
extends RefCounted
## Forged gear carried in the bag: vests soften bites and hits, car parts tune the car. Pure rules, no nodes.

const VEST_TAKEN := {"leather_vest": 0.9, "copper_vest": 0.85, "iron_vest": 0.7}   # share of damage you still take (best vest counts)
const ENGINE_KIT_SPEED := 1.12
const GRIP_TYRES_GRIP := 1.2
const BUMPER_TAKEN := 0.65   # share of crash damage the car still takes

static func damage_taken_mult(bag: Inventory) -> float:
	var m := 1.0
	for id in VEST_TAKEN:
		if bag.count(id) > 0:
			m = minf(m, float(VEST_TAKEN[id]))
	return m

static func soften(bag: Inventory, dmg: float) -> float:
	return dmg * damage_taken_mult(bag)

static func top_speed_mult(bag: Inventory) -> float:
	return ENGINE_KIT_SPEED if bag.count("engine_kit") > 0 else 1.0

static func grip_mult(bag: Inventory) -> float:
	return GRIP_TYRES_GRIP if bag.count("grip_tyres") > 0 else 1.0

static func crash_mult(bag: Inventory) -> float:
	return BUMPER_TAKEN if bag.count("bumper_guard") > 0 else 1.0

## Grey-black smoke from a battered engine: none above 60% health, thick at 0.
static func smoke_rate(health: float) -> float:
	var f := clampf((60.0 - health) / 60.0, 0.0, 1.0)
	return f * f * 9.0   # puffs per second

static func smoke_alpha(health: float) -> float:
	return lerpf(0.25, 0.7, clampf((60.0 - health) / 60.0, 0.0, 1.0))

## Forging sparks: n sparks fan upward; deterministic velocity for spark i (px/s).
static func spark_velocity(i: int, n: int) -> Vector2:
	var t := (float(i) + 0.5) / float(maxi(n, 1))
	var ang := lerpf(-PI * 0.85, -PI * 0.15, t)
	var sp := 70.0 + 50.0 * fposmod(float(i) * 0.618, 1.0)
	return Vector2(cos(ang), sin(ang)) * sp

static func spark_pos(origin: Vector2, vel: Vector2, age: float) -> Vector2:
	return origin + vel * age + Vector2(0, 160.0 * age * age)   # gravity pulls them down
