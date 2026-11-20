extends BaseTest

func test_crates_inside_yard() -> void:
	var cs := YardHeist.crate_cells()
	check_eq(cs.size(), 2)
	for c in cs:
		check(VanceYard.in_rect(c) and not VanceYard.is_fence(c))

func test_cooldown() -> void:
	var l := {0: 10}
	check(not YardHeist.ready(l, 0, 12))
	check_eq(YardHeist.days_left(l, 0, 12), 5)
	check(YardHeist.ready(l, 0, 17))
	check(YardHeist.ready(l, 1, 11), "other crate untouched")
	check_eq(YardHeist.days_left(l, 1, 11), 0)

func test_loot_deterministic_and_valid() -> void:
	for idx in 2:
		for day in range(1, 60):
			var a := YardHeist.loot(idx, day)
			check_eq(a, YardHeist.loot(idx, day))
			check(int(a["cash"]) > 0)
			if String(a["item"]) != "":
				check(String(a["item"]) in ["iron_bar", "copper_bar"] and int(a["n"]) > 0)

func test_nearest() -> void:
	var cs := YardHeist.crate_cells()
	check_eq(YardHeist.nearest(Vector2(cs[1]) * 32.0 + Vector2(16, 40)), 1)
	check_eq(YardHeist.nearest(Vector2(0, 0)), -1)
