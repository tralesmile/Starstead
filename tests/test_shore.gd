extends BaseTest

func _straight(t: Vector2i) -> float:
	return float(t.x) - 10.0   # shore: water for x < 10 (zero crossing at u = 10.5)

func test_bilinear_matches_texel_centres() -> void:
	var g := Callable(self, "_straight")
	check(absf(ShoreMath.sdf_bilinear(g, Vector2(10.5, 5.5)) - 0.0) < 0.001)
	check(absf(ShoreMath.sdf_bilinear(g, Vector2(12.5, 5.5)) - 2.0) < 0.001)
	check(ShoreMath.sdf_bilinear(g, Vector2(9.0, 5.5)) < 0.0)

func test_rects_follow_the_contour_not_tile_squares() -> void:
	var g := Callable(self, "_straight")
	var rects := ShoreMath.blocked_rects(g, 16, func(_t): return false, 20.0)
	check(rects.size() > 0)
	var maxx := 0.0
	for r in rects:
		maxx = maxf(maxx, r.end.x)
	# contour at u=10.5 tiles = 336px, quantised to 8px sub-cells
	check(absf(maxx - 336.0) <= 8.0)
	# land (x >= 11 tiles) is never blocked
	for r in rects:
		check(r.end.x <= 344.0)

func test_free_tiles_stay_open() -> void:
	var g := Callable(self, "_straight")
	var rects := ShoreMath.blocked_rects(g, 16, func(t): return t == Vector2i(9, 3), 20.0)
	for r in rects:
		var in_tile := r.position.x >= 9 * 32.0 and r.end.x <= 10 * 32.0 and r.position.y >= 3 * 32.0 and r.end.y <= 4 * 32.0
		check(not in_tile)
