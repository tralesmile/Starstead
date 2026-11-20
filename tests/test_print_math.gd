extends BaseTest

func test_wet_rules() -> void:
	check(PrintMath.wet(0.8, true))
	check(not PrintMath.wet(0.8, false), "grass leaves mud, not prints")
	check(not PrintMath.wet(0.0, true), "dry quay")

func test_paved_cells() -> void:
	check(PrintMath.paved_cell(Vector2i(192, 3)), "city")
	check(not PrintMath.paved_cell(Vector2i(10, 10)))

func test_alternating_feet() -> void:
	var a := PrintMath.offset(0, PlayerMath.Facing.DOWN)
	var b := PrintMath.offset(1, PlayerMath.Facing.DOWN)
	check_eq(a.x, -b.x)
	check_eq(a.y, 0.0)
	check_eq(PrintMath.offset(0, PlayerMath.Facing.LEFT).x, 0.0)

func test_fade_and_prune() -> void:
	check(PrintMath.alpha(0.0) > PrintMath.alpha(3.0))
	check_eq(PrintMath.alpha(PrintMath.LIFE), 0.0)
	var ps: Array = []
	for i in 60:
		ps.append({"pos": Vector2(i, 0), "age": 0.0})
	var out := PrintMath.prune(ps, 0.1)
	check_eq(out.size(), PrintMath.MAX)
	check_eq(out[out.size() - 1]["pos"], Vector2(59, 0), "newest kept")
	check_eq(PrintMath.prune([{"pos": Vector2.ZERO, "age": 5.95}], 0.1).size(), 0)
