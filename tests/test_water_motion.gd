extends BaseTest

func test_offset_small_and_whole_pixels() -> void:
	for i in 200:
		var o := WaterMotion.offset(i * 0.37, 1.1)
		check(absf(o.x) <= 2.0 and absf(o.y) <= 2.0, "bounded")
		check_eq(o, o.round(), "whole pixels")

func test_offset_actually_moves() -> void:
	var seen := {}
	for i in 100:
		seen[WaterMotion.offset(i * 0.5, 0.0)] = true
	check(seen.size() > 3, "pad moves over time")

func test_push_away() -> void:
	check_eq(WaterMotion.push_away(Vector2(100, 0), Vector2(0, 0)), Vector2.ZERO, "far")
	var p := WaterMotion.push_away(Vector2(10, 0), Vector2(0, 0))
	check(p.x > 0.0 and p.y == 0.0, "pushed away along +x")
	check_eq(WaterMotion.push_away(Vector2.ONE, Vector2.ONE), Vector2.ZERO, "no NaN")
