extends Node2D
## Placeholder world root: shows clock and money until the player/world slice lands.

@onready var label: Label = $HUD/Label

func _process(delta: float) -> void:
	GameState.clock.advance(delta)
	label.text = "Day %d  %s  $%d" % [GameState.clock.day, GameState.clock.time_string(), GameState.money]
