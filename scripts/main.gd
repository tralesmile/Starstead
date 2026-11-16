extends Node2D
## World root: chunk + player + HUD + day/night; passing out advances the day and saves.

var player: Player
var modulate_node: CanvasModulate
var world: World
var hotbar: Hotbar
var toast: Label
var toast_t := 0.0

func _ready() -> void:
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
	add_child(player)
	modulate_node = CanvasModulate.new()
	add_child(modulate_node)
	add_child(Hud.new())
	hotbar = Hotbar.new()
	add_child(hotbar)
	toast = Label.new()
	toast.position = Vector2(8, 24)
	add_child(toast)
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

	toast_t -= delta
	if toast_t <= 0.0:
		toast.text = ""

func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("use_tool"):
		var cell := PlayerMath.facing_tile(player.position, player.facing)
		var msg := ToolUse.apply(hotbar.current(), cell, GameState.farm, GameState.bag, GameState.clock.season(), world.gen, GameState.nodes, GameState.energy)
		world.sync_props(GameState.nodes)
		if msg != "":
			toast.text = msg
			toast_t = 1.5
