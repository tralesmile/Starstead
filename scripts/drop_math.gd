class_name DropMath
extends RefCounted
## Pure maths for items lying in the world: pop arc, bobbing, magnet toward the player, pickup.

const POP_TIME := 0.4      # s: item arcs out, cannot be picked up yet
const MAGNET_R := 56.0     # px: starts flying to the player
const PICKUP_R := 12.0
const LIFETIME := 300.0    # s before an unclaimed drop despawns

## Height (px, up is positive) during the pop arc; 0 once landed.
static func pop_height(age: float) -> float:
	if age >= POP_TIME:
		return 0.0
	var k := age / POP_TIME
	return 4.0 * k * (1.0 - k) * 14.0

## Whole-pixel idle bob after landing.
static func bob(age: float, phase: float) -> float:
	if age < POP_TIME:
		return 0.0
	return roundf(sin(age * 3.0 + phase) * 1.5)

## Horizontal scatter for piece i of n (spread on a small ring, deterministic).
static func scatter(i: int, n: int) -> Vector2:
	if n <= 1:
		return Vector2.ZERO
	return Vector2.from_angle(TAU * float(i) / float(n) + 0.6) * 14.0

static func in_magnet(pos: Vector2, player: Vector2, age: float) -> bool:
	return age >= POP_TIME and pos.distance_to(player + Vector2(0, -6)) <= MAGNET_R

## Next position while magnetised: speeds up as it nears the player.
static func magnet_step(pos: Vector2, player: Vector2, dt: float) -> Vector2:
	var t := player + Vector2(0, -6)
	var d := pos.distance_to(t)
	var spd := lerpf(260.0, 70.0, clampf(d / MAGNET_R, 0.0, 1.0))
	return pos.move_toward(t, spd * dt)

static func in_pickup(pos: Vector2, player: Vector2) -> bool:
	return pos.distance_to(player + Vector2(0, -6)) <= PICKUP_R

## Pieces to spawn for a stack: one item per piece up to a cap, the rest bundled in the last.
static func pieces(n: int, cap: int = 5) -> Array:
	var out: Array = []
	var left := maxi(n, 0)
	var k := mini(left, cap)
	for i in k:
		var c := 1
		if i == k - 1:
			c = left - (k - 1)
		out.append(c)
	return out
