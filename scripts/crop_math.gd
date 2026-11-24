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

## Twinkle of the i-th glint on a watered tile: x, y (0..32 px inside the tile) and alpha 0..1 (mostly dark, brief flash).
static func glint(cell: Vector2i, i: int, t: float) -> Dictionary:
	var h: int = (cell.x * 73856093 + cell.y * 19349663 + i * 83492791) & 0xffffff
	var period := 2.4 + float(h % 100) / 100.0 * 2.0
	var ph := fposmod(t / period + float((h >> 8) % 100) / 100.0, 1.0)
	var a := clampf(1.0 - absf(ph - 0.5) * 9.0, 0.0, 1.0)   # flash window ~ 22% of the period
	return {"x": 4.0 + float(h % 24), "y": 4.0 + float((h >> 5) % 24), "a": a}
