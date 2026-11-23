class_name InteriorView
extends Node
## Walk through a building's door: fade out, the room is built far from the map, the player is moved in,
## fade in. Leaving through the door gap (or Esc) returns to the exact outside spot.
## Actions: sleep (farmhouse bed), loot (robbery of house furniture).

signal garage_requested
signal cook_requested
signal smelt_requested
signal chest_requested
signal sleep_requested
signal service_requested(action: String)
signal loot_requested(building: Dictionary)
signal message(msg: String)

const ORIGIN := Vector2(9000, 9000)
const ACTIONS := ["sleep", "loot", "chest", "cook", "smelt", "garage", "shop", "bank", "heal", "fine", "coffee", "notice", "debt", "hoops", "ring", "licence", "business"]
var world: Node2D
var player: Player
var active := false
var busy := false
var building: Dictionary = {}
var layout: Dictionary = {}
var outside_pos := Vector2.ZERO
var nodes: Array = []
var fade: ColorRect
var tex := {}
var dog_cb: Callable    # (building id) -> true when this house keeps a guard dog (RobberyModel memory)
var bark_cb: Callable   # () -> called on every bark (noise toward waking the residents)
var dog: Node2D = null
var dog_state := {"awake": false, "timer": DogMath.BARK_EVERY, "chew": 0.0, "t": 0.0}

func setup(w: Node2D, p: Player, host: Node) -> void:
	world = w
	player = p
	var layer := CanvasLayer.new()
	layer.layer = 20
	fade = ColorRect.new()
	fade.color = Color(0, 0, 0, 0)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(fade)
	host.add_child(layer)

func _t(name: String) -> Texture2D:
	if not tex.has(name):
		tex[name] = load("res://assets/sprites/%s.png" % name)
	return tex[name]

func enter(b: Dictionary) -> void:
	if active or busy:
		return
	busy = true
	building = b
	layout = InteriorModel.layout(InteriorModel.kind_for(String(b["id"])))
	_freeze(true)
	var tw := create_tween()
	tw.tween_property(fade, "color:a", 1.0, 0.22)
	tw.tween_callback(_do_enter)
	tw.tween_property(fade, "color:a", 0.0, 0.22)
	tw.tween_callback(func():
		busy = false
		_freeze(false))

func _freeze(on: bool) -> void:
	player.set_physics_process(not on)
	if on:
		player.velocity = Vector2.ZERO
		player.move_v = Vector2.ZERO

func _do_enter() -> void:
	outside_pos = player.position
	_build()
	active = true
	player.position = ORIGIN + InteriorModel.entrance(layout)
	player.facing = PlayerMath.Facing.UP
	var c := ORIGIN + Vector2(int(layout["w"]) * 16.0, int(layout["h"]) * 16.0 - 12.0)
	player.focus = c
	player.camera.limit_left = int(c.x - 700)
	player.camera.limit_right = int(c.x + 700)
	player.camera.limit_top = int(c.y - 400)
	player.camera.limit_bottom = int(c.y + 400)

func leave() -> void:
	if not active or busy:
		return
	busy = true
	_freeze(true)
	var tw := create_tween()
	tw.tween_property(fade, "color:a", 1.0, 0.22)
	tw.tween_callback(_do_leave)
	tw.tween_property(fade, "color:a", 0.0, 0.22)
	tw.tween_callback(func():
		busy = false
		_freeze(false))

func _do_leave() -> void:
	active = false
	for n in nodes:
		if is_instance_valid(n):
			n.queue_free()
	nodes.clear()
	player.position = outside_pos
	player.facing = PlayerMath.Facing.DOWN
	player.focus = null
	player.camera.limit_left = int(ChunkGrid.world_rect_px().position.x)
	player.camera.limit_top = int(ChunkGrid.world_rect_px().position.y)
	player.camera.limit_right = int(ChunkGrid.world_rect_px().end.x)
	player.camera.limit_bottom = int(ChunkGrid.world_rect_px().end.y)

func _add(n: Node) -> void:
	world.add_child(n)
	nodes.append(n)

func _build() -> void:
	var w: int = layout["w"]
	var h: int = layout["h"]
	var bg := ColorRect.new()
	bg.position = ORIGIN - Vector2(900, 600)
	bg.size = Vector2(1800 + w * 32, 1200 + h * 32)
	bg.color = Color(0.07, 0.05, 0.04)
	bg.z_index = -20
	_add(bg)
	var floor_tex := _t("int_floor")
	for y in h:
		for x in w:
			var s := Sprite2D.new()
			s.texture = floor_tex
			s.centered = false
			s.position = ORIGIN + Vector2(x, y) * 32.0
			s.z_index = -19
			_add(s)
	for x in w:
		var s := Sprite2D.new()
		s.texture = _t("int_window") if x in layout["window_x"] else _t("int_wall")
		s.centered = false
		s.position = ORIGIN + Vector2(x * 32, -48)
		s.z_index = -18
		_add(s)
	for f in layout["furniture"]:
		var t := _t(String(f["sprite"]))
		var s := Sprite2D.new()
		s.texture = t
		var cell: Vector2i = f["cell"]
		var size: Vector2i = f["size"]
		var foot_bottom := ORIGIN + Vector2(cell.x * 32.0 + size.x * 16.0, (cell.y + size.y) * 32.0)
		s.offset = Vector2(0, -t.get_height() / 2.0)
		s.position = foot_bottom
		if not f["solid"]:
			s.z_index = -17  # rugs and mats lie on the floor
		_add(s)
		if f["solid"] and f["id"] != "rug":
			var sh := World.make_shadow(float(size.x) * 28.0)
			sh.position = foot_bottom + Vector2(0, -2)
			_add(sh)
	# walls: back, left, right, bottom with a gap at the door
	var body := StaticBody2D.new()
	body.position = ORIGIN
	var door_x: int = layout["door_x"]
	var rects: Array[Rect2] = [
		Rect2(-16, -22, w * 32 + 32, 22),
		Rect2(-16, 0, 16, h * 32 + 16),
		Rect2(w * 32, 0, 16, h * 32 + 16),
		Rect2(-16, h * 32, door_x * 32 + 16, 16),
		Rect2((door_x + 1) * 32, h * 32, (w - door_x - 1) * 32 + 16, 16),
	]
	rects.append_array(InteriorModel.solid_rects(layout))
	_spawn_dog(w)
	for r in rects:
		var cs := CollisionShape2D.new()
		var rs := RectangleShape2D.new()
		rs.size = r.size
		cs.shape = rs
		cs.position = r.position + r.size * 0.5
		body.add_child(cs)
	_add(body)

func _spawn_dog(w: int) -> void:
	dog = null
	if not dog_cb.is_valid() or String(building.get("id", "")) in InteriorModel.PUBLIC or not bool(dog_cb.call(String(building.get("id", "")))):
		return
	dog = Node2D.new()
	dog.position = ORIGIN + Vector2(w * 32.0 - 40.0, 56.0)   # asleep in the far corner
	var s := Sprite2D.new()
	s.texture = _t("guard_dog")
	s.hframes = 2
	s.offset = Vector2(0, -10)
	s.name = "Sprite"
	dog.add_child(s)
	var l := Label.new()
	l.name = "Woof"
	l.text = "Zzz"
	l.position = Vector2(-10, -38)
	l.add_theme_font_size_override("font_size", 10)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	l.add_theme_constant_override("outline_size", 3)
	dog.add_child(l)
	_add(dog)
	dog_state = {"awake": false, "timer": 0.3, "chew": 0.0, "t": 0.0}

func _dog_tick(d: float) -> void:
	if dog == null or not is_instance_valid(dog):
		return
	var s := dog.get_node("Sprite") as Sprite2D
	var l := dog.get_node("Woof") as Label
	dog_state["awake"] = DogMath.awake(dog.position, player.position, bool(dog_state["awake"]))
	if not bool(dog_state["awake"]):
		return
	if float(dog_state["chew"]) > 0.0:
		dog_state["chew"] = float(dog_state["chew"]) - d
		s.frame = 0
		l.text = "*chew*"
		return
	if GameState.bag.count(DogMath.TREAT) > 0:   # toss it a piece of raw meat: quiet for a while
		GameState.bag.remove(DogMath.TREAT, 1)
		dog_state["chew"] = DogMath.CHEW_SECS
		message.emit("You toss the dog some raw meat. It's busy chewing.")
		return
	var before := dog.position
	dog.position = DogMath.step(dog.position, player.position, d)
	var mv := dog.position - before
	if absf(mv.x) > 0.01:
		s.flip_h = mv.x < 0.0
	dog_state["t"] = float(dog_state["t"]) + d
	s.frame = (int(float(dog_state["t"]) * 8.0) % 2) if mv.length() > 0.01 else 0
	var r := DogMath.bark(float(dog_state["timer"]), d)
	dog_state["timer"] = r["timer"]
	if r["bark"]:
		l.text = "WOOF!"
		if bark_cb.is_valid():
			bark_cb.call()
	elif float(dog_state["timer"]) < DogMath.BARK_EVERY * 0.5:
		l.text = "grr"

func rel() -> Vector2:
	return player.position - ORIGIN

func prompt() -> String:
	if not active or busy:
		return ""
	var a := InteriorModel.action_near(layout, rel(), ACTIONS)
	match String(a.get("action", "")):
		"garage": return "E: Garage services"
		"cook": return "E: Cook at the stove"
		"smelt": return "E: Smelt ore at the furnace"
		"chest": return "E: Open the storage chest"
		"sleep": return "E: Sleep until morning"
		"loot": return "E: Search the %s" % a["id"]
	return CityActions.prompt(String(a.get("action", "")))

func interact() -> bool:
	## E key inside a room; returns true when handled.
	if not active or busy:
		return false
	var a := InteriorModel.action_near(layout, rel(), ACTIONS)
	match String(a.get("action", "")):
		"garage":
			garage_requested.emit()
			return true
		"cook":
			cook_requested.emit()
			return true
		"smelt":
			smelt_requested.emit()
			return true
		"chest":
			chest_requested.emit()
			return true
		"sleep":
			sleep_requested.emit()
			return true
		"loot":
			loot_requested.emit(building)
			return true
		"shop", "bank", "heal", "fine", "coffee", "notice", "debt", "hoops", "ring", "licence", "business":
			service_requested.emit(String(a["action"]))
			return true
	return true

func _process(_d: float) -> void:
	if active and not busy:
		_dog_tick(_d)
	if active and not busy and InteriorModel.left_through_door(layout, rel()):
		leave()
