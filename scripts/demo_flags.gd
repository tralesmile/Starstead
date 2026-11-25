class_name DemoFlags
extends RefCounted
## Screenshot/QA helpers: command-line flags after `--` (see tools/check.sh and docs/RUNBOOK.md). Kept out of main.gd.
## `m` is the Main node. Flags: --car-demo --race-demo --hut-demo --blueprint-demo --build-demo --enter-demo=KIND --sports-demo=MODE --fish-demo --chop-demo
## --farm-demo --fx-demo --journal-demo --pot-demo --chest-demo --garage-demo --cook-demo --bag-demo --levelup-demo
## --craft-demo --crime-demo (use with --at= in Port Halden) --drops-demo --mouse-demo --swing-demo (plus --hour=H --season=N --zoom=N --at=x,y --rain --fog --storm in main.gd).

var m

func _init(main) -> void:
	m = main

func on_ready() -> void:
	for a in OS.get_cmdline_user_args():   # demos and QA flags want the full toolbelt
		if a.ends_with("-demo") or a.begins_with("--sports-demo") or a.begins_with("--enter-demo") or a.begins_with("--arrow-demo") or a == "--allgear":
			GameState.tools_owned = ToolKit.all_tools()
	if "--car-demo" in OS.get_cmdline_user_args():  # screenshot helper: sit in the m.car and floor it
		m.player.position = m.car.position
		m.car.enter()
		if "--battered" in OS.get_cmdline_user_args():   # screenshot helper: a smoking engine
			m.car.health = 18.0
		Input.action_press("move_up")
		Input.action_press("move_right")
		if "--race-demo" in OS.get_cmdline_user_args():
			m.race.start()
	for a in OS.get_cmdline_user_args():   # screenshot helper: day-1 tutorial arrow (--arrow-demo=tree or bed)
		if a.begins_with("--arrow-demo"):
			var apc := Vector2i(floori(m.player.position.x / 32.0), floori(m.player.position.y / 32.0))
			GameState.farm.till(apc + Vector2i(2, 1))
			GameState.farm.plant(apc + Vector2i(2, 1), "turnip_seed", 0)
			if a.ends_with("=tree"):
				GameState.tools_owned.erase("watering_can")
	if "--bench-demo" in OS.get_cmdline_user_args() and m.town.bench_cell.x > -9000:   # screenshot helper: stand in front of the carpenter bench
		m.player.position = Vector2(m.town.bench_cell) * 32.0 + Vector2(16, 48)
	if "--fert-demo" in OS.get_cmdline_user_args():   # screenshot helper: a fertilised row beside a plain one
		var pc := Vector2i(floori(m.player.position.x / 32.0), floori(m.player.position.y / 32.0))
		for dx in 4:
			for dy in 2:
				GameState.farm.till(pc + Vector2i(dx + 1, dy + 1))
				if dy == 0:
					GameState.farm.fertilise(pc + Vector2i(dx + 1, dy + 1))
	if "--hut-demo" in OS.get_cmdline_user_args():  # screenshot helper: stamp a hut via the blueprint key path
		GameState.bag.add("wood", 99)
		m.player.position += Vector2(160, 0)
		m.player.facing = PlayerMath.Facing.RIGHT
		m.build_view.stamp_blueprint("hut")
	if "--blueprint-demo" in OS.get_cmdline_user_args():  # screenshot helper: the house and the animal pen side by side
		GameState.bag.add("wood", 400)
		m.player.facing = PlayerMath.Facing.RIGHT
		m.player.position += Vector2(96, -64)
		m.build_view.stamp_blueprint("house")
		m.player.position += Vector2(224, 0)
		m.build_view.stamp_blueprint("pen")
		m.player.position -= Vector2(256, -128)
		var pc := Vector2i(floori(m.player.position.x / 32.0), floori(m.player.position.y / 32.0))
		for dx in [-3, 0, 3]:   # lamp posts along the front (lit after dark)
			if GameState.build.place(pc + Vector2i(dx, 1), "lamp", 3.0, false, GameState.bag) == "":
				m.build_view._spawn(pc + Vector2i(dx, 1), "lamp")
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
	if "--treasure-demo" in OS.get_cmdline_user_args() and m.fishing.state == Fishing.State.REELING and not m.fishing.treasure_on:  # screenshot helper: a chest in the reel track
		m.fishing.treasure_on = true
		m.fishing.treasure_pos = 0.75
		m.fishing.treasure_prog = 0.45
	if "--leap-demo" in OS.get_cmdline_user_args() and Engine.get_process_frames() == 20:  # screenshot helper: a carp leaps from the water into your arms
		m.fish_fx.target = m.player.position + Vector2(70, 80)
		m.fish_fx.leap("carp")
	if "--knock-demo" in OS.get_cmdline_user_args() and Engine.get_process_frames() == 30:  # screenshot helper: the nearest pedestrian is knocked out
		var best: Array = []
		for t in m.folk.targets():
			if best.is_empty() or (t[0] as Node2D).position.distance_to(m.player.position) < (best[0] as Node2D).position.distance_to(m.player.position):
				best = t
		if not best.is_empty():
			m.combat._hurt(best[0], m.combat._state(best[0], best[1]), 999.0, 1.0, m.player.position)
	if "--crime-demo" in OS.get_cmdline_user_args() and Engine.get_process_frames() == 30:  # screenshot helper: a theft in Port Halden; pedestrians flee
		m.police.commit("theft", m.player.position)
	if "--map-demo" in OS.get_cmdline_user_args() and Engine.get_process_frames() == 3:  # screenshot helper: world map open
		m.map_view.toggle()
	if "--story-demo" in OS.get_cmdline_user_args() and Engine.get_process_frames() == 3:  # screenshot helper: quest log with a few beats done
		GameState.story.notify("enter_farmhouse")
		GameState.debt_paid = 500
		m.story_view.poll(2)
		m.story_view.toggle_log()
	if "--hunt-demo" in OS.get_cmdline_user_args() and Engine.get_process_frames() == 3:  # screenshot helper: wildlife around the player, a deer and a rabbit right in front of the club
		GameState.bag.add("club", 1)
		for id in ["deer", "rabbit", "boar"]:
			m.animals._spawn(id, m.player.position + Vector2(40 + 26 * ["deer", "rabbit", "boar"].find(id), -6), null)
		m.animals._spawn("deer", m.player.position + Vector2(-60, 30), null)
	if "--hunt-demo" in OS.get_cmdline_user_args() and Engine.get_process_frames() == 12:
		m.animals.hunt(m.player.position, Vector2.RIGHT, CombatModel.weapon("club"))
		m.animals.hunt(m.player.position, Vector2.RIGHT, CombatModel.weapon("club"))
	if "--shop-demo" in OS.get_cmdline_user_args() and Engine.get_process_frames() == 3:  # screenshot helper: the stall with a glut of turnips already sold
		GameState.bag.add("turnip", 12)
		GameState.bag.add("carp", 2)
		GameState.market.record("turnip", 10)
		m.shop.open()
	if "--craft-demo" in OS.get_cmdline_user_args() and Engine.get_process_frames() == 3:   # screenshot helper: the craft menu with wood, new-game toolbelt
		GameState.tools_owned = ToolKit.start()
		GameState.bag.add("wood", 5)
		m.craft_view.open()
	if "--smelt-demo" in OS.get_cmdline_user_args() and Engine.get_process_frames() == 3:  # screenshot helper: the furnace menu with ore in the bag
		GameState.bag.add("copper_ore", 4)
		GameState.bag.add("coal", 2)
		GameState.bag.add("iron_ore", 1)
		m.smelt_view.open()
	for a in OS.get_cmdline_user_args():   # screenshot helper: --shift-demo=timing|sequence|balance opens the job mini-game mid-play
		if a.begins_with("--shift-demo=") and Engine.get_process_frames() == 3:
			var k := a.get_slice("=", 1)
			m.jobs.game_view.open("farmhand", k, 1, 40, 7)
		if a.begins_with("--shift-demo=") and Engine.get_process_frames() == 14 and m.jobs.game_view.visible:
			var g: ShiftGame = m.jobs.game_view.game
			if g.kind == "timing":
				g.t = 0.9 / ShiftGame.timing_speed(0) * 1.0
				g.press_action()
			elif g.kind == "sequence":
				g.press_dir(g.seq[0])
				g.press_dir(g.seq[1])
	if "--crow-demo" in OS.get_cmdline_user_args() and Engine.get_process_frames() == 2:   # screenshot helper: ripe turnips with crows 5 tiles away (use --hour=9)
		var pc2 := Vector2i(floori(m.player.position.x / 32.0), floori(m.player.position.y / 32.0))
		for dx in 3:
			var cell := pc2 + Vector2i(dx + 3, -2)
			GameState.farm.till(cell)
			GameState.farm.soil[cell].crop = "turnip"
			GameState.farm.soil[cell].age = 99
	if "--forge-demo" in OS.get_cmdline_user_args() and Engine.get_process_frames() == 3:  # screenshot helper: the anvil menu with bars in the bag
		GameState.bag.add("iron_bar", 6)
		GameState.bag.add("copper_bar", 4)
		GameState.bag.add("hide", 3)
		m.forge_view.open()
	if "--cave-demo" in OS.get_cmdline_user_args() and Engine.get_process_frames() == 3:  # screenshot helper: stand inside the mine with a pickaxe
		GameState.energy.value = 100.0
		m.cave.enter(GameState.clock.day)
	if "--cave-demo" in OS.get_cmdline_user_args() and Engine.get_process_frames() == 40 and m.cave.active:
		var ore: Vector2i = m.cave.model.ores.keys()[0]
		m.player.position = m.cave.px(ore) + Vector2(16, 48)
		if "--cave-walls" in OS.get_cmdline_user_args():   # stand beside a torch and a wall edge
			m.player.position = m.cave.px(m.cave.model.torches[1]) + Vector2(16, 48)
	if m._arg_prefix("--cave-floor") and Engine.get_process_frames() == 40 and m.cave.active:   # screenshot helper: --cave-floor=3 goes down the ladders
		var fl := 3
		for a in OS.get_cmdline_user_args():
			if a.begins_with("--cave-floor="):
				fl = int(a.substr(13))
		m.cave.busy = false
		m.cave._do_change_floor(fl, true)
	if m._arg_prefix("--cave-floor") and Engine.get_process_frames() == 60 and m.cave.active:
		var spots: Array = m.cave.model.crab_spawns + m.cave.model.slime_spawns
		if not spots.is_empty():
			m.player.position = m.cave.px(spots[0]) + Vector2(16, 90)
		if "--cave-ladder" in OS.get_cmdline_user_args() and m.cave.model.has_ladder_down():
			m.player.position = m.cave.px(m.cave.model.ladder_down) + Vector2(16, -40)
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
	if "--ride-demo" in OS.get_cmdline_user_args() and Engine.get_process_frames() == 3:   # screenshot helper: gallop a tamed horse
		var st := {"id": "horse", "trust": 100.0, "hunger": 0.0, "gear": {}, "bond": 80}
		GameState.animals.append(st)
		m.animals._spawn("horse", m.player.position, st)
		m.animals._mount(m.animals.critters[m.animals.critters.size() - 1])
		Input.action_press("move_down")
		Input.action_press("sprint")
	if "--derby-demo" in OS.get_cmdline_user_args() and Engine.get_process_frames() == 3:
		GameState.money = maxi(GameState.money, 300)
		m.derby.open()
		m.derby.countdown = 0.0
		m.derby.bet = 50
		m.derby.force_gallop = true
	if m._arg_prefix("--enter-demo") and Engine.get_process_frames() == 3:
		var kind := "farmhouse"
		for a in OS.get_cmdline_user_args():
			if a.begins_with("--enter-demo="):
				kind = a.substr(13)
		if "--dog-demo" in OS.get_cmdline_user_args():   # screenshot helper: this house keeps a guard dog
			m.robbery.model.house(kind)["dog"] = true
		if "--safe-demo" in OS.get_cmdline_user_args():   # screenshot helper: this house has a safe and an armed alarm
			var hh: Dictionary = m.robbery.model.house(kind)
			hh["locked"] = false
			hh["safe"] = true
			hh["alarm"] = true
			hh["alarm_armed"] = true
		for b in m.town.buildings:
			if b["id"] == kind:
				m.player.position = TownModel.sprite_bottom_center(b) + Vector2(0, 40)
				m.interior.enter(b)
	if "--steal-demo" in OS.get_cmdline_user_args() and Engine.get_process_frames() == 10 and not m.car_theft.slots.is_empty():   # screenshot helper: stand beside the first parked car and hot-wire it
		var sl: Dictionary = m.car_theft.slots[0]
		m.player.position = (Vector2(sl["cell"]) + Vector2(0.5, 1.5)) * 32.0
	if "--steal-demo" in OS.get_cmdline_user_args() and Engine.get_process_frames() == 14:
		GameState.rep_street = 200   # odds 90%
		m.car_theft.try_steal(0, 12.0)
	if "--dealer-demo" in OS.get_cmdline_user_args() and Engine.get_process_frames() == 6:   # screenshot helper: the alley dealer window with a street name
		GameState.rep_street = 35
		GameState.rep_honest = 32
		GameState.money = 400
		m.police.add_heat(50.0)
		m.player.position = (Vector2(HarbourModel.DEALER_CELL) + Vector2(0.5, 1.6)) * 32.0
	if "--dealer-demo" in OS.get_cmdline_user_args() and Engine.get_process_frames() == 12:
		m.dealer.open()
	if "--alarm-demo" in OS.get_cmdline_user_args() and Engine.get_process_frames() == 20:   # siren flash in the room
		m.robbery.model.add_noise(50.0)
	if "--till-demo" in OS.get_cmdline_user_args() and Engine.get_process_frames() == 14 and m.interior.active:   # stand at the counter of a closed shop
		for f in m.interior.layout["furniture"]:
			if String(f["action"]) in ShopHours.TILL_ACTIONS:
				m.player.position = InteriorView.ORIGIN + (Vector2(f["cell"]) + Vector2(0.5, float(f["size"].y) + 0.5)) * 32.0
				break
	if "--wake-demo" in OS.get_cmdline_user_args() and Engine.get_process_frames() == 14:   # residents wake and shove
		m.robbery.model.add_noise(100.0)
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
	if "--hotspot-demo" in OS.get_cmdline_user_args():   # screenshot helper: hold a cast and see the day's hot water ripple
		var f2 := Engine.get_process_frames()
		m.hotbar.selected = 6
		m.player.facing = PlayerMath.Facing.DOWN
		if f2 == 2:
			var pc2 := Vector2i(floori(m.player.position.x / 32.0), floori(m.player.position.y / 32.0))
			var best := 1
			for d in range(1, 60):
				if FishSpots.hot_blocks_near(pc2, d).size() > FishSpots.hot_blocks_near(pc2, best).size():
					best = d
			GameState.clock.day = best
		if f2 == 3:
			var ev2 := InputEventAction.new()
			ev2.action = "use_tool"
			ev2.pressed = true
			m._unhandled_input(ev2)
	if "--chop-demo" in OS.get_cmdline_user_args():
		var f := Engine.get_process_frames()
		m.hotbar.selected = 4
		m.player.facing = PlayerMath.Facing.UP
		if f == 2:  # stand just below the nearest grass tree so the chops land on it
			var best := Vector2i.ZERO
			var bd := 1e9
			for tc in m.world.gen.trees:
				var dd: float = Vector2(tc).distance_to(Vector2(TargetMath.cell_of(m.player.position)))
				if dd < bd and m.world.gen.sdf_at(tc.x, tc.y + 1) > 3.0:
					bd = dd
					best = tc
			m.player.position = TargetMath.center_of(best + Vector2i(0, 1))
		if f > 3 and f % 5 == 0 and f <= 45:
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
		GameState.farm.scarecrows[o + Vector2i(-1, 3)] = true
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
	if "--upgrade-demo" in OS.get_cmdline_user_args() and Engine.get_process_frames() == 3:
		GameState.money = 1200
		GameState.home.buy("kitchen", 9999)
		m.upgrade_view.open()
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
