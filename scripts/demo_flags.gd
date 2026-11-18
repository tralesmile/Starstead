class_name DemoFlags
extends RefCounted
## Screenshot/QA helpers: command-line flags after `--` (see tools/check.sh and docs/RUNBOOK.md). Kept out of main.gd.
## `m` is the Main node. Flags: --car-demo --race-demo --hut-demo --build-demo --enter-demo=KIND --sports-demo=MODE --fish-demo --chop-demo
## --farm-demo --fx-demo --journal-demo --pot-demo --chest-demo --garage-demo --cook-demo --bag-demo --levelup-demo
## --drops-demo --mouse-demo --swing-demo (plus --hour=H --season=N --zoom=N --at=x,y --rain --fog --storm in main.gd).

var m

func _init(main) -> void:
	m = main

func on_ready() -> void:
	if "--car-demo" in OS.get_cmdline_user_args():  # screenshot helper: sit in the m.car and floor it
		m.player.position = m.car.position
		m.car.enter()
		Input.action_press("move_up")
		Input.action_press("move_right")
		if "--race-demo" in OS.get_cmdline_user_args():
			m.race.start()
	if "--hut-demo" in OS.get_cmdline_user_args():  # screenshot helper: stamp a hut via the blueprint key path
		GameState.bag.add("wood", 99)
		m.player.position += Vector2(160, 0)
		m.player.facing = PlayerMath.Facing.RIGHT
		m.build_view.stamp_blueprint("hut")
	if "--build-demo" in OS.get_cmdline_user_args():  # screenshot helper: a little house next to the m.player
		GameState.bag.add("wood", 99)
		var o := Vector2i(floori(m.player.position.x / 32.0), floori(m.player.position.y / 32.0)) + Vector2i(2, -3)
		var bm: BuildModel = GameState.build
		for dx in 4:
			for dy in 3:
				var c := o + Vector2i(dx, dy)
				var pid := "floor"
				if dy == 0 or dx == 0 or dx == 3:
					pid = "wall"
				if dy == 0 and dx == 2:
					pid = "door"
				if dy == 2 and dx > 0 and dx < 3:
					pid = "floor"
				bm.place(c, pid, 9.0, false, GameState.bag)
		for fx in range(5, 10):   # a connected fence run with a corner turning south
			bm.place(o + Vector2i(fx, 1), "fence", 9.0, false, GameState.bag)
		for fy in range(2, 5):
			bm.place(o + Vector2i(9, fy), "fence", 9.0, false, GameState.bag)
		m.build_view.setup(m.world, m.world.gen, m.player)

func on_process() -> void:
	if "--story-demo" in OS.get_cmdline_user_args() and Engine.get_process_frames() == 3:  # screenshot helper: quest log with a few beats done
		GameState.story.notify("enter_farmhouse")
		GameState.debt_paid = 500
		m.story_view.poll(2)
		m.story_view.toggle_log()
	if "--shop-demo" in OS.get_cmdline_user_args() and Engine.get_process_frames() == 3:  # screenshot helper: the stall with a glut of turnips already sold
		GameState.bag.add("turnip", 12)
		GameState.bag.add("carp", 2)
		GameState.market.record("turnip", 10)
		m.shop.open()
	if "--smelt-demo" in OS.get_cmdline_user_args() and Engine.get_process_frames() == 3:  # screenshot helper: the furnace menu with ore in the bag
		GameState.bag.add("copper_ore", 4)
		GameState.bag.add("coal", 2)
		GameState.bag.add("iron_ore", 1)
		m.smelt_view.open()
	if "--cave-demo" in OS.get_cmdline_user_args() and Engine.get_process_frames() == 3:  # screenshot helper: stand inside the mine with a pickaxe
		GameState.energy.value = 100.0
		m.cave.enter(GameState.clock.day)
	if "--cave-demo" in OS.get_cmdline_user_args() and Engine.get_process_frames() == 40 and m.cave.active:
		var ore: Vector2i = m.cave.model.ores.keys()[0]
		m.player.position = m.cave.px(ore) + Vector2(16, 70)
		if "--cave-walls" in OS.get_cmdline_user_args():   # stand beside a torch and a wall edge
			m.player.position = m.cave.px(m.cave.model.torches[1]) + Vector2(16, 70)
	if m._arg_prefix("--sports-demo") and Engine.get_process_frames() == 3:   # screenshot helper: --sports-demo=hoops|penalty|boxing
		var mode := "hoops"
		for a in OS.get_cmdline_user_args():
			if a.begins_with("--sports-demo="):
				mode = a.substr(14)
		GameState.money = maxi(GameState.money, 100)
		m.sports.open(mode)
		if mode == "boxing":
			m.sports.tele = 1
			m.sports.tele_t = 0.2
	if m._arg_prefix("--enter-demo") and Engine.get_process_frames() == 3:
		var kind := "farmhouse"
		for a in OS.get_cmdline_user_args():
			if a.begins_with("--enter-demo="):
				kind = a.substr(13)
		for b in m.town.buildings:
			if b["id"] == kind:
				m.player.position = TownModel.sprite_bottom_center(b) + Vector2(0, 40)
				m.interior.enter(b)
	if "--fish-demo" in OS.get_cmdline_user_args():
		var f := Engine.get_process_frames()
		m.hotbar.selected = 6
		m.player.facing = PlayerMath.Facing.DOWN
		if f == 3:
			var ev := InputEventAction.new()
			ev.action = "use_tool"
			ev.pressed = true
			m._unhandled_input(ev)
		if f == 9:
			m._rod_released()
		if f == 14:
			m.fishing.timer = 0.0
		if f == 24 and m.fishing.state == Fishing.State.BITE:
			m.fishing.fish_id = "perch"
			m.fishing.hook()
	if "--chop-demo" in OS.get_cmdline_user_args():
		var f := Engine.get_process_frames()
		m.hotbar.selected = 4
		m.player.facing = PlayerMath.Facing.UP
		if f > 3 and f % 5 == 0 and f <= 28:
			var ev := InputEventAction.new()
			ev.action = "use_tool"
			ev.pressed = true
			m._unhandled_input(ev)
	if "--farm-demo" in OS.get_cmdline_user_args() and Engine.get_process_frames() == 2:
		var o := TargetMath.cell_of(m.player.position) + Vector2i(2, -2)
		for dx in 5:
			for dy in 3:
				var c := o + Vector2i(dx, dy)
				GameState.farm.till(c)
				GameState.farm.soil[c].watered = (dx + dy) % 2 == 0
				GameState.farm.soil[c].crop = ("pumpkin" if dx == 4 else "tomato" if dx == 3 else "turnip") if dy < 2 else ""
				GameState.farm.soil[c].age = dx
				if dy == 2 and dx % 2 == 1:
					GameState.farm.weeds[c] = 0
		GameState.farm.sprinklers[o + Vector2i(-1, 1)] = true
	if "--fx-demo" in OS.get_cmdline_user_args():  # screenshot helper: pickup floaters + level-up burst
		var fr := Engine.get_process_frames()
		if fr == 5:
			m.float_fx.pickup(m.player.position, "wood", 2)
		if fr == 8:
			m.float_fx.pickup(m.player.position, "stone", 1)
		if fr == 10:
			m.float_fx.pickup(m.player.position, "turnip", 3)
	if "--journal-demo" in OS.get_cmdline_user_args() and Engine.get_process_frames() == 3:
		GameState.journal.record("minnow", 14)
		GameState.journal.record("carp", 38)
		GameState.journal.record("carp", 44)
		m.journal_view.toggle()
	if "--pot-demo" in OS.get_cmdline_user_args() and Engine.get_process_frames() == 3:
		var pc := TargetMath.cell_of(m.player.position)
		for dx in range(-3, 0):
			var c := pc + Vector2i(dx, 1)
			if GameState.pots.place(c, m.world.gen.sdf_at(c.x, c.y)):
				GameState.pots.pots[c]["ready"] = ["crab"] if dx == -2 else []
	if "--chest-demo" in OS.get_cmdline_user_args() and Engine.get_process_frames() == 3:
		GameState.chest.add("wood", 30)
		GameState.chest.add("egg", 6)
		GameState.bag.add("stone", 12)
		m.chest_view.open()
	if "--garage-demo" in OS.get_cmdline_user_args() and Engine.get_process_frames() == 3:
		m.car.health = 60.0
		m.car.fuel = 12.0
		m.garage_view.open()
	if "--cook-demo" in OS.get_cmdline_user_args() and Engine.get_process_frames() == 3:
		for id in ["potato", "egg", "turnip", "tomato", "pumpkin", "milk"]:
			GameState.bag.add(id, 2)
		m.cook_view.open()
	if "--bag-demo" in OS.get_cmdline_user_args() and Engine.get_process_frames() == 3:
		for id in ["wood", "stone", "egg", "milk", "minnow", "perch", "golden_koi", "wool", "worm_bait", "pike", "axe_copper"]:
			GameState.bag.add(id, 7)
		m.inv_view.toggle()
		m.inv_view.picked = 2
		GameState.skill_xp = {"farming": 190, "mining": 40, "fishing": 700}
	if "--bag-demo" in OS.get_cmdline_user_args():
		m.get_viewport().warp_mouse(Vector2(140 + 28 * 3 + 10, 96 + 28 + 8))
	if "--levelup-demo" in OS.get_cmdline_user_args() and Engine.get_process_frames() == 3:
		GameState.skill_xp["farming"] = 95
		m._skill_gain("farming")
	if "--drops-demo" in OS.get_cmdline_user_args() and Engine.get_process_frames() == 2:
		var ids := ["wood", "stone", "turnip", "egg", "minnow", "milk", "golden_koi", "wool"]
		for i in ids.size():
			m.drops_view.spawn(ids[i], 1, m.player.position + Vector2(70 + (i % 4) * 26, -20 + (i / 4) * 26))
	if "--mouse-demo" in OS.get_cmdline_user_args():  # screenshot helper: mouse hovering 2 tiles right of the m.player
		m.mouse_aim = true
		m.get_viewport().warp_mouse(Vector2(320 + 2 * 64 + 20, 180 - 10))
	if "--swing-demo" in OS.get_cmdline_user_args():  # screenshot helper: hold the axe mid-swing
		m.player.held_tool = "axe"
		m.player.facing = PlayerMath.Facing.RIGHT
		m.player.tool_t = 0.14
