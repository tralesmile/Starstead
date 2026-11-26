extends BaseTest

const BOUNDS := Rect2(-8000, -8000, 16000, 16000)

func _round_trip(d: Dictionary) -> Dictionary:
	return JSON.parse_string(JSON.stringify(d))

func test_player_and_car_survive_json() -> void:
	var s := _round_trip(WorldState.pack(Vector2(1200, -340), 2, Vector2(90, 80), 1.25, 37.5, 62.0, {}))
	var p := WorldState.player_of(s, BOUNDS)
	check(p["pos"] == Vector2(1200, -340) and p["facing"] == 2, "player spot")
	var c := WorldState.car_of(s, BOUNDS)
	check(c["pos"] == Vector2(90, 80), "car spot")
	check(is_equal_approx(c["fuel"], 37.5) and is_equal_approx(c["health"], 62.0), "fuel and damage")
	check(is_equal_approx(c["heading"], 1.25), "heading")

func test_bad_data_is_dropped_or_clamped() -> void:
	check(WorldState.player_of({}, BOUNDS).is_empty(), "no save")
	check(WorldState.car_of({"car": "junk"}, BOUNDS).is_empty(), "junk car")
	check(WorldState.player_of({"player": {"x": 90000.0, "y": 0.0}}, BOUNDS).is_empty(), "a room far off the map is never restored")
	var c := WorldState.car_of({"car": {"x": 0, "y": 0, "fuel": -5, "health": 9999}}, BOUNDS)
	check(c["fuel"] == 0.0 and c["health"] == VehicleMath.HEALTH_MAX, "clamped")

func test_robbery_memory_survives_and_noise_resets() -> void:
	var m := RobberyModel.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 4
	m.house("city_house1")["locked"] = false
	m.finish_robbery("city_house1", rng)
	m.add_noise(40.0)
	var s := _round_trip(WorldState.pack(Vector2.ZERO, 0, Vector2.ZERO, 0.0, 1.0, 1.0, m.serialize()))
	var n := RobberyModel.new()
	n.deserialize(WorldState.robbery_of(s))
	var h := n.house("city_house1")
	check(h["grudge"] and h["robberies"] == 1 and h["locked"], "house remembers")
	check(n.noise == 0.0, "quiet after loading")
	check(WorldState.robbery_of({}).is_empty(), "none saved")
