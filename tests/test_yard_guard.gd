extends BaseTest

func test_routes_inside_yard_off_props() -> void:
	var solid := VanceYard.solid_cells()
	for route in YardGuard.routes():
		check(route.size() >= 3)
		for c in route:
			check(VanceYard.in_rect(c) and not VanceYard.is_fence(c), "in the yard %s" % str(c))
			check(not solid.has(c), "not on a prop %s" % str(c))

func test_sees_only_inside_fence() -> void:
	var inside := Vector2i(285, -102)
	var d := Vector2(inside) * 32.0
	check(YardGuard.sees(d, d + Vector2(80, 0), inside))
	check(not YardGuard.sees(d, d + Vector2(300, 0), inside), "too far")
	check(not YardGuard.sees(d, d + Vector2(80, 0), Vector2i(285, -90)), "player outside the fence")

func test_step_speeds() -> void:
	var a := YardGuard.step(Vector2.ZERO, Vector2(1000, 0), false, 1.0)
	var b := YardGuard.step(Vector2.ZERO, Vector2(1000, 0), true, 1.0)
	check(b.x > a.x)
	check_eq(YardGuard.step(Vector2.ZERO, Vector2(3, 0), true, 1.0), Vector2(3, 0), "no overshoot")

func test_waypoint_and_bite() -> void:
	var pts := [Vector2(0, 0), Vector2(100, 0), Vector2(0, 100)]
	check_eq(YardGuard.next_waypoint(0, Vector2(2, 0), pts), 1)
	check_eq(YardGuard.next_waypoint(2, Vector2(2, 100), pts), 0, "wraps")
	check_eq(YardGuard.next_waypoint(1, Vector2(50, 0), pts), 1)
	check(YardGuard.can_bite(Vector2.ZERO, Vector2(10, 0), 0.0))
	check(not YardGuard.can_bite(Vector2.ZERO, Vector2(10, 0), 1.0), "cooldown")
	check(not YardGuard.can_bite(Vector2.ZERO, Vector2(40, 0), 0.0), "out of reach")
