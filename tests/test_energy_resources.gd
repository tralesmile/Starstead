extends BaseTest

func test_energy_limits_actions() -> void:
	var e := Energy.new()
	var uses := 0
	while e.spend("axe"):
		uses += 1
	check_eq(uses, 25)
	check(not e.can_use("hoe") or e.value >= 2.0)
	e.new_day(false)
	check_eq(e.value, 100.0)
	e.new_day(true)
	check_eq(e.value, 50.0)
	check_eq(e.cost_of("turnip_seed"), 0)

func test_tree_chop_and_regrow() -> void:
	var r := ResourceNodes.new()
	var c := Vector2i(2, 2)
	r.add("tree", c)
	check(r.hit(c, "pickaxe").is_empty(), "wrong tool")
	for i in 4:
		check(r.hit(c, "axe").has("hit"))
	var drop := r.hit(c, "axe")
	check_eq(drop.id, "wood")
	check(not r.is_solid(c), "stump walkable")
	for i in ResourceNodes.REGROW_DAYS:
		r.next_day()
	check(r.is_solid(c), "regrown")

func test_rock_breaks_once() -> void:
	var r := ResourceNodes.new()
	r.add("rock", Vector2i(0, 0))
	r.hit(Vector2i(0, 0), "pickaxe"); r.hit(Vector2i(0, 0), "pickaxe")
	check_eq(r.hit(Vector2i(0, 0), "pickaxe").id, "stone")
	check(not r.nodes.has(Vector2i(0, 0)))
