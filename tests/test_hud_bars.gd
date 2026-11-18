extends BaseTest

func test_frac_clamps() -> void:
	check_eq(HudBars.frac(50, 100), 0.5)
	check_eq(HudBars.frac(-3, 100), 0.0)
	check_eq(HudBars.frac(300, 100), 1.0)

func test_colour_bands_and_low() -> void:
	check(HudBars.bar_color(0.9).g > 0.7 and HudBars.bar_color(0.9).r < 0.5)
	check(HudBars.bar_color(0.1).r > 0.8 and HudBars.bar_color(0.1).g < 0.4)
	check(HudBars.low(0.2) and not HudBars.low(0.21))

func test_text() -> void:
	check_eq(HudBars.text(63.4, 100), "63/100")
