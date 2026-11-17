class_name CastMath
extends RefCounted
## Hold-to-cast fishing: the power bar ping-pongs while the button is held; release throws the bobber
## 2-7 tiles out. Farther water is deeper, so it holds rarer fish.

const PERIOD := 1.2   # seconds for the bar to go up and down once
const MIN_TILES := 2
const MAX_TILES := 7

static func power(t: float) -> float:
	return clampf(1.0 - absf(fposmod(t / PERIOD, 2.0) - 1.0), 0.0, 1.0)  # 0 -> 1 -> 0 triangle

static func distance_tiles(p: float) -> int:
	return MIN_TILES + int(round(clampf(p, 0.0, 1.0) * float(MAX_TILES - MIN_TILES)))

## water[i] says whether the tile at distance i+1 along the cast line is water.
## Returns the index to cast to: the farthest water tile not beyond `want` tiles, else the nearest water, else -1.
static func choose(water: Array, want: int) -> int:
	var best := -1
	for i in water.size():
		if water[i] and i + 1 <= want:
			best = i
	if best >= 0:
		return best
	for i in water.size():
		if water[i]:
			return i
	return -1
