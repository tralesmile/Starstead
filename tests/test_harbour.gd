extends BaseTest

func test_sea_and_quay_do_not_overlap() -> void:
	for x in range(190, 260):
		for y in range(90, 130):
			var c := Vector2i(x, y)
			check(not (HarbourModel.is_sea(c) and HarbourModel.is_quay(c)), "no overlap %s" % c)

func test_road_end_is_land_and_quay_touches_it() -> void:
	check(not HarbourModel.is_sea(Vector2i(224, 96)), "road end dry")
	check(HarbourModel.is_quay(Vector2i(224, 100)), "quay below the road end")
	check(HarbourModel.is_sea(Vector2i(224, 130)), "open sea south")
	check(HarbourModel.is_quay(Vector2i(224, 118)), "pier reaches out")
	check(HarbourModel.is_deep(Vector2i(210, 125)), "deep water far out")

func test_props_on_land_or_water_and_pier_head_cells() -> void:
	for p in HarbourModel.props():
		check(HarbourModel.is_quay(p["cell"]) or p["kind"] == "boat", "prop on quay: " + p["kind"])
	check(HarbourModel.is_quay(HarbourModel.CRATE_CELL), "crate on the pier head")
	check(HarbourModel.is_quay(HarbourModel.BOARD), "board on the quay")
	check(CityModel.in_rect(HarbourModel.FENCE_CELL) and CityModel.tile_kind(HarbourModel.FENCE_CELL) == "", "fence barrel on city park land")

func test_world_gen_paints_sea_and_quay() -> void:
	var g := WorldGen.new(1, Vector2i(6, 5))
	var sea := Vector2i(210, 125) - ChunkGrid.origin_cell(Vector2i(6, 5))
	var quay := Vector2i(224, 110) - ChunkGrid.origin_cell(Vector2i(6, 5))
	check(WorldGen.is_water(g.tiles[sea.y * WorldGen.SIZE + sea.x]), "sea tile is water")
	check(WorldGen.is_road(g.tiles[quay.y * WorldGen.SIZE + quay.x]), "pier is paved")
	check(g.sdf_at(sea.x, sea.y) < -3.0, "deep sea")

func test_sea_fish_only_in_sea() -> void:
	var table: Dictionary = DataDB.load_json("fish")
	for i in 20:
		var f := Fishing.pick_fish(table, "deep", 1, i / 20.0, true)
		check(bool(table[f].get("sea", false)), "sea pick is a sea fish " + f)
		var l := Fishing.pick_fish(table, "deep", 1, i / 20.0, false)
		check(not bool(table[l].get("sea", false)), "lake pick is a lake fish " + l)
	check_eq(Fishing.legendary_for(table, "deep", {"rain": 1.0, "hour": 20.0, "caught": [], "sea": true}, 0.0), "", "no lake legend in the sea")

func test_contest_days_and_rank() -> void:
	check(HarbourModel.is_contest_day(6) and HarbourModel.is_contest_day(13) and not HarbourModel.is_contest_day(7), "every 7th day")
	check(HarbourModel.contest_open(6, 9.0) and not HarbourModel.contest_open(6, 7.0) and not HarbourModel.contest_open(6, 18.0), "hours")
	var rv := HarbourModel.rival_scores(6)
	check_eq(rv.size(), 3, "3 rivals")
	check_eq(HarbourModel.rival_scores(6), rv, "deterministic")
	check_eq(HarbourModel.rank(9999, rv), 1, "huge score wins")
	check_eq(HarbourModel.rank(0, rv), 4, "zero is last")
	check_eq(HarbourModel.prize(1), 300, "first prize")
	check_eq(HarbourModel.prize(4), 0, "no prize for 4th")

func test_contest_flow() -> void:
	var h := HarbourState.new()
	check(not h.enter(5, 9.0, 100)["ok"], "not a contest day")
	check(not h.enter(6, 9.0, 10)["ok"], "too poor")
	var r := h.enter(6, 9.0, 100)
	check(r["ok"], "entered")
	check_eq(r["money"], 75, "fee paid")
	check(not h.enter(6, 9.5, 100)["ok"], "no double entry")
	check(h.add_catch(6, 10.0, 40), "catch counts")
	check(not h.add_catch(6, 19.0, 40), "late catch does not")
	check(not h.finish(6, 12.0)["done"], "not over yet")
	h.add_catch(6, 12.0, 500)
	var f := h.finish(6, 18.5)
	check(f["done"], "settled")
	check_eq(f["rank"], 1, "540 cm wins")
	check_eq(f["prize"], 300, "prize")
	check(not h.finish(6, 19.0)["done"], "settled once")

func test_crate_nights() -> void:
	check(HarbourModel.crate_available(1, 22.0) and HarbourModel.crate_available(4, 2.0), "every third night")
	check(not HarbourModel.crate_available(1, 12.0) and not HarbourModel.crate_available(2, 22.0), "not by day / other nights")
	var h := HarbourState.new()
	check(h.take_crate(1, 22.0), "taken")
	check(not h.take_crate(1, 23.0), "only once a night")
	check(HarbourModel.crate_pay(1) > 200 and HarbourModel.too_hot(3) and not HarbourModel.too_hot(2), "pay and heat")

func test_state_round_trip() -> void:
	var h := HarbourState.new()
	h.enter(6, 9.0, 100)
	h.add_catch(6, 10.0, 77)
	h.take_crate(1, 22.0)
	var h2 := HarbourState.new()
	h2.from_dict(h.to_dict())
	check_eq(h2.score, 77, "score saved")
	check(h2.entered(6), "entry saved")
	check(not h2.take_crate(1, 23.0), "crate pickup saved")
