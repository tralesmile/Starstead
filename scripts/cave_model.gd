class_name CaveModel
extends RefCounted
## Pure mine layout for the Highlands cave (E4). A drunken-walk carver makes a connected cavern from the
## entrance at the bottom, ore nodes (copper near, coal mid, iron deep) grow on floor cells beside walls and
## respawn each day, torches hang on walls, bats sleep in the deep rooms. No nodes, no autoloads: fully testable.

const W := 48
const H := 34
const LAYOUT_SEED := 4242
const ORE_HP := {"copper": 3, "coal": 3, "iron": 5, "silver": 5, "gold": 6}
const ORE_DROP := {"copper": ["copper_ore", 2], "coal": ["coal", 2], "iron": ["iron_ore", 1], "silver": ["silver_ore", 1], "gold": ["gold_ore", 1]}
const BAT_HP := 12.0
const BAT_CONTACT := 0.9   # seconds between bites
const MAX_FLOOR := 6
const BOSS_FLOOR := 6       # the Warden's Hall: a round arena under the deepest mine floor
const SILVER_FROM := 3
const GOLD_FROM := 4
const VEIN_MAX := 4
const HALL_CENTRE := Vector2i(W / 2, 13)
const HALL_RADIUS := Vector2(13.5, 9.5)
const RAIL_MIN := 8         # shorter paths get no track
const SLIME_HP := 18.0
const CRAB_HP := 36.0

var floor_no := 1
var ladder_down := Vector2i(-1, -1)   # deepest floor cell; (-1,-1) on the last floor
var slime_spawns: Array[Vector2i] = []
var crab_spawns: Array[Vector2i] = []
var rail: Array[Vector2i] = []   # mine-cart track from near the entrance to near the ladder down (4-neighbour steps)

var floor_cells: Dictionary = {}   # Vector2i -> true
var entrance := Vector2i(W / 2, H - 4)
var ores: Dictionary = {}          # cell -> {"kind", "hp"}
var torches: Array[Vector2i] = []  # wall cells that carry a torch
var bat_spawns: Array[Vector2i] = []

static func generate(day: int = 1, floor_no: int = 1, layout_seed: int = LAYOUT_SEED) -> CaveModel:
	## Floor 1 keeps the original layout; every floor below has its own seed, more ore and tougher monsters.
	var m := CaveModel.new()
	m.floor_no = clampi(floor_no, 1, MAX_FLOOR)
	var sd := layout_seed + (m.floor_no - 1) * 977
	if m.is_boss_floor():
		m._carve_hall()
		m._torches()
	else:
		m._carve(sd)
		m._torches()
		m._bats(sd)
		m._ladder()
		m._monsters(sd)
		m._lay_rail()
	m.refill(day)
	return m

static func floor_bias(f: int) -> float:
	## Added to the depth of a cell so deeper floors give iron-rich veins.
	return (clampi(f, 1, MAX_FLOOR) - 1) * 0.18

static func monster_counts(f: int) -> Dictionary:
	## Bats from floor 1, slimes from floor 2, rock crabs from floor 3. The boss fights alone.
	var fl := clampi(f, 1, MAX_FLOOR)
	if fl == BOSS_FLOOR:
		return {"bat": 0, "slime": 0, "crab": 0}
	return {"bat": 5, "slime": 0 if fl < 2 else 2 + fl, "crab": 0 if fl < 3 else fl - 1}

func is_boss_floor() -> bool:
	return floor_no == BOSS_FLOOR

func boss_spawn() -> Vector2i:
	return HALL_CENTRE + Vector2i(0, -3)

func _carve_hall() -> void:
	## A wide round hall with a straight corridor down to the ladder you came in by.
	for y in range(2, H - 2):
		for x in range(2, W - 2):
			var d := Vector2(x - HALL_CENTRE.x, y - HALL_CENTRE.y) / HALL_RADIUS
			if d.length() <= 1.0:
				floor_cells[Vector2i(x, y)] = true
	for y in range(HALL_CENTRE.y, entrance.y + 2):
		for dx in range(-2, 3):
			floor_cells[Vector2i(entrance.x + dx, y)] = true

func _lay_rail() -> void:
	## Shortest walk from just above the entrance to just short of the ladder, preferring straight runs.
	rail.clear()
	if not has_ladder_down():
		return
	var start := entrance + Vector2i(2, -1)
	if not floor_cells.has(start):
		start = entrance + Vector2i(0, -1)
	var dirs: Array[Vector2i] = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1)]
	var cost := {}
	var came := {}
	var open: Array = [[0, start, -1]]   # [cost, cell, direction index]
	cost[Vector3i(start.x, start.y, -1)] = 0
	var goal_key = null
	while not open.is_empty():
		var bi := 0
		for i in range(1, open.size()):
			if int(open[i][0]) < int(open[bi][0]):
				bi = i
		var cur: Array = open[bi]
		open[bi] = open[open.size() - 1]
		open.pop_back()
		var c: Vector2i = cur[1]
		var di: int = cur[2]
		var key := Vector3i(c.x, c.y, di)
		if int(cur[0]) > int(cost[key]):
			continue
		if absi(c.x - ladder_down.x) + absi(c.y - ladder_down.y) == 2:
			goal_key = key
			break
		for i in 4:
			var n: Vector2i = c + dirs[i]
			if not floor_cells.has(n) or n == ladder_down:
				continue
			if di >= 0 and dirs[i] == -dirs[di]:
				continue
			var step_cost := 10 + (0 if i == di or di < 0 else 14)
			# keep the track off the walls where there is room
			for o in dirs:
				if not floor_cells.has(n + o):
					step_cost += 3
			var nk := Vector3i(n.x, n.y, i)
			var nc := int(cur[0]) + step_cost
			if not cost.has(nk) or nc < int(cost[nk]):
				cost[nk] = nc
				came[nk] = key
				open.append([nc, n, i])
	if goal_key == null:
		return
	var k: Vector3i = goal_key
	while true:
		rail.push_front(Vector2i(k.x, k.y))
		if not came.has(k):
			break
		k = came[k]
	if rail.size() < RAIL_MIN:
		rail.clear()

func on_rail(c: Vector2i) -> bool:
	return rail.has(c)

func rare_kind(base: String, roll: float) -> String:
	## Silver replaces some ore from floor 3, gold from floor 4; richer the deeper you go.
	var gold := 0.0 if floor_no < GOLD_FROM else 0.10 + 0.04 * (floor_no - GOLD_FROM)
	var silver := 0.0 if floor_no < SILVER_FROM else 0.16
	if roll < gold:
		return "gold"
	if roll < gold + silver:
		return "silver"
	return base

func has_ladder_down() -> bool:
	return ladder_down.x >= 0

func _ladder() -> void:
	if floor_no >= MAX_FLOOR:
		return
	var best := entrance
	var bd := -1.0
	for c in floor_cells:
		var d := Vector2(c - entrance).length()
		if d > bd or (is_equal_approx(d, bd) and (c.y < best.y or (c.y == best.y and c.x < best.x))):
			bd = d
			best = c
	ladder_down = best

func _monsters(sd: int) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = sd + 13
	var cand: Array[Vector2i] = []
	for c in floor_cells:
		if depth(c) > 0.25 and Vector2(c - ladder_down).length() > 4.0:
			cand.append(c)
	cand.sort()
	if cand.is_empty():
		return
	var cnt := monster_counts(floor_no)
	for i in int(cnt["slime"]):
		slime_spawns.append(cand[r.randi_range(0, cand.size() - 1)])
	for i in int(cnt["crab"]):
		crab_spawns.append(cand[r.randi_range(0, cand.size() - 1)])

func is_floor(c: Vector2i) -> bool:
	return floor_cells.has(c)

func is_solid(c: Vector2i) -> bool:
	## Walls and un-mined ore block movement; anything outside the grid is wall.
	return not floor_cells.has(c) or ores.has(c)

func _carve(sd: int) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = sd
	var pos := entrance
	for dx in range(-2, 3):
		for dy in range(-1, 2):
			floor_cells[entrance + Vector2i(dx, dy)] = true
	var target := int(W * H * 0.34)
	var heading := Vector2i(0, -1)
	var steps := 0
	while floor_cells.size() < target and steps < 6000:
		steps += 1
		if r.randf() < 0.22:
			heading = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, -1)][r.randi_range(0, 3)]
		var nxt := pos + heading
		if nxt.x < 3 or nxt.x > W - 4 or nxt.y < 3 or nxt.y > H - 4:
			heading = Vector2i(0, -1) if pos.y > H / 2 else [Vector2i(1, 0), Vector2i(-1, 0)][r.randi_range(0, 1)]
			if r.randf() < 0.3:
				pos = floor_cells.keys()[r.randi_range(0, floor_cells.size() - 1)]
			continue
		pos = nxt
		var rad := 1
		if steps % 40 == 0:
			rad = r.randi_range(3, 4)   # a chamber
		for dx in range(-rad, rad + 1):
			for dy in range(-rad, rad + 1):
				if dx * dx + dy * dy <= rad * rad + 1:
					var c := pos + Vector2i(dx, dy)
					if c.x >= 2 and c.x <= W - 3 and c.y >= 2 and c.y <= H - 3:
						floor_cells[c] = true

func depth(c: Vector2i) -> float:
	## 0 at the entrance, 1 at the far end.
	return clampf(Vector2(c - entrance).length() / 34.0, 0.0, 1.0)

func ore_kind_for(c: Vector2i, roll: float) -> String:
	var d := clampf(depth(c) + floor_bias(floor_no), 0.0, 1.0)
	if d < 0.33:
		return "copper" if roll < 0.75 else "coal"
	if d < 0.62:
		return "coal" if roll < 0.45 else ("copper" if roll < 0.8 else "iron")
	return "iron" if roll < 0.6 else "coal"

func refill(day: int) -> void:
	## New ore each day (different rolls per day, same layout). Never blocks the way out.
	var r := RandomNumberGenerator.new()
	r.seed = (LAYOUT_SEED + (floor_no - 1) * 977) * 31 + day
	ores.clear()
	var cand: Array[Vector2i] = []
	for c in floor_cells:
		if Vector2(c - entrance).length() < 6.0 or Vector2(c - ladder_down).length() < 3.0:
			continue
		var wall_n := 0
		for o in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			if not floor_cells.has(c + o):
				wall_n += 1
		if wall_n >= 1:
			cand.append(c)
	cand.sort()
	for i in range(cand.size() - 1, 0, -1):
		var j := r.randi_range(0, i)
		var t := cand[i]
		cand[i] = cand[j]
		cand[j] = t
	var want := 22 + (floor_no - 1) * 3
	if is_boss_floor():
		want = 10
	var wall_set := {}
	for c in cand:
		wall_set[c] = true
	# ore grows in veins: a seed cell, then neighbours along the same wall carry the same metal
	for c in cand:
		if ores.size() >= want:
			break
		if ores.has(c) or rail.has(c):
			continue
		var kind := rare_kind(ore_kind_for(c, r.randf()), r.randf())
		if is_boss_floor():
			kind = "gold" if r.randf() < 0.4 else "silver"
		if not _try_ore(c, kind):
			continue
		var size := r.randi_range(1, VEIN_MAX)
		var frontier: Array[Vector2i] = [c]
		var grown := 1
		while grown < size and not frontier.is_empty() and ores.size() < want:
			var from: Vector2i = frontier.pop_front()
			for o in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var n: Vector2i = from + o
				if grown < size and ores.size() < want and wall_set.has(n) and not ores.has(n) and not rail.has(n) and _try_ore(n, kind):
					frontier.append(n)
					grown += 1

func _try_ore(c: Vector2i, kind: String) -> bool:
	ores[c] = {"kind": kind, "hp": ORE_HP[kind]}
	if not reachable_all():
		ores.erase(c)
		return false
	return true

func reachable_all() -> bool:
	## True when every floor cell without ore can be reached from the entrance.
	var seen := {entrance: true}
	var q: Array[Vector2i] = [entrance]
	var free := 0
	for c in floor_cells:
		if not ores.has(c):
			free += 1
	while not q.is_empty():
		var c: Vector2i = q.pop_back()
		for o in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = c + o
			if floor_cells.has(n) and not ores.has(n) and not seen.has(n):
				seen[n] = true
				q.append(n)
	return seen.size() == free

func _torches() -> void:
	## A torch on every wall cell that has floor to its south, spaced out along the walls.
	var cand: Array[Vector2i] = []
	for c in floor_cells:
		var up: Vector2i = c + Vector2i(0, -1)
		if not floor_cells.has(up):
			cand.append(up)
	cand.sort()
	for c in cand:
		var ok := true
		for t in torches:
			if Vector2(c - t).length() < 7.0:
				ok = false
				break
		if ok:
			torches.append(c)

func _bats(sd: int) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = sd + 7
	var cand: Array[Vector2i] = []
	for c in floor_cells:
		if depth(c) > 0.4:
			cand.append(c)
	cand.sort()
	if cand.is_empty():
		return
	for i in 5:
		bat_spawns.append(cand[r.randi_range(0, cand.size() - 1)])

func hit_ore(cell: Vector2i, power: int) -> Dictionary:
	## {} when no ore, {"hit":true,"hp"} when damaged, {"id","n","kind"} when it breaks.
	if not ores.has(cell):
		return {}
	var n: Dictionary = ores[cell]
	n["hp"] = int(n["hp"]) - maxi(power, 1)
	if int(n["hp"]) > 0:
		return {"hit": true, "hp": n["hp"]}
	ores.erase(cell)
	var d: Array = ORE_DROP[n["kind"]]
	return {"id": d[0], "n": d[1], "kind": n["kind"]}

## --- bats (pure steering) ---
static func bat_step(bat: Dictionary, target: Vector2, dt: float) -> void:
	## bat: {pos, vel, hp, cd, down}. Chases within 220px with a wobble, sleeps beyond 320.
	bat["cd"] = maxf(0.0, float(bat["cd"]) - dt)
	if float(bat["down"]) > 0.0:
		bat["down"] = maxf(0.0, float(bat["down"]) - dt)
		bat["vel"] = Vector2.ZERO
		return
	var to: Vector2 = target - bat["pos"]
	var dist := to.length()
	var want := Vector2.ZERO
	if dist < 220.0 and dist > 0.5:
		var side := Vector2(-to.y, to.x).normalized() * sin(float(bat.get("t", 0.0)) * 5.0) * 0.6
		want = (to.normalized() + side).normalized() * 70.0
	bat["t"] = float(bat.get("t", 0.0)) + dt
	bat["vel"] = (bat["vel"] as Vector2).move_toward(want, 420.0 * dt)
	bat["pos"] = (bat["pos"] as Vector2) + (bat["vel"] as Vector2) * dt

static func bat_bite(bat: Dictionary, target: Vector2) -> float:
	## Energy lost when the bat touches the player (0 when on cooldown, knocked out or far).
	if float(bat["cd"]) > 0.0 or float(bat["down"]) > 0.0:
		return 0.0
	if (bat["pos"] as Vector2).distance_to(target) > 18.0:
		return 0.0
	bat["cd"] = BAT_CONTACT
	return 5.0

static func new_bat(p: Vector2) -> Dictionary:
	return {"pos": p, "vel": Vector2.ZERO, "hp": BAT_HP, "cd": 0.0, "down": 0.0, "t": p.x * 0.01}

## --- slimes and rock crabs (pure steering, same dictionary shape as bats) ---
static func new_slime(p: Vector2) -> Dictionary:
	return {"pos": p, "vel": Vector2.ZERO, "hp": SLIME_HP, "cd": 0.0, "down": 0.0, "t": p.x * 0.013, "kind": "slime"}

static func new_crab(p: Vector2) -> Dictionary:
	return {"pos": p, "vel": Vector2.ZERO, "hp": CRAB_HP, "cd": 0.0, "down": 0.0, "t": p.y * 0.017, "kind": "crab"}

static func crawler_speed(kind: String, t: float) -> float:
	## Slimes lurch in hops (fast on the push, still on the landing); crabs scuttle slowly and steadily.
	if kind == "slime":
		var ph := fposmod(t * 2.2, 1.0)
		return 62.0 * maxf(0.0, sin(ph * PI)) if ph < 0.7 else 0.0
	return 34.0

static func crawler_step(m: Dictionary, target: Vector2, dt: float) -> void:
	m["cd"] = maxf(0.0, float(m["cd"]) - dt)
	if float(m["down"]) > 0.0:
		m["down"] = maxf(0.0, float(m["down"]) - dt)
		m["pos"] = (m["pos"] as Vector2) + (m["vel"] as Vector2) * dt
		m["vel"] = (m["vel"] as Vector2).move_toward(Vector2.ZERO, 500.0 * dt)
		return
	m["t"] = float(m["t"]) + dt
	var to: Vector2 = target - m["pos"]
	var want := Vector2.ZERO
	if to.length() < 190.0 and to.length() > 0.5:
		want = to.normalized() * crawler_speed(String(m["kind"]), float(m["t"]))
	m["vel"] = (m["vel"] as Vector2).move_toward(want, 600.0 * dt)
	m["pos"] = (m["pos"] as Vector2) + (m["vel"] as Vector2) * dt

static func crawler_bite(m: Dictionary, target: Vector2) -> float:
	if float(m["cd"]) > 0.0 or float(m["down"]) > 0.0:
		return 0.0
	if (m["pos"] as Vector2).distance_to(target) > 20.0:
		return 0.0
	m["cd"] = 1.2
	return 4.0 if m["kind"] == "slime" else 7.0

static func monster_drop(kind: String, roll: float) -> Array:
	## [item, n] or [] ; slime gel is common, crab shell rarer.
	if kind == "slime" and roll < 0.8:
		return ["slime_gel", 1]
	if kind == "crab" and roll < 0.55:
		return ["crab_shell", 1]
	return []

static func crab_damage(base: float) -> float:
	## Rock crab shells soak a third of every blow.
	return base * 0.65

static func bite_force(kind: String) -> float:
	## Knockback strength on the player (HitMath.knockback force): crabs shove, bats flutter.
	return {"bat": 0.45, "slime": 0.75, "crab": 1.2}.get(kind, 0.5)

static func slime_squash(t: float) -> Vector2:
	## Sprite scale over a hop cycle: squashed on the landing, stretched tall on the push (volume ~ kept).
	var ph := fposmod(t * 2.2, 1.0)
	var k := sin(ph * TAU)
	return Vector2(1.0 - 0.18 * k, 1.0 + 0.22 * k)

static func splat_color(kind: String) -> Color:
	return {"slime": Color(0.45, 0.85, 0.35), "crab": Color(0.6, 0.58, 0.55), "bat": Color(0.35, 0.3, 0.4)}.get(kind, Color.WHITE)
