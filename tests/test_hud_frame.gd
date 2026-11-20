extends BaseTest

func test_money_text() -> void:
	check_eq(HudText.money_text(0), "$0")
	check_eq(HudText.money_text(500), "$500")
	check_eq(HudText.money_text(1500), "$1,500")
	check_eq(HudText.money_text(1234567), "$1,234,567")
	check_eq(HudText.money_text(-2500), "-$2,500")

func test_dial() -> void:
	var d := HudText.dial(6.0)
	check(d["day"] and is_equal_approx(d["t"], 0.0), "sunrise on the left")
	d = HudText.dial(13.0)
	check(d["day"] and is_equal_approx(d["t"], 0.5), "noon in the middle")
	d = HudText.dial(20.0)
	check(not d["day"] and is_equal_approx(d["t"], 0.0), "moon rises")
	d = HudText.dial(1.0)
	check(not d["day"] and is_equal_approx(d["t"], 0.5), "midnight-ish halfway")
	d = HudText.dial(29.0)
	check(not d["day"] and is_equal_approx(d["t"], 0.9), "wraps")
