class_name CropMath
extends RefCounted
## Pure maths for living crops: wind sway (shear at the top of the plant) and glints on wet soil.

const MAX_SKEW := 0.09

## Horizontal shear for a crop at `cell`, `stage` 0..4, game-independent time `t` (seconds). Taller stages sway more,
## neighbours are out of phase so a field ripples like wind rolling across it.
static func sway(cell: Vector2i, t: float, stage: int, wind: float = 1.0) -> float:
	if stage <= 0:
		return 0.0
	var phase := float(cell.x) * 0.55 + float(cell.y) * 0.25
	var gust := 0.65 + 0.35 * sin(t * 0.23 + float(cell.x) * 0.05)   # slow gust envelope
	var wave := sin(t * 1.7 + phase) * 0.7 + sin(t * 2.9 + phase * 1.7) * 0.3
	return clampf(wave * gust * wind * MAX_SKEW * float(stage) / 4.0, -MAX_SKEW, MAX_SKEW)

const BRUSH_R := 28.0
const BRUSH_LEAN := 0.3
## Extra shear when the player walks through a plant: it bends away from them, strongest right at the plant.
## `plant` and `player` are world positions of the plant's foot and the player's feet; the player's pushing reads as a lean.
static func brush(plant: Vector2, player: Vector2, stage: int) -> float:
	if stage <= 0:
		return 0.0
	var d := plant - player
	if absf(d.y) > BRUSH_R * 0.7 or absf(d.x) > BRUSH_R:
		return 0.0
	var k := 1.0 - clampf(d.length() / BRUSH_R, 0.0, 1.0)
	if k <= 0.0:
		return 0.0
	var dir := 1.0 if d.x >= 0.0 else -1.0
	return dir * k * BRUSH_LEAN * minf(float(stage) / 2.0, 1.0)

## Soil colour multiplier in rain: dry soil soaks up water and darkens a lot, wet soil only a little (0.74..1).
static func rain_darken(rain: float, watered: bool) -> float:
	var r := clampf(rain, 0.0, 1.0)
	return 1.0 - r * (0.1 if watered else 0.26)

## Twinkle of the i-th glint on a watered tile: x, y (0..32 px inside the tile) and alpha 0..1 (mostly dark, brief flash).
static func glint(cell: Vector2i, i: int, t: float) -> Dictionary:
	var h: int = (cell.x * 73856093 + cell.y * 19349663 + i * 83492791) & 0xffffff
	var period := 2.4 + float(h % 100) / 100.0 * 2.0
	var ph := fposmod(t / period + float((h >> 8) % 100) / 100.0, 1.0)
	var a := clampf(1.0 - absf(ph - 0.5) * 9.0, 0.0, 1.0)   # flash window ~ 22% of the period
	return {"x": 4.0 + float(h % 24), "y": 4.0 + float((h >> 5) % 24), "a": a}

## Rain puddle on a tilled tile (a sky-coloured sheen in the furrows): {"on", "x", "y", "rx", "ry", "a"} or on=false.
## More tiles hold a puddle the harder it rains; wet (watered) soil drains slower so it puddles first.
static func puddle(cell: Vector2i, rain: float) -> Dictionary:
	var r := clampf(rain, 0.0, 1.0)
	var h: int = (cell.x * 2654435 + cell.y * 40503 + 977) & 0xffff
	var roll := float(h % 1000) / 1000.0
	if r < 0.3 or roll > r * 0.75:
		return {"on": false}
	var k := clampf((r - 0.3) / 0.7, 0.0, 1.0)
	return {"on": true, "x": 9.0 + float((h >> 4) % 14), "y": 12.0 + float((h >> 8) % 12), "rx": 5.0 + 4.0 * k + float(h % 3), "ry": 2.0 + 1.5 * k, "a": 0.25 + 0.3 * k}

## Raindrop ripple ring inside a puddle: radius fraction 0..1 and fade for the i-th ring at time t.
static func puddle_ring(cell: Vector2i, i: int, t: float) -> Dictionary:
	var h: int = (cell.x * 31 + cell.y * 17 + i * 53) & 0xff
	var ph := fposmod(t * 1.3 + float(h) / 255.0, 1.0)
	return {"r": ph, "a": (1.0 - ph) * 0.8}
