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
	for id in ["chicken", "cow", "sheep", "horse"]:
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
	for id in ["cow", "sheep", "horse"]:
		check("hay" in m.animals[id]["feed"], id)
	check(not ("hay" in m.animals["chicken"]["feed"]), "chickens want turnips")
	var st := {"id": "cow", "hunger": 80.0}
	check(m.feed(st, "hay"))
	check_eq(st["hunger"], 0.0)
