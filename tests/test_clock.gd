extends BaseTest

func test_start_time() -> void:
	var c := GameClock.new()
	check_eq(c.time_string(), "06:00")
	check(not c.is_night())

func test_advance_and_day_rollover() -> void:
	var c := GameClock.new()
	c.advance(60.0)
	check(c.minutes > 60.0)
	var ended := c.advance(100000.0)
	check(ended)
	check_eq(c.day, 2)
	check_eq(c.minutes, 0.0)

func test_night_and_season() -> void:
	var c := GameClock.new()
	c.minutes = 15 * 60  # 21:00
	check(c.is_night())
	c.day = 29
	check_eq(c.season(), 1)
