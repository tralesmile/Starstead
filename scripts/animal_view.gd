class_name AnimalView
extends Node2D
## Wild chickens and a horse roam near the start. Feed turnips (E) to build trust and tame them;
## tamed animals follow you, lay eggs / give milk each day, and the horse can be ridden.

signal message(msg: String)

const LOOK := {
	"chicken": {"y": 8, "shadow": 14},
	"horse": {"y": 14, "shadow": 28},
	"cow": {"y": 11, "shadow": 24},
	"sheep": {"y": 9, "shadow": 18},
}
const FEED_ITEM := "turnip"
var world: Node2D
var player: Player
var gen: WorldGen
var model := AnimalModel.new(DataDB.load_json("animals"))
var critters: Array = []  # {st, node, sprite, wild, prog, target, t, frames, cols}
var riding = null
var mount_stamina := 1.0
var mount_winded := false
var stamina_bar: ColorRect
var stamina_back: ColorRect
var heart: Sprite2D

func setup(w: Node2D, p: Player, g: WorldGen) -> void:
	world = w
	player = p
	gen = g
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	for st in GameState.animals:
		_spawn(String(st["id"]), _free_spot(rng, 2, 5), st)
	for id in ["chicken", "chicken", "chicken", "horse", "cow", "sheep", "sheep"]:
		_spawn(id, _free_spot(rng, 4, 12), null)

func _land(c: Vector2i) -> bool:
	if GameState.build.placed.has(c) and GameState.build.defs[GameState.build.placed[c]].solid:
		return false  # fences and walls pen animals in
	return gen.sdf_at(c.x, c.y) >= 2.0 and not (c in gen.trees) and not (c in gen.rocks) and not (c in gen.bushes) and not GameState.nodes.is_solid(c)

func _free_spot(rng: RandomNumberGenerator, rmin: int, rmax: int) -> Vector2:
	var pc := Vector2i(floori(player.position.x / 32.0), floori(player.position.y / 32.0))
	for i in 80:
		var c := pc + Vector2i(rng.randi_range(-rmax, rmax), rng.randi_range(-rmax, rmax))
		if maxi(absi(c.x - pc.x), absi(c.y - pc.y)) >= rmin and _land(c):
			return (Vector2(c) + Vector2(0.5, 0.6)) * 32.0
	return player.position + Vector2(48, 0)

func _spawn(id: String, pos: Vector2, st) -> void:
	var node := Node2D.new()
	var s := Sprite2D.new()
	var look: Dictionary = LOOK.get(id, LOOK["chicken"])
	s.texture = load("res://assets/sprites/%s.png" % (id if LOOK.has(id) else "chicken"))
	s.hframes = 2
	s.offset = Vector2(0, -float(look.y))
	node.add_child(s)
	var sh := World.make_shadow(float(look.shadow))
	sh.scale = Vector2(float(look.shadow) / 32.0, 0.7)
	node.add_child(sh)
	node.position = pos
	world.add_child(node)
	var wild: bool = st == null
	critters.append({"st": st if st != null else {}, "id": id, "node": node, "sprite": s, "wild": wild, "prog": model.new_approach(id),
		"target": pos, "t": randf() * 3.0, "step": 0.0})

func near(pos: Vector2, radius: float = 36.0) -> Dictionary:
	var best := {}
	var bd := radius
	for c in critters:
		if c == riding:
			continue
		var d: float = (c["node"] as Node2D).position.distance_to(pos)
		if d < bd:
			bd = d
			best = c
	return best

func prompt_for(c: Dictionary) -> String:
	if c.is_empty():
		return ""
	var nm := String(model.animals[c["id"]]["name"])
	if c["wild"]:
		return "E: Feed %s (%s) trust %d%%" % [nm, FEED_ITEM, int(100.0 * float(c["prog"]["trust"]) / model.trust_max())]
	if model.is_rideable(c["st"]):
		return "E: Ride %s" % nm
	return "E: Stay/follow %s" % nm if model.is_fed(c["st"]) else "E: Feed %s" % nm

func interact(c: Dictionary) -> void:
	if c.is_empty():
		return
	var nm := String(model.animals[c["id"]]["name"])
	if c["wild"]:
		if GameState.bag.count(FEED_ITEM) < 1:
			message.emit("%s wants a turnip" % nm)
			return
		GameState.bag.remove(FEED_ITEM, 1)
		model.feed_wild(c["prog"], FEED_ITEM)
		_pop_heart(c["node"])
		if model.is_tamed(c["prog"]):
			c["st"] = model.tame(c["prog"])
			c["wild"] = false
			GameState.animals.append(c["st"])
			message.emit("%s is tamed!" % nm)
		else:
			message.emit("%s trusts you more" % nm)
	elif model.is_rideable(c["st"]):
		_mount(c)
	elif GameState.bag.count(FEED_ITEM) > 0 and model.feed(c["st"], FEED_ITEM):
		GameState.bag.remove(FEED_ITEM, 1)
		_pop_heart(c["node"])
		message.emit("%s is fed" % nm)
	else:
		var st: Dictionary = c["st"]
		var stay := not bool(st.get("stay", false))
		st["stay"] = stay
		st["hx"] = (c["node"] as Node2D).position.x
		st["hy"] = (c["node"] as Node2D).position.y
		message.emit("%s stays here (fence them in for a pen)" % nm if stay else "%s follows you again" % nm)

func _mount(c: Dictionary) -> void:
	riding = c
	player.speed_mult = AnimalModel.ride_mult(model.ride_speed(c["st"]))
	mount_stamina = 1.0
	mount_winded = false
	message.emit("Riding %s - E to dismount" % model.animals[c["id"]]["name"])

func dismount() -> void:
	if riding == null:
		return
	riding["node"].position = player.position + Vector2(24, 0)
	riding = null
	player.speed_mult = 1.0
	if stamina_back != null:
		stamina_back.visible = false

func day_tick() -> void:
	for c in critters:
		if c["wild"]:
			continue
		var out := model.day_tick(c["st"])
		for item in out:
			GameState.bag.add(item, int(out[item]))
			message.emit("%s gave %s" % [model.animals[c["id"]]["name"], item])

func _pop_heart(node: Node2D) -> void:
	var h := Sprite2D.new()
	h.texture = load("res://assets/sprites/heart.png")
	h.position = Vector2(0, -26)
	h.z_index = 10
	node.add_child(h)
	var tw := create_tween()
	tw.tween_property(h, "position:y", -40.0, 0.8)
	tw.parallel().tween_property(h, "modulate:a", 0.0, 0.8)
	tw.tween_callback(h.queue_free)

func _process(delta: float) -> void:
	for c in critters:
		var node: Node2D = c["node"]
		var s: Sprite2D = c["sprite"]
		var before := node.position
		if c == riding:
			node.position = player.position + Vector2(0, 2)
			s.offset.y = -22.0
			var dv := player.velocity
			s.flip_h = dv.x < -1.0 if absf(dv.x) > 1.0 else s.flip_h
			c["step"] = c["step"] + delta * (8.0 if dv.length() > 8.0 else 0.0)
			_update_stamina(c, dv.length(), delta)
			s.frame = int(c["step"]) % 2
			continue
		s.offset.y = -float((LOOK.get(c["id"], LOOK["chicken"]) as Dictionary).y)
		var spd := float(model.animals[c["id"]]["wild_speed"])
		var move := Vector2.ZERO
		if c["wild"]:
			var tf := float(c["prog"]["trust"]) / model.trust_max()
			model.decay(c["prog"], delta)
			var dist := node.position.distance_to(player.position)
			if AnimalModel.should_flee(dist, tf):
				move = AnimalModel.flee_dir(node.position, player.position) * spd * 0.8 * delta
			else:
				c["t"] -= delta
				if c["t"] <= 0.0:
					c["t"] = randf_range(1.5, 4.0)
					var a := randf() * TAU
					c["target"] = node.position + Vector2(cos(a), sin(a)) * randf_range(10.0, 50.0)
				var d: Vector2 = c["target"] - node.position
				if d.length() > 2.0:
					move = d.normalized() * spd * 0.25 * delta
		elif bool(c["st"].get("stay", false)):
			var home := Vector2(float(c["st"].get("hx", node.position.x)), float(c["st"].get("hy", node.position.y)))
			c["t"] -= delta
			if c["t"] <= 0.0:
				c["t"] = randf_range(1.5, 4.0)
				c["target"] = AnimalModel.pen_target(home, node.position, randf() * TAU, randf_range(10.0, 40.0))
			var dd2: Vector2 = c["target"] - node.position
			if dd2.length() > 2.0:
				move = dd2.normalized() * spd * 0.25 * delta
		else:
			move = AnimalModel.follow_step(node.position, player.position, spd * 0.9, delta, 44.0 + 14.0 * critters.find(c))
		if move.length() > 0.0:
			var np := node.position + move
			if _land(Vector2i(floori(np.x / 32.0), floori(np.y / 32.0))):
				node.position = np
			elif _land(Vector2i(floori(np.x / 32.0), floori(node.position.y / 32.0))):
				node.position.x = np.x
			elif _land(Vector2i(floori(node.position.x / 32.0), floori(np.y / 32.0))):
				node.position.y = np.y
			else:
				c["t"] = 0.0
		var dd := node.position - before
		if absf(dd.x) > 0.01:
			s.flip_h = dd.x < 0.0
		if dd.length() > 0.01:
			c["step"] = c["step"] + delta * 8.0
			s.frame = int(c["step"]) % 2
		else:
			s.frame = 0

func _update_stamina(c: Dictionary, speed: float, delta: float) -> void:
	var full := AnimalModel.ride_mult(model.ride_speed(c["st"]))
	mount_stamina = MountMath.step(mount_stamina, speed, delta)
	var was := mount_winded
	mount_winded = MountMath.winded(mount_stamina, mount_winded)
	player.speed_mult = MountMath.speed_scale(mount_winded, full)
	if mount_winded and not was:
		message.emit("Your mount is winded - rest a moment")
	if stamina_back == null:
		stamina_back = ColorRect.new()
		stamina_back.color = Color(0, 0, 0, 0.6)
		stamina_back.size = Vector2(22, 4)
		stamina_back.position = Vector2(-11, -44)
		stamina_bar = ColorRect.new()
		stamina_bar.position = Vector2(1, 1)
		stamina_back.add_child(stamina_bar)
	if stamina_back.get_parent() != c["node"]:
		if stamina_back.get_parent() != null:
			stamina_back.get_parent().remove_child(stamina_back)
		(c["node"] as Node2D).add_child(stamina_back)
	stamina_back.visible = mount_stamina < 0.995
	stamina_bar.size = Vector2(20.0 * mount_stamina, 2)
	stamina_bar.color = Color(0.9, 0.35, 0.25) if mount_winded else Color(0.4, 0.85, 0.4)
