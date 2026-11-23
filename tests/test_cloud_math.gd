extends BaseTest

func test_strength() -> void:
	check_eq(CloudMath.strength(0.0, 0.0, 0), 0.0, "none at dawn start")
	check(CloudMath.strength(300.0, 0.0, 0) > 0.99, "full by midday")
	check_eq(CloudMath.strength(900.0, 0.0, 0), 0.0, "none at night")
	check_eq(CloudMath.strength(300.0, 1.0, 0), 0.0, "none in rain")
	check(CloudMath.strength(300.0, 0.0, 3) < CloudMath.strength(300.0, 0.0, 0), "softer in winter")

func test_pos_drifts_and_wraps() -> void:
	var c := Vector2(100, 100)
	var a := CloudMath.pos(2, 0.0, c)
	var b := CloudMath.pos(2, 10.0, c)
	check(b != a, "drifts")
	for k in 40:
		var p := CloudMath.pos(k % CloudMath.COUNT, float(k) * 37.0, c)
		check(absf(p.x - c.x) <= CloudMath.SPAN * 0.5 + 1.0 and absf(p.y - c.y) <= CloudMath.SPAN * 0.5 + 1.0, "inside window")

func test_world_anchored() -> void:
	## Moving the viewer a little must not move a cloud that stays in the window.
	var a := CloudMath.pos(1, 5.0, Vector2(0, 0))
	var b := CloudMath.pos(1, 5.0, Vector2(30, 0))
	check((a - b).length() < 0.01 or (a - b).length() > CloudMath.SPAN * 0.9, "same world spot")

func test_ellipse() -> void:
	var e := CloudMath.ellipse(Vector2(10, 10), Vector2(20, 10), 16)
	check_eq(e.size(), 16)
	check_eq(e[0], Vector2(30, 10))
