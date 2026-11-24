class_name RobberyView
extends Node
## Break into town buildings: E picks the lock, then E loots one item at a time. Noise wakes residents (police heat).

signal message(msg: String)
signal alarm_rang(id: String)

var model := RobberyModel.new()
var rng := RandomNumberGenerator.new()
var town: TownView
var world: Node2D
var police: PoliceView
var player: Node2D
var active := ""        # house id currently being robbed
var alerted := false
var indoors_cb: Callable   # () -> id of the home the player stands in ("" outside / public building)
var sneaking_cb: Callable  # () -> Array[bool] [moving, sprinting, sneaking]

func setup(t: TownView, w: Node2D, p: PoliceView, pl: Node2D) -> void:
	town = t
	world = w
	police = p
	player = pl
	rng.randomize()

func building_at(cell: Vector2i) -> Dictionary:
	for b in town.buildings:
		if b["door"] == cell:
			return b
	return {}

func _process(delta: float) -> void:
	var pc := Vector2i(floori(player.position.x / 32.0), floori(player.position.y / 32.0))
	if active != "":
		var b := building_at(pc)
		if b.is_empty() or str(b["id"]) != active:
			if model.noise <= 0.0:
				active = ""
	var inside: String = String(indoors_cb.call()) if indoors_cb.is_valid() else ""
	if inside != "":
		active = inside
		var st: Array = sneaking_cb.call() if sneaking_cb.is_valid() else [false, false, false]
		model.tick_steps(inside, delta, bool(st[0]), bool(st[1]), bool(st[2]))
		if model.alarm_check(inside):
			_alarm(inside)
	model.tick(active if active != "" else "none", delta, false, false)
	if active != "" and model.residents_awake() and not alerted:
		alerted = true
		police.add_heat(WantedMath.crime_heat("trespass"))
		message.emit("A light turns on! Residents saw you")
	if model.noise <= 0.0:
		alerted = false
	for b in town.buildings:
		world.interactables.cells[b["door"]]["prompt"] = _prompt(b)

func _prompt(b: Dictionary) -> String:
	if String(b["id"]) in InteriorModel.PUBLIC:
		return "E: Enter %s" % b["name"]
	var h := model.house(str(b["id"]))
	if h["locked"]:
		return "E: Pick lock %s (%d%%)" % [b["name"], int(100.0 * model.pick_chance(int(h["lock_level"]), GameState.rep_street / 10))]
	if not h["locked"] and not (String(b["id"]) in InteriorModel.PUBLIC) and not (h["looted"] or h["loot"].is_empty()):
		return "E: Enter %s (unlocked)" % b["name"]
	if h["looted"] or h["loot"].is_empty():
		return "%s: nothing left" % b["name"]
	return "E: Loot %s (%d left)  noise %d" % [b["name"], h["loot"].size(), int(model.noise)]

func _alarm(id: String) -> void:
	alerted = true
	police.add_heat(float(model.cfg["alarm"]["heat"]))
	alarm_rang.emit(id)
	message.emit("ALARM! The siren is wailing")

func crack_safe(b: Dictionary) -> void:
	var id := str(b["id"])
	var h := model.house(id)
	if not h["safe"] or h["safe_open"]:
		message.emit("The safe is empty")
		return
	var cash := model.crack_safe(id, GameState.rep_street / 10, rng)
	if cash < 0:
		message.emit("The dial slips (%d%% chance). Noise!" % int(100.0 * model.safe_chance(GameState.rep_street / 10)))
		return
	GameState.money += cash
	GameState.rep_street += 3
	message.emit("Click-click-clunk! $%d from the safe" % cash)

func cut_alarm(b: Dictionary) -> void:
	var id := str(b["id"])
	var h := model.house(id)
	if not h["alarm_armed"]:
		message.emit("The alarm is already dead")
		return
	var sk: int = GameState.rep_street / 10
	if model.cut_alarm(id, sk, rng):
		message.emit("Snip. The alarm goes quiet")
	else:
		_alarm(id)

func interact(cell: Vector2i) -> void:
	var b := building_at(cell)
	if b.is_empty():
		return
	var id := str(b["id"])
	active = id
	var h := model.house(id)
	if h["locked"]:
		if model.attempt_pick(id, GameState.rep_street / 10, rng):
			message.emit("Click! The lock gives")
		else:
			message.emit("The pick snaps. Noise!")
		return
	var item := model.loot_item(id)
	if item == "":
		message.emit("Nothing left to take")
		return
	var v := model.loot_value(item)
	GameState.money += v
	GameState.rep_street += 1
	message.emit("Took %s ($%d)" % [item, v])
	if h["looted"]:
		model.finish_robbery(id, rng)
		police.add_heat(WantedMath.crime_heat("robbery") * (1.0 if alerted else 0.25))
		message.emit("House cleaned out. They will remember.")
