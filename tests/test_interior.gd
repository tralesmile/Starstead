extends BaseTest

func test_every_kind_is_valid() -> void:
	for k in ["farmhouse", "house", "workshop", "barn"]:
		var l := InteriorModel.layout(k)
		var w: int = l["w"]
		var h: int = l["h"]
		for f in l["furniture"]:
			var c: Vector2i = f["cell"]
			var s: Vector2i = f["size"]
			check(c.x >= 0 and c.y >= 0 and c.x + s.x <= w and c.y + s.y <= h, "%s %s in bounds" % [k, f["id"]])
		# door column and the entrance cell are never blocked by solid furniture
		var ent := InteriorModel.entrance(l)
		for r in InteriorModel.solid_rects(l):
			check(not r.grow(6.0).has_point(ent), "%s entrance free" % k)
		check(not InteriorModel.left_through_door(l, ent), k)

func test_solid_furniture_does_not_overlap() -> void:
	for k in ["farmhouse", "house", "workshop", "barn"]:
		var rects := InteriorModel.solid_rects(InteriorModel.layout(k))
		for i in rects.size():
			for j in range(i + 1, rects.size()):
				check(not rects[i].intersects(rects[j]), "%s overlap %d/%d" % [k, i, j])

func test_farmhouse_has_bed_and_house_has_loot() -> void:
	var fh := InteriorModel.layout("farmhouse")
	var bed := InteriorModel.action_near(fh, Vector2(0.5 * 32, 3.0 * 32 + 10), ["sleep"])
	check_eq(bed.get("id", ""), "bed")
	var hs := InteriorModel.layout("house")
	check(not InteriorModel.action_near(hs, Vector2(3.5 * 32, 1.5 * 32), ["loot"]).is_empty())
	check(InteriorModel.action_near(hs, Vector2(100, 100), ["sleep"]).is_empty())

func test_exit_through_door_gap() -> void:
	var l := InteriorModel.layout("barn")
	var door_x := (int(l["door_x"]) + 0.5) * 32.0
	check(InteriorModel.left_through_door(l, Vector2(door_x, int(l["h"]) * 32.0 + 10.0)))
	check(not InteriorModel.left_through_door(l, Vector2(door_x + 60.0, int(l["h"]) * 32.0 + 10.0)))

func test_kinds_and_public() -> void:
	check_eq(InteriorModel.kind_for("fish_hut"), "house")
	check_eq(InteriorModel.kind_for("barn"), "barn")
	check("farmhouse" in InteriorModel.PUBLIC)
	check(not ("fish_hut" in InteriorModel.PUBLIC))
