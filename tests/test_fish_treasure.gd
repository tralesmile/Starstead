extends BaseTest

func _reeling() -> Fishing:
	var f := Fishing.new(3)
	f.state = Fishing.State.BITE
	f.fish_id = "carp"
	f.hook()
	return f

func test_chest_appears_and_opens_under_the_bar() -> void:
	var f := _reeling()
	f.treasure_in = 0.1
	f.difficulty = 0.0
	f._treasure(0.2)
	check(f.treasure_on, "appeared")
	f.bar = f.treasure_pos
	for i in 30:
		f._treasure(0.1)
	check(f.treasure_got, "opened after ~2 s on it")
	check(not f.treasure_on)

func test_chest_drains_when_ignored() -> void:
	var f := _reeling()
	f.treasure_on = true
	f.treasure_pos = 0.9
	f.bar = 0.2
	f.treasure_prog = 0.5
	f._treasure(1.0)
	check(f.treasure_prog < 0.5)
	f._treasure(10.0)
	check_eq(f.treasure_prog, 0.0, "never negative")
	check(not f.treasure_got)

func test_hook_resets_treasure() -> void:
	var f := _reeling()
	f.treasure_got = true
	f.state = Fishing.State.BITE
	f.hook()
	check(not f.treasure_got and not f.treasure_on and f.treasure_prog == 0.0)

func test_chance_is_occasional() -> void:
	var n := 0
	for s in 200:
		var f := Fishing.new(s + 10)
		f.state = Fishing.State.BITE
		f.hook()
		if f.treasure_in > 0.0:
			n += 1
	check(n > 10 and n < 80, "about 18%% of reels: %d/200" % n)

func test_loot_table() -> void:
	var items: Dictionary = DataDB.load_json("items")
	for i in 50:
		var l := Fishing.treasure_loot(i / 50.0, fposmod(i * 0.37, 1.0))
		check(l["n"] >= 1)
		check(l["id"] == "$" or items.has(l["id"]), str(l))
	check_eq(Fishing.treasure_loot(0.0, 0.0), {"id": "$", "n": 40})
	check_eq(Fishing.treasure_loot(1.0, 1.0)["id"], "iron_bar")
