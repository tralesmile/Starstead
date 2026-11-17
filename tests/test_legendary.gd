extends BaseTest

const T := {
	"minnow": {"name": "Minnow", "depth": "shallow", "seasons": [0], "weight": 10, "difficulty": 0.1, "price": 5},
	"king": {"name": "King", "depth": "deep", "seasons": [0, 1, 2, 3], "weight": 0, "difficulty": 0.9, "price": 900, "legendary": true, "min_rain": 0.3, "hours": [17, 24], "chance": 0.5},
}

func test_needs_rain_hour_depth_and_roll() -> void:
	var ok := {"rain": 0.8, "hour": 20.0, "caught": []}
	check_eq(Fishing.legendary_for(T, "deep", ok, 0.1), "king")
	check_eq(Fishing.legendary_for(T, "deep", ok, 0.9), "")
	check_eq(Fishing.legendary_for(T, "shallow", ok, 0.1), "")
	check_eq(Fishing.legendary_for(T, "deep", {"rain": 0.0, "hour": 20.0, "caught": []}, 0.1), "")
	check_eq(Fishing.legendary_for(T, "deep", {"rain": 0.8, "hour": 10.0, "caught": []}, 0.1), "")

func test_only_once() -> void:
	check_eq(Fishing.legendary_for(T, "deep", {"rain": 0.8, "hour": 20.0, "caught": ["king"]}, 0.1), "")

func test_normal_pick_never_returns_legendary() -> void:
	for i in 20:
		check_eq(Fishing.pick_fish(T, "deep", 0, float(i) / 20.0), "")

func test_cast_uses_legendary_when_rolled() -> void:
	var f := Fishing.new(3)
	var t := T.duplicate(true)
	t["king"]["chance"] = 1.0
	t["carp"] = {"name": "Carp", "depth": "deep", "seasons": [0], "weight": 5, "difficulty": 0.4, "price": 40}
	check(f.cast(-5.0, t, 0, {}, {"rain": 1.0, "hour": 20.0, "caught": []}))
	check_eq(f.fish_id, "king")
