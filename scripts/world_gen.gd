class_name WorldGen
extends RefCounted
## Deterministic 64x64 chunk generator. Tile ids = column in assets/tiles/atlas.png.

const SIZE := 64
const GRASS := 0   # 0-2 variants
const DIRT := 3    # 3-5
const PATH := 6    # 6-8
const WATER_SHALLOW := 9
const WATER_DEEP := 10

const HOME := Vector2i(3, 4)   # chunk coordinates of the homestead (cells 0..63 = world cells)
const PAD := 8                 # sdf padding so shores match across chunk edges

var seed_value: int
var chunk := HOME
var tree_mul := 1.0
var rock_mul := 1.0
var _stream_w: WeakRef = null  # weak: ChunkStream owns the gens (a strong ref would be a leak cycle)
var stream_ref:
	get: return _stream_w.get_ref() if _stream_w != null else null
	set(v): _stream_w = weakref(v) if v != null else null
var grid:
	get: return _stream_w.get_ref() if _stream_w != null else null
	set(v): _stream_w = weakref(v) if v != null else null

var _ox := 0                   # noise offset in cells (chunk - HOME) * SIZE
var _oy := 0
var tiles := PackedInt32Array()
var trees: Array[Vector2i] = []
var rocks: Array[Vector2i] = []
var tree_kinds: Dictionary = {}   # cell -> "pine" | "oak"
var bushes: Array[Vector2i] = []
var lilies: Array[Vector2i] = []
var reeds: Array[Vector2i] = []
var tufts: Array[Vector2i] = []   # grass tuft cells (separate RNG so the layout above never shifts)
var dock: Array[Vector2i] = []    # walkable dock cells over water, nearest the spawn
var sdf := PackedFloat32Array()   # signed distance to shore in tiles (water < 0)

func _init(s: int = 1, ch: Vector2i = HOME, biome: Dictionary = {}) -> void:
	seed_value = s
	chunk = ch
	_ox = (ch.x - HOME.x) * SIZE
	_oy = (ch.y - HOME.y) * SIZE
	tree_mul = float(biome.get("trees", 1.0))
	rock_mul = float(biome.get("rocks", 1.0))
	generate()

func is_home() -> bool:
	return chunk == HOME

func _water_noise(wx: int, wy: int) -> bool:
	## Global water mask outside this chunk (same noise as generate(), cells relative to the homestead).
	var ch := Vector2i(HOME.x + floori(float(wx) / SIZE), HOME.y + floori(float(wy) / SIZE))
	if ch.x < 0 or ch.y < 0 or ch.x >= 8 or ch.y >= 8:
		return true  # beyond the world edge is sea
	return _n.get_noise_2d(wx, wy) < -0.14

var _n: FastNoiseLite

func generate() -> void:
	var n := FastNoiseLite.new()
	n.seed = seed_value
	n.frequency = 0.035
	_n = n
	var n2 := FastNoiseLite.new()
	n2.seed = seed_value + 99
	n2.frequency = 0.12
	var r := RandomNumberGenerator.new()
	r.seed = seed_value if is_home() else seed_value + chunk.x * 7919 + chunk.y * 104729
	tiles.resize(SIZE * SIZE)
	trees.clear()
	rocks.clear()
	bushes.clear()
	lilies.clear()
	reeds.clear()
	tufts.clear()
	tree_kinds.clear()
	var forest := FastNoiseLite.new()
	forest.seed = seed_value + 31
	forest.frequency = 0.06
	for y in SIZE:
		for x in SIZE:
			var v := n.get_noise_2d(x + _ox, y + _oy)
			var t := GRASS + r.randi() % 3
			if v < -0.3:
				t = WATER_DEEP
			elif v < -0.14:
				t = WATER_SHALLOW
			elif n2.get_noise_2d(x + _ox, y + _oy) > 0.55:
				t = DIRT + r.randi() % 3
			tiles[y * SIZE + x] = t
	# a path crossing the chunk row through the spawn area (continues east and west)
	if chunk.y == HOME.y:
		for x in SIZE:
			var y := 32 + int(round(sin((x + _ox) * 0.2) * 3.0))
			for dy in 2:
				if not is_water(tiles[(y + dy) * SIZE + x]):
					tiles[(y + dy) * SIZE + x] = PATH + r.randi() % 3
	# keep spawn (32,32) dry
	if is_home():
		for y in range(28, 37):
			for x in range(28, 37):
				if is_water(tiles[y * SIZE + x]):
					tiles[y * SIZE + x] = GRASS
	for y in SIZE:
		for x in SIZE:
			var t := tiles[y * SIZE + x]
			if t <= 2 and (not is_home() or absi(x - 32) + absi(y - 32) > 6):
				var roll := r.randf()
				var dens := (0.015 + 0.3 * maxf(0.0, forest.get_noise_2d(x + _ox, y + _oy))) * tree_mul
				var rd := 0.012 * rock_mul
				if roll < dens:
					trees.append(Vector2i(x, y))
				elif roll < dens + rd:
					rocks.append(Vector2i(x, y))
				elif roll < dens + rd + 0.023:
					bushes.append(Vector2i(x, y))
	var kn := FastNoiseLite.new()
	kn.seed = seed_value + 7
	kn.frequency = 0.08
	for t in trees:
		tree_kinds[t] = "pine" if kn.get_noise_2d(t.x + _ox, t.y + _oy) > -0.05 else "oak"
	compute_sdf()
	if is_home():
		_place_dock()
	for y in SIZE:
		for x in SIZE:
			var c := Vector2i(x, y)
			if not is_water(tiles[y * SIZE + x]) or c in dock:
				continue
			var d := -sdf[y * SIZE + x]
			var roll2 := r.randf()
			if d < 1.0 and roll2 < 0.18:
				reeds.append(c)
			elif d >= 1.0 and d < 3.5 and roll2 < 0.12:
				lilies.append(c)
	var tr := RandomNumberGenerator.new()
	tr.seed = seed_value + 211
	for y in SIZE:
		for x in SIZE:
			var c := Vector2i(x, y)
			var roll := tr.randf()
			if roll < 0.07 and tiles[y * SIZE + x] <= 2 and not (c in trees) and not (c in rocks) and not (c in bushes):
				tufts.append(c)

static func is_water(t: int) -> bool:
	return t == WATER_SHALLOW or t == WATER_DEEP

func tile_at(x: int, y: int) -> int:
	if x < 0 or y < 0 or x >= SIZE or y >= SIZE:
		if grid != null:
			return grid.tile_at(Vector2i(x, y))
		return WATER_DEEP
	return tiles[y * SIZE + x]

func compute_sdf() -> void:
	## Chamfer distance transform on a padded grid (neighbour terrain from the global noise) so shores line up across chunks.
	var big := 1e6
	var P := SIZE + 2 * PAD
	var dw := PackedFloat32Array()  # land cell: distance to nearest water
	var dl := PackedFloat32Array()  # water cell: distance to nearest land
	dw.resize(P * P)
	dl.resize(P * P)
	for y in P:
		for x in P:
			var lx := x - PAD
			var ly := y - PAD
			var w: bool
			if lx >= 0 and ly >= 0 and lx < SIZE and ly < SIZE:
				w = is_water(tiles[ly * SIZE + lx])
			else:
				w = _water_noise(lx + _ox, ly + _oy)
			dw[y * P + x] = 0.0 if w else big
			dl[y * P + x] = big if w else 0.0
	_chamfer(dw, P)
	_chamfer(dl, P)
	sdf.resize(SIZE * SIZE)
	for y in SIZE:
		for x in SIZE:
			var i := (y + PAD) * P + x + PAD
			var v := -(dl[i] - 0.5) if is_water(tiles[y * SIZE + x]) else dw[i] - 0.5
			sdf[y * SIZE + x] = clampf(v, -8.0, 8.0)

func _chamfer(a: PackedFloat32Array, n: int) -> void:
	var d2 := 1.4142
	for y in n:
		for x in n:
			var i := y * n + x
			var v := a[i]
			if x > 0: v = minf(v, a[i - 1] + 1.0)
			if y > 0: v = minf(v, a[i - n] + 1.0)
			if x > 0 and y > 0: v = minf(v, a[i - n - 1] + d2)
			if x < n - 1 and y > 0: v = minf(v, a[i - n + 1] + d2)
			a[i] = v
	for y in range(n - 1, -1, -1):
		for x in range(n - 1, -1, -1):
			var i := y * n + x
			var v := a[i]
			if x < n - 1: v = minf(v, a[i + 1] + 1.0)
			if y < n - 1: v = minf(v, a[i + n] + 1.0)
			if x < n - 1 and y < n - 1: v = minf(v, a[i + n + 1] + d2)
			if x > 0 and y < n - 1: v = minf(v, a[i + n - 1] + d2)
			a[i] = v

func _place_dock() -> void:
	## Dock: from the land tile nearest spawn that borders water, 3 tiles out over the water.
	dock.clear()
	var best := Vector2i(-1, -1)
	var best_d := 1e9
	var dirs := [Vector2i(1, 0), Vector2i(-1, 0)]  # dock sprite is horizontal
	var best_dir := Vector2i.ZERO
	for y in range(2, SIZE - 2):
		for x in range(2, SIZE - 2):
			if is_water(tile_at(x, y)):
				continue
			for dv in dirs:
				var ok := true
				for k in range(1, 4):
					if not is_water(tile_at(x + dv.x * k, y + dv.y * k)):
						ok = false
				var dd := Vector2(x - 32, y - 32).length()
				if ok and dd < best_d:
					best_d = dd
					best = Vector2i(x, y)
					best_dir = dv
	if best.x < 0:
		return
	for k in range(1, 4):
		dock.append(best + best_dir * k)

func sdf_at(x: int, y: int) -> float:
	if x < 0 or y < 0 or x >= SIZE or y >= SIZE:
		if grid != null:
			return grid.sdf_at(Vector2i(x, y))
		return -8.0
	return sdf[y * SIZE + x]
