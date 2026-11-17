extends BaseTest

func test_pop_arc_lands() -> void:
	check_eq(DropMath.pop_height(0.0), 0.0)
	check(DropMath.pop_height(DropMath.POP_TIME * 0.5) > 10.0)
	check_eq(DropMath.pop_height(DropMath.POP_TIME), 0.0)
	check_eq(DropMath.bob(0.1, 0.0), 0.0)

func test_magnet_and_pickup() -> void:
	var player := Vector2(100, 100)
	check(not DropMath.in_magnet(Vector2(105, 100), player, 0.1))   # still popping
	check(DropMath.in_magnet(Vector2(130, 100), player, 1.0))
	check(not DropMath.in_magnet(Vector2(300, 100), player, 1.0))
	var p := Vector2(140, 94)
	for i in 60:
		p = DropMath.magnet_step(p, player, 0.05)
	check(DropMath.in_pickup(p, player))

func test_pieces_bundle_remainder() -> void:
	check_eq(DropMath.pieces(3), [1, 1, 1])
	check_eq(DropMath.pieces(8), [1, 1, 1, 1, 4])
	check_eq(DropMath.pieces(0), [])
	var total := 0
	for c in DropMath.pieces(12):
		total += c
	check_eq(total, 12)

func test_scatter_is_deterministic() -> void:
	check_eq(DropMath.scatter(0, 1), Vector2.ZERO)
	check_eq(DropMath.scatter(1, 3), DropMath.scatter(1, 3))

func test_tool_use_drops_list() -> void:
	var farm := FarmModel.new(DataDB.load_json("crops"))
	var inv := Inventory.new(30, {})
	var nodes := ResourceNodes.new()
	nodes.add("rock", Vector2i(3, 3))
	var out: Array = []
	var msg := ""
	for i in 3:
		msg = ToolUse.apply("pickaxe", Vector2i(3, 3), farm, inv, 0, null, nodes, null, out)
	check(msg.begins_with("Got"))
	check_eq(out.size(), 1)
	check_eq(inv.count("stone"), 0)   # went to the drop list, not the bag
