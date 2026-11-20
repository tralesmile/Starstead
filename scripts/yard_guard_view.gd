class_name YardGuardView
extends Node2D
## Guard dogs of the Vance rocket yard (rules in YardGuard, pure and tested). Two dogs trot loops inside the fence,
## chase you when you are in the yard, bite for energy, then go back to their loop.

signal message(text: String)
var player: Node2D
var dogs: Array = []   # {node, sprite, route: Array[Vector2], idx, chase, cd, t}

func setup(p: Node2D) -> void:
	player = p
	var tex: Texture2D = load("res://assets/sprites/guard_dog.png")
	for route in YardGuard.routes():
		var px: Array = []
		for c in route:
			px.append(Vector2(c.x * 32.0 + 16.0, c.y * 32.0 + 16.0))
		var n := Node2D.new()
		n.position = px[0]
		var s := Sprite2D.new()
		s.texture = tex
		s.hframes = 2
		s.offset = Vector2(0, -10)
		n.add_child(s)
		n.add_child(World.make_shadow(18))
		add_child(n)
		dogs.append({"node": n, "sprite": s, "route": px, "idx": 1, "chase": false, "cd": 0.0, "t": 0.0})

func _process(delta: float) -> void:
	if player == null:
		return
	var pc := Vector2i(floori(player.position.x / 32.0), floori(player.position.y / 32.0))
	for d in dogs:
		var n: Node2D = d["node"]
		d["cd"] = maxf(0.0, float(d["cd"]) - delta)
		d["chase"] = YardGuard.sees(n.position, player.position, pc)
		var target: Vector2 = player.position if bool(d["chase"]) else d["route"][d["idx"]]
		var old := n.position
		n.position = YardGuard.step(n.position, target, bool(d["chase"]), delta)
		d["idx"] = YardGuard.next_waypoint(int(d["idx"]), n.position, d["route"])
		d["t"] = float(d["t"]) + delta * (8.0 if bool(d["chase"]) else 4.0)
		var s: Sprite2D = d["sprite"]
		s.frame = int(d["t"]) % 2
		if absf(n.position.x - old.x) > 0.01:
			s.flip_h = n.position.x < old.x
		if YardGuard.can_bite(n.position, player.position, float(d["cd"])) and bool(d["chase"]):
			d["cd"] = YardGuard.BITE_COOLDOWN
			GameState.energy.value = maxf(0.0, GameState.energy.value - YardGuard.BITE_COST)
			if player.has_method("push"):
				player.push(n.position, 1.2)
			if player.has_method("shake"):
				player.shake(1.5, 0.2)
			message.emit("A guard dog bit you! -%d energy" % int(YardGuard.BITE_COST))
