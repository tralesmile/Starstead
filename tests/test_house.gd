extends BaseTest

func _m() -> BuildModel:
	return BuildModel.new(DataDB.load_json("build"))

func test_hut_cost_and_stamp() -> void:
	var m := _m()
	var cost := m.blueprint_cost("hut")
	check_eq(cost["wood"], 7 * 4 + 2 + 6)  # 7 walls, floor, door
	var b := Inventory.new(30, {})
	b.add("wood", 99)
	check_eq(m.stamp("hut", Vector2i(10, 10), b), 9)
	check_eq(b.count("wood"), 99 - int(cost["wood"]))

func test_enclosed_room() -> void:
	var m := _m()
	var b := Inventory.new(30, {})
	b.add("wood", 99)
	m.stamp("hut", Vector2i(0, 0), b)
	check(m.is_enclosed(Vector2i(1, 1)))
	m.remove_piece(Vector2i(0, 1), b)
	check(not m.is_enclosed(Vector2i(1, 1)))

func test_roof_data() -> void:
	check(bool(DataDB.load_json("build")["roof"].roof))

func test_squash_ends_at_one() -> void:
	check_eq(HitMath.squash(0.0, 0.2), Vector2.ONE)
	var s := HitMath.squash(0.2, 0.2)
	check(s.x > 1.0 and s.y < 1.0)

func test_roof_piece_selectable_with_sprite() -> void:
	check("roof" in BuildModel.PIECES)
	var d: Dictionary = DataDB.load_json("build")
	for p in BuildModel.PIECES:
		check(FileAccess.file_exists("res://assets/sprites/%s.png" % d[p]["sprite"]), p)
