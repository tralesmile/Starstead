extends BaseTest
## Sports venue jobs: pit crew (circuit pit office), groundskeeper and coach (Sports Hall).

const NEW := {"pit_crew": "circ_pit", "groundskeeper": "circ_hall", "sparring_partner": "circ_hall"}
const FAR := Vector2(9000, 9000)   # where rooms are built

func _m() -> JobModel:
	return JobModel.new(DataDB.load_json("jobs"))

func test_jobs_sit_in_public_circuit_venues_within_their_hours() -> void:
	var m := _m()
	for id in NEW:
		check_eq(m.place_of(id), NEW[id], id)
		check_eq(m.jobs[id]["ranks"].size(), 3, id)
		check(NEW[id] in InteriorModel.PUBLIC, id)
		check(CircuitModel.kind_of(NEW[id]) != "", id)
		check(int(m.jobs[id]["hours"]["end"]) <= int(ShopHours.cfg()[NEW[id]]["close"]), id + " ends by closing time")
		check(ShiftGame.title_for(id, String(m.jobs[id]["game"])) != ShiftGame.title_for("", String(m.jobs[id]["game"])), id + " has its own title")

func test_balance_ladder() -> void:
	var jobs = DataDB.load_json("jobs")
	for id in NEW:
		var prev := 0.0
		for r in 3:
			var v := EconomyAudit.job_per_energy(jobs[id], r)
			check(v > prev and v >= 1.0 and v <= 4.5, "%s rank %d: %.2f per energy" % [id, r, v])
			prev = v

func test_sports_hall_offers_by_time_and_rep() -> void:
	var m := _m()
	var rep := {"honest": 10, "street": 0}
	check_eq(m.pick_at("circ_hall", 8.0, rep, 100.0, {}), "groundskeeper")
	check_eq(m.pick_at("circ_hall", 15.0, rep, 100.0, {}), "sparring_partner")
	check_eq(m.pick_at("circ_hall", 15.0, {"honest": 0}, 100.0, {}), "sparring_partner", "afternoon refusal is about rep, not the morning job's hours")
	check_eq(m.pick_at("circ_pit", 12.0, rep, 100.0, {}), "pit_crew")
	check_eq(m.can_work("pit_crew", 12.0, {"honest": 9}, 100.0), "rep")
	check_eq(m.can_work("pit_crew", 20.0, rep, 100.0), "hours")

func test_perks() -> void:
	var m := _m()
	var items: Dictionary = DataDB.load_json("items")
	check_eq(m.perk("groundskeeper", 0)["item"], "fertiliser")
	check(items.has("fertiliser"))
	check_eq(m.perk("groundskeeper", 2)["qty"], 4)
	for key in ["car_fuel", "car_health"]:
		check(m.perk("pit_crew", 1)[key] > m.perk("pit_crew", 0)[key], key)
		check_eq(float(m.perk("chef", 2)[key]), 0.0, "other jobs leave the car alone")
	var low := JobModel.service_car(0.0, 10.0, m.perk("pit_crew", 0))
	check(is_equal_approx(low["fuel"], VehicleMath.FUEL_MAX * 0.35))
	check(is_equal_approx(low["health"], 35.0))
	var top := JobModel.service_car(1.0, 10.0, m.perk("pit_crew", 2))
	check_eq(top["fuel"], VehicleMath.FUEL_MAX)
	check_eq(top["health"], VehicleMath.HEALTH_MAX)

func test_ring_training() -> void:
	var m := _m()
	check_eq(m.ring_bonus({}), 0.0)
	check_eq(m.ring_bonus({"pit_crew": 500}), 0.0)
	check(is_equal_approx(m.ring_bonus({"sparring_partner": 12}), 0.05))
	check(is_equal_approx(m.ring_bonus({"sparring_partner": 160}), 0.13))

func test_doorstep_and_indoor_reach() -> void:
	var spots := {}
	for b in CircuitModel.buildings():
		spots[b["id"]] = JobModel.door_spot(b)
	for b in CircuitModel.buildings():
		var id := String(b["id"])
		var doorstep := (Vector2(b["door"]) + Vector2(0.5, 0.5)) * 32.0
		check(JobModel.in_reach(id, "", spots, doorstep), "J works on the doorstep of " + id)
		var other := "circ_hall" if id == "circ_pit" else "circ_pit"
		check(not JobModel.in_reach(other, "", spots, doorstep), "only one venue per doorstep")
		check(JobModel.in_reach(id, id, spots, FAR), "J works inside " + id)
		check(not JobModel.in_reach(other, id, spots, FAR))
		check(not JobModel.in_reach(id, "", spots, FAR), "nothing from far away")
	check(not JobModel.in_reach("city_house2", "city_house2", spots, FAR), "no building job from inside a home")

func test_join_prompt() -> void:
	check_eq(JobModel.join_prompt("E: a", "J: b"), "E: a    J: b")
	check_eq(JobModel.join_prompt("", "J: b"), "J: b")
	check_eq(JobModel.join_prompt("E: a", ""), "E: a")
