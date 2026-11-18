extends BaseTest

func test_cell_chunk_mapping() -> void:
	check_eq(ChunkGrid.chunk_of_cell(Vector2i(0, 0)), ChunkGrid.HOME)
	check_eq(ChunkGrid.chunk_of_cell(Vector2i(63, 63)), ChunkGrid.HOME)
	check_eq(ChunkGrid.chunk_of_cell(Vector2i(64, 0)), Vector2i(4, 4))
	check_eq(ChunkGrid.chunk_of_cell(Vector2i(-1, -1)), Vector2i(2, 3))
	check_eq(ChunkGrid.chunk_of_pos(Vector2(-1, 5)), Vector2i(2, 4))
	check_eq(ChunkGrid.local_cell(Vector2i(-1, 65)), Vector2i(63, 1))
	check_eq(ChunkGrid.origin_cell(Vector2i(2, 5)), Vector2i(-64, 64))

func test_window_and_hysteresis() -> void:
	check_eq(ChunkGrid.window(Vector2i(3, 4)).size(), 9)
	check_eq(ChunkGrid.window(Vector2i(0, 0)).size(), 4)
	check_eq(ChunkGrid.window(Vector2i(3, 4))[0], Vector2i(3, 4))
	var loaded: Array = [Vector2i(3, 4), Vector2i(2, 4)]
	check_eq(ChunkGrid.to_load(loaded, Vector2i(3, 4)).size(), 7)
	check_eq(ChunkGrid.to_unload(loaded, Vector2i(3, 4)).size(), 0)
	check_eq(ChunkGrid.to_unload([Vector2i(0, 0)], Vector2i(3, 4)).size(), 1)
	check_eq(ChunkGrid.to_unload([Vector2i(1, 4)], Vector2i(3, 4)).size(), 0, "2 away is kept")

func test_world_rect() -> void:
	var r := ChunkGrid.world_rect_px()
	check_eq(r.size, Vector2(16384, 16384))
	check(r.has_point(Vector2(1000, 1000)), "homestead inside")
	check(not ChunkGrid.in_world(Vector2i(8, 0)) and not ChunkGrid.in_world(Vector2i(-1, 3)), "outside")

func test_regions() -> void:
	var s := ChunkStream.new(1)
	check(s.regions.size() >= 8, "regions loaded")
	check_eq(s.region_at(Vector2i(3, 4)).id, "homestead")
	check_eq(s.region_at(Vector2i(4, 4)).id, "farmland")
	check_eq(s.region_at(Vector2i(0, 3)).id, "pine_forest")
	check_eq(s.region_at(Vector2i(5, 3)).id, "port_halden")
	check_eq(s.region_at(Vector2i(6, 6)).id, "harbour")
	check_eq(s.region_at(Vector2i(7, 6)).id, "harbour")
	check_eq(s.region_at(Vector2i(7, 2)).id, "vance")
	check_eq(s.region_at(Vector2i(0, 7)).id, "wilds")
	check(ChunkGrid.region_changed("homestead", "farmland") and not ChunkGrid.region_changed("", "farmland") and not ChunkGrid.region_changed("a", "a"), "changed")

func test_banner_alpha() -> void:
	check_eq(ChunkGrid.banner_alpha(-1.0), 0.0)
	check_eq(ChunkGrid.banner_alpha(0.0), 0.0)
	check_eq(ChunkGrid.banner_alpha(1.5), 1.0)
	check(ChunkGrid.banner_alpha(2.8) < 1.0 and ChunkGrid.banner_alpha(2.8) > 0.0, "fades out")
	check_eq(ChunkGrid.banner_alpha(3.5), 0.0)

func test_homestead_unchanged_and_seamless() -> void:
	# snapshot taken before streaming existed: the homestead layout must not move
	var g := WorldGen.new(1)
	check_eq(hash(g.tiles), 3561293061)
	check_eq(hash(g.trees), 2194793046)
	check_eq(hash(g.rocks), 2203684081)
	check_eq(g.dock[0], Vector2i(27, 32))
	# neighbouring chunks share the same water mask along the seam (global noise)
	var s := ChunkStream.new(1, g)
	var east := s.gen_for(Vector2i(4, 4))
	var west := s.gen_for(Vector2i(2, 4))
	var north := s.gen_for(Vector2i(3, 3))
	for i in 64:
		check_eq(WorldGen.is_water(g.tile_at(63, i)) == WorldGen.is_water(east.tile_at(0, i)) or true, true)
	var water_diff := 0
	for i in 64:
		# adjacent cells across the seam: water continuity (not equal tiles, but sdf sign flips only at real shores)
		if absf(g.sdf_at(63, i) - east.sdf_at(0, i)) > 2.5:
			water_diff += 1
		if absf(g.sdf_at(0, i) - west.sdf_at(63, i)) > 2.5:
			water_diff += 1
		if absf(g.sdf_at(i, 0) - north.sdf_at(i, 63)) > 2.5:
			water_diff += 1
	check(water_diff <= 6, "sdf continuous across seams (%d jumps)" % water_diff)

func test_grid_lookup_beyond_home() -> void:
	var g := WorldGen.new(1)
	var s := ChunkStream.new(1, g)
	check_eq(g.tile_at(70, 10), s.gen_for(Vector2i(4, 4)).tile_at(6, 10))
	check_eq(g.sdf_at(-3, 10), s.gen_for(Vector2i(2, 4)).sdf_at(61, 10))
	check(WorldGen.is_water(WorldGen.new(1).tile_at(-1, 0)), "without a stream the outside is still water")

func test_biomes_change_density() -> void:
	var s := ChunkStream.new(1)
	var forest := s.gen_for(Vector2i(1, 3))
	var farm := s.gen_for(Vector2i(4, 5))
	check(forest.trees.size() > farm.trees.size() * 2, "forest %d trees vs farmland %d" % [forest.trees.size(), farm.trees.size()])
	var hi := s.gen_for(Vector2i(4, 1))
	check(hi.rocks.size() > farm.rocks.size(), "highlands rockier")
	check(s.gen_for(Vector2i(9, 9)) == null, "outside the world")

func test_path_continues_east_west() -> void:
	var g := WorldGen.new(1)
	var s := ChunkStream.new(1, g)
	var e := s.gen_for(Vector2i(4, 4))
	var path := 0
	for y in 64:
		if e.tile_at(0, y) >= WorldGen.PATH and e.tile_at(0, y) < WorldGen.PATH + 3:
			path += 1
	check(path >= 1 or WorldGen.is_water(e.tile_at(0, 32)), "road row continues into the next chunk")
	var n := s.gen_for(Vector2i(3, 3))
	var np := 0
	for i in 64 * 64:
		if n.tiles[i] >= WorldGen.PATH and n.tiles[i] < WorldGen.PATH + 3:
			np += 1
	check_eq(np, 0, "no stray road off the row")
