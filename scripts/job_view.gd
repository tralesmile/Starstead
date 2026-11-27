class_name JobView
extends Node2D
## Work shifts in play: stand at a workplace (barn, market stall, workshop) or inside a public one and press J.
## Pays money, spends energy, advances the clock, gives xp (promotions) and reputation.

signal message(msg: String)

var model := JobModel.new(DataDB.load_json("jobs"))
var player: Node2D
var spots := {}  # place -> Vector2
var indoor_cb: Callable   # () -> id of the building whose room you are in, "" outdoors
var car: CarView          # the player's car, for the pit crew perk
var game_view := ShiftGameView.new()
var _pending := ""

func setup(p: Node2D, town_buildings: Array, stall_cell: Vector2i) -> void:
	player = p
	game_view.finished.connect(_on_game_done)
	add_child(game_view)
	for b in town_buildings:
		spots[String(b["id"])] = JobModel.door_spot(b)
	for b in CityModel.buildings() + CircuitModel.buildings():   # police, hospital, cafe, site, pit office, Sports Hall
		spots[String(b["id"])] = JobModel.door_spot(b)
	spots["stall"] = (Vector2(stall_cell) + Vector2(0.5, 1.6)) * 32.0

func job_here(radius: float = 60.0) -> String:
	var hour := 6.0 + GameState.clock.minutes / 60.0
	var rep := {"honest": GameState.rep_honest, "street": GameState.rep_street}
	var done := {}
	var inside := String(indoor_cb.call()) if indoor_cb.is_valid() else ""
	for id in model.ids():
		var pl := model.place_of(id)
		if done.has(pl) or not JobModel.in_reach(pl, inside, spots, player.position, radius):
			continue
		done[pl] = true
		var pick := model.pick_at(pl, hour, rep, GameState.energy.value, GameState.job_xp)
		if pick != "":
			return pick
	return ""

func prompt() -> String:
	var id := job_here()
	if id == "" or (car != null and car.driving):
		return ""
	var xp := int(GameState.job_xp.get(id, 0))
	return "J: Work as %s (%s) $%d" % [model.jobs[id]["name"], model.rank_name(id, xp), model.shift_pay(id, xp)]

func work() -> bool:
	if game_view.visible:
		return true
	var id := job_here()
	if id == "":
		return false
	var xp := int(GameState.job_xp.get(id, 0))
	var hour := 6.0 + GameState.clock.minutes / 60.0
	var r := model.work_shift(id, hour, {"honest": GameState.rep_honest, "street": GameState.rep_street}, GameState.energy.value, xp)
	if not r["ok"]:
		message.emit(JobModel.reason_text(String(r["reason"]), String(model.jobs[id]["name"])))
		return true
	_pending = id
	player.velocity = Vector2.ZERO
	player.set_physics_process(false)
	game_view.open(id, String(model.jobs[id].get("game", "timing")), model.rank_index(id, xp), int(r["pay"]), GameState.clock.day * 7 + id.length())
	return true

## The mini-game ended: pay scaled by how well the shift went (Esc = normal pay).
func _on_game_done(res: Dictionary) -> void:
	player.set_physics_process(true)
	var id := _pending
	_pending = ""
	if id == "" or not model.jobs.has(id):
		return
	var xp := int(GameState.job_xp.get(id, 0))
	var hour := 6.0 + GameState.clock.minutes / 60.0
	var r := model.work_shift(id, hour, {"honest": GameState.rep_honest, "street": GameState.rep_street}, GameState.energy.value, xp)
	if not r["ok"]:
		message.emit(JobModel.reason_text(String(r["reason"]), String(model.jobs[id]["name"])))
		return
	var mult := float(res.get("mult", 1.0))
	var pay := int(round(float(r["pay"]) * mult))
	var nxp := int(r["xp"]) + int(res.get("bonus_xp", 0))
	GameState.money += pay
	GameState.energy.value -= float(r["energy_cost"])
	GameState.job_xp[id] = nxp
	GameState.clock.minutes = model.minutes_after_shift(id, GameState.clock.minutes)
	if String(model.jobs[id]["rep"]["kind"]) == "street":
		GameState.rep_street += 1
	else:
		GameState.rep_honest += 1
	var perk := model.perk(id, model.rank_index(id, nxp))
	GameState.energy.value = minf(GameState.energy.value + float(perk["energy_back"]), 100.0)
	GameState.rep_honest += int(perk["rep_bonus"])
	var msg := "Shift done: +$%d" % pay
	if not bool(res.get("skipped", false)):
		msg = "%s! " % String(res.get("grade", "")).trim_suffix("!") + msg
		if bool(res.get("perfect", false)):
			GameState.bump("perfect_shifts")
	if String(perk["item"]) != "":
		var q := int(perk["qty"]) + (1 if bool(res.get("perfect", false)) else 0)
		GameState.add_item(String(perk["item"]), q)
		msg += "  +%d %s" % [q, String(perk["item"]).replace("_", " ")]
	if car != null and float(perk["car_fuel"]) > 0.0:
		var s := JobModel.service_car(car.fuel, car.health, perk)
		car.fuel = s["fuel"]
		car.health = s["health"]
		msg += "  Crew serviced your car (fuel %d%%, health %d%%)" % [int(100.0 * car.fuel / VehicleMath.FUEL_MAX), int(car.health)]
	if float(perk["ring_window"]) > 0.0:
		msg += "  Ring training: +%.2fs to dodge" % float(perk["ring_window"])
	if model.rank_index(id, nxp) > model.rank_index(id, xp):
		GameState.bump("promotions")
		msg += "  PROMOTED to %s!" % model.rank_name(id, nxp)
	message.emit(msg)

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo and e.keycode == KEY_J:
		if not player.is_physics_processing():
			return   # driving, a menu or a door fade has the player
		if work():
			get_viewport().set_input_as_handled()   # J is also the fish journal: a shift wins at a workplace
