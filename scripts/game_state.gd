extends Node
## Autoload holding the whole save-able state. Save is versioned JSON.

const SAVE_VERSION := 1
const SAVE_PATH := "user://save.json"

var clock := GameClock.new()
var money: int = 500
var inventory: Dictionary = {}  # item_id -> count
var farm := FarmModel.new(DataDB.load_json("crops"))
var bag := Inventory.new(30, _limits())
var energy := Energy.new()
var nodes := ResourceNodes.new()
var world: String = "earth"
var rep_honest: int = 0
var rep_street: int = 0  # two reputations, both viable (DESIGN differentiator 4)

static func _limits() -> Dictionary:
	var out := {}
	var items = DataDB.load_json("items")
	for id in items:
		out[id] = int(items[id].stack)
	return out

func add_item(id: String, n: int = 1) -> void:
	inventory[id] = int(inventory.get(id, 0)) + n
	if inventory[id] <= 0:
		inventory.erase(id)

func has_item(id: String, n: int = 1) -> bool:
	return int(inventory.get(id, 0)) >= n

func to_dict() -> Dictionary:
	return {
		"version": SAVE_VERSION, "clock": clock.to_dict(), "money": money,
		"inventory": inventory, "world": world,
		"rep_honest": rep_honest, "rep_street": rep_street,
		"farm": farm.to_array(), "bag": bag.to_array(),
	}

func from_dict(d: Dictionary) -> bool:
	if int(d.get("version", 0)) > SAVE_VERSION:
		return false
	clock.from_dict(d.get("clock", {}))
	money = int(d.get("money", 500))
	inventory = {}
	for k in d.get("inventory", {}):
		inventory[k] = int(d["inventory"][k])
	world = str(d.get("world", "earth"))
	rep_honest = int(d.get("rep_honest", 0))
	rep_street = int(d.get("rep_street", 0))
	farm.from_array(d.get("farm", []))
	if d.has("bag"):
		bag.from_array(d["bag"])
	return true

func save_game(path: String = SAVE_PATH) -> bool:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(to_dict()))
	return true

func load_game(path: String = SAVE_PATH) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	return from_dict(parsed)
