class_name RegionWildlife
extends RefCounted
## Wild animals that live in each streamed region (data/wildlife.json) and fish shadows per water chunk. Pure.

const KEEP_CHUNKS := 2        # wild animals farther than this many chunks from the player are dropped
const MAX_WILD_OUTSIDE := 24  # cap on streamed wildlife alive at once
const FISH_PER_CHUNK := 6
const FISH_MIN_WATER := 40    # a chunk needs this many deep-water cells for any fish

static func wanted(table: Dictionary, region_id: String) -> Dictionary:
	## id -> count the region keeps per chunk (empty when unknown).
	var t = table.get(region_id, {})
	return t if t is Dictionary else {}

static func fish_count(deep_cells: int) -> int:
	if deep_cells < FISH_MIN_WATER:
		return 0
	return mini(FISH_PER_CHUNK, 1 + deep_cells / 120)

static func should_keep(dist_px: float, chunk_px: float) -> bool:
	return dist_px <= chunk_px * (KEEP_CHUNKS + 0.5)

static func chunk_seed(world_seed: int, ch: Vector2i, day: int) -> int:
	## Different herd positions each day, stable inside a day.
	return world_seed * 7919 + ch.x * 131 + ch.y * 977 + day * 31

static func room(alive: int, want: int) -> int:
	return clampi(want, 0, maxi(0, MAX_WILD_OUTSIDE - alive))
