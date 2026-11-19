extends BaseTest

func test_gates() -> void:
	var g := StoryGate.load_gates()
	check(g.has("port_halden") and g.has("highlands") and g.has("vance"), "gates data has the city, highlands and Vance")
	var done := {}
	check(StoryGate.lock_message(g, "homestead", done) == "", "homestead is always open")
	check(StoryGate.lock_message(g, "farmland", done) == "", "farmland is free")
	check(StoryGate.lock_message(g, "pine_forest", done) == "", "forest is free")
	check(StoryGate.lock_message(g, "port_halden", done) != "", "city locked at the start")
	check(StoryGate.lock_message(g, "harbour", done) != "" and StoryGate.lock_message(g, "circuit", done) != "", "harbour and circuit locked at the start")
	done["vance_car"] = true
	check(StoryGate.lock_message(g, "port_halden", done) == "", "city opens with the Vance visit")
	check(StoryGate.lock_message(g, "highlands", done) != "", "highlands still locked")
	done["see_ledger"] = true
	check(StoryGate.lock_message(g, "highlands", done) == "", "highlands open after the ledger")
	check(StoryGate.lock_message(g, "vance", done) != "", "Vance yard locked until the debt is cleared")
	done["debt_free"] = true
	check(StoryGate.lock_message(g, "vance", done) == "", "Vance yard opens when debt free")
	check(StoryGate.lock_message(g, "unknown_region", {}) == "", "unknown regions are open")
	check(StoryGate.bypass(PackedStringArray(["--at=192,-2"])), "--at bypasses")
	check(StoryGate.bypass(PackedStringArray(["--car-demo"])), "demo flags bypass")
	check(not StoryGate.bypass(PackedStringArray()), "normal play does not bypass")
	var ids := ["homestead", "farmland", "port_halden", "vance"]
	check(StoryGate.open_regions(g, ids, {}).size() == 2, "two regions open at the start")
	var b := StoryGate.bounce_velocity(Vector2(100, 0), Vector2(0, 0), Vector2(10, 0))
	check(b.x < 0.0 and b.length() <= 60.0, "bounce points back, capped")
	# every gate step id exists in the story data
	var story: Dictionary = DataDB.load_json("story")
	var ids_in_story := {}
	for q in story["quests"]:
		for s in q["steps"]:
			ids_in_story[str(s["id"])] = true
	for k in g:
		check(ids_in_story.has(str(g[k]["needs"])), "gate step exists: " + k)
	# every gated region exists in regions.json
	var regs: Array = DataDB.load_json("regions")
	var rid := {}
	for r in regs:
		rid[str(r["id"])] = true
	for k in g:
		check(rid.has(k), "gated region exists: " + k)

func test_keeper() -> void:
	var g := StoryGate.load_gates()
	var k := StoryGate.Keeper.new(g, true)
	var r := k.step(Vector2(10, 10), "homestead", {}, 0.1)
	check(not r["bounce"], "open region: no bounce")
	r = k.step(Vector2(500, 10), "port_halden", {}, 0.1)
	check(r["bounce"] and (r["to"] as Vector2) == Vector2(10, 10), "locked: bounce to last safe spot")
	check(str(r["msg"]) != "", "first bounce shows the message")
	r = k.step(Vector2(500, 10), "port_halden", {}, 0.1)
	check(r["bounce"] and str(r["msg"]) == "", "message rate limited")
	r = k.step(Vector2(500, 10), "port_halden", {}, 3.5)
	check(str(r["msg"]) != "", "message returns after the cooldown")
	r = k.step(Vector2(500, 10), "port_halden", {"vance_car": true}, 0.1)
	check(not r["bounce"], "story step opens the road")
	var off := StoryGate.Keeper.new(g, false)
	check(not off.step(Vector2(1, 1), "port_halden", {}, 0.1)["bounce"], "disabled keeper never bounces")
	var fresh := StoryGate.Keeper.new(g, true)
	check(not fresh.step(Vector2(1, 1), "port_halden", {}, 0.1)["bounce"], "no safe spot yet (old save): no bounce")

func test_spots() -> void:
	var st := ChunkStream.new(1, null)
	var g := StoryGate.load_gates()
	var spots := StoryGate.spots(st.roads, st.regions, g)
	check(spots.size() > 0, "barricade spots found on the roads (%d)" % spots.size())
	var regions_hit := {}
	for sp in spots:
		regions_hit[str(sp["region"])] = true
		var ch := ChunkGrid.chunk_of_cell(sp["cell"])
		check(str(st.region_at(ch)["id"]) == str(sp["region"]), "spot lies in its gated region")
	check(regions_hit.has("port_halden"), "the city road is barricaded")
	check(StoryGate.spots(st.roads, st.regions, {}).is_empty(), "no gates, no spots")
	var again := StoryGate.spots(st.roads, st.regions, g)
	check(again.size() == spots.size(), "deterministic")
	print("gate spots: ", regions_hit.keys(), " n=", spots.size())
