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
var water_at: Callable = func(_c): return false
var day := 0
var line := FishingLine.new()
var throw_age := 99.0   # since the last cast left the rod (cast_age also restarts for a caught fish's splash)
var wind := 0.0         # px/s^2 sideways on the line (storm wind)
var sound_cb: Callable = func(_n: String): pass
var _click_t := 0.0
var _last_progress := 0.0
var _bob := Vector2.ZERO

func setup(f: Fishing, p: Node2D) -> void:
	fishing = f
	player = p
	z_index = 5

var _icons: Dictionary = DataDB.load_json("item_icons")
var _item_tex: Texture2D = load("res://assets/sprites/items.png")
var leaps: Array = []   # {id, from, to, t, dur}: caught fish arcing into the player's arms (LeapMath)

func leap(fish_id: String) -> void:
	var from := target if target != Vector2.ZERO else player.position + Vector2(0, 40)
	var to := player.position + Vector2(0, -24)
	leaps.append({"id": fish_id, "from": from, "to": to, "t": 0.0, "dur": LeapMath.duration(from, to)})
	cast_age = 0.0   # splash rings where it jumped out

func start_cast(cell_center: Vector2) -> void:
	target = cell_center
	cast_age = 0.0
	throw_age = 0.0
	line.reset(_rod_tip(), _rod_tip() + Vector2(0.5, 0))

func _process(delta: float) -> void:
	t += delta
	cast_age += delta
	bite_age += delta
	if fishing.state == Fishing.State.BITE and _last_state != Fishing.State.BITE:
		bite_age = 0.0
	throw_age += delta
	if fishing.state == Fishing.State.LOST or (_last_state == Fishing.State.REELING and fishing.state == Fishing.State.IDLE):
		if _last_progress <= 0.05:
			sound_cb.call("line_snap")
		_last_progress = 1.0
	_last_state = fishing.state
	_update_line(delta)
	_update_pose()
	for l in leaps:
		l["t"] = float(l["t"]) + delta
		l["to"] = player.position + Vector2(0, -24)   # follows the player if they step back
	leaps = leaps.filter(func(l): return float(l["t"]) < float(l["dur"]) + 0.35)
	queue_redraw()

func _update_line(delta: float) -> void:
	if not casting_target():
		return
	var reeling := fishing.state == Fishing.State.REELING
	var biting := fishing.state == Fishing.State.BITE
	var bp := target + Vector2(0, BobberMath.bob(t, biting or reeling))
	if reeling:
		bp += FishingLine.fish_tug(fishing.fish_pos, fishing.progress, t)
		_click_t -= delta
		if _click_t <= 0.0:
			var gaining := fishing.overlapping()
			_click_t = FishingLine.click_interval(gaining)
			sound_cb.call("reel_click")
		_last_progress = fishing.progress
	var flying := throw_age < 0.35
	if flying:   # the bobber flies out from the rod tip in an arc
		var k := throw_age / 0.35
		bp = _rod_tip().lerp(bp, k) + Vector2(0, -sin(k * PI) * 22.0)
	_bob = bp
	line.step(_rod_tip(), bp, FishingLine.slack_for(flying, fishing.state == Fishing.State.WAITING), wind, delta)

func _update_pose() -> void:
	var col := -1
	if charge >= 0.0 or casting_target():
		col = PlayerMath.fishing_frame(charge >= 0.0, throw_age, fishing.state == Fishing.State.REELING, t)
	player.fish_pose = col

func _draw_leaps() -> void:
	var cols := maxi(1, _item_tex.get_width() / 16)
	for l in leaps:
		var dur: float = l["dur"]
		var k := float(l["t"]) / dur
		var from: Vector2 = l["from"]
		var to: Vector2 = l["to"]
		var p := LeapMath.pos(from, to, k) - global_position
		var rot := LeapMath.spin(k, to.x - from.x) if k < 1.0 else 0.0
		var sc := LeapMath.landing_squash(float(l["t"]) - dur) if k >= 1.0 else Vector2.ONE
		if k < 1.0:   # shadow on the ground under the fish
			var gp := from.lerp(to, clampf(k, 0.0, 1.0)) - global_position + Vector2(0, 24 * k)
			_ellipse(gp, 6.0, 2.0, Color(0, 0, 0, 0.25))
		var fi := int(_icons.get(String(l["id"]), 0))
		draw_set_transform(p, rot, sc * 1.25)
		draw_texture_rect_region(_item_tex, Rect2(-8, -8, 16, 16), Rect2((fi % cols) * 16, (fi / cols) * 16, 16, 16))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		if k < 0.25:   # water drops shaken off as it leaves the water
			for i in 3:
				draw_rect(Rect2(p + Vector2(-6 + i * 6, 6 + i % 2 * 3) * (1.0 + k * 3.0), Vector2(1, 1)), Color(0.8, 0.95, 1.0, 0.9))

func _draw_hot_spots() -> void:
	## While you hold the cast button: slow ripples over the day's hot blocks (FishSpots) near you.
	var pc := Vector2i(floori(player.position.x / 32.0), floori(player.position.y / 32.0))
	for b in FishSpots.hot_blocks_near(pc, day):
		for k in 3:
			var c := b * FishSpots.BLOCK + Vector2i((k * 2 + 1) % FishSpots.BLOCK, (k * 3 + 2) % FishSpots.BLOCK)
			if not bool(water_at.call(c)):
				continue
			var ph := fposmod(t * 0.7 + float(k) / 3.0 + float(b.x + b.y) * 0.13, 1.0)
			var ctr := Vector2(c) * 32.0 + Vector2(16, 16)
			_ellipse(ctr, 4.0 + ph * 14.0, (4.0 + ph * 14.0) * 0.45, Color(1, 1, 1, 0.85 * (1.0 - ph * 0.8)))
			if ph < 0.3:
				draw_rect(Rect2(ctr + Vector2(-1, -4 - ph * 12.0), Vector2(2, 2)), Color(0.9, 1.0, 1.0, 0.8 - ph * 2.0))

func _draw() -> void:
	_draw_leaps()
	if charge >= 0.0:
		_draw_hot_spots()
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
	var biting := fishing.state == Fishing.State.BITE
	var bp := _bob
	var red := FishingLine.strain(fishing.progress) if fishing.state == Fishing.State.REELING else 0.0
	var col := Color(1, 1, 1, 0.75).lerp(Color(1.0, 0.3, 0.2, 0.95), red * (0.65 + 0.35 * sin(t * 24.0)))
	for i in range(1, line.pts.size()):
		draw_line(line.pts[i - 1].round(), line.pts[i].round(), col, 1.0)
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
