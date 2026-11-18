class_name CaveModel
extends RefCounted
## Pure mine layout for the Highlands cave (E4). A drunken-walk carver makes a connected cavern from the
## entrance at the bottom, ore nodes (copper near, coal mid, iron deep) grow on floor cells beside walls and
## respawn each day, torches hang on walls, bats sleep in the deep rooms. No nodes, no autoloads: fully testable.

const W := 48
const H := 34
const LAYOUT_SEED := 4242
const ORE_HP := {"copper": 3, "coal": 3, "iron": 5}
const ORE_DROP := {"copper": ["copper_ore", 2], "coal": ["coal", 2], "iron": ["iron_ore", 1]}
const BAT_HP := 12.0
const BAT_CONTACT := 0.9   # seconds between bites

var floor_cells: Dictionary = {}   # Vector2i -> true
var entrance := Vector2i(W / 2, H - 4)
var ores: Dictionary = {}          # cell -> {"kind", "hp"}
var torches: Array[Vector2i] = []  # wall cells that carry a torch
var bat_spawns: Array[Vector2i] = []

static func generate(day: int = 1, layout_seed: int = LAYOUT_SEED) -> CaveModel:
	var m := CaveModel.new()
	m._carve(layout_seed)
	m._torches()
	m._bats(layout_seed)
	m.refill(day)
	return m

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
	var d := depth(c)
	if d < 0.33:
		return "copper" if roll < 0.75 else "coal"
	if d < 0.62:
		return "coal" if roll < 0.45 else ("copper" if roll < 0.8 else "iron")
	return "iron" if roll < 0.6 else "coal"

func refill(day: int) -> void:
	## New ore each day (different rolls per day, same layout). Never blocks the way out.
	var r := RandomNumberGenerator.new()
	r.seed = LAYOUT_SEED * 31 + day
	ores.clear()
	var cand: Array[Vector2i] = []
	for c in floor_cells:
		if Vector2(c - entrance).length() < 6.0:
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
	var want := 22
	for c in cand:
		if ores.size() >= want:
			break
		var kind := ore_kind_for(c, r.randf())
		ores[c] = {"kind": kind, "hp": ORE_HP[kind]}
		if not reachable_all():
			ores.erase(c)

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
