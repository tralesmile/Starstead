class_name CloudMath
extends RefCounted
## Pure helpers for drifting cloud shadows: where each cloud is, how big, and how dark the shadows are.

const COUNT := 14
const SPAN := 1500.0          # clouds wrap inside a SPAN x SPAN window centred on the player (world anchored, so they do not follow you)
const WIND := Vector2(7.0, 2.5)   # px per second

static func strength(minutes: float, rain: float, season: int) -> float:
	## 0..1 how visible the shadows are: none at night or in rain (overcast has no hard shadows), softer in winter.
	var day := 1.0 - AmbientMath.night_factor(minutes)
	var morning := clampf(minutes / 90.0, 0.0, 1.0)   # fade in after 06:00
	var s := day * morning * (1.0 - clampf(rain * 1.5, 0.0, 1.0))
	return s * (0.7 if season == 3 else 1.0)

static func radius(i: int) -> Vector2:
	## Ellipse half-size in px; every cloud a bit different.
	var k := fposmod(float(i) * 0.7548776, 1.0)
	return Vector2(130.0 + 140.0 * k, 70.0 + 60.0 * fposmod(float(i) * 0.5698403, 1.0))

static func pos(i: int, t: float, around: Vector2) -> Vector2:
	## World position of cloud i at time t, wrapped to the window around `around`.
	var base := Vector2(fposmod(float(i) * 611.0, SPAN), fposmod(float(i) * 397.0 + 130.0, SPAN))
	var p := base + WIND * t * (0.8 + 0.1 * float(i % 4))
	var rel := Vector2(fposmod(p.x - around.x + SPAN * 0.5, SPAN), fposmod(p.y - around.y + SPAN * 0.5, SPAN))
	return around + rel - Vector2(SPAN, SPAN) * 0.5

static func ellipse(centre: Vector2, r: Vector2, n: int = 20) -> PackedVector2Array:
	var out := PackedVector2Array()
	for k in n:
		var a := TAU * float(k) / float(n)
		out.append((centre + Vector2(cos(a) * r.x, sin(a) * r.y)).round())
	return out
