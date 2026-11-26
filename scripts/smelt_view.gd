class_name SmeltView
extends CookView
## Workshop furnace: same menu as the stove, with ore + coal recipes from data/smelting.json.

func _init() -> void:
	super._init()
	recipes = DataDB.load_json("smelting")
	trim = WoodUI.Trim.EMBER
	title = "Furnace - click a bar or press its number"
	footer = "Ore and coal come from the Highlands cave.   E / Esc: leave"
	done_word = "Smelted"
