extends BaseTest

const HOMES := ["city_house1", "city_house2", "city_house3", "city_apt_a", "city_apt_b"]

func test_quiet_never_calls() -> void:
	check(Neighbours.rate(10.0, 4) < 0.0)
	check(Neighbours.rate(80.0, 0) < 0.0)   # nobody awake to hear

func test_louder_is_faster() -> void:
	check(Neighbours.rate(90.0, 2) > Neighbours.rate(40.0, 2))
	check(Neighbours.rate(60.0, 4) > Neighbours.rate(60.0, 1))
	check_eq(Neighbours.rate(60.0, 9), Neighbours.rate(60.0, 4))   # capped

func test_meter_calls() -> void:
	var m := 0.0
	for i in 400:
		m = Neighbours.step(m, 100.0, 3, 0.1)
	check(Neighbours.calls(m))
	var c := 1.0
	for i in 100:
		c = Neighbours.step(c, 0.0, 3, 0.1)
	check(c < 1.0)
	check(c >= 0.0)

func test_seconds_to_call() -> void:
	check(Neighbours.seconds_to_call(100.0, 1) < 12.0)
	check(Neighbours.seconds_to_call(5.0, 3) == INF)

func test_awake_neighbours_excludes_own_house() -> void:
	var all := Neighbours.awake_neighbours("none", 19.0, HOMES)
	var own := Household.awake_home("city_house1", 19.0).size()
	check_eq(Neighbours.awake_neighbours("city_house1", 19.0, HOMES), all - own)
	check_eq(Neighbours.awake_neighbours("city_house1", 3.0, HOMES), Neighbours.awake_neighbours("city_house1", 3.0, HOMES))

func test_goal_arrow_kind() -> void:
	check_eq(GoalArrow.kind(0, 0, 1, false), "")
	check_eq(GoalArrow.kind(3, 0, 1, false), "")
	check_eq(GoalArrow.kind(3, 2, 1, false), "tree")
	check_eq(GoalArrow.kind(3, 2, 1, true), "bed")
	check_eq(GoalArrow.kind(3, 2, 2, true), "")

func test_goal_arrow_edge_and_fade() -> void:
	var r := GoalArrow.edge_pos(Vector2.ZERO, Vector2(1000, 0), Vector2(320, 180))
	check_eq(r["pos"].x, 320.0 - GoalArrow.MARGIN)
	check_eq(r["angle"], 0.0)
	var near := GoalArrow.edge_pos(Vector2.ZERO, Vector2(50, 20), Vector2(320, 180))
	check_eq(near["pos"], Vector2(50, 20))
	var diag := GoalArrow.edge_pos(Vector2.ZERO, Vector2(900, 900), Vector2(320, 180))
	check(absf(diag["pos"].y) <= 180.0 - GoalArrow.MARGIN + 0.01)
	check_eq(GoalArrow.alpha(50.0), 0.0)
	check_eq(GoalArrow.alpha(500.0), 1.0)
	check(GoalArrow.alpha(160.0) > 0.0 and GoalArrow.alpha(160.0) < 1.0)
	check_eq(GoalArrow.nearest(Vector2.ZERO, [Vector2(50, 0), Vector2(10, 0)]), Vector2(10, 0))
