extends BaseTest

func test_angle_starts_flat_and_ends_lying() -> void:
	check_eq(TreeFall.angle(0.0, 1.0), 0.0)
	check_eq(TreeFall.angle(TreeFall.FALL_TIME, 1.0), TreeFall.LAND)
	check_eq(TreeFall.angle(5.0, -1.0), -TreeFall.LAND)

func test_angle_accelerates_then_settles() -> void:
	var a1 := TreeFall.angle(0.2, 1.0)
	var a2 := TreeFall.angle(0.4, 1.0)
	var a3 := TreeFall.angle(0.6, 1.0)
	check(a1 < a2 and a2 < a3)
	check(a2 - a1 < a3 - a2)
	for i in 21:
		check(absf(TreeFall.angle(i * 0.04, 1.0)) < TreeFall.LAND + 0.1)

func test_direction_mirrors() -> void:
	check_eq(TreeFall.angle(0.5, 1.0), -TreeFall.angle(0.5, -1.0))

func test_impact_shake_only_after_landing() -> void:
	check_eq(TreeFall.impact_shake(0.4), 0.0)
	check_eq(TreeFall.impact_shake(2.0), 0.0)

func test_log_needs_two_hits_then_wood() -> void:
	var m := TreeFall.new()
	var c := Vector2i(3, 4)
	m.start(c, 1.0)
	check(m.is_falling(c))
	check(m.hit(c).is_empty())  # cannot chop while still falling
	m.land(c)
	check(m.has_log(c))
	check(m.hit(c).has("hit"))
	var r := m.hit(c)
	check_eq(r.id, "wood")
	check_eq(r.n, TreeFall.LOG_WOOD)
	check(not m.has_log(c))
	check(m.hit(c).is_empty())

func test_stump_bookkeeping_unaffected() -> void:
	var rn := ResourceNodes.new()
	var c := Vector2i(1, 1)
	rn.add("tree", c)
	var r := {}
	for i in 5:
		r = rn.hit(c, "axe", 1)
	check_eq(r.id, "wood")
	check(not rn.is_solid(c))
	check(rn.nodes.has(c))
