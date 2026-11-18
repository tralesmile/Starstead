class_name HudBars
extends RefCounted
## Pure helpers for the HUD energy bar and car fuel gauge.

static func frac(value: float, maxv: float) -> float:
	return clampf(value / maxf(maxv, 0.001), 0.0, 1.0)

static func bar_color(f: float) -> Color:
	if f > 0.5:
		return Color(0.35, 0.8, 0.3)
	if f > 0.2:
		return Color(0.95, 0.75, 0.2)
	return Color(0.9, 0.25, 0.2)

static func low(f: float) -> bool:
	return f <= 0.2

static func text(value: float, maxv: float) -> String:
	return "%d/%d" % [int(round(value)), int(round(maxv))]
