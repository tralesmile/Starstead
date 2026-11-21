extends BaseTest

func _m() -> AnimalModel:
	return AnimalModel.new(DataDB.load_json("animals"))

func _tamed(m: AnimalModel, id: String) -> Dictionary:
	var p := m.new_approach(id)
	for i in 10:
		m.feed_wild(p, "turnip")
	return m.tame(p)

func test_data_valid() -> void:
	var d: Dictionary = DataDB.load_json("animals")
	var items = DataDB.load_json("items")
	for id in ["chicken", "cow", "sheep", "goat", "horse"]:
		check(d["animals"].has(id), id)
		var a: Dictionary = d["animals"][id]
		for k in ["name", "wild_speed", "tame_difficulty", "resource", "rideable", "ride_speed_mult", "gear_slots"]:
			check(a.has(k), id + k)
		if a["resource"]["item"] != "":
			check(items.has(a["resource"]["item"]), "item " + id)
	for g in d["gear"]:
		check(items.has(g), "gear item " + g)

func test_feeding_tames() -> void:
	var m := _m()
	var p := m.new_approach("horse")
	check(not m.feed_wild(p, "stone"))
	check_eq(m.tame(p), {})
	for i in 10:
		m.feed_wild(p, "turnip")
	var st := m.tame(p)
	check_eq(st["id"], "horse")
	check_eq(st["gear"], {})

func test_trust_decays() -> void:
	var m := _m()
	var p := m.new_approach("chicken")
	m.feed_wild(p, "turnip")
	var t: float = p["trust"]
	m.decay(p, 1.0)
	check(p["trust"] < t)
	m.decay(p, 999.0)
	check_eq(p["trust"], 0.0)

func test_hard_animal_slower() -> void:
	var m := _m()
	var c := m.new_approach("chicken")
	var h := m.new_approach("horse")
	m.feed_wild(c, "turnip")
	m.feed_wild(h, "turnip")
	check(c["trust"] > h["trust"])

func test_production_needs_food() -> void:
	var m := _m()
	var st := _tamed(m, "chicken")
	var got := m.day_tick(st)
	check_eq(got.get("egg", 0), 1)
	m.day_tick(st)  # hunger 50 -> still fed
	check_eq(m.day_tick(st), {}, "hungry animal produces nothing")
	m.feed(st, "turnip")
	check_eq(m.day_tick(st).get("egg", 0), 1)

func test_sheep_every_three_days() -> void:
	var m := _m()
	var st := _tamed(m, "sheep")
	check_eq(m.day_tick(st), {})
	m.feed(st, "turnip")
	check_eq(m.day_tick(st), {})
	m.feed(st, "turnip")
	check_eq(m.day_tick(st).get("wool", 0), 1)

func test_ride_speed_and_gear() -> void:
	var m := _m()
	var horse := _tamed(m, "horse")
	var base := m.ride_speed(horse)
	check(base > 160.0)
	check(m.equip(horse, "saddle"))
	check(m.ride_speed(horse) > base)
	check(m.equip(horse, "fur_coat"))
	check(m.equip(horse, "armour"))
	check_eq(m.gear_total(horse, "cold_resist"), 3.0)
	check_eq(m.gear_total(horse, "defense"), 5.0)
	check(not m.equip(horse, "turnip"))
	check_eq(m.unequip(horse, "saddle"), "saddle")
	check_eq(m.ride_speed(horse), base)
	var hen := _tamed(m, "chicken")
	check_eq(m.ride_speed(hen), 0.0)
	check(not m.equip(hen, "saddle"))

func test_serialize_roundtrip() -> void:
	var m := _m()
	var a := _tamed(m, "cow")
	m.equip(a, "saddle")
	m.day_tick(a)
	var b := m.deserialize(m.serialize([a, _tamed(m, "sheep")]))
	check_eq(b.size(), 2)
	check_eq(b[0]["id"], "cow")
	check_eq(b[0]["gear"], {"saddle": "saddle"})
	check_eq(b[0]["hunger"], a["hunger"])
	check_eq(m.ride_speed(b[0]), m.ride_speed(a))
	check_eq(m.deserialize("garbage").size(), 0)

func test_pen_target_stays_in_radius() -> void:
	var home := Vector2(100, 100)
	for i in 20:
		var t := AnimalModel.pen_target(home, home + Vector2(50, 0), float(i), 40.0)
		check(t.distance_to(home) <= AnimalModel.PEN_RADIUS + 0.01)

func test_next_gear_fits_empty_slot_only() -> void:
	var m := AnimalModel.new(DataDB.load_json("animals"))
	var st := {"id": "chicken", "gear": {}}
	check_eq(m.next_gear(st, {"saddle": 1}), "")          # chickens take no saddle
	check_eq(m.next_gear(st, {"armour": 1}), "armour")
	st["gear"]["armour"] = "armour"
	check_eq(m.next_gear(st, {"armour": 1}), "")
	var h := {"id": "horse", "gear": {}}
	check_eq(m.next_gear(h, {"saddle": 1, "fur_coat": 1}), "fur_coat")  # sorted ids: fur_coat before saddle

func test_grazers_eat_hay() -> void:
	var m := AnimalModel.new(DataDB.load_json("animals"))
	for id in ["cow", "sheep", "goat", "horse"]:
		check("hay" in m.animals[id]["feed"], id)
	check(not ("hay" in m.animals["chicken"]["feed"]), "chickens want turnips")
	var st := {"id": "cow", "hunger": 80.0}
	check(m.feed(st, "hay"))
	check_eq(st["hunger"], 0.0)

func _bm() -> AnimalModel:
	return AnimalModel.new(DataDB.load_json("animals"))

func test_pet_once_a_day_and_tiers() -> void:
	var m := _bm()
	var st := {"id": "cow", "trust": 0.0, "hunger": 0.0, "gear": {}}
	check(m.pet(st, 5))
	check(not m.pet(st, 5), "once per day")
	check_eq(m.bond(st), AnimalModel.PET_GAIN)
	check_eq(m.bond_tier(st), "wary")
	for d in range(6, 30):
		m.pet(st, d)
	check(m.bond(st) >= 80, "a month of pats")
	check_eq(m.bond_tier(st), "devoted")
	for d in range(30, 60):
		m.pet(st, d)
	check_eq(m.bond(st), AnimalModel.BOND_MAX, "capped")

func test_bonus_yield_needs_a_bond() -> void:
	check(not AnimalModel.bonus_roll(49, 3, 1))
	var any := false
	var none_low := true
	for d in range(1, 200):
		if AnimalModel.bonus_roll(100, d, 0):
			any = true
		if AnimalModel.bonus_roll(50, d, 0):
			none_low = false
	check(any, "full bond sometimes doubles")
	check(none_low, "bond 50 gives 0% chance")
	check_eq(AnimalModel.bonus_roll(90, 7, 2), AnimalModel.bonus_roll(90, 7, 2), "deterministic")

func test_day_tick_double_yield() -> void:
	var m := _bm()
	var total1 := 0
	var total0 := 0
	for d in range(1, 120):
		var a := {"id": "chicken", "trust": 0.0, "hunger": 0.0, "gear": {}, "bond": 100}
		var b := {"id": "chicken", "trust": 0.0, "hunger": 0.0, "gear": {}}
		total1 += int(m.day_tick(a, d, 0).get("egg", 0))
		total0 += int(m.day_tick(b, d, 0).get("egg", 0))
	check_eq(total0, 119, "daily egg without a bond")
	check(total1 > total0, "bonded hen lays extra")

func test_sneaking_lets_you_get_close() -> void:
	check(AnimalModel.should_flee(60.0, 0.0), "walking up at 60px spooks it")
	check(not AnimalModel.should_flee(60.0, 0.0, HuntModel.scare_scale(true, false)), "creeping does not")
	check(AnimalModel.should_flee(100.0, 0.0, HuntModel.scare_scale(false, true)), "sprinting spooks from farther")
	check(HuntModel.scare_scale(false, true) > HuntModel.scare_scale(false, false))
	check(PlayerMath.sneak_mult(true) < 1.0 and PlayerMath.sneak_mult(false) == 1.0)

func test_tame_animals_sleep_at_night() -> void:
	check(AnimalModel.asleep(23.0, false))
	check(AnimalModel.asleep(3.0, false))
	check(not AnimalModel.asleep(12.0, false))
	check(not AnimalModel.asleep(23.0, true), "wild ones roam all night")
	check(not AnimalModel.asleep(5.0, false) and AnimalModel.asleep(21.0, false), "edges")

func test_pen_bonus_needs_stay_and_enclosure() -> void:
	var m := _bm()
	var st := {"id": "cow", "stay": true, "bond": 10}
	m.pen_bonus(st, true)
	check_eq(m.bond(st), 11)
	m.pen_bonus(st, false)
	check_eq(m.bond(st), 11, "open field")
	var free := {"id": "cow", "bond": 10}
	m.pen_bonus(free, true)
	check_eq(m.bond(free), 10, "not told to stay")
	var full := {"id": "cow", "stay": true, "bond": 100}
	m.pen_bonus(full, true)
	check_eq(m.bond(full), 100, "capped")
	var bm := BuildModel.new(DataDB.load_json("build"))
	var bag := Inventory.new()
	bag.add("wood", 200)
	bm.stamp("pen", Vector2i(20, 20), bag)
	check(bm.is_enclosed(Vector2i(22, 22)) and not bm.is_enclosed(Vector2i(40, 40)), "pen counts, open ground does not")

func test_goat_gives_milk_every_two_days() -> void:
	var m := _bm()
	check_eq(m.animals["goat"]["resource"]["item"], "goat_milk")
	check(DataDB.load_json("items").has("goat_milk"))
	var st := {"id": "goat", "trust": 0.0, "hunger": 0.0, "gear": {}, "age": 0, "days": 0}
	var got := 0
	for d in range(1, 9):
		st["hunger"] = 0.0   # fed every day
		got += int(m.day_tick(st, d, 0).get("goat_milk", 0))
	check(got >= 3 and got <= 4, "about every other day (%d)" % got)
