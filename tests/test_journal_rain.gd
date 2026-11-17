extends BaseTest

func test_size_scales_with_difficulty() -> void:
	check(FishJournal.size_cm(0.8, 0.5) > FishJournal.size_cm(0.1, 0.5))
	check(FishJournal.size_cm(0.3, 1.0) > FishJournal.size_cm(0.3, 0.0))

func test_record_and_roundtrip() -> void:
	var j := FishJournal.new()
	check(j.record("carp", 40))
	check(not j.record("carp", 30))
	check(j.record("carp", 55))
	check_eq(j.entries["carp"]["count"], 3)
	check_eq(j.entries["carp"]["best"], 55)
	var j2 := FishJournal.new()
	j2.from_dict(j.to_dict())
	check_eq(j2.species_caught(), 1)
	check_eq(j2.entries["carp"]["best"], 55)
	check_eq(j.summary({"a": 1, "b": 2}), "Journal 1/2 species")

func test_rain_waters_crops() -> void:
	var f := FarmModel.new(DataDB.load_json("crops"))
	var seed_id := ""
	for k in DataDB.load_json("items"):
		if f.crop_for_seed(k) != "":
			seed_id = k
			break
	var c := Vector2i(3, 3)
	f.till(c)
	check(f.plant(c, seed_id, 0))
	f.rain_water()
	check(f.soil[c].watered)
	f.next_day()
	check_eq(f.soil[c].age, 1)
