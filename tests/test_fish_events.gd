extends BaseTest

func _cfg() -> Dictionary:
	return DataDB.load_json("fish_events")

func _table() -> Dictionary:
	return DataDB.load_json("fish")

func test_every_event_is_a_legendary_with_a_note() -> void:
	for id in _cfg()["events"]:
		check(_table().has(id) and bool(_table()[id].get("legendary", false)), id)
		check(String(_cfg()["events"][id]).length() > 20, id)
		check(DataDB.load_json("items").has(id) and DataDB.load_json("item_icons").has(id), "item + icon " + id)

func test_sightings_are_rare_in_season_and_stop_once_caught() -> void:
	var seen := {}
	var days := 0
	for day in range(1, 225):
		var season: int = ((day - 1) / 28) % 4
		var id := FishEvents.for_day(_cfg(), _table(), day, season, [])
		if id == "":
			continue
		days += 1
		seen[id] = true
		check(day >= 8)
		var ok := false
		for s in _table()[id].seasons:
			ok = ok or int(s) == season
		check(ok, "%s out of season on day %d" % [id, day])
	check(days >= 20 and days <= 50, "sightings %d" % days)
	check_eq(seen.size(), 4)
	check_eq(FishEvents.for_day(_cfg(), _table(), 8, 0, ["river_king", "lantern_eel", "anvil_sturgeon", "glass_marlin"]), "")

func test_hit_needs_the_spot_and_the_hour() -> void:
	var eel: Dictionary = _table()["lantern_eel"]
	check(FishEvents.hits(_cfg(), eel, Vector2i(12, 10), Vector2i(10, 10), 21.0))
	check(not FishEvents.hits(_cfg(), eel, Vector2i(20, 10), Vector2i(10, 10), 21.0))
	check(not FishEvents.hits(_cfg(), eel, Vector2i(10, 10), Vector2i(10, 10), 12.0))
	check(not FishEvents.hits(_cfg(), eel, Vector2i(0, 0), Vector2i(-1, -1), 21.0))

func test_boost_puts_the_sighted_fish_on_the_hook_even_in_shallows() -> void:
	var hits := 0
	for i in 200:
		var f := Fishing.new(i)
		if f.cast(-1.0, _table(), 0, {}, {"event_fish": "lantern_eel", "event_boost": 0.4}):
			hits += 1 if f.fish_id == "lantern_eel" else 0
	check(hits > 55 and hits < 105, "boost hits %d of 200" % hits)

func test_spot_search_finds_the_nearest_open_water() -> void:
	var sdf := func(c: Vector2i) -> float: return -3.0 if c.x >= 7 else 2.0
	check_eq(FishEvents.find_spot(Vector2i(0, 0), sdf).x, 7)
	check_eq(FishEvents.find_spot(Vector2i(0, 0), func(_c): return 5.0, 6), Vector2i(-1, -1))

func test_journal_fits_the_screen() -> void:
	var n := _table().size()
	var rects: Array = []
	for i in n:
		var r := FishJournal.cell_rect(i, n)
		check(FishJournal.PANEL.encloses(r), "row %d %s" % [i, r])
		check(r.end.y < FishJournal.PANEL.end.y - 18.0, "row %d covers the footer" % i)
		for o in rects:
			check(not r.intersects(o), "overlap %d" % i)
		rects.append(r)
	check(Rect2(0, 0, 640, 360).encloses(FishJournal.PANEL.grow(6)))
