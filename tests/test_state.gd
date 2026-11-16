extends BaseTest

func test_inventory() -> void:
	var g = load("res://scripts/game_state.gd").new()
	g.add_item("wood", 3)
	check(g.has_item("wood", 3))
	g.add_item("wood", -3)
	check(not g.has_item("wood"))
	g.free()

func test_save_roundtrip() -> void:
	var g = load("res://scripts/game_state.gd").new()
	g.money = 123
	g.add_item("egg", 2)
	g.clock.day = 5
	g.rep_street = 7
	check(g.save_game("user://test_save.json"))
	var h = load("res://scripts/game_state.gd").new()
	check(h.load_game("user://test_save.json"))
	check_eq(h.money, 123)
	check_eq(h.inventory.get("egg"), 2)
	check_eq(h.clock.day, 5)
	check_eq(h.rep_street, 7)
	g.free()
	h.free()

func test_future_version_rejected() -> void:
	var g = load("res://scripts/game_state.gd").new()
	check(not g.from_dict({"version": 999}))
	g.free()
