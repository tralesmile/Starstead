extends BaseTest
## The sun moves a building's shadow from the west (morning) to the east (evening).

func test_reach_swings_with_the_sun() -> void:
	check(BuildingShadow.reach(60.0, 100.0) < -20.0, "long westward in the early morning")
	check(BuildingShadow.reach(720.0, 100.0) > 20.0, "long eastward in the evening")
	check_eq(BuildingShadow.reach(390.0, 100.0), BuildingShadow.NOON_REACH)
	check(absf(BuildingShadow.reach(0.0, 400.0)) <= BuildingShadow.MAX_REACH, "capped at the horizon")

func test_taller_buildings_cast_further() -> void:
	check(BuildingShadow.reach(660.0, 140.0) > BuildingShadow.reach(660.0, 70.0), "taller reaches further")

func test_cast_points_stay_on_the_shadow_side() -> void:
	var pts := BuildingShadow.cast_points(720.0, -60.0, 60.0, 100.0)
	for p in pts:
		check(p.x >= 53.0 and p.x <= 60.0 + BuildingShadow.MAX_REACH, "beside the east wall")
	for p in BuildingShadow.cast_points(60.0, -60.0, 60.0, 100.0):
		check(p.x <= -53.0, "beside the west wall in the morning")

func test_outlines_are_simple_polygons() -> void:
	for m in [0.0, 200.0, 390.0, 600.0, 780.0, 1200.0]:
		check(not Geometry2D.triangulate_polygon(BuildingShadow.cast_points(m, -40.0, 40.0, 90.0)).is_empty(), "cast draws at %d" % int(m))
		check(not Geometry2D.triangulate_polygon(BuildingShadow.cast_points(m, -40.0, 40.0, 90.0, 3.0)).is_empty(), "soft layer draws at %d" % int(m))
	check(not Geometry2D.triangulate_polygon(BuildingShadow.contact_points(-40.0, 40.0, 3.0)).is_empty(), "contact draws")
