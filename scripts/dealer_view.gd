class_name DealerView
extends CanvasLayer
## Back-alley dealer window: W/S move, E buys, Esc closes. Street tier gates it (ReputationModel.dealer_open).

signal closed
var panel: ColorRect
var label: Label
var cursor := 0
var msg := ""
var police: PoliceView

func _init() -> void:
	layer = 8
	panel = ColorRect.new()
	panel.color = Color(0.05, 0.08, 0.05, 0.9)
	panel.position = Vector2(130, 80)
	panel.size = Vector2(380, 175)
	add_child(panel)
	label = Label.new()
	label.position = Vector2(12, 8)
	panel.add_child(label)
	visible = false

func open() -> void:
	cursor = 0
	msg = "" if ReputationModel.dealer_open(GameState.rep_street) else "Nobody sells to a Nobody. Get Known first."
	visible = true

func _stars() -> int:
	return 0 if police == null else police.stars()

func close() -> void:
	visible = false
	closed.emit()

func _unhandled_input(e: InputEvent) -> void:
	if not visible:
		return
	get_viewport().set_input_as_handled()
	if e.is_action_pressed("pause"):
		close()
	elif e.is_action_pressed("move_up"):
		cursor = posmod(cursor - 1, 2)
	elif e.is_action_pressed("move_down"):
		cursor = posmod(cursor + 1, 2)
	elif e.is_action_pressed("interact") or e.is_action_pressed("use_tool"):
		_buy()

func _buy() -> void:
	var has := GameState.bag.count("lockpick_set") > 0
	var es := DealerModel.entries(GameState.rep_street, _stars(), has)
	var id := String(es[cursor]["id"])
	var r := DealerModel.buy(id, GameState.money, GameState.rep_street, _stars(), has)
	msg = String(r["msg"])
	if not bool(r["ok"]):
		return
	if id == "lockpick_set":
		if GameState.bag.add("lockpick_set", 1) > 0:
			msg = "Bag full"
			return
	elif police != null:
		police.clear_heat()
	GameState.money = int(r["money"])

func _process(_d: float) -> void:
	if not visible:
		return
	var has := GameState.bag.count("lockpick_set") > 0
	var lines := ["Back-alley dealer   $%d" % GameState.money, ReputationModel.summary(GameState.rep_honest, GameState.rep_street), "W/S move  E buy  Esc close", ""]
	var es := DealerModel.entries(GameState.rep_street, _stars(), has)
	for i in es.size():
		lines.append("%s %s  $%d" % [">" if i == cursor else " ", es[i]["label"], es[i]["price"]])
	lines.append("")
	lines.append(msg)
	label.text = "\n".join(lines)
