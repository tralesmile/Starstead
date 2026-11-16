class_name Hud
extends CanvasLayer
## Clock, day, season, money labels bound to GameState.

var label: Label

func _init() -> void:
	label = Label.new()
	label.position = Vector2(8, 6)
	add_child(label)

func _process(_d: float) -> void:
	label.text = HudText.format(GameState.clock, GameState.money)
