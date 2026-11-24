class_name CarTheftView
extends Node2D
## Parked cars along the Port Halden kerbs (CarTheft.slots) and the steal/sell flow for your own CarView.
## Hot-wire a parked car with E: the car you drive becomes that car (your own is parked safely and comes back
## when you sell the hot one at the garage chop shop). Taken cars stay gone for the rest of the day.

signal toast(msg: String)
signal crime(kind: String, at: Vector2)

var car: CarView
var player: Player
var slots: Array = []
var taken: Array = []
var hot := {}                 # the slot being driven ("" id when none)
var own_pos := Vector2.ZERO
var own_heading := 0.0
var own_paint := 0
var _nodes := {}
var day := -1

func refresh(new_day: int) -> void:
	if new_day == day:
		return
	day = new_day
	taken.clear()
	_build()

func _build() -> void:
	for n in _nodes.values():
		(n as Node).queue_free()
	_nodes.clear()
	slots = CarTheft.slots(day)
	var tex: Texture2D = load("res://assets/sprites/car.png")
	for s in slots:
		var n := StaticBody2D.new()
		n.position = (Vector2(s["cell"]) + Vector2(0.5, 0.5)) * 32.0
		var sh := World.make_shadow(30)
		n.add_child(sh)
		var sp := Sprite2D.new()
		sp.texture = tex
		sp.offset = Vector2(0, -6)
		sp.rotation = float(s["heading"])
		sp.modulate = (GarageModel.PAINTS[int(s["paint"])]["color"] as Color) * Color(0.92, 0.92, 0.92)
		n.add_child(sp)
		var cs := CollisionShape2D.new()
		var rs := RectangleShape2D.new()
		rs.size = Vector2(26, 14)
		cs.shape = rs
		n.add_child(cs)
		n.visible = false
		add_child(n)
		_nodes[s["id"]] = n

func _process(_d: float) -> void:
	if player == null:
		return
	for s in slots:
		var n: Node2D = _nodes[s["id"]]
		n.visible = not taken.has(s["id"]) and n.position.distance_squared_to(player.position) < 900.0 * 900.0

func near_slot() -> Dictionary:
	if car.driving or player == null or not hot.is_empty():
		return {}
	return CarTheft.nearest(slots, player.position, taken)

func prompt() -> String:
	var s := near_slot()
	if s.is_empty():
		return ""
	return "E: Hot-wire the %s car (%d%%)" % [String(s["lock"]), int(100.0 * CarTheft.hotwire_chance(GameState.rep_street / 5, String(s["lock"])))]

## Returns true when the key press was used up.
func try_steal(crowd: int, hour: float) -> bool:
	var s := near_slot()
	if s.is_empty():
		return false
	var lvl: int = GameState.rep_street / 5
	var r := CarTheft.attempt(lvl, String(s["lock"]), randf(), randf())
	var at: Vector2 = (Vector2(s["cell"]) + Vector2(0.5, 0.5)) * 32.0
	if bool(r["alarm"]):
		toast.emit("The alarm shrieks!")
		crime.emit("theft", at)
	if not bool(r["ok"]):
		toast.emit("The wires won't take. Try again" if not bool(r["alarm"]) else "The wires won't take, and the alarm shrieks!")
		return true
	taken.append(s["id"])
	(_nodes[s["id"]] as Node2D).visible = false
	hot = s
	own_pos = car.position
	own_heading = car.heading
	own_paint = GameState.car_paint
	car.position = at
	car.heading = float(s["heading"])
	car.vel = Vector2.ZERO
	car.rotation = car.heading
	car.sprite.modulate = GarageModel.PAINTS[int(s["paint"])]["color"]
	car.enter()
	GameState.rep_street += 2
	GameState.rep_honest = maxi(0, GameState.rep_honest - 2)
	GameState.stats["cars_stolen"] = int(GameState.stats.get("cars_stolen", 0)) + 1
	if CarTheft.owner_sees(crowd, hour, randf()):
		crime.emit("car_theft", at)
	else:
		toast.emit("Engine sparks to life, nobody saw")
	return true

func can_sell() -> bool:
	return not hot.is_empty() and car.driving

## Chop shop: pay out, give your own car back and put the player on foot at the garage.
func sell() -> int:
	var price := CarTheft.chop_price(int(hot["value"]), car.health / VehicleMath.HEALTH_MAX)
	GameState.money += price
	GameState.stats["cars_chopped"] = int(GameState.stats.get("cars_chopped", 0)) + 1
	car.vel = Vector2.ZERO
	car.driving = false
	car.remove_collision_exception_with(player)
	player.remove_collision_exception_with(car)
	player.sprite.visible = true
	player.set_physics_process(true)
	player.position = car.position + Vector2(0, 40)
	car.position = own_pos
	car.heading = own_heading
	car.rotation = own_heading
	car.health = VehicleMath.HEALTH_MAX
	car.sprite.modulate = GarageModel.PAINTS[own_paint]["color"]
	hot = {}
	toast.emit("The chop shop pays $%d. Your own car is waiting where you left it." % price)
	return price
