extends BaseTest

func test_tint_curve() -> void:
	check(DayNight.tint(300) == Color(1, 1, 1), "midday white")
	check(DayNight.tint(1000).b > DayNight.tint(1000).r, "night bluish")
	check(DayNight.tint(5000) == DayNight.KEYS[-1][1], "clamps late")
	check(DayNight.tint(0).r >= DayNight.tint(900).r, "dawn brighter than night")

func test_hud_format() -> void:
	var c := GameClock.new()
	check_eq(HudText.format(c, 500), "Spring 1  06:00  $500")
	c.day = 30
	check_eq(HudText.format(c, 7), "Summer 2  06:00  $7")

func test_passout_new_day() -> void:
	var c := GameClock.new()
	check(c.advance(2000.0), "day ends")
	check_eq(c.day, 2)
