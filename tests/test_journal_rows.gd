extends BaseTest

func test_rows_hide_uncaught_names_and_sort_by_price() -> void:
	var table := {"carp": {"name": "Carp", "depth": "deep", "seasons": [0, 1, 2, 3], "price": 45}, "minnow": {"name": "Minnow", "depth": "shallow", "seasons": [0], "price": 12}}
	var rows := FishJournal.rows(table, {"carp": {"count": 2, "best": 40}})
	check_eq(rows[0]["id"], "minnow")
	check_eq(rows[0]["name"], "???")
	check_eq(rows[1]["name"], "Carp")
	check_eq(rows[1]["best"], 40)
	check_eq(rows[1]["seasons"], "all year")

func test_season_text() -> void:
	check_eq(FishJournal.season_text([0, 2]), "Spr/Aut")
