extends BaseTest

const DT := 1.0 / 30.0
const SAFE_PEAK := 0.2   # below suspicion: the bot never even makes the guard look

func test_entry_needs_night_break_in_and_cooldown() -> void:
	check(BankJob.entry_block(true, true, 22.0, -1, 3) != "", "open bank")
	check(BankJob.entry_block(false, false, 22.0, -1, 3) != "", "no break-in")
	check(BankJob.entry_block(false, true, 18.0, -1, 3) != "", "evening is too early")
	check_eq(BankJob.entry_block(false, true, 22.0, -1, 3), "")
	check_eq(BankJob.entry_block(false, true, 1.0, -1, 3), "")
	check(BankJob.entry_block(false, true, 22.0, 10, 12) != "", "cooldown")
	check_eq(BankJob.days_left(10, 12), 5)
	check_eq(BankJob.entry_block(false, true, 22.0, 10, 17), "")

func test_standing_in_view_gets_you_caught() -> void:
	var j := BankJob.new()
	j.g_wp = 4   # west post, looking west over open floor
	j.g_pos = BankJob.ROUTE[4]["pos"]
	j.g_face = PI
	j.g_timer = 30.0
	j.pos = j.g_pos + Vector2(-60, 0)
	check(j.guard_sees(j.pos), "in his cone")
	for i in 90:
		j.step(DT, Vector2.ZERO, false, false, false)
	check_eq(j.result, "caught")
	check_eq(j.banked(), 0)

func test_walls_and_cover_block_sight() -> void:
	var j := BankJob.new()
	check(not j.in_cone(Vector2(344, 80), PI, 200.0, 1.0, Vector2(230, 80)), "cabinet hides you")
	check(j.in_cone(Vector2(344, 48), PI, 200.0, 1.0, Vector2(230, 48)), "open floor")
	check(not j.in_cone(Vector2(344, 48), 0.0, 200.0, 1.0, Vector2(470, 48)), "vault wall")

func test_camera_sees_until_fuse_pulled() -> void:
	var j := BankJob.new()
	var p: Vector2 = BankJob.CAMS[0]["pos"] + Vector2.from_angle(BankJob.cam_angle(0, 0.0)) * 40.0
	check(j.cam_sees(0, p))
	j.cams_on = false
	check(not j.cam_sees(0, p))

func test_sprint_is_heard_sneak_is_not() -> void:
	for sprinting in [true, false]:
		var j := BankJob.new()
		j.g_face = 0.0   # looking away
		j.g_pos = Vector2(208, 160)
		j.pos = Vector2(110, 220)
		j.cams_on = false
		j.step(DT, Vector2(1, 0), not sprinting, sprinting, false)
		check_eq(j.g_state == BankJob.Guard.SUSPICIOUS, sprinting, "sprint=%s" % sprinting)

func test_guard_investigates_last_seen_spot_then_returns() -> void:
	var j := BankJob.new()
	j.g_wp = 4   # west post, looking west over open floor
	j.g_pos = BankJob.ROUTE[4]["pos"]
	j.g_face = PI
	j.g_timer = 30.0
	var spot := j.g_pos + Vector2(-60, 0)
	j.pos = spot
	for i in 12:
		j.step(DT, Vector2.ZERO, false, false, false)
	check(j.g_state == BankJob.Guard.SUSPICIOUS, "suspicious first")
	j.pos = Vector2(40, 260)   # slipped away
	j.g_timer = BankJob.SUSPECT_TIME
	var searched := false
	var closest := 999.0
	for i in 600:
		j.step(DT, Vector2.ZERO, false, false, false)
		j.meter = 0.0
		closest = minf(closest, j.g_pos.distance_to(spot))
		if j.g_state == BankJob.Guard.SEARCH:
			searched = true
		if searched and j.g_state == BankJob.Guard.PAUSE:
			break
	check(searched, "searched")
	check(closest < 20.0, "walked to the spot, got %f" % closest)
	check(searched and j.g_state == BankJob.Guard.PAUSE, "back on the route")

func test_patrol_route_never_walks_through_walls() -> void:
	var j := BankJob.new()
	j.pos = Vector2(-500, -500)
	for i in 30 * 60:
		j._guard_step(DT)
		for r in j.blockers():
			check(not r.grow(-1).has_point(j.g_pos), "guard inside %s at %s" % [r, j.g_pos])

func test_vault_door_needs_the_card() -> void:
	var j := BankJob.new()
	j.pos = Vector2(11.6 * 32.0, 4.5 * 32.0)
	check_eq(String(j.use_target()["id"]), "locked")
	check(not j._free(Vector2(12.5 * 32.0, 4.5 * 32.0)))
	j.has_card = true
	check_eq(String(j.use_target()["id"]), "door")

func test_abandon_banks_nothing() -> void:
	var j := BankJob.new()
	j.taken = [0, 1]
	j.abandon()
	check_eq(j.banked(), 0)

func test_fine_never_exceeds_money() -> void:
	check_eq(BankJob.fine_for(10000), BankJob.CAUGHT_FINE)
	check_eq(BankJob.fine_for(40), 40)
	check_eq(BankJob.fine_for(-5), 0)

func test_reward_balance() -> void:
	var all: Array = range(BankJob.BAGS.size())
	var take := BankJob.total_cash(all)
	var till: Array = ShopHours.cfg()["city_bank"]["till"]
	check(take > HangarHeist.total_cash(range(HangarHeist.CASES.size())), "the vault beats the hangar's cash")
	check(take >= 2 * int(till[1]), "far better than the lobby till")
	check(take <= 3 * int(till[1]), "but not absurd")
	var jobs = DataDB.load_json("jobs")
	var best := 0.0
	for id in jobs:
		best = maxf(best, float(jobs[id].pay) * float(jobs[id].ranks.back().pay_mult))
	check(float(take) / BankJob.COOLDOWN_DAYS < best * 2.0, "per day it does not drown honest work")
	check(BankJob.CAUGHT_FINE < take / 3)

func test_panel_fits_the_screen() -> void:
	var screen := Rect2(0, 0, 640, 360)
	check(screen.encloses(BankJob.PANEL.grow(6)))
	check(BankJob.PANEL.encloses(Rect2(BankJob.ORIGIN, Vector2(BankJob.W, BankJob.H) * BankJob.CELL)))

# --- a scripted raid: the bot waits at each stop until the next leg can be sneaked unseen ---

## Sneak along the points, then hold E for `hold` seconds. Returns the highest meter reached.
func _leg(j: BankJob, points: Array, hold: float) -> float:
	var peak := 0.0
	for p in points:
		var guard_ticks := 0
		while j.result == "" and j.pos.distance_to(p) > 2.0 and guard_ticks < 600:
			var d: Vector2 = p - j.pos
			j.step(DT, d.normalized() * minf(1.0, d.length() / (BankJob.SNEAK * DT)), true, false, false)
			peak = maxf(peak, j.meter)
			guard_ticks += 1
		if guard_ticks >= 600:
			return 9.0   # stuck on furniture
	var n := int(ceil(hold / DT)) + 2
	for i in n:
		j.step(DT, Vector2.ZERO, true, false, true)
		peak = maxf(peak, j.meter)
	return peak

## Find the shortest wait after which the leg is clean; returns the new state or null.
func _timed(j: BankJob, points: Array, hold: float) -> BankJob:
	var waiting := j.clone()
	for w in 240:   # up to two minutes in half-second steps
		var trial := waiting.clone()
		if _leg(trial, points, hold) < SAFE_PEAK and trial.result != "caught":
			return trial
		for i in 15:
			waiting.step(DT, Vector2.ZERO, true, false, false)
		if waiting.meter >= SAFE_PEAK or waiting.result != "":
			return null
	return null

func _pt(cx: float, cy: float) -> Vector2:
	return Vector2(cx, cy) * BankJob.CELL

func test_scripted_route_can_win() -> void:
	var legs := [
		# [name, points in cells, seconds of E]
		["card", [_pt(1.5, 7.0), _pt(2.5, 6.8), _pt(2.5, 4.5), _pt(3.7, 4.4), _pt(3.7, 2.5), _pt(2.5, 1.5), _pt(2.0, 1.4)], BankJob.CARD_TIME],
		["leave desk", [_pt(3.7, 2.5), _pt(3.7, 4.4), _pt(2.5, 4.6), _pt(2.5, 7.5)], 0.0],
		["fuse", [_pt(7.0, 7.6), _pt(7.0, 8.4), _pt(10.7, 8.4)], BankJob.FUSE_TIME],
		["door", [_pt(11.5, 7.6), _pt(11.5, 4.5), _pt(11.65, 4.5)], BankJob.DOOR_TIME],
		["bag 3", [_pt(13.5, 4.5), _pt(14.5, 6.4)], BankJob.BAG_TIME],
		["bag 4", [_pt(14.5, 5.8), _pt(17.4, 6.4)], BankJob.BAG_TIME],
		["bag 2", [_pt(17.4, 2.7)], BankJob.BAG_TIME],
		["bag 1", [_pt(14.5, 2.7)], BankJob.BAG_TIME],
		["back to the door", [_pt(13.5, 4.5), _pt(11.5, 4.5)], 0.0],
		["to the south wall", [_pt(11.5, 7.6), _pt(10.7, 8.4), _pt(7.0, 8.4)], 0.0],
		["to the exit", [_pt(7.0, 7.6), _pt(2.5, 7.5), _pt(1.5, 8.2)], 0.0],
	]
	var j := BankJob.new()
	for leg in legs:
		var next := _timed(j, leg[1], leg[2])
		check(next != null, "no clean window for leg '%s' from %s" % [leg[0], j.pos])
		if next == null:
			return
		j = next
	check(j.has_card and not j.cams_on and j.vault_open, "card, fuse, door")
	check_eq(j.taken.size(), BankJob.BAGS.size(), "all bags")
	for i in 60:
		j.step(DT, Vector2(0, 1), true, false, false)
	check_eq(j.result, "out")
	check_eq(j.banked(), 1300)
