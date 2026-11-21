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

func test_beginner_assist_widens_bar() -> void:
	var f := Fishing.new(5)
	f.cast(-1.0, _table(), 0, {}, {"caught_count": 0})
	check_eq(f.bar_size, Fishing.BAR_SIZE + Fishing.BEGINNER_BONUS, "wider bar for beginners")
	var g := Fishing.new(5)
	g.cast(-1.0, _table(), 0, {}, {"caught_count": 12})
	check_eq(g.bar_size, Fishing.BAR_SIZE, "normal bar later")

func test_bite_time_of_day() -> void:
	check(Fishing.bite_time_mult(6.0, 0.0) < Fishing.bite_time_mult(12.5, 0.0), "dawn beats midday")
	check(Fishing.bite_time_mult(18.0, 0.0) < 1.0)
	check_eq(Fishing.bite_time_mult(22.0, 0.0), 1.0, "night is neutral")
	check(Fishing.bite_time_mult(22.0, 1.0) < 1.0, "rain stirs fish")
	var f := Fishing.new()
	var table: Dictionary = DataDB.load_json("fish")
	f.rng.seed = 5
	check(f.cast(-5.0, table, 0, {}, {"hour": 6.0}))
	var dawn := f.timer
	f.reset()
	f.rng.seed = 5
	check(f.cast(-5.0, table, 0, {}, {"hour": 12.5}))
	check(dawn < f.timer, "same roll, quicker at dawn")

func test_hot_spots_bite_sooner() -> void:
	var table: Dictionary = DataDB.load_json("fish")
	var hot := Vector2i(-1, -1)
	var cold := Vector2i(-1, -1)
	for x in range(0, 200, FishSpots.BLOCK):
		if FishSpots.is_hot(Vector2i(x, 0), 3):
			hot = Vector2i(x, 0)
		else:
			cold = Vector2i(x, 0)
	check(hot.x >= 0 and cold.x >= 0, "some blocks are hot and some are not")
	var f := Fishing.new()
	f.rng.seed = 9
	f.cast(-5.0, table, 0, {}, {"hour": 22.0, "hot": false})
	var t0 := f.timer
	f.reset()
	f.rng.seed = 9
	f.cast(-5.0, table, 0, {}, {"hour": 22.0, "hot": true})
	check(f.timer < t0 * 0.6, "hot water bites in about half the time")

func test_hot_blocks_deterministic_and_about_one_in_seven() -> void:
	var n := 0
	for bx in 70:
		for by in 70:
			if FishSpots.is_hot(Vector2i(bx * 5, by * 5), 12):
				n += 1
	check(n > 4900 / 7 * 0.7 and n < 4900 / 7 * 1.3, "about 1/7 hot (%d)" % n)
	check_eq(FishSpots.is_hot(Vector2i(13, 4), 5), FishSpots.is_hot(Vector2i(14, 3), 5), "same block, same answer")
	check(FishSpots.hot_blocks_near(Vector2i(100, 100), 4).size() <= 16)
