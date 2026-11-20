class_name YardGuard
extends RefCounted
## Pure rules for the guard dogs that patrol the Vance rocket yard: they trot a loop of waypoints, give chase when
## you are inside the fence and close, bite on contact (energy loss, then a cooldown) and return to the loop once
## you leave. Raw meat in your bag does not help here: these are trained.

const SPEED := 46.0        # px/s patrolling
const CHASE_SPEED := 88.0  # px/s, faster than a walk, slower than a sprint
const SEE_RADIUS := 170.0
const BITE_RADIUS := 18.0
const BITE_COOLDOWN := 2.5
const BITE_COST := 10.0    # energy

static func routes() -> Array:
	## Two loops (cells) inside the yard, clear of the rocket, hangar and tanks.
	var r := VanceYard.RECT
	var l := r.position.x + 3
	var rt := r.end.x - 6
	var t := r.position.y + 3
	var b := r.end.y - 4
	return [
		[Vector2i(l, b), Vector2i(l, t + 6), Vector2i(l + 4, b)],
		[Vector2i(rt, t + 6), Vector2i(rt, b), Vector2i(rt - 3, t + 6)],
	]

static func sees(dog: Vector2, player: Vector2, player_cell: Vector2i) -> bool:
	return VanceYard.in_rect(player_cell) and dog.distance_to(player) <= SEE_RADIUS

static func step(dog: Vector2, target: Vector2, chasing: bool, dt: float) -> Vector2:
	var d := target - dog
	var l := d.length()
	if l < 0.5:
		return dog
	return dog + d / l * minf((CHASE_SPEED if chasing else SPEED) * dt, l)

static func next_waypoint(idx: int, dog: Vector2, route_px: Array) -> int:
	if dog.distance_to(route_px[idx]) < 6.0:
		return (idx + 1) % route_px.size()
	return idx

static func can_bite(dog: Vector2, player: Vector2, cooldown: float) -> bool:
	return cooldown <= 0.0 and dog.distance_to(player) <= BITE_RADIUS
