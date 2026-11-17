class_name PoliceModel
extends RefCounted
## Pure police logic: chase steering, arrest check, spawn ring, witness test. Heat itself lives in WantedMath.

const CHASE_SPEED := 52.0       # slightly below player run speed so escape is possible on foot
const STAR_SPEED := 6.0         # extra speed per star
const ARREST_RADIUS := 14.0
const SIGHT := 220.0
const SPAWN_RING := 260.0

static func speed(star_n: int) -> float:
	return CHASE_SPEED + STAR_SPEED * star_n

static func step(pos: Vector2, target: Vector2, star_n: int, dt: float) -> Vector2:
	return pos.move_toward(target, speed(star_n) * dt)

static func arrests(pos: Vector2, target: Vector2) -> bool:
	return pos.distance_to(target) <= ARREST_RADIUS

static func sees(pos: Vector2, target: Vector2) -> bool:
	return pos.distance_to(target) <= SIGHT

static func any_sees(cops: Array, target: Vector2) -> bool:
	for c in cops:
		if sees(c, target):
			return true
	return false

static func spawn_positions(center: Vector2, n: int) -> Array:
	var out := []
	for i in n:
		var a := TAU * float(i) / float(maxi(n, 1)) + 0.7
		out.append(center + Vector2.from_angle(a) * SPAWN_RING)
	return out

static func witnessed(cops: Array, crime_pos: Vector2) -> bool:
	return any_sees(cops, crime_pos)
