class_name HudText
extends RefCounted
const SEASONS := ["Spring", "Summer", "Autumn", "Winter"]

static func format(c: GameClock, money: int) -> String:
	return "%s %d  %s  $%d" % [SEASONS[c.season()], ((c.day - 1) % GameClock.DAYS_PER_SEASON) + 1, c.time_string(), money]

static func date_text(c: GameClock) -> String:
	return "%s %d" % [SEASONS[c.season()], ((c.day - 1) % GameClock.DAYS_PER_SEASON) + 1]

static func money_text(money: int) -> String:
	## $1234567 -> "$1,234,567" (readable at a glance).
	var s := str(absi(money))
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return ("-$" if money < 0 else "$") + s + out

static func dial(hour: float) -> Dictionary:
	## Day dial: {day, t}. day = sun is up (6:00-20:00); t = 0..1 progress across the dial's arc (left to right)
	## for the sun by day or the moon by night.
	var h := fposmod(hour, 24.0)
	if h >= 6.0 and h < 20.0:
		return {"day": true, "t": (h - 6.0) / 14.0}
	return {"day": false, "t": fposmod(h - 20.0, 24.0) / 10.0}
