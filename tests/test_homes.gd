extends BaseTest

func test_every_robbable_home_is_furnished_and_walkable() -> void:
	var ids := ["city_house1", "city_house2", "city_house3", "city_apt_a", "city_apt_b"]
	var seen := {}
	for id in ids:
		var l := InteriorModel.layout_for(id)
		check(l["furniture"].size() >= 8, id + " furnished")
		var loot := 0
		var w := int(l["w"])
		var h := int(l["h"])
		var door := Rect2(int(l["door_x"]) * 32.0, (h - 1) * 32.0, 32, 32)
		var cells := {}
		for f in l["furniture"]:
			if String(f["action"]) == "loot":
				loot += 1
			var c: Vector2i = f["cell"]
			var sz: Vector2i = f["size"]
			check(c.x >= 0 and c.y >= 0 and c.x + sz.x <= w and c.y + sz.y <= h, id + " " + String(f["id"]) + " inside room")
			if f["solid"]:
				for dx in sz.x:
					for dy in sz.y:
						check(not cells.has(c + Vector2i(dx, dy)), id + " no overlap " + String(f["id"]))
						cells[c + Vector2i(dx, dy)] = true
		check(loot >= 2, id + " has loot spots")
		for r in InteriorModel.solid_rects(l):
			check(not r.intersects(door), id + " door row clear")
		# the cell in front of the door is free so the player can walk in
		check(not cells.has(Vector2i(int(l["door_x"]), h - 2)), id + " entry cell free")
		seen[JSON.stringify(l["furniture"].map(func(f): return f["id"]))] = true
		for f in l["furniture"]:
			check(FileAccess.file_exists("res://assets/sprites/%s.png" % f["sprite"]), "sprite " + String(f["sprite"]))
	check(seen.size() >= 4, "homes look different")

func test_other_kinds_unchanged() -> void:
	check_eq(InteriorModel.layout_for("farmhouse")["w"], 9)
	check_eq(InteriorModel.layout_for("city_bank")["w"], 9)
