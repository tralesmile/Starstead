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
var prompt: Label
var fishing := Fishing.new(int(Time.get_unix_time_from_system()))
var fish_table: Dictionary = DataDB.load_json("fish")

func _ready() -> void:
	y_sort_enabled = true
	world = World.new()
	add_child(world)
	world.build(1)
	add_child(FarmView.new())
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
	add_child(FishingView.new(fishing))
	build_view = BuildView.new()
	add_child(build_view)
	build_view.setup(world, world.gen, player)
	build_view.message.connect(_say)
	shop = ShopView.new()
	shop.closed.connect(func(): player.set_physics_process(true))
	add_child(shop)
	prompt = Label.new()
	prompt.position = Vector2(260, 300)
	add_child(prompt)
	if GameState.bag.count("turnip_seed") == 0:
		GameState.bag.add("turnip_seed", 10)
	for a in OS.get_cmdline_user_args():  # screenshot helper: --hour=22 sets the clock
		if a.begins_with("--hour="):
			GameState.clock.minutes = (float(a.substr(7)) - 6.0) * 60.0
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
	if GameState.clock.advance(delta):
		GameState.farm.next_day()
		GameState.nodes.next_day()
		GameState.energy.new_day(false)
		world.sync_props(GameState.nodes)
		GameState.save_game()  # bedtime / pass-out: next day, autosave
	modulate_node.color = DayNight.tint(GameState.clock.minutes)

	_update_fishing(delta)
	var near := world.interactables.near(player.position, PlayerMath.facing_tile(player.position, player.facing))
	prompt.text = "" if shop.visible else String(near.get("prompt", ""))
	_update_highlight()
	_update_fade(delta)
	toast_t -= delta
	if toast_t <= 0.0:
		toast.text = ""

func _unhandled_input(e: InputEvent) -> void:
	if shop.visible:
		return
	if build_view.handle_key(e):
		return
	if e.is_action_pressed("interact"):
		var it := world.interactables.near(player.position, PlayerMath.facing_tile(player.position, player.facing))
		if it.get("kind", "") == "shop":
			player.velocity = Vector2.ZERO
			player.move_v = Vector2.ZERO
			player.set_physics_process(false)
			shop.open()
			return
	if e.is_action_pressed("use_tool") and hotbar.current() == "rod":
		_rod_pressed()
	elif e.is_action_pressed("use_tool"):
		player.swing()
		var cell := PlayerMath.facing_tile(player.position, player.facing)
		var msg := ToolUse.apply(hotbar.current(), cell, GameState.farm, GameState.bag, GameState.clock.season(), world.gen, GameState.nodes, GameState.energy)
		world.sync_props(GameState.nodes)
		if msg != "" and (hotbar.current() == "axe" or hotbar.current() == "pickaxe"):
			_hit_feedback(cell, hotbar.current(), msg.begins_with("Got"))
		if msg != "":
			toast.text = msg
			toast_t = 1.5

func _update_highlight() -> void:
	## Yellow outline on the tree/rock the player faces (the interact target).
	var cell := PlayerMath.facing_tile(player.position, player.facing)
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

func _water_cell_ahead() -> Vector2i:
	## First water cell 1-4 tiles in front of the player (cast distance), or (-1,-1).
	var base := PlayerMath.facing_tile(player.position, player.facing)
	var dir := base - Vector2i(floori(player.position.x / 32.0), floori(player.position.y / 32.0))
	for k in 4:
		var c := base + dir * k
		if world.gen.sdf_at(c.x, c.y) < 0.0:
			return c
	return Vector2i(-1, -1)

func _rod_pressed() -> void:
	if fishing.state == Fishing.State.IDLE:
		var c := _water_cell_ahead()
		if c.x < 0:
			_say("Face the water to cast")
		elif not GameState.energy.can_use("rod"):
			_say("Too tired")
		elif fishing.cast(world.gen.sdf_at(c.x, c.y), fish_table, GameState.clock.season()):
			GameState.energy.spend("rod")
			player.swing()
	elif fishing.state == Fishing.State.WAITING:
		fishing.hook()
		_say("Too early!")
	elif fishing.state == Fishing.State.BITE:
		fishing.hook()

func _update_fishing(delta: float) -> void:
	fishing.tick(delta, Input.is_action_pressed("use_tool"))
	if fishing.state == Fishing.State.CAUGHT:
		GameState.bag.add(fishing.fish_id, 1)
		_say("Caught a " + fish_table[fishing.fish_id].name + "!")
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
