class_name FootballLeague
extends RefCounted
## Pure Halden Sunday League: four clubs, three rounds (everyone meets once), one fixture of yours per day.
## The other fixture of each round is simulated from the season number. 3 points a win, 1 a draw.

const CLUBS := ["Starstead Rovers", "Halden Dockers", "Vance XI", "Highland Miners"]
const BASE_TIER := [2, 1, 3, 2]
## ROUNDS[r] = [[you, rival], [other, other]]
const ROUNDS := [[[0, 1], [2, 3]], [[0, 3], [1, 2]], [[0, 2], [3, 1]]]
const MATCH_FEE := 15
const WIN_PAY := 90
const DRAW_PAY := 40
const CHAMPION_PAY := 400
const ENERGY_COST := 20
const MATCH_MINUTES := 90

var season := 1
var round_i := 0
var table: Array = []      # one row per club: [played, won, drawn, lost, goals for, goals against]
var titles := 0
var last_day := -1

func _init() -> void:
	_clear_table()

func _clear_table() -> void:
	table = []
	for i in CLUBS.size():
		table.append([0, 0, 0, 0, 0, 0])

func opponent() -> int:
	return int(ROUNDS[round_i][0][1])

func tier_of(club: int) -> int:
	## Rivals sharpen up by one after each title you take (capped).
	if club == 0:
		return BASE_TIER[0]
	return mini(4, int(BASE_TIER[club]) + mini(titles, 2))

func can_play(day: int, money: int, energy: float, hour: float) -> String:
	## "" when a match can start, otherwise the reason.
	if day == last_day:
		return "One league match a day - come back tomorrow"
	if hour < 8.0 or hour >= 20.0:
		return "Kick-offs run 08:00 to 20:00"
	if energy <= ENERGY_COST:   # never let a match drop you to zero
		return "Too tired to play (needs %d energy)" % ENERGY_COST
	if money < MATCH_FEE:
		return "The referee's fee is $%d" % MATCH_FEE
	return ""

func _add(a: int, b: int, ga: int, gb: int) -> void:
	for pair in [[a, ga, gb], [b, gb, ga]]:
		var row: Array = table[pair[0]]
		row[0] += 1
		row[1 if pair[1] > pair[2] else (2 if pair[1] == pair[2] else 3)] += 1
		row[4] += pair[1]
		row[5] += pair[2]

static func sim_goals(tier_for: int, tier_against: int, rng: RandomNumberGenerator) -> int:
	var expected := clampf(2.0 + 0.6 * float(tier_for - tier_against), 0.4, 4.5)
	var n := 0
	for i in 8:
		if rng.randf() < expected / 8.0:
			n += 1
	return n

static func points(row: Array) -> int:
	return int(row[1]) * 3 + int(row[2])

## Club ids best first: points, goal difference, goals for.
func standings() -> Array:
	var ids := [0, 1, 2, 3]
	ids.sort_custom(func(a, b):
		var ra: Array = table[a]
		var rb: Array = table[b]
		var ka := [points(ra), ra[4] - ra[5], ra[4], -a]
		var kb := [points(rb), rb[4] - rb[5], rb[4], -b]
		return ka > kb)
	return ids

## Books your result (and the other fixture). Returns {"pay", "season_over", "champion", "place", "text"}.
## When the season ends the final table stays readable until start_next_season().
func record(mine: int, theirs: int, day: int) -> Dictionary:
	if season_done():
		start_next_season()
	var rng := RandomNumberGenerator.new()
	rng.seed = season * 1000 + round_i
	var fixture: Array = ROUNDS[round_i]
	_add(0, opponent(), mine, theirs)
	var a := int(fixture[1][0])
	var b := int(fixture[1][1])
	_add(a, b, sim_goals(tier_of(a), tier_of(b), rng), sim_goals(tier_of(b), tier_of(a), rng))
	last_day = day
	round_i += 1
	var pay := WIN_PAY if mine > theirs else (DRAW_PAY if mine == theirs else 0)
	var over := season_done()
	var place := standings().find(0) + 1
	var champion := over and place == 1
	if champion:
		pay += CHAMPION_PAY
		titles += 1
	var verdict := "Win" if mine > theirs else ("Draw" if mine == theirs else "Defeat")
	var text := "%s %d-%d, $%d" % [verdict, mine, theirs, pay]
	if champion:
		text += "  CHAMPIONS!"
	elif over:
		text += "  Season over: place %d" % place
	return {"pay": pay, "season_over": over, "champion": champion, "place": place, "text": text}

func season_done() -> bool:
	return round_i >= ROUNDS.size()

func start_next_season() -> void:
	season += 1
	round_i = 0
	_clear_table()

func to_dict() -> Dictionary:
	return {"season": season, "round": round_i, "table": table.duplicate(true), "titles": titles, "last_day": last_day}

func from_dict(d: Dictionary) -> void:
	season = maxi(1, int(d.get("season", 1)))
	round_i = clampi(int(d.get("round", 0)), 0, ROUNDS.size())
	titles = int(d.get("titles", 0))
	last_day = int(d.get("last_day", -1))
	_clear_table()
	var t: Array = d.get("table", [])
	if t.size() == CLUBS.size():
		for i in t.size():
			for k in 6:
				table[i][k] = int(t[i][k])
