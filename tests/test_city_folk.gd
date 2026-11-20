extends BaseTest

func test_walkable_surfaces() -> void:
	var b := CityFolk.blocked_cells()
	check(CityFolk.walkable(Vector2i(180, -2), b), "street sidewalk")
	check(CityFolk.walkable(Vector2i(190, 10), b), "avenue sidewalk")
	check(not CityFolk.walkable(Vector2i(180, 0), b), "street asphalt is for cars")
	check(not CityFolk.walkable(Vector2i(192, 10), b), "avenue asphalt")
	check(CityFolk.walkable(Vector2i(188, 0), b), "zebra crossing")
	check(not CityFolk.walkable(Vector2i(202, 6), b), "fountain")
	check(not CityFolk.walkable(Vector2i(170, -3), b), "inside a building")
	check(not CityFolk.walkable(Vector2i(100, 0), b), "outside the city")

func test_spots_are_walkable_and_reachable() -> void:
	var b := CityFolk.blocked_cells()
	var g := CityFolk.build_grid(b)
	var sp := CityFolk.spots()
	check(sp.size() >= 12, "doors + benches + plazas")
	var kinds := {}
	for s in sp:
		kinds[s["kind"]] = true
		check(CityFolk.walkable(s["cell"], b), "spot %s" % str(s["cell"]))
	check(kinds.has("door") and kinds.has("bench") and kinds.has("plaza"))
	var start: Vector2i = sp[0]["cell"]
	for s in sp:
		var r := CityFolk.route(g, start, s["cell"])
		check(r.size() > 0, "route to %s" % str(s["cell"]))
		for c in r:
			check(CityFolk.walkable(c, b), "route cell %s" % str(c))

func test_route_crosses_only_at_zebras() -> void:
	var b := CityFolk.blocked_cells()
	var g := CityFolk.build_grid(b)
	var r := CityFolk.route(g, Vector2i(180, -2), Vector2i(180, 2))   # straight across the street
	check(r.size() > 5, "has to detour to a crossing")
	var crossed := false
	for c in r:
		if CityModel.is_asphalt(c):
			check(CityModel.zebra(c) != 0, "asphalt only on zebra %s" % str(c))
			crossed = true
	check(crossed)

func test_density_day_night() -> void:
	check(CityFolk.density(12.0) > CityFolk.density(2.0))
	check(CityFolk.density(8.0) > CityFolk.density(23.0))
	check(CityFolk.density(26.0) == CityFolk.density(2.0), "wraps")
	check(CityFolk.cop_count(12.0) == 2 and CityFolk.cop_count(3.0) == 1)

func test_dwell_ranges() -> void:
	check(CityFolk.dwell("bench", 0.0) > CityFolk.dwell("door", 1.0) - 0.01)
	check(is_equal_approx(CityFolk.dwell("door", 0.5), 5.0))
	check(CityFolk.dwell("none", 0.5) == 0.0)

func test_active_radius() -> void:
	check(CityFolk.active(CityFolk.CENTER))
	check(CityFolk.active(Vector2i(192, 40)))
	check(not CityFolk.active(Vector2i(20, 14)), "homestead is far")
