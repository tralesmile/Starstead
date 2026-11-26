extends BaseTest

func test_rows_add_leave_only_indoors() -> void:
	check(not ("leave" in PauseModel.rows("")))
	var r := PauseModel.rows("mine")
	check("leave" in r)
	check_eq(r[0], "resume")
	check_eq(r[r.size() - 1], "quit")

func test_selection_wraps() -> void:
	check_eq(PauseModel.move(0, -1, 6), 5)
	check_eq(PauseModel.move(5, 1, 6), 0)

func test_volume_steps_and_gain() -> void:
	check_eq(PauseModel.step_volume(10, 1), 10)
	check_eq(PauseModel.step_volume(0, -1), 0)
	check(PauseModel.volume_db(0) <= -60.0)
	check(absf(PauseModel.volume_db(10)) < 0.001)
	check(PauseModel.volume_db(5) < PauseModel.volume_db(8))

func test_menu_fits_the_screen_and_rows_hit() -> void:
	var n := PauseModel.rows("building").size()
	check(Rect2(Vector2.ZERO, PauseModel.SCREEN).encloses(PauseModel.panel_rect(n).grow(6)))
	for i in n:
		check_eq(PauseModel.row_at(PauseModel.row_rect(i, n).get_center(), n), i)
	check_eq(PauseModel.row_at(Vector2(2, 2), n), -1)

func test_quit_only_saves_a_real_session() -> void:
	check(PauseModel.quit_saves(PackedStringArray()))
	check(PauseModel.quit_saves(PackedStringArray(["--continue"])))
	check(not (PauseModel.quit_saves(PackedStringArray(["--fresh"]))))
	check(not (PauseModel.quit_saves(PackedStringArray(["--farm-demo"]))))

func test_settings_survive_bad_files() -> void:
	check_eq(PauseModel.clean_volume(null), 10)
	check_eq(PauseModel.clean_volume({"volume": "loud"}), 10)
	check_eq(PauseModel.clean_volume({"volume": 99.0}), 10)
	PauseModel.store_volume(4, "user://test_settings.json")
	check_eq(PauseModel.load_volume("user://test_settings.json"), 4)
	DirAccess.remove_absolute("user://test_settings.json")

func test_wanted_heat_survives_the_save() -> void:
	var s := WorldState.pack(Vector2(10, 10), 0, Vector2(20, 20), 0.0, 5.0, 50.0, {}, 63.0)
	check_eq(WorldState.heat_of(s), 63.0)
	check_eq(WorldState.heat_of({}), 0.0)
	check_eq(WorldState.heat_of({"heat": 99999}), WantedMath.MAX_HEAT)

func test_fireflies_hide_from_rain() -> void:
	check_eq(AmbientMath.firefly_amount(1.0, 0.0), 1.0)
	check(AmbientMath.firefly_amount(1.0, 0.2) < 1.0)
	check_eq(AmbientMath.firefly_amount(1.0, 0.8), 0.0)
