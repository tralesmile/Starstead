class_name SeasonMath
extends RefCounted
## Seasonal palette: how grass, leaves and flowers look in spring (0), summer (1), autumn (2), winter (3).

static func ground_mul(season: int) -> Color:
	## Multiplier applied to the painted grass colours.
	match season % 4:
		1: return Color(1.06, 1.02, 0.84)    # sun-baked, a little yellow
		2: return Color(1.38, 0.80, 0.42)    # orange-brown
		3: return Color(0.92, 1.02, 1.08)    # cold and pale
	return Color(1, 1, 1)

static func ground_frost(season: int) -> float:
	## 0..1 how far the grass fades toward snow-white (winter only).
	return 0.68 if season % 4 == 3 else 0.0

static func tree_tint(season: int, kind: String) -> Color:
	## Modulate for a prop sprite. Pines stay green except under winter frost; oaks and bushes turn.
	var s := season % 4
	if kind == "rock":
		return Color(1, 1, 1) if s != 3 else Color(1.0, 1.0, 1.08)
	if kind == "pine":
		return [Color(1, 1, 1), Color(1, 1, 0.95), Color(1.08, 0.97, 0.85), Color(0.9, 0.98, 1.1)][s]
	return [Color(1, 1, 1), Color(1.0, 1.04, 0.9), Color(1.45, 0.82, 0.38), Color(0.88, 0.92, 1.02)][s]

static func flowers_visible(season: int) -> bool:
	return season % 4 != 3

static func kind_of(tex_path: String) -> String:
	for k in ["pine", "oak", "bush", "rock"]:
		if tex_path.contains(k):
			return k
	return ""
