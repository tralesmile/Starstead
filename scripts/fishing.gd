class_name Fishing
extends RefCounted
## Pure fishing logic: cast on water, bite timer, fish pick by depth/season, reel mini-game.
## No scene access: the caller feeds delta and the player's reel input.

enum State { IDLE, WAITING, BITE, REELING, CAUGHT, LOST }

const BITE_MIN := 2.0
const BITE_MAX := 7.0
const BITE_WINDOW := 1.2     # seconds to hook after the bobber dips
const BAR_SIZE := 0.28       # fraction of the track covered by the catch bar
const GAIN := 0.30           # progress per second while overlapping
const LOSS := 0.22           # progress lost per second while not overlapping
const BAR_UP := 1.1          # bar acceleration while reeling (held)
const GRAVITY := 0.9

var state: int = State.IDLE
var timer := 0.0
var fish_id := ""
var difficulty := 0.0
var bar := 0.5       # centre of the catch bar, 0..1
var bar_v := 0.0
var fish_pos := 0.5
var fish_target := 0.5
var progress := 0.3
var rng := RandomNumberGenerator.new()
var bar_size := BAR_SIZE   # per-cast (bait can widen it)

func _init(seed_value: int = 1) -> void:
	rng.seed = seed_value

static func depth_for(sdf: float) -> String:
	## sdf < 0 is water; deeper (more negative) water holds deep fish.
	return "deep" if sdf < -3.0 else "shallow"

static func pick_fish(table: Dictionary, depth: String, season: int, roll: float) -> String:
	## Weighted pick among fish that live at this depth in this season. roll in 0..1. "" if none.
	var ids := []
	var total := 0.0
	for id in table:
		var f = table[id]
		if f.depth != depth:
			continue
		var ok := false
		for s in f.seasons:
			if int(s) == season:
				ok = true
		if ok:
			ids.append(id)
			total += float(f.weight)
	ids.sort()
	var acc := 0.0
	for id in ids:
		acc += float(table[id].weight) / total
		if roll <= acc:
			return id
	return ids[ids.size() - 1] if ids.size() > 0 else ""

func cast(sdf: float, table: Dictionary, season: int, bait: Dictionary = {}) -> bool:
	## Only on water. Picks the fish now so bite time and difficulty are fixed per cast.
	if state != State.IDLE or sdf >= 0.0:
		return false
	fish_id = pick_fish(table, depth_for(sdf), season, rng.randf())
	if fish_id == "":
		return false
	difficulty = float(table[fish_id].difficulty)
	timer = rng.randf_range(BITE_MIN, BITE_MAX) * float(bait.get("bite_mult", 1.0))
	bar_size = BAR_SIZE + float(bait.get("bar_bonus", 0.0))
	state = State.WAITING
	return true

func hook() -> bool:
	## Player presses use during the bite window: starts the reel mini-game.
	if state == State.BITE:
		state = State.REELING
		bar = 0.5
		bar_v = 0.0
		fish_pos = 0.5
		fish_target = 0.5
		progress = 0.3
		return true
	if state == State.WAITING:
		reset()  # pulled too early: the fish is scared off
	return false

func reset() -> void:
	state = State.IDLE
	fish_id = ""

func tick(delta: float, hold: bool) -> void:
	match state:
		State.WAITING:
			timer -= delta
			if timer <= 0.0:
				state = State.BITE
				timer = BITE_WINDOW
		State.BITE:
			timer -= delta
			if timer <= 0.0:
				state = State.LOST
		State.REELING:
			_reel(delta, hold)

func _reel(delta: float, hold: bool) -> void:
	bar_v += (-BAR_UP if hold else GRAVITY) * delta
	bar = clampf(bar + bar_v * delta, bar_size / 2.0, 1.0 - bar_size / 2.0)
	if bar <= bar_size / 2.0 or bar >= 1.0 - bar_size / 2.0:
		bar_v = 0.0
	if absf(fish_pos - fish_target) < 0.02 and rng.randf() < delta * (1.0 + 4.0 * difficulty):
		fish_target = rng.randf()  # darting: harder fish choose new spots more often
	fish_pos = move_toward(fish_pos, fish_target, delta * (0.15 + 0.9 * difficulty))
	progress += (GAIN if overlapping() else -LOSS) * delta
	if progress >= 1.0:
		state = State.CAUGHT
	elif progress <= 0.0:
		state = State.LOST

func overlapping() -> bool:
	return absf(bar - fish_pos) <= bar_size / 2.0

static func pick_bait(bait: Dictionary, inv) -> String:
	## Best bait (lowest bite multiplier) the bag holds, or "".
	var best := ""
	var bm := 9.0
	for id in bait:
		if inv.count(id) > 0 and float(bait[id].bite_mult) < bm:
			bm = float(bait[id].bite_mult)
			best = id
	return best
