class_name FishingWorldView
extends Node2D
## In-world fishing visuals: line from the rod tip, bobber that bobs / dips, splash rings on cast and bite, "!" alert.

var fishing: Fishing
var player: Node2D
var target := Vector2.ZERO
var t := 0.0
var charge := -1.0   # 0..1 while holding the cast button, -1 otherwise
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
	var casting := fishing.state != Fishing.State.IDLE and fishing.state != Fishing.State.CAUGHT
	if charge >= 0.0 or casting or cast_age < 0.5:
		_draw_rod(casting)
	if charge >= 0.0:
		var o := player.position + Vector2(-12, 6)
		draw_rect(Rect2(o + Vector2(-1, -1), Vector2(26, 5)), Color(0.1, 0.06, 0.03, 0.9))
		draw_rect(Rect2(o, Vector2(24.0 * charge, 3)), Color(1.0, 0.8, 0.2) if charge < 0.85 else Color(0.5, 1.0, 0.4))
		var d := CastMath.distance_tiles(charge)
		draw_string(ThemeDB.fallback_font, o + Vector2(2, 14), "%d tiles" % d, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(1, 1, 1, 0.9))
	if fishing.state == Fishing.State.IDLE or fishing.state == Fishing.State.CAUGHT:
		return
	var tip := _rod_tip()
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

func _side() -> float:
	return RodMath.side_for(player.facing == PlayerMath.Facing.LEFT, target.x - player.position.x if casting_target() else 0.0)

func casting_target() -> bool:
	return fishing.state != Fishing.State.IDLE and fishing.state != Fishing.State.CAUGHT

func _grip() -> Vector2:
	return player.position + Vector2(_side() * 6.0, -13.0)

func _rod_deg() -> float:
	if charge >= 0.0:
		return RodMath.charge_deg(charge)
	if cast_age < RodMath.SWING_TIME:
		return RodMath.swing_deg(cast_age)
	return RodMath.hold_deg(t, fishing.state == Fishing.State.BITE, fishing.state == Fishing.State.REELING)

func _rod_tip() -> Vector2:
	return RodMath.tip(_grip(), _side(), _rod_deg())

func _draw_rod(_casting: bool) -> void:
	var g := _grip().round()
	var tp := _rod_tip().round()
	var mid := g.lerp(tp, 0.5)
	draw_line(g, tp + Vector2(0, 1), Color(0.12, 0.07, 0.04), 3.0)   # outline
	draw_line(g, mid, Color(0.55, 0.36, 0.18), 1.0)                   # handle half
	draw_line(mid, tp, Color(0.78, 0.6, 0.3), 1.0)                    # thin tip half
	draw_circle(g, 1.5, Color(0.9, 0.72, 0.55))                       # hand
	draw_rect(Rect2(tp - Vector2(1, 1), Vector2(2, 2)), Color(0.9, 0.9, 0.85))
