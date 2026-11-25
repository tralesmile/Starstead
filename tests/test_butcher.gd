extends BaseTest

func test_bait_lifts_chance_and_is_eaten() -> void:
	check(Snares.night_chance(false, true) > Snares.night_chance(false, false))
	check(Snares.night_chance(true, true) < Snares.night_chance(false, false) + 0.01)
	var s := Snares.new()
	var c := Vector2i(2, 2)
	check(not s.bait(c))
	s.place(c, 4.0, "meadow")
	check(s.bait(c))
	check(not s.bait(c))
	check(s.is_baited(c))
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	s.night_tick(rng, false)
	check(not s.is_baited(c))

func test_bait_never_empty_and_richer() -> void:
	check_eq(Snares.catch_for(0.0, "meadow", true), ["raw_meat"])
	check_eq(Snares.catch_for(0.99, "forest", true), ["raw_meat", "raw_meat", "hide"])
	check_eq(Snares.catch_for(0.0, "forest", false), [])

func test_bait_saved() -> void:
	var s := Snares.new()
	s.place(Vector2i(1, 1), 4.0, "forest")
	s.bait(Vector2i(1, 1))
	var t := Snares.new()
	t.from_array(s.to_array())
	check(t.is_baited(Vector2i(1, 1)))

func test_butcher_recipes_craft() -> void:
	var rec: Dictionary = DataDB.load_json("butcher")
	var bag := Inventory.new(20, {})
	bag.add("hide", 6)
	bag.add("raw_meat", 3)
	bag.add("feather", 1)
	var owned: Array = []
	check_eq(ToolKit.craft(owned, rec["leather"], bag), "")
	check_eq(ToolKit.craft(owned, rec["leather"], bag), "")
	check_eq(ToolKit.craft(owned, rec["leather"], bag), "")
	check_eq(bag.count("leather"), 3)
	check_eq(ToolKit.craft(owned, rec["leather_vest"], bag), "")
	check_eq(ToolKit.craft(owned, rec["leather_vest"], bag), "You already have it")
	check_eq(ToolKit.craft(owned, rec["snare_bait"], bag), "")
	check_eq(bag.count("snare_bait"), 2)
	check(owned.is_empty())

func test_leather_vest_softens() -> void:
	var bag := Inventory.new(20, {})
	bag.add("leather_vest", 1)
	check_eq(GearModel.damage_taken_mult(bag), 0.9)
	bag.add("iron_vest", 1)
	check_eq(GearModel.damage_taken_mult(bag), 0.7)

func test_workshop_has_butcher_block() -> void:
	var found := false
	for f in InteriorModel.layout_for("workshop")["furniture"]:
		if String(f.get("action", "")) == "butcher":
			found = true
	check(found)
