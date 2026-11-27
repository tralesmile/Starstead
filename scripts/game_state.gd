extends Node
## Autoload holding the whole save-able state. Save is versioned JSON.

signal before_save   # the live world (player, car, house memory) writes itself into world_state

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
var artisan := ArtisanModel.new(DataDB.load_json("artisan"))  # barn machines
var ranger := RangerModel.new()  # hunting licence + ranger heat
var car_paint := 0
var licence := false              # Halden circuit licence (CircuitModel)
var stats: Dictionary = {}   # lifetime counters for story beats: race_wins, contests, promotions (StoryModel stat_min)
var football := FootballLeague.new()   # Halden Sunday League (E6)
var hoops := HoopLadder.new()   # 3-on-3 street basketball crews (E6)
var sport_best: Dictionary = {}   # hoops / penalty best scores, bouts_won (SportsModel)
var race_best: Dictionary = {}   # laps (as text) -> best time
var energy := Energy.new()
var nodes := ResourceNodes.new()
var forestry := Forestry.new(DataDB.load_json("forestry"))  # tree seeds, saplings, planted trees
var build := BuildModel.new(DataDB.load_json("build"))
var journal := FishJournal.new()
var harbour := HarbourState.new()
var isle := IsleState.new()  # Gull Isle finds (E13)
var can := WaterCan.new()
var animals: Array = []  # tamed animal states (AnimalModel dicts)
var job_xp: Dictionary = {}  # job id -> xp
var skill_xp: Dictionary = {}  # skill id -> xp (SkillModel)
var perks: Dictionary = {}  # skill id -> level-5 perk id (PerkModel), permanent
var world: String = "earth"
var world_state: Dictionary = {}   # player spot, car, robbery memory (WorldState)
var bank_balance: int = 0   # Halden Bank savings (CityServices)
var story := StoryModel.new(DataDB.load_json("story"))
var home := HomeUpgrades.new()  # farmhouse upgrades bought at the Town Hall builder
var business := BusinessModel.new()  # cafe franchise (own business)
var market := MarketModel.new()  # sell pressure (E8)
var tools_owned: Array = ToolKit.start()   # hotbar tools you have crafted or started with (ToolKit)
var drift_board: Array = []       # best circuit drift scores (DriftBoard)
var after_hours: Dictionary = {}   # public building id -> {"in": day lock picked, "till": day till emptied} (ShopHours)
var hangar_day := -1   # day of the last Vance hangar raid
var vault_day := -1   # day of the last Halden Bank vault job (BankJob)
var cart_cargo: Dictionary = {}   # ore left in the mine cart (CartCargo.serialize)
var warden_day := -1   # day the Stone Warden in the deep mine was last beaten
var yard_looted: Dictionary = {}   # Vance yard crate index -> day last cleared
var debt_paid: int = 0       # Vance debt repaid at the Town Hall ledger
var rep_honest: int = 0
func street_skill() -> int:
	return ReputationModel.skill(rep_street, bag.count("lockpick_set") > 0)

var rep_street: int = 0  # two reputations, both viable (DESIGN differentiator 4)

func choose_perk(skill: String, id: String) -> bool:
	if not PerkModel.choose(perks, skill, id):
		return false
	energy.discounts = PerkModel.energy_discounts(perks)
	return true

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
		"version": SAVE_VERSION, "clock": clock.to_dict(), "energy": energy.value, "money": money, "bank_balance": bank_balance,
		"inventory": inventory, "world": world, "world_state": world_state,
		"rep_honest": rep_honest, "rep_street": rep_street,
		"farm": farm.to_array(), "weeds": farm.weeds_to_array(), "sprinklers": farm.sprinklers_to_array(), "scarecrows": farm.scarecrows_to_array(), "pots": pots.to_array(), "snares": snares.to_array(), "artisan": artisan.to_dict(), "ranger": ranger.to_dict(), "nodes": nodes.to_array(), "forestry": forestry.to_dict(), "car_paint": car_paint, "race_best": race_best, "licence": licence, "sport_best": sport_best, "football": football.to_dict(), "hoops": hoops.to_dict(), "stats": stats, "bag": bag.to_array(), "chest": chest.to_array(), "build": build.to_dict(), "journal": journal.to_dict(), "harbour": harbour.to_dict(), "isle": isle.to_dict(), "animals": animals, "can": can.to_dict(), "job_xp": job_xp, "story": story.to_array(), "debt_paid": debt_paid, "yard_looted": yard_looted, "hangar_day": hangar_day, "vault_day": vault_day,"warden_day": warden_day, "cart_cargo": cart_cargo, "after_hours": after_hours, "drift_board": drift_board, "market": market.to_dict(), "business": business.to_dict(), "home": home.to_dict(), "skill_xp": skill_xp, "perks": perks, "tools_owned": tools_owned,
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
	var ws = d.get("world_state", {})
	world_state = (ws as Dictionary).duplicate(true) if ws is Dictionary else {}
	rep_honest = int(d.get("rep_honest", 0))
	rep_street = int(d.get("rep_street", 0))
	farm.from_array(d.get("farm", []))
	farm.weeds_from_array(d.get("weeds", []))
	farm.sprinklers_from_array(d.get("sprinklers", []))
	farm.scarecrows_from_array(d.get("scarecrows", []))
	pots.from_array(d.get("pots", []))
	snares.from_array(d.get("snares", []))
	artisan.from_dict(d.get("artisan", {}))
	ranger.from_dict(d.get("ranger", {}))
	car_paint = int(d.get("car_paint", 0))
	licence = bool(d.get("licence", false))
	stats = {}
	for k in d.get("stats", {}):
		stats[str(k)] = int(d["stats"][k])
	football.from_dict(d.get("football", {}))
	hoops.from_dict(d.get("hoops", {}))
	sport_best = {}
	for k in d.get("sport_best", {}):
		sport_best[str(k)] = int(d["sport_best"][k])
	race_best = {}
	for k in d.get("race_best", {}):
		race_best[str(k)] = float(d["race_best"][k])
	build.from_dict(d.get("build", {}))
	journal.from_dict(d.get("journal", {}))
	harbour.from_dict(d.get("harbour", {}))
	isle.from_dict(d.get("isle", {}))
	animals = AnimalModel.new(DataDB.load_json("animals")).deserialize(JSON.stringify(d.get("animals", [])))
	can.from_dict(d.get("can", {}))
	skill_xp = {}
	for k in d.get("skill_xp", {}):
		skill_xp[k] = int(d["skill_xp"][k])
	perks = PerkModel.clean(d.get("perks", {}))
	energy.discounts = PerkModel.energy_discounts(perks)
	energy.value = clampf(float(d.get("energy", Energy.MAX)), 0.0, float(Energy.MAX))
	job_xp = {}
	for k in d.get("job_xp", {}):
		job_xp[k] = int(d["job_xp"][k])
	story.from_array(d.get("story", []))
	tools_owned = Array(d["tools_owned"]) if d.has("tools_owned") else ToolKit.all_tools()   # old saves own every tool
	debt_paid = int(d.get("debt_paid", 0))
	drift_board = DriftBoard.clean(d.get("drift_board", []))
	yard_looted = {}
	hangar_day = -1
	warden_day = -1
	after_hours = {}
	for k in d.get("after_hours", {}):
		after_hours[str(k)] = {"in": int(d["after_hours"][k].get("in", -1)), "till": int(d["after_hours"][k].get("till", -1))}
	hangar_day = int(d.get("hangar_day", -1))
	vault_day = int(d.get("vault_day", -1))
	warden_day = int(d.get("warden_day", -1))
	var cc = d.get("cart_cargo", {})
	cart_cargo = (cc as Dictionary).duplicate() if cc is Dictionary else {}
	var yl: Dictionary = d.get("yard_looted", {})
	for k in yl:
		yard_looted[int(k)] = int(yl[k])
	nodes.from_array(d.get("nodes", []))
	forestry.from_dict(d.get("forestry", {}))
	forestry.register(nodes)
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
	before_save.emit()
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(to_dict()))
	return true

## Start over: every field back to what a brand-new GameState holds. The old save is kept as a backup.
func reset_new(path: String = SAVE_PATH) -> void:
	if path != "" and FileAccess.file_exists(path):
		DirAccess.rename_absolute(path, path + ".bak")
	var fresh: Node = (get_script() as GDScript).new()
	for p in (get_script() as GDScript).get_script_property_list():
		if int(p.usage) & PROPERTY_USAGE_SCRIPT_VARIABLE:
			set(p.name, fresh.get(p.name))
	fresh.free()

func load_game(path: String = SAVE_PATH) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	return from_dict(parsed)
