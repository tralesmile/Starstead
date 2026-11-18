class_name ChunkStream
extends RefCounted
## Holds the generated chunks (cached WorldGen per chunk) and answers terrain queries in world cells,
## so the player, footprints and the home chunk can look past their own 64x64 chunk.

var seed_value := 1
var regions: Array = []
var gens: Dictionary = {}   # chunk -> WorldGen

func _init(s: int = 1, home: WorldGen = null) -> void:
	seed_value = s
	var f := FileAccess.open("res://data/regions.json", FileAccess.READ)
	if f != null:
		var parsed = JSON.parse_string(f.get_as_text())
		if parsed is Array:
			regions = parsed
	if home != null:
		gens[ChunkGrid.HOME] = home
		home.grid = self

func region_at(ch: Vector2i) -> Dictionary:
	return ChunkGrid.region_of(ch, regions)

func gen_for(ch: Vector2i) -> WorldGen:
	if not ChunkGrid.in_world(ch):
		return null
	if not gens.has(ch):
		gens[ch] = WorldGen.new(seed_value, ch, region_at(ch).get("biome", {}))
	return gens[ch]

func tile_at(cell: Vector2i) -> int:
	var g := gen_for(ChunkGrid.chunk_of_cell(cell))
	if g == null:
		return WorldGen.WATER_DEEP
	var l := ChunkGrid.local_cell(cell)
	return g.tile_at(l.x, l.y)

func sdf_at(cell: Vector2i) -> float:
	var g := gen_for(ChunkGrid.chunk_of_cell(cell))
	if g == null:
		return -8.0
	var l := ChunkGrid.local_cell(cell)
	return g.sdf_at(l.x, l.y)
