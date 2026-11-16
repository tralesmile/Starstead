extends Node2D
## World root: chunk + player + HUD + day/night; passing out advances the day and saves.

var player: Player
var modulate_node: CanvasModulate

func _ready() -> void:
	var world := World.new()
	add_child(world)
	world.build(1)
	player = Player.new()
	player.position = Vector2(32.5, 32.5) * 32.0
	add_child(player)
	modulate_node = CanvasModulate.new()
	add_child(modulate_node)
	add_child(Hud.new())
	$HUD.queue_free()

func _process(delta: float) -> void:
	if GameState.clock.advance(delta):
		GameState.save_game()  # bedtime / pass-out: next day, autosave
	modulate_node.color = DayNight.tint(GameState.clock.minutes)
