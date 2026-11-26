class_name DemoFlags
extends RefCounted
## Screenshot/QA helpers: command-line flags after `--` (see tools/check.sh and docs/RUNBOOK.md). Kept out of main.gd.
## `m` is the Main node. Flags: --car-demo --race-demo --hut-demo --blueprint-demo --build-demo --enter-demo=KIND --sports-demo=MODE --fish-demo --chop-demo
## --farm-demo --fx-demo --journal-demo --pot-demo --chest-demo --garage-demo --cook-demo --bag-demo --levelup-demo
## --perk-demo --craft-demo --crime-demo (use with --at= in Port Halden) --drops-demo --mouse-demo --swing-demo (plus --hour=H --season=N --zoom=N --at=x,y --rain --fog --storm in main.gd).

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
	if "--welcome-demo" in OS.get_cmdline_user_args():   # screenshot helper: the welcome-back card
		m._setup_welcome()
	if "--save-roundtrip" in OS.get_cmdline_user_args():
		save_roundtrip.call_deferred()
	if "--door-demo" in OS.get_cmdline_user_args():   # screenshot helper: two wall runs with doors; you walk up to the right one, the left stays shut
		var base := Vector2i(floori(m.player.position.x / 32.0), floori(m.player.position.y / 32.0))
		for k in 7:
			var c := base + Vector2i(k - 4, -1)
			var pid := "door" if k == 1 or k == 4 else "wall"
			GameState.build.placed[c] = pid
			m.build_view._spawn(c, pid)
		m.player.position = Vector2(base) * 32.0 + Vector2(16, 12)
		m.player.facing = PlayerMath.Facing.UP
	if "--fishevent-demo" in OS.get_cmdline_user_args():   # screenshot helper: today's legendary sighting, camera on its shadow
		GameState.clock.day = 8
		GameState.clock.minutes = 13.0 * 60.0
	if "--mud-demo" in OS.get_cmdline_user_args():   # screenshot helper: boots caked in mud
		m.player._mud = 1.0
	if "--traffic-demo" in OS.get_cmdline_user_args():   # screenshot helper: cars and a hiker close to the camera on the open road
		m.traffic.ring = Vector2(70.0, 230.0)
		m.traffic.spawn_cd = 0.0
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
	if "--perk-demo" in OS.get_cmdline_user_args():   # screenshot helper: the level-5 farming perk chooser
		GameState.skill_xp["farming"] = SkillModel.THRESHOLDS[PerkModel.UNLOCK_LEVEL]
		m.perk_view.open("farming")

func save_roundtrip() -> void:
	## QA (--save-roundtrip): play a little, save, start over, load, and compare the whole save dictionary.
	var g := GameState
	var path := "user://qa_roundtrip.json"
	var pc := Vector2i(floori(m.player.position.x / 32.0), floori(m.player.position.y / 32.0))
	g.money = 1234
	g.energy.value = 37.0
	g.clock.day = 12
	g.farm.till(pc + Vector2i(2, 1))
	g.farm.plant(pc + Vector2i(2, 1), "turnip_seed", 1)
	g.bag.add("wood", 40)
	g.chest.add("stone", 7)
	g.build.place(pc + Vector2i(3, 0), "wall", 9.0, false, g.bag)
	g.build.place(pc + Vector2i(4, 0), "door", 9.0, false, g.bag)
	g.journal.record("carp", 44)
	g.skill_xp = {"fishing": 1100}
	g.choose_perk("fishing", String(PerkModel.options("fishing")[0]["id"]))
	g.nodes.hit(m.world.gen.trees[0], "axe")
	var before: Dictionary = g.to_dict()
	var before_text := JSON.stringify(before)
	g.save_game(path)
	g.reset_new("")
	var wiped := g.money != 1234 and g.farm.soil.is_empty() and g.build.placed.is_empty()
	var ok := g.load_game(path)
	var bad := SaveBoot.diff_keys(JSON.parse_string(before_text), g.to_dict())
	DirAccess.remove_absolute(path)
	if ok and wiped and bad.is_empty():
		print("save roundtrip ok (%d keys)" % before.size())
	else:
		print("SCRIPT save roundtrip failed: loaded=%s wiped=%s differing=%s" % [ok, wiped, bad])

func on_process() -> void:
	if "--fishevent-demo" in OS.get_cmdline_user_args() and Engine.get_process_frames() == 3:
		var s: Vector2i = m.fish_event_view.spot
		print("fish event ", m.event_fish, " at ", s)
		if s.x >= 0:
			m.player.position = Vector2(s) * 32.0 + Vector2(60, -14)
	if "--traffic-debug" in OS.get_cmdline_user_args() and Engine.get_process_frames() % 40 == 0:
		print("TRAFFIC ", m.player.position, "\n", m.traffic.debug_text())
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
	if "--bow-demo" in OS.get_cmdline_user_args():   # screenshot helper: two arrows stuck, one in flight, the third drawn at a deer
		var fr := Engine.get_process_frames()
		if fr == 3:
			GameState.bag.add("arrow", 12)
			if not "bow" in GameState.tools_owned:
				GameState.tools_owned.append("bow")
			m.hotbar.selected = ToolUse.TOOLS.find("club")
			m.hotbar.melee_idx = 1
			m.player.facing = PlayerMath.Facing.RIGHT
			m.animals._spawn("deer", m.player.position + Vector2(150, 4), null)
			m.bow.stuck.append({"pos": m.player.position + Vector2(70, 34), "angle": 0.25, "t": 40.0})
			m.bow.stuck.append({"pos": m.player.position + Vector2(104, -26), "angle": -0.15, "t": 40.0})
		if fr == 5:
			m.bow.aim = Vector2(1.0, 0.45)
			m.bow.loose(1.0)
		if fr >= 6 and not m.bow.drawing:
			m.bow.cd = 0.0
			m.bow.press()
		if fr >= 6:
			m.mouse_aim = false
			m.player.facing = PlayerMath.Facing.RIGHT
	if "--ferry-demo" in OS.get_cmdline_user_args() and Engine.get_process_frames() == 3:   # screenshot helper: stand by the pier-head ferry post
		GameState.money = maxi(GameState.money, 100)
		m.player.position = (Vector2(FerryModel.HARBOUR_LANDING) + Vector2(0.5, 0.6)) * 32.0
	if "--ferry-demo" in OS.get_cmdline_user_args() and "--crossing" in OS.get_cmdline_user_args() and Engine.get_process_frames() == 8:   # ... and board
		FerryActions.run(m, true)
	if "--isle-demo" in OS.get_cmdline_user_args() and Engine.get_process_frames() == 3:   # screenshot helper: on Gull Isle's beach beside today's first find
		var spot: Vector2i = IsleModel.forage(GameState.clock.day, false)[0]["cell"]
		var inland := Vector2(IsleModel.CENTER - Vector2(spot)).normalized() * 2.2
		m.player.position = (Vector2(spot) + Vector2(0.5, 0.6) + inland) * 32.0
	if "--sfx-log" in OS.get_cmdline_user_args():   # QA: walk, shoot, spend money; print which sounds played and the ambience mix
		var f := Engine.get_process_frames()
		if f == 3:
			Input.action_press("move_left")
		if f == 30:
			Input.action_release("move_left")
			GameState.money += 5
			GameState.bag.add("arrow", 3)
			GameState.tools_owned = ToolKit.all_tools()
			GameState.tools_owned.append("bow")
			m.hotbar.selected = ToolUse.TOOLS.find("club")
			m.hotbar.melee_idx = 1
			m.bow.cd = 0.0
			m.bow.press()
		if f == 34:
			m.bow.held_t = BowMath.DRAW_TIME
			m.bow.release()
		if f == 38:
			m.inv_view.visible = true
		if f == 55:
			print("SFX ", m.sfx_director.sfx.play_counts, " ambience ", m.sfx_director.sfx.ambience)
	if "--perfect-demo" in OS.get_cmdline_user_args() and m.bow.drawing:   # with --bow-demo: hold the string inside the perfect window
		m.bow.held_t = BowMath.DRAW_TIME + 0.05
	if "--shop-demo" in OS.get_cmdline_user_args() and Engine.get_process_frames() == 3:  # screenshot helper: the stall with a glut of turnips already sold
		GameState.bag.add("turnip", 12)
		GameState.bag.add("carp", 2)
		GameState.market.record("turnip", 10)
		m.shop.open()
	if "--shop-buy" in OS.get_cmdline_user_args() and Engine.get_process_frames() == 4:   # with --shop-demo: the long BUY list, scrolled
		m.shop.menu.switch_tab()
		m.shop.menu.cursor = 14
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
	if "--bus-demo" in OS.get_cmdline_user_args() and Engine.get_process_frames() == 3:  # screenshot helper: the bus stop menu at the homestead stop
		GameState.money = maxi(GameState.money, 60)
		var st: Dictionary = m.bus_stops.stops[0]
		m.player.position = (Vector2(st["cell"]) + Vector2(1.0, 1.8)) * 32.0
	if "--bus-demo" in OS.get_cmdline_user_args() and Engine.get_process_frames() == 8:
		m._open_bus(m.bus_stops.near())
	if "--butcher-demo" in OS.get_cmdline_user_args() and Engine.get_process_frames() == 3:  # screenshot helper: the butcher block menu with game in the bag
		GameState.bag.add("raw_meat", 4)
		GameState.bag.add("hide", 5)
		GameState.bag.add("feather", 2)
		GameState.bag.add("leather", 3)
		m.butcher_view.open()
	if "--cave-demo" in OS.get_cmdline_user_args() and Engine.get_process_frames() == 3:  # screenshot helper: stand inside the mine with a pickaxe
		GameState.energy.value = 100.0
		m.cave.enter(GameState.clock.day)
	if "--cave-demo" in OS.get_cmdline_user_args() and Engine.get_process_frames() == 40 and m.cave.active and not ("--cart-demo" in OS.get_cmdline_user_args()):
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
	if "--boss-demo" in OS.get_cmdline_user_args() and Engine.get_process_frames() == 62 and m.cave.active and m.cave.boss != null:   # with --cave-demo --cave-floor=6: the Warden mid-slam, enraged
		m.player.position = m.cave.boss.model.pos + Vector2(52, 40)
		m.player.facing = PlayerMath.Facing.UP
		GameState.warden_day = -1
		m.cave.boss.model.take_hit(400.0 * 0.9)
	if "--cart-demo" in OS.get_cmdline_user_args() and Engine.get_process_frames() == 44 and m.cave.active:   # with --cave-demo: ride the mine cart down the track
		var at := CartMath.pos_at(m.cave.cart_pts, 0.0)
		m.player.position = at + Vector2(0, 20)
		m.cave.board()
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
	if "--hangar-demo" in OS.get_cmdline_user_args() and Engine.get_process_frames() == 3:
		m.hangar.open()
		m.hangar.demo_pos = Vector2(6.5 * 32.0, 6.5 * 32.0)
		m.hangar.opened = [0]
	if m._arg_prefix("--football-demo") and Engine.get_process_frames() == 3:
		# screenshot helper: --football-demo=lobby|play|goal|result (with --rain for a wet pitch)
		var fv: FootballView = m.football_view
		fv.rain = m.rain_today
		fv.open()
		var args := OS.get_cmdline_user_args()
		if not ("--football-demo=lobby" in args):
			GameState.money = maxi(GameState.money, 100)
			fv.kick_off(7)
			fv.game.auto = true
			var warm := 9.0
			if "--football-demo=goal" in args:
				while int(fv.game.score[0]) + int(fv.game.score[1]) == 0 and not fv.game.finished:
					fv.game.update(FootballMatch.TICK)
				fv.game.events = ["goal0" if int(fv.game.score[0]) > 0 else "goal1"]
			elif "--football-demo=result" in args:
				while not fv.game.finished:
					fv.game.update(0.2)
			else:
				while warm > 0.0:
					fv.game.update(0.1)
					warm -= 0.1
				fv.game.events = []
				fv.banner_t = 0.0
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
	if "--passout-demo" in OS.get_cmdline_user_args() and Engine.get_process_frames() == 8:   # collapse far from home
		GameState.money = 900
		GameState.energy.value = 0.0
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
		if f == 24 and m.fishing.state == Fishing.State.BITE and not "--wait-only" in OS.get_cmdline_user_args():
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
	if "--snare-demo" in OS.get_cmdline_user_args() and Engine.get_process_frames() == 3:
		var sc := TargetMath.cell_of(m.player.position)
		for dx in range(1, 4):
			var c := sc + Vector2i(dx, 0)
			if GameState.snares.place(c, 4.0, "meadow"):
				GameState.snares.snares[c]["ready"] = ["raw_meat"] if dx == 2 else []
	if "--artisan-demo" in OS.get_cmdline_user_args() and Engine.get_process_frames() == 3:   # screenshot helper (with --enter-demo=barn): two machines ready, two working
		GameState.artisan.slots = {"press": {"out": "cheese", "days_left": 0}, "jar1": {"out": "jam", "days_left": 2}, "jar2": {"out": "pickles", "days_left": 0}, "loom": {"out": "cloth", "days_left": 1}}
		GameState.bag.add("milk", 2)
	if "--artisan-demo" in OS.get_cmdline_user_args() and Engine.get_process_frames() == 14 and m.interior.active:
		m.player.position = InteriorView.ORIGIN + Vector2(2.5 * 32.0, 1.6 * 32.0)
		m.player.facing = PlayerMath.Facing.UP
	if "--gear-demo" in OS.get_cmdline_user_args() and Engine.get_process_frames() == 3:   # screenshot helper: tamed animals in their gear beside the player
		var worn := {"horse": {"coat": "fur_coat", "saddle": "saddle", "armour": "armour"}, "cow": {"coat": "fur_coat", "saddle": "saddle"}, "goat": {"coat": "fur_coat"}, "sheep": {"armour": "armour"}, "chicken": {"armour": "armour"}}
		var i := 0
		for id in worn:
			var at: Vector2 = m.player.position + Vector2(-96.0 + 48.0 * i, 30.0 + 14.0 * (i % 2))
			var st := {"id": id, "trust": 100.0, "hunger": 0.0, "gear": worn[id], "bond": 0, "stay": true, "hx": at.x, "hy": at.y}
			m.animals._spawn(id, at, st)
			i += 1
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
