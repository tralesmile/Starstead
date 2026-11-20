extends Node2D
## World root: chunk + player + HUD + day/night; passing out advances the day and saves.

var player: Player
var modulate_node: CanvasModulate
var world: World
var hotbar: Hotbar
var toast: Label
var toast_t := 0.0
var _sun_applied := -1.0
var _season_applied := -1
var stall_stolen := 0   # grabs from the stall today (resets at day end)
var highlighted: Sprite2D = null
var shop: ShopView
var build_view: BuildView
var ambient: AmbientView
var npcs: NpcView
var folk: CityFolkView
var vance_pos := Vector2.INF   # Mr. Vance at his yard gate (also the Rocket Yard Tech job spot)
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
var cave: CaveView
var smelt_view: SmeltView
var craft_view: CraftView
var fish_fx: FishingWorldView
var inv_view: InventoryView
var journal_view: JournalView
var story_view: StoryView
var map_view: MapView
var hud: Hud
var chest_view: ChestView
var cook_view: CookView
var sports: SportsView
var garage_view: GarageView
var drops_view: DropsView
var tree_fall: TreeFallView
var float_fx: FloatFx
var mouse_aim := false
var legend: Label
var goal_label: Label
var city_seen := false
var _goal_t := 0.0
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
var axe_table: Dictionary = _merge(_merge(DataDB.load_json("axes"), DataDB.load_json("pickaxes")), _merge(DataDB.load_json("hoes"), DataDB.load_json("cans")))

var demos: DemoFlags

var region_banner: RegionBanner
var gate_keeper: StoryGate.Keeper

func _ready() -> void:
	demos = DemoFlags.new(self)
	y_sort_enabled = true
	world = World.new()
	add_child(world)
	world.build(1)
	add_child(FarmView.new())
	world.add_child(CrabPotView.new())
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
	world.player_ref = player
	world.nodes_ref = GameState.nodes
	var gate_on := not StoryGate.bypass(OS.get_cmdline_user_args())
	gate_keeper = StoryGate.Keeper.new(StoryGate.load_gates(), gate_on)
	if gate_on:
		world.gates = gate_keeper.gates
		world.gate_done = GameState.story.done
	region_banner = RegionBanner.new()
	add_child(region_banner)
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
	hud = Hud.new()
	add_child(hud)
	hotbar = Hotbar.new()
	for cid in GameState.farm.crops:
		hotbar.seed_ids.append(GameState.farm.crops[cid].seed)
	add_child(hotbar)
	toast = Label.new()   # on its own screen layer: as a child of this Node2D it sat at a fixed WORLD spot, so messages were off-screen
	toast.position = Vector2(8, 72)   # below the HUD panel (and the fuel gauge while driving)
	toast.add_theme_font_size_override("font_size", 12)
	toast.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	toast.add_theme_constant_override("font_outline_size", 3)
	var toast_layer := CanvasLayer.new()
	toast_layer.layer = 3
	toast_layer.add_child(toast)
	add_child(toast_layer)
	ambient = AmbientView.new()
	ambient.player = player
	world.add_child(ambient)
	player.footstep.connect(func(): ambient.puff(player.position))
	player.skid.connect(func(n: int): ambient.puff(player.position + Vector2(0, 2), n, 120.0))
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
	_place_vance()
	folk = CityFolkView.new()   # Port Halden pedestrians + beat cops (E9)
	folk.setup(world, player)
	folk.message.connect(_say)
	world.add_child(folk)
	car = CarView.new()
	car.player = player
	car.world = world
	car.position = _car_spot()
	car.toast.connect(_say)
	hud.car = car
	car.drift_banked.connect(func(p):
		var best: int = int(GameState.sport_best.get("drift", 0))
		GameState.sport_best["drift"] = maxi(best, p)
		_say("Drift +%d%s" % [p, "  NEW BEST!" if p > best else "  (best %d)" % best]))
	world.add_child(car)
	police = PoliceView.new()
	police.setup(world, player, self, world.gen)
	police.message.connect(_say)
	car.crime.connect(police.commit)
	police.witness_cb = folk.witnessed
	police.crime_seen.connect(folk.on_crime)
	world.add_child(police)
	robbery = RobberyView.new()
	robbery.setup(town, world, police, player)
	robbery.message.connect(_say)
	add_child(robbery)
	race = RaceView.new()
	race.setup(car, world, world.gen, self)
	race.message.connect(_say)
	race.add_gate(car.position)   # homestead track start line where the car is parked
	race.add_gate(CircuitModel.start_px(), false, false)   # the circuit's own chequered line is already painted
	add_child(race)
	jobs = JobView.new()
	jobs.setup(player, town.buildings, world.stall_cell())
	if vance_pos != Vector2.INF:
		jobs.spots["vance_gate"] = vance_pos
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
	combat.hunt_cb = animals.hunt
	police.combat = combat
	npcs.combat = combat
	folk.combat = combat
	combat.extra_targets = folk.targets
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
	dialogue.gossip_cb = func(n: int) -> String: return Dialogue.gate_gossip(gate_keeper.gates if gate_keeper.enabled else {}, GameState.story.done, n)
	add_child(dialogue)
	inv_view = InventoryView.new()
	inv_view.closed.connect(func(): player.set_physics_process(true))
	inv_view.ate.connect(func(n, g): _say("Ate %s (+%d energy)" % [n, g]))
	add_child(inv_view)
	map_view = MapView.new().setup(player, world.gen, _workshop_door())
	map_view.locked_cb = func() -> Dictionary: return MapModel.locked_regions(gate_keeper.gates if gate_keeper.enabled else {}, GameState.story.done)
	add_child(map_view)
	story_view = StoryView.new()
	story_view.said.connect(func(t): _say(t); toast_t = 5.0)
	story_view.closed.connect(func(): player.set_physics_process(true))
	add_child(story_view)
	journal_view = JournalView.new()
	journal_view.closed.connect(func(): player.set_physics_process(true))
	add_child(journal_view)
	chest_view = ChestView.new()
	chest_view.closed.connect(func(): player.set_physics_process(true))
	add_child(chest_view)
	cook_view = CookView.new()
	cook_view.closed.connect(func(): player.set_physics_process(true))
	cook_view.cooked.connect(func(n): _say("Cooked " + n))
	add_child(cook_view)
	sports = SportsView.new()
	sports.closed.connect(func(): player.set_physics_process(true))
	sports.message.connect(_say)
	add_child(sports)
	garage_view = GarageView.new()
	garage_view.car = car
	garage_view.closed.connect(func(): player.set_physics_process(true))
	add_child(garage_view)
	car.sprite.modulate = GarageModel.PAINTS[GameState.car_paint]["color"]
	interior = InteriorView.new()
	interior.setup(world, player, self)
	interior.message.connect(_say)
	interior.sleep_requested.connect(_sleep)
	interior.garage_requested.connect(func():
		player.velocity = Vector2.ZERO
		player.move_v = Vector2.ZERO
		player.set_physics_process(false)
		garage_view.open())
	interior.cook_requested.connect(func():
		player.velocity = Vector2.ZERO
		player.move_v = Vector2.ZERO
		player.set_physics_process(false)
		cook_view.open())
	interior.chest_requested.connect(func():
		player.velocity = Vector2.ZERO
		player.move_v = Vector2.ZERO
		player.set_physics_process(false)
		chest_view.open())
	interior.service_requested.connect(func(a): CityActions.run(self, a))
	interior.loot_requested.connect(func(b): robbery.interact(b["door"]))
	interior.dog_cb = func(id: String) -> bool: return bool(robbery.model.house(id)["dog"])
	interior.bark_cb = func() -> void:
		robbery.active = String(interior.building.get("id", ""))
		robbery.model.add_noise(DogMath.BARK_NOISE)
	interior.smelt_requested.connect(func():
		player.velocity = Vector2.ZERO
		player.move_v = Vector2.ZERO
		player.set_physics_process(false)
		smelt_view.open())
	add_child(interior)
	smelt_view = SmeltView.new()
	smelt_view.closed.connect(func(): player.set_physics_process(true))
	smelt_view.cooked.connect(func(n): _say("Smelted " + n))
	add_child(smelt_view)
	craft_view = CraftView.new()
	craft_view.closed.connect(func(): player.set_physics_process(true))
	craft_view.cooked.connect(func(n): _say("Crafted " + n))
	add_child(craft_view)
	cave = CaveView.new()
	cave.setup(world, player, self)
	cave.ore_broken.connect(_on_ore_broken)
	cave.bat_down.connect(func(p): drops_view.spawn("bat_wing", 1, p) if randf() < 0.6 else null)
	cave.bitten.connect(func(a): GameState.energy.value = maxf(0.0, GameState.energy.value - a); _say("A bat bites! -%d energy" % int(a)))
	add_child(cave)
	drops_view = DropsView.new()
	drops_view.setup(world, player)
	tree_fall = TreeFallView.new()
	tree_fall.setup(world, drops_view)
	float_fx = FloatFx.new()
	world.add_child(float_fx)
	drops_view.picked.connect(func(id, n): float_fx.pickup(player.position, id, n))
	add_child(drops_view)
	cursor = CursorView.new()
	cursor.z_index = 30
	world.add_child(cursor)
	world.add_child(CropHoverView.new().setup(cursor))
	legend = Label.new()
	legend.position = Vector2(8, 347)
	legend.add_theme_font_size_override("font_size", 10)
	legend.modulate = Color(1, 1, 1, 0.7)
	legend.text = "Click: use tool   Right-click / E: interact   Wheel: tool   +/-: zoom   C: craft  Tab: bag  J: journal  K: story  G: gear  T: steal   Shift: sprint"
	var leg_layer := CanvasLayer.new()
	leg_layer.add_child(legend)
	goal_label = Label.new()
	goal_label.position = Vector2(8, 72)
	goal_label.add_theme_font_size_override("font_size", 11)
	goal_label.modulate = Color(1.0, 0.92, 0.55, 0.9)
	leg_layer.add_child(goal_label)
	add_child(leg_layer)
	prompt = Label.new()   # screen layer, centred above the hotbar (was a world-space child: invisible away from the homestead)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.position = Vector2(0, 276)
	prompt.size = Vector2(640, 16)
	prompt.add_theme_font_size_override("font_size", 12)
	prompt.add_theme_color_override("font_color", Color(1.0, 0.96, 0.8))
	prompt.add_theme_color_override("font_outline_color", Color(0.12, 0.07, 0.03))
	prompt.add_theme_constant_override("outline_size", 4)
	leg_layer.add_child(prompt)
	if GameState.bag.count("turnip_seed") == 0:
		GameState.bag.add("turnip_seed", 10)
		GameState.bag.add("turnip", 4)  # treats for taming the first animals
	for a in OS.get_cmdline_user_args():  # screenshot helper: --hour=22 sets the clock
		if a.begins_with("--season="):
			GameState.clock.day = int(a.substr(9)) * GameState.clock.DAYS_PER_SEASON + 1
		if a.begins_with("--hour="):
			GameState.clock.minutes = (float(a.substr(7)) - 6.0) * 60.0
	demos.on_ready()
	$HUD.queue_free()

func _process(delta: float) -> void:
	if rod_charging:
		rod_charge_t += delta
	fish_fx.charge = CastMath.power(rod_charge_t) if rod_charging else -1.0
	demos.on_process()
	_goal_t -= delta
	if _goal_t <= 0.0:
		_goal_t = 0.5
		if CityModel.RECT.has_point(Vector2i(floori(player.position.x / 32.0), floori(player.position.y / 32.0))):
			city_seen = true
		story_view.poll(GameState.farm.crops_planted())
		world.refresh_gate_props()
		if VanceYard.gate_open(GameState.story.done):
			get_tree().call_group("vance_gate", "queue_free")   # Act 2 seat earned: the yard gate rolls away
		goal_label.text = "" if _indoors() else GoalText.current(GameState.farm.soil.size(), GameState.farm.crops_planted(), GameState.clock.day, GameState.money, city_seen, GameState.bank_balance, GameState.story.goal_text(), "watering_can" in GameState.tools_owned)
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
	world.set_wet(weather.now)
	fog_rect.size = get_viewport_rect().size  # CanvasLayer parent has no size: anchors alone leave it 0x0
	flash_rect.size = fog_rect.size
	var fl := WeatherMath.lightning_flash(1, rain_day, storm_t, weather.now)
	if "--storm" in OS.get_cmdline_user_args():
		fl = 0.8
	flash_rect.color = Color(0.85, 0.9, 1.0, fl * 0.55)
	modulate_node.color = DayNight.tint(GameState.clock.minutes) * WeatherMath.darken(weather.now)
	if interior.active:
		modulate_node.color = Color(1.0, 0.95, 0.86)  # warm lamp-lit room
	if cave.active:
		modulate_node.color = CaveView.DARK  # torches and the miner's lamp do the lighting

	_update_fishing(delta)
	world.set_lamps(DayNight.lamp_strength(GameState.clock.minutes))
	car.night = 0.0 if _indoors() else DayNight.lamp_strength(GameState.clock.minutes)
	if GameState.clock.season() != _season_applied:
		_season_applied = GameState.clock.season()
		world.set_season(_season_applied)
	if absf(GameState.clock.minutes - _sun_applied) >= 6.0 or _sun_applied < 0.0:
		_sun_applied = GameState.clock.minutes
		World.apply_sun(get_tree(), _sun_applied)
	var lamp_k := 0.0 if _indoors() else DayNight.lamp_strength(GameState.clock.minutes)
	town.set_night(lamp_k)
	for l in get_tree().get_nodes_in_group("night_lights"):   # streamed-chunk lights (Vance yard floodlights)
		(l as PointLight2D).energy = 1.3 * lamp_k
		(l as PointLight2D).visible = lamp_k > 0.01
	world.part_reeds(player.position, delta)
	if not _indoors():
		world.stream_update(player.position)
		var reg: Dictionary = world.region_now(player.position)
		if ChunkGrid.region_changed(world.region_id, String(reg.id)):
			region_banner.show_region(String(reg.name))
			story_view.event("region_" + String(reg.id))
		world.region_id = String(reg.id)
		var gr := gate_keeper.step(player.position, String(reg.id), GameState.story.done, delta)
		if gr["bounce"]:
			_gate_bounce(gr)
	var near := world.interactables.near(player.position, _target_cell())
	var npc_near := npcs.near(player.position + Vector2(0, -8))
	prompt.text = "" if shop.visible else String(near.get("prompt", ""))
	if prompt.text == "" and not shop.visible and not npc_near.is_empty():
		prompt.text = "E: Talk to " + String(npc_near["name"])
		var jp := jobs.prompt()   # Vance's gate is also a workplace (Rocket Yard Tech)
		if jp != "":
			prompt.text += "    " + jp
	if _indoors():
		prompt.text = interior.prompt() if interior.active else cave.prompt()
	elif prompt.text == "" and not shop.visible:
		prompt.text = jobs.prompt()
	if prompt.text == "" and not _indoors() and not car.driving and player.position.distance_to(_stall_pos()) < StallTheft.REACH:
		prompt.text = "T: Swipe something (risky)"
	var an_near := animals.near(player.position)
	if prompt.text == "" and not shop.visible and not an_near.is_empty():
		prompt.text = animals.prompt_for(an_near)
	if animals.riding != null:
		prompt.text = "E: Dismount"
	if car.can_enter() and prompt.text == "":
		prompt.text = "E: Drive"
	elif car.driving:
		prompt.text = "Fuel %d%%  E: exit" % int(100.0 * car.fuel / VehicleMath.FUEL_MAX)
	player.indoors = _indoors()
	player.zoom_bias = (0 if _indoors() else -1 if (car.driving or animals.riding != null) else 0)
	weather.visible = not _indoors()
	ambient.visible = not _indoors()
	fog_rect.visible = not _indoors()
	flash_rect.visible = not _indoors()
	_update_cursor()
	_update_highlight()
	_update_fade(delta)
	get_tree().call_group("harbour_crate", "set_visible", HarbourActions.crate_visible(self))
	toast_t -= delta
	if toast_t <= 0.0:
		toast.text = ""
	goal_label.visible = toast.text == ""   # both live at (8,72): a fresh message hides the goal line for 1.5 s

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
	if not shop.visible and not dialogue.visible and not inv_view.visible and not story_view.log_open() and map_view.handle(e):
		if not car.driving:
			player.velocity = Vector2.ZERO
			player.move_v = Vector2.ZERO
			player.set_physics_process(not map_view.is_open())
		get_viewport().set_input_as_handled()
		return
	if not shop.visible and not car.driving and not dialogue.visible and not inv_view.visible and not journal_view.visible and story_view.handle(e):
		if story_view.log_open():
			player.velocity = Vector2.ZERO
			player.move_v = Vector2.ZERO
			player.set_physics_process(false)
		get_viewport().set_input_as_handled()
		return
	if not shop.visible and not car.driving and not dialogue.visible and not inv_view.visible and journal_view.handle(e):
		if journal_view.visible:
			player.velocity = Vector2.ZERO
			player.move_v = Vector2.ZERO
			player.set_physics_process(false)
		get_viewport().set_input_as_handled()
		return
	if not shop.visible and not car.driving and not dialogue.visible and inv_view.handle(e):
		if inv_view.visible:
			player.velocity = Vector2.ZERO
			player.move_v = Vector2.ZERO
			player.set_physics_process(false)
		get_viewport().set_input_as_handled()
		return
	if garage_view.visible:
		garage_view.handle(e)
		get_viewport().set_input_as_handled()
		return
	if smelt_view.visible:
		smelt_view.handle(e)
		get_viewport().set_input_as_handled()
		return
	if craft_view.visible or (e is InputEventKey and e.pressed and not e.echo and e.keycode == KEY_C and not car.driving and not shop.visible and not dialogue.visible and not inv_view.visible and not journal_view.visible and not interior.active):
		if not craft_view.visible:
			player.velocity = Vector2.ZERO
			player.move_v = Vector2.ZERO
			player.set_physics_process(false)
			craft_view.open()
		else:
			craft_view.handle(e)
		get_viewport().set_input_as_handled()
		return
	if sports.visible:
		sports.handle(e)
		get_viewport().set_input_as_handled()
		return
	if cook_view.visible:
		cook_view.handle(e)
		get_viewport().set_input_as_handled()
		return
	if chest_view.visible:
		chest_view.handle(e)
		get_viewport().set_input_as_handled()
		return
	if cave.active:
		if cave.busy:
			return
		if e.is_action_pressed("pause"):
			cave.leave()
		elif e.is_action_pressed("use_tool"):
			_cave_tool()
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
	if e is InputEventKey and e.pressed and not e.echo and e.keycode == KEY_G and not car.driving and not shop.visible and not _indoors():
		animals.gear_action()
		return
	if e is InputEventKey and e.pressed and not e.echo and e.keycode == KEY_T and not car.driving and not shop.visible and not _indoors():
		_steal_from_stall()
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
			if String(nn.get("id", "")) == "vance":
				story_view.event("vance_talk")
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
				story_view.event("enter_" + String(bb["id"]))
			else:
				robbery.interact(dcell)
			return
		if it.get("kind", "") == "cave":
			cave.enter(GameState.clock.day)
			story_view.event("enter_cave")
			return
		if it.get("kind", "") == "pitch":
			CityActions.run(self, "pitch")
			return
		if it.get("kind", "") == "rocket":
			_say("Your seat on the Vance rocket is waiting. The Moon (Act 3) is not built yet." if VanceYard.gate_open(GameState.story.done) else "Half-built, white and red, scaffolding up one side. Grandmother beat this to the Moon?")
			toast_t = 4.0
			return
		if it.get("kind", "") in ["board", "crate", "fence"]:
			HarbourActions.run(self, String(it["kind"]))
			return
		if it.get("kind", "") == "sign":
			_say(String(it.get("text", "")))
			toast_t = 4.0
			return
		if it.get("kind", "") == "shop":
			player.velocity = Vector2.ZERO
			player.move_v = Vector2.ZERO
			player.set_physics_process(false)
			shop.open()
			return
		var rc := ContextAction.ripe_cell(GameState.farm, _target_cell(), Vector2i(floori(player.position.x / 32.0), floori(player.position.y / 32.0)))
		if it.is_empty() and rc != ContextAction.NONE:
			_context_harvest(rc)  # E on a ripe crop: pick it with any tool in hand
			return
	if e.is_action_pressed("use_tool") and not ToolKit.owns(GameState.tools_owned, hotbar.current()):
		_say("You have no %s yet - press C to craft it from wood" % hotbar.current().replace("_", " "))
	elif e.is_action_pressed("use_tool") and hotbar.current() == "rod":
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
		if hotbar.current() == "crab_pot":
			if GameState.bag.count("crab_pot") < 1:
				_say("No crab pots - buy them at the shop")
			elif GameState.pots.place(cell, world.gen.sdf_at(cell.x, cell.y)):
				GameState.bag.remove("crab_pot", 1)
				_splash_fx(cell)
				_say("Crab pot placed - check it tomorrow")
			else:
				_say("Needs open water, half a tile out")
			return
		if hotbar.current() == "hand" and GameState.pots.pots.has(cell):
			var got: Array = GameState.pots.collect(cell)
			if got.is_empty():
				GameState.pots.pick_up(cell)
				GameState.bag.add("crab_pot", 1)
				_say("Picked up the crab pot")
			else:
				for id in got:
					drops_view.spawn(id, 1, TargetMath.center_of(cell) + Vector2(0, 6))
				_say("Emptied the crab pot (%d)" % got.size())
			return
		if hotbar.current() == "watering_can":
			GameState.can.set_capacity(LineMath.capacity_for(20, GameState.bag, axe_table))
			if world.gen.sdf_at(cell.x, cell.y) < 0.0:
				var added := GameState.can.refill()
				_say("Refilled the can" if added > 0 else "The can is full")
				_splash_fx(cell)
				return
			if GameState.can.is_empty():
				_say("The can is empty - face the water and use it to refill")
				return
		if hotbar.current() == "axe" and tree_fall.hit_log(cell, player.position):
			return  # chopping a fallen trunk into logs
		var msg := ToolUse.apply(hotbar.current(), cell, GameState.farm, GameState.bag, GameState.clock.season(), world.gen, GameState.nodes, GameState.energy, dl, axe_table)
		if msg == "" and hotbar.current() == "scythe" and world.cut_tuft(cell):   # wild grass -> hay (feeds cows, sheep, horses)
			dl.append({"id": "hay", "n": 1})
			msg = "Cut grass"
			_hay_fx(cell)
		var line_cells: Array = [cell]
		if msg != "" and (hotbar.current() == "hoe" or hotbar.current() == "watering_can"):
			var extra: Array = LineMath.cells(cell, player.facing, ToolUse.axe_power(GameState.bag, axe_table, hotbar.current()))
			for i in range(1, extra.size()):
				if hotbar.current() == "watering_can" and GameState.can.level <= 1:
					break  # keep a unit for the first tile's use below
				var m2 := ToolUse.apply(hotbar.current(), extra[i], GameState.farm, GameState.bag, GameState.clock.season(), world.gen, GameState.nodes, null, dl, axe_table)
				if m2 != "":
					line_cells.append(extra[i])
					if hotbar.current() == "watering_can":
						GameState.can.use()
		if msg.begins_with("Harvested"):
			_quality_pass(dl, GameState.farm.fert_bonus(cell))
		if hotbar.current() == "axe" and msg.begins_with("Got") and world.gen.trees.has(cell):
			dl.clear()  # the felled tree is chopped into logs later (TreeFallView)
		for d in dl:
			drops_view.spawn(d["id"], int(d["n"]), TargetMath.center_of(cell) + Vector2(0, 6))
		if hotbar.current() == "axe" and world.props.has(cell) and world.gen.trees.has(cell):
			var tspr := world.prop_sprite(cell)
			if msg.begins_with("Got"):
				var tb := (world.props[cell] as Node2D).position
				tree_fall.fell(cell, tspr, tb, ChopFx.fall_dir(player.position.x, tb.x))
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
		if sk != "" and _skill_gain(sk):
			msg = "%s level %d!" % [sk.capitalize(), SkillModel.level(int(GameState.skill_xp[sk]))]
		world.sync_props(GameState.nodes)
		if msg == "Tilled":
			for lc in line_cells:
				_dirt_puff(lc)
		if msg == "Watered":
			GameState.can.use()
			for lc in line_cells:
				_splash_fx(lc, true)
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

func _stall_pos() -> Vector2:
	return (Vector2(world.stall_cell()) + Vector2(1.0, 0.5)) * 32.0

func _steal_from_stall() -> void:
	var d := player.position.distance_to(_stall_pos())
	if d > 96.0:
		return
	if not StallTheft.can_steal(stall_stolen, d):
		_say("Too far from the goods" if d > StallTheft.REACH else "The stall is picked clean today")
		return
	var id := StallTheft.loot_for(randf())
	stall_stolen += 1
	drops_view.spawn(id, 1, _stall_pos() + Vector2(0, 28))
	GameState.rep_street += 1
	GameState.rep_honest = maxi(0, GameState.rep_honest - 1)
	var hour := fposmod(6.0 + GameState.clock.minutes / 60.0, 24.0)
	var crowd := 0
	for n in npcs.actors:
		if (n["node"] as Node2D).position.distance_to(_stall_pos()) < 140.0:
			crowd += 1
	if StallTheft.vendor_sees(crowd, hour, randf()):
		police.commit("theft", player.position)
		_say("The vendor shouts: thief!")
	else:
		_say("You swipe a %s unseen" % id)

func _quality_pass(dl: Array, fert: float = 0.0) -> void:
	## Harvested crops roll silver/gold by farming level (QualityMath).
	var flvl := SkillModel.level(int(GameState.skill_xp.get("farming", 0)))
	for d in dl:
		if GameState.farm.crops.has(d["id"]):
			d["id"] = QualityMath.variant(String(d["id"]), QualityMath.roll(flvl, randf(), fert))

func _fish_ctx() -> Dictionary:
	var caught: Array = []
	for id in GameState.journal.entries:
		if int(GameState.journal.entries[id].count) > 0:
			caught.append(id)
	var cc := _water_cell_ahead(CastMath.distance_tiles(CastMath.power(rod_charge_t)))
	return {"rain": rain_today, "hour": fposmod(6.0 + GameState.clock.minutes / 60.0, 24.0), "caught": caught, "caught_count": GameState.journal.total_caught(), "sea": cc.x >= 0 and HarbourModel.in_sea_area(cc)}

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
			if not fishing.cast(world.gen.sdf_at(c.x, c.y), fish_table, GameState.clock.season(), Fishing.combine(rod_table.get(Fishing.pick_rod(rod_table, GameState.bag), {}), bait_table.get(bait_id, {})), _fish_ctx()):
				return
			if fishing.fish_id != "" and bool(fish_table[fishing.fish_id].get("legendary", false)):
				_say("Something huge stirs below...")
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
		fish_fx.leap(fishing.fish_id)
		var treasure_txt := ""
		if fishing.treasure_got:   # opened the chest in the reel and landed the fish: the loot comes too
			var loot := Fishing.treasure_loot(randf(), randf())
			var lid := String(loot["id"])
			if lid == "$":
				GameState.money += int(loot["n"])
				treasure_txt = "  + TREASURE $%d" % int(loot["n"])
			else:
				GameState.bag.add(lid, int(loot["n"]))
				float_fx.pickup(player.position + Vector2(0, -30), lid, int(loot["n"]))
				treasure_txt = "  + TREASURE %d %s" % [int(loot["n"]), lid.replace("_", " ")]
		var sz := FishJournal.size_cm(float(fish_table[fishing.fish_id].difficulty), randf())
		var rec := GameState.journal.record(fishing.fish_id, sz)
		_skill_gain("fishing")
		if bool(fish_table[fishing.fish_id].get("sea", false)) and GameState.harbour.add_catch(GameState.clock.day, HarbourActions.hour_now(), sz):
			_say("Caught a %s! %d cm. Contest total %d cm%s" % [fish_table[fishing.fish_id].name, sz, GameState.harbour.score, treasure_txt])
		else:
			_say(("LEGENDARY! " if bool(fish_table[fishing.fish_id].get("legendary", false)) else "") + "Caught a %s! %d cm%s  (%s)%s" % [fish_table[fishing.fish_id].name, sz, " NEW!" if rec else "", GameState.journal.summary(fish_table), treasure_txt])
		fishing.reset()
	elif fishing.state == Fishing.State.LOST:
		_say("It got away")
		fishing.reset()

func _gate_bounce(gr: Dictionary) -> void:
	## Story gate: the road is closed, so the mover is pushed back to the last open spot.
	var to: Vector2 = gr["to"]
	if car.driving:
		car.vel = StoryGate.bounce_velocity(car.vel, to, car.position)
		car.position = to
	player.position = to
	player.shake(1.5, 0.2)
	if str(gr["msg"]) != "":
		_say(str(gr["msg"]))
		toast_t = 4.0

func _place_vance() -> void:
	## Act 2: Mr. Vance waits beside the road end at his yard (RoadNet hub "vance").
	var st: ChunkStream = world.gen.stream_ref
	var npc: Dictionary = DataDB.load_json("story").get("vance_npc", {})
	if st == null or npc.is_empty() or not st.roads.hubs.has("vance"):
		return
	var hub: Vector2i = st.roads.hubs["vance"]
	vance_pos = (Vector2(hub) + Vector2(1.5, 0.6)) * 32.0
	npcs.add_static(npc, vance_pos)

func _hay_fx(cell: Vector2i) -> void:
	## A puff of cut grass blades.
	var p := CPUParticles2D.new()
	p.position = TargetMath.center_of(cell) + Vector2(0, 8)
	p.emitting = true
	p.one_shot = true
	p.amount = 10
	p.lifetime = 0.5
	p.explosiveness = 0.9
	p.direction = Vector2(0, -1)
	p.spread = 70.0
	p.initial_velocity_min = 25.0
	p.initial_velocity_max = 55.0
	p.gravity = Vector2(0, 140)
	p.scale_amount_min = 1.0
	p.scale_amount_max = 2.0
	p.color = Color(0.62, 0.78, 0.3)
	world.add_child(p)
	get_tree().create_timer(1.0).timeout.connect(p.queue_free)

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

func _indoors() -> bool:
	return interior.active or cave.active

func _cave_tool() -> void:
	var tool := hotbar.current()
	if tool == "club":
		if GameState.energy.can_use("club") and combat.cd <= 0.0:
			GameState.energy.spend("club")
			player.held_tool = "club"
			player.swing()
			combat.cd = CombatModel.cooldown("club")
			var w := CombatModel.weapon("club")
			cave.club_swing(float(w["dmg"]), float(w["range"]) + 10.0, float(w["force"]))
		return
	if tool != "pickaxe":
		_say("Use the pickaxe on ore, the club on bats")
		return
	if not GameState.energy.can_use("pickaxe"):
		_say("Too tired to mine")
		return
	player.held_tool = tool
	player.swing()
	var msg := cave.use_tool(tool, ToolUse.axe_power(GameState.bag, axe_table, "pickaxe"))
	if msg != "":
		GameState.energy.spend("pickaxe")
		_hit_feedback(cave.target_cell() + CaveView.CELL_OFFSET, "pickaxe", msg.begins_with("Got"))
		_say(msg)

func _on_ore_broken(id: String, n: int, pos: Vector2, _kind: String) -> void:
	drops_view.spawn(id, n, pos)
	var sk := "mining"
	if _skill_gain(sk):
		_say("Mining level %d!" % SkillModel.level(int(GameState.skill_xp[sk])))

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

func _context_harvest(cell: Vector2i) -> void:
	var dl: Array = []
	var msg := ToolUse.apply("hand", cell, GameState.farm, GameState.bag, GameState.clock.season(), world.gen, GameState.nodes, GameState.energy, dl, axe_table)
	if msg == "":
		return
	player.held_tool = "hand"
	player.swing()
	if msg.begins_with("Harvested"):
		_quality_pass(dl, GameState.farm.fert_bonus(cell))
	for d in dl:
		drops_view.spawn(d["id"], int(d["n"]), TargetMath.center_of(cell) + Vector2(0, 6))
	if SkillModel.roll_bonus(SkillModel.level(int(GameState.skill_xp.get("farming", 0))), randf()) > 0 and not dl.is_empty():
		drops_view.spawn(dl[0]["id"], 1, TargetMath.center_of(cell) + Vector2(8, 10))
		msg += " +1 bonus"
	if _skill_gain("farming"):
		msg = "Farming level %d!" % SkillModel.level(int(GameState.skill_xp["farming"]))
	toast.text = msg
	toast_t = 1.5

func _skill_gain(sk: String) -> bool:
	## Adds skill xp; on a level-up plays the sparkle + banner fanfare at the player.
	var up := SkillModel.gain(GameState.skill_xp, sk)
	if up:
		LevelFx.spawn(world, player.position, sk, SkillModel.level(int(GameState.skill_xp[sk])))
		player.shake(0.6, 0.1)
	return up

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
	var sprinkled := GameState.farm.sprinkle()
	if sprinkled > 0:
		_say("Sprinklers watered %d tiles" % sprinkled)
	GameState.farm.next_day()
	stall_stolen = 0
	var rngp := RandomNumberGenerator.new()
	rngp.seed = GameState.clock.day * 31 + 5
	var caught := GameState.pots.day_tick(rngp)
	if caught > 0:
		_say("Your crab pots caught something")
	GameState.farm.spawn_weeds(GameState.clock.day)
	GameState.nodes.next_day()
	GameState.market.new_day()
	animals.day_tick()
	GameState.bank_balance += CityServices.daily_interest(GameState.bank_balance)
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

func _merge(a: Dictionary, b: Dictionary) -> Dictionary:
	var o := a.duplicate()
	o.merge(b)
	return o

func _workshop_door() -> Vector2i:
	for b in town.buildings:
		if b.get("id", "") == "workshop":
			return b["door"]
	return Vector2i(20, 30)
