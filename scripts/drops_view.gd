class_name DropsView
extends Node2D
## Items lying in the world: pop out of trees/rocks/crops, bob, fly to you when you are near and go into the bag.
## A full bag leaves the item on the ground.

signal picked(id: String, n: int)

var player: Node2D
var world: Node2D
var drops: Array = []  # {id, n, node, spr, pos, age, phase}
var icons: Dictionary = DataDB.load_json("item_icons")
var tex: Texture2D = load("res://assets/sprites/items.png")
var frames := 19

func setup(w: Node2D, p: Node2D) -> void:
	world = w
	player = p
	frames = maxi(1, tex.get_width() / 16)

func spawn(id: String, n: int, pos: Vector2) -> void:
	var parts := DropMath.pieces(n)
	for i in parts.size():
		var node := Node2D.new()
		var spr := Sprite2D.new()
		spr.texture = tex
		spr.hframes = frames
		spr.frame = int(icons.get(id, 0))
		spr.offset = Vector2(0, -6)
		node.add_child(spr)
		var sh := World.make_shadow(10)
		sh.scale = Vector2(0.35, 0.5)
		node.add_child(sh)
		var target := pos + DropMath.scatter(i, parts.size())
		node.position = target
		world.add_child(node)
		drops.append({"id": id, "n": int(parts[i]), "node": node, "spr": spr, "age": 0.0, "phase": randf() * TAU, "start": pos, "end": target})

func _process(delta: float) -> void:
	var keep: Array = []
	for d in drops:
		var node: Node2D = d["node"]
		d["age"] = float(d["age"]) + delta
		var age: float = d["age"]
		var spr: Sprite2D = d["spr"]
		if age < DropMath.POP_TIME:
			node.position = (d["start"] as Vector2).lerp(d["end"], age / DropMath.POP_TIME)
		elif DropMath.in_magnet(node.position, player.position, age) and GameState.bag.count(d["id"]) >= 0 and _room(d["id"]):
			node.position = DropMath.magnet_step(node.position, player.position, delta)
		spr.offset.y = -6.0 - DropMath.pop_height(age) - DropMath.bob(age, float(d["phase"]))
		if age >= DropMath.POP_TIME and DropMath.in_pickup(node.position, player.position) and _room(d["id"]):
			var left := GameState.bag.add(d["id"], int(d["n"]))
			picked.emit(d["id"], int(d["n"]) - left)
			if left <= 0:
				node.queue_free()
				continue
			d["n"] = left
		if age > DropMath.LIFETIME:
			node.queue_free()
			continue
		keep.append(d)
	drops = keep

func _room(id: String) -> bool:
	var probe := GameState.bag
	for s in probe.slots:
		if s == null or (s.id == id and s.n < probe.limit(id)):
			return true
	return false
