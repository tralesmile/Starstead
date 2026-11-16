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

func _init(s: int = 1) -> void:
	seed_value = s
	generate()

func generate() -> void:
	var n := FastNoiseLite.new()
	n.seed = seed_value
	n.frequency = 0.05
	var n2 := FastNoiseLite.new()
	n2.seed = seed_value + 99
	n2.frequency = 0.12
	var r := RandomNumberGenerator.new()
	r.seed = seed_value
	tiles.resize(SIZE * SIZE)
	trees.clear()
	rocks.clear()
	for y in SIZE:
		for x in SIZE:
			var v := n.get_noise_2d(x, y)
			var t := GRASS + r.randi() % 3
			if v < -0.32:
				t = WATER_DEEP
			elif v < -0.2:
				t = WATER_SHALLOW
			elif n2.get_noise_2d(x, y) > 0.45:
				t = DIRT + r.randi() % 3
			tiles[y * SIZE + x] = t
	# a path crossing the chunk through the spawn area
	for x in SIZE:
		var y := 32 + int(round(sin(x * 0.2) * 3.0))
		for dy in 2:
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
				if roll < 0.04:
					trees.append(Vector2i(x, y))
				elif roll < 0.055:
					rocks.append(Vector2i(x, y))

static func is_water(t: int) -> bool:
	return t == WATER_SHALLOW or t == WATER_DEEP

func tile_at(x: int, y: int) -> int:
	if x < 0 or y < 0 or x >= SIZE or y >= SIZE:
		return WATER_DEEP
	return tiles[y * SIZE + x]
