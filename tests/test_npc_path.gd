extends BaseTest

func test_routes_around_wall() -> void:
	# 8x8 grid, wall at x=4 for y 0..5 (gap at y 6,7)
	var land := func(c: Vector2i) -> bool: return not (c.x == 4 and c.y <= 5)
	var g := NpcPath.build(8, land)
	var r := NpcPath.route(g, Vector2i(1, 1), Vector2i(7, 1))
	check(r.size() > 6)
	for p in r:
		check(not (floori(p.x / 32.0) == 4 and floori(p.y / 32.0) <= 5))

func test_unreachable_and_solid() -> void:
	var land := func(c: Vector2i) -> bool: return c.x != 4
	var g := NpcPath.build(8, land)
	check(NpcPath.route(g, Vector2i(1, 1), Vector2i(7, 1)).is_empty())
	check(NpcPath.route(g, Vector2i(4, 1), Vector2i(1, 1)).is_empty())
	check(NpcPath.route(g, Vector2i(-1, 1), Vector2i(1, 1)).is_empty())
