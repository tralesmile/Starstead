extends BaseTest

func test_head_on_bounces_back() -> void:
	var r := VehicleMath.crash_response(Vector2(200, 0), Vector2(-1, 0), 0.0)
	check(absf((r["vel"] as Vector2).x - -60.0) < 0.01)
	check(absf(float(r["spin"]) - 0.0) < 0.001)

func test_scrape_keeps_speed() -> void:
	var r := VehicleMath.crash_response(Vector2(100, 100), Vector2(0, -1), 0.0)
	check(absf((r["vel"] as Vector2).x - 80.0) < 0.01)
	check((r["vel"] as Vector2).y < 0.0, "pushed off the wall")

func test_nose_turns_away() -> void:
	# heading east, wall face normal points up-left: nose rotates toward -y (negative angle)
	var r := VehicleMath.crash_response(Vector2(150, 0), Vector2(-0.7, -0.7), 0.0)
	check(float(r["spin"]) < 0.0)
	check(absf(float(r["spin"])) <= 0.5)

func test_moving_away_is_untouched() -> void:
	var r := VehicleMath.crash_response(Vector2(-50, 0), Vector2(-1, 0), PI)
	check(absf((r["vel"] as Vector2).x - -50.0) < 0.01)
	check(absf(float(r["spin"]) - 0.0) < 0.001)
