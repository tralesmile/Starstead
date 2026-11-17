extends BaseTest

func test_storm_threshold() -> void:
	check(WeatherMath.is_storm(0.9))
	check(not WeatherMath.is_storm(0.5))

func test_no_flash_without_storm() -> void:
	for i in 200:
		check_eq(WeatherMath.lightning_flash(1, 3, float(i) * 0.1, 0.5), 0.0)

func test_flash_happens_and_is_bounded() -> void:
	var peak := 0.0
	var lit := 0
	for i in 2800:
		var f := WeatherMath.lightning_flash(1, 3, float(i) * 0.01, 1.0)
		check(f >= 0.0 and f <= 1.0)
		peak = maxf(peak, f)
		if f > 0.0:
			lit += 1
	check_eq(peak, 1.0)
	check(lit > 0 and lit < 1400, "flash is short")  # 28 s = 2 slots, each lit ~0.6 s

func test_flash_deterministic() -> void:
	check_eq(WeatherMath.lightning_flash(1, 5, 7.3, 1.0), WeatherMath.lightning_flash(1, 5, 7.3, 1.0))

func test_thunder_delay_range() -> void:
	for i in 50:
		var d := WeatherMath.thunder_delay(1, i, float(i) * 3.0)
		check(d >= 0.5 and d <= 3.0)
