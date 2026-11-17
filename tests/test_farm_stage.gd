extends BaseTest

func test_stage_progress() -> void:
	check_eq(FarmModel.stage(0, 4), 0)
	check_eq(FarmModel.stage(1, 4), 1)
	check_eq(FarmModel.stage(2, 4), 2)
	check_eq(FarmModel.stage(3, 4), 3)
	check_eq(FarmModel.stage(4, 4), 4)   # ripe only at full age
	check_eq(FarmModel.stage(9, 4), 4)
	check_eq(FarmModel.stage(0, 0), 4)

func test_stage_never_ripe_early() -> void:
	for total in [2, 3, 5, 8]:
		for age in total:
			check(FarmModel.stage(age, total) <= 3, "t%d a%d" % [total, age])
