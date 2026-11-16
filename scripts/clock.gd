class_name GameClock
extends RefCounted
## In-game clock. 1 real second = SECONDS_PER_REAL_SECOND game seconds.
## A day runs 06:00 -> 26:00 (2am) like Stardew; time is stored as minutes since day start 06:00.

const DAY_START_HOUR := 6
const DAY_LENGTH_MIN := 20 * 60  # 06:00 to 02:00
const GAME_MIN_PER_REAL_SEC := 1.0 / 0.7  # ~14 real minutes per day
const DAYS_PER_SEASON := 28

var day: int = 1
var minutes: float = 0.0  # minutes since 06:00

func advance(real_seconds: float) -> bool:
	## Returns true if the day ended (passed out / bedtime).
	minutes += real_seconds * GAME_MIN_PER_REAL_SEC
	if minutes >= DAY_LENGTH_MIN:
		new_day()
		return true
	return false

func new_day() -> void:
	day += 1
	minutes = 0.0

func hour() -> int:
	return (DAY_START_HOUR + int(minutes) / 60) % 24

func minute() -> int:
	return int(minutes) % 60

func season() -> int:
	return ((day - 1) / DAYS_PER_SEASON) % 4

func time_string() -> String:
	return "%02d:%02d" % [hour(), minute()]

func is_night() -> bool:
	var h := DAY_START_HOUR + int(minutes) / 60
	return h >= 20 or h < 6

func to_dict() -> Dictionary:
	return {"day": day, "minutes": minutes}

func from_dict(d: Dictionary) -> void:
	day = int(d.get("day", 1))
	minutes = float(d.get("minutes", 0.0))
