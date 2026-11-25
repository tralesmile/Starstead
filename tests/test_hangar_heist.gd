extends BaseTest

func test_cooldown() -> void:
	check(HangarHeist.ready(-1, 3))
	check(not HangarHeist.ready(10, 12))
	check_eq(HangarHeist.days_left(10, 12), 5)
	check(HangarHeist.ready(10, 17))

func test_cases_inside_room_and_not_in_crates() -> void:
	for c in HangarHeist.CASES:
		var cell: Vector2i = c["cell"]
		check(cell.x >= 0 and cell.x < HangarHeist.W and cell.y >= 0 and cell.y < HangarHeist.H)
		for r in HangarHeist.CRATES:
			check(not r.has_point(cell))

func test_cone_sees_straight_below_and_not_behind() -> void:
	var t := 0.0
	var cam: Dictionary = HangarHeist.CAMS[2]
	var a := HangarHeist.cam_angle(2, t)
	var p: Vector2 = Vector2(cam["pos"]) + Vector2.from_angle(a) * 120.0
	check(HangarHeist.seen_by(2, t, p) or HangarHeist.hidden(Vector2(cam["pos"]), p))
	var far: Vector2 = Vector2(cam["pos"]) + Vector2.from_angle(a) * 400.0
	check(not HangarHeist.seen_by(2, t, far), "out of range")
	var behind: Vector2 = Vector2(cam["pos"]) - Vector2.from_angle(a) * 60.0
	check(not HangarHeist.seen_by(2, t, behind))

func test_crate_hides_player() -> void:
	var r: Rect2 = HangarHeist.crate_rects()[2]   # (6,5) crate
	var from := Vector2(7.0 * 32.0, 0.2 * 32.0)
	var behind := Vector2(r.position.x + r.size.x * 0.5, r.end.y + 12.0)
	check(HangarHeist.hidden(from, behind))
	check(not HangarHeist.hidden(from, Vector2(7.0 * 32.0, 2.0 * 32.0)))

func test_meter() -> void:
	var m := 0.0
	for i in 20:
		m = HangarHeist.step_meter(m, true, false, 0.1)
	check(m >= 1.0 - 0.001)
	var s := HangarHeist.step_meter(0.0, true, true, 1.0)
	check(s < HangarHeist.step_meter(0.0, true, false, 1.0))
	check_eq(HangarHeist.step_meter(0.3, false, false, 10.0), 0.0)

func test_route_exists() -> void:
	## the first case at (1,1) can be reached and left without ever standing in a cone at some time t
	var safe := false
	for k in 100:
		if not HangarHeist.seen(k * 0.2, Vector2(1.5 * 32.0, 2.0 * 32.0)):
			safe = true
	check(safe, "windows of safety exist at the left case")
	for k in 100:
		if not HangarHeist.seen(k * 0.2, HangarHeist.entrance()):
			return
	check(false, "entrance never safe")

func test_door_and_total() -> void:
	check(HangarHeist.at_door(Vector2(6.5 * 32.0, 9 * 32.0)))
	check(not HangarHeist.at_door(Vector2(2 * 32.0, 9 * 32.0)))
	check_eq(HangarHeist.total_cash([0, 1]), 520)
