extends BaseTest

func test_limits_and_reach() -> void:
	check(StallTheft.can_steal(0, 30.0))
	check(not StallTheft.can_steal(StallTheft.MAX_PER_DAY, 30.0))
	check(not StallTheft.can_steal(0, 200.0))

func test_loot_covers_table() -> void:
	check_eq(StallTheft.loot_for(0.0), "turnip")
	check_eq(StallTheft.loot_for(0.999), "pumpkin")
	check_eq(StallTheft.loot_for(1.0), "pumpkin")

func test_witness_chance_rises_with_crowd_and_falls_at_night() -> void:
	check(not StallTheft.vendor_sees(0, 12.0, 0.5))
	check(StallTheft.vendor_sees(2, 12.0, 0.5))
	check(not StallTheft.vendor_sees(2, 23.0, 0.5))
