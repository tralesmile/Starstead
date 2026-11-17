extends Node2D
## World root: chunk + player + HUD + day/night; passing out advances the day and saves.

var player: Player
var modulate_node: CanvasModulate
var world: World
var hotbar: Hotbar
var toast: Label
var toast_t := 0.0
var highlighted: Sprite2D = null
var shop: ShopView
var build_view: BuildView
var ambient: AmbientView
var npcs: NpcView
var dialogue: DialogueView
var car: CarView
var police: PoliceView
var robbery: RobberyView
var combat: CombatView
var animals: AnimalView
var cursor: CursorView
var rod_charging := false
var rod_charge_t := 0.0
var interior: InteriorView
var fish_fx: FishingWorldView
var inv_view: InventoryView
var drops_view: DropsView
var mouse_aim := false
var legend: Label
var jobs: JobView
var race: RaceView
var town: TownView
var fog_rect: ColorRect
var flash_rect: ColorRect
var storm_t := 0.0
var weather: WeatherView
var rain_today := 0.0
var rain_day := -1
var prompt: Label
var fishing := Fishing.new(int(Time.get_unix_time_from_system()))
var fish_table: Dictionary = DataDB.load_json("fish")
var bait_table: Dictionary = DataDB.load_json("bait")
var rod_table: Dictionary = DataDB.load_json("rods")
var axe_table: Dictionary = DataDB.load_json("axes")

func _ready() -> void:
	y_sort_enabled = true
	world = World.new()
	add_child(world)
	world.build(1)
	add_child(FarmView.new())
	town = TownView.new()
	town.setup(world, world.gen, world.stall_cell())
	world.add_child(town)
	for c in world.gen.trees:
		GameState.nodes.add("tree", c)
	for c in world.gen.rocks:
		GameState.nodes.add("rock", c)
	player = Player.new()
	player.gen = world.gen
	for lp in world.lily_pads:
		lp.player = player
	player.position = Vector2(32.5, 32.5) * 32.0
	if world.gen.dock.size() > 0:  # start at the dock: the first view is the pond
		var d0: Vector2i = world.gen.dock[0]
		var d1: Vector2i = world.gen.dock[1]
		player.position = (Vector2(d0 - (d1 - d0)) + Vector2(0.5, 0.6)) * 32.0
	world.add_child(player)  # same y-sorted parent as props so it can walk behind trees
	modulate_node = CanvasModulate.new()
	add_child(modulate_node)
	var fog_layer := CanvasLayer.new()
	fog_layer.layer = 5
	fog_rect = ColorRect.new()
	fog_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fog_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fog_rect.color = Color(0.82, 0.86, 0.9, 0.0)
	fog_layer.add_child(fog_rect)
	flash_rect = ColorRect.new()
	flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash_rect.color = Color(0.85, 0.9, 1.0, 0.0)
	fog_layer.add_child(flash_rect)
	add_child(fog_layer)
	add_child(Hud.new())
	hotbar = Hotbar.new()
	add_child(hotbar)
	toast = Label.new()
	toast.position = Vector2(8, 24)
	add_child(toast)
	ambient = AmbientView.new()
	ambient.player = player
	world.add_child(ambient)
	player.footstep.connect(func(): ambient.puff(player.position))
	var fp := FootprintView.new()
	fp.player = player
	fp.gen = world.gen
	world.add_child(fp)
	weather = WeatherView.new()
	weather.player = player
	weather.gen = world.gen
	world.add_child(weather)
	npcs = NpcView.new()
	npcs.setup(world, world.gen)
	world.add_child(npcs)
	car = CarView.new()
	car.player = player
	car.world = world
	car.position = _car_spot()
	car.toast.connect(_say)
	world.add_child(car)
	police = PoliceView.new()
	police.setup(world, player, self, world.gen)
	police.message.connect(_say)
	car.crime.connect(police.commit)
	world.add_child(police)
	robbery = RobberyView.new()
	robbery.setup(town, world, police, player)
	robbery.message.connect(_say)
	add_child(robbery)
	race = RaceView.new()
	race.setup(car, world, world.gen, self)
	race.message.connect(_say)
	add_child(race)
	jobs = JobView.new()
	jobs.setup(player, town.buildings, world.stall_cell())
	jobs.message.connect(_say)
	add_child(jobs)
	animals = AnimalView.new()
	animals.setup(world, player, world.gen)
	animals.message.connect(_say)
	world.add_child(animals)
	combat = CombatView.new()
	combat.setup(world, player, npcs, police)
	combat.message.connect(_say)
	combat.car = car
	police.combat = combat
	npcs.combat = combat
	add_child(combat)
	add_child(FishingView.new(fishing))
	fish_fx = FishingWorldView.new()
	fish_fx.setup(fishing, player)
	world.add_child(fish_fx)
	build_view = BuildView.new()
	add_child(build_view)
	build_view.setup(world, world.gen, player)
	build_view.message.connect(_say)
	shop = ShopView.new()
	shop.closed.connect(func(): player.set_physics_process(true))
	add_child(shop)
	dialogue = DialogueView.new()
	add_child(dialogue)
	inv_view = InventoryView.new()
	inv_view.closed.connect(func(): player.set_physics_process(true))
	add_child(inv_view)
	interior = InteriorView.new()
	interior.setup(world, player, self)
	interior.sleep_requested.connect(_sleep)
	interior.loot_requested.connect(func(b): robbery.interact(b["door"]))
	add_child(interior)
	drops_view = DropsView.new()
	drops_view.setup(world, player)
	drops_view.picked.connect(func(id, n): _say("+%d %s" % [n, String(DataDB.load_json("items").get(id, {}).get("name", id))]))
	add_child(drops_view)
	cursor = CursorView.new()
	cursor.z_index = 30
	world.add_child(cursor)
	legend = Label.new()
	legend.position = Vector2(8, 347)
	legend.add_theme_font_size_override("font_size", 10)
	legend.modulate = Color(1, 1, 1, 0.7)
	legend.text = "Click: use tool   Right-click / E: interact   Wheel: tool   +/-: zoom   Tab: bag   Shift: sprint"
	var leg_layer := CanvasLayer.new()
	leg_layer.add_child(legend)
	add_child(leg_layer)
	prompt = Label.new()
	prompt.position = Vector2(260, 300)
	add_child(prompt)
	if GameState.bag.count("turnip_seed") == 0:
		GameState.bag.add("turnip_seed", 10)
		GameState.bag.add("turnip", 4)  # treats for taming the first animals
	for a in OS.get_cmdline_user_args():  # screenshot helper: --hour=22 sets the clock
		if a.begins_with("--hour="):
			GameState.clock.minutes = (float(a.substr(7)) - 6.0) * 60.0
	if "--car-demo" in OS.get_cmdline_user_args():  # screenshot helper: sit in the car and floor it
		player.position = car.position
		car.enter()
		Input.action_press("move_up")
		Input.action_press("move_right")
		if "--race-demo" in OS.get_cmdline_user_args():
			race.start()
	if "--hut-demo" in OS.get_cmdline_user_args():  # screenshot helper: stamp a hut via the blueprint key path
		GameState.bag.add("wood", 99)
		player.position += Vector2(160, 0)
		player.facing = PlayerMath.Facing.RIGHT
		build_view.stamp_blueprint("hut")
	if "--build-demo" in OS.get_cmdline_user_args():  # screenshot helper: a little house next to the player
		GameState.bag.add("wood", 99)
		var o := Vector2i(floori(player.position.x / 32.0), floori(player.position.y / 32.0)) + Vector2i(2, -3)
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
		bm.place(o + Vector2i(5, 1), "fence", 9.0, false, GameState.bag)
		build_view.setup(world, world.gen, player)
	$HUD.queue_free()

func _process(delta: float) -> void:
	if rod_charging:
		rod_charge_t += delta
	fish_fx.charge = CastMath.power(rod_charge_t) if rod_charging else -1.0
	if _arg_prefix("--enter-demo") and Engine.get_process_frames() == 3:
		var kind := "farmhouse"
		for a in OS.get_cmdline_user_args():
			if a.begins_with("--enter-demo="):
				kind = a.substr(13)
		for b in town.buildings:
			if b["id"] == kind:
				player.position = TownModel.sprite_bottom_center(b) + Vector2(0, 40)
				interior.enter(b)
	if "--fish-demo" in OS.get_cmdline_user_args():
		var f := Engine.get_process_frames()
		hotbar.selected = 6
		player.facing = PlayerMath.Facing.DOWN
		if f == 3:
			var ev := InputEventAction.new()
			ev.action = "use_tool"
			ev.pressed = true
			_unhandled_input(ev)
		if f == 9:
			_rod_released()
		if f == 14:
			fishing.timer = 0.0
		if f == 24 and fishing.state == Fishing.State.BITE:
			fishing.fish_id = "perch"
			fishing.hook()
	if "--chop-demo" in OS.get_cmdline_user_args():
		var f := Engine.get_process_frames()
		hotbar.selected = 4
		player.facing = PlayerMath.Facing.UP
		if f > 3 and f % 5 == 0 and f <= 28:
			var ev := InputEventAction.new()
			ev.action = "use_tool"
			ev.pressed = true
			_unhandled_input(ev)
	if "--farm-demo" in OS.get_cmdline_user_args() and Engine.get_process_frames() == 2:
		var o := TargetMath.cell_of(player.position) + Vector2i(2, -2)
		for dx in 5:
			for dy in 3:
				var c := o + Vector2i(dx, dy)
				GameState.farm.till(c)
				GameState.farm.soil[c].watered = (dx + dy) % 2 == 0
				GameState.farm.soil[c].crop = "turnip" if dy < 2 else ""
				GameState.farm.soil[c].age = dx
	if "--bag-demo" in OS.get_cmdline_user_args() and Engine.get_process_frames() == 3:
		for id in ["wood", "stone", "egg", "milk", "minnow", "perch", "golden_koi", "wool", "worm_bait", "pike", "axe_copper"]:
			GameState.bag.add(id, 7)
		inv_view.toggle()
		inv_view.picked = 2
	if "--bag-demo" in OS.get_cmdline_user_args():
		get_viewport().warp_mouse(Vector2(140 + 28 * 3 + 10, 96 + 28 + 8))
	if "--drops-demo" in OS.get_cmdline_user_args() and Engine.get_process_frames() == 2:
		var ids := ["wood", "stone", "turnip", "egg", "minnow", "milk", "golden_koi", "wool"]
		for i in ids.size():
			drops_view.spawn(ids[i], 1, player.position + Vector2(70 + (i % 4) * 26, -20 + (i / 4) * 26))
	if "--mouse-demo" in OS.get_cmdline_user_args():  # screenshot helper: mouse hovering 2 tiles right of the player
		mouse_aim = true
		get_viewport().warp_mouse(Vector2(320 + 2 * 64 + 20, 180 - 10))
	if "--swing-demo" in OS.get_cmdline_user_args():  # screenshot helper: hold the axe mid-swing
		player.held_tool = "axe"
		player.facing = PlayerMath.Facing.RIGHT
		player.tool_t = 0.14
	if GameState.clock.advance(delta):
		_end_day()
	if rain_day != GameState.clock.day:
		rain_day = GameState.clock.day
		rain_today = WeatherMath.rain_for_day(1, rain_day, GameState.clock.season())
		if "--rain" in OS.get_cmdline_user_args():
			rain_today = 1.0
		weather.intensity = rain_today
	var fog := WeatherMath.fog_now(WeatherMath.fog_for_day(1, rain_day, GameState.clock.season(), rain_today), GameState.clock.minutes)
	if "--fog" in OS.get_cmdline_user_args():
		fog = 0.6
	fog_rect.color = Color(0.82, 0.86, 0.9, fog * 0.75)
	storm_t += delta
	player.rain = weather.now
	fog_rect.size = get_viewport_rect().size  # CanvasLayer parent has no size: anchors alone leave it 0x0
	flash_rect.size = fog_rect.size
	var fl := WeatherMath.lightning_flash(1, rain_day, storm_t, weather.now)
	if "--storm" in OS.get_cmdline_user_args():
		fl = 0.8
	flash_rect.color = Color(0.85, 0.9, 1.0, fl * 0.55)
	modulate_node.color = DayNight.tint(GameState.clock.minutes) * WeatherMath.darken(weather.now)
	if interior.active:
		modulate_node.color = Color(1.0, 0.95, 0.86)  # warm lamp-lit room

	_update_fishing(delta)
	world.set_lamps(DayNight.lamp_strength(GameState.clock.minutes))
	town.set_night(0.0 if interior.active else DayNight.lamp_strength(GameState.clock.minutes))
	world.part_reeds(player.position, delta)
	var near := world.interactables.near(player.position, _target_cell())
	var npc_near := npcs.near(player.position + Vector2(0, -8))
	prompt.text = "" if shop.visible else String(near.get("prompt", ""))
	if prompt.text == "" and not shop.visible and not npc_near.is_empty():
		prompt.text = "E: Talk to " + String(npc_near["name"])
	if interior.active:
		prompt.text = interior.prompt()
	elif prompt.text == "" and not shop.visible:
		prompt.text = jobs.prompt()
	var an_near := animals.near(player.position)
	if prompt.text == "" and not shop.visible and not an_near.is_empty():
		prompt.text = animals.prompt_for(an_near)
	if animals.riding != null:
		prompt.text = "E: Dismount"
	if car.can_enter() and prompt.text == "":
		prompt.text = "E: Drive"
	elif car.driving:
		prompt.text = "Fuel %d%%  E: exit" % int(100.0 * car.fuel / VehicleMath.FUEL_MAX)
	player.zoom_bias = (0 if interior.active else -1 if (car.driving or animals.riding != null) else 0)
	weather.visible = not interior.active
	ambient.visible = not interior.active
	fog_rect.visible = not interior.active
	flash_rect.visible = not interior.active
	_update_cursor()
	_update_highlight()
	_update_fade(delta)
	toast_t -= delta
	if toast_t <= 0.0:
		toast.text = ""

func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_released("use_tool") or (e is InputEventMouseButton and not e.pressed and e.button_index == MOUSE_BUTTON_LEFT):
		_rod_released()
	if e is InputEventMouseMotion:
		mouse_aim = true
	elif e is InputEventKey and e.pressed and not e.echo and (e.is_action_pressed("move_up") or e.is_action_pressed("move_down") or e.is_action_pressed("move_left") or e.is_action_pressed("move_right")):
		mouse_aim = false  # walking with the keyboard goes back to the tile in front of you
	if e is InputEventMouseButton and e.pressed and not shop.visible:
		if e.button_index == MOUSE_BUTTON_WHEEL_UP or e.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			var dir := -1 if e.button_index == MOUSE_BUTTON_WHEEL_UP else 1
			if e.ctrl_pressed:
				player.zoom_step = TargetMath.zoom_step(player.zoom_step, -dir)
			else:
				hotbar.selected = TargetMath.cycle(hotbar.selected, dir, ToolUse.TOOLS.size())
			return
		if e.button_index == MOUSE_BUTTON_LEFT or e.button_index == MOUSE_BUTTON_RIGHT:
			mouse_aim = true
			var act := "use_tool" if e.button_index == MOUSE_BUTTON_LEFT else "interact"
			var ev := InputEventAction.new()
			ev.action = act
			ev.pressed = true
			_unhandled_input(ev)
			return
	if e is InputEventKey and e.pressed and not e.echo and (e.keycode == KEY_EQUAL or e.keycode == KEY_KP_ADD):
		player.zoom_step = TargetMath.zoom_step(player.zoom_step, 1)
	elif e is InputEventKey and e.pressed and not e.echo and (e.keycode == KEY_MINUS or e.keycode == KEY_KP_SUBTRACT):
		player.zoom_step = TargetMath.zoom_step(player.zoom_step, -1)
	if not shop.visible and not car.driving and not dialogue.visible and inv_view.handle(e):
		if inv_view.visible:
			player.velocity = Vector2.ZERO
			player.move_v = Vector2.ZERO
			player.set_physics_process(false)
		get_viewport().set_input_as_handled()
		return
	if interior.active:
		if interior.busy:
			return
		if e.is_action_pressed("interact"):
			interior.interact()
		elif e.is_action_pressed("pause"):
			interior.leave()
		return
	if dialogue.handle(e):
		get_viewport().set_input_as_handled()
		return
	if shop.visible:
		return
	if build_view.handle_key(e):
		return
	if e.is_action_pressed("interact") and car.driving:
		if car.leave() and _near_workshop(car.position):
			var m := car.repair(GameState.bag)
			if m != "":
				_say(m)
		return
	if e.is_action_pressed("interact") and car.can_enter():
		car.enter()
		return
	if car.driving:
		return  # hands on the wheel: no tools
	if e.is_action_pressed("interact") and animals.riding != null:
		animals.dismount()
		return
	if e.is_action_pressed("interact"):
		var it := world.interactables.near(player.position, _target_cell())
		var nn := npcs.near(player.position + Vector2(0, -8))
		if it.is_empty() and not nn.is_empty():
			dialogue.open(nn["npc"], nn["activity"])
			return
		var an := animals.near(player.position)
		if it.is_empty() and not an.is_empty():
			animals.interact(an)
			return
		if it.get("kind", "") == "door":
			var fc := _target_cell()
			var pc := Vector2i(floori(player.position.x / 32.0), floori(player.position.y / 32.0))
			var dcell := fc if not robbery.building_at(fc).is_empty() else pc
			var bb := robbery.building_at(dcell)
			if not bb.is_empty() and (String(bb["id"]) in InteriorModel.PUBLIC or not robbery.model.house(String(bb["id"]))["locked"]):
				interior.enter(bb)
			else:
				robbery.interact(dcell)
			return
		if it.get("kind", "") == "shop":
			player.velocity = Vector2.ZERO
			player.move_v = Vector2.ZERO
			player.set_physics_process(false)
			shop.open()
			return
	if e.is_action_pressed("use_tool") and hotbar.current() == "rod":
		_rod_pressed()
	elif e.is_action_pressed("use_tool") and hotbar.current() == "club":
		if GameState.energy.can_use("club") and combat.cd <= 0.0:
			GameState.energy.spend("club")
			player.held_tool = "club"
			player.swing()
			combat.attack("club")
	elif e.is_action_pressed("use_tool"):
		player.held_tool = hotbar.current()
		player.swing()
		var cell := _target_cell()
		var dl: Array = []
		if hotbar.current() == "watering_can":
			if world.gen.sdf_at(cell.x, cell.y) < 0.0:
				var added := GameState.can.refill()
				_say("Refilled the can" if added > 0 else "The can is full")
				_splash_fx(cell)
				return
			if GameState.can.is_empty():
				_say("The can is empty - face the water and use it to refill")
				return
		var msg := ToolUse.apply(hotbar.current(), cell, GameState.farm, GameState.bag, GameState.clock.season(), world.gen, GameState.nodes, GameState.energy, dl, axe_table)
		for d in dl:
			drops_view.spawn(d["id"], int(d["n"]), TargetMath.center_of(cell) + Vector2(0, 6))
		if hotbar.current() == "axe" and world.props.has(cell) and world.gen.trees.has(cell):
			var tspr := world.prop_sprite(cell)
			if msg.begins_with("Got"):
				ChopFx.fall(world, tspr, (world.props[cell] as Node2D).position, ChopFx.fall_dir(player.position.x, (world.props[cell] as Node2D).position.x))
			elif msg == "Hit":
				ChopFx.wobble(tspr, tspr)
				ChopFx.leaves(world, (world.props[cell] as Node2D).position + Vector2(0, -34), 5)
		var sk := ""
		if msg.begins_with("Harvested"):
			sk = "farming"
			if SkillModel.roll_bonus(SkillModel.level(int(GameState.skill_xp.get("farming", 0))), randf()) > 0 and not dl.is_empty():
				drops_view.spawn(dl[0]["id"], 1, TargetMath.center_of(cell) + Vector2(8, 10))
				msg += " +1 bonus"
		elif msg.begins_with("Got") and hotbar.current() == "axe":
			sk = "foraging"
		elif msg.begins_with("Got") and hotbar.current() == "pickaxe":
			sk = "mining"
		if sk != "" and SkillModel.gain(GameState.skill_xp, sk):
			msg = "%s level %d!" % [sk.capitalize(), SkillModel.level(int(GameState.skill_xp[sk]))]
		world.sync_props(GameState.nodes)
		if msg == "Tilled":
			_dirt_puff(cell)
		if msg == "Watered":
			GameState.can.use()
			_splash_fx(cell, true)
		if msg != "" and (hotbar.current() == "axe" or hotbar.current() == "pickaxe"):
			_hit_feedback(cell, hotbar.current(), msg.begins_with("Got"))
		if msg != "":
			toast.text = msg
			toast_t = 1.5

func _update_highlight() -> void:
	## Yellow outline on the tree/rock the player faces (the interact target).
	var cell := _target_cell()
	var s: Sprite2D = null
	if GameState.nodes.is_solid(cell):
		s = world.prop_sprite(cell)
	if s != highlighted:
		if highlighted != null:
			Outline.set_enabled(highlighted, false)
		if s != null:
			Outline.set_enabled(s, true)
		highlighted = s

func _update_fade(delta: float) -> void:
	## Trees/bushes the player walks behind turn see-through (keeps the player visible).
	var pc := Vector2i(floori(player.position.x / 32.0), floori(player.position.y / 32.0))
	for dy in range(0, 4):
		for dx in range(-2, 3):
			var c := pc + Vector2i(dx, dy)
			var s := world.prop_sprite(c)
			if s == null:
				continue
			var body: Node2D = s.get_parent()
			var behind := WorldFade.is_behind(player.position, body.position, s.texture.get_size(), s.offset)
			var target := 0.5 if behind else 1.0
			s.modulate.a = move_toward(s.modulate.a, target, delta * 4.0)

func _water_cell_ahead(want: int = 4) -> Vector2i:
	## Water cell along the facing line: the farthest within `want` tiles, else the nearest within 7, or (-1,-1).
	var pc := Vector2i(floori(player.position.x / 32.0), floori(player.position.y / 32.0))
	var dir := PlayerMath.facing_tile(player.position, player.facing) - pc
	var line: Array = []
	for k in range(1, CastMath.MAX_TILES + 1):
		var c := pc + dir * k
		line.append(world.gen.sdf_at(c.x, c.y) < 0.0)
	var i := CastMath.choose(line, want)
	if i < 0:
		return Vector2i(-1, -1)
	return pc + dir * (i + 1)

func _rod_pressed() -> void:
	if fishing.state == Fishing.State.IDLE:
		rod_charging = true
		rod_charge_t = 0.0
	elif fishing.state == Fishing.State.WAITING:
		fishing.hook()
		_say("Too early!")
	elif fishing.state == Fishing.State.BITE:
		fishing.hook()

func _rod_released() -> void:
	if not rod_charging:
		return
	rod_charging = false
	if fishing.state == Fishing.State.IDLE:
		var c := _water_cell_ahead(CastMath.distance_tiles(CastMath.power(rod_charge_t)))
		if c.x < 0:
			_say("Face the water to cast")
		elif not GameState.energy.can_use("rod"):
			_say("Too tired")
		else:
			var bait_id := Fishing.pick_bait(bait_table, GameState.bag)
			if not fishing.cast(world.gen.sdf_at(c.x, c.y), fish_table, GameState.clock.season(), Fishing.combine(rod_table.get(Fishing.pick_rod(rod_table, GameState.bag), {}), bait_table.get(bait_id, {}))):
				return
			if bait_id != "":
				GameState.bag.remove(bait_id, 1)
				_say("Used " + bait_id.replace("_", " "))
			GameState.energy.spend("rod")
			fish_fx.start_cast(TargetMath.center_of(c))
			player.held_tool = "rod"
			player.swing()

func _update_fishing(delta: float) -> void:
	fishing.tick(delta, Input.is_action_pressed("use_tool") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT))
	if fishing.state == Fishing.State.CAUGHT:
		GameState.bag.add(fishing.fish_id, 1)
		var sz := FishJournal.size_cm(float(fish_table[fishing.fish_id].difficulty), randf())
		var rec := GameState.journal.record(fishing.fish_id, sz)
		SkillModel.gain(GameState.skill_xp, "fishing")
		_say("Caught a %s! %d cm%s  (%s)" % [fish_table[fishing.fish_id].name, sz, " NEW!" if rec else "", GameState.journal.summary(fish_table)])
		fishing.reset()
	elif fishing.state == Fishing.State.LOST:
		_say("It got away")
		fishing.reset()

func _say(msg: String) -> void:
	toast.text = msg
	toast_t = 1.5

func _hit_feedback(cell: Vector2i, tool: String, broke: bool) -> void:
	## Wood chips / stone sparks, 1px shake and a tiny freeze so chops feel weighty.
	var p := CPUParticles2D.new()
	p.position = Vector2(cell) * 32.0 + Vector2(16, 20)
	p.emitting = true
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = 14 if broke else 6
	p.lifetime = 0.45
	p.direction = Vector2(0, -1)
	p.spread = 70.0
	p.initial_velocity_min = 40.0
	p.initial_velocity_max = 90.0
	p.gravity = Vector2(0, 260)
	p.scale_amount_min = 1.0
	p.scale_amount_max = 2.0
	p.color = Color(0.72, 0.5, 0.28) if tool == "axe" else Color(0.85, 0.85, 0.8)
	world.add_child(p)
	get_tree().create_timer(1.0).timeout.connect(p.queue_free)
	player.shake(1.0 if not broke else 2.0, 0.12)
	var force := 1.5 if broke else 0.8
	Engine.time_scale = 0.1
	get_tree().create_timer(HitMath.hitstop(force), true, false, true).timeout.connect(func(): Engine.time_scale = 1.0)

func _car_spot() -> Vector2:
	## Dry, empty cell 3-8 tiles from the player start, parked on open ground.
	var pc := Vector2i(floori(player.position.x / 32.0), floori(player.position.y / 32.0))
	for r in range(3, 9):
		for dx in range(-r, r + 1):
			for dy in range(-r, r + 1):
				if maxi(absi(dx), absi(dy)) != r:
					continue
				var c := pc + Vector2i(dx, dy)
				var clear := true
				for ox in range(-1, 2):
					for oy in range(-1, 2):
						var q := c + Vector2i(ox, oy)
						if world.gen.sdf_at(q.x, q.y) < 2.0 or q in world.gen.trees or q in world.gen.rocks or q in world.gen.bushes or world.interactables.at(q).size() > 0:
							clear = false
				if clear:
					return (Vector2(c) + Vector2(0.5, 0.6)) * 32.0
	return player.position + Vector2(64, 0)

func _near_workshop(p: Vector2) -> bool:
	for b in town.buildings:
		if b["id"] == "workshop" and p.distance_to(TownModel.sprite_bottom_center(b)) < 160.0:
			return true
	return false

func _target_cell() -> Vector2i:
	## Mouse tile when aiming with the mouse and in reach, otherwise the tile in front of the player.
	if mouse_aim:
		var c := TargetMath.cell_of(get_global_mouse_position())
		if TargetMath.in_reach(player.position, c):
			return c
	return PlayerMath.facing_tile(player.position, player.facing)

func _update_cursor() -> void:
	var c := TargetMath.cell_of(get_global_mouse_position())
	cursor.active = mouse_aim and not car.driving and not shop.visible
	cursor.cell = c
	cursor.reach = TargetMath.in_reach(player.position, c)
	if mouse_aim and cursor.reach and not car.driving:
		player.facing = TargetMath.facing_toward(player.position, c, player.facing)

func _dirt_puff(cell: Vector2i) -> void:
	var p := CPUParticles2D.new()
	p.position = TargetMath.center_of(cell) + Vector2(0, 6)
	p.emitting = true
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = 9
	p.lifetime = 0.4
	p.direction = Vector2(0, -1)
	p.spread = 80.0
	p.initial_velocity_min = 25.0
	p.initial_velocity_max = 60.0
	p.gravity = Vector2(0, 220)
	p.scale_amount_min = 1.0
	p.scale_amount_max = 2.0
	p.color = Color(0.45, 0.3, 0.18)
	world.add_child(p)
	get_tree().create_timer(0.8).timeout.connect(p.queue_free)

func _end_day() -> void:
	## Bedtime / pass-out / sleeping in a bed: crops grow, rain waters, energy refills, autosave.
	if rain_today > 0.0:
		GameState.farm.rain_water()  # it rained today: crops are watered
		_say("Rain watered the crops")
	GameState.farm.next_day()
	GameState.nodes.next_day()
	animals.day_tick()
	GameState.energy.new_day(false)
	world.sync_props(GameState.nodes)
	GameState.save_game()

func _sleep() -> void:
	GameState.clock.new_day()
	_end_day()
	_say("Slept well. A new day begins (saved)")

func _arg_prefix(prefix: String) -> bool:
	for a in OS.get_cmdline_user_args():
		if a.begins_with(prefix):
			return true
	return false

func _splash_fx(cell: Vector2i, soil_drops := false) -> void:
	var p := CPUParticles2D.new()
	p.position = TargetMath.center_of(cell) + Vector2(0, 4)
	p.emitting = true
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = 8
	p.lifetime = 0.45
	p.direction = Vector2(0, -1)
	p.spread = 70.0
	p.initial_velocity_min = 20.0
	p.initial_velocity_max = 50.0
	p.gravity = Vector2(0, 180)
	p.scale_amount_min = 1.0
	p.scale_amount_max = 1.8
	p.color = Color(0.6, 0.8, 1.0, 0.9) if not soil_drops else Color(0.5, 0.7, 0.95, 0.8)
	world.add_child(p)
	get_tree().create_timer(0.9).timeout.connect(p.queue_free)
