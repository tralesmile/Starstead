extends BaseTest

func test_bend_zero_outside() -> void:
	check_eq(ReedMath.bend(Vector2(100, 0), Vector2(0, 0)), 0.0)

func test_bend_away_and_stronger_when_close() -> void:
	var near := ReedMath.bend(Vector2(4, 0), Vector2(0, 0))
	var far := ReedMath.bend(Vector2(16, 0), Vector2(0, 0))
	check(near > far and far > 0.0)
	check(ReedMath.bend(Vector2(-4, 0), Vector2(0, 0)) < 0.0)

func test_ease_converges() -> void:
	var v := 5.0
	for i in 60:
		v = ReedMath.ease_to(v, 0.0, 0.05)
	check_eq(v, 0.0)
