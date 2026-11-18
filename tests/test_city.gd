extends BaseTest

func test_twelve_buildings_unique_and_doors_walkable() -> void:
	var bs := CityModel.buildings()
	check_eq(bs.size(), 12, "12 buildings")
	var ids := {}
	var taken := {}
	for b in bs:
		check(not ids.has(b["id"]), "unique id " + b["id"])
		ids[b["id"]] = true
		check(CityModel.in_rect(b["cell"]), "inside city " + b["id"])
		for c in CityModel.building_cells(b):
			check(not taken.has(c), "footprints do not overlap " + b["id"])
			taken[c] = true
			check_eq(CityModel.tile_kind(c), "", "footprint on park land " + b["id"])
	for b in bs:
		var d: Vector2i = b["door"]
		check(not taken.has(d), "door cell is free " + b["id"])
		check_eq(CityModel.tile_kind(d), "sidewalk", "door on a sidewalk " + b["id"])

func test_civic_kinds_have_interiors() -> void:
	for k in ["shop", "police", "cafe", "bank", "hospital", "garage", "hall"]:
		var id: String = "city_" + k
		check(id in InteriorModel.PUBLIC, id + " public")
		var l := InteriorModel.layout(InteriorModel.kind_for(id))
		check(l["furniture"].size() > 3, id + " furnished")
		var door := Rect2((int(l["door_x"])) * 32.0, (int(l["h"]) - 1) * 32.0, 32, 32)
		for r in InteriorModel.solid_rects(l):
			check(not r.intersects(door), id + " door row clear")
	check_eq(InteriorModel.kind_for("city_apt_a"), "house", "apartments are robbable houses")
	check(not ("city_apt_a" in InteriorModel.PUBLIC), "apartments not public")

func test_services_wired_to_actions() -> void:
	var want := {"city_shop": "shop", "city_bank": "bank", "city_police": "fine", "city_hospital": "heal", "city_cafe": "coffee", "city_hall": "notice"}
	for id in want:
		var l := InteriorModel.layout(InteriorModel.kind_for(id))
		var found := false
		for f in l["furniture"]:
			if f["action"] == want[id]:
				found = true
		check(found, id + " has " + want[id])

func test_streets_connect_to_spine() -> void:
	check_eq(CityModel.tile_kind(Vector2i(192, 0)), "asphalt", "main crossing")
	check_eq(CityModel.tile_kind(Vector2i(192, 31)), "asphalt", "avenue reaches the spine road")
	check(CityModel.in_rect(Vector2i(192, 33)), "avenue strip forced to land")
	check_eq(CityModel.tile_kind(Vector2i(180, -2)), "sidewalk")
	check_eq(CityModel.tile_kind(Vector2i(100, 0)), "")

func test_worldgen_paints_city_and_keeps_it_dry() -> void:
	var s := ChunkStream.new(1)
	for c in [Vector2i(192, 0), Vector2i(166, -22), Vector2i(218, 28), Vector2i(180, -2), Vector2i(191, 33)]:
		var t := s.tile_at(c)
		check(not WorldGen.is_water(t), "dry at %s" % [c])
	check_eq(s.tile_at(Vector2i(192, 0)), WorldGen.ASPHALT)
	check(WorldGen.is_road(s.tile_at(Vector2i(180, -2))), "sidewalk counts as road")
	check_eq(s.tile_at(Vector2i(192, 1)), WorldGen.ASPHALT, "crosses the chunk border cleanly")
	for b in CityModel.buildings():
		for c in CityModel.building_cells(b):
			var g := s.gen_for(ChunkGrid.chunk_of_cell(c))
			var l := ChunkGrid.local_cell(c)
			check(not (l in g.trees) and not (l in g.rocks) and not (l in g.bushes), "no props under " + b["id"])

func test_bank() -> void:
	var r := CityServices.deposit(300, 100)
	check_eq(r["cash"], 0); check_eq(r["bal"], 400)
	r = CityServices.withdraw(10, 400, 150)
	check_eq(r["cash"], 160); check_eq(r["bal"], 250)
	r = CityServices.deposit(50, 0, 500)
	check_eq(r["moved"], 50, "cannot deposit more than you hold")
	check_eq(CityServices.daily_interest(1000), 20)
	check_eq(CityServices.daily_interest(1000000), CityServices.INTEREST_CAP)

func test_clinic_police_coffee() -> void:
	check_eq(CityServices.heal_cost(100.0), 0)
	check_eq(CityServices.heal_cost(40.0), 36)
	var r := CityServices.clinic(100, 40.0)
	check_eq(r["energy"], 100.0); check_eq(r["cash"], 64)
	r = CityServices.clinic(18, 40.0)
	check_eq(r["paid"], 18); check(r["energy"] > 69.0 and r["energy"] < 71.0, "partial heal")
	check_eq(CityServices.pay_fine(300, 2)["cleared"], true)
	check_eq(CityServices.pay_fine(300, 2)["cash"], 100)
	check_eq(CityServices.pay_fine(100, 3)["cleared"], false, "450 > 100")
	check_eq(CityServices.pay_fine(100, 0)["cleared"], false)
	check_eq(CityServices.coffee(5, 10.0)["ok"], false)
	check_eq(CityServices.coffee(50, 90.0)["energy"], 100.0)

func test_props_not_on_avenue() -> void:
	for p in CityModel.props():
		if p["kind"] == "lamp":
			check(not CityModel.is_asphalt(p["cell"]), "lamp off the road")
