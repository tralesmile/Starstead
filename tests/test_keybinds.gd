extends BaseTest

const TMP := "user://test_keybinds.json"

func test_defaults_match_input_setup_and_are_legal() -> void:
	var d := KeyBinds.defaults()
	check_eq(d.size(), KeyBinds.LIST.size())
	var used := {}
	for a in d:
		check_eq(KeyBinds.refusal(a, d[a]), "", a)
		check(not used.has(d[a]), "unique " + a)
		used[d[a]] = true
	for a in KeyBinds.SETUP.ACTIONS:
		check(a == "pause" or d.has(a), "rebindable: " + a)
		for k in (KeyBinds.SETUP.ACTIONS[a] as Array).slice(1):
			check(KeyBinds.RESERVED.has(k), "fixed second keys are reserved: " + a)

func test_rebind_to_a_free_key() -> void:
	var d := KeyBinds.defaults()
	var r := KeyBinds.rebind(d, "interact", KEY_V)
	check(r["ok"])
	check_eq(r["binds"]["interact"], KEY_V)
	check_eq(d["interact"], KEY_E, "input not changed")

func test_conflict_swaps() -> void:
	var r := KeyBinds.rebind(KeyBinds.defaults(), "craft", KEY_M)
	check(r["ok"])
	check_eq(r["binds"]["craft"], KEY_M)
	check_eq(r["binds"]["map"], KEY_C)
	check(String(r["msg"]).begins_with("Swapped"))

func test_reserved_keys_are_refused_with_a_message() -> void:
	for k in [KEY_ESCAPE, KEY_F1, KEY_1, KEY_0, KEY_B, KEY_G, KEY_N, KEY_SPACE, KEY_UP, KEY_I, KEY_MINUS, KEY_F5, KEY_ALT]:
		var r := KeyBinds.rebind(KeyBinds.defaults(), "interact", k)
		check(not r["ok"] and String(r["msg"]) != "", "refused %d" % k)
		check_eq(r["binds"], KeyBinds.defaults())

func test_modifiers_and_sort_key_limits() -> void:
	check(KeyBinds.refusal("interact", KEY_SHIFT) != "")
	check_eq(KeyBinds.refusal("sneak", KEY_SHIFT), "")
	check(KeyBinds.refusal("inventory", KEY_S) != "")
	check(KeyBinds.rebind(KeyBinds.defaults(), "sprint", KEY_CTRL)["ok"], "sprint and sneak swap")
	check(not KeyBinds.rebind(KeyBinds.defaults(), "sprint", KEY_E)["ok"], "the swap would give Use the Shift key")
	check(not KeyBinds.rebind(KeyBinds.defaults(), "craft", KEY_S)["ok"], "the swap would give walk down C, craft S")

func test_saving_keeps_other_settings_and_bad_files_give_defaults() -> void:
	PauseModel.store_volume(3, TMP)
	var chosen: Dictionary = KeyBinds.rebind(KeyBinds.defaults(), "interact", KEY_V)["binds"]
	KeyBinds.store(chosen, TMP)
	check_eq(PauseModel.load_volume(TMP), 3)
	check_eq(KeyBinds.from_settings(PauseModel.read_settings(TMP)), chosen)
	PauseModel.store_volume(5, TMP)
	check_eq(KeyBinds.from_settings(PauseModel.read_settings(TMP)), chosen, "volume keeps keys")
	KeyBinds.store(KeyBinds.defaults(), TMP)
	check(not PauseModel.read_settings(TMP).has("keys"))
	check_eq(PauseModel.load_volume(TMP), 5)
	DirAccess.remove_absolute(TMP)
	for bad in [{}, {"keys": "no"}, {"keys": {"interact": "x"}}, {"keys": {"interact": float(KEY_F)}}, {"keys": {"interact": float(KEY_ESCAPE)}}]:
		check_eq(KeyBinds.from_settings(bad), KeyBinds.defaults())

func _press(code: int) -> InputEventKey:
	var e := InputEventKey.new()
	e.keycode = code
	e.pressed = true
	return e

func test_page_rebinds_the_input_map_and_resets() -> void:
	var was := KeyBinds.persist
	KeyBinds.persist = false
	KeyBinds.apply(KeyBinds.defaults())
	if not InputMap.has_action("pause"):   # the InputSetup autoload has not run in -s mode
		InputMap.add_action("pause")
		InputMap.action_add_event("pause", _press(KEY_ESCAPE))
	var page := KeysPage.new()
	page.open()
	page.sel = 6   # Use / talk
	check(not page.handle(_press(KEY_ENTER), Vector2.ZERO) and page.waiting)
	page.handle(_press(KEY_V), Vector2.ZERO)
	check(_press(KEY_V).is_action_pressed("interact"), "new key works")
	check(not _press(KEY_E).is_action_pressed("interact"), "old key is free")
	check(_press(KEY_SPACE).is_action_pressed("interact"), "second key stays")
	page.handle(_press(KEY_ENTER), Vector2.ZERO)
	page.handle(_press(KEY_ESCAPE), Vector2.ZERO)
	check(not page.waiting and KeyBinds.key_of("interact") == KEY_V, "Esc cancels")
	page.sel = KeysPage.RESET
	page.handle(_press(KEY_ENTER), Vector2.ZERO)
	check(_press(KEY_E).is_action_pressed("interact"))
	check(not _press(KEY_V).is_action_pressed("interact"))
	page.sel = KeysPage.BACK
	check(page.handle(_press(KEY_ENTER), Vector2.ZERO))
	KeyBinds.persist = was

func test_legend_and_hints_follow_the_keys() -> void:
	var c: Dictionary = KeyBinds.rebind(KeyBinds.defaults(), "interact", KEY_F)["binds"]   # E and F swap
	c = KeyBinds.rebind(c, "move_up", KEY_Z)["binds"]
	KeyBinds.apply(c)
	var rows := KeyLegend.rows("foot")
	check_eq(rows[0][0], "ZASD")
	check(["F", "Use / talk"] in rows)
	check(["E/Click", "Tool"] in rows)
	check_eq(KeyBinds.hint("E: Drive"), "F: Drive")
	check_eq(KeyBinds.hint("Hold F with the Fishing Rod"), "Hold E with the Fishing Rod")
	check_eq(KeyBinds.hint("F / Click: cut the weeds"), "E / Click: cut the weeds")
	check_eq(KeyBinds.hint("E: Collect the till   Shift+E: upgrade"), "F: Collect the till   Shift+F: upgrade")
	check_eq(ShiftGameView.key_dir(KEY_Z), 0)
	check_eq(ShiftGameView.key_dir(KEY_UP), 0)
	check_eq(ShiftGameView.key_dir(KEY_W), -1)
	KeyBinds.apply(KeyBinds.defaults())
	check_eq(KeyBinds.hint("E: Drive"), "E: Drive")

func test_legend_stays_narrow_with_long_key_names() -> void:
	var c := KeyBinds.defaults()
	c["move_up"] = KEY_PAGEUP
	c["use_tool"] = KEY_PAGEDOWN
	c["interact"] = KEY_BACKSPACE
	KeyBinds.apply(c)
	for m in KeyLegend.MODES:
		check(KeyLegend.panel_width(m) < 140.0, m)
	KeyBinds.apply(KeyBinds.defaults())

func test_page_fits_the_screen() -> void:
	check(Rect2(Vector2.ZERO, PauseModel.SCREEN).encloses(KeysPage.PANEL.grow(6)))
	check_eq(KeyBinds.LIST.size(), KeysPage.RESET, "one cell per action")
	for i in KeysPage.COUNT:
		var r := KeysPage.item_rect(i)
		check(KeysPage.PANEL.encloses(r), "item %d inside" % i)
		check_eq(KeysPage.item_at(r.get_center()), i)
		for j in i:
			check(not r.intersects(KeysPage.item_rect(j)), "no overlap %d %d" % [i, j])
	var last_line := KeysPage.item_rect(KeysPage.RESET).end.y + 32 + (KeysPage.FIXED.size() - 1) * 13
	check(last_line + 3 <= KeysPage.PANEL.end.y)
	for line in KeysPage.FIXED:
		check(ThemeDB.fallback_font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x <= KeysPage.PANEL.size.x - 8, line)
