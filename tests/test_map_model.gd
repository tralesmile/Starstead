extends BaseTest

func test_to_map_roundtrip_and_bounds() -> void:
	var p := MapModel.to_map(Vector2(MapModel.X0, MapModel.Y0))
	check_eq(p, Vector2.ZERO)
	var q := MapModel.to_map(Vector2(MapModel.X0 + MapModel.SPAN - 1, MapModel.Y0 + MapModel.SPAN - 1))
	check(q.x < MapModel.N and q.y < MapModel.N)
	check_eq(MapModel.from_map(MapModel.to_map(Vector2(32, 32))), Vector2(32, 32))

func test_clamp_keeps_marker_inside() -> void:
	var c := MapModel.clamp_px(Vector2(-5, 500))
	check_eq(c, Vector2(0, MapModel.N - 1.0))

func test_pois_have_fuel_town_and_circuit() -> void:
	var list := MapModel.pois(Vector2i(96, -157), {"vance": Vector2i(288, -96)})
	var kinds := {}
	for p in list:
		kinds[p["kind"]] = true
	for k in ["home", "town", "fuel", "sea", "race", "cave", "place"]:
		check(kinds.has(k), "missing kind " + k)

func test_nearest_fuel_picks_closest() -> void:
	var list := MapModel.pois(Vector2i(RoadNet.NO_CELL, 0), {})
	var f := MapModel.nearest_fuel(Vector2i(30, 30), list)
	check_eq(f["name"], "Workshop (fuel)")
	var g := MapModel.nearest_fuel(CityModel.SPAWN, list)
	check_eq(g["name"], "Garage (fuel)")
	check(MapModel.fuel_prompt(Vector2i(30, 30), list).begins_with("Workshop"))
