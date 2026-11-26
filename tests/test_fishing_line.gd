extends BaseTest

const A := Vector2(0, 0)
const B := Vector2(120, 0)

func _run(slack: float, wind: float, secs: float, from: FishingLine = null) -> FishingLine:
	var r := from
	if r == null:
		r = FishingLine.new()
		r.reset(A, B)
	for i in int(secs * 60.0):
		r.step(A, B, slack, wind, 1.0 / 60.0)
	return r

func test_slack_line_sags_with_pinned_ends() -> void:
	var r := _run(FishingLine.slack_for(false, true), 0.0, 2.0)
	check_eq(r.pts[0], A)
	check_eq(r.pts[FishingLine.N - 1], B)
	check(r.sag() > 6.0 and r.sag() < 30.0, "sag %f" % r.sag())

func test_bite_pulls_it_taut() -> void:
	var r := _run(0.035, 0.0, 2.0)
	_run(FishingLine.slack_for(false, false), 0.0, 0.25, r)
	check(r.sag() < 1.5, "still sagging %f" % r.sag())

func test_wind_blows_it_downwind() -> void:
	var calm := FishingLine.new()   # a line cast straight "north", so a sideways wind bows it
	var windy := FishingLine.new()
	for i in 120:
		calm.step(Vector2.ZERO, Vector2(0, -120), 0.035, 0.0, 1.0 / 60.0)
		windy.step(Vector2.ZERO, Vector2(0, -120), 0.035, 200.0, 1.0 / 60.0)
	check(windy.pts[7].x > calm.pts[7].x + 2.0, "%f vs %f" % [windy.pts[7].x, calm.pts[7].x])

func test_stays_bounded_through_a_frame_hitch() -> void:
	var r := _run(0.1, 80.0, 0.5)
	r.step(A, B, 0.1, 80.0, 3.0)
	for p in r.pts:
		check(p.length() < 400.0, str(p))

func test_strain_tug_and_clicks() -> void:
	check_eq(FishingLine.strain(0.8), 0.0)
	check_eq(FishingLine.strain(0.0), 1.0)
	check(FishingLine.fish_tug(1.0, 1.0, 0.0).x > 0.0 and FishingLine.fish_tug(0.0, 1.0, 0.0).x < 0.0)
	check(FishingLine.click_interval(true) < FishingLine.click_interval(false))
