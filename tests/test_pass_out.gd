extends BaseTest

func test_exhausted() -> void:
	check(PassOut.exhausted(0.0))
	check(not PassOut.exhausted(3.0))

func test_money_loss_caps() -> void:
	check_eq(PassOut.money_loss(0), 0)
	check_eq(PassOut.money_loss(999), 99)
	check_eq(PassOut.money_loss(50000), 1000)
	check_eq(PassOut.money_loss(-5), 0)

func test_wake_spot_nearest() -> void:
	var home := Vector2i(40, 40)
	var hosp := Vector2i(197, -2)
	check_eq(PassOut.wake_spot(Vector2i(45, 42), home, hosp), "home")
	check_eq(PassOut.wake_spot(Vector2i(190, 5), home, hosp), "hospital")
	check_eq(PassOut.wake_spot(Vector2i(300, 300), home, hosp), "home" if Vector2(Vector2i(300, 300) - home).length() < Vector2(Vector2i(300, 300) - hosp).length() else "hospital")
	# in the cave highlands, far from home but nearer home than hospital -> still home inside radius
	check_eq(PassOut.wake_spot(Vector2i(100, 10), home, hosp), "home")

func test_bill_capped_by_money() -> void:
	check_eq(PassOut.bill("home", 500), 0)
	check_eq(PassOut.bill("hospital", 500), 60)
	check_eq(PassOut.bill("hospital", 20), 20)
	check_eq(PassOut.bill("hospital", -4), 0)

func test_wake_energy_and_warning() -> void:
	check_eq(PassOut.wake_energy("late"), 50.0)
	check(PassOut.wake_energy("exhausted") < 50.0)
	check_eq(PassOut.warning(60.0), "")
	check(PassOut.warning(18.5 * 60.0) != "")
	check_eq(PassOut.warning_level(19.8 * 60.0), 3)
	check_eq(PassOut.warning_level(19.2 * 60.0), 2)
	check_eq(PassOut.warning_level(18.0 * 60.0), 1)

func test_summary_mentions_cost() -> void:
	check(PassOut.summary("late", 80, "home", 0).contains("-$80"))
	check(PassOut.summary("exhausted", 0, "hospital", 0).contains("hospital"))
