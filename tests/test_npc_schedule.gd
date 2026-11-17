extends BaseTest

func _data() -> Dictionary:
	return DataDB.load_json("npcs")

func _farmer() -> Dictionary:
	for n in _data()["npcs"]:
		if n["id"] == "farmer":
			return n
	return {}

func test_four_npcs_with_fields() -> void:
	var d := _data()
	check_eq(d["npcs"].size(), 4)
	for n in d["npcs"]:
		check(n.has("id") and n.has("name") and n.has("home") and n.has("schedule"), str(n.get("id")))

func test_all_hours_covered_no_gaps() -> void:
	var d := _data()
	for n in d["npcs"]:
		var h := 0.0
		while h < 24.0:
			var e := NpcSchedule.current_entry(n, h)
			check(not e.is_empty(), "%s gap at %s" % [n["id"], h])
			h += 0.25
		# exactly one entry per sample (no overlaps)
		h = 0.0
		while h < 24.0:
			var c := 0
			for e in n["schedule"]:
				if NpcSchedule._covers(e, h):
					c += 1
			check_eq(c, 1, "%s overlap at %s" % [n["id"], h])
			h += 0.25

func test_places_exist() -> void:
	var d := _data()
	for n in d["npcs"]:
		for e in n["schedule"]:
			check(e["place"] == "home" or d["places"].has(e["place"]), "%s %s" % [n["id"], e["place"]])

func test_wrap_midnight_sleep() -> void:
	var f := _farmer()
	check(NpcSchedule.is_sleeping(f, 23.0))
	check(NpcSchedule.is_sleeping(f, 0.0))
	check(NpcSchedule.is_sleeping(f, 3.5))
	check(not NpcSchedule.is_sleeping(f, 9.0))
	check(NpcSchedule.is_sleeping(f, 27.0)) # 3:00 next day
	check(not NpcSchedule.is_sleeping(f, 5.5))

func test_target_cell() -> void:
	var d := _data()
	var f := _farmer()
	check_eq(NpcSchedule.target_cell(f, 8.0, d["places"]), Vector2i(12, 10))
	check_eq(NpcSchedule.target_cell(f, 2.0, d["places"]), Vector2i(9, 8))
	check_eq(NpcSchedule.target_cell({"home": [1, 2], "schedule": []}, 5.0, {}), Vector2i(1, 2))

func test_step_toward_no_overshoot() -> void:
	check_eq(NpcSchedule.step_toward(Vector2(0, 0), Vector2(10, 0), 2.0, 1.0), Vector2(2, 0))
	check_eq(NpcSchedule.step_toward(Vector2(9, 0), Vector2(10, 0), 5.0, 1.0), Vector2(10, 0))
	check_eq(NpcSchedule.step_toward(Vector2(3, 3), Vector2(3, 3), 5.0, 1.0), Vector2(3, 3))
	check_eq(NpcSchedule.step_toward(Vector2(0, 0), Vector2(10, 0), 2.0, 0.0), Vector2(0, 0))
