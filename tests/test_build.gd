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
