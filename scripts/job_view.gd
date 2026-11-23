class_name JobView
extends Node2D
## Work shifts in play: stand at a workplace (barn, market stall, workshop) and press J.
## Pays money, spends energy, advances the clock, gives xp (promotions) and reputation.

signal message(msg: String)

var model := JobModel.new(DataDB.load_json("jobs"))
var player: Node2D
var spots := {}  # place -> Vector2

func setup(p: Node2D, town_buildings: Array, stall_cell: Vector2i) -> void:
	player = p
	for b in town_buildings:
		spots[String(b["id"])] = TownModel.sprite_bottom_center(b) + Vector2(0, 14)
	for b in CityModel.buildings():   # police, hospital, cafe, building site
		spots[String(b["id"])] = TownModel.sprite_bottom_center(b) + Vector2(0, 14)
	spots["stall"] = (Vector2(stall_cell) + Vector2(0.5, 1.6)) * 32.0

func job_here(radius: float = 60.0) -> String:
	var hour := 6.0 + GameState.clock.minutes / 60.0
	var rep := {"honest": GameState.rep_honest, "street": GameState.rep_street}
	var done := {}
	for id in model.ids():
		var pl := model.place_of(id)
		if done.has(pl) or not spots.has(pl) or (spots[pl] as Vector2).distance_to(player.position) >= radius:
			continue
		done[pl] = true
		var pick := model.pick_at(pl, hour, rep, GameState.energy.value, GameState.job_xp)
		if pick != "":
			return pick
	return ""

func prompt() -> String:
	var id := job_here()
	if id == "":
		return ""
	var xp := int(GameState.job_xp.get(id, 0))
	return "J: Work as %s (%s) $%d" % [model.jobs[id]["name"], model.rank_name(id, xp), model.shift_pay(id, xp)]

func work() -> bool:
	var id := job_here()
	if id == "":
		return false
	var xp := int(GameState.job_xp.get(id, 0))
	var hour := 6.0 + GameState.clock.minutes / 60.0
	var r := model.work_shift(id, hour, {"honest": GameState.rep_honest, "street": GameState.rep_street}, GameState.energy.value, xp)
	if not r["ok"]:
		message.emit(JobModel.reason_text(String(r["reason"]), String(model.jobs[id]["name"])))
		return true
	GameState.money += int(r["pay"])
	GameState.energy.value -= float(r["energy_cost"])
	GameState.job_xp[id] = int(r["xp"])
	GameState.clock.minutes = model.minutes_after_shift(id, GameState.clock.minutes)
	if String(model.jobs[id]["rep"]["kind"]) == "street":
		GameState.rep_street += 1
	else:
		GameState.rep_honest += 1
	var perk := model.perk(id, model.rank_index(id, int(r["xp"])))
	GameState.energy.value = minf(GameState.energy.value + float(perk["energy_back"]), 100.0)
	GameState.rep_honest += int(perk["rep_bonus"])
	var msg := "Shift done: +$%d" % int(r["pay"])
	if String(perk["item"]) != "":
		GameState.add_item(String(perk["item"]), int(perk["qty"]))
		msg += "  +%d %s" % [int(perk["qty"]), String(perk["item"]).replace("_", " ")]
	if r["promoted"]:
		GameState.bump("promotions")
		msg += "  PROMOTED to %s!" % r["rank"]
	message.emit(msg)
	return true

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo and e.keycode == KEY_J:
		work()
