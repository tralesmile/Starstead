class_name InputCheck
extends Node
## QA (--input-check): drives the running game with real key and mouse events, the way a player does, because
## demo flags call the handlers directly and hid dead menu clicks. Prints "INPUT CHECK ok N/N" when every step
## passes and a SCRIPT ERROR line for each one that does not. Needs a window (xvfb); tools/check.sh runs it.

var m   # the Main node
var passed := 0
var failed := 0

static func start(main: Node) -> void:
	var c := InputCheck.new()
	c.m = main
	c.process_mode = Node.PROCESS_MODE_ALWAYS   # keeps going while the pause menu is up
	main.add_child(c)
	c._run.call_deferred()

func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame

func _key(code: Key, down: bool) -> void:
	var e := InputEventKey.new()
	e.keycode = code
	e.physical_keycode = code
	e.pressed = down
	Input.parse_input_event(e)

func _tap(code: Key) -> void:
	_key(code, true)
	await _frames(1)
	_key(code, false)
	await _frames(1)

func _click(at: Vector2) -> void:
	get_viewport().warp_mouse(at)
	await _frames(1)
	for down in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.pressed = down
		e.position = at
		e.global_position = at
		get_viewport().push_input(e, true)
		await _frames(1)

func _expect(ok: bool, what: String) -> void:
	if ok:
		passed += 1
		print("INPUT ok   ", what)
	else:
		failed += 1
		printerr("SCRIPT ERROR: input check failed: ", what)

func _slot_center(i: int) -> Vector2:
	return WoodUI.grid_slot_rect(InventoryView.ORIGIN, i).get_center()

func _run() -> void:
	await _frames(4)
	var bag: Inventory = GameState.bag
	bag.add("stone", 3)
	var from := -1
	var to := -1
	for i in bag.slots.size():
		if bag.slots[i] != null and bag.slots[i].id == "stone":
			from = i
		elif bag.slots[i] == null and to < 0:
			to = i
	await _tap(KEY_TAB)
	_expect(m.inv_view.visible, "Tab opens the bag")
	await _click(_slot_center(from))
	_expect(m.inv_view.picked == from, "a click picks up a bag slot")
	await _click(_slot_center(to))
	_expect(bag.slots[to] != null and bag.slots[to].id == "stone" and bag.slots[from] == null, "a second click moves the stack")
	await _tap(KEY_TAB)
	_expect(not m.inv_view.visible, "Tab closes the bag")

	await _tap(KEY_ESCAPE)
	_expect(m.pause_view.active, "Esc pauses")
	await _tap(KEY_ESCAPE)
	_expect(not m.pause_view.active, "Esc resumes")

	await _tap(KEY_M)
	_expect(m.map_view.is_open(), "M opens the map")
	await _tap(KEY_M)
	_expect(not m.map_view.is_open(), "M closes the map")

	await _tap(KEY_K)
	_expect(m.story_view.log_open(), "K opens the quest log")
	await _tap(KEY_K)
	_expect(not m.story_view.log_open(), "K closes the quest log")

	await _tap(KEY_C)
	_expect(m.craft_view.visible, "C opens crafting")
	await _tap(KEY_ESCAPE)
	_expect(not m.craft_view.visible and not m.pause_view.active, "Esc closes crafting without pausing")

	var moved := false
	for code in [KEY_D, KEY_A, KEY_S, KEY_W]:
		var was: Vector2 = m.player.position
		_key(code, true)
		await _frames(4)
		_key(code, false)
		await _frames(4)
		if m.player.position.distance_to(was) > 8.0:
			moved = true
			break
	_expect(moved, "the walk keys move the player")

	if not ToolKit.owns(GameState.tools_owned, "club"):
		GameState.tools_owned.append("club")
	await _tap(KEY_8)
	_expect(m.hotbar.current() == "club", "8 picks the club")
	var energy: float = GameState.energy.value
	_key(KEY_F, true)
	await _frames(1)
	_key(KEY_F, false)
	_expect(GameState.energy.value < energy and m.swing_hit.busy() and m.combat.cd <= 0.0, "F starts a club swing that has not landed yet")
	await _frames(2)
	_expect(not m.swing_hit.busy() and m.combat.cd > 0.0, "the club blow lands a moment later")

	var total := passed + failed
	if failed == 0:
		print("INPUT CHECK ok %d/%d" % [passed, total])
	else:
		printerr("SCRIPT ERROR: input check: %d of %d steps failed" % [failed, total])
	get_tree().quit()
