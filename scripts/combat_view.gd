class_name CombatView
extends Node2D
## Melee in play: the club swing hits townsfolk and cops in a cone, flashes them, knocks them
## back (HitMath) and knocks them out for a few seconds. Every hit is an assault crime.

signal message(msg: String)

var world: Node2D
var player: Player
var npcs: NpcView
var police: PoliceView
var cd := 0.0
var foes := {}  # Node2D -> {hp, down, kv, bar, sprite}

func setup(w: Node2D, p: Player, n: NpcView, pol: PoliceView) -> void:
	world = w
	player = p
	npcs = n
	police = pol

func _state(node: Node2D, sprite: Sprite2D) -> Dictionary:
	if not foes.has(node):
		var bar := ColorRect.new()
		bar.size = Vector2(16, 2)
		bar.position = Vector2(-8, -54)
		bar.color = Color(0.9, 0.2, 0.2)
		bar.visible = false
		node.add_child(bar)
		foes[node] = {"hp": CombatModel.MAX_HP, "down": 0.0, "kv": Vector2.ZERO, "bar": bar, "sprite": sprite}
	return foes[node]

func attack(weapon_id: String) -> int:
	## Swing now; returns how many people were hit (0 while on cooldown).
	if cd > 0.0:
		return 0
	var w := CombatModel.weapon(weapon_id)
	cd = CombatModel.cooldown(weapon_id)
	var face := CombatModel.facing_vec(player.facing)
	var origin := player.position + Vector2(0, -8)
	var hits := 0
	var targets: Array = []
	for a in npcs.actors:
		targets.append([a["node"], a["sprite"], false])
	for c in police.cops:
		var spr: Sprite2D = (c as Node2D).get_child(0) as Sprite2D
		targets.append([c, spr, true])
	for t in targets:
		var node: Node2D = t[0]
		if not is_instance_valid(node):
			continue
		var s := _state(node, t[1])
		if float(s["down"]) > 0.0:
			continue
		if not CombatModel.in_swing(origin, face, node.position + Vector2(0, -8), float(w["range"])):
			continue
		hits += 1
		s["hp"] = CombatModel.hit(float(s["hp"]), float(w["dmg"]))
		s["kv"] = HitMath.knockback(player.position, node.position, float(w["force"]))
		s["flash"] = 0.12
		(s["bar"] as ColorRect).visible = true
		(s["bar"] as ColorRect).size.x = 16.0 * float(s["hp"]) / CombatModel.MAX_HP
		if CombatModel.is_down(float(s["hp"])):
			s["down"] = CombatModel.DOWN_SECONDS
			(s["sprite"] as Sprite2D).rotation = PI * 0.5
			message.emit("Knocked out!")
		police.commit(CombatModel.crime_for("npc"), node.position)
		GameState.rep_honest = maxi(0, GameState.rep_honest - 1)
	if hits > 0:
		player.shake(1.0, 0.1)
		Engine.time_scale = 0.1
		get_tree().create_timer(HitMath.hitstop(float(w["force"])), true, false, true).timeout.connect(func(): Engine.time_scale = 1.0)
	return hits

func _process(delta: float) -> void:
	cd = maxf(0.0, cd - delta)
	for node in foes.keys():
		if not is_instance_valid(node):
			foes.erase(node)
			continue
		var s: Dictionary = foes[node]
		var kv: Vector2 = s["kv"]
		if kv.length() > 1.0:
			var np: Vector2 = node.position + kv * delta
			if npcs._land_point(np):
				node.position = np
			else:
				s["kv"] = Vector2.ZERO
			s["kv"] = HitMath.decay(s["kv"], delta)
		var spr: Sprite2D = s["sprite"]
		var fl := float(s.get("flash", 0.0))
		if fl > 0.0:
			s["flash"] = fl - delta
			spr.modulate = Color(2.2, 2.2, 2.2)
		elif spr.modulate.r > 1.0:
			spr.modulate = npcs.TINTS.get(_npc_id(node), Color.WHITE)
		if float(s["down"]) > 0.0:
			s["down"] = CombatModel.recover(float(s["down"]), delta)
			if float(s["down"]) <= 0.0:
				s["hp"] = CombatModel.stand_hp()
				spr.rotation = 0.0
				(s["bar"] as ColorRect).visible = false

func _npc_id(node: Node2D) -> String:
	for a in npcs.actors:
		if a["node"] == node:
			return String(a["npc"]["id"])
	return ""

func is_down(node: Node2D) -> bool:
	return foes.has(node) and float(foes[node]["down"]) > 0.0
