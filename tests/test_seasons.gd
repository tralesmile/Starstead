extends BaseTest

func _farm() -> FarmModel:
	var crops = JSON.parse_string(FileAccess.open("res://data/crops.json", FileAccess.READ).get_as_text())
	var f := FarmModel.new(crops)
	f.till(Vector2i(0, 0))
	return f

func test_crop_seasons() -> void:
	var f := _farm()
	check(f.in_season("potato", 0))
	check(not f.in_season("potato", 1))
	check(f.in_season("tomato", 1))
	check(f.in_season("pumpkin", 2))
	check(not f.in_season("pumpkin", 0))

func test_wrong_season_message_and_seed_kept() -> void:
	var f := _farm()
	var inv := Inventory.new(30, {"pumpkin_seed": 99})
	inv.add("pumpkin_seed", 3)
	check(ToolUse.apply("pumpkin_seed", Vector2i(0, 0), f, inv, 0).begins_with("Wrong season"))
	check_eq(inv.count("pumpkin_seed"), 3)
	check_eq(ToolUse.apply("pumpkin_seed", Vector2i(0, 0), f, inv, 2), "Planted")
	check_eq(inv.count("pumpkin_seed"), 2)

func test_new_crops_have_items_icons_and_yield() -> void:
	var items = JSON.parse_string(FileAccess.open("res://data/items.json", FileAccess.READ).get_as_text())
	var icons = JSON.parse_string(FileAccess.open("res://data/item_icons.json", FileAccess.READ).get_as_text())
	var f := _farm()
	for id in f.crops:
		check(items.has(id))
		check(items.has(f.crops[id].seed))
		check(icons.has(id) and icons.has(f.crops[id].seed))

func test_harvest_yield_two_potatoes() -> void:
	var f := _farm()
	check(f.plant(Vector2i(0, 0), "potato_seed", 0))
	f.soil[Vector2i(0, 0)].age = 5
	check_eq(f.harvest(Vector2i(0, 0)), {"id": "potato", "n": 2})

func test_new_crops_fill_the_calendar() -> void:
	var f := FarmModel.new(DataDB.load_json("crops"))
	check(f.in_season("strawberry", 0) and not f.in_season("strawberry", 1))
	check(f.in_season("kale", 3) and not f.in_season("kale", 2))
	var winter := 0
	for id in f.crops:
		if f.in_season(id, 3):
			winter += 1
	check(winter >= 2, "winter has more than turnips")
	var items: Dictionary = DataDB.load_json("items")
	for id in ["strawberry", "kale"]:
		check(items.has(f.crops[id].seed) and bool(items[f.crops[id].seed].get("buy", false)), "%s seed is sold" % id)
		check(int(items[id].price) > int(items[f.crops[id].seed].price), "sells for more than a seed's value")
