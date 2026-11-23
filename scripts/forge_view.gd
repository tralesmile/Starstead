class_name ForgeView
extends CookView
## Workshop anvil: forge vests and car parts from bars (data/forge.json). Gear is carried in the bag.

func _init() -> void:
	super._init()
	recipes = DataDB.load_json("forge")
	title = "Anvil - click gear or press its number"
	footer = "Bars come from the furnace. Carried gear works from your bag.   E / Esc: leave"
	done_word = "Forged"

func _try(i: int) -> void:
	var ids := recipes.keys()
	if i < 0 or i >= ids.size():
		return
	var r: Dictionary = recipes[ids[i]]
	var err := ToolKit.craft(GameState.tools_owned, r, GameState.bag)
	if err == "":
		_spark_t = 0.0
		msg = "%s %s!" % [done_word, r["name"]]
		cooked.emit(String(r["name"]))
	else:
		msg = err

var _spark_t := 99.0

func _process(d: float) -> void:
	super._process(d)
	_spark_t += d

func _draw_all() -> void:
	super._draw_all()
	if _spark_t > 0.7:
		return
	var o := ORIGIN + Vector2(170, -40)
	for i in 14:
		var p := GearModel.spark_pos(o, GearModel.spark_velocity(i, 14), _spark_t)
		var a := clampf(1.0 - _spark_t / 0.7, 0.0, 1.0)
		canvas.draw_rect(Rect2(p, Vector2(2, 2)), Color(1.0, 0.75 - 0.3 * (1.0 - a), 0.25, a))
