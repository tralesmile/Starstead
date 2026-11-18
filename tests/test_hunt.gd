extends BaseTest

func test_hunt_data() -> void:
	var a = DataDB.load_json("animals")["animals"]
	var items = DataDB.load_json("items")
	for id in ["deer", "rabbit", "boar", "chicken", "sheep"]:
		check(HuntModel.huntable(a, id), "%s is huntable" % id)
		for d in a[id].hunt.drops:
			check(items.has(d.item), "drop %s exists in items.json" % d.item)
	check(not HuntModel.huntable(a, "horse"), "horses are not game")
	check(not HuntModel.tameable(a, "deer") and HuntModel.tameable(a, "cow"))
	check(HuntModel.fights_back(a, "boar") and not HuntModel.fights_back(a, "rabbit"))
	check(HuntModel.hp_for(a, "deer") > HuntModel.hp_for(a, "rabbit"))

func test_drops_roll() -> void:
	var a = DataDB.load_json("animals")["animals"]
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var d := HuntModel.roll_drops(a, "deer", rng)
	check(int(d.get("raw_meat", 0)) >= 2, "deer always gives meat")
	check(HuntModel.roll_drops(a, "ghost", rng).is_empty())
	check_eq(HuntModel.bite_damage(30.0), 0.0)
	check(HuntModel.bite_damage(10.0) > 0.0)

func test_club_kills_rabbit_in_one_hit_deer_in_three() -> void:
	var a = DataDB.load_json("animals")["animals"]
	var club: float = float(CombatModel.weapon("club").dmg)
	check(HuntModel.hp_for(a, "rabbit") <= club, "one club hit")
	check(HuntModel.hp_for(a, "deer") > club and HuntModel.hp_for(a, "deer") <= club * 3.0, "2-3 club hits")
	check(HuntModel.hp_for(a, "deer") > float(CombatModel.weapon("fist").dmg) * 3.0, "fists are slow on a deer")
