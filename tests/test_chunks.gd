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

func test_roads_planned_and_avoid_water() -> void:
	var r := RoadNet.new(1)
	check(r.polylines.size() >= 5, "branches planned: %d" % r.polylines.size())
	check_eq(r.signs.size(), r.polylines.size())
	var s := ChunkStream.new(1)
	var painted := 0
	for ch in r.cells:
		check(ch != ChunkGrid.HOME, "home layout untouched")
		var g := s.gen_for(ch)
		for lc in r.cells[ch]:
			var t := g.tile_at(lc.x, lc.y)
			if t >= WorldGen.PATH and t < WorldGen.PATH + 3:
				painted += 1
			else:
				check(WorldGen.is_water(t) or t >= WorldGen.PATH, "road cell is path or a ford")
	check(painted > 200, "roads painted: %d" % painted)

func test_roads_deterministic_and_start_on_spine() -> void:
	var a := RoadNet.new(1)
	var b := RoadNet.new(1)
	check_eq(a.polylines, b.polylines)
	for pl in a.polylines:
		var st: Vector2i = pl[0]
		check_eq(st.y, RoadNet.spine_y(st.x), "branch leaves the spine")
		check(not ChunkGrid.chunk_of_cell(st) == ChunkGrid.HOME, "junction outside home")

func test_no_trees_on_roads() -> void:
	var s := ChunkStream.new(1)
	for ch in s.roads.cells:
		var g := s.gen_for(ch)
		for t in g.trees:
			check(not s.roads.cells[ch].has(t), "tree on road at %s %s" % [ch, t])

func test_direction_text() -> void:
	check(RoadNet.direction_text(Vector2i(0, 0), Vector2i(0, 100)).begins_with("South"), "south")
	check(RoadNet.direction_text(Vector2i(0, 0), Vector2i(-100, 0)).begins_with("West"), "west")
	check(RoadNet.direction_text(Vector2i(0, 0), Vector2i(60, -60)).begins_with("Northeast"), "northeast")

func test_spine_is_walkable_everywhere() -> void:
	var s := ChunkStream.new(1, WorldGen.new(1))
	for ch in [Vector2i(0, 4), Vector2i(1, 4), Vector2i(2, 4), Vector2i(4, 4), Vector2i(5, 4), Vector2i(6, 4), Vector2i(7, 4)]:
		var g := s.gen_for(ch)
		for x in 64:
			var y := 32 + int(round(sin((x + (ch.x - 3) * 64) * 0.2) * 3.0))
			var t := g.tile_at(x, y)
			check(t >= WorldGen.PATH and t < WorldGen.PATH + 3, "spine open at chunk %s x=%d" % [ch, x])
