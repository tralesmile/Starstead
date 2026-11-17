extends BaseTest

func _land(c: Vector2i) -> bool:
	return c.x > 0 and c.y > 0 and c.x < 63 and c.y < 63

func test_layout_places_all_without_overlap() -> void:
	var places := {"barn": [8, 7], "workshop": [16, 22], "fish_hut": [28, 18]}
	var l := TownModel.layout(places, Vector2i(9, 8), Callable(self, "_land"))
	check_eq(l.size(), 4)
	var seen := {}
	for b in l:
		for c in TownModel.footprint_cells(b):
			check(not seen.has(c), "overlap at %s" % str(c))
			seen[c] = true

func test_layout_avoids_water() -> void:
	var land := func(c: Vector2i) -> bool: return c.x >= 20 and c.x < 60 and c.y > 0 and c.y < 60
	var l := TownModel.layout({"barn": [5, 5]}, Vector2i(5, 5), land)
	for b in l:
		for c in TownModel.footprint_cells(b):
			check(c.x >= 20, "building in water")

func test_door_is_below_footprint() -> void:
	var l := TownModel.layout({}, Vector2i(30, 30), Callable(self, "_land"))
	for b in l:
		check_eq(b["door"].y, b["cell"].y + TownModel.DEPTH)

func test_blocked_cells_respected() -> void:
	var blocked: Array = []
	for x in range(0, 64):
		for y in range(0, 64):
			if Vector2i(x, y).distance_to(Vector2(30, 30)) < 6.0:
				blocked.append(Vector2i(x, y))
	var l := TownModel.layout({"barn": [30, 30]}, Vector2i(30, 30), Callable(self, "_land"), blocked)
	for b in l:
		for c in TownModel.footprint_cells(b):
			check(not (c in blocked))
