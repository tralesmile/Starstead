extends BaseTest

const R := {"needs": {"pumpkin": 1, "egg": 1}, "makes": "pumpkin_pie"}

func test_cook_consumes_and_makes() -> void:
	var inv := Inventory.new(10, {})
	inv.add("pumpkin", 1)
	inv.add("egg", 2)
	check(CookModel.cook(inv, R))
	check_eq(inv.count("pumpkin"), 0)
	check_eq(inv.count("egg"), 1)
	check_eq(inv.count("pumpkin_pie"), 1)
	check(not CookModel.cook(inv, R))

func test_full_bag_keeps_ingredients() -> void:
	var inv := Inventory.new(2, {"pumpkin": 1, "egg": 1, "pumpkin_pie": 1})
	inv.add("pumpkin", 1)
	inv.add("egg", 1)
	check(CookModel.cook(inv, R))  # frees both slots, pie fits
	var inv2 := Inventory.new(3, {"pumpkin": 1, "egg": 1, "pumpkin_pie": 1, "stone": 1})
	inv2.add("pumpkin", 1)
	inv2.add("egg", 2)
	inv2.add("stone", 1)
	check(CookModel.cook(inv2, R))

func test_eat_restores_capped() -> void:
	var inv := Inventory.new(5, {})
	inv.add("fried_egg", 2)
	var en := Energy.new()
	en.value = 90.0
	var items := {"fried_egg": {"energy": 20}}
	check_eq(CookModel.eat(inv, items, en, "fried_egg"), 10)
	check_eq(en.value, 100.0)
	check_eq(inv.count("fried_egg"), 1)
	check_eq(CookModel.eat(inv, items, en, "stone"), -1)

func test_recipes_reference_real_items() -> void:
	var items = JSON.parse_string(FileAccess.open("res://data/items.json", FileAccess.READ).get_as_text())
	var rec = JSON.parse_string(FileAccess.open("res://data/recipes.json", FileAccess.READ).get_as_text())
	for k in rec:
		check(items.has(rec[k]["makes"]))
		check(int(items[rec[k]["makes"]].get("energy", 0)) > 0)
		for n in rec[k]["needs"]:
			check(items.has(n))

func test_new_dishes_cook_from_the_new_ingredients() -> void:
	var rec: Dictionary = DataDB.load_json("recipes")
	var items: Dictionary = DataDB.load_json("items")
	for id in ["strawberry_tart", "kale_soup", "hunters_stew"]:
		check(rec.has(id) and items.has(id) and int(items[id].energy) > 0, id)
		var cost := 0
		for n in rec[id]["needs"]:
			cost += int(items[n].price) * int(rec[id]["needs"][n])
		check(int(items[id].price) > cost, "%s is worth cooking (%d > %d)" % [id, items[id].price, cost])
	var inv := Inventory.new()
	inv.add("kale", 2)
	inv.add("turnip", 1)
	check(CookModel.cook(inv, rec["kale_soup"]))
	check_eq(inv.count("kale_soup"), 1)
