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
var blocks_drawn := 0
var _scan_t := 0.0
var _t := 0.0

func setup(w: Node2D, p: Node2D) -> void:
	world = w
	player = p
	z_index = -2
	z_as_relative = false
	p.footstep.connect(_on_step)

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
			_scan(world, 0)
	else:
		sources.clear()
		_scan_t = 0.0
	if on or not splashes.is_empty() or blocks_drawn > 0:
		queue_redraw()   # also once after the water goes, so no stale mirror is left behind

func _scan(n: Node, depth: int) -> void:
	for c in n.get_children():
		if c == self or not (c is Node2D) or not (c as Node2D).visible:
			continue
		var cd := c as Node2D
		if cd is Sprite2D and _stands(cd as Sprite2D):
			sources.append(cd)
		if depth < 3:
			_scan(cd, depth + 1)

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
			var m := standing_water(Vector2(x + 2.0, y + 2.0))
			if m >= PuddleMath.SEEN:
				var u := clampf(x - left + wob, 0.0, w - 4.0)
				if s.flip_h:
					u = w - 4.0 - u
				var v := clampf(h - 7.0 - row, 0.0, h - 4.0)
				var dest := Rect2(Vector2(x, y), Vector2(-4.0 if s.flip_h else 4.0, -4.0))
				draw_texture_rect_region(s.texture, dest, Rect2(fr.position + Vector2(u, v), Vector2(4, 4)), Color(0.62, 0.74, 0.9, alpha * m * (1.0 - 0.5 * clampf(row / h, 0.0, 1.0))))
				blocks_drawn += 1
			x += 4.0
		y += 4.0
