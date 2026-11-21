extends BaseTest

func _m() -> BuildModel:
	return BuildModel.new(DataDB.load_json("build"))

func _bag(wood: int) -> Inventory:
	var b := Inventory.new(30, {})
	b.add("wood", wood)
	return b

func test_place_consumes_cost() -> void:
	var m := _m(); var b := _bag(10)
	check_eq(m.place(Vector2i(1, 1), "wall", 3.0, false, b), "")
	check_eq(b.count("wood"), 6)
	check(m.is_solid(Vector2i(1, 1)))

func test_invalid_reasons() -> void:
	var m := _m(); var b := _bag(1)
	check_eq(m.check(Vector2i(0, 0), "wall", 3.0, false, b), "Need materials")
	check_eq(m.check(Vector2i(0, 0), "floor", 0.2, false, _bag(9)), "Too close to water")
	check_eq(m.check(Vector2i(0, 0), "floor", 3.0, true, _bag(9)), "Something is in the way")
	check_eq(m.check(Vector2i(0, 0), "nope", 3.0, false, b), "Unknown piece")

func test_no_double_place_and_floor_not_solid() -> void:
	var m := _m(); var b := _bag(20)
	m.place(Vector2i(2, 2), "floor", 3.0, false, b)
	check_eq(m.place(Vector2i(2, 2), "wall", 3.0, false, b), "Occupied")
	check(not m.is_solid(Vector2i(2, 2)))
	check_eq(b.count("wood"), 18)

func test_demolish_refund_and_save_roundtrip() -> void:
	var m := _m(); var b := _bag(10)
	m.place(Vector2i(3, 4), "door", 3.0, false, b)
	var m2 := _m()
	m2.from_dict(m.to_dict())
	check_eq(m2.placed.get(Vector2i(3, 4)), "door")
	check(m.remove_piece(Vector2i(3, 4), b))
	check_eq(b.count("wood"), 7)
	check(not m.remove_piece(Vector2i(3, 4), b))

func test_blueprints_cycle_and_cost() -> void:
	check_eq(BuildModel.next_blueprint("hut"), "house")
	check_eq(BuildModel.next_blueprint("pen"), "hut")
	var bm := BuildModel.new(DataDB.load_json("build"))
	for k in BuildModel.BLUEPRINTS:
		var seen := {}
		for e in BuildModel.BLUEPRINTS[k].cells:
			var c := Vector2i(int(e[0]), int(e[1]))
			check(not seen.has(c), "%s: no duplicate cell %s" % [k, str(c)])
			seen[c] = true
			check(bm.defs.has(str(e[2])), "%s: known piece" % k)
		check(int(bm.blueprint_cost(k).get("wood", 0)) > 0)

func test_house_is_enclosed_and_pen_is_sealed() -> void:
	var bm := BuildModel.new(DataDB.load_json("build"))
	var bag := Inventory.new()
	bag.add("wood", 500)
	var o := Vector2i(10, 10)
	check(bm.stamp("house", o, bag) > 15)
	check(bm.is_enclosed(o + Vector2i(1, 1)), "house interior is sealed")
	check_eq(bm.placed[o + Vector2i(2, 3)], "door")
	var bm2 := BuildModel.new(DataDB.load_json("build"))
	bm2.stamp("pen", o, bag)
	check(bm2.is_solid(o + Vector2i(0, 2)), "pen fence blocks")
	check(bm2.is_enclosed(o + Vector2i(2, 2)), "pen interior is closed off")

func test_lamp_post_piece() -> void:
	var bm := BuildModel.new(DataDB.load_json("build"))
	check("lamp" in BuildModel.PIECES)
	check(bool(bm.defs["lamp"].get("light", false)) and bool(bm.defs["lamp"].solid))
	var bag := Inventory.new()
	bag.add("wood", 3)
	check_eq(bm.place(Vector2i(1, 1), "lamp", 3.0, false, bag), "")
	check_eq(bag.count("wood"), 0)
	check_eq(bm.place(Vector2i(2, 1), "lamp", 3.0, false, bag), "Need materials")
	check(bm.remove_piece(Vector2i(1, 1), bag), "demolish refunds")
