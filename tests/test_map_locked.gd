extends BaseTest

const GATES := {
	"port_halden": {"needs": "vance_car", "msg": "Road closed: a chain across the road. Opens on day 3."},
	"highlands": {"needs": "see_ledger", "msg": "Rockfall on the road: ask at the ledger first."},
}

func test_locked_until_story_step() -> void:
	var l := MapModel.locked_regions(GATES, {})
	check(l.has("port_halden") and l.has("highlands"))
	l = MapModel.locked_regions(GATES, {"vance_car": true})
	check(not l.has("port_halden"), "city opens with the Vance visit")
	check(l.has("highlands"))
	check(MapModel.locked_regions(GATES, {"vance_car": true, "see_ledger": true}).is_empty())
	check(MapModel.locked_regions({}, {}).is_empty(), "gates off (demo flags)")

func test_real_gates_lock_city_on_day_one() -> void:
	var l := MapModel.locked_regions(StoryGate.load_gates(), {})
	check(l.has("port_halden") and l.has("harbour") and l.has("circuit"))

func test_chunk_rect() -> void:
	var r := MapModel.chunk_rect(Vector2i(0, 0))
	check_eq(r.position, Vector2(0, 0))
	check_eq(r.size, Vector2(16, 16))
	var h := MapModel.chunk_rect(ChunkGrid.HOME)
	check_eq(h.position, MapModel.to_map(Vector2(0, 0)), "homestead chunk starts at cell 0")

func test_short_reason() -> void:
	check_eq(MapModel.short_reason("Road closed: a chain."), "a chain.")
	check_eq(MapModel.short_reason("no colon"), "no colon")
	check(MapModel.short_reason("x: " + "a".repeat(100)).length() <= 60)

func test_hint_preferred() -> void:
	var g := {"x": {"needs": "a", "msg": "Closed: long text", "hint": "X: soon"}}
	check_eq(MapModel.locked_regions(g, {})["x"], "X: soon")
	check_eq(MapModel.locked_regions(GATES, {})["highlands"], "ask at the ledger first.")
