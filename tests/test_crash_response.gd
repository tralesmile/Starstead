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

func test_mud_drag() -> void:
	var grass := WorldGen.GRASS if "GRASS" in WorldGen else 0
	check_eq(VehicleMath.mud_drag(grass, 5.0, 0.0), 0.0)            # dry grass: clean
	check_eq(VehicleMath.mud_drag(grass, 5.0, 0.2), 0.0)            # drizzle: still clean
	check(VehicleMath.mud_drag(grass, 5.0, 1.0) > VehicleMath.mud_drag(grass, 5.0, 0.6))
	check_eq(VehicleMath.mud_drag(grass, 0.5, 1.0), 0.0)            # the bank stays out of it
	check_eq(VehicleMath.mud_drag(WorldGen.ASPHALT, 5.0, 1.0), 0.0) # roads shed water
	check_eq(VehicleMath.mud_splash(20.0, 1.0), 0)
	check(VehicleMath.mud_splash(200.0, VehicleMath.MUD_DRAG) > VehicleMath.mud_splash(60.0, VehicleMath.MUD_DRAG))
	check_eq(VehicleMath.mud_splash(200.0, 0.0), 0)
