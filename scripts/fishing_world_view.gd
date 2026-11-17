class_name FishingWorldView
extends Node2D
## In-world fishing visuals: line from the rod tip, bobber that bobs / dips, splash rings on cast and bite, "!" alert.

var fishing: Fishing
var player: Node2D
var target := Vector2.ZERO
var t := 0.0
var cast_age := 99.0
var bite_age := 99.0
var _last_state := Fishing.State.IDLE

func setup(f: Fishing, p: Node2D) -> void:
	fishing = f
	player = p
	z_index = 5

func start_cast(cell_center: Vector2) -> void:
	target = cell_center
	cast_age = 0.0

func _process(delta: float) -> void:
	t += delta
	cast_age += delta
	bite_age += delta
	if fishing.state == Fishing.State.BITE and _last_state != Fishing.State.BITE:
		bite_age = 0.0
	_last_state = fishing.state
	queue_redraw()

func _draw() -> void:
	if fishing.state == Fishing.State.IDLE or fishing.state == Fishing.State.CAUGHT:
		return
	var tip := player.position + Vector2(11, -26)
	var biting := fishing.state == Fishing.State.BITE
	var reeling := fishing.state == Fishing.State.REELING
	var bp := target + Vector2(0, BobberMath.bob(t, biting or reeling))
	if cast_age < 0.35:  # the bobber flies out from the rod tip in an arc
		var k := cast_age / 0.35
		bp = tip.lerp(bp, k) + Vector2(0, -sin(k * PI) * 22.0)
	var sag := 6.0 if not reeling else 1.0
	var prev := tip
	for i in range(1, 13):
		var q := BobberMath.line_point(tip, bp, float(i) / 12.0, sag)
		draw_line(prev.round(), q.round(), Color(1, 1, 1, 0.75), 1.0)
		prev = q
	for sp in [cast_age - 0.35, bite_age]:
		var s := BobberMath.splash(sp)
		if s.y > 0.0:
			_ellipse(target + Vector2(0, 2), s.x, s.x * 0.45, Color(1, 1, 1, s.y * 0.8))
	draw_circle(bp + Vector2(0, -1), 3.0, Color(0.15, 0.1, 0.08))
	draw_circle(bp + Vector2(0, -1), 2.0, Color(0.92, 0.2, 0.18))
	draw_rect(Rect2(bp + Vector2(-2, -1), Vector2(4, 1)), Color(1, 1, 1))
	if biting:
		var font := ThemeDB.fallback_font
		var bounce := roundf(sin(t * 18.0) * 2.0)
		draw_string(font, player.position + Vector2(-4, -58 + bounce), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1, 0.9, 0.2))

func _ellipse(c: Vector2, rx: float, ry: float, col: Color) -> void:
	var prev := c + Vector2(rx, 0)
	for i in range(1, 17):
		var a := TAU * float(i) / 16.0
		var p := c + Vector2(roundf(cos(a) * rx), roundf(sin(a) * ry))
		draw_line(prev, p, col, 1.0)
		prev = p
