class_name WaterMotion
extends RefCounted
## Pure motion for floating decor: lily pads drift in a slow ellipse and bob 1px; whole pixels only.

static func offset(t: float, phase: float, drift: float = 2.0) -> Vector2:
	var a := t * 0.6 + phase
	return Vector2(roundf(sin(a) * drift), roundf(cos(a * 0.8 + 1.3) * drift * 0.5 + sin(t * 1.7 + phase * 3.0)))

static func push_away(pad: Vector2, player: Vector2, radius: float = 20.0, strength: float = 6.0) -> Vector2:
	## Pads slide out of the way when something wades close; zero outside the radius.
	var d := pad - player
	var l := d.length()
	if l >= radius or l < 0.001:
		return Vector2.ZERO
	return (d / l * strength * (1.0 - l / radius)).round()
