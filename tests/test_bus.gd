extends BaseTest

func _stops() -> Array:
	return BusModel.make_stops(Vector2i(96, -157), {"farmland": Vector2i(96, 96), "lumber": Vector2i(-96, -32), "vance": Vector2i(288, -96)}, Vector2i(38, 32))

func test_stops_cover_the_map() -> void:
	var ids := []
	for s in _stops():
		ids.append(s["id"])
	for id in ["home", "city", "harbour", "circuit", "mine", "farmland", "lumber", "vance"]:
		check(id in ids)

func test_fare_grows_with_distance_and_has_minimum() -> void:
	check_eq(BusModel.fare(Vector2i(0, 0), Vector2i(0, 0)), BusModel.MIN_FARE)
	check(BusModel.fare(Vector2i(0, 0), Vector2i(200, 0)) > BusModel.fare(Vector2i(0, 0), Vector2i(50, 0)))
	check_eq(BusModel.fare(Vector2i(0, 0), Vector2i(90, 0)), BusModel.fare(Vector2i(90, 0), Vector2i(0, 0)))

func test_service_hours_and_wait() -> void:
	check(BusModel.in_service(0.0))             # 06:00
	check(BusModel.in_service(16.0 * 60.0 + 59.0))  # 22:59
	check(not BusModel.in_service(17.0 * 60.0))   # 23:00
	check_eq(BusModel.wait_minutes(0.0), 0)
	check_eq(BusModel.wait_minutes(1.0), 29)
	check_eq(BusModel.wait_minutes(29.5), 1)
	check_eq(BusModel.wait_minutes(30.0), 0)

func test_options_block_locked_and_poor() -> void:
	var rows := BusModel.options(_stops(), "home", 20, func(cell: Vector2i) -> bool: return cell.x < 250)
	check_eq(rows.size(), _stops().size() - 1)
	var by := {}
	for r in rows:
		by[r["id"]] = r
	check_eq(by["vance"]["why"], "road closed")
	check(not by["vance"]["ok"])
	check(by["farmland"]["ok"] == (20 >= by["farmland"]["fare"]))
	var broke := BusModel.options(_stops(), "home", 0, func(_c: Vector2i) -> bool: return true)
	for r in broke:
		check(not r["ok"])

func test_ride_is_never_faster_than_waiting_and_arrival_adds_wait() -> void:
	var a := Vector2i(0, 0)
	var b := Vector2i(180, 0)
	check_eq(BusModel.ride_minutes(a, b), 40)
	check_eq(BusModel.arrival_minutes(1.0, a, b), 1.0 + 29.0 + 40.0)

func test_nearest_stop_reach() -> void:
	var st := _stops()
	var cell := Vector2(st[1]["cell"]) + Vector2(1.0, 0.5)
	check_eq(BusModel.nearest_stop(st, cell, BusStopsView.REACH)["id"], "city")
	check(BusModel.nearest_stop(st, Vector2(0, 0), BusStopsView.REACH).is_empty())
