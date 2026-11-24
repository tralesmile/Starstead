extends BaseTest

func test_slots_deterministic_and_vary_by_day() -> void:
	var a := CarTheft.slots(3)
	check_eq(a.size(), CarTheft.slots(3).size())
	check(a.size() > 6 and a.size() < 40)
	check(str(CarTheft.slots(3)) != str(CarTheft.slots(4)))

func test_slots_on_asphalt_and_off_plazas() -> void:
	for d in 6:
		for s in CarTheft.slots(d):
			check(CityModel.is_asphalt(s["cell"]), "slot %s not asphalt" % str(s["cell"]))
			check(not (s["cell"].x >= 191 and s["cell"].x <= 193), "slot on avenue")

func test_hotwire_odds() -> void:
	check(CarTheft.hotwire_chance(0, "basic") > CarTheft.hotwire_chance(0, "hardened"))
	check(CarTheft.hotwire_chance(5, "basic") > CarTheft.hotwire_chance(0, "basic"))
	check(CarTheft.hotwire_chance(99, "basic") <= 0.9)
	check(CarTheft.hotwire_chance(-9, "hardened") >= 0.1)

func test_attempt_alarm_rules() -> void:
	check(CarTheft.attempt(0, "basic", 0.1, 0.9)["ok"])
	check(not CarTheft.attempt(0, "basic", 0.9, 0.9)["alarm"])
	check(CarTheft.attempt(0, "hardened", 0.99, 0.9)["alarm"])
	check(CarTheft.attempt(0, "alarmed", 0.99, 0.5)["alarm"])
	check(not CarTheft.attempt(0, "alarmed", 0.0, 0.9)["alarm"])

func test_owner_and_price() -> void:
	check(CarTheft.owner_sees(3, 12.0, 0.5))
	check(not CarTheft.owner_sees(3, 23.0, 0.5))
	check(CarTheft.chop_price(320, 1.0) > CarTheft.chop_price(320, 0.2))
	check_eq(CarTheft.chop_price(100, 1.0), 75)
	var s := CarTheft.slots(1)
	var near := CarTheft.nearest(s, (Vector2(s[0]["cell"]) + Vector2(0.5, 0.5)) * 32.0, [])
	check_eq(near["id"], s[0]["id"])
	check(CarTheft.nearest(s, (Vector2(s[0]["cell"]) + Vector2(0.5, 0.5)) * 32.0, [s[0]["id"]]).get("id", "") != s[0]["id"])
