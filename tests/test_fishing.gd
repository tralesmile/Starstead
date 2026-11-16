extends BaseTest

func _table() -> Dictionary:
	return DataDB.load_json("fish")

func test_depth_and_pick() -> void:
	check_eq(Fishing.depth_for(-1.0), "shallow")
	check_eq(Fishing.depth_for(-5.0), "deep")
	var t := _table()
	check_eq(Fishing.pick_fish(t, "shallow", 0, 0.0), "minnow")
	check_eq(Fishing.pick_fish(t, "shallow", 3, 0.99), "minnow", "perch not in winter")
	check_eq(Fishing.pick_fish(t, "deep", 1, 0.0), "carp")
	check(Fishing.pick_fish(t, "deep", 0, 1.0) != "", "roll 1.0 still picks")
	check_eq(Fishing.pick_fish({}, "deep", 0, 0.5), "")

func test_cast_rules() -> void:
	var f := Fishing.new(7)
	check(not f.cast(2.0, _table(), 0), "cannot cast on land")
	check(f.cast(-1.0, _table(), 0))
	check_eq(f.state, Fishing.State.WAITING)
	check(not f.cast(-1.0, _table(), 0), "already casting")

func test_bite_and_miss() -> void:
	var f := Fishing.new(3)
	f.cast(-1.0, _table(), 0)
	f.tick(Fishing.BITE_MAX + 0.1, false)
	check_eq(f.state, Fishing.State.BITE)
	f.tick(Fishing.BITE_WINDOW + 0.1, false)
	check_eq(f.state, Fishing.State.LOST, "missed the window")

func test_early_pull_resets() -> void:
	var f := Fishing.new(3)
	f.cast(-1.0, _table(), 0)
	check(not f.hook())
	check_eq(f.state, Fishing.State.IDLE)

func test_reel_win_and_lose() -> void:
	var f := Fishing.new(5)
	f.cast(-1.0, _table(), 0)
	f.tick(10.0, false)
	check(f.hook())
	check_eq(f.state, Fishing.State.REELING)
	f.fish_pos = f.bar
	f.fish_target = f.bar
	f.progress = 0.99
	f._reel(0.1, false)  # overlapping -> gains
	check_eq(f.state, Fishing.State.CAUGHT)
	var g := Fishing.new(5)
	g.cast(-1.0, _table(), 0)
	g.tick(10.0, false)
	g.hook()
	g.fish_pos = 0.95
	g.fish_target = 0.95
	g.bar = 0.14
	g.progress = 0.01
	g._reel(0.1, false)
	check_eq(g.state, Fishing.State.LOST)

func test_bar_clamped() -> void:
	var f := Fishing.new(2)
	f.cast(-1.0, _table(), 0)
	f.tick(10.0, false)
	f.hook()
	for i in 600:
		f.tick(0.016, true)
		check(f.bar >= Fishing.BAR_SIZE / 2.0 - 0.001 and f.bar <= 1.0 - Fishing.BAR_SIZE / 2.0 + 0.001)
		if f.state != Fishing.State.REELING:
			break
