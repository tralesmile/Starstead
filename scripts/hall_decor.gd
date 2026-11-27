class_name HallDecor
extends Node2D
## Set dressing for the Warden's Hall: carved rune dais, broken pillars, braziers, wall banners and stone faces,
## rubble, bones and old mining gear. layout() is pure (tested); the node only draws it.
## Everything flat sits under z -10, where BossView draws its warning rings and rock shadows.
## Standing props hug the walls and are y-sorted with the player.

const DAIS_CELL := Vector2i(CaveModel.W / 2, 12)
const DAIS_RADIUS := Vector2(144, 112)     # px, matches hall_rune.png
const DAIS_Z := -16
const LITTER_Z := -15
const WALL_Z := -16
const SOLID_REACH := 4.5                   # cells a prop may slide from its wished-for spot
const SOLID_GAP := 2.2
## [angle in degrees on the hall ellipse (-90 = north), kind, frame]
const SOLID_WISHES := [
	[-104.0, "brazier", 0], [-76.0, "brazier", 0],
	[-122.0, "pillar", 0], [-58.0, "pillar", 0],
	[-142.0, "pillar", 1], [-38.0, "pillar", 0],
	[-158.0, "brazier", 0], [-22.0, "brazier", 0],
	[178.0, "pillar", 0], [2.0, "pillar", 1],
	[154.0, "pillar", 2], [26.0, "pillar", 2],
	[130.0, "brazier", 0], [50.0, "brazier", 0],
	[112.0, "pillar", 1], [68.0, "pillar", 1],
]
const WALL_FRAMES := [0, 2, 1, 2]          # red banner, face, blue banner, face
const LITTER_RUBBLE := [0, 1]
const LITTER_RELICS := [2, 3, 4, 5, 6]
const LITTER_CRACKS := [7, 8]
const SIDES: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

var boss_cb: Callable                      # () -> BossView or null
var glow: Sprite2D
var glow_light: PointLight2D
var glow_now := 0.0
var flames: Array = []                     # {sprite, light, phase}
var t := 0.0

## --- pure layout ---
static func dais_center() -> Vector2:
	## Local px (add the cave origin).
	return Vector2(DAIS_CELL) * 32.0 + Vector2(16, 16)

static func on_dais(c: Vector2i, grow: float = 1.0) -> bool:
	return ((Vector2(c) * 32.0 + Vector2(16, 16) - dais_center()) / (DAIS_RADIUS * grow)).length() <= 1.0

static func keep_clear(m: CaveModel, c: Vector2i) -> bool:
	## The way in and out, the spawns and the cart track stay bare.
	if c == m.entrance or c == m.entrance + Vector2i(0, 1) or c == m.boss_spawn() or m.rail.has(c):
		return true
	return c.y >= m.entrance.y - 1

static func reachable(m: CaveModel, blocked: Dictionary) -> bool:
	## Every free floor cell is still reachable from the entrance, and no ore loses its last open side.
	var seen := {m.entrance: true}
	var q: Array[Vector2i] = [m.entrance]
	var free := 0
	for c in m.floor_cells:
		if not m.ores.has(c) and not blocked.has(c):
			free += 1
	while not q.is_empty():
		var c: Vector2i = q.pop_back()
		for o in SIDES:
			var n: Vector2i = c + o
			if m.floor_cells.has(n) and not m.ores.has(n) and not blocked.has(n) and not seen.has(n):
				seen[n] = true
				q.append(n)
	if seen.size() != free:
		return false
	for ore in m.ores:
		var had := false
		var has := false
		for o in SIDES:
			var n: Vector2i = ore + o
			if m.floor_cells.has(n) and not m.ores.has(n):
				had = true
				has = has or not blocked.has(n)
		if had and not has:
			return false
	return true

static func _wall_beside(m: CaveModel, c: Vector2i) -> bool:
	for o in SIDES:
		if not m.is_floor(c + o):
			return true
	return false

static func _fits_solid(m: CaveModel, c: Vector2i, kind: String, frame: int, blocked: Dictionary) -> bool:
	if not m.is_floor(c) or m.ores.has(c) or blocked.has(c) or keep_clear(m, c) or not _wall_beside(m, c):
		return false
	if Vector2(c - m.boss_spawn()).length() < 3.0 or Vector2(c - m.entrance).length() < 6.0:
		return false
	# the corridor mouth stays wide open
	if absi(c.x - m.entrance.x) <= 3 and c.y > CaveModel.HALL_CENTRE.y + 4:
		return false
	# a tall shaft stands against the north wall, so it rises over rock and not over the floor
	if kind == "pillar" and frame == 0 and m.is_floor(c + Vector2i(0, -1)):
		return false
	if m.torches.has(c + Vector2i(0, -1)) or m.torches.has(c + Vector2i(0, -2)):
		return false
	for other in blocked:
		if Vector2(c - other).length() < SOLID_GAP:
			return false
	return true

static func _solids(m: CaveModel) -> Array:
	var out: Array = []
	var blocked := {}
	var cells: Array = m.floor_cells.keys()
	cells.sort()
	for wish in SOLID_WISHES:
		var a := deg_to_rad(float(wish[0]))
		var want := Vector2(CaveModel.HALL_CENTRE) + Vector2(cos(a), sin(a)) * CaveModel.HALL_RADIUS
		var near: Array = cells.filter(func(c): return Vector2(c).distance_to(want) <= SOLID_REACH)
		near.sort_custom(func(x, y):
			var dx := Vector2(x).distance_squared_to(want)
			var dy := Vector2(y).distance_squared_to(want)
			return dx < dy if not is_equal_approx(dx, dy) else x < y)
		for c in near:
			if not _fits_solid(m, c, wish[1], wish[2], blocked):
				continue
			blocked[c] = true
			if reachable(m, blocked):
				out.append({"kind": wish[1], "frame": wish[2], "cell": c, "solid": true, "off": Vector2.ZERO, "flip": want.x > CaveModel.HALL_CENTRE.x})
				break
			blocked.erase(c)
	return out

static func _walls(m: CaveModel, solids: Array) -> Array:
	## Banners and carved faces on the rock faces of the upper hall, between the torches.
	var under := {}
	for s in solids:
		under[(s["cell"] as Vector2i) + Vector2i(0, -1)] = true
	var cand: Array[Vector2i] = []
	for c in m.floor_cells:
		var w: Vector2i = c + Vector2i(0, -1)
		if not m.is_floor(w) and w.y <= CaveModel.HALL_CENTRE.y and not under.has(w):
			cand.append(w)
	cand.sort()
	var out: Array = []
	for w in cand:
		var ok := true
		for tc in m.torches:
			if Vector2(w - tc).length() < 1.5:
				ok = false
		for other in out:
			if Vector2(w - (other["cell"] as Vector2i)).length() < 2.5:
				ok = false
		if ok:
			out.append({"kind": "wall", "frame": WALL_FRAMES[out.size() % WALL_FRAMES.size()], "cell": w, "solid": false, "off": Vector2.ZERO, "flip": false})
	return out

static func _scatter(m: CaveModel, r: RandomNumberGenerator, cand: Array, want: int, frames: Array, gap: float, taken: Dictionary, out: Array) -> void:
	var pool := cand.duplicate()
	var placed := 0
	while placed < want and not pool.is_empty():
		var i := r.randi_range(0, pool.size() - 1)
		var c: Vector2i = pool[i]
		pool.remove_at(i)
		if m.ores.has(c) or keep_clear(m, c):
			continue
		var crowded := false
		for other in taken:
			if Vector2(c - other).length() < gap:
				crowded = true
				break
		if crowded:
			continue
		taken[c] = true
		var frame: int = frames[placed % frames.size()]
		out.append({"kind": "litter", "frame": frame, "cell": c, "solid": false,
			"off": Vector2(r.randi_range(-5, 5), r.randi_range(-4, 4)), "flip": r.randf() < 0.5})
		placed += 1

static func layout(m: CaveModel) -> Array:
	## Items {kind: pillar|brazier|wall|litter, frame, cell, solid, off, flip}. Same model, same hall.
	if not m.is_boss_floor():
		return []
	var out := _solids(m)
	var taken := {}
	for s in out:
		taken[s["cell"]] = true
	out.append_array(_walls(m, out))
	var cells: Array = m.floor_cells.keys()
	cells.sort()
	var edge: Array = cells.filter(func(c): return _wall_beside(m, c))
	var ring: Array = cells.filter(func(c): return not _wall_beside(m, c) and not on_dais(c, 1.05) and on_dais(c, 1.75))
	var outer: Array = cells.filter(func(c): return not _wall_beside(m, c) and not on_dais(c, 1.75))
	var worn: Array = cells.filter(func(c): return on_dais(c, 0.95) and not on_dais(c, 0.4))
	var r := RandomNumberGenerator.new()
	r.seed = 6061
	_scatter(m, r, edge, 22, [0, 1, 0, 1, 2, 0, 6, 1], 2.0, taken, out)
	_scatter(m, r, ring, 14, [4, 1, 2, 7, 5, 1, 3, 8, 6, 1, 7, 2, 1, 8], 2.2, taken, out)
	_scatter(m, r, outer, 12, [3, 7, 1, 2, 8, 1, 5, 7, 1, 2, 8, 0], 2.5, taken, out)
	_scatter(m, r, worn, 5, [7, 8, 1, 7, 2], 2.5, taken, out)
	return out

## Brightness of the rune light: faint while the hall sleeps, steady in the fight, blazing and pulsing in rage.
static func glow_level(state: String, enraged: bool, time: float) -> float:
	if state == "" or state == "dead" or state == "sleep":
		return 0.12 + 0.03 * sin(time * 1.3)
	if enraged:
		return 0.48 + 0.14 * sin(time * 5.0)
	return 0.24 + 0.04 * sin(time * 2.2)

## --- the node ---
func setup(m: CaveModel, origin: Vector2, boss_getter: Callable) -> HallDecor:
	boss_cb = boss_getter
	y_sort_enabled = true
	_make_dais(origin)
	for item in layout(m):
		var at := origin + Vector2(item["cell"]) * 32.0
		match String(item["kind"]):
			"wall":
				_flat("hall_wall", 3, item["frame"], at + Vector2(16, 21), WALL_Z, false)
			"litter":
				var s := _flat("hall_litter", 9, item["frame"], at + Vector2(16, 12) + (item["off"] as Vector2), LITTER_Z, item["flip"])
				s.modulate = Color(0.9, 0.9, 0.92)
			"pillar":
				_standing("hall_pillar", 3, item["frame"], at + Vector2(16, 27), -27.0, item["flip"])
			"brazier":
				var s := _standing("hall_brazier", 4, 0, at + Vector2(16, 27), -20.0, false)
				var l := _light(at + Vector2(16, 18), Color(1.0, 0.6, 0.28), 2.2, 0.6)
				flames.append({"sprite": s, "light": l, "phase": float(item["cell"].x) * 0.7})
	return self

func _tex(name: String) -> Texture2D:
	return load("res://assets/sprites/%s.png" % name)

func _flat(name: String, frames: int, frame: int, at: Vector2, z: int, flip: bool) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = _tex(name)
	s.hframes = frames
	s.frame = frame
	s.flip_h = flip
	s.position = at
	s.z_index = z
	add_child(s)
	return s

func _standing(name: String, frames: int, frame: int, base: Vector2, lift: float, flip: bool) -> Sprite2D:
	## y-sorted by its foot, with a collider that fills the cell down to the foot (no slot behind it to wedge into).
	var s := _flat(name, frames, frame, base, 0, flip)
	s.offset = Vector2(0, lift)
	var body := StaticBody2D.new()
	body.position = base
	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(26, 28)
	cs.shape = rs
	cs.position = Vector2(0, -13)
	body.add_child(cs)
	add_child(body)
	return s

func _light(at: Vector2, col: Color, size: float, energy: float) -> PointLight2D:
	var l := PointLight2D.new()
	l.texture = Lantern.light_texture()
	l.texture_scale = size
	l.color = col
	l.energy = energy
	l.position = at
	add_child(l)
	return l

func _make_dais(origin: Vector2) -> void:
	var at := origin + dais_center()
	_flat("hall_rune", 1, 0, at, DAIS_Z, false)
	glow = _flat("hall_rune_glow", 1, 0, at, DAIS_Z, false)
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	glow.material = mat
	glow_now = glow_level("", false, 0.0)
	glow.modulate = Color(1, 1, 1, glow_now)
	glow_light = _light(at, Color(0.35, 0.9, 0.95), 2.4, glow_now * 0.45)

func _process(d: float) -> void:
	t += d
	var state := ""
	var enraged := false
	var boss: Object = boss_cb.call() if boss_cb.is_valid() else null   # a BossView (untyped: it needs autoloads, tests do not)
	if boss != null and is_instance_valid(boss):
		state = boss.model.state
		enraged = boss.model.enraged
	glow_now = lerpf(glow_now, glow_level(state, enraged, t), minf(1.0, d * 5.0))
	glow.modulate.a = glow_now
	glow_light.energy = glow_now * 0.45
	for f in flames:
		var ph: float = f["phase"]
		(f["sprite"] as Sprite2D).frame = int(t * 9.0 + ph) % 4
		(f["light"] as PointLight2D).energy = 0.6 + 0.06 * sin(t * 11.0 + ph) + 0.03 * sin(t * 27.0 + ph * 2.0)
