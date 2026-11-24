extends BaseTest

func test_tiers() -> void:
	check_eq(ReputationModel.tier(0), 0)
	check_eq(ReputationModel.tier(9), 0)
	check_eq(ReputationModel.tier(10), 1)
	check_eq(ReputationModel.tier(59), 2)
	check_eq(ReputationModel.tier(500), 4)

func test_honest_perks_rise() -> void:
	check(ReputationModel.buy_mult(100) < ReputationModel.buy_mult(30))
	check(ReputationModel.sell_mult(100) > ReputationModel.sell_mult(0))
	check(ReputationModel.fine_mult(100) < ReputationModel.fine_mult(10))
	check_eq(ReputationModel.apply_fine(100, 100), 60)
	check_eq(ReputationModel.apply_fine(100, 0), 100)

func test_street_perks_rise() -> void:
	check(ReputationModel.fence_mult(100) > ReputationModel.fence_mult(10))
	check(ReputationModel.bribe_cost(2, 100) < ReputationModel.bribe_cost(2, 10))
	check_eq(ReputationModel.bribe_cost(2, 0), 160)
	check(ReputationModel.skill(60, true) > ReputationModel.skill(60, false))
	check_eq(ReputationModel.skill(0, true), 2)

func test_double_life_and_dealer() -> void:
	check(not ReputationModel.double_life(30, 29))
	check(ReputationModel.double_life(30, 30))
	check(ReputationModel.decay_mult(30, 30) > ReputationModel.decay_mult(0, 30))
	check(not ReputationModel.dealer_open(5))
	check(ReputationModel.dealer_open(10))

func test_bribe_cheaper_than_fine_at_top() -> void:
	# a kingpin bribe must undercut the fine so the street road has a payoff
	check(ReputationModel.bribe_cost(3, 100) < WantedMath.fine(3))

func test_summary_text() -> void:
	check(ReputationModel.summary(35, 40).contains("Double life"))
	check(ReputationModel.summary(0, 0).contains("Newcomer"))

func test_dealer_rules() -> void:
	var r := DealerModel.buy("lockpick_set", 500, 0, 0, false)
	check(not r["ok"], "closed to a nobody")
	r = DealerModel.buy("lockpick_set", 500, 15, 0, false)
	check(r["ok"])
	check_eq(r["money"], 500 - DealerModel.PICK_PRICE)
	check(not DealerModel.buy("lockpick_set", 500, 15, 0, true)["ok"], "already own one")
	check(not DealerModel.buy("bribe", 500, 15, 0, false)["ok"], "no stars, no bribe")
	r = DealerModel.buy("bribe", 500, 15, 2, false)
	check(r["ok"])
	check_eq(r["money"], 500 - 160)
	check(not DealerModel.buy("bribe", 10, 15, 2, false)["ok"], "cash first")

func test_load_grip() -> void:
	check_eq(PlayerMath.load_grip(0.5), 1.0)
	check_eq(PlayerMath.load_grip(0.8), 1.0)
	check_eq(PlayerMath.load_grip(1.0), 0.8)
	check(PlayerMath.load_grip(0.9) < 1.0 and PlayerMath.load_grip(0.9) > 0.8)

func test_decay_mult_speeds_cooling() -> void:
	check(WantedMath.decay(50.0, 1.0, false, 1.3) < WantedMath.decay(50.0, 1.0, false, 1.0))
