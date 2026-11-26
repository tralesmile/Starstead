extends BaseTest

func _xp(lvl: int) -> int:
	return SkillModel.THRESHOLDS[lvl]

func test_two_options_per_skill() -> void:
	var ids := {}
	for sk in SkillModel.SKILLS:
		var opts := PerkModel.options(sk)
		check_eq(opts.size(), 2, sk)
		for o in opts:
			check(String(o.name) != "" and String(o.desc) != "" and not (o.effect as Dictionary).is_empty(), sk + " card is filled in")
			check(not ids.has(o.id), "unique id " + String(o.id))
			ids[o.id] = true
			for k in o.effect:
				check(float(o.effect[k]) > 0.0, "numeric effect " + String(k))

func test_pending_from_level_five() -> void:
	check_eq(PerkModel.pending({}, {}), [])
	check_eq(PerkModel.pending({"farming": _xp(5) - 1}, {}), [])
	check_eq(PerkModel.pending({"farming": _xp(5), "fishing": _xp(9), "mining": _xp(2)}, {}), ["farming", "fishing"])
	check_eq(PerkModel.pending({"farming": _xp(5), "fishing": _xp(9)}, {"farming": "heavy_rows"}), ["fishing"])

func test_choice_is_permanent_and_validated() -> void:
	var c := {}
	check(not PerkModel.choose(c, "farming", "easy_swing"), "other skill's perk")
	check(not PerkModel.choose(c, "cooking", "heavy_rows"), "unknown skill")
	check(PerkModel.choose(c, "farming", "heavy_rows"))
	check(not PerkModel.choose(c, "farming", "stall_favourite"), "no second pick")
	check_eq(c, {"farming": "heavy_rows"})

func test_values_and_neutral_defaults() -> void:
	check_eq(PerkModel.value({}, "crop_sell_mult"), 1.0)
	check_eq(PerkModel.value({}, "wood_bonus"), 0.0)
	check(is_equal_approx(PerkModel.value({"farming": "stall_favourite"}, "crop_sell_mult"), 1.15))
	check_eq(PerkModel.value({"farming": "heavy_rows"}, "crop_sell_mult"), 1.0, "the other card gives nothing here")
	check_eq(PerkModel.crop_bonus({}, 5, 0.3), 0)
	check_eq(PerkModel.crop_bonus({"farming": "heavy_rows"}, 5, 0.3), 1)
	check_eq(PerkModel.ore_extra({}, 0.0), 0)
	check_eq(PerkModel.ore_extra({"mining": "seam_reader"}, 0.2), 1)
	check_eq(PerkModel.ore_extra({"mining": "seam_reader"}, 0.8), 0)

func test_energy_discounts() -> void:
	var e := Energy.new()
	e.discounts = PerkModel.energy_discounts({})
	check_eq(e.cost_of("axe"), 4)
	e.discounts = PerkModel.energy_discounts({"foraging": "easy_swing", "mining": "steady_pick"})
	check_eq(e.cost_of("axe"), 2)
	check_eq(e.cost_of("pickaxe"), 3)
	check_eq(e.cost_of("hoe"), 2)
	e.discounts = {"watering_can": 9}
	check_eq(e.cost_of("watering_can"), 1, "never free")
	check_eq(e.cost_of("hand"), 0)

func test_wood_and_reel_hooks() -> void:
	var t := TreeFall.new()
	t.bonus_wood = int(PerkModel.value({"foraging": "clean_splitter"}, "wood_bonus"))
	t.start(Vector2i.ZERO, 1.0)
	t.land(Vector2i.ZERO)
	var r := {}
	for i in TreeFall.LOG_HITS:
		r = t.hit(Vector2i.ZERO)
	check_eq(r.get("n"), TreeFall.LOG_WOOD + 2)
	var table: Dictionary = DataDB.load_json("fish")
	var plain := Fishing.new(3)
	var wide := Fishing.new(3)
	check(plain.cast(-1.0, table, 0))
	check(wide.cast(-1.0, table, 0, {}, {"perk_bar": PerkModel.value({"fishing": "soft_hands"}, "reel_bar_bonus")}))
	check(is_equal_approx(wide.bar_size - plain.bar_size, 0.07), "wider bar")

func test_shop_sell_perks() -> void:
	var items: Dictionary = DataDB.load_json("items")
	var menu := ShopMenu.new(items)
	var turnip := menu._sell_now("turnip")
	var gold := menu._sell_now("pumpkin_gold")
	var perch := menu._sell_now("perch")
	var wood := menu._sell_now("wood")
	menu.perks = {"farming": "stall_favourite"}
	check_eq(menu._sell_now("turnip"), int(round(turnip * 1.15)))
	check(menu._sell_now("pumpkin_gold") > gold, "quality crops count")
	check_eq(menu._sell_now("perch"), perch)
	menu.perks = {"fishing": "quay_haggler"}
	check_eq(menu._sell_now("perch"), int(round(perch * 1.25)))
	check_eq(menu._sell_now("turnip"), turnip)
	check_eq(menu._sell_now("wood"), wood)

func test_save_round_trip_and_old_saves() -> void:
	# GameState is an autoload and does not compile here: the save path is PerkModel.clean over JSON.
	var back := PerkModel.clean(JSON.parse_string(JSON.stringify({"mining": "steady_pick"})))
	check_eq(back, {"mining": "steady_pick"})
	check_eq(PerkModel.clean({}), {}, "old save")
	check_eq(PerkModel.clean({"mining": "nonsense", "junk": 3}), {})

func test_every_effect_key_is_read_by_the_code() -> void:
	var code := ""
	for f in DirAccess.open("res://scripts").get_files():
		if f.ends_with(".gd"):
			code += FileAccess.get_file_as_string("res://scripts/" + f)
	for sk in SkillModel.SKILLS:
		for o in PerkModel.options(sk):
			for k in o.effect:
				check(code.contains("\"%s\")" % k), "no code reads effect key " + String(k))

func test_card_text_fits() -> void:
	var font := ThemeDB.fallback_font
	var w := PerkModel.CARD_SIZE.x - PerkModel.CARD_PAD * 2.0
	var line_h := font.get_height(PerkModel.DESC_SIZE)
	for sk in SkillModel.SKILLS:
		for o in PerkModel.options(sk):
			check(font.get_string_size(o.name, HORIZONTAL_ALIGNMENT_LEFT, -1, PerkModel.NAME_SIZE).x <= w, "name fits: " + String(o.name))
			var sz := font.get_multiline_string_size(o.desc, HORIZONTAL_ALIGNMENT_CENTER, w, PerkModel.DESC_SIZE)
			check(sz.y <= line_h * PerkModel.DESC_LINES + 0.5, "desc within %d lines: %s" % [PerkModel.DESC_LINES, o.name])
			check(PerkModel.DESC_Y + sz.y - font.get_ascent(PerkModel.DESC_SIZE) < PerkModel.PICK_Y - 13.0, "desc clears the key plate: " + String(o.name))
	check(font.get_string_size(PerkModel.FOOTER, HORIZONTAL_ALIGNMENT_LEFT, -1, PerkModel.FOOTER_SIZE).x <= PerkModel.PANEL.size.x - 16, "footer fits")
	check(Rect2(0, 0, 640, 360).encloses(PerkModel.PANEL.grow(6)), "panel on screen")
	for i in 2:
		check(PerkModel.PANEL.encloses(PerkModel.card_rect(i)), "card inside panel")
		check_eq(PerkModel.card_at(PerkModel.card_rect(i).get_center()), i)
	check(not PerkModel.card_rect(0).intersects(PerkModel.card_rect(1)))
