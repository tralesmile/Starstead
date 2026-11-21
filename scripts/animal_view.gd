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
	"deer": {"y": 12, "shadow": 24},
	"rabbit": {"y": 6, "shadow": 10},
	"boar": {"y": 9, "shadow": 20},
}
## Wild herd the land keeps topped up (hunted ones return over the days). id -> [count, min radius, max radius] in tiles.
const WILD := {
	"chicken": [4, 4, 14], "horse": [1, 6, 14], "cow": [2, 6, 16], "sheep": [3, 6, 16],
	"deer": [5, 10, 28], "rabbit": [7, 5, 22], "boar": [2, 14, 30],
}
const FEED_ITEM := "turnip"   # default treat; grazers also eat hay (feed_for)

func feed_for(id: String) -> String:
	## The item this animal would be fed now: hay first for grazers when the bag has some, else turnips.
	var feeds: Array = model.animals.get(id, {}).get("feed", [FEED_ITEM])
	for f in feeds:
		if GameState.bag.count(String(f)) > 0:
			return String(f)
	return FEED_ITEM
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
	for id in WILD:
		for i in int(WILD[id][0]):
			_spawn(id, _free_spot(rng, int(WILD[id][1]), int(WILD[id][2])), null)

var extra_solid: Dictionary = {}   # cell -> true: the village paddock fence (TownView) pens animals too

func _land(c: Vector2i) -> bool:
	if extra_solid.has(c):
		return false
	if GameState.build.placed.has(c) and GameState.build.defs[GameState.build.placed[c]].solid:
		return false  # fences and walls pen animals in
	return gen.sdf_at(c.x, c.y) >= 2.0 and not (c in gen.trees) and not (c in gen.rocks) and not (c in gen.bushes) and not GameState.nodes.is_solid(c)

func _free_spot(rng: RandomNumberGenerator, rmin: int, rmax: int) -> Vector2:
	var pc := Vector2i(floori(player.position.x / 32.0), floori(player.position.y / 32.0))
	for i in 160:   # second half searches a wider ring (from inside Port Halden the nearest meadow is far)
		var r := rmax if i < 80 else rmax * 3
		var c := pc + Vector2i(rng.randi_range(-r, r), rng.randi_range(-r, r))
		if maxi(absi(c.x - pc.x), absi(c.y - pc.y)) >= rmin and _land(c) and AnimalModel.wild_ok(c):
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
	if not wild and not st.has("gear"):
		st["gear"] = {}
	critters.append({"st": st if st != null else {}, "id": id, "node": node, "sprite": s, "wild": wild, "prog": model.new_approach(id),
		"target": pos, "t": randf() * 3.0, "step": 0.0, "hp": HuntModel.hp_for(model.animals, id), "rage": 0.0, "bite": 0.0})

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
	if c["wild"] and not HuntModel.tameable(model.animals, c["id"]):
		return "Swing the club or fists to hunt %s" % nm
	if c["wild"]:
		return "E: Feed %s (%s) trust %d%%" % [nm, feed_for(c["id"]), int(100.0 * float(c["prog"]["trust"]) / model.trust_max())]
	if model.is_rideable(c["st"]):
		return "E: Ride %s" % nm
	return "E: Stay/follow %s" % nm if model.is_fed(c["st"]) else "E: Feed %s" % nm

func interact(c: Dictionary) -> void:
	if c.is_empty():
		return
	var nm := String(model.animals[c["id"]]["name"])
	if c["wild"]:
		if not HuntModel.tameable(model.animals, c["id"]):
			message.emit("%s is too wild to tame - hunt it (club or fists)" % nm)
			return
		var fi := feed_for(c["id"])
		if GameState.bag.count(fi) < 1:
			message.emit("%s wants %s" % [nm, " or ".join(model.animals[c["id"]].get("feed", [FEED_ITEM]))])
			return
		GameState.bag.remove(fi, 1)
		model.feed_wild(c["prog"], fi)
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
	elif GameState.bag.count(feed_for(c["id"])) > 0 and model.feed(c["st"], feed_for(c["id"])):
		GameState.bag.remove(feed_for(c["id"]), 1)
		_pop_heart(c["node"])
		c["st"]["bond"] = mini(AnimalModel.BOND_MAX, model.bond(c["st"]) + AnimalModel.FEED_GAIN)
		message.emit("%s is fed" % nm)
	elif model.pet(c["st"], GameState.clock.day):
		_pop_heart(c["node"])
		message.emit("You pet %s: %s (bond %d)" % [nm, model.bond_tier(c["st"]), model.bond(c["st"])])
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

func hunt(origin: Vector2, face: Vector2, weapon: Dictionary) -> int:
	## A weapon swing at wild animals in the cone. Returns how many were hit; kills drop meat, hides, feathers.
	var hits := 0
	for c in critters.duplicate():
		if not c["wild"] or not HuntModel.huntable(model.animals, c["id"]):
			continue
		var node: Node2D = c["node"]
		if not CombatModel.in_swing(origin, face, node.position + Vector2(0, -6), float(weapon["range"])):
			continue
		hits += 1
		c["hp"] = CombatModel.hit(float(c["hp"]), float(weapon["dmg"]))
		node.position += HitMath.knockback(origin, node.position, float(weapon["force"])) * 0.5
		var spr: Sprite2D = c["sprite"]
		spr.modulate = Color(1.6, 0.7, 0.7)
		get_tree().create_timer(0.12).timeout.connect(func(): if is_instance_valid(spr): spr.modulate = Color.WHITE)
		if CombatModel.is_down(float(c["hp"])):
			_kill(c)
		elif HuntModel.fights_back(model.animals, c["id"]):
			c["rage"] = 6.0
	return hits

func _kill(c: Dictionary) -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var drops := HuntModel.roll_drops(model.animals, c["id"], rng)
	var parts := []
	for item in drops:
		GameState.bag.add(item, int(drops[item]))
		parts.append("%d %s" % [int(drops[item]), String(item).replace("_", " ")])
	message.emit("Hunted %s: %s" % [String(model.animals[c["id"]]["name"]).to_lower(), ", ".join(parts) if parts.size() > 0 else "nothing useful"])
	(c["node"] as Node2D).queue_free()
	critters.erase(c)

func respawn_wild(rng: RandomNumberGenerator) -> void:
	## Overnight the land restocks hunted game, out of sight of the player.
	for id in WILD:
		var have := 0
		for c in critters:
			if c["wild"] and c["id"] == id:
				have += 1
		for i in maxi(0, int(WILD[id][0]) - have):
			_spawn(id, _free_spot(rng, maxi(int(WILD[id][1]), 8), int(WILD[id][2])), null)

func day_tick() -> void:
	var rr := RandomNumberGenerator.new()
	rr.randomize()
	respawn_wild(rr)
	for c in critters:
		if c["wild"]:
			continue
		var salt := critters.find(c)
		var out := model.day_tick(c["st"], GameState.clock.day, salt)
		for item in out:
			GameState.bag.add(item, int(out[item]))
			message.emit("%s gave %s%s" % [model.animals[c["id"]]["name"], item, (" x%d (a happy one!)" % int(out[item])) if int(out[item]) > 1 else ""])

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
			if float(c["rage"]) > 0.0:
				c["rage"] = float(c["rage"]) - delta
				c["bite"] = float(c["bite"]) - delta
				move = (player.position - node.position).normalized() * spd * 0.9 * delta
				if float(c["bite"]) <= 0.0 and HuntModel.bite_damage(dist) > 0.0:
					c["bite"] = 1.0
					GameState.energy.value = maxf(0.0, GameState.energy.value - HuntModel.bite_damage(dist))
					message.emit("The boar gores you!")
			elif AnimalModel.should_flee(dist, tf, HuntModel.scare_scale(player.sneaking, player.sprinting)):
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
		if move.length() > 0.0 and bool(c.get("wild", false)) and not AnimalModel.wild_ok(Vector2i(floori((node.position.x + move.x) / 32.0), floori((node.position.y + move.y) / 32.0))):
			move = Vector2.ZERO   # wild ones turn back at the city edge
			c["t"] = 0.0
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

func gear_action() -> void:
	## G near a tamed animal: put on the next gear piece from the bag, or take everything off when nothing fits.
	var c := near(player.position)
	if c.is_empty() or c["wild"]:
		message.emit("Stand next to a tamed animal (G: gear)")
		return
	var st: Dictionary = c["st"]
	var nm := String(model.animals[c["id"]]["name"])
	var have := {}
	for id in model.gear_defs:
		have[id] = GameState.bag.count(id)
	var next := model.next_gear(st, have)
	if next != "":
		GameState.bag.remove(next, 1)
		model.equip(st, next)
		message.emit("%s wears %s" % [nm, next.replace("_", " ")])
	elif not (st["gear"] as Dictionary).is_empty():
		for slot in (st["gear"] as Dictionary).keys():
			GameState.bag.add(model.unequip(st, slot), 1)
		message.emit("%s's gear is back in your bag" % nm)
	else:
		message.emit("No gear to put on %s (saddle, fur coat, armour: buy at the shop)" % nm)
	_tint(c)

func _tint(c: Dictionary) -> void:
	var g: Dictionary = c["st"]["gear"]
	var col := Color.WHITE
	if g.has("coat"):
		col = col.lerp(Color(1.0, 0.85, 0.7), 0.5)
	if g.has("armour"):
		col = col.lerp(Color(0.8, 0.88, 1.0), 0.6)
	(c["sprite"] as Sprite2D).modulate = col
