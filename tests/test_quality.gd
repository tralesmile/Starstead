extends BaseTest

func test_roll_bands_and_level() -> void:
	check_eq(QualityMath.roll(0, 0.5), 0)
	check_eq(QualityMath.roll(0, 0.05), 1)
	check_eq(QualityMath.roll(5, 0.05), 2)
	check_eq(QualityMath.roll(10, 0.1), 2)
	check_eq(QualityMath.roll(10, 0.99), 0)

func test_variant_and_base() -> void:
	check_eq(QualityMath.variant("turnip", 2), "turnip_gold")
	check_eq(QualityMath.variant("turnip", 0), "turnip")
	check_eq(QualityMath.base_id("pumpkin_silver"), "pumpkin")
	check_eq(QualityMath.base_id("wood"), "wood")

func test_remove_any_prefers_plain() -> void:
	var inv := Inventory.new(10, {})
	inv.add("turnip", 1)
	inv.add("turnip_gold", 1)
	check_eq(QualityMath.count_any(inv, "turnip"), 2)
	check(QualityMath.remove_any(inv, "turnip", 1))
	check_eq(inv.count("turnip_gold"), 1)
	check_eq(inv.count("turnip"), 0)
	check(not QualityMath.remove_any(inv, "turnip", 2))

func test_cooking_accepts_quality_crops() -> void:
	var inv := Inventory.new(10, {})
	inv.add("potato_silver", 1)
	var r := {"needs": {"potato": 1}, "makes": "baked_potato"}
	check(CookModel.cook(inv, r))
	check_eq(inv.count("baked_potato"), 1)

func test_variants_have_items_icons_and_rarity() -> void:
	var items = JSON.parse_string(FileAccess.open("res://data/items.json", FileAccess.READ).get_as_text())
	var icons = JSON.parse_string(FileAccess.open("res://data/item_icons.json", FileAccess.READ).get_as_text())
	for c in ["turnip", "potato", "tomato", "pumpkin", "strawberry", "kale", "radish", "corn"]:
		check_eq(items[c + "_gold"]["rarity"], "gold")
		check(items[c + "_gold"]["price"] > items[c + "_silver"]["price"])
		check_eq(icons[c + "_gold"], icons[c])
