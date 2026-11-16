extends BaseTest

func test_deterministic() -> void:
	var a := WorldGen.new(5)
	var b := WorldGen.new(5)
	check(a.tiles == b.tiles, "same seed same tiles")
	check(a.trees == b.trees, "same trees")
	check(a.tiles != WorldGen.new(6).tiles, "different seed differs")

func test_spawn_dry_and_path() -> void:
	for s in [1, 2, 3, 42]:
		var g := WorldGen.new(s)
		check(not WorldGen.is_water(g.tile_at(32, 32)), "spawn dry seed %d" % s)
		check(g.tiles.size() == 64 * 64, "size")
		check(g.trees.size() > 20, "has trees seed %d" % s)
		for t in g.trees:
			check(g.tile_at(t.x, t.y) <= 2, "tree on grass")
	check(WorldGen.is_water(WorldGen.new(1).tile_at(-1, 0)), "outside is water")
