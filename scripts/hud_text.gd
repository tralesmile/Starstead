class_name HudText
extends RefCounted
const SEASONS := ["Spring", "Summer", "Autumn", "Winter"]

static func format(c: GameClock, money: int) -> String:
	return "%s %d  %s  $%d" % [SEASONS[c.season()], ((c.day - 1) % GameClock.DAYS_PER_SEASON) + 1, c.time_string(), money]
