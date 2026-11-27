class_name PourMath
extends RefCounted
## Pure arcs for the water that leaves the watering can: each drop is lobbed from the spout to a spot on the soil.

const DROPS_PER_CELL := 14
const EMIT_TIME := 0.2    # the stream runs this long (the rest of the pour pose)
const FLIGHT := 0.22      # one drop's trip from spout to soil
const RING_TIME := 0.18   # splash ring where it lands
const LIFT := 7.0         # how high the arc bulges above the straight line, px

## Seconds after the pour starts at which drop `i` leaves the spout.
static func birth(i: int, n: int = DROPS_PER_CELL) -> float:
	return EMIT_TIME * float(i) / float(maxi(n - 1, 1))

## Where on the target tile drop `i` lands: a fixed scatter inside the soil (offsets from the tile centre).
static func spread(i: int) -> Vector2:
	var a := float(i) * 2.399963   # golden angle: even cover with no clumps
	var r := sqrt(float(i % DROPS_PER_CELL) + 0.5) / sqrt(float(DROPS_PER_CELL))
	return Vector2(cos(a) * 12.0, sin(a) * 8.0) * r + Vector2(0, 3)

## Position at flight fraction u (0 = spout, 1 = soil): straight across, falling faster toward the end, with a small lift.
static func at(from: Vector2, to: Vector2, u: float) -> Vector2:
	u = clampf(u, 0.0, 1.0)
	var x := lerpf(from.x, to.x, u)
	var y := lerpf(from.y, to.y, u * u) - sin(u * PI) * (LIFT + absf(to.x - from.x) * 0.12)
	return Vector2(x, y)

## Everything is over once the last drop's ring has faded.
static func duration() -> float:
	return EMIT_TIME + FLIGHT + RING_TIME

## Where the spout is, relative to the player's feet, for a facing (the can's rose sits past the fist).
static func spout(facing: int) -> Vector2:
	var g := PoseMath.grip(PoseMath.CAN_POUR, facing)
	match facing:
		PlayerMath.Facing.DOWN:
			return g + Vector2(7, 3)
		PlayerMath.Facing.UP:
			return g + Vector2(5, -6)
		PlayerMath.Facing.LEFT:
			return g + Vector2(-9, 1)
	return g + Vector2(9, 1)
