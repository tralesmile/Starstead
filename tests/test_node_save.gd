extends BaseTest

func test_chopped_tree_and_mined_rock_roundtrip() -> void:
	var a := ResourceNodes.new()
	a.add("tree", Vector2i(5, 5))
	a.add("tree", Vector2i(6, 5))
	a.add("rock", Vector2i(7, 5))
	for i in 5:
		a.hit(Vector2i(5, 5), "axe")
	a.hit(Vector2i(6, 5), "axe")            # damaged only
	for i in 3:
		a.hit(Vector2i(7, 5), "pickaxe")    # broken
	var arr: Array = JSON.parse_string(JSON.stringify(a.to_array()))
	var b := ResourceNodes.new()
	b.from_array(arr)
	b.add("tree", Vector2i(5, 5))
	b.add("tree", Vector2i(6, 5))
	b.add("rock", Vector2i(7, 5))
	b.add("tree", Vector2i(9, 9))
	check(not b.is_solid(Vector2i(5, 5)), "stump stays chopped")
	check_eq(b.nodes[Vector2i(5, 5)].stump_days, ResourceNodes.REGROW_DAYS)
	check_eq(b.nodes[Vector2i(6, 5)].hp, ResourceNodes.HP.tree - 1)
	check(not b.nodes.has(Vector2i(7, 5)), "mined rock does not respawn")
	check_eq(b.nodes[Vector2i(9, 9)].hp, ResourceNodes.HP.tree)

func test_unregistered_deltas_survive_a_second_save() -> void:
	var a := ResourceNodes.new()
	a.from_array([[40, 40, 2, 0], [41, 41, -1, 0]])   # streamed chunk not loaded this session
	var again := a.to_array()
	check_eq(again.size(), 2)
	var b := ResourceNodes.new()
	b.from_array(again)
	b.add_once("tree", Vector2i(40, 40))
	check_eq(b.nodes[Vector2i(40, 40)].hp, 2)
	b.add_once("rock", Vector2i(41, 41))
	check(not b.nodes.has(Vector2i(41, 41)))

func test_homestead_registered_before_load() -> void:
	var b := ResourceNodes.new()
	b.add("tree", Vector2i(1, 1))
	b.add("rock", Vector2i(2, 2))
	b.from_array([[1, 1, 3, 0], [2, 2, -1, 0]])
	check_eq(b.nodes[Vector2i(1, 1)].hp, 3)
	check(not b.nodes.has(Vector2i(2, 2)))

func test_game_state_saves_nodes() -> void:
	var g = load("res://scripts/game_state.gd").new()
	g.nodes.add("tree", Vector2i(3, 3))
	for i in 5:
		g.nodes.hit(Vector2i(3, 3), "axe")
	check(g.save_game("user://test_nodes.json"))
	var h = load("res://scripts/game_state.gd").new()
	check(h.load_game("user://test_nodes.json"))
	h.nodes.add("tree", Vector2i(3, 3))
	check(not h.nodes.is_solid(Vector2i(3, 3)))
	g.free()
	h.free()
