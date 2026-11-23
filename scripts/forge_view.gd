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
		msg = "%s %s!" % [done_word, r["name"]]
		cooked.emit(String(r["name"]))
	else:
		msg = err
