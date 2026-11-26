class_name PuddleView
extends Node2D
## Mirrors people, cars, trees and posts in rain puddles, and draws the splash rings and droplets of footfalls.
## Each reflection is drawn in 4px blocks, only where PuddleMath says water stands on a path or asphalt.

const SCAN_EVERY := 0.4
const REACH := Vector2(420, 260)
const MIN_WET := 0.25

signal splashed(gain: float, pitch: float)

var world: Node2D       # World: .wet, .gen
var player: Node2D
var sources: Array = []   # Sprite2D nodes standing near the player
var splashes: Array = []  # {pos, age, drops: [{v, p}]}
var lamps: Array = []     # PointLight2D of street lamps, lanterns and windows near the player
var glow: Node2D          # additive, unshaded layer for their reflection streaks
var streak_blocks := 0
var _gloss := {}          # Vector2i (2px cell) -> PuddleMath.gloss, cleared on every scan
var blocks_drawn := 0
var _scan_t := 0.0
var _t := 0.0

func setup(w: Node2D, p: Node2D) -> void:
	world = w
	player = p
	z_index = -2
	z_as_relative = false
	p.footstep.connect(_on_step)
	glow = Node2D.new()
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	m.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	glow.material = m
	glow.draw.connect(_draw_streaks)
	add_child(glow)

func standing_water(at: Vector2) -> float:
	## Puddle depth 0..1 under a world pixel (0 off paths/asphalt and in dry weather).
	if world == null or world.wet < MIN_WET:
		return 0.0
	if not PuddleMath.capable(world.gen.tile_at(floori(at.x / 32.0), floori(at.y / 32.0))):
		return 0.0
	return PuddleMath.mask_at(at, world.wet)

func _on_step() -> void:
	if player.get("indoors"):
		return
	var feet := player.global_position + Vector2(0, 2)
	var n := PuddleMath.step_drops((player.get("velocity") as Vector2).length(), standing_water(feet))
	if n > 0:
		splash(feet, n)
		splashed.emit(0.35, 1.5)

func splash(at: Vector2, n: int) -> void:
	var drops: Array = []
	for i in n:
		var a := TAU * float(i) / n + randf() * 0.6
		drops.append({"v": Vector2(cos(a) * randf_range(14.0, 34.0), -randf_range(28.0, 62.0)), "side": sin(a) * 8.0})
	splashes.append({"pos": at, "age": 0.0, "drops": drops})
	if splashes.size() > 24:
		splashes.pop_front()

var _demo_done := false
var _demo_at := Vector2.INF

func _demo() -> void:
	## --puddle-demo: stand at the north edge of the widest nearby puddle (add --rain) and splash beside it.
	_demo_done = true
	var best := Vector2.INF
	var score := 0.0
	for dy in range(-6, 7):
		for dx in range(-10, 11):
			var at: Vector2 = player.global_position.snappedf(4.0) + Vector2(dx, dy) * 16.0
			var s := 0.0
			for ox in range(-2, 3):
				for oy in range(0, 6):
					s += standing_water(at + Vector2(ox * 8, 6 + oy * 7))
			if s > score:
				score = s
				best = at
	if best != Vector2.INF:
		player.global_position = best
		_demo_at = best + Vector2(26, 8)
	else:
		print("SCRIPT puddle demo found no water")

func _process(delta: float) -> void:
	if not _demo_done and "--puddle-demo" in OS.get_cmdline_user_args() and world != null and world.wet > 0.5:
		_demo()
	_t += delta
	if _demo_at != Vector2.INF and Engine.get_process_frames() % 3 == 0:
		splash(_demo_at, 10)
	for s in splashes:
		s["age"] = float(s["age"]) + delta
	splashes = splashes.filter(func(s): return float(s["age"]) < 0.45)
	var on: bool = world != null and world.wet >= MIN_WET and not player.get("indoors")
	if on:
		_scan_t -= delta
		if _scan_t <= 0.0:
			_scan_t = SCAN_EVERY
			sources.clear()
			lamps.clear()
			_gloss.clear()
			_scan(world, 0)
	else:
		sources.clear()
		lamps.clear()
		_scan_t = 0.0
	if on or not splashes.is_empty() or blocks_drawn > 0 or streak_blocks > 0:
		queue_redraw()   # also once after the water goes, so no stale mirror is left behind
		glow.queue_redraw()

func _scan(n: Node, depth: int) -> void:
	for c in n.get_children():
		if c == self or not (c is Node2D) or not (c as Node2D).visible:
			continue
		var cd := c as Node2D
		if cd is Sprite2D and _stands(cd as Sprite2D):
			sources.append(cd)
		elif cd is PointLight2D and _is_fixed_lamp(cd as PointLight2D):
			lamps.append(cd)
		if depth < 3:
			_scan(cd, depth + 1)

func _is_fixed_lamp(l: PointLight2D) -> bool:
	## Lamps on posts and house fronts (not headlights or the player): their parent's origin is their foot.
	var par := l.get_parent()
	if not (par is StaticBody2D or par is Lantern or l.is_in_group("night_lights")) or l.position.y > -8.0:
		return false
	var d := (l.global_position - player.global_position).abs()
	return d.x < REACH.x and d.y < REACH.y

func _gloss_at(cell: Vector2i) -> float:
	var g: float = _gloss.get(cell, -1.0)
	if g < 0.0:
		var at := Vector2(cell) * 2.0 + Vector2.ONE
		var tile: int = world.gen.tile_at(floori(at.x / 32.0), floori(at.y / 32.0))
		g = PuddleMath.gloss(tile, PuddleMath.mask_at(at, world.wet), world.wet)
		_gloss[cell] = g
	return g

func _draw_streaks() -> void:
	streak_blocks = 0
	if world == null or world.wet < MIN_WET or player.get("indoors"):
		return
	for node in lamps:
		if not is_instance_valid(node):
			continue
		var l := node as PointLight2D
		if not l.is_visible_in_tree() or l.energy <= 0.02:
			continue
		var post := l.texture_scale >= 1.4   # lamp posts throw wider, brighter streaks than windows
		var foot := (l.get_parent() as Node2D).global_position
		var height := maxf(foot.y - l.global_position.y, 8.0)
		var length := PuddleMath.streak_length(height)
		var k := clampf(l.energy / 0.9, 0.0, 1.0) * (1.0 if post else 0.85)
		var cx := l.global_position.x
		var phase := fposmod(cx * 0.131 + foot.y * 0.071, TAU)
		var half := 7.0 if post else 5.0
		var y := 2.0
		while y < length:
			var u := y / length
			var a := PuddleMath.streak_profile(u) * k
			var dash := PuddleMath.streak_dash(y, _t, phase)
			var w := roundf(half * (1.0 - 0.45 * u) * (0.55 + 0.6 * dash) * 0.5) * 2.0
			var x0 := floorf((cx - w + PuddleMath.streak_wobble(y, _t, phase)) / 2.0)
			var cy := floori((foot.y + y) / 2.0)
			for i in int(w):
				var cell := Vector2i(int(x0) + i, cy)
				var g := _gloss_at(cell)
				if g <= 0.0:
					continue
				var core := 1.0 - absf((i + 0.5) / w * 2.0 - 1.0)   # 0 at the sides, 1 in the middle
				# standing water holds an almost unbroken image; rough wet ground breaks it into dashes
				var broken := lerpf(dash * dash, 0.45 + 0.55 * dash, clampf(g * 1.6 - 0.6, 0.0, 1.0))
				var alpha := a * g * broken * (0.35 + 0.65 * core) * 1.25
				if alpha < 0.04:
					continue
				var col := Color(1.0, 0.52, 0.14).lerp(Color(1.0, 0.74, 0.36), core * dash)
				col.a = minf(alpha, 0.85)
				glow.draw_rect(Rect2(Vector2(cell) * 2.0, Vector2(2, 2)), col)
				streak_blocks += 1
			y += 2.0

func _stands(s: Sprite2D) -> bool:
	## Upright things only: tall enough, drawn above the ground layers, not already a mirror image.
	if s.texture == null or s.flip_v or s.z_index < 0 or s.modulate.a < 0.6 or not s.centered:
		return false
	var sz := _frame_rect(s).size
	if sz.y < 20.0 or sz.y > 110.0 or sz.x > 110.0:
		return false
	var d := (s.global_position - player.global_position).abs()
	return d.x < REACH.x and d.y < REACH.y

static func _frame_rect(s: Sprite2D) -> Rect2:
	var base := s.region_rect if s.region_enabled else Rect2(Vector2.ZERO, s.texture.get_size())
	var fs := Vector2(base.size.x / s.hframes, base.size.y / s.vframes)
	return Rect2(base.position + Vector2(s.frame_coords) * fs, fs)

func _draw() -> void:
	blocks_drawn = 0
	for s in sources:
		if is_instance_valid(s) and (s as Sprite2D).is_visible_in_tree():
			_mirror(s as Sprite2D)
	for sp in splashes:
		var a := float(sp["age"])
		var fade := 1.0 - a / 0.45
		var at: Vector2 = sp["pos"]
		draw_set_transform(at, 0.0, Vector2(1.0, 0.45))
		draw_arc(Vector2.ZERO, 3.0 + a * 34.0, 0.0, TAU, 18, Color(0.85, 0.93, 1.0, 0.85 * fade), 1.5)
		draw_set_transform(Vector2.ZERO)
		for d in sp["drops"]:
			var v: Vector2 = d["v"]
			var p := at + Vector2(v.x * a, v.y * a + 220.0 * a * a + float(d["side"]) * a)
			if p.y <= at.y + 6.0:
				draw_rect(Rect2(p.round(), Vector2(2, 2)), Color(0.86, 0.94, 1.0, 0.95 * fade))

func _mirror(s: Sprite2D) -> void:
	var fr := _frame_rect(s)
	var w := fr.size.x
	var h := fr.size.y
	var left := roundf(s.global_position.x + s.offset.x - w * 0.5)
	var base := roundf(s.global_position.y + s.offset.y + h * 0.5) - 3.0   # where it meets the ground
	var alpha := 0.55 * float(world.wet) * s.modulate.a
	var y := floorf(base / 4.0) * 4.0
	while y < base + h:
		var row := y - base                        # distance below the ground line = height up the sprite
		var wob := roundf(sin(_t * 3.0 + y * 0.35) * 1.0)
		var x := floorf(left / 4.0) * 4.0
		while x < left + w:
			# whole 4px block inside one puddle: draw it at once; on the outline: 2px pieces that follow the curve
			var c0 := standing_water(Vector2(x + 0.5, y + 0.5)) >= PuddleMath.SEEN
			var c1 := standing_water(Vector2(x + 3.5, y + 0.5)) >= PuddleMath.SEEN
			var c2 := standing_water(Vector2(x + 0.5, y + 3.5)) >= PuddleMath.SEEN
			var c3 := standing_water(Vector2(x + 3.5, y + 3.5)) >= PuddleMath.SEEN
			var size := 4.0 if c0 and c1 and c2 and c3 else 2.0
			if c0 or c1 or c2 or c3:
				var oy := 0.0
				while oy < 4.0:
					var ox := 0.0
					while ox < 4.0:
						var m := standing_water(Vector2(x + ox, y + oy) + Vector2.ONE * size * 0.5)
						if m >= PuddleMath.SEEN:
							var u := clampf(x + ox - left + wob, 0.0, w - size)
							if s.flip_h:
								u = w - size - u
							var v := clampf(h - 3.0 - size - row - oy, 0.0, h - size)
							var dest := Rect2(Vector2(x + ox, y + oy), Vector2(-size if s.flip_h else size, -size))   # negative size = mirrored
							draw_texture_rect_region(s.texture, dest, Rect2(fr.position + Vector2(u, v), Vector2(size, size)), Color(0.62, 0.74, 0.9, alpha * m * (1.0 - 0.5 * clampf(row / h, 0.0, 1.0))))
							blocks_drawn += 1
						ox += size
					oy += size
			x += 4.0
		y += 4.0
