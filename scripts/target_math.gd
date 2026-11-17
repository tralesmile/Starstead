class_name TargetMath
extends RefCounted
## Pure helpers for mouse aiming: world point -> tile, reach test, facing toward a tile.

const REACH_TILES := 2.5

static func cell_of(p: Vector2, tile: int = 32) -> Vector2i:
	return Vector2i(floori(p.x / tile), floori(p.y / tile))

static func center_of(c: Vector2i, tile: int = 32) -> Vector2:
	return (Vector2(c) + Vector2(0.5, 0.5)) * tile

## Player stands with feet at pos; chest height is 8px above. True when the tile centre is within reach.
static func in_reach(player_pos: Vector2, c: Vector2i, reach: float = REACH_TILES, tile: int = 32) -> bool:
	return (player_pos + Vector2(0, -8)).distance_to(center_of(c, tile)) <= reach * tile

## Facing (PlayerMath.Facing) that looks at tile c from pos; the larger axis wins, ties look down/up.
static func facing_toward(player_pos: Vector2, c: Vector2i, current: int, tile: int = 32) -> int:
	var d := center_of(c, tile) - (player_pos + Vector2(0, -8))
	if d.length() < 4.0:
		return current
	if absf(d.x) > absf(d.y):
		return PlayerMath.Facing.RIGHT if d.x > 0.0 else PlayerMath.Facing.LEFT
	return PlayerMath.Facing.DOWN if d.y > 0.0 else PlayerMath.Facing.UP

## Next hotbar slot after a wheel notch (dir = +1/-1), wrapping.
static func cycle(sel: int, dir: int, n: int) -> int:
	return posmod(sel + dir, maxi(n, 1))

## Zoom: user step 1..3, bias -1 while driving/riding; result stays within 1..3.
static func effective_zoom(step: int, bias: int) -> int:
	return clampi(step + bias, 1, 3)

static func zoom_step(step: int, dir: int) -> int:
	return clampi(step + dir, 1, 3)
