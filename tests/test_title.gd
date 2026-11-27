extends BaseTest

func test_title_only_on_real_launches() -> void:
	check(TitleModel.shows(PackedStringArray()))
	check(TitleModel.shows(PackedStringArray(["--continue"])))
	check(not TitleModel.shows(PackedStringArray(["--farm-demo"])))
	check(not TitleModel.shows(PackedStringArray(["--fresh"])))

func test_rows_depend_on_save() -> void:
	check_eq(TitleModel.rows(true)[0], "continue")
	check("new" in TitleModel.rows(true))
	check_eq(TitleModel.rows(false)[0], "start")
	check(not ("new" in TitleModel.rows(false)))

func test_rows_fit_and_hit_test() -> void:
	for has in [true, false]:
		var n := TitleModel.rows(has).size()
		var p := TitleModel.panel_rect(n)
		check(p.position.y > 108.0 and p.end.y < 354.0)
		for i in n:
			check(p.encloses(TitleModel.row_rect(i, n)))
			check_eq(TitleModel.row_at(TitleModel.row_rect(i, n).get_center(), n), i)

func test_logo_has_every_letter_and_fits() -> void:
	for ch in "STARSTEAD":
		check(TitleModel.GLYPHS.has(ch))
	check(TitleModel.logo_width("STARSTEAD") < 520.0)
	check(TitleModel.logo_cells("STARSTEAD").size() > 100)
	for i in 20:
		check(absf(TitleModel.bob(i, i * 0.7)) <= 2.0)
		var k := TitleModel.twinkle(i, i * 1.3)
		check(k >= 0.0 and k <= 1.0)

func test_new_farm_needs_two_presses() -> void:
	var v := WelcomeView.new()
	v.open("Day 3, Spring  -  $500")
	var wiped := [0]
	v.new_game.connect(func(): wiped[0] += 1)
	v.activate(1)
	check_eq(wiped[0], 0)
	check(v.armed)
	v._move(1)
	v._move(-1)
	check(not v.armed, "moving away disarms")
	v.activate(1)
	v.activate(1)
	check_eq(wiped[0], 1)
	v.free()

func test_continue_closes() -> void:
	var v := WelcomeView.new()
	v.open("")
	var went := [0]
	v.continued.connect(func(): went[0] += 1)
	v.activate(0)
	check_eq(went[0], 1)
	check(not v.active)
	v.free()
