class_name PassOut
extends RefCounted
## Pure rules for collapsing from exhaustion or staying up past 2am (Stardew-style, but you wake where help is).

const MAX_LOSS := 1000
const LOSS_FRAC := 0.10
const HOSPITAL_BILL := 60
const WAKE_ENERGY_LATE := 50.0
const WAKE_ENERGY_EXHAUSTED := 40.0
const HOME_RADIUS_CELLS := 120.0   # farther than this from the farmhouse, the hospital is closer to carry you to

static func exhausted(energy: float) -> bool:
	return energy <= 0.5

static func money_loss(money: int) -> int:
	return clampi(int(floor(float(money) * LOSS_FRAC)), 0, MAX_LOSS)

static func wake_energy(cause: String) -> float:
	return WAKE_ENERGY_EXHAUSTED if cause == "exhausted" else WAKE_ENERGY_LATE

## "home" or "hospital": whichever door is nearer to where you dropped.
static func wake_spot(at: Vector2i, home_door: Vector2i, hospital_door: Vector2i) -> String:
	var dh := Vector2(at - home_door).length()
	var dc := Vector2(at - hospital_door).length()
	if dh <= HOME_RADIUS_CELLS and dh <= dc:
		return "home"
	return "hospital" if dc < dh else "home"

## Hospital bill is capped by what you carry; the home wake costs nothing extra.
static func bill(spot: String, money_after_loss: int) -> int:
	if spot != "hospital":
		return 0
	return mini(HOSPITAL_BILL, maxi(money_after_loss, 0))

## Warning text as bedtime nears (minutes since 06:00): 00:00 -> 1:00 -> 1:45.
static func warning(minutes: float) -> String:
	if minutes >= 19.75 * 60.0:
		return "You can barely keep your eyes open... get to bed!"
	if minutes >= 19.0 * 60.0:
		return "It's very late. Head home and sleep."
	if minutes >= 18.0 * 60.0:
		return "Midnight. You should think about bed."
	return ""

static func warning_level(minutes: float) -> int:
	if minutes >= 19.75 * 60.0:
		return 3
	if minutes >= 19.0 * 60.0:
		return 2
	if minutes >= 18.0 * 60.0:
		return 1
	return 0

static func summary(cause: String, loss: int, spot: String, bill_paid: int) -> String:
	var why := "You collapsed from exhaustion" if cause == "exhausted" else "You stayed up too late and passed out"
	var where := "woke up in the hospital" if spot == "hospital" else "woke up in your own bed"
	var cost := ""
	if loss + bill_paid > 0:
		cost = " (-$%d)" % (loss + bill_paid)
	return "%s, %s%s." % [why, where, cost]
