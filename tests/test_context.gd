extends BaseTest

func _ripe_farm(c: Vector2i) -> FarmModel:
	var f := FarmModel.new(DataDB.load_json("crops"))
	f.till(c)
	f.soil[c].crop = "turnip"
	f.soil[c].age = 99
	return f

func test_nothing_ripe() -> void:
	var f := FarmModel.new(DataDB.load_json("crops"))
	f.till(Vector2i(5, 5))
	check_eq(ContextAction.ripe_cell(f, Vector2i(5, 5), Vector2i(0, 0)), ContextAction.NONE)
	check_eq(ContextAction.hint(f, Vector2i(5, 5), Vector2i(0, 0)), "")

func test_ripe_faced_or_underfoot() -> void:
	var f := _ripe_farm(Vector2i(5, 5))
	check_eq(ContextAction.ripe_cell(f, Vector2i(5, 5), Vector2i(0, 0)), Vector2i(5, 5))
	check_eq(ContextAction.ripe_cell(f, Vector2i(9, 9), Vector2i(5, 5)), Vector2i(5, 5))
	check_eq(ContextAction.hint(f, Vector2i(5, 5), Vector2i(0, 0)), "E: harvest")
