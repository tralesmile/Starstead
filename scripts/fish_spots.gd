class_name FishSpots
extends RefCounted
## Daily fishing hotspots: the sea and lakes are split into BLOCK x BLOCK cell blocks and about one in HOT_ONE is
## "bubbling" on a given day (deterministic). A cast into a hot block bites much sooner. Pure.

const BLOCK := 5
const HOT_ONE := 7
const BITE_MULT := 0.55
const RADIUS_CELLS := 9   # ripples are drawn this far around the player while you hold a rod

static func block_of(cell: Vector2i) -> Vector2i:
	return Vector2i(floori(float(cell.x) / BLOCK), floori(float(cell.y) / BLOCK))

static func is_hot(cell: Vector2i, day: int) -> bool:
	var b := block_of(cell)
	var h := absi((b.x * 73856093) ^ (b.y * 19349663) ^ (day * 83492791))
	return h % HOT_ONE == 0

static func block_center(cell: Vector2i) -> Vector2:
	var b := block_of(cell)
	return (Vector2(b) * BLOCK + Vector2(BLOCK, BLOCK) * 0.5) * 32.0

static func hot_blocks_near(cell: Vector2i, day: int) -> Array[Vector2i]:
	## Hot blocks within RADIUS_CELLS of a cell (block coordinates).
	var out: Array[Vector2i] = []
	var lo := block_of(cell - Vector2i(RADIUS_CELLS, RADIUS_CELLS))
	var hi := block_of(cell + Vector2i(RADIUS_CELLS, RADIUS_CELLS))
	for by in range(lo.y, hi.y + 1):
		for bx in range(lo.x, hi.x + 1):
			if is_hot(Vector2i(bx * BLOCK, by * BLOCK), day):
				out.append(Vector2i(bx, by))
	return out
