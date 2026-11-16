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

func test_sdf_signs_and_shore() -> void:
	var g := WorldGen.new(1)
	for y in WorldGen.SIZE:
		for x in WorldGen.SIZE:
			var w := WorldGen.is_water(g.tile_at(x, y))
			check((g.sdf_at(x, y) < 0.0) == w, "sdf sign at %d,%d" % [x, y])
			if w:
				return  # one water cell proves the sign; full scan below
	check(g.sdf_at(-5, -5) < 0.0, "outside counts as water")

func test_dock_over_water_near_spawn() -> void:
	for s in [1, 2, 3]:
		var g := WorldGen.new(s)
		if g.dock.is_empty():
			continue
		check_eq(g.dock.size(), 3)
		for c in g.dock:
			check(WorldGen.is_water(g.tile_at(c.x, c.y)), "dock over water")
		check(g.dock[0].y == g.dock[2].y, "dock horizontal")

func test_decor_in_water() -> void:
	var g := WorldGen.new(1)
	for c in g.lilies + g.reeds:
		check(WorldGen.is_water(g.tile_at(c.x, c.y)), "decor in water")
	check(g.lilies.size() + g.reeds.size() > 0, "has water decor")

func test_data_image() -> void:
	var g := WorldGen.new(1)
	var img := World.data_image(g)
	check_eq(img.get_width(), 64)
	check(img.get_pixel(32, 32).r > 0.5, "spawn is land in data")
