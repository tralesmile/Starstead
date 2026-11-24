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
var hour_cb: Callable      # () -> hour of day
var spotters_cb: Callable  # () -> Array of {name, pos} awake residents in the room (room pixels)
var spotter := ""
var report := 0.0         # neighbours' phone-the-police meter (Neighbours)
var reported := false
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
		var hr: float = float(hour_cb.call()) if hour_cb.is_valid() else 12.0
		model.wake_override = Household.wake_threshold(float(model.cfg["noise"]["wake_threshold"]), inside, hr)
		_watch(inside, delta, bool(st[2]))
		_neighbours(inside, hr, delta)
		if model.alarm_check(inside):
			_alarm(inside)
	if inside == "":
		report = maxf(report - 0.15 * delta, 0.0)
		reported = reported and report > 0.0
		model.wake_override = -1.0
		model.suspicion = 0.0
	model.tick(active if active != "" else "none", delta, false, false)
	if active != "" and model.residents_awake() and not alerted:
		alerted = true
		police.add_heat(WantedMath.crime_heat("trespass"))
		message.emit("%s: Who's there?!" % spotter if spotter != "" else "A light turns on! Residents saw you")
	if model.noise <= 0.0:
		alerted = false
		spotter = ""
	for b in town.buildings:
		world.interactables.cells[b["door"]]["prompt"] = _prompt(b)

func _watch(id: String, delta: float, sneaking: bool) -> void:
	## Awake residents in the room notice you: suspicion climbs while one of them can see you.
	if not spotters_cb.is_valid():
		return
	var best := -0.5
	var who := ""
	for r in spotters_cb.call():
		var rate := Household.suspicion_rate((r["pos"] as Vector2).distance_to(player.position) / 32.0, sneaking)
		if rate > best:
			best = rate
			who = String(r["name"])
	model.suspicion = clampf(model.suspicion + best * delta, 0.0, 1.0)
	if model.suspicion >= 1.0 and not model.residents_awake():
		spotter = who
		model.suspicion = 0.3
		model.add_noise(100.0)

func _neighbours(inside: String, hr: float, delta: float) -> void:
	## Awake people in the OTHER homes hear loud noise through the walls and phone the police once.
	var awake := Neighbours.awake_neighbours(inside, hr, Household.cfg()["homes"].keys())
	report = Neighbours.step(report, model.noise, awake, delta)
	if Neighbours.calls(report) and not reported:
		reported = true
		police.add_heat(Neighbours.heat())
		message.emit("A neighbour heard the racket and called the police!")

func _prompt(b: Dictionary) -> String:
	if String(b["id"]) in InteriorModel.PUBLIC:
		return "E: Enter %s" % b["name"]
	var h := model.house(str(b["id"]))
	var lit := " - lights on" if Household.lights_on(str(b["id"]), NpcSchedule.hour_of(GameState.clock.minutes)) else ""
	if h["locked"]:
		return "E: Pick lock %s (%d%%)%s" % [b["name"], int(100.0 * model.pick_chance(int(h["lock_level"]), GameState.street_skill())), lit]
	if not h["locked"] and not (String(b["id"]) in InteriorModel.PUBLIC) and not (h["looted"] or h["loot"].is_empty()):
		return "E: Enter %s (unlocked)%s" % [b["name"], lit]
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
	var cash := model.crack_safe(id, GameState.street_skill(), rng)
	if cash < 0:
		message.emit("The dial slips (%d%% chance). Noise!" % int(100.0 * model.safe_chance(GameState.street_skill())))
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
	var sk: int = GameState.street_skill()
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
		if model.attempt_pick(id, GameState.street_skill(), rng):
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
