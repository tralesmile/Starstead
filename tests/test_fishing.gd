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

func test_bait_speeds_bite_and_widens_bar() -> void:
	var bait := {"bite_mult": 0.5, "bar_bonus": 0.1}
	var a := Fishing.new(11)
	var b := Fishing.new(11)
	a.cast(-1.0, _table(), 0)
	b.cast(-1.0, _table(), 0, bait)
	check(is_equal_approx(b.timer, a.timer * 0.5))
	check(is_equal_approx(b.bar_size, Fishing.BAR_SIZE + 0.1))
	check(is_equal_approx(a.bar_size, Fishing.BAR_SIZE))

func test_pick_bait_prefers_best_owned() -> void:
	var bait: Dictionary = DataDB.load_json("bait")
	var inv := Inventory.new()
	check_eq(Fishing.pick_bait(bait, inv), "")
	inv.add("worm_bait", 2)
	check_eq(Fishing.pick_bait(bait, inv), "worm_bait")
	inv.add("glow_bait", 1)
	check_eq(Fishing.pick_bait(bait, inv), "glow_bait")

func test_rod_upgrade_stacks_with_bait() -> void:
	var rods: Dictionary = DataDB.load_json("rods")
	var inv := Inventory.new()
	check_eq(Fishing.pick_rod(rods, inv), "")
	inv.add("rod_bamboo", 1)
	check_eq(Fishing.pick_rod(rods, inv), "rod_bamboo")
	inv.add("rod_carbon", 1)
	check_eq(Fishing.pick_rod(rods, inv), "rod_carbon")
	var c := Fishing.combine(rods["rod_carbon"], DataDB.load_json("bait")["glow_bait"])
	check(absf(c.bite_mult - 0.28) < 0.001)
	check(absf(c.bar_bonus - 0.18) < 0.001)
	check_eq(Fishing.combine({}, {}).bite_mult, 1.0)
