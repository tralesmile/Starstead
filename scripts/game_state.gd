extends Node
## Autoload holding the whole save-able state. Save is versioned JSON.

const SAVE_VERSION := 1
const SAVE_PATH := "user://save.json"

var clock := GameClock.new()
var money: int = 500
var inventory: Dictionary = {}  # item_id -> count
var farm := FarmModel.new(DataDB.load_json("crops"))
var bag := Inventory.new(30, _limits())
var chest := Inventory.new(30, _limits())
var pots := CrabPots.new()
var snares := Snares.new()
var car_paint := 0
var licence := false              # Halden circuit licence (CircuitModel)
var stats: Dictionary = {}   # lifetime counters for story beats: race_wins, contests, promotions (StoryModel stat_min)
var sport_best: Dictionary = {}   # hoops / penalty best scores, bouts_won (SportsModel)
var race_best: Dictionary = {}   # laps (as text) -> best time
var energy := Energy.new()
var nodes := ResourceNodes.new()
var build := BuildModel.new(DataDB.load_json("build"))
var journal := FishJournal.new()
var harbour := HarbourState.new()
var can := WaterCan.new()
var animals: Array = []  # tamed animal states (AnimalModel dicts)
var job_xp: Dictionary = {}  # job id -> xp
var skill_xp: Dictionary = {}  # skill id -> xp (SkillModel)
var world: String = "earth"
var bank_balance: int = 0   # Halden Bank savings (CityServices)
var story := StoryModel.new(DataDB.load_json("story"))
var home := HomeUpgrades.new()  # farmhouse upgrades bought at the Town Hall builder
var business := BusinessModel.new()  # cafe franchise (own business)
var market := MarketModel.new()  # sell pressure (E8)
var tools_owned: Array = ToolKit.start()   # hotbar tools you have crafted or started with (ToolKit)
var drift_board: Array = []       # best circuit drift scores (DriftBoard)
var after_hours: Dictionary = {}   # public building id -> {"in": day lock picked, "till": day till emptied} (ShopHours)
var yard_looted: Dictionary = {}   # Vance yard crate index -> day last cleared
var debt_paid: int = 0       # Vance debt repaid at the Town Hall ledger
var rep_honest: int = 0
func street_skill() -> int:
	return ReputationModel.skill(rep_street, bag.count("lockpick_set") > 0)

var rep_street: int = 0  # two reputations, both viable (DESIGN differentiator 4)

func bump(stat: String, n: int = 1) -> void:
	stats[stat] = int(stats.get(stat, 0)) + n

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
		"version": SAVE_VERSION, "clock": clock.to_dict(), "money": money, "bank_balance": bank_balance,
		"inventory": inventory, "world": world,
		"rep_honest": rep_honest, "rep_street": rep_street,
		"farm": farm.to_array(), "weeds": farm.weeds_to_array(), "sprinklers": farm.sprinklers_to_array(), "scarecrows": farm.scarecrows_to_array(), "pots": pots.to_array(), "snares": snares.to_array(), "nodes": nodes.to_array(), "car_paint": car_paint, "race_best": race_best, "licence": licence, "sport_best": sport_best, "stats": stats, "bag": bag.to_array(), "chest": chest.to_array(), "build": build.to_dict(), "journal": journal.to_dict(), "harbour": harbour.to_dict(), "animals": animals, "can": can.to_dict(), "job_xp": job_xp, "story": story.to_array(), "debt_paid": debt_paid, "yard_looted": yard_looted, "after_hours": after_hours, "drift_board": drift_board, "market": market.to_dict(), "business": business.to_dict(), "home": home.to_dict(), "skill_xp": skill_xp, "tools_owned": tools_owned,
	}

func from_dict(d: Dictionary) -> bool:
	if int(d.get("version", 0)) > SAVE_VERSION:
		return false
	clock.from_dict(d.get("clock", {}))
	money = int(d.get("money", 500))
	bank_balance = int(d.get("bank_balance", 0))
	inventory = {}
	for k in d.get("inventory", {}):
		inventory[k] = int(d["inventory"][k])
	world = str(d.get("world", "earth"))
	rep_honest = int(d.get("rep_honest", 0))
	rep_street = int(d.get("rep_street", 0))
	farm.from_array(d.get("farm", []))
	farm.weeds_from_array(d.get("weeds", []))
	farm.sprinklers_from_array(d.get("sprinklers", []))
	farm.scarecrows_from_array(d.get("scarecrows", []))
	pots.from_array(d.get("pots", []))
	snares.from_array(d.get("snares", []))
	car_paint = int(d.get("car_paint", 0))
	licence = bool(d.get("licence", false))
	stats = {}
	for k in d.get("stats", {}):
		stats[str(k)] = int(d["stats"][k])
	sport_best = {}
	for k in d.get("sport_best", {}):
		sport_best[str(k)] = int(d["sport_best"][k])
	race_best = {}
	for k in d.get("race_best", {}):
		race_best[str(k)] = float(d["race_best"][k])
	build.from_dict(d.get("build", {}))
	journal.from_dict(d.get("journal", {}))
	harbour.from_dict(d.get("harbour", {}))
	animals = AnimalModel.new(DataDB.load_json("animals")).deserialize(JSON.stringify(d.get("animals", [])))
	can.from_dict(d.get("can", {}))
	skill_xp = {}
	for k in d.get("skill_xp", {}):
		skill_xp[k] = int(d["skill_xp"][k])
	job_xp = {}
	for k in d.get("job_xp", {}):
		job_xp[k] = int(d["job_xp"][k])
	story.from_array(d.get("story", []))
	tools_owned = Array(d["tools_owned"]) if d.has("tools_owned") else ToolKit.all_tools()   # old saves own every tool
	debt_paid = int(d.get("debt_paid", 0))
	drift_board = DriftBoard.clean(d.get("drift_board", []))
	yard_looted = {}
	after_hours = {}
	for k in d.get("after_hours", {}):
		after_hours[str(k)] = {"in": int(d["after_hours"][k].get("in", -1)), "till": int(d["after_hours"][k].get("till", -1))}
	var yl: Dictionary = d.get("yard_looted", {})
	for k in yl:
		yard_looted[int(k)] = int(yl[k])
	nodes.from_array(d.get("nodes", []))
	market.from_dict(d.get("market", {}))
	business.from_dict(d.get("business", {}))
	home.from_dict(d.get("home", {}))
	if d.has("chest"):
		chest.from_array(d["chest"])
	if d.has("bag"):
		bag.from_array(d["bag"])
	bag.ensure_size(home.bag_slots())
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
