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
const BEGINNER_BONUS := 0.12   # wider catch bar for the first catches (Stardew's fishing starts too hard)
const BEGINNER_CATCHES := 5

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

## Treasure chest in the reel (Stardew-style side goal): sometimes a chest drifts into the track; keep the bar
## on it to open it, but the fish slips meanwhile. Loot only counts if the fish is landed too.
const TREASURE_CHANCE := 0.18
const TREASURE_FILL := 0.5    # per second while the bar covers the chest
const TREASURE_DRAIN := 0.2
const TREASURE_LOOT := [   # [weight, item id ("$" = money), min, max]
	[30, "$", 40, 120], [20, "glow_bait", 3, 6], [15, "copper_ore", 3, 6], [12, "iron_ore", 2, 4],
	[10, "coal", 3, 6], [8, "copper_bar", 1, 2], [5, "iron_bar", 1, 1],
]
var treasure_on := false
var treasure_pos := 0.5
var treasure_prog := 0.0
var treasure_got := false
var treasure_in := -1.0   # seconds until the chest appears (-1 = none this cast)

func _init(seed_value: int = 1) -> void:
	rng.seed = seed_value

static func depth_for(sdf: float) -> String:
	## sdf < 0 is water; deeper (more negative) water holds deep fish.
	return "deep" if sdf < -3.0 else "shallow"

static func pick_fish(table: Dictionary, depth: String, season: int, roll: float, sea: bool = false) -> String:
	## Weighted pick among fish that live at this depth in this season. roll in 0..1. "" if none.
	var ids := []
	var total := 0.0
	for id in table:
		var f = table[id]
		if f.depth != depth or bool(f.get("legendary", false)) or bool(f.get("sea", false)) != sea:
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

static func legendary_for(table: Dictionary, depth: String, ctx: Dictionary, roll: float) -> String:
	## A legendary fish may take the hook when its rule fits: depth, enough rain, hour window, not caught yet.
	## ctx = {rain: 0..1, hour: 0..24, caught: [ids]}. roll in 0..1 against the fish's chance.
	for id in table:
		var f: Dictionary = table[id]
		if not bool(f.get("legendary", false)) or f.depth != depth or id in ctx.get("caught", []) or bool(f.get("sea", false)) != bool(ctx.get("sea", false)):
			continue
		var hrs: Array = f.get("hours", [0, 24])
		var h: float = float(ctx.get("hour", 12.0))
		if float(ctx.get("rain", 0.0)) >= float(f.get("min_rain", 0.0)) and h >= float(hrs[0]) and h < float(hrs[1]) and roll < float(f.get("chance", 0.05)):
			return id
	return ""

func cast(sdf: float, table: Dictionary, season: int, bait: Dictionary = {}, ctx: Dictionary = {}) -> bool:
	## Only on water. Picks the fish now so bite time and difficulty are fixed per cast.
	if state != State.IDLE or sdf >= 0.0:
		return false
	fish_id = pick_fish(table, depth_for(sdf), season, rng.randf(), bool(ctx.get("sea", false)))
	var lg := legendary_for(table, depth_for(sdf), ctx, rng.randf())
	if lg != "":
		fish_id = lg
	if fish_id == "":
		return false
	difficulty = float(table[fish_id].difficulty)
	timer = rng.randf_range(BITE_MIN, BITE_MAX) * float(bait.get("bite_mult", 1.0)) * bite_time_mult(float(ctx.get("hour", 12.0)), float(ctx.get("rain", 0.0)))
	bar_size = BAR_SIZE + float(bait.get("bar_bonus", 0.0)) + (BEGINNER_BONUS if int(ctx.get("caught_count", 99)) < BEGINNER_CATCHES else 0.0)
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
		treasure_on = false
		treasure_got = false
		treasure_prog = 0.0
		treasure_in = rng.randf_range(1.0, 3.0) if rng.randf() < TREASURE_CHANCE else -1.0
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
	_treasure(delta)
	if progress >= 1.0:
		state = State.CAUGHT
	elif progress <= 0.0:
		state = State.LOST

func _treasure(delta: float) -> void:
	if treasure_in > 0.0:
		treasure_in -= delta
		if treasure_in <= 0.0:
			treasure_on = true
			treasure_pos = rng.randf_range(0.15, 0.85)
	if not treasure_on:
		return
	if absf(bar - treasure_pos) <= bar_size / 2.0:
		treasure_prog += TREASURE_FILL * delta
	else:
		treasure_prog = maxf(0.0, treasure_prog - TREASURE_DRAIN * delta)
	if treasure_prog >= 1.0:
		treasure_got = true
		treasure_on = false

static func treasure_loot(roll: float, roll2: float) -> Dictionary:
	## {id, n}: id "$" means money. roll picks the entry by weight, roll2 the amount.
	var total := 0.0
	for e in TREASURE_LOOT:
		total += float(e[0])
	var acc := 0.0
	for e in TREASURE_LOOT:
		acc += float(e[0]) / total
		if roll <= acc:
			return {"id": String(e[1]), "n": int(round(lerpf(float(e[2]), float(e[3]), clampf(roll2, 0.0, 1.0))))}
	var last: Array = TREASURE_LOOT[TREASURE_LOOT.size() - 1]
	return {"id": String(last[1]), "n": int(last[2])}

func overlapping() -> bool:
	return absf(bar - fish_pos) <= bar_size / 2.0

static func bite_time_mult(hour: float, rain: float) -> float:
	## Waiting-time multiplier (below 1 = quicker bites): fish feed at dawn and dusk, sulk in the midday glare,
	## and rain stirs them up.
	var m := 1.0
	if (hour >= 5.0 and hour < 8.0) or (hour >= 17.0 and hour < 20.0):
		m = 0.75
	elif hour >= 11.0 and hour < 15.0:
		m = 1.15
	return m * (1.0 - 0.15 * clampf(rain, 0.0, 1.0))

static func pick_bait(bait: Dictionary, inv) -> String:
	## Best bait (lowest bite multiplier) the bag holds, or "".
	var best := ""
	var bm := 9.0
	for id in bait:
		if inv.count(id) > 0 and float(bait[id].bite_mult) < bm:
			bm = float(bait[id].bite_mult)
			best = id
	return best

static func pick_rod(rods: Dictionary, inv) -> String:
	## Best rod upgrade owned (lowest bite multiplier), or "" for the starter rod.
	return pick_bait(rods, inv)

static func combine(rod: Dictionary, bait: Dictionary) -> Dictionary:
	## Rod and bait stack: bite multipliers multiply, bar bonuses add (bar capped by BAR_SIZE+0.3).
	return {
		"bite_mult": float(rod.get("bite_mult", 1.0)) * float(bait.get("bite_mult", 1.0)),
		"bar_bonus": minf(float(rod.get("bar_bonus", 0.0)) + float(bait.get("bar_bonus", 0.0)), 0.3),
	}
