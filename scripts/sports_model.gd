class_name SportsModel
extends RefCounted
## Pure rules for the Halden Sports Hall and pitch mini-games: basketball free throws, football penalties, boxing bouts.
## All randomness comes in as a 0..1 roll so everything is testable. Timing uses a triangle-wave meter 0..1.

const SHOTS := 10
const KICKS := 5
const HOOP_PAY := 12
const HOOP_STREAK_BONUS := 6      # extra per made shot after the 2nd in a row
const GOAL_PAY := 40
const BOUT_FEE := 20
const BOUT_PRIZE := 90
const ROUND_MAX := 12

static func meter(t: float, speed: float = 1.4) -> float:
	## Triangle wave 0..1..0 (period 2/speed seconds).
	return absf(fposmod(t * speed, 2.0) - 1.0)

# ---- basketball ----
static func hoop_width(best: int) -> float:
	## Sweet zone half-width: wider as your best score grows (0.09 .. 0.15).
	return 0.09 + 0.006 * float(clampi(best, 0, 10))

static func hoop_made(m: float, roll: float, width: float) -> bool:
	var d := absf(m - 0.5)
	if d <= width:
		return true
	if d <= width * 2.0:
		return roll < 0.4
	return false

static func hoop_payout(results: Array) -> int:
	## results: Array[bool]. HOOP_PAY per make, bonus for every make after two in a row.
	var pay := 0
	var streak := 0
	for r in results:
		if r:
			streak += 1
			pay += HOOP_PAY + (HOOP_STREAK_BONUS if streak > 2 else 0)
		else:
			streak = 0
	return pay

# ---- football penalty ----
static func zone_of(aim: float) -> int:
	## 0 left, 1 middle, 2 right.
	return 0 if aim < 0.34 else (2 if aim > 0.66 else 1)

static func keeper_zone(roll: float) -> int:
	return clampi(int(roll * 3.0), 0, 2)

static func penalty(aim: float, power: float, keeper: int) -> String:
	## "goal" | "saved" | "miss". Too weak is saved, too hard sails over; a hard shot beats a keeper who guessed right.
	if power > 0.94:
		return "miss"
	if power < 0.35:
		return "saved"
	if zone_of(aim) != keeper:
		return "goal"
	return "goal" if power >= 0.8 else "saved"

# ---- boxing ----
static func exchange(tele: int, action: int, react: float, window: float) -> Dictionary:
	## tele: -1 left / +1 right punch from the opponent. action: 0 none, -1/+1 dodge that way, 2 jab.
	## react: seconds since the telegraph; window: seconds you have. Returns {you: dmg taken, opp: dmg dealt, text}.
	if action == tele and react <= window:
		return {"you": 0, "opp": 8, "text": "Dodged! Counter"}
	if action == 2 and react <= window:
		return {"you": 6, "opp": 4, "text": "Trade blows"}
	return {"you": 6, "opp": 0, "text": "Took a punch"}

static func bout_window(tier: int) -> float:
	return maxf(0.45, 0.9 - 0.12 * float(tier))

static func opp_hp(tier: int) -> int:
	return 30 + 8 * tier

static func bout_over(you_hp: int, opp_hp_now: int, rounds: int) -> String:
	if opp_hp_now <= 0:
		return "win"
	if you_hp <= 0 or rounds >= ROUND_MAX:
		return "lose" if opp_hp_now > 0 else "win"
	return ""

static func bout_prize(tier: int) -> int:
	return BOUT_PRIZE + 40 * tier
