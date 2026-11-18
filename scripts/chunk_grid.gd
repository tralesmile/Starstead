class_name ChunkGrid
extends RefCounted
## Pure chunk-grid math for the Earth map (docs/EARTH_MAP.md): 8x8 chunks of 64x64 cells.
## World cells are relative to the homestead chunk (3,4): its cells keep 0..63.

const GRID := 8
const CELLS := 64
const TILE := 32
const HOME := Vector2i(3, 4)

static func chunk_of_cell(c: Vector2i) -> Vector2i:
	return HOME + Vector2i(floori(float(c.x) / CELLS), floori(float(c.y) / CELLS))

static func chunk_of_pos(px: Vector2) -> Vector2i:
	return chunk_of_cell(Vector2i(floori(px.x / TILE), floori(px.y / TILE)))

static func origin_cell(ch: Vector2i) -> Vector2i:
	return (ch - HOME) * CELLS

static func local_cell(c: Vector2i) -> Vector2i:
	return Vector2i(posmod(c.x, CELLS), posmod(c.y, CELLS))

static func in_world(ch: Vector2i) -> bool:
	return ch.x >= 0 and ch.y >= 0 and ch.x < GRID and ch.y < GRID

static func world_rect_px() -> Rect2:
	var o := Vector2(origin_cell(Vector2i.ZERO)) * TILE
	return Rect2(o, Vector2(GRID * CELLS * TILE, GRID * CELLS * TILE))

static func window(center: Vector2i, radius: int = 1) -> Array[Vector2i]:
	## Chunks inside the world within `radius` of center (Chebyshev), nearest first.
	var out: Array[Vector2i] = []
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			var ch := center + Vector2i(dx, dy)
			if in_world(ch):
				out.append(ch)
	out.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		var da := (a - center).length_squared()
		var db := (b - center).length_squared()
		return da < db if da != db else (a.y * GRID + a.x) < (b.y * GRID + b.x))
	return out

static func to_load(loaded: Array, center: Vector2i, radius: int = 1) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for ch in window(center, radius):
		if not (ch in loaded):
			out.append(ch)
	return out

static func to_unload(loaded: Array, center: Vector2i, keep: int = 2) -> Array[Vector2i]:
	## Hysteresis: chunks are only dropped beyond `keep` so walking on a border does not thrash.
	var out: Array[Vector2i] = []
	for ch in loaded:
		if maxi(absi(ch.x - center.x), absi(ch.y - center.y)) > keep:
			out.append(ch)
	return out

static func region_of(ch: Vector2i, regions: Array) -> Dictionary:
	## First region (list order = priority) with a rect [x0,y0,x1,y1] covering the chunk; fallback is the wilds.
	for r in regions:
		for rect in r.get("rects", []):
			if ch.x >= int(rect[0]) and ch.x <= int(rect[2]) and ch.y >= int(rect[1]) and ch.y <= int(rect[3]):
				return r
	return {"id": "wilds", "name": "The Wilds", "biome": {}}

static func region_changed(prev_id: String, now_id: String) -> bool:
	return prev_id != "" and prev_id != now_id

static func banner_alpha(t: float, dur: float = 3.0) -> float:
	## Region name banner: quick fade in, hold, fade out. 0 outside [0, dur].
	if t < 0.0 or t > dur:
		return 0.0
	return clampf(minf(t / 0.4, (dur - t) / 0.8), 0.0, 1.0)
