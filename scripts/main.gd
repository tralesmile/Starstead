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
var dealer: DealerView
var build_view: BuildView
var ambient: AmbientView
var npcs: NpcView
var folk: CityFolkView
var yard_dogs: YardGuardView
var prints: PrintView
var vance_pos := Vector2.INF   # Mr. Vance at his yard gate (also the Rocket Yard Tech job spot)
var dialogue: DialogueView
var car: CarView
var car_theft: CarTheftView
var traffic: RoadTrafficView
var police: PoliceView
var robbery: RobberyView
var combat: CombatView
var animals: AnimalView
var bow: BowView
var cursor: CursorView
var rod_charging := false
var rod_charge_t := 0.0
var interior: InteriorView
var cave: CaveView
var smelt_view: SmeltView
var forge_view: ForgeView
var butcher_view: ButcherView
var bus_view: BusView
var isle_view: IsleView
var ferry_view: FerryView
var sfx_director: SfxDirector
var bus_stops: BusStopsView
var craft_view: CraftView
var welcome: WelcomeView
var perk_view: PerkView
var fish_fx: FishingWorldView
var inv_view: InventoryView
var journal_view: JournalView
var story_view: StoryView
var map_view: MapView
var hud: Hud
var chest_view: ChestView
var cook_view: CookView
var upgrade_view: UpgradeView
var farm_view: FarmView
var sports: SportsView
var football_view: FootballView
var derby: DerbyView
var hangar: HangarView
var hoof_t := 0.0
var garage_view: GarageView
var drops_view: DropsView
var tree_fall: TreeFallView
var float_fx: FloatFx
var mouse_aim := false
var goal_label: Label
var goal_arrow: GoalArrowView
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
var fish_events: Dictionary = DataDB.load_json("fish_events")
var event_fish := ""   # today's sighted legendary (FishEvents)
var fish_event_view: FishEventView
var bait_table: Dictionary = DataDB.load_json("bait")
var rod_table: Dictionary = DataDB.load_json("rods")
var axe_table: Dictionary = _merge(_merge(DataDB.load_json("axes"), DataDB.load_json("pickaxes")), _merge(DataDB.load_json("hoes"), DataDB.load_json("cans")))

var demos: DemoFlags

var region_banner: RegionBanner
var gate_keeper: StoryGate.Keeper

func _ready() -> void:
	demos = DemoFlags.new(self)
	var loaded := SaveBoot.should_load(OS.get_cmdline_user_args(), FileAccess.file_exists(GameState.SAVE_PATH)) and GameState.load_game()
	y_sort_enabled = true
	world = World.new()
	add_child(world)
	world.build(1)
	farm_view = FarmView.new()
	add_child(farm_view)
	world.add_child(CrabPotView.new())
	world.add_child(SnareView.new())
	town = TownView.new()
	town.setup(world, world.gen, world.stall_cell())
	world.add_child(town)
	for c in world.gen.trees:
		GameState.nodes.add("tree", c)
	for c in world.gen.rocks:
		GameState.nodes.add("rock", c)
	player = Player.new()
	farm_view.walker = player
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
	player.footstep.connect(func(): ambient.puff(player.position, AmbientMath.step_puffs(GameState.clock.season(), player.sprinting), 60.0, AmbientMath.step_dust_color(world.gen.tile_at(floori(player.position.x / 32.0), floori(player.position.y / 32.0)), GameState.clock.season())))
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
	prints = PrintView.new()   # wet footprints on paved ground in rain
	prints.setup(player)
	world.add_child(prints)
	yard_dogs = YardGuardView.new()   # Vance yard guard dogs
	yard_dogs.setup(player)
	yard_dogs.message.connect(_say)
	world.add_child(yard_dogs)
	car = CarView.new()
	car.player = player
	car.world = world
	car.position = _car_spot()
	car.toast.connect(_say)
	hud.car = car
	car.impact.connect(func(at: Vector2, n: int): ambient.puff(at, n, 160.0))
	car.drift_banked.connect(func(p):
		var best: int = int(GameState.sport_best.get("drift", 0))
		GameState.sport_best["drift"] = maxi(best, p)
		var res := DriftBoard.submit(GameState.drift_board, p)
		GameState.drift_board = res["board"]
		_say("Drift +%d%s%s" % [p, "  NEW BEST!" if p > best else "  (best %d)" % best, ("  #%d on the board" % int(res["rank"])) if int(res["rank"]) > 0 else ""]))
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
	car_theft = CarTheftView.new()
	car_theft.car = car
	car_theft.player = player
	car_theft.toast.connect(_say)
	car_theft.crime.connect(police.commit)
	world.add_child(car_theft)
	traffic = RoadTrafficView.new()   # ambient cars + hikers on the open roads (E11)
	traffic.setup(world, player, car, world.stream.roads)
	traffic.open_cb = func(pos: Vector2) -> bool:
		if not gate_keeper.enabled:
			return true
		var rid := String(world.stream.region_at(ChunkGrid.chunk_of_cell(Vector2i(floori(pos.x / 32.0), floori(pos.y / 32.0)))).get("id", ""))
		return StoryGate.lock_message(gate_keeper.gates, rid, GameState.story.done) == ""
	world.add_child(traffic)
	race.add_gate(car.position)   # homestead track start line where the car is parked
	race.add_gate(CircuitModel.start_px(), false, false)   # the circuit's own chequered line is already painted
	add_child(race)
	jobs = JobView.new()
	jobs.setup(player, town.buildings, world.stall_cell())
	if vance_pos != Vector2.INF:
		jobs.spots["vance_gate"] = vance_pos
	var cm: Vector2i = world.stream.roads.cave_mouth
	if cm.x != RoadNet.NO_CELL:
		jobs.spots["cave_mouth"] = (Vector2(cm) + Vector2(0.5, 1.8)) * 32.0
	jobs.message.connect(_say)
	add_child(jobs)
	animals = AnimalView.new()
	ambient.animals = animals
	for pc in town.paddock_cells:
		animals.extra_solid[pc] = true
	animals.setup(world, player, world.gen)
	animals.message.connect(_say)
	world.add_child(animals)
	world.chunk_built.connect(func(ch: Vector2i) -> void: animals.populate_chunk(ch, String(world.stream.region_at(ch).get("id", "")), world.stream, GameState.clock.day))
	world.chunk_dropped.connect(func(_ch: Vector2i) -> void: animals.drop_far(player.position))
	bow = BowView.new()
	bow.player = player
	bow.animals = animals
	bow.solid_cb = func(c: Vector2i) -> bool: return GameState.nodes.is_solid(c) or (GameState.build.placed.has(c) and GameState.build.defs[GameState.build.placed[c]].solid)
	bow.message.connect(_say)
	world.add_child(bow)
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
	fish_event_view = FishEventView.new()
	world.add_child(fish_event_view)
	fish_fx = FishingWorldView.new()
	fish_fx.setup(fishing, player)
	fish_fx.water_at = func(c: Vector2i) -> bool: return world.gen.sdf_at(c.x, c.y) < -0.3
	fish_fx.sound_cb = func(n: String): sfx_director.play(n)
	world.add_child(fish_fx)
	build_view = BuildView.new()
	add_child(build_view)
	build_view.setup(world, world.gen, player)
	build_view.message.connect(_say)
	shop = ShopView.new()
	shop.closed.connect(func(): player.set_physics_process(true))
	add_child(shop)
	dealer = DealerView.new()
	dealer.police = police
	dealer.closed.connect(func(): player.set_physics_process(true))
	add_child(dealer)
	dialogue = DialogueView.new()
	dialogue.gossip_cb = func(n: int) -> String: return Dialogue.gate_gossip(gate_keeper.gates if gate_keeper.enabled else {}, GameState.story.done, n)
	add_child(dialogue)
	inv_view = InventoryView.new()
	inv_view.closed.connect(func(): player.set_physics_process(true))
	inv_view.ate.connect(func(n, g): _say("Ate %s (+%d energy)" % [n, g]))
	add_child(inv_view)
	bus_stops = BusStopsView.new()
	bus_stops.player = player
	bus_stops.stops = BusModel.make_stops(world.stream.roads.cave_mouth, world.stream.roads.hubs, _workshop_door())
	world.add_child(bus_stops)
	bus_view = BusView.new()
	bus_view.closed.connect(func(): player.set_physics_process(true))
	bus_view.ride.connect(_bus_ride)
	add_child(bus_view)
	isle_view = IsleView.new()
	isle_view.player = player
	world.add_child(isle_view)
	isle_view.found.connect(func(id, at): float_fx.pickup(at, id, 1))
	ferry_view = FerryView.new()
	ferry_view.arrived.connect(func(): FerryActions.arrived(self))
	add_child(ferry_view)
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
	upgrade_view = UpgradeView.new()
	upgrade_view.closed.connect(func(): player.set_physics_process(true))
	upgrade_view.bought.connect(func(n): _say("Built: " + n))
	add_child(upgrade_view)
	sports = SportsView.new()
	sports.closed.connect(func(): player.set_physics_process(true))
	sports.message.connect(_say)
	add_child(sports)
	football_view = FootballView.new()
	football_view.closed.connect(func(): player.set_physics_process(true))
	football_view.message.connect(_say)
	football_view.sound.connect(func(n: String): sfx_director.play(n))
	add_child(football_view)
	hangar = HangarView.new()
	hangar.finished.connect(_hangar_done)
	add_child(hangar)
	derby = DerbyView.new()
	derby.closed.connect(func(): player.set_physics_process(true))
	derby.message.connect(_say)
	add_child(derby)
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
	interior.safe_requested.connect(func(b): robbery.crack_safe(b))
	interior.alarm_requested.connect(func(b): robbery.cut_alarm(b))
	interior.till_requested.connect(func(b): robbery.crack_till(b))
	robbery.alarm_rang.connect(func(_id): interior.ring_alarm())
	interior.extras_cb = func(id: String) -> Dictionary:
		var h: Dictionary = robbery.model.house(id)
		return {"safe": h["safe"], "safe_open": h["safe_open"], "alarm": h["alarm"], "armed": h["alarm_armed"]}
	robbery.indoors_cb = func() -> String:
		if not interior.active or String(interior.building.get("id", "")) in InteriorModel.PUBLIC:
			return ""
		return String(interior.building.get("id", ""))
	var hour_now := func() -> float: return NpcSchedule.hour_of(GameState.clock.minutes)
	robbery.hour_cb = hour_now
	interior.hour_cb = hour_now
	robbery.spotters_cb = func() -> Array: return interior.resident_awake_positions()
	interior.grudge_cb = func(id: String) -> bool: return bool(robbery.model.house(id)["grudge"])
	interior.woke_cb = func() -> bool: return robbery.model.residents_awake()
	robbery.sneaking_cb = func() -> Array: return [player.velocity.length() > 8.0, player.sprinting, player.sneaking]
	interior.dog_cb = func(id: String) -> bool: return bool(robbery.model.house(id)["dog"])
	interior.bark_cb = func() -> void:
		robbery.active = String(interior.building.get("id", ""))
		robbery.model.add_noise(DogMath.BARK_NOISE)
	var artisan_view := ArtisanView.new()
	artisan_view.setup(world, interior)
	artisan_view.message.connect(_say)
	artisan_view.collected.connect(func(_id): sfx_director.play("pickup"))
	interior.smelt_requested.connect(func():
		player.velocity = Vector2.ZERO
		player.move_v = Vector2.ZERO
		player.set_physics_process(false)
		smelt_view.open())
	interior.butcher_requested.connect(func():
		player.velocity = Vector2.ZERO
		player.move_v = Vector2.ZERO
		player.set_physics_process(false)
		butcher_view.open())
	interior.forge_requested.connect(func():
		player.velocity = Vector2.ZERO
		player.move_v = Vector2.ZERO
		player.set_physics_process(false)
		forge_view.open())
	add_child(interior)
	forge_view = ForgeView.new()
	forge_view.closed.connect(func(): player.set_physics_process(true))
	forge_view.cooked.connect(func(n): _say("Forged " + n))
	add_child(forge_view)
	butcher_view = ButcherView.new()
	butcher_view.closed.connect(func(): player.set_physics_process(true))
	butcher_view.cooked.connect(func(n): _say("Made " + n))
	add_child(butcher_view)
	smelt_view = SmeltView.new()
	smelt_view.closed.connect(func(): player.set_physics_process(true))
	smelt_view.cooked.connect(func(n): _say("Smelted " + n))
	add_child(smelt_view)
	_setup_perk_view()
	craft_view = CraftView.new()
	craft_view.closed.connect(func(): player.set_physics_process(true))
	craft_view.cooked.connect(func(n): _say("Crafted " + n))
	add_child(craft_view)
	goal_arrow = GoalArrowView.new()
	goal_arrow.setup(player, world.gen, town)
	add_child(goal_arrow)
	cave = CaveView.new()
	cave.setup(world, player, self)
	cave.ore_broken.connect(_on_ore_broken)
	cave.bat_down.connect(func(p): drops_view.spawn("bat_wing", 1, p) if randf() < 0.6 else null)
	cave.monster_down.connect(func(k, p):
		var dr := CaveModel.monster_drop(k, randf())
		if not dr.is_empty():
			drops_view.spawn(dr[0], dr[1], p)
		_say("%s down" % String(k).capitalize()))
	cave.bitten.connect(func(a): a = GearModel.soften(GameState.bag, a); GameState.energy.value = maxf(0.0, GameState.energy.value - a); _say("Hurt! -%d energy" % int(a)))
	cave.boss_ready_cb = func() -> int:
		return 0 if BossModel.can_respawn(GameState.warden_day, GameState.clock.day) else BossModel.RESPAWN_DAYS - (GameState.clock.day - GameState.warden_day)
	cave.wide_lamp_cb = func() -> bool: return GameState.bag.count("deep_lamp") > 0
	cave.sound.connect(func(n, g, pi): sfx_director.play(n, g, pi))
	cave.message.connect(func(msg): _say(msg))
	cave.boss_defeated.connect(_on_warden_down)
	add_child(cave)
	drops_view = DropsView.new()
	drops_view.setup(world, player)
	tree_fall = TreeFallView.new()
	tree_fall.setup(world, drops_view)
	float_fx = FloatFx.new()
	world.add_child(float_fx)
	drops_view.picked.connect(func(id, n): float_fx.pickup(player.position, id, n))
	sfx_director = SfxDirector.new()
	sfx_director.setup(self)
	build_view.door_moved.connect(func(opening: bool): sfx_director.play("door_open" if opening else "door_close"))
	add_child(sfx_director)
	add_child(drops_view)
	cursor = CursorView.new()
	cursor.z_index = 30
	world.add_child(cursor)
	world.add_child(CropHoverView.new().setup(cursor))
	var leg_layer := CanvasLayer.new()
	goal_label = Label.new()
	goal_label.position = Vector2(8, 72)
	goal_label.add_theme_font_size_override("font_size", 11)
	goal_label.modulate = Color(1.0, 0.92, 0.55)
	goal_label.add_theme_color_override("font_outline_color", Color(0.12, 0.07, 0.03))
	goal_label.add_theme_constant_override("outline_size", 4)
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
	if not loaded and GameState.bag.count("turnip_seed") == 0:
		GameState.bag.add("turnip_seed", 10)
		GameState.bag.add("turnip", 4)  # treats for taming the first animals
	for a in OS.get_cmdline_user_args():  # screenshot helper: --hour=22 sets the clock
		if a.begins_with("--season="):
			GameState.clock.day = int(a.substr(9)) * GameState.clock.DAYS_PER_SEASON + 1
		if a.begins_with("--hour="):
			GameState.clock.minutes = (float(a.substr(7)) - 6.0) * 60.0
	if loaded:
		_setup_welcome()
	demos.on_ready()
	$HUD.queue_free()

func _setup_welcome() -> void:
	## A loaded save wakes you at your own door, behind the welcome-back card.
	player.position = (Vector2(_home_door()) + Vector2(0.5, 1.6)) * 32.0
	welcome = WelcomeView.new()
	add_child(welcome)
	welcome.continued.connect(func(): _welcome_lock(false))
	welcome.new_game.connect(func():
		GameState.reset_new()
		get_tree().reload_current_scene())
	welcome.open(SaveBoot.summary(GameState.clock.day, GameState.clock.season(), GameState.money))
	_welcome_lock(true)

func _home_door() -> Vector2i:
	for b in town.buildings:
		if String(b["id"]) == "farmhouse":
			return b["door"]
	return Vector2i(32, 34)

func _welcome_lock(on: bool) -> void:
	player.velocity = Vector2.ZERO
	player.move_v = Vector2.ZERO
	player.set_physics_process(not on)
	hotbar.locked = on
	jobs.set_process_unhandled_input(not on)

func _process(delta: float) -> void:
	car_theft.refresh(GameState.clock.day)
	if rod_charging:
		rod_charge_t += delta
	fish_fx.charge = CastMath.power(rod_charge_t) if rod_charging else -1.0
	fish_fx.day = GameState.clock.day
	fish_fx.wind = WeatherMath.tree_wind(weather.now, PlayerMath.wind_angle(GameState.clock.day)).x * 140.0
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
		goal_arrow.set_kind(GoalArrow.kind(GameState.farm.soil.size(), GameState.farm.crops_planted(), GameState.clock.day, "watering_can" in GameState.tools_owned))
		goal_label.text = "" if _indoors() else GoalText.current(GameState.farm.soil.size(), GameState.farm.crops_planted(), GameState.clock.day, GameState.money, city_seen, GameState.bank_balance, GameState.story.goal_text(), "watering_can" in GameState.tools_owned)
	if GameState.clock.advance(0.0 if welcome != null and welcome.active else delta):
		_pass_out("late", true)
	elif PassOut.exhausted(GameState.energy.value) and not _passing_out:
		_pass_out("exhausted", false)
	else:
		_late_warning()
	if rain_day != GameState.clock.day:
		rain_day = GameState.clock.day
		rain_today = WeatherMath.rain_for_day(1, rain_day, GameState.clock.season())
		if "--rain" in OS.get_cmdline_user_args():
			rain_today = 1.0
		weather.intensity = rain_today
		farm_view.rain = rain_today
		_start_fish_event()
	if event_fish != "":
		fish_event_view.active = FishEvents.in_hours(fish_table[event_fish], fposmod(6.0 + GameState.clock.minutes / 60.0, 24.0))
	var fog := WeatherMath.fog_now(WeatherMath.fog_for_day(1, rain_day, GameState.clock.season(), rain_today), GameState.clock.minutes)
	if "--fog" in OS.get_cmdline_user_args():
		fog = 0.6
	fog_rect.color = Color(0.82, 0.86, 0.9, fog * 0.75)
	storm_t += delta
	player.rain = weather.now
	ambient.rain = maxf(weather.now, fog * 0.8)
	world.set_wet(weather.now)
	world.set_wind(WeatherMath.tree_wind(weather.now, PlayerMath.wind_angle(GameState.clock.day)))
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
	_update_bow()
	isle_view.rain = weather.now
	isle_view.haze = maxf(weather.now, fog)
	isle_view.lamp = 0.0 if _indoors() else DayNight.lamp_strength(GameState.clock.minutes)
	world.set_lamps(DayNight.lamp_strength(GameState.clock.minutes))
	car.night = 0.0 if _indoors() else DayNight.lamp_strength(GameState.clock.minutes)
	traffic.night = car.night
	traffic.rain = weather.now
	traffic.fog = fog
	if GameState.clock.season() != _season_applied:
		_season_applied = GameState.clock.season()
		world.set_season(_season_applied)
	if absf(GameState.clock.minutes - _sun_applied) >= 6.0 or _sun_applied < 0.0:
		_sun_applied = GameState.clock.minutes
		World.apply_sun(get_tree(), _sun_applied)
	var lamp_k := 0.0 if _indoors() else DayNight.lamp_strength(GameState.clock.minutes)
	town.set_night(lamp_k, NpcSchedule.hour_of(GameState.clock.minutes))
	for l in get_tree().get_nodes_in_group("night_lights"):   # streamed-chunk lights (Vance yard floodlights)
		(l as PointLight2D).energy = 1.3 * lamp_k * float(l.get_meta("dim", 1.0))
		(l as PointLight2D).visible = lamp_k > 0.01
	world.part_reeds(player.position, delta)
	if not _indoors():
		world.stream_update(player.position)
		var reg: Dictionary = world.region_now(player.position)
		if ChunkGrid.region_changed(world.region_id, String(reg.id)):
			region_banner.show_region("Gull Isle" if IsleModel.RECT.has_point(Vector2i(floori(player.position.x / 32.0), floori(player.position.y / 32.0))) else String(reg.name))
			story_view.event("region_" + String(reg.id))
		world.region_id = String(reg.id)
		var gr := gate_keeper.step(player.position, String(reg.id), GameState.story.done, delta)
		if gr["bounce"]:
			_gate_bounce(gr)
	var near := world.interactables.near(player.position, _target_cell())
	var npc_near := npcs.near(player.position + Vector2(0, -8))
	prompt.text = "" if shop.visible or dealer.visible else String(near.get("prompt", ""))
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
	if prompt.text == "" and not _indoors() and not shop.visible and not car.driving and animals.riding == null:
		prompt.text = WorldHints.text(self)
	if prompt.text == "" and not _indoors() and not shop.visible:
		prompt.text = car_theft.prompt()
	if prompt.text == "" and not _indoors() and not car.driving and animals.riding == null and not shop.visible and not bus_stops.near().is_empty():
		prompt.text = "E: Take the bus (next in %d min)" % BusModel.wait_minutes(GameState.clock.minutes) if BusModel.in_service(GameState.clock.minutes) else "Bus stop: no buses after 23:00"
	if car.can_enter() and prompt.text == "":
		prompt.text = "E: Drive"
	elif car.driving and _near_chop():
		prompt.text = "E: Sell this stolen car to the chop shop"
	elif car.driving:
		prompt.text = "Fuel %d%%  E: exit" % int(100.0 * car.fuel / VehicleMath.FUEL_MAX)
	player.indoors = _indoors()
	hud.legend_mode = KeyLegend.mode_for(car.driving, animals.riding != null, _indoors())
	_hoof_dust(delta)
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

func _update_bow() -> void:
	bow.rain = weather.now
	bow.day = GameState.clock.day
	if not bow.drawing:
		return
	if _indoors() or car.driving or hotbar.current() != "bow" or not player.is_physics_processing():
		bow.cancel()   # a menu, door or another tool lowers the bow without loosing
		return
	var to_mouse := get_global_mouse_position() - player.position
	bow.aim = to_mouse if mouse_aim and to_mouse.length() > 8.0 else CombatModel.facing_vec(player.facing)

func _hoof_dust(delta: float) -> void:
	## A galloping mount kicks up ground-coloured dust behind it (rate by speed, MountMath.dust_rate).
	var rate := MountMath.dust_rate(player.velocity.length()) if animals.riding != null and not _indoors() else 0.0
	if rate <= 0.0:
		hoof_t = 0.0
		return
	hoof_t += delta * rate
	if hoof_t >= 1.0:
		hoof_t = 0.0
		var tile: int = world.gen.tile_at(floori(player.position.x / 32.0), floori(player.position.y / 32.0))
		var back := -player.velocity.normalized() * 8.0
		ambient.puff(player.position + back + Vector2(0, 4), 4, 70.0, AmbientMath.step_dust_color(tile, GameState.clock.season()))

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo and e.keycode == KEY_F1:
		hud.legend_on = not hud.legend_on
	if e.is_action_released("use_tool") or (e is InputEventMouseButton and not e.pressed and e.button_index == MOUSE_BUTTON_LEFT):
		_rod_released()
		bow.release()
	if perk_view.handle_key(e):   # perk chooser grabs input above every other menu
		get_viewport().set_input_as_handled()
		return
	if e is InputEventKey and e.pressed and not e.echo and e.keycode == KEY_P and not car.driving and not shop.visible and not dealer.visible and not dialogue.visible and fishing.state == Fishing.State.IDLE and _open_pending_perk():
		get_viewport().set_input_as_handled()
		return
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
	if football_view.visible:
		football_view.handle(e)
		get_viewport().set_input_as_handled()
		return
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
	if forge_view.visible:
		forge_view.handle(e)
		get_viewport().set_input_as_handled()
		return
	if ferry_view.visible:
		ferry_view.handle(e)
		get_viewport().set_input_as_handled()
		return
	if bus_view.visible:
		bus_view.handle(e)
		get_viewport().set_input_as_handled()
		return
	if butcher_view.visible:
		butcher_view.handle(e)
		get_viewport().set_input_as_handled()
		return
	if smelt_view.visible:
		smelt_view.handle(e)
		get_viewport().set_input_as_handled()
		return
	if craft_view.visible or (e is InputEventKey and e.pressed and not e.echo and e.keycode == KEY_C and not car.driving and not shop.visible and not dialogue.visible and not inv_view.visible and not journal_view.visible and not interior.active):
		if not craft_view.visible:
			_open_craft()
		else:
			craft_view.handle(e)
		get_viewport().set_input_as_handled()
		return
	if sports.visible:
		sports.handle(e)
		get_viewport().set_input_as_handled()
		return
	if hangar.visible:
		get_viewport().set_input_as_handled()
		return
	if derby.visible:
		derby.handle(e)
		get_viewport().set_input_as_handled()
		return
	if upgrade_view.visible:
		upgrade_view.handle(e)
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
		elif e.is_action_pressed("interact"):
			cave.interact()
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
	if shop.visible or dealer.visible:
		return
	if build_view.handle_key(e):
		return
	if e is InputEventKey and e.pressed and not e.echo and e.keycode == KEY_G and not car.driving and not shop.visible and not _indoors():
		animals.gear_action()
		return
	if e is InputEventKey and e.pressed and not e.echo and e.keycode == KEY_T and not car.driving and not shop.visible and not _indoors():
		_steal_from_stall()
		return
	if e.is_action_pressed("interact") and car.driving and _near_chop():
		car_theft.sell()
		return
	if e.is_action_pressed("interact") and not car.driving and not _indoors() and car_theft.near_slot() != {} and not car.can_enter():
		car_theft.try_steal(_folk_near(player.position), fposmod(6.0 + GameState.clock.minutes / 60.0, 24.0))
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
	if e.is_action_pressed("interact") and not _indoors() and not car.driving and animals.riding == null and not bus_stops.near().is_empty():
		_open_bus(bus_stops.near())
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
			if not bb.is_empty() and String(bb["id"]) in InteriorModel.PUBLIC and robbery.is_closed(bb):
				if robbery.break_in(bb):
					interior.enter(bb)
					story_view.event("enter_" + String(bb["id"]))
			elif not bb.is_empty() and (String(bb["id"]) in InteriorModel.PUBLIC or not robbery.model.house(String(bb["id"]))["locked"]):
				interior.enter(bb)
				story_view.event("enter_" + String(bb["id"]))
			else:
				robbery.interact(dcell)
			return
		if it.get("kind", "") == "cave":
			cave.enter(GameState.clock.day)
			story_view.event("enter_cave")
			return
		if it.get("kind", "") == "pitch" or it.get("kind", "") == "league":
			CityActions.run(self, String(it["kind"]))
			return
		if it.get("kind", "") == "driftboard":
			_say(DriftBoard.lines(GameState.drift_board))
			toast_t = 6.0
			return
		if it.get("kind", "") == "yardcrate":
			var yi := YardHeist.nearest(player.position)
			var yd: int = GameState.clock.day
			if yi < 0:
				return
			if not YardHeist.ready(GameState.yard_looted, yi, yd):
				_say("Already stripped. Restocked in %d days" % YardHeist.days_left(GameState.yard_looted, yi, yd))
				toast_t = 3.0
				return
			var yl := YardHeist.loot(yi, yd)
			GameState.yard_looted[yi] = yd
			GameState.money += int(yl["cash"])
			if String(yl["item"]) != "":
				GameState.bag.add(String(yl["item"]), int(yl["n"]))
			GameState.rep_street += YardHeist.REP
			police.add_heat(WantedMath.crime_heat("theft"))
			_say("You lift Vance stock: $%d%s. Quiet!" % [int(yl["cash"]), (" + %d %s" % [int(yl["n"]), String(yl["item"]).replace("_", " ")]) if String(yl["item"]) != "" else ""])
			toast_t = 4.0
			return
		if it.get("kind", "") == "hangar":
			var hd: int = GameState.clock.day
			if not HangarHeist.ready(GameState.hangar_day, hd):
				_say("The hangar is locked down. Security resets in %d days" % HangarHeist.days_left(GameState.hangar_day, hd))
				toast_t = 3.0
				return
			player.velocity = Vector2.ZERO
			player.move_v = Vector2.ZERO
			player.set_physics_process(false)
			GameState.hangar_day = hd
			hangar.open()
			return
		if it.get("kind", "") == "rocket":
			_say("Your seat on the Vance rocket is waiting. The Moon (Act 3) is not built yet." if VanceYard.gate_open(GameState.story.done) else "Half-built, white and red, scaffolding up one side. Grandmother beat this to the Moon?")
			toast_t = 4.0
			return
		if it.get("kind", "") in ["board", "crate", "fence"]:
			HarbourActions.run(self, String(it["kind"]))
			return
		if it.get("kind", "") == "ferry":
			FerryActions.run(self, bool(it["outbound"]))
			return
		if it.get("kind", "") == "cairn":
			FerryActions.cairn(self)
			return
		if it.get("kind", "") == "sign":
			_say(String(it.get("text", "")))
			toast_t = 4.0
			return
		if it.get("kind", "") == "bench":
			_open_craft()
			return
		if it.get("kind", "") == "dealer":
			player.velocity = Vector2.ZERO
			player.move_v = Vector2.ZERO
			player.set_physics_process(false)
			dealer.open()
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
	elif e.is_action_pressed("use_tool") and hotbar.current() == "bow":
		bow.press()
	elif e.is_action_pressed("use_tool") and hotbar.current() == "club":
		if GameState.energy.can_use("club") and combat.cd <= 0.0:
			GameState.energy.spend("club")
			player.held_tool = "club"
			player.swing()
			sfx_director.play("swing")
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
		if hotbar.current() == "snare" and GameState.snares.snares.has(cell):
			if GameState.snares.is_ready(cell):
				_say("Empty it first (hand)")
			elif GameState.bag.count("snare_bait") < 1:
				_say("No bait - make it at the butcher block in the workshop")
			elif GameState.snares.bait(cell):
				GameState.bag.remove("snare_bait", 1)
				_say("Baited - a better catch tomorrow")
			else:
				_say("Already baited")
			return
		if hotbar.current() == "snare":
			if GameState.bag.count("snare") < 1:
				_say("No snares - buy them at the shop")
			elif GameState.snares.place(cell, world.gen.sdf_at(cell.x, cell.y), Snares.habitat_for(ChunkGrid.chunk_of_cell(cell))):
				GameState.bag.remove("snare", 1)
				_say("Snare set - check it tomorrow (rain spoils the scent)")
			else:
				_say("Set snares on dry ground away from the water")
			return
		if hotbar.current() == "hand" and GameState.snares.snares.has(cell):
			if GameState.snares.is_ready(cell):
				var worn := GameState.snares.worn(cell)
				var loot: Array = GameState.snares.collect(cell)
				for id in loot:
					drops_view.spawn(id, 1, TargetMath.center_of(cell) + Vector2(0, 6))
				_say("The snare caught game (%d)%s" % [loot.size(), " - it frayed and broke" if not GameState.snares.snares.has(cell) else ""])
			else:
				GameState.snares.pick_up(cell)
				GameState.bag.add("snare", 1)
				_say("Picked up the snare")
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
		tree_fall.model.bonus_wood = int(PerkModel.value(GameState.perks, "wood_bonus"))
		if hotbar.current() == "axe" and tree_fall.hit_log(cell, player.position):
			return  # chopping a fallen trunk into logs
		var msg := ToolUse.apply(hotbar.current(), cell, GameState.farm, GameState.bag, GameState.clock.season(), world.gen, GameState.nodes, GameState.energy, dl, axe_table)
		if msg == "" and hotbar.current() == "hand" and combat.cd <= 0.0 and GameState.energy.can_use("club"):   # bare fists on small game
			if animals.hunt(player.position + Vector2(0, -8), CombatModel.facing_vec(player.facing), CombatModel.weapon("fist")) > 0:
				combat.cd = CombatModel.cooldown("fist")
				GameState.energy.spend("club")
				return
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
		if hotbar.current() == "pickaxe" and msg.begins_with("Got") and not dl.is_empty() and PerkModel.ore_extra(GameState.perks, randf()) > 0:
			dl[0]["n"] = int(dl[0]["n"]) + 1
			msg += " +1 bonus"
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

			if PerkModel.crop_bonus(GameState.perks, SkillModel.level(int(GameState.skill_xp.get("farming", 0))), randf()) > 0 and not dl.is_empty():
				drops_view.spawn(dl[0]["id"], 1, TargetMath.center_of(cell) + Vector2(8, 10))
				msg += " +1 bonus"
		elif msg.begins_with("Got") and hotbar.current() == "axe":
			sk = "foraging"
		elif msg.begins_with("Got") and hotbar.current() == "pickaxe":
			sk = "mining"
		if sk != "" and _skill_gain(sk):
			msg = "%s level %d!" % [sk.capitalize(), SkillModel.level(int(GameState.skill_xp[sk]))]
		world.sync_props(GameState.nodes)
		if msg != "":
			sfx_director.tool_result(hotbar.current(), msg)
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

func _start_fish_event() -> void:
	## A new day: maybe a legendary is sighted, in the lake by the home dock or off the harbour pier.
	var caught: Array = []
	for id in GameState.journal.entries:
		if int(GameState.journal.entries[id].count) > 0:
			caught.append(id)
	event_fish = FishEvents.for_day(fish_events, fish_table, GameState.clock.day, GameState.clock.season(), caught)
	var spot := Vector2i(-1, -1)
	if event_fish != "":
		var sea := bool(fish_table[event_fish].get("sea", false))
		var from: Vector2i = HarbourModel.HEAD.position + Vector2i(HarbourModel.HEAD.size.x / 2, 6) if sea else (world.gen.dock[1] if world.gen.dock.size() > 1 else Vector2i(32, 32))
		spot = FishEvents.find_spot(from, func(c: Vector2i) -> float: return world.gen.sdf_at(c.x, c.y), 40, -1.5, 0 if sea else 6)
		_say(String(fish_events["events"][event_fish]))
		toast_t = 8.0
	fish_event_view.show_at(spot)

func _fish_ctx() -> Dictionary:
	var caught: Array = []
	for id in GameState.journal.entries:
		if int(GameState.journal.entries[id].count) > 0:
			caught.append(id)
	var cc := _water_cell_ahead(CastMath.distance_tiles(CastMath.power(rod_charge_t)))
	var hour := fposmod(6.0 + GameState.clock.minutes / 60.0, 24.0)
	var sighted := ""
	if event_fish != "" and cc.x >= 0 and FishEvents.hits(fish_events, fish_table[event_fish], cc, fish_event_view.spot, hour):
		sighted = event_fish
	return {"event_fish": sighted, "event_boost": float(fish_events.get("boost", 0.4)), "rain": rain_today, "hour": fposmod(6.0 + GameState.clock.minutes / 60.0, 24.0), "caught": caught, "caught_count": GameState.journal.total_caught(), "sea": cc.x >= 0 and HarbourModel.in_sea_area(cc), "hot": cc.x >= 0 and FishSpots.is_hot(cc, GameState.clock.day), "perk_bar": PerkModel.value(GameState.perks, "reel_bar_bonus")}

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
			sfx_director.play("swing")
			player.held_tool = "rod"
			player.swing()

func _update_fishing(delta: float) -> void:
	fishing.tick(delta, Input.is_action_pressed("use_tool") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT))
	if fishing.state == Fishing.State.CAUGHT:
		GameState.bag.add(fishing.fish_id, 1)
		sfx_director.play("splash")
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

func _folk_near(p: Vector2) -> int:
	var n := 0
	for a in npcs.actors:
		if (a["node"] as Node2D).position.distance_to(p) < 200.0:
			n += 1
	return n

func _near_chop() -> bool:
	if not car_theft.can_sell():
		return false
	for b in CityModel.buildings():
		if b["kind"] == "garage":
			return car.position.distance_to((Vector2(b["door"]) + Vector2(0.5, 0.5)) * 32.0) < 110.0
	return false

func _open_craft() -> void:
	player.velocity = Vector2.ZERO
	player.move_v = Vector2.ZERO
	player.set_physics_process(false)
	craft_view.open()

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
			var w := CombatModel.with_mult(CombatModel.weapon("club"), CombatModel.club_mult(GameState.bag, DataDB.load_json("clubs")))
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
	drops_view.spawn(id, n + PerkModel.ore_extra(GameState.perks, randf()), pos)
	var sk := "mining"
	if _skill_gain(sk):
		_say("Mining level %d!" % SkillModel.level(int(GameState.skill_xp[sk])))

func _on_warden_down(pos: Vector2) -> void:
	GameState.warden_day = GameState.clock.day
	GameState.bump("wardens")
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var i := 0
	for l in BossModel.loot(rng):
		drops_view.spawn(String(l[0]), int(l[1]), pos + Vector2(-28 + 28 * i, 12))
		i += 1
	_say("The Stone Warden falls! Take its core to the anvil")
	toast_t = 5.0

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
	if PerkModel.crop_bonus(GameState.perks, SkillModel.level(int(GameState.skill_xp.get("farming", 0))), randf()) > 0 and not dl.is_empty():
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
		if PerkModel.pending(GameState.skill_xp, GameState.perks).has(sk):
			perk_view.open_later(sk, SkillModel.level(int(GameState.skill_xp[sk])))
	return up

func _setup_perk_view() -> void:
	perk_view = PerkView.new()
	perk_view.blocked = func() -> bool: return shop.visible or dealer.visible or dialogue.visible or car.driving
	var was_free := [true]   # restore the player's state: a bag or cutscene may still hold them under the chooser
	perk_view.opened.connect(func():
		was_free[0] = player.is_physics_processing()
		player.velocity = Vector2.ZERO
		player.move_v = Vector2.ZERO
		player.set_physics_process(false)
		hotbar.locked = true
		jobs.set_process_unhandled_input(false))
	perk_view.closed.connect(func():
		player.set_physics_process(was_free[0])
		hotbar.locked = false
		jobs.set_process_unhandled_input(true))
	perk_view.picked.connect(func(sk: String, id: String):
		if not GameState.choose_perk(sk, id):
			return
		sfx_director.play("pickup")
		_say("New perk: %s" % PerkModel.option(sk, id)["name"])
		if not _open_pending_perk():
			perk_view.close())
	add_child(perk_view)

func _open_pending_perk() -> bool:
	var waiting := PerkModel.pending(GameState.skill_xp, GameState.perks)
	if waiting.is_empty():
		return false
	perk_view.open(waiting[0], SkillModel.level(int(GameState.skill_xp.get(waiting[0], 0))))
	return true

func _dirt_puff(cell: Vector2i) -> void:
	var fd: Vector2 = TargetMath.center_of(cell) - player.position
	for i in 5:   # soil clods flicked away from the hoe in a fan
		var clod := CPUParticles2D.new()
		clod.position = TargetMath.center_of(cell) + Vector2(0, 4)
		clod.emitting = true
		clod.one_shot = true
		clod.explosiveness = 1.0
		clod.amount = 1
		clod.lifetime = 0.45
		var v := HitMath.clod_velocity(i, 5, fd)
		clod.direction = v.normalized()
		clod.spread = 4.0
		clod.initial_velocity_min = v.length()
		clod.initial_velocity_max = v.length()
		clod.gravity = Vector2(0, 260)
		clod.scale_amount_min = 2.0
		clod.scale_amount_max = 3.0
		clod.color = Color(0.36, 0.23, 0.13) if i % 2 == 0 else Color(0.5, 0.34, 0.2)
		world.add_child(clod)
		get_tree().create_timer(0.9).timeout.connect(clod.queue_free)
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

var _passing_out := false
var _warn_level := 0

func _late_warning() -> void:
	var lv := PassOut.warning_level(GameState.clock.minutes)
	if lv != _warn_level:
		_warn_level = lv
		if lv > 0:
			_say(PassOut.warning(GameState.clock.minutes))
			toast_t = 3.0

func _pass_out(cause: String, clock_rolled: bool) -> void:
	## Collapse (zero energy or 2am): lose some cash, wake at the farmhouse or the Port Halden hospital.
	_passing_out = true
	_warn_level = 0
	var cell := Vector2i(floori(player.position.x / 32.0), floori(player.position.y / 32.0))
	if interior.active:
		interior._do_leave()
		interior.busy = false
		interior._freeze(false)
	if cave.active:
		cave._do_leave()
		cave.busy = false
		cave._freeze(false)
	if car.driving:
		car.driving = false
		car.vel = Vector2.ZERO
	var home_door := _home_door()
	var hosp_door := Vector2i(198, -2)
	for b in CityModel.buildings():
		if String(b["id"]) == "city_hospital":
			hosp_door = b["door"]
	var spot := PassOut.wake_spot(cell, home_door, hosp_door)
	var loss := PassOut.money_loss(GameState.money)
	GameState.money -= loss
	var fee := PassOut.bill(spot, GameState.money)
	GameState.money -= fee
	if not clock_rolled:
		GameState.clock.new_day()
	_end_day()
	GameState.energy.value = PassOut.wake_energy(cause)
	var door: Vector2i = home_door if spot == "home" else hosp_door
	player.position = (Vector2(door) + Vector2(0.5, 1.6)) * 32.0
	player.facing = PlayerMath.Facing.DOWN
	GameState.stats["pass_outs"] = int(GameState.stats.get("pass_outs", 0)) + 1
	_say(PassOut.summary(cause, loss, spot, fee))
	toast_t = 5.0
	_pass_out_fade()
	GameState.save_game()
	_passing_out = false

func _bus_open_cb(cell: Vector2i) -> bool:
	if not gate_keeper.enabled:
		return true
	var rid := String(world.stream.region_at(ChunkGrid.chunk_of_cell(cell)).get("id", ""))
	return StoryGate.lock_message(gate_keeper.gates, rid, GameState.story.done) == ""

func _open_bus(stop: Dictionary) -> void:
	if not BusModel.in_service(GameState.clock.minutes):
		_say("The last bus has gone - buses run 06:00-23:00")
		return
	player.velocity = Vector2.ZERO
	player.move_v = Vector2.ZERO
	player.set_physics_process(false)
	bus_view.open(stop, BusModel.options(bus_stops.stops, String(stop["id"]), GameState.money, _bus_open_cb), BusModel.wait_minutes(GameState.clock.minutes))

func _bus_ride(stop: Dictionary, fare: int, minutes: int) -> void:
	GameState.money -= fare
	GameState.clock.minutes = minf(GameState.clock.minutes + float(minutes), float(GameClock.DAY_LENGTH_MIN) - 1.0)
	player.position = (Vector2(stop["cell"]) + Vector2(1.0, 1.8)) * 32.0
	player.facing = PlayerMath.Facing.DOWN
	GameState.stats["bus_rides"] = int(GameState.stats.get("bus_rides", 0)) + 1
	_say("Bus to %s: $%d, %d min. Arrived %s" % [stop["name"], fare, minutes, GameState.clock.time_string()])
	toast_t = 4.0
	_pass_out_fade()

func _pass_out_fade() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 90
	var r := ColorRect.new()
	r.color = Color(0, 0, 0, 1)
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(r)
	add_child(layer)
	var tw := create_tween()
	tw.tween_interval(0.5)
	tw.tween_property(r, "color:a", 0.0, 1.4)
	tw.tween_callback(layer.queue_free)

func _end_day() -> void:
	## Bedtime / pass-out / sleeping in a bed: crops grow, rain waters, energy refills, autosave.
	if rain_today > 0.0:
		GameState.farm.rain_water()  # it rained today: crops are watered
		_say("Rain watered the crops")
	var sprinkled := GameState.farm.sprinkle()
	if sprinkled > 0:
		_say("Sprinklers watered %d tiles" % sprinkled)
	var crows := GameState.farm.crow_raid(GameState.clock.day)
	if crows > 0:
		_say("Crows ate %d crops (a scarecrow keeps them off)" % crows)
	GameState.farm.next_day()
	stall_stolen = 0
	var rngp := RandomNumberGenerator.new()
	rngp.seed = GameState.clock.day * 31 + 5
	var snared := GameState.snares.night_tick(rngp, rain_today > 0.0)
	if snared > 0:
		_say("Something is caught in your snares")
	var caught := GameState.pots.day_tick(rngp)
	if caught > 0:
		_say("Your crab pots caught something")
	GameState.farm.spawn_weeds(GameState.clock.day)
	GameState.nodes.next_day()
	GameState.market.new_day()
	if GameState.artisan.day_tick() > 0:
		_say("Something is ready in the barn")
	var cafe_add := GameState.business.day_tick(GameState.clock.day, rain_today > 0.0)
	if cafe_add > 0:
		_say("Your cafe took $%d last night" % cafe_add)
	animals.day_tick()
	GameState.ranger.new_day()
	GameState.bank_balance += CityServices.daily_interest(GameState.bank_balance)
	GameState.energy.new_day(false)
	world.sync_props(GameState.nodes)
	GameState.save_game()

func _hangar_done(r: Dictionary) -> void:
	player.set_physics_process(true)
	if bool(r["alarm"]):
		police.add_heat(WantedMath.crime_heat("robbery"))
		_say("The hangar alarm trips! Vance security throws you out.")
		toast_t = 4.0
		return
	var opened: Array = r["opened"]
	if opened.is_empty():
		_say("You slip out of the hangar with nothing.")
		toast_t = 3.0
		return
	GameState.money += int(r["cash"])
	for it in r["items"]:
		GameState.bag.add(String(it["item"]), int(it["n"]))
	for i in opened:
		GameState.rep_street += int(HangarHeist.CASES[int(i)]["rep"])
	GameState.stats["hangar_heists"] = int(GameState.stats.get("hangar_heists", 0)) + 1
	police.add_heat(WantedMath.crime_heat("theft"))
	_say("Hangar raid: $%d from %d case(s). Clean getaway!" % [int(r["cash"]), opened.size()])
	toast_t = 5.0

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
	if not soil_drops:
		sfx_director.play("splash")
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
