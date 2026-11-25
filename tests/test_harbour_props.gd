extends BaseTest

func test_props_on_quay_off_pier_and_road() -> void:
	check(HarbourProps.items().size() >= 4, "4-6 props")
	var seen := {}
	var taken := {}
	for p in HarbourModel.props():
		taken[p["cell"]] = true
	for it in HarbourProps.items():
		var c: Vector2i = it["cell"]
		check(HarbourModel.QUAY.has_point(c), "on quay %s" % c)
		check(not HarbourModel.PIER.has_point(c) and not HarbourModel.HEAD.has_point(c), "off pier %s" % c)
		check(c.x < 222 or c.x > 227, "keeps the road/pier approach clear %s" % c)
		check(not taken.has(c), "not on an existing prop %s" % c)
		check(not seen.has(c), "unique %s" % c)
		seen[c] = true
		check(int(it["frame"]) >= 0 and int(it["frame"]) < 10, "valid frame")
