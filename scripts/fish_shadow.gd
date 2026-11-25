class_name FishShadow
extends Sprite2D
## A fish shadow that wanders inside water (stays where sdf < -0.8), tail animated.

var gen: WorldGen
var origin := Vector2i.ZERO   # chunk origin cell (streamed chunks query their own local sdf)
var target := Vector2.ZERO
var rng := RandomNumberGenerator.new()
var _t := 0.0

func setup(tex: Texture2D, g: WorldGen, cell: Vector2i, s: int) -> void:
	texture = tex
	hframes = 4
	gen = g
	rng.seed = s
	position = Vector2(cell) * 32.0 + Vector2(16, 16)
	z_index = -6
	_pick()

func _pick() -> void:
	for i in 10:
		var p := position + Vector2(rng.randf_range(-80, 80), rng.randf_range(-60, 60))
		var c := Vector2i(floori(p.x / 32), floori(p.y / 32))
		if gen.sdf_at(c.x - origin.x, c.y - origin.y) < -0.8:
			target = p
			return
	target = position

func _process(delta: float) -> void:
	_t += delta
	frame = int(_t * 6.0) % 4
	var to := target - position
	if to.length() < 2.0:
		_pick()
		return
	var v := to.normalized() * 14.0 * delta
	position += v
	flip_h = v.x < 0
