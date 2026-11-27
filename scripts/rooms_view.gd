class_name RoomsView
extends Node2D
## Player-built rooms at work: names the room you step into, hangs a sign over the door of each finished room,
## runs the E key on beds, shop counters and workbenches, and pays the Farm Shop's takings when the day ends.
## The rules are in RoomModel and FarmShopModel; the stock window is FarmShopView.

const SIGNS := ["shop", "garage", "bedroom"]   # frame order in room_signs.png
const PROMPTS := {"bedroom": "E: Sleep until morning", "shop": "E: Stock your Farm Shop", "garage": "E: Use your garage"}

var m   # the Main node
var rules: Dictionary = DataDB.load_json("rooms")
var shop_ui: FarmShopView
var banner: Control
var title := ""
var detail := ""
var good := false
var banner_t := 0.0
var _key := ""
var _hash := 0
var _signs: Array = []

func setup(main: Node) -> void:
	m = main
	shop_ui = FarmShopView.new()
	shop_ui.closed.connect(func(): m.player.set_physics_process(true))
	add_child(shop_ui)
	var layer := CanvasLayer.new()
	layer.layer = 3
	banner = Control.new()
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.draw.connect(_draw_banner)
	layer.add_child(banner)
	add_child(layer)

func _cell_of(p: Vector2) -> Vector2i:
	return Vector2i(floori(p.x / 32.0), floori(p.y / 32.0))

func station_near(target: Vector2i) -> Vector2i:
	## The bed, counter or workbench you face, else one right beside you. Vector2i.MAX when none.
	var pc := _cell_of(m.player.position)
	var spots := [target] if (target - pc).length_squared() <= 2 else []
	for d in RoomModel.DIRS:
		spots.append(pc + d)
	for c in spots:
		if GameState.build.placed.has(c) and RoomModel.station_type(rules, GameState.build.placed[c]) != "":
			return c
	return Vector2i.MAX

func _check(c: Vector2i) -> Dictionary:
	var type := RoomModel.station_type(rules, GameState.build.placed[c])
	var out := RoomModel.station_check(GameState.build.placed, c, type, rules, GameState.build.defs)
	out["type"] = type
	return out

func prompt_or(current: String, target: Vector2i) -> String:
	## The prompt line: a station beside you wins over whatever was there.
	if m.car.driving or m.animals.riding != null or m._indoors():
		return current
	var c := station_near(target)
	if c == Vector2i.MAX:
		return current
	var s := _check(c)
	if not s.ok:
		return "E: Unfinished %s (what is missing?)" % rules[s.type].name
	return String(PROMPTS[s.type])

func interact(target: Vector2i) -> bool:
	var c := station_near(target)
	if c == Vector2i.MAX:
		return false
	var s := _check(c)
	if not s.ok:
		show_banner("Unfinished " + String(rules[s.type].name), RoomModel.needs_text(rules[s.type].name, s.missing), false, 4.0)
		return true
	match String(s.type):
		"bedroom":
			m._sleep()
		"shop":
			_halt()
			shop_ui.open(int(s.flood.count.get("shelf", 0)))
		"garage":
			var reach := float(rules.garage.car_range_tiles) * 32.0
			if m.car.position.distance_to(Vector2(c) * 32.0 + Vector2(16, 16)) > reach:
				show_banner("Garage", "Park your car within %d tiles of the workbench." % int(rules.garage.car_range_tiles), false, 4.0)
				return true
			_halt()
			m.garage_view.open(1.0 - float(rules.garage.repair_discount))
	return true

func _halt() -> void:
	m.player.velocity = Vector2.ZERO
	m.player.move_v = Vector2.ZERO
	m.player.set_physics_process(false)

func night() -> void:
	## Day end (before MarketModel.new_day, so tonight's sales count toward the same glut).
	var shop: FarmShopModel = GameState.farm_shop
	if shop.total() == 0:
		return
	var shelves := -1
	for r in RoomModel.find_rooms(GameState.build.placed, rules, GameState.build.defs):
		if RoomModel.missing(r.flood, rules.shop, GameState.build.defs).is_empty():
			shelves = maxi(shelves, int(r.flood.count.get("shelf", 0)))   # one shop's worth of customers, however many rooms
	if shelves < 0:
		show_banner("Farm Shop closed", "No finished shop room: your %d goods stayed unsold." % shop.total(), false, 7.0)
		return
	var menu := FarmShopView.price_menu(ShopMenu.new(DataDB.load_json("items")), GameState.market, maxi(GameState.clock.day - 1, 1))
	menu.planets = DataDB.load_json("planets")
	var r := shop.sell_night(menu, rules.shop, shelves)
	GameState.money += int(r.money)
	GameState.bump("farm_shop_sales", int(r.units))
	show_banner("Farm Shop takings: +$%d" % r.money, "%d sold overnight, %d still on the shelves." % [r.units, shop.total()], true, 7.0)

func show_banner(t: String, d: String, ok: bool, secs: float) -> void:
	title = t
	detail = d
	good = ok
	banner_t = secs
	banner.queue_redraw()

func _process(delta: float) -> void:
	if m == null:
		return
	var h: int = GameState.build.placed.hash()
	if h != _hash:
		_hash = h
		_refresh_signs()
		_key = "?"   # the room around you may have changed
	var pc := _cell_of(m.player.position)
	var here := "%s:%d" % [pc, h]
	if not m._indoors() and not m.car.driving and (_key == "?" or not _key.begins_with(here + "|")):
		var room := RoomModel.judge(GameState.build.placed, pc, rules, GameState.build.defs)
		var inside: bool = room.flood.enclosed and not room.flood.doors.is_empty()
		var id := ""
		if inside:
			var low: Vector2i = pc
			for c in room.flood.cells:
				if c.y < low.y or (c.y == low.y and c.x < low.x):
					low = c
			id = "%s %s %s %s" % [low, room.type, room.valid, room.missing]
		if _key.get_slice("|", 1) != id:
			if id == "":
				if banner_t < 3.0:
					banner_t = 0.0
			elif banner_t <= 0.0 or not title.begins_with("Farm Shop takings"):
				if room.valid:
					show_banner(room.name, String(rules[room.type].use), true, 3.5)
				elif room.type != "":
					show_banner("Unfinished " + String(room.name), RoomModel.needs_text(room.name, room.missing), false, 4.0)
				else:
					show_banner("Empty room", "Add a bed, a shop counter or a workbench to give it a purpose.", false, 3.5)
		_key = here + "|" + id
	banner_t = maxf(banner_t - delta, 0.0)
	banner.visible = banner_t > 0.0 and not m._overlay_open()
	if banner.visible:
		banner.modulate.a = clampf(banner_t * 2.0, 0.0, 1.0)
		banner.queue_redraw()

func _draw_banner() -> void:
	var font := ThemeDB.fallback_font
	var w := clampf(maxf(font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x, font.get_string_size(detail, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x) + 24.0, 150.0, 480.0)
	var r := Rect2(roundf((640.0 - w) / 2.0), 232, w, 34)
	banner.draw_rect(r.grow(3), WoodUI.OUTLINE)
	banner.draw_rect(r.grow(2), WoodUI.WOOD)
	banner.draw_rect(r, WoodUI.PAPER)
	WoodUI.text(banner, r.position + Vector2(0, 15), title, 13, WoodUI.GOOD if good else WoodUI.BAD, w, HORIZONTAL_ALIGNMENT_CENTER)
	WoodUI.text(banner, r.position + Vector2(4, 29), detail, 10, WoodUI.INK, w - 8, HORIZONTAL_ALIGNMENT_CENTER)

func _refresh_signs() -> void:
	for s in _signs:
		s.queue_free()
	_signs.clear()
	var hung := {}
	for r in RoomModel.find_rooms(GameState.build.placed, rules, GameState.build.defs):
		var doors: Array = r.flood.doors.keys()
		doors.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.y > b.y or (a.y == b.y and a.x < b.x))
		var d: Vector2i = doors[0]   # the front-most door
		if hung.has(d):
			continue
		hung[d] = true
		var s := Sprite2D.new()
		s.texture = load("res://assets/sprites/room_signs.png")
		s.region_enabled = true
		s.region_rect = Rect2(maxi(SIGNS.find(r.type), 0) * 20, 0, 20, 14)
		s.centered = false
		s.offset = Vector2(-10, -54)
		s.position = Vector2(d.x * 32 + 16, d.y * 32 + 32.5)   # just in front of the door when y-sorted
		m.world.add_child(s)
		_signs.append(s)
