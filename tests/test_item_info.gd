extends BaseTest

func test_border_colors() -> void:
	check(ItemInfo.has_border("gold"))
	check(not ItemInfo.has_border(""))
	check(ItemInfo.border_color("gold").r > 0.9)
	check_eq(ItemInfo.border_color("nope").a, 0.0)

func test_plurals() -> void:
	check_eq(ItemInfo.display_name({"name": "Turnip"}, 1), "Turnip")
	check_eq(ItemInfo.display_name({"name": "Turnip"}, 3), "3 Turnips")
	check_eq(ItemInfo.display_name({"name": "Turnip Seeds"}, 5), "5 Turnip Seeds")
	check_eq(ItemInfo.display_name({"name": "Perch"}, 2), "2 Perches")
	check_eq(ItemInfo.display_name({"name": "Milk"}, 2), "2 Milk")
