class_name ButcherView
extends CookView
## Workshop butcher block: jerky, tanned leather, snare bait and a leather vest (data/butcher.json).

func _init() -> void:
	super._init()
	recipes = DataDB.load_json("butcher")
	title = "Butcher block - click a product or press its number"
	footer = "Meat and hides come from hunting and snares.   E / Esc: leave"
	done_word = "Made"

func _try(i: int) -> void:
	var ids := recipes.keys()
	if i < 0 or i >= ids.size():
		return
	var r: Dictionary = recipes[ids[i]]
	var err := ToolKit.craft(GameState.tools_owned, r, GameState.bag)
	if err == "":
		msg = "%s %s!" % [done_word, r["name"]]
		cooked.emit(String(r["name"]))
	else:
		msg = err
