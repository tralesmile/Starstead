extends BaseTest

func test_layout_in_vance_chunk() -> void:
	for c in [VanceYard.RECT.position, VanceYard.RECT.end - Vector2i.ONE]:
		check_eq(ChunkGrid.chunk_of_cell(c), Vector2i(7, 2), "yard stays in the Vance chunk")

func test_fence_ring_with_gate_gap() -> void:
	var f := VanceYard.fence_cells()
	var r := VanceYard.RECT
	check_eq(f.size(), 2 * (r.size.x + r.size.y) - 4 - VanceYard.GATE.size())
	for g in VanceYard.GATE:
		check(not VanceYard.is_fence(g), "gate gap")
		check_eq(g.y, r.end.y - 1, "gate on the south side")
	check(not VanceYard.is_fence(VanceYard.ROCKET))

func test_props_inside_and_not_on_fence() -> void:
	for p in VanceYard.props():
		var c: Vector2i = p["cell"]
		check(VanceYard.in_rect(c), str(p))
		check(not VanceYard.is_fence(c), str(p))
		check(not (c in VanceYard.GATE), str(p))

func test_gate_opens_with_story() -> void:
	check(not VanceYard.gate_open({}))
	check(VanceYard.gate_open({"rocket_seat": true}))

func test_road_end_outside_by_the_gate() -> void:
	var hub := Vector2i(288, -96)   # RoadNet "vance" target
	check(not VanceYard.in_rect(hub), "Vance waits outside")
	check(Vector2(hub - VanceYard.GATE[1]).length() <= 3.0, "gate faces the road end")
