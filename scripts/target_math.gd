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

## Zoom: user step 1..4 maps to ZOOMS (owner 2026-11-18: 2x was too close, default is now 1.5x), bias -1 while driving/riding.
const ZOOMS := [1.0, 1.5, 2.0, 3.0]
const DEFAULT_STEP := 2

static func effective_zoom(step: int, bias: int) -> int:
	return clampi(step + bias, 1, ZOOMS.size())

static func zoom_step(step: int, dir: int) -> int:
	return clampi(step + dir, 1, ZOOMS.size())

static func zoom_value(step: int) -> float:
	return float(ZOOMS[clampi(step, 1, ZOOMS.size()) - 1])

static func step_for_zoom(z: float) -> int:
	var best := 1
	for i in ZOOMS.size():
		if absf(float(ZOOMS[i]) - z) < absf(float(ZOOMS[best - 1]) - z):
			best = i + 1
	return best

## Number key -> hotbar slot (1..9 -> 0..8, 0 -> 9), -1 if not a number key.
static func key_slot(keycode: int) -> int:
	if keycode >= KEY_1 and keycode <= KEY_9:
		return keycode - KEY_1
	if keycode == KEY_0:
		return 9
	return -1
