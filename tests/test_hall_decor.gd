extends BaseTest
## Warden's Hall decor layout (pure rules) and the boss bar's place on screen.

const DAYS := 30

func _hall(day: int) -> CaveModel:
	return CaveModel.generate(day, CaveModel.BOSS_FLOOR)

func test_only_the_boss_floor_is_dressed() -> void:
	check(HallDecor.layout(CaveModel.generate(1, 2)).is_empty(), "ordinary floors stay bare")
	check(not HallDecor.layout(_hall(1)).is_empty())

func test_same_day_same_hall() -> void:
	check_eq(str(HallDecor.layout(_hall(3))), str(HallDecor.layout(_hall(3))))

func test_every_kind_is_present() -> void:
	for day in range(1, DAYS + 1):
		var n := {"pillar": 0, "brazier": 0, "wall": 0, "litter": 0}
		for it in HallDecor.layout(_hall(day)):
			n[it["kind"]] += 1
		check(n["pillar"] >= 6, "day %d pillars %d" % [day, n["pillar"]])
		check(n["brazier"] >= 4, "day %d braziers %d" % [day, n["brazier"]])
		check(n["wall"] >= 4, "day %d wall decor %d" % [day, n["wall"]])
		check(n["litter"] >= 30, "day %d litter %d" % [day, n["litter"]])

func test_props_on_floor_and_wall_decor_on_walls() -> void:
	for day in range(1, DAYS + 1):
		var m := _hall(day)
		var used := {}
		for it in HallDecor.layout(m):
			var c: Vector2i = it["cell"]
			if it["kind"] == "wall":
				check(not m.is_floor(c) and m.is_floor(c + Vector2i(0, 1)), "wall decor on a rock face %s" % str(c))
				check(not m.torches.has(c), "wall decor off the torches %s" % str(c))
			else:
				check(m.is_floor(c) and not m.ores.has(c), "%s on free floor %s" % [it["kind"], str(c)])
				check(not used.has(c), "one floor item per cell %s" % str(c))
				used[c] = true

func test_door_spawns_and_exit_stay_clear() -> void:
	for day in range(1, DAYS + 1):
		var m := _hall(day)
		for it in HallDecor.layout(m):
			var c: Vector2i = it["cell"]
			check(c != m.entrance and c != m.entrance + Vector2i(0, 1) and c != m.boss_spawn(), "clear of door and spawns %s" % str(c))
			check(c.y < m.entrance.y - 1, "clear of the way out %s" % str(c))
			if it["solid"]:
				check(Vector2(c - m.entrance).length() >= 6.0, "solid far from the entrance %s" % str(c))
				check(Vector2(c - m.boss_spawn()).length() >= 3.0, "solid not on the Warden %s" % str(c))

func test_solid_props_hug_walls_and_trap_nobody() -> void:
	for day in range(1, DAYS + 1):
		var m := _hall(day)
		var blocked := {}
		for it in HallDecor.layout(m):
			if not it["solid"]:
				continue
			var c: Vector2i = it["cell"]
			var beside := false
			for o in HallDecor.SIDES:
				beside = beside or not m.is_floor(c + o)
			check(beside, "solid against a wall %s" % str(c))
			check(not HallDecor.on_dais(c), "the fighting circle stays open %s" % str(c))
			blocked[c] = true
		check(HallDecor.reachable(m, blocked), "day %d: all floor and ore still reachable" % day)

func test_reachable_spots_a_blocked_corridor() -> void:
	var m := _hall(1)
	var wall := {}
	for dx in range(-2, 3):
		wall[m.entrance + Vector2i(dx, -4)] = true
	check(not HallDecor.reachable(m, wall))

func test_dais_lies_on_the_floor() -> void:
	var m := _hall(1)
	for i in 64:
		var p := HallDecor.dais_center() + Vector2.from_angle(TAU * i / 64.0) * HallDecor.DAIS_RADIUS
		check(m.is_floor(Vector2i((p / 32.0).floor())), "dais edge on floor %s" % str(p))

func test_flat_decor_stays_under_the_warning_rings() -> void:
	# BossView draws its rings and rock shadows at z -10
	for z in [HallDecor.DAIS_Z, HallDecor.LITTER_Z, HallDecor.WALL_Z]:
		check(z < -10 and z > -18, "z %d between the rock and the rings" % z)

func test_runes_flare_when_enraged() -> void:
	for i in 40:
		var time := i * 0.17
		var asleep := HallDecor.glow_level("sleep", false, time)
		var calm := HallDecor.glow_level("walk", false, time)
		var rage := HallDecor.glow_level("walk", true, time)
		check(asleep < calm and calm < rage, "sleep < fight < rage")
		check(rage <= 1.0)
		check(HallDecor.glow_level("dead", true, time) < calm, "dim once the Warden falls")

func test_boss_bar_clears_prompt_hotbar_and_key_legend() -> void:
	var view := Vector2(640, 360)
	var r := BossBarLayout.panel(view)
	check(r.end.y <= 272.0, "above the prompt line at y 276")
	check(r.position.y > view.y * 0.6, "low on the screen")
	check(r.end.x < 555.0 and r.position.x >= 0.0, "left of the key legend")
	check(is_equal_approx(r.get_center().x, 320.0), "centred")

func test_boss_bar_fades_only_when_the_warden_is_under_it() -> void:
	var r := BossBarLayout.panel(Vector2(640, 360))
	check_eq(BossBarLayout.alpha_for(r, Rect2(260, 40, 120, 140)), 1.0, "north of the player")
	check_eq(BossBarLayout.alpha_for(r, Rect2(260, 180, 120, 140)), BossBarLayout.COVERED_ALPHA, "south, under the bar")
	check_eq(BossBarLayout.alpha_for(r, Rect2(0, 220, 100, 140)), 1.0, "off to the side")
