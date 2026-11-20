extends BaseTest

func _bld() -> Array:
	return [
		{"id": "barn", "cell": Vector2i(10, 5), "w": 4, "door": Vector2i(12, 7)},
		{"id": "workshop", "cell": Vector2i(20, 12), "w": 4, "door": Vector2i(21, 14)},
	]

func test_paths_link_doors_to_hub() -> void:
	var water := func(c: Vector2i) -> bool: return not (c.x == 16 and c.y < 20)   # a stream with a ford at y >= 20
	var p := TownModel.village_paths(_bld(), Vector2i(14, 22), water)
	check(p.size() > 10)
	check(Vector2i(12, 7) in p and Vector2i(21, 14) in p and Vector2i(14, 22) in p, "doors and hub on the path")
	for c in p:
		check(water.call(c), "no path through water %s" % str(c))
		for b in _bld():
			check(not (c in TownModel.footprint_cells(b)), "not through a building")
	var set := {}
	for c in p:
		set[c] = true
	check_eq(set.size(), p.size(), "unique")

func test_paddock_beside_barn() -> void:
	var barn: Dictionary = _bld()[0]
	var pd := TownModel.paddock(barn, func(c): return true)
	check(not pd.is_empty())
	var r: Rect2i = pd["rect"]
	check_eq(r.position.x, 15, "east of the barn with a 1-cell lane")
	check_eq(pd["fence"].size(), 2 * (5 + 4) - 4 - 1, "ring minus the gate")
	check(not (pd["gate"] in pd["fence"]))
	check_eq(pd["gate"].y, r.end.y - 1, "gate on the south side")
	var west := TownModel.paddock(barn, func(c): return c.x < 10)
	check(not west.is_empty() and (west["rect"] as Rect2i).end.x <= 10, "falls back to the west side")
	check(TownModel.paddock(barn, func(c): return false).is_empty())

func test_field_south_of_barn() -> void:
	var barn: Dictionary = _bld()[0]
	var f := TownModel.field(barn, Rect2i(), func(c): return true)
	check_eq(f.size(), 18, "6x3 plot")
	for c in f:
		check(c.y >= 10, "below the barn")
	var pad := Rect2i(Vector2i(10, 9), Vector2i(5, 4))
	var g := TownModel.field(barn, pad, func(c): return true)
	for c in g:
		check(not pad.has_point(c), "clear of the paddock")
	check(TownModel.field(barn, Rect2i(), func(c): return false).is_empty())
