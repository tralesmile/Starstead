extends BaseTest

func test_spring_is_neutral_autumn_is_orange() -> void:
	check_eq(SeasonMath.ground_mul(0), Color(1, 1, 1))
	var a := SeasonMath.ground_mul(2)
	check(a.r > a.g and a.g > a.b)
	check(SeasonMath.tree_tint(2, "oak").r > 1.2)

func test_winter_frost_only_in_winter() -> void:
	check_eq(SeasonMath.ground_frost(0), 0.0)
	check(SeasonMath.ground_frost(3) > 0.4)
	check(not SeasonMath.flowers_visible(3))
	check(SeasonMath.flowers_visible(1))

func test_kind_of_paths() -> void:
	check_eq(SeasonMath.kind_of("res://assets/sprites/tree_pine.png"), "pine")
	check_eq(SeasonMath.kind_of("res://assets/sprites/bush.png"), "bush")
	check_eq(SeasonMath.kind_of("res://assets/sprites/x.png"), "")

func test_season_wraps() -> void:
	check_eq(SeasonMath.ground_mul(4), SeasonMath.ground_mul(0))
