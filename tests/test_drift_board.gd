extends BaseTest

func test_ranking_and_cap() -> void:
	var b: Array = []
	for p in [100, 300, 200]:
		b = DriftBoard.submit(b, p)["board"]
	check_eq(b, [300, 200, 100])
	var r := DriftBoard.submit(b, 250)
	check_eq(r["rank"], 2)
	check_eq(r["board"], [300, 250, 200, 100])
	for p in [50, 400, 60]:
		r = DriftBoard.submit(r["board"], p)
	check_eq(r["board"].size(), DriftBoard.SIZE)
	check_eq(r["board"][0], 400)
	check_eq(DriftBoard.submit([9, 8, 7, 6, 5], 4)["rank"], 0, "below a full board")
	check_eq(DriftBoard.submit([], 0)["rank"], 0, "zero never counts")

func test_ties_go_below() -> void:
	check_eq(DriftBoard.submit([100], 100)["rank"], 2)

func test_lines_and_clean() -> void:
	check(DriftBoard.lines([]).begins_with("No drifts"))
	check(DriftBoard.lines([200, 100]).contains("1. 200"))
	check_eq(DriftBoard.clean([5, "9", 7, 1, 2, 3, 4]), [9, 7, 5, 4, 3])
