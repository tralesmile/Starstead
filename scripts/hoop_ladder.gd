class_name HoopLadder
extends RefCounted
## Pure streetball ladder: three rival crews climbed in order (a loss keeps your rung). Beat all three for the
## court crown, a bonus, and sharper rivals on the next climb. One paid game a day.

const CREWS := ["Starstead Ballers", "Dockside Dunkers", "Highland Hammers", "Skyline Aces"]
const BASE_TIER := [2, 1, 2, 3]
const MATCH_FEE := 10
const WIN_PAY := [60, 85, 120]     # by rung
const CROWN_PAY := 220
const ENERGY_COST := 18
const MATCH_MINUTES := 60
const OPEN_HOUR := 8.0
const CLOSE_HOUR := 21.0

var rung := 0
var crowns := 0
var wins := 0
var losses := 0
var last_day := -1
var best_margin := 0

func rival() -> int:
	return rung + 1

func tier_of(crew: int) -> int:
	if crew == 0:
		return BASE_TIER[0]
	return mini(4, int(BASE_TIER[crew]) + mini(crowns, 2))

func prize() -> int:
	return int(WIN_PAY[rung]) + (CROWN_PAY if rung == WIN_PAY.size() - 1 else 0)

func can_play(day: int, money: int, energy: float, hour: float) -> String:
	## "" when a game can start, otherwise the reason.
	if day == last_day:
		return "One money game a day - come back tomorrow"
	if hour < OPEN_HOUR or hour >= CLOSE_HOUR:
		return "The court runs 08:00 to 21:00"
	if energy <= ENERGY_COST:
		return "Too tired to ball (needs %d energy)" % ENERGY_COST
	if money < MATCH_FEE:
		return "The court fee is $%d" % MATCH_FEE
	return ""

## Books a result. Returns {"pay", "won", "crown", "text"}.
func record(mine: int, theirs: int, day: int) -> Dictionary:
	last_day = day
	var won := mine > theirs
	var pay := prize() if won else 0
	var crown := false
	if won:
		wins += 1
		best_margin = maxi(best_margin, mine - theirs)
		rung += 1
		if rung >= WIN_PAY.size():
			rung = 0
			crowns += 1
			crown = true
	else:
		losses += 1
	var text := "%s %d-%d, $%d" % ["Win" if won else "Defeat", mine, theirs, pay]
	if crown:
		text += "  COURT CROWN!"
	return {"pay": pay, "won": won, "crown": crown, "text": text}

func to_dict() -> Dictionary:
	return {"rung": rung, "crowns": crowns, "wins": wins, "losses": losses, "last_day": last_day, "best_margin": best_margin}

func from_dict(d: Dictionary) -> void:
	rung = clampi(int(d.get("rung", 0)), 0, WIN_PAY.size() - 1)
	crowns = maxi(0, int(d.get("crowns", 0)))
	wins = maxi(0, int(d.get("wins", 0)))
	losses = maxi(0, int(d.get("losses", 0)))
	last_day = int(d.get("last_day", -1))
	best_margin = maxi(0, int(d.get("best_margin", 0)))
