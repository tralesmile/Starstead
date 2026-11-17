extends BaseTest

func _farm() -> FarmModel:
	var f := FarmModel.new({})
	for x in range(0, 6):
		for y in range(0, 3):
			f.till(Vector2i(x, y))
	return f

func test_place_not_on_soil_and_once() -> void:
	var f := _farm()
	check(not f.place_sprinkler(Vector2i(1, 1)))
	check(f.place_sprinkler(Vector2i(9, 9)))
	check(not f.place_sprinkler(Vector2i(9, 9)))

func test_sprinkle_waters_3x3_ring_only() -> void:
	var f := _farm()
	f.soil.erase(Vector2i(2, 1))
	check(f.place_sprinkler(Vector2i(2, 1)))
	var n := f.sprinkle()
	check_eq(n, 8)
	check(f.soil[Vector2i(1, 0)].watered)
	check(f.soil[Vector2i(3, 2)].watered)
	check(not f.soil[Vector2i(5, 1)].watered)
	check_eq(f.sprinkle(), 0)

func test_tool_place_and_pickup() -> void:
	var f := _farm()
	var inv := Inventory.new(30, {"sprinkler": 99})
	check_eq(ToolUse.apply("sprinkler", Vector2i(8, 8), f, inv, 0), "No sprinklers")
	inv.add("sprinkler", 2)
	check_eq(ToolUse.apply("sprinkler", Vector2i(8, 8), f, inv, 0), "Placed sprinkler")
	check_eq(inv.count("sprinkler"), 1)
	check_eq(ToolUse.apply("hand", Vector2i(8, 8), f, inv, 0), "Picked up sprinkler")
	check_eq(inv.count("sprinkler"), 2)

func test_sprinkler_save_roundtrip() -> void:
	var f := _farm()
	f.place_sprinkler(Vector2i(7, 7))
	var g := _farm()
	g.sprinklers_from_array(f.sprinklers_to_array())
	check(g.sprinklers.has(Vector2i(7, 7)))
