extends BaseTest

func test_levels() -> void:
	check_eq(SkillModel.level(0), 0)
	check_eq(SkillModel.level(99), 0)
	check_eq(SkillModel.level(100), 1)
	check_eq(SkillModel.level(99999), 10)

func test_xp_to_next() -> void:
	check_eq(SkillModel.xp_to_next(40), 60)
	check_eq(SkillModel.xp_to_next(99999), 0)

func test_bonus_chance_scales_and_caps() -> void:
	check_eq(SkillModel.bonus_chance(0), 0.0)
	check(is_equal_approx(SkillModel.bonus_chance(4), 0.2))
	check_eq(SkillModel.bonus_chance(99), 0.5)
	check_eq(SkillModel.roll_bonus(4, 0.1), 1)
	check_eq(SkillModel.roll_bonus(4, 0.9), 0)

func test_gain_reports_level_up() -> void:
	var xp := {"farming": 95}
	check(SkillModel.gain(xp, "farming"))
	check(not SkillModel.gain(xp, "farming"))
	check_eq(xp["farming"], 111)
