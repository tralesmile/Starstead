class_name LilyPad
extends Sprite2D
## A drifting, bobbing lily pad (WaterMotion); `player` is optional so pads can part around the swimmer/boat later.

var base := Vector2.ZERO
var phase := 0.0
var player: Node2D = null
var _t := 0.0

func _process(delta: float) -> void:
	_t += delta
	var off := WaterMotion.offset(_t, phase)
	if player != null:
		off += WaterMotion.push_away(base + off, player.position)
	position = base + off
