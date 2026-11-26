class_name HarbourModel
extends RefCounted
## Pure layout + rules of Halden Harbour (docs/EARTH_MAP.md E5), world cells (homestead chunk = 0..63).
## A forced sea lies south of the harbour road end (224,96); a stone quay and a T-shaped pier of paved
## land reach into it. Sea fishing uses the "sea" fish in data/fish.json, a weekly fishing contest pays the
## top three, and at night a sealed crate can be carried to the fence in Port Halden for cash (and heat).

const SEA_X0 := 196
const QUAY := Rect2i(212, 96, 25, 10)      # x 212..236, y 96..105
const PIER := Rect2i(223, 106, 4, 16)      # x 223..226, y 106..121
const HEAD := Rect2i(216, 119, 18, 3)      # x 216..233, y 119..121
const BOARD := Vector2i(219, 99)           # contest board on the quay
const CRATE_CELL := Vector2i(231, 120)     # night crate at the pier head
const DEALER_CELL := Vector2i(183, 18)    # back-alley dealer beside the buyer (street tier Known)
const FENCE_CELL := Vector2i(180, 18)      # buyer in a Port Halden back alley
const ENTRY_FEE := 25
const CONTEST_START := 8.0
const CONTEST_END := 18.0
const PRIZES := [300, 150, 75]

static func shore_y(x: int) -> int:
	return 102 + int(round(sin(x * 0.15) * 3.0))

static func is_quay(c: Vector2i) -> bool:
	return QUAY.has_point(c) or PIER.has_point(c) or HEAD.has_point(c)

static func is_sea(c: Vector2i) -> bool:
	## Forced water (not on the quay/pier). South of a wavy shore, east of SEA_X0, inside the world.
	return c.x >= SEA_X0 and c.y >= shore_y(c.x) and not is_quay(c) and not IsleModel.is_land(c)

static func in_sea_area(c: Vector2i) -> bool:
	## Fishing here uses the sea fish table (a bit of margin north of the shore for the wobble).
	return c.x >= SEA_X0 and c.y >= shore_y(c.x) - 1

static func is_deep(c: Vector2i) -> bool:
	return is_sea(c) and c.y - shore_y(c.x) >= 6 and not IsleModel.is_shallows(c)

static func props() -> Array:
	var out: Array = [
		{"kind": "board", "cell": BOARD},
		{"kind": "lighthouse", "cell": Vector2i(233, 120)},
		{"kind": "boat", "cell": Vector2i(219, 112)},
		{"kind": "boat", "cell": Vector2i(231, 110)},
		{"kind": "barrel", "cell": Vector2i(214, 100)},
		{"kind": "barrel", "cell": Vector2i(215, 100)},
		{"kind": "fish_crate", "cell": Vector2i(228, 99)},
		{"kind": "net_pile", "cell": Vector2i(230, 99)},
	]
	for y in [108, 112, 116]:
		out.append({"kind": "bollard", "cell": Vector2i(223, y)})
		out.append({"kind": "bollard", "cell": Vector2i(226, y)})
	return out

# ---- weekly contest ----
static func is_contest_day(day: int) -> bool:
	return day % 7 == 6

static func contest_open(day: int, hour: float) -> bool:
	return is_contest_day(day) and hour >= CONTEST_START and hour < CONTEST_END

static func rival_scores(day: int) -> Array:
	## Three named rivals with a deterministic total length (cm) per contest day; they get stronger over the weeks.
	var names := ["Old Brannock", "Mara Quill", "Tobbe"]
	var out: Array = []
	var week := day / 7
	for i in 3:
		var h := (day * 7919 + i * 104729 + 13) % 1000
		out.append({"name": names[i], "score": 60 + i * 10 + h % 40 + mini(week, 10) * 4})
	return out

static func rank(score: int, rivals: Array) -> int:
	## 1 = best. Ties go to the player.
	var r := 1
	for v in rivals:
		if int(v["score"]) > score:
			r += 1
	return r

static func prize(r: int) -> int:
	return int(PRIZES[r - 1]) if r >= 1 and r <= PRIZES.size() else 0

# ---- smuggling ----
static func crate_available(day: int, hour: float) -> bool:
	## A sealed crate waits at the pier head on every third night (21:00-05:00).
	return day % 3 == 1 and (hour >= 21.0 or hour < 5.0)

static func crate_pay(day: int) -> int:
	return 200 + (day % 5) * 15

static func too_hot(stars: int) -> bool:
	return stars >= 3
