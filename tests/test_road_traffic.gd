extends BaseTest

func _line() -> PackedVector2Array:
	return PackedVector2Array([Vector2(0, 0), Vector2(100, 0), Vector2(100, 100)])

func test_length_and_sample_follow_corners() -> void:
	var l := _line()
	check_eq(RoadTraffic.length(l), 200.0)
	var a := RoadTraffic.sample(l, 150.0)
	check((a["pos"] as Vector2).is_equal_approx(Vector2(100, 50)))
	check((a["dir"] as Vector2).is_equal_approx(Vector2(0, 1)))
	check(not bool(a["done"]))
	check(bool(RoadTraffic.sample(l, 230.0)["done"]))
	check(bool(RoadTraffic.sample(l, -5.0)["done"]))

func test_cars_keep_right_in_both_directions() -> void:
	var l := _line()
	var east := RoadTraffic.lane_point(l, 50.0, true)
	check((east["pos"] as Vector2).y > 0.0, "heading east keeps to the south side (screen right)")
	var west := RoadTraffic.lane_point(l, 50.0, false)
	check((west["pos"] as Vector2).y < 0.0, "heading west keeps to the north side")
	check(absf(float(west["heading"])) > 3.0, "west heading is about pi")

func test_gap_ahead_ignores_behind_and_aside() -> void:
	var g := RoadTraffic.gap_ahead(Vector2.ZERO, 0.0, [Vector2(100, 5), Vector2(-50, 0), Vector2(60, 90), Vector2(70, -3)])
	check_eq(g, 70.0)
	check(is_inf(RoadTraffic.gap_ahead(Vector2.ZERO, 0.0, [Vector2(-10, 0)])))

func test_follow_speed_ramps_and_stops() -> void:
	check_eq(RoadTraffic.follow_speed(100.0, 400.0), 100.0)
	check_eq(RoadTraffic.follow_speed(100.0, 30.0), 0.0)
	var mid := RoadTraffic.follow_speed(100.0, 100.0)
	check(mid > 0.0 and mid < 100.0)
	check(RoadTraffic.follow_speed(100.0, 120.0) > mid, "monotonic")

func test_brakes_harder_than_it_accelerates() -> void:
	var slow := RoadTraffic.ease_speed(100.0, 0.0, 0.1)
	var fast := RoadTraffic.ease_speed(0.0, 100.0, 0.1)
	check(100.0 - slow > fast)

func test_honk_after_wait() -> void:
	check(not RoadTraffic.honks(1.0))
	check(RoadTraffic.honks(2.5))

func test_density_by_hour() -> void:
	check(RoadTraffic.car_target(3.0) < RoadTraffic.car_target(12.0))
	check_eq(RoadTraffic.car_target(8.0), RoadTraffic.MAX_CARS)
	check_eq(RoadTraffic.hiker_target(23.0), 0)
	check(RoadTraffic.hiker_target(12.0) > 0)

func test_spine_polyline_and_px_centre() -> void:
	var p := RoadTraffic.spine_polyline(0, 24, func(_x): return 32)
	check_eq(p.size(), 4)
	var px := RoadTraffic.to_px([Vector2i(2, 3)])
	check_eq(px[0], Vector2(96, 128))

func test_despawn_rules() -> void:
	check(RoadTraffic.should_despawn(1000.0, 100.0, 500.0))
	check(RoadTraffic.should_despawn(300.0, 600.0, 500.0))
	check(not RoadTraffic.should_despawn(300.0, 100.0, 500.0))

func test_speeds_in_range() -> void:
	for s in 40:
		var c := RoadTraffic.cruise_speed(s)
		check(c >= 78.0 and c <= 134.0)

func test_hit_response_scales_and_points_away() -> void:
	var soft := RoadTraffic.hit_response(30.0, Vector2(1, 0))
	var hard := RoadTraffic.hit_response(300.0, Vector2(0, 5))
	check_eq(float(soft["stall"]), 0.6)
	check_eq(float(hard["stall"]), 4.0)
	check((hard["shove"] as Vector2).is_equal_approx(Vector2(0, 28)))
	check((soft["shove"] as Vector2).x > 0.0)
	check_eq(RoadTraffic.hit_response(100.0, Vector2.ZERO)["shove"], Vector2.ZERO)

func test_shove_eases_out() -> void:
	var s := Vector2(20, 0)
	for i in 30:
		s = RoadTraffic.shove_decay(s, 0.1)
	check(s.length() < 1.0)

func test_weather_slows_drivers() -> void:
	check_eq(RoadTraffic.weather_cruise(100.0, 0.0, 0.0), 100.0)
	check(RoadTraffic.weather_cruise(100.0, 1.0, 0.0) < 80.0)
	check(RoadTraffic.weather_cruise(100.0, 1.0, 1.0) >= 55.0)
	check(RoadTraffic.weather_brake(1.0) > RoadTraffic.weather_brake(0.3))
	check_eq(RoadTraffic.weather_brake(0.0), 1.0)
