class_name WorldGen
extends RefCounted
## Deterministic 64x64 chunk generator. Tile ids = column in assets/tiles/atlas.png.

const SIZE := 64
const GRASS := 0   # 0-2 variants
const DIRT := 3    # 3-5
const PATH := 6    # 6-8
const WATER_SHALLOW := 9
const WATER_DEEP := 10

var seed_value: int
var tiles := PackedInt32Array()
var trees: Array[Vector2i] = []
var rocks: Array[Vector2i] = []
var tree_kinds: Dictionary = {}   # cell -> "pine" | "oak"
var bushes: Array[Vector2i] = []
var lilies: Array[Vector2i] = []
var reeds: Array[Vector2i] = []
var dock: Array[Vector2i] = []    # walkable dock cells over water, nearest the spawn
var sdf := PackedFloat32Array()   # signed distance to shore in tiles (water < 0)

func _init(s: int = 1) -> void:
	seed_value = s
	generate()

func generate() -> void:
	var n := FastNoiseLite.new()
	n.seed = seed_value
	n.frequency = 0.035
	var n2 := FastNoiseLite.new()
	n2.seed = seed_value + 99
	n2.frequency = 0.12
	var r := RandomNumberGenerator.new()
	r.seed = seed_value
	tiles.resize(SIZE * SIZE)
	trees.clear()
	rocks.clear()
	bushes.clear()
	lilies.clear()
	reeds.clear()
	tree_kinds.clear()
	var forest := FastNoiseLite.new()
	forest.seed = seed_value + 31
	forest.frequency = 0.06
	for y in SIZE:
		for x in SIZE:
			var v := n.get_noise_2d(x, y)
			var t := GRASS + r.randi() % 3
			if v < -0.3:
				t = WATER_DEEP
			elif v < -0.14:
				t = WATER_SHALLOW
			elif n2.get_noise_2d(x, y) > 0.55:
				t = DIRT + r.randi() % 3
			tiles[y * SIZE + x] = t
	# a path crossing the chunk through the spawn area
	for x in SIZE:
		var y := 32 + int(round(sin(x * 0.2) * 3.0))
		for dy in 2:
			if not is_water(tiles[(y + dy) * SIZE + x]):
				tiles[(y + dy) * SIZE + x] = PATH + r.randi() % 3
	# keep spawn (32,32) dry
	for y in range(28, 37):
		for x in range(28, 37):
			if is_water(tiles[y * SIZE + x]):
				tiles[y * SIZE + x] = GRASS
	for y in SIZE:
		for x in SIZE:
			var t := tiles[y * SIZE + x]
			if t <= 2 and absi(x - 32) + absi(y - 32) > 6:
				var roll := r.randf()
				var dens := 0.015 + 0.3 * maxf(0.0, forest.get_noise_2d(x, y))
				if roll < dens:
					trees.append(Vector2i(x, y))
				elif roll < dens + 0.012:
					rocks.append(Vector2i(x, y))
				elif roll < dens + 0.035:
					bushes.append(Vector2i(x, y))
	var kn := FastNoiseLite.new()
	kn.seed = seed_value + 7
	kn.frequency = 0.08
	for t in trees:
		tree_kinds[t] = "pine" if kn.get_noise_2d(t.x, t.y) > -0.05 else "oak"
	compute_sdf()
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

static func is_water(t: int) -> bool:
	return t == WATER_SHALLOW or t == WATER_DEEP

func tile_at(x: int, y: int) -> int:
	if x < 0 or y < 0 or x >= SIZE or y >= SIZE:
		return WATER_DEEP
	return tiles[y * SIZE + x]

func compute_sdf() -> void:
	## Two-pass chamfer distance transform to the other terrain class (water vs land).
	var big := 1e6
	var dw := PackedFloat32Array()  # land cell: distance to nearest water
	var dl := PackedFloat32Array()  # water cell: distance to nearest land
	dw.resize(SIZE * SIZE)
	dl.resize(SIZE * SIZE)
	for i in SIZE * SIZE:
		var w := is_water(tiles[i])
		dw[i] = 0.0 if w else big
		dl[i] = big if w else 0.0
	for arr in [dw, dl]:
		_chamfer(arr)
	sdf.resize(SIZE * SIZE)
	for i in SIZE * SIZE:
		sdf[i] = -(dl[i] - 0.5) if is_water(tiles[i]) else dw[i] - 0.5
		sdf[i] = clampf(sdf[i], -8.0, 8.0)

func _chamfer(a: PackedFloat32Array) -> void:
	var d2 := 1.4142
	for y in SIZE:
		for x in SIZE:
			var i := y * SIZE + x
			var v := a[i]
			if x > 0: v = minf(v, a[i - 1] + 1.0)
			if y > 0: v = minf(v, a[i - SIZE] + 1.0)
			if x > 0 and y > 0: v = minf(v, a[i - SIZE - 1] + d2)
			if x < SIZE - 1 and y > 0: v = minf(v, a[i - SIZE + 1] + d2)
			a[i] = v
	for y in range(SIZE - 1, -1, -1):
		for x in range(SIZE - 1, -1, -1):
			var i := y * SIZE + x
			var v := a[i]
			if x < SIZE - 1: v = minf(v, a[i + 1] + 1.0)
			if y < SIZE - 1: v = minf(v, a[i + SIZE] + 1.0)
			if x < SIZE - 1 and y < SIZE - 1: v = minf(v, a[i + SIZE + 1] + d2)
			if x > 0 and y < SIZE - 1: v = minf(v, a[i + SIZE - 1] + d2)
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
		return -8.0
	return sdf[y * SIZE + x]
