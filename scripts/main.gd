extends Node2D
## World root: chunk + player + HUD + day/night; passing out advances the day and saves.

var player: Player
var modulate_node: CanvasModulate
var world: World
var hotbar: Hotbar
var toast: Label
var toast_t := 0.0
var highlighted: Sprite2D = null
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
	add_child(FishingView.new(fishing))
	if GameState.bag.count("turnip_seed") == 0:
		GameState.bag.add("turnip_seed", 10)
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
	_update_highlight()
	_update_fade(delta)
	toast_t -= delta
	if toast_t <= 0.0:
		toast.text = ""

func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("use_tool") and hotbar.current() == "rod":
		_rod_pressed()
	elif e.is_action_pressed("use_tool"):
		player.swing()
		var cell := PlayerMath.facing_tile(player.position, player.facing)
		var msg := ToolUse.apply(hotbar.current(), cell, GameState.farm, GameState.bag, GameState.clock.season(), world.gen, GameState.nodes, GameState.energy)
		world.sync_props(GameState.nodes)
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
