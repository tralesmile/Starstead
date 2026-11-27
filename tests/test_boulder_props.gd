extends BaseTest
## The Warden's boulder against the hall's pillars and braziers (pure rules).

func _prop(kind: String, cell: Vector2i) -> Dictionary:
	return {"kind": kind, "cell": cell, "rect": BossModel.prop_rect(cell, Vector2.ZERO)}

func _roll(b: Dictionary, list: Array, steps: int) -> Array:
	var out: Array = []
	for i in steps:
		b["pos"] += (b["vel"] as Vector2) / 60.0
		var hit := BossModel.hit_props(b, list)
		if not hit.is_empty():
			out.append(hit)
			if hit["shatter"]:
				break
	return out

func test_rect_contact() -> void:
	var r := Rect2(100, 100, 26, 28)
	check(BossModel.rect_contact(Vector2(80, 114), 10.0, r).is_empty(), "clear")
	var c := BossModel.rect_contact(Vector2(94, 114), 10.0, r)
	check(c["normal"].is_equal_approx(Vector2.LEFT))
	check(is_equal_approx(c["depth"], 4.0))
	c = BossModel.rect_contact(Vector2(103, 114), 10.0, r)
	check(c["normal"].is_equal_approx(Vector2.LEFT), "centre inside leaves by the nearest face")
	check(is_equal_approx(c["depth"], 13.0))

func test_fast_boulder_breaks_on_a_pillar() -> void:
	var list := [_prop("pillar", Vector2i(5, 0))]
	var b := BossModel.new_boulder(Vector2(60, 14), Vector2(230, 0))
	var hits := _roll(b, list, 90)
	check_eq(hits.size(), 1)
	check(hits[0]["shatter"], "pillars are cover")
	check_eq(list.size(), 1, "the pillar stands")
	check(b["pos"].x <= 163.0 - BossModel.BOULDER_R + 0.01, "never inside the pillar")

func test_slow_boulder_only_bounces_off_a_pillar() -> void:
	var list := [_prop("pillar", Vector2i(3, 0))]
	var b := BossModel.new_boulder(Vector2(60, 14), Vector2(BossModel.PILLAR_BREAK_SPEED - 20.0, 0))
	var hits := _roll(b, list, 90)
	check(hits.size() >= 1 and not hits[0]["shatter"])
	check(b["vel"].x < 0.0, "comes back")

func test_brazier_is_ploughed_through_once() -> void:
	var list := [_prop("brazier", Vector2i(3, 0))]
	var b := BossModel.new_boulder(Vector2(60, 14), Vector2(200, 0))
	var hits := _roll(b, list, 90)
	check_eq(hits.size(), 1)
	check_eq(hits[0]["kind"], "brazier")
	check(is_equal_approx(b["vel"].x, 200.0 * BossModel.BRAZIER_KEEP), "slowed, same heading")
	check(list.is_empty(), "knocked over")

func test_lane_stops_on_a_pillar_but_not_a_brazier() -> void:
	var list := [_prop("brazier", Vector2i(2, 0)), _prop("pillar", Vector2i(5, 0))]
	var lane := BossModel.trace_lane(Vector2(20, 14), Vector2.RIGHT, Callable(), Vector2.ZERO, 440.0, 56.0, list)
	check_eq(lane.size(), 2)
	check(absf(lane[1].x - (163.0 - BossModel.BOULDER_R)) <= BossModel.BOULDER_SUBSTEP, str(lane))

func test_hall_props_feed_the_boulder() -> void:
	var m := CaveModel.generate(3, CaveModel.BOSS_FLOOR)
	var n := 0
	for item in HallDecor.layout(m):
		if item["solid"]:
			n += 1
	check(n >= 10)
	check_eq(HallDecor.broken_frame(0), 1)
	check_eq(HallDecor.broken_frame(2), 2)
