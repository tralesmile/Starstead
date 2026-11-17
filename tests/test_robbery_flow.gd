extends BaseTest
## Pure flow on RobberyModel as RobberyView drives it: pick, loot to empty, memory, heat.

func test_full_robbery_flow() -> void:
	var m := RobberyModel.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var id := "barn"
	var tries := 0
	while m.house(id)["locked"] and tries < 200:
		m.attempt_pick(id, 5, rng)
		tries += 1
	check(not m.house(id)["locked"])
	var got := 0
	while m.loot_item(id) != "":
		got += 1
	check(got > 0)
	check(m.house(id)["looted"])
	m.finish_robbery(id, rng)
	check(m.house(id)["locked"])
	check(m.house(id)["grudge"])
