class_name DayNight
extends RefCounted
## Maps clock minutes-since-06:00 to an ambient tint (CanvasModulate).

const KEYS := [  # minutes since 06:00, colour
	[0, Color(1.0, 0.92, 0.8)],      # 06:00 dawn
	[120, Color(1, 1, 1)],           # 08:00 day
	[600, Color(1, 1, 1)],           # 16:00
	[780, Color(1.0, 0.75, 0.55)],   # 19:00 dusk
	[900, Color(0.45, 0.5, 0.8)],    # 21:00 night
	[1200, Color(0.3, 0.34, 0.6)],   # 02:00 deep night
]

static func tint(minutes: float) -> Color:
	for i in range(KEYS.size() - 1):
		var a: Array = KEYS[i]
		var b: Array = KEYS[i + 1]
		if minutes <= b[0]:
			var t := clampf((minutes - a[0]) / float(b[0] - a[0]), 0.0, 1.0)
			return (a[1] as Color).lerp(b[1], t)
	return KEYS[KEYS.size() - 1][1]

static func lamp_strength(minutes: float) -> float:
	## 0 in daylight, 1 at night: how strongly lanterns glow (ramps with the dusk tint).
	var t := tint(minutes)
	var dark := 1.0 - (t.r + t.g + t.b) / 3.0
	return clampf((dark - 0.05) / 0.45, 0.0, 1.0)
