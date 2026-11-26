extends BaseTest

func test_plain_launch_continues_the_save() -> void:
	check(SaveBoot.should_load(PackedStringArray(), true))
	check(not SaveBoot.should_load(PackedStringArray(), false))

func test_demo_flags_stay_clean_unless_asked() -> void:
	check(not SaveBoot.should_load(PackedStringArray(["--farm-demo"]), true))
	check(SaveBoot.should_load(PackedStringArray(["--continue"]), true))
	check(not SaveBoot.should_load(PackedStringArray(["--continue", "--fresh"]), true))

func test_summary_names_the_season() -> void:
	check(SaveBoot.summary(30, 1, 750) == "Day 30, Summer  -  $750")

func test_diff_keys_ignores_cell_order_but_sees_changes() -> void:
	var a := {"money": 5, "farm": [{"x": 1, "y": 2}, {"x": 3, "y": 4}]}
	var b := {"money": 5.0, "farm": [{"x": 3, "y": 4}, {"x": 1, "y": 2}]}
	check(SaveBoot.diff_keys(a, b).is_empty(), str(SaveBoot.diff_keys(a, b)))
	b["money"] = 6
	check(SaveBoot.diff_keys(a, b) == ["money"])
