extends BaseTest

func test_wakes_near_and_stays_awake() -> void:
	check(not DogMath.awake(Vector2.ZERO, Vector2(400, 0), false))
	check(DogMath.awake(Vector2.ZERO, Vector2(100, 0), false))
	check(DogMath.awake(Vector2.ZERO, Vector2(900, 0), true), "once up it keeps barking")

func test_chases_but_keeps_distance() -> void:
	var p := Vector2(100, 0)
	var d := DogMath.step(Vector2.ZERO, p, 0.5)
	check(is_equal_approx(d.x, DogMath.SPEED * 0.5))
	for i in 20:
		d = DogMath.step(d, p, 0.5)
	check(is_equal_approx(d.distance_to(p), DogMath.STOP), "stops at growling distance")

func test_bark_rhythm() -> void:
	var t := DogMath.BARK_EVERY
	var barks := 0
	for i in 50:   # 5 seconds
		var r := DogMath.bark(t, 0.1)
		t = r["timer"]
		if r["bark"]:
			barks += 1
	check(barks >= 4 and barks <= 5, "about one bark a second: %d" % barks)

func test_barking_wakes_residents_fast() -> void:
	var m := RobberyModel.new()
	for i in int(ceil(60.0 / DogMath.BARK_NOISE)) + 1:
		m.add_noise(DogMath.BARK_NOISE)
	check(m.residents_awake(), "about 9 barks wake the house")
