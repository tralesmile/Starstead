class_name NpcView
extends Node2D
## Spawns the townsfolk from data/npcs.json and walks them along their schedule.
## Visual only (no collision): they stay on land via NpcSchedule.safe_step. Sprites reuse the
## player sheet with a per-NPC tint until dedicated NPC art exists.

const SPEED := 38.0
const TINTS := {
	"farmer": Color(1.0, 0.85, 0.6),
	"shopkeeper": Color(0.7, 0.85, 1.0),
	"fisher": Color(0.7, 1.0, 0.85),
	"mechanic": Color(1.0, 0.7, 0.7),
}

var gen: WorldGen
var world: Node2D
var data: Dictionary
var actors: Array = []  # {npc, node, sprite, face, t, goal, path}
var grid: AStarGrid2D

func setup(w: Node2D, g: WorldGen) -> void:
	world = w
	gen = g
	data = DataDB.load_json("npcs")
	grid = NpcPath.build(WorldGen.SIZE, _land_cell)
	for n in data["npcs"]:
		_spawn(n)

func _land_cell(c: Vector2i) -> bool:
	return c.x > 0 and c.y > 0 and c.x < WorldGen.SIZE - 1 and c.y < WorldGen.SIZE - 1 and gen.sdf_at(c.x, c.y) >= 1.2 and not (c in gen.trees) and not (c in gen.rocks)

func _land_point(p: Vector2) -> bool:
	return _land_cell(Vector2i(floori(p.x / 32.0), floori(p.y / 32.0)))

func cell_for(npc: Dictionary, hour: float) -> Vector2i:
	var c := NpcSchedule.target_cell(npc, hour, data["places"])
	return NpcSchedule.snap_to_land(c, _land_cell)

func _spawn(npc: Dictionary) -> void:
	var body := Node2D.new()
	var s := Sprite2D.new()
	s.texture = load("res://assets/sprites/player_hd.png")
	s.hframes = 8
	s.vframes = 4
	s.offset = Vector2(0, -22)
	s.modulate = TINTS.get(npc["id"], Color.WHITE)
	body.add_child(s)
	var sh := World.make_shadow(20)
	sh.scale = Vector2(0.6, 0.7)
	body.add_child(sh)
	var l := Label.new()
	l.text = str(npc["name"])
	l.scale = Vector2(0.5, 0.5)
	l.position = Vector2(-14, -62)
	l.add_theme_font_size_override("font_size", 12)
	body.add_child(l)
	var h := NpcSchedule.hour_of(GameState.clock.minutes)
	var start := (Vector2(cell_for(npc, h)) + Vector2(0.5, 0.6)) * 32.0
	body.position = start
	world.add_child(body)
	actors.append({"npc": npc, "node": body, "sprite": s, "face": 0, "t": 0.0, "goal": Vector2i(-1, -1), "path": [] as Array[Vector2]})

func _process(delta: float) -> void:
	var h := NpcSchedule.hour_of(GameState.clock.minutes)
	for a in actors:
		var body: Node2D = a["node"]
		var goal := cell_for(a["npc"], h)
		var before := body.position
		if goal != a["goal"]:  # new destination: plan a route around trees/rocks/water
			a["goal"] = goal
			var here := Vector2i(floori(before.x / 32.0), floori(before.y / 32.0))
			a["path"] = NpcPath.route(grid, here, goal)
		var target := (Vector2(goal) + Vector2(0.5, 0.6)) * 32.0
		var path: Array = a["path"]
		while path.size() > 1 and before.distance_to(path[0]) < 3.0:
			path.pop_front()
		if path.size() > 0:
			target = path[0]
			if path.size() == 1 and before.distance_to(target) < 1.0:
				path.clear()
		body.position = NpcSchedule.safe_step(before, target, SPEED, delta, _land_point)
		var d: Vector2 = body.position - before
		var moving := d.length() > 0.01
		a["face"] = NpcSchedule.facing_of(d, a["face"])
		a["t"] = a["t"] + delta if moving else 0.0
		var col := PlayerMath.walk_frame_hd(a["t"], moving)
		a["sprite"].frame = a["face"] * 8 + col

func near(pos: Vector2, radius: float = 40.0) -> Dictionary:
	## Closest NPC within radius of pos: {name, activity} or {}.
	var best := {}
	var bd := radius
	var h := NpcSchedule.hour_of(GameState.clock.minutes)
	for a in actors:
		var d: float = (a["node"] as Node2D).position.distance_to(pos)
		if d < bd:
			bd = d
			var e := NpcSchedule.current_entry(a["npc"], h)
			best = {"npc": a["npc"], "name": a["npc"]["name"], "activity": str(e.get("activity", "idle")), "id": a["npc"]["id"]}
	return best
