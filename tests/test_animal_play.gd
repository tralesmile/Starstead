extends BaseTest

func test_ride_mult() -> void:
	check_eq(AnimalModel.ride_mult(0.0), 1.0)
	check(AnimalModel.ride_mult(256.0) > 1.5)
	check(AnimalModel.ride_mult(9999.0) <= 2.5)
	check(AnimalModel.ride_mult(50.0) >= 1.0)

func test_flee_rules() -> void:
	check(AnimalModel.should_flee(50.0, 0.0))
	check(not AnimalModel.should_flee(200.0, 0.0))
	check(not AnimalModel.should_flee(10.0, 0.8))   # trusting animals stay
	check(not AnimalModel.should_flee(50.0, 0.9))
	var d := AnimalModel.flee_dir(Vector2(10, 0), Vector2(0, 0))
	check(d.x > 0.99)
	check_eq(AnimalModel.flee_dir(Vector2.ZERO, Vector2.ZERO), Vector2.DOWN)

func test_follow_step() -> void:
	check_eq(AnimalModel.follow_step(Vector2.ZERO, Vector2(20, 0), 50.0, 1.0), Vector2.ZERO)
	var s := AnimalModel.follow_step(Vector2.ZERO, Vector2(100, 0), 50.0, 0.5)
	check_eq(s, Vector2(25, 0))
	var s2 := AnimalModel.follow_step(Vector2.ZERO, Vector2(40, 0), 500.0, 1.0)
	check_eq(s2, Vector2(4, 0))  # never overshoots into the gap

func test_taming_flow_and_production() -> void:
	var m := AnimalModel.new(DataDB.load_json("animals"))
	var p := m.new_approach("chicken")
	var n := 0
	while not m.is_tamed(p) and n < 20:
		m.feed_wild(p, "turnip")
		n += 1
	check(m.is_tamed(p))
	var st := m.tame(p)
	var got := m.day_tick(st)
	check_eq(got.get("egg", 0), 1)
	check_eq(m.serialize([st]).length() > 0, true)
