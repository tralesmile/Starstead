class_name GoalText
extends RefCounted
## One-line "what should I do now" hint under the HUD (playtest 2026-11-18: no goal was visible in the first 30 seconds).

static func current(tilled: int, planted: int, day: int, money: int, city_seen: bool, bank: int = 0) -> String:
	if tilled == 0 and planted == 0 and day <= 1:
		return "Goal: press 1 for the hoe and click grass to till a field"
	if planted == 0 and day <= 1:
		return "Goal: press 3 (seeds) and click the tilled soil to plant"
	if day <= 1:
		return "Goal: water with the can (2), fish at the dock (6), then sleep in your farmhouse bed (E)"
	if not city_seen and (money >= 600 or day >= 4):
		return "Goal: follow the road east to Port Halden (bank, hospital, shops)"
	if money < 1500:
		return "Goal: harvest crops and sell at the stall; the Vance debt waits"
	if bank == 0 and city_seen:
		return "Goal: save money at Halden Bank for interest"
	return ""
