extends BaseTest

func _r() -> RaceModel:
	var r := RaceModel.new([Vector2(100, 0), Vector2(100, 100), Vector2(0, 0)], 2, 10.0)
	r.add_racer("a")
	r.add_racer("b")
	return r

func _lap(r: RaceModel, id: String, t0: float) -> void:
	r.update(id, Vector2(100, 0), t0 + 1.0)
	r.update(id, Vector2(100, 100), t0 + 2.0)
	r.update(id, Vector2(0, 0), t0 + 3.0)

func test_checkpoints_in_order() -> void:
	var r := _r()
	check(not r.update("a", Vector2(100, 100), 1.0))  # wrong order
	check(r.update("a", Vector2(105, 0), 1.0))
	check_eq(r.racers["a"]["cp"], 1)

func test_lap_timing_and_finish() -> void:
	var r := _r()
	_lap(r, "a", 0.0)
	check_eq(r.racers["a"]["lap"], 1)
	check_eq(r.racers["a"]["best_lap"], 3.0)
	check(not r.is_finished("a"))
	_lap(r, "a", 3.0)
	check(r.is_finished("a"))
	check_eq(r.best_time, 6.0)

func test_ranking_by_progress() -> void:
	var r := _r()
	r.update("a", Vector2(100, 0), 1.0)
	check_eq(r.ranking(), ["a", "b"])
	check_eq(r.place("b"), 2)
	r.update("b", Vector2(100, 0), 2.0)
	r.update("b", Vector2(100, 100), 3.0)
	check_eq(r.place("b"), 1)

func test_distance_breaks_ties() -> void:
	var r := _r()
	r.update("a", Vector2(100, 50), 1.0)
	r.update("b", Vector2(100, 400), 1.0)
	check_eq(r.place("a"), 1)

func test_finish_beats_unfinished_and_earlier_wins() -> void:
	var r := _r()
	_lap(r, "b", 0.0)
	_lap(r, "b", 3.0)
	_lap(r, "a", 0.0)
	check_eq(r.place("b"), 1)

func test_payout_and_record_and_serialize() -> void:
	var r := _r()
	check_eq(r.payout_for_place(1), 200)
	check_eq(r.payout_for_place(3), 50)
	check_eq(r.payout_for_place(4), 0)
	check(r.record_time(10.0))
	check(not r.record_time(12.0))
	check(r.record_time(9.5))
	var r2 := RaceModel.new()
	r2.load_data(r.serialize())
	check_eq(r2.best_time, 9.5)

func test_gate_near() -> void:
	var gates := [Vector2(0, 0), Vector2(500, 0)]
	check_eq(RaceModel.gate_near(Vector2(40, 10), gates), 0)
	check_eq(RaceModel.gate_near(Vector2(470, 0), gates), 1)
	check_eq(RaceModel.gate_near(Vector2(250, 0), gates), -1)
