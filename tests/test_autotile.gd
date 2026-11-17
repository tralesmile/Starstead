extends BaseTest

const J := ["wall", "door"]

func test_all_16_masks_unique_names() -> void:
	var expect := {
		0: "isolated", 1: "end_n", 2: "end_e", 4: "end_s", 8: "end_w",
		5: "straight_ns", 10: "straight_ew",
		3: "corner_ne", 6: "corner_se", 12: "corner_sw", 9: "corner_nw",
		14: "t_n", 13: "t_e", 11: "t_s", 7: "t_w", 15: "cross",
	}
	var seen := {}
	for m in range(16):
		check_eq(Autotile.shape_name(m), expect[m], "mask %d" % m)
		check_eq(Autotile.atlas_index(m), m)
		seen[Autotile.shape_name(m)] = true
	check_eq(seen.size(), 16)

func test_mask_ignores_non_joins() -> void:
	var cells := {Vector2i(1, 0): "wall", Vector2i(0, 1): "floor", Vector2i(-1, 0): "door"}
	check_eq(Autotile.mask(cells, Vector2i(0, 0), J), 2 | 8)
	check_eq(Autotile.mask({}, Vector2i(0, 0), J), 0)

func test_l_shaped_wall() -> void:
	var cells := {}
	for c in [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2)]:
		cells[c] = "wall"
	check_eq(Autotile.shape_name(Autotile.mask(cells, Vector2i(0, 0), J)), "end_s")
	check_eq(Autotile.shape_name(Autotile.mask(cells, Vector2i(0, 1), J)), "straight_ns")
	check_eq(Autotile.shape_name(Autotile.mask(cells, Vector2i(0, 2), J)), "corner_ne")
	check_eq(Autotile.shape_name(Autotile.mask(cells, Vector2i(1, 2), J)), "straight_ew")
	check_eq(Autotile.shape_name(Autotile.mask(cells, Vector2i(2, 2), J)), "end_w")

func test_t_shaped_wall() -> void:
	var cells := {}
	for c in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1), Vector2i(1, 2)]:
		cells[c] = "wall"
	cells[Vector2i(1, 1)] = "door"
	check_eq(Autotile.shape_name(Autotile.mask(cells, Vector2i(1, 0), J)), "t_n")
	check_eq(Autotile.shape_name(Autotile.mask(cells, Vector2i(0, 0), J)), "end_e")
	check_eq(Autotile.shape_name(Autotile.mask(cells, Vector2i(2, 0), J)), "end_w")
	check_eq(Autotile.shape_name(Autotile.mask(cells, Vector2i(1, 1), J)), "straight_ns")
	check_eq(Autotile.shape_name(Autotile.mask(cells, Vector2i(1, 2), J)), "end_n")
