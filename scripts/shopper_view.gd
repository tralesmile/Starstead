class_name ShopperView
extends Node2D
## A villager calls at your Farm Shop: walks up to the front door, goes to a shelf, buys one unit (paid at once,
## "+$" floats up), shows the item and a coin in a bubble, and walks out again. One at a time. Visual only (no
## collision), but the walk is a 4-way route that enters by the door. Rules live in ShopVisit (pure, tested).

const SPEED := 46.0
const BROWSE_SECS := 0.9
const PAY_SECS := 1.6
const BUBBLE_SECS := 2.6
const DEPTH := 8   # tiles walked up to the door

signal sold(id: String, money: int)

var m   # the Main node
var rules: Dictionary = DataDB.load_json("rooms")
var visit := ShopVisit.new()
var rng := RandomNumberGenerator.new()
var items: Dictionary = DataDB.load_json("items")
var icons: Dictionary = DataDB.load_json("item_icons")
var item_tex: Texture2D = load("res://assets/sprites/items.png")
var body: Node2D
var sprite: Sprite2D
var bubble: Node2D
var outfit := 0
var state := ""   # "", "in", "browse", "pay", "out"
var route: Array = []
var door := Vector2i.ZERO
var goods := Vector2i.ZERO
var at := 0   # index of the route cell being walked to
var wait := 0.0
var walk_t := 0.0
var face := 0
var bubble_t := 0.0
var sale: Dictionary = {}
var floats: Array = []   # {node, t, base}
var _serial := 0
var _last_min := -1.0
var _build_hash := 0
var _room := {}

func setup(main: Node) -> void:
	m = main
	rng.randomize()

static func cell_px(c: Vector2i) -> Vector2:
	return Vector2(c.x * 32.0 + 16.0, c.y * 32.0 + 20.0)

func active() -> bool:
	return body != null

func room() -> Dictionary:
	var h: int = GameState.build.placed.hash()
	if h != _build_hash:
		_build_hash = h
		_room = ShopVisit.shop_room(GameState.build.placed, rules, GameState.build.defs)
	return _room

func _ground(c: Vector2i) -> bool:
	## Dry land with nothing standing on it: no trees or rocks, and no town or farm building in the way.
	if m.world.gen.sdf_at(c.x, c.y) < 0.9 or GameState.nodes.is_solid(c):
		return false
	if GameState.build.placed.has(c):
		return true   # walls and furniture are judged by ShopVisit
	var q := PhysicsShapeQueryParameters2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(18, 18)
	q.shape = r
	q.transform = Transform2D(0.0, Vector2(c) * 32.0 + Vector2(16, 16))
	for hit in m.world.get_world_2d().direct_space_state.intersect_shape(q, 4):
		if hit.collider is StaticBody2D:
			return false
	return true

func start_visit(depth: int = DEPTH) -> bool:
	## Sends someone to the shop if the rules allow it (opening hours, finished room, goods, custom left today).
	var shop_room := room()
	var hour := NpcSchedule.hour_of(GameState.clock.minutes)
	if active() or not ShopVisit.wants_visit(rules.shop, hour, GameState.farm_shop, shop_room):
		return false
	var p := ShopVisit.plan(GameState.build.placed, GameState.build.defs, shop_room.flood, _ground, depth, rng)
	if p.is_empty():
		return false
	route = p.route
	door = p.door
	goods = p.goods
	_serial += 1
	outfit = NpcLook.outfit_of("shopper_%d_%d" % [GameState.clock.day, _serial])
	body = Node2D.new()
	body.position = cell_px(route[0])
	body.modulate.a = 0.0
	sprite = NpcLook.make_sprite(outfit)
	body.add_child(sprite)
	var sh := World.make_shadow(20)
	sh.scale = Vector2(0.6, 0.7)
	body.add_child(sh)
	bubble = Node2D.new()
	bubble.position = Vector2(0, -56)
	bubble.z_index = 90
	bubble.visible = false
	bubble.draw.connect(_draw_bubble)
	body.add_child(bubble)
	m.world.add_child(body)
	state = "in"
	at = 1
	walk_t = 0.0
	sale = {}
	bubble_t = 0.0
	return true

func clear() -> void:
	## Day end: whoever was on the way goes home without buying.
	if body != null:
		body.queue_free()
		body = null
	state = ""
	visit.next_in = -1.0
	_last_min = -1.0
	if m != null:
		m.build_view.visitors.clear()

func _process(delta: float) -> void:
	if m == null:
		return
	_step_floats(delta)
	var now: float = GameState.clock.minutes
	var passed := clampf(now - _last_min, 0.0, 15.0) if _last_min >= 0.0 else 0.0
	_last_min = now
	if m._overlay_open():
		return   # nobody buys from under an open window
	if not active():
		if GameState.world != "earth":
			return
		var eligible := ShopVisit.wants_visit(rules.shop, NpcSchedule.hour_of(now), GameState.farm_shop, room())
		if visit.tick(rules.shop, passed, eligible, rng):
			start_visit()
		return
	_step(delta)

func _step(delta: float) -> void:
	room()   # keeps _build_hash fresh
	if state != "out" and (_room.is_empty() or not _room.flood.cells.has(goods)):
		_turn_back()
	var ahead: Array = route.slice(maxi(at - 1, 0)) if state == "in" else route.slice(0, at + 1)
	if not ShopVisit.route_clear(GameState.build.placed, GameState.build.defs, ahead, door):
		clear()   # built over: better gone than walking through a wall
		return
	if bubble_t > 0.0:
		bubble_t -= delta
		bubble.visible = bubble_t > 0.0
		bubble.queue_redraw()
	var moving := false
	match state:
		"in", "out":
			var target := cell_px(route[at])
			body.position = body.position.move_toward(target, SPEED * delta)
			var d := target - body.position
			if d.length() > 0.1:
				face = NpcSchedule.facing_of(d, face)
				moving = true
			elif state == "in":
				if at < route.size() - 1:
					at += 1
					moving = true
				else:
					state = "browse"
					wait = BROWSE_SECS
					face = NpcSchedule.facing_of(Vector2(goods - route[at]), face)
			elif at > 0:
				at -= 1
				moving = true
		"browse":
			wait -= delta
			if wait <= 0.0:
				_pay()
		"pay":
			wait -= delta
			if wait <= 0.0:
				_turn_back()
	var left: float = body.position.distance_to(cell_px(route[0]))
	var fade := clampf(left / 24.0, 0.0, 1.0) if state == "out" else 1.0
	body.modulate.a = fade if state == "out" else minf(body.modulate.a + delta * 3.0, 1.0)
	walk_t = walk_t + delta if moving else 0.0
	sprite.frame = NpcLook.frame(outfit, face, PlayerMath.walk_frame_hd(walk_t, moving))
	m.build_view.visitors = [body.position]
	if state == "out" and at == 0 and left < 0.5:
		var wait_next := visit.next_in
		clear()
		visit.next_in = wait_next

func _turn_back() -> void:
	## Retrace the way in. While still walking in, `at` already points ahead, so step back one.
	if state == "in":
		at = maxi(at - 1, 0)
	state = "out"

func _pay() -> void:
	var menu := FarmShopView.price_menu(ShopMenu.new(items), GameState.market, GameState.clock.day)
	menu.planets = DataDB.load_json("planets")
	sale = ShopVisit.buy(GameState.farm_shop, menu, rules.shop, int(_room.shelves))
	if sale.is_empty():   # you emptied the shelves while they walked over
		_turn_back()
		return
	GameState.money += int(sale.money)
	GameState.bump("farm_shop_sales", 1)
	state = "pay"
	wait = PAY_SECS
	bubble_t = BUBBLE_SECS
	bubble.visible = true
	bubble.queue_redraw()
	_float_money(int(sale.money))
	sold.emit(String(sale.id), int(sale.money))

func _draw_bubble() -> void:
	if sale.is_empty():
		return
	var r := Rect2(-19, -18, 38, 20)
	bubble.draw_rect(r.grow(1), WoodUI.OUTLINE)
	bubble.draw_rect(r, WoodUI.PAPER)
	bubble.draw_colored_polygon(PackedVector2Array([Vector2(-3, 3), Vector2(3, 3), Vector2(0, 7)]), WoodUI.PAPER)
	bubble.draw_polyline(PackedVector2Array([Vector2(-4, 3), Vector2(0, 8), Vector2(4, 3)]), WoodUI.OUTLINE, 1.0)
	bubble.draw_texture_rect_region(item_tex, Rect2(-17, -16, 16, 16), Rect2(int(icons.get(sale.id, 0)) * 16, 0, 16, 16))
	# the coin hops and spins as the money changes hands
	var t := BUBBLE_SECS - bubble_t
	var hop := -absf(sin(t * 9.0)) * 4.0 * maxf(1.0 - t, 0.0)
	var wide := maxf(absf(cos(t * 7.0)) if t < 0.6 else 1.0, 0.25)
	bubble.draw_set_transform(Vector2(9, -8 + hop), 0.0, Vector2(wide, 1.0))
	bubble.draw_circle(Vector2.ZERO, 6.0, WoodUI.OUTLINE)
	bubble.draw_circle(Vector2.ZERO, 5.0, Color(0.96, 0.76, 0.22))
	bubble.draw_circle(Vector2.ZERO, 3.0, Color(1.0, 0.9, 0.48))
	bubble.draw_rect(Rect2(-0.5, -2.5, 1.0, 5.0), Color(0.72, 0.5, 0.12))
	bubble.draw_set_transform(Vector2.ZERO)

func _float_money(money: int) -> void:
	var node := Node2D.new()
	node.z_index = 95
	var l := Label.new()
	l.text = "+$%d" % money
	l.add_theme_font_size_override("font_size", 10)
	l.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
	l.add_theme_color_override("font_outline_color", Color(0.15, 0.1, 0.05))
	l.add_theme_constant_override("outline_size", 3)
	l.position = Vector2(22, -8)
	node.add_child(l)
	var base := body.position + Vector2(0, -50)
	node.position = base
	m.world.add_child(node)
	floats.append({"node": node, "t": 0.0, "base": base})

func _step_floats(delta: float) -> void:
	for f in floats.duplicate():
		f.t = float(f.t) + delta
		var n: Node2D = f.node
		if float(f.t) >= FloatMath.LIFE * 1.5:
			n.queue_free()
			floats.erase(f)
			continue
		n.position = (f.base as Vector2) + Vector2(0, -FloatMath.rise(float(f.t) / 1.5))
		n.modulate.a = FloatMath.alpha(float(f.t) / 1.5)
