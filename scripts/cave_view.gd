class_name CaveView
extends Node
## The Highlands mine in play. Like InteriorView: fade out, the cavern (CaveModel) is built far from the map,
## the player is moved in and gets a miner's lamp; torches light the walls, ore breaks under the pickaxe,
## bats chase and are driven off with the club. Walking off the bottom edge returns to the cave mouth.

signal ore_broken(id: String, n: int, pos: Vector2, kind: String)
signal bat_down(pos: Vector2)
signal monster_down(kind: String, pos: Vector2)
signal floor_changed(n: int)
signal bitten(amount: float)
var motes: CPUParticles2D
signal message(msg: String)
signal sound(name: String, gain: float, pitch: float)
signal boss_defeated(pos: Vector2)

const ORIGIN := Vector2(30016, 30016)
const CELL_OFFSET := Vector2i(938, 938)   # ORIGIN / 32
const DARK := Color(0.52, 0.52, 0.66)

var world: Node2D
var player: Player
var model: CaveModel
var model_day := -1
var models: Dictionary = {}      # floor -> CaveModel for the current day (mined ore stays mined)
var floor_no := 1
var ladder_lock := false
var active := false
var busy := false
var outside_pos := Vector2.ZERO
var nodes: Array = []
var ore_nodes: Dictionary = {}   # model cell -> StaticBody2D
var bats: Array = []             # {data, node, sprite}
var torch_sprites: Array = []
var lamp: PointLight2D
var fade: ColorRect
var tex := {}
var t := 0.0
var boss: BossView
var boss_ready_cb: Callable      # () -> days until the Warden is back (0 = awake and waiting)
var wide_lamp_cb: Callable       # () -> true when the Deepglow Lamp is carried
var cart: Dictionary = {}        # {s, v} on model.rail
var cart_pts := PackedVector2Array()
var cart_node: Node2D
var cart_sprite: Sprite2D
var riding := false
var cart_roll := 0.0
var rumble_t := 0.0
signal cargo_spilled(id: String, n: int, pos: Vector2)
const DOOR_END := 40.0     # px of track from the entrance buffer where the cart can be emptied
const SCOOP_R := 40.0
var cargo := CartCargo.new()
var bag_cb: Callable       # () -> the player's Inventory
var heap_node: Node2D

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

func px(c: Vector2i) -> Vector2:
	return ORIGIN + Vector2(c) * 32.0

func model_cell(world_px: Vector2) -> Vector2i:
	return Vector2i(floori(world_px.x / 32.0), floori(world_px.y / 32.0)) - CELL_OFFSET

func enter(day: int) -> void:
	if active or busy:
		return
	busy = true
	if model_day != day:
		models.clear()
		model_day = day
	floor_no = 1
	model = _floor_model(1)
	_freeze(true)
	var tw := create_tween()
	tw.tween_property(fade, "color:a", 1.0, 0.25)
	tw.tween_callback(_do_enter)
	tw.tween_property(fade, "color:a", 0.0, 0.25)
	tw.tween_callback(func():
		busy = false
		_freeze(false))

func _floor_model(n: int) -> CaveModel:
	if not models.has(n):
		models[n] = CaveModel.generate(model_day, n)
	return models[n]

func change_floor(n: int, going_down: bool) -> void:
	## Ladder: fade, rebuild the cavern for floor n, arrive at the entrance (going down) or beside the ladder (going up).
	if not active or busy:
		return
	busy = true
	_freeze(true)
	var tw := create_tween()
	tw.tween_property(fade, "color:a", 1.0, 0.2)
	tw.tween_callback(func(): _do_change_floor(n, going_down))
	tw.tween_property(fade, "color:a", 0.0, 0.2)
	tw.tween_callback(func():
		busy = false
		_freeze(false))

func _do_change_floor(n: int, going_down: bool) -> void:
	_clear_nodes()
	floor_no = n
	model = _floor_model(n)
	_build()
	var spot: Vector2i = model.entrance if going_down else model.ladder_down + Vector2i(0, 1)
	if not going_down and not model.is_floor(spot):
		spot = model.ladder_down + Vector2i(0, -1)
	player.position = px(spot) + Vector2(16, 16)
	player.facing = PlayerMath.Facing.UP if going_down else PlayerMath.Facing.DOWN
	ladder_lock = true
	floor_changed.emit(n)

func _clear_nodes() -> void:
	_return_cargo()
	for n in nodes:
		if is_instance_valid(n):
			n.queue_free()
	nodes.clear()
	riding = false
	boss = null
	cart_node = null
	cart.clear()
	ore_nodes.clear()
	bats.clear()
	torch_sprites.clear()

func _freeze(on: bool) -> void:
	player.set_physics_process(not on)
	if on:
		player.velocity = Vector2.ZERO
		player.move_v = Vector2.ZERO

func _do_enter() -> void:
	outside_pos = player.position
	_build()
	active = true
	player.position = px(model.entrance) + Vector2(16, 16)
	player.facing = PlayerMath.Facing.UP
	var c := ORIGIN + Vector2(CaveModel.W, CaveModel.H) * 16.0
	player.camera.limit_left = int(c.x - CaveModel.W * 16 - 40)
	player.camera.limit_right = int(c.x + CaveModel.W * 16 + 40)
	player.camera.limit_top = int(c.y - CaveModel.H * 16 - 40)
	player.camera.limit_bottom = int(c.y + CaveModel.H * 16 + 40)
	lamp = PointLight2D.new()
	lamp.texture = Lantern.light_texture()
	lamp.texture_scale = 3.6 if wide_lamp_cb.is_valid() and bool(wide_lamp_cb.call()) else 2.4
	lamp.color = Color(1.0, 0.86, 0.6)
	lamp.energy = 0.85
	lamp.position = Vector2(0, -14)
	player.add_child(lamp)
	_make_motes()

func leave() -> void:
	if not active or busy:
		return
	busy = true
	_freeze(true)
	var tw := create_tween()
	tw.tween_property(fade, "color:a", 1.0, 0.25)
	tw.tween_callback(_do_leave)
	tw.tween_property(fade, "color:a", 0.0, 0.25)
	tw.tween_callback(func():
		busy = false
		_freeze(false))

func _do_leave() -> void:
	active = false
	_clear_nodes()
	if lamp != null and is_instance_valid(lamp):
		lamp.queue_free()
	if motes != null and is_instance_valid(motes):
		motes.queue_free()
	player.position = outside_pos
	player.facing = PlayerMath.Facing.DOWN
	var r := ChunkGrid.world_rect_px()
	player.camera.limit_left = int(r.position.x)
	player.camera.limit_top = int(r.position.y)
	player.camera.limit_right = int(r.end.x)
	player.camera.limit_bottom = int(r.end.y)

func _add(n: Node) -> void:
	world.add_child(n)
	nodes.append(n)

func _near_floor(c: Vector2i, r: int) -> bool:
	for dy in range(-r, r + 1):
		for dx in range(-r, r + 1):
			if model.is_floor(c + Vector2i(dx, dy)):
				return true
	return false

func _build() -> void:
	var bg := ColorRect.new()
	bg.position = ORIGIN - Vector2(900, 700)
	bg.size = Vector2(1800 + CaveModel.W * 32, 1400 + CaveModel.H * 32)
	bg.color = Color(0.03, 0.03, 0.05)
	bg.z_index = -20
	_add(bg)
	var wall_runs: Array[Rect2] = []
	for y in range(0, CaveModel.H):
		var run_start := -1
		for x in range(0, CaveModel.W + 1):
			var c := Vector2i(x, y)
			var is_wall: bool = x < CaveModel.W and not model.is_floor(c)
			if is_wall and _near_floor(c, 2):
				var s := Sprite2D.new()
				s.centered = false
				s.texture = _t("cave_wall") if model.is_floor(c + Vector2i(0, 1)) else _t("cave_wall_top")
				s.position = px(c)
				s.z_index = -18
				_add(s)
			var solid := is_wall and _near_floor(c, 1)
			if solid and run_start < 0:
				run_start = x
			elif not solid and run_start >= 0:
				wall_runs.append(Rect2(px(Vector2i(run_start, y)), Vector2((x - run_start) * 32.0, 32.0)))
				run_start = -1
	for y in range(0, CaveModel.H):
		for x in range(0, CaveModel.W):
			var c := Vector2i(x, y)
			if model.is_floor(c):
				var s := Sprite2D.new()
				s.centered = false
				s.texture = _t("cave_floor")
				s.position = px(c)
				s.z_index = -19
				_add(s)
	var body := StaticBody2D.new()
	for r in wall_runs:
		var cs := CollisionShape2D.new()
		var rs := RectangleShape2D.new()
		rs.size = r.size
		cs.shape = rs
		cs.position = r.position + r.size * 0.5
		body.add_child(cs)
	_add(body)
	# a stone lip under the exit so the way out reads as a doorway
	for tc in model.torches:
		var ts := Sprite2D.new()
		ts.texture = _t("cave_torch")
		ts.hframes = 4
		ts.centered = false
		ts.position = px(tc) + Vector2(0, -16)
		ts.z_index = -17
		_add(ts)
		torch_sprites.append(ts)
		var l := PointLight2D.new()
		l.texture = Lantern.light_texture()
		l.texture_scale = 3.2
		l.color = Color(1.0, 0.7, 0.38)
		l.energy = 1.1
		l.position = px(tc) + Vector2(16, 38)
		_add(l)
	ore_nodes.clear()
	for c in model.ores:
		_make_ore(c)
	bats.clear()
	for sp in model.bat_spawns:
		_make_bat(px(sp) + Vector2(16, 16))
	for sp in model.slime_spawns:
		_make_crawler(px(sp) + Vector2(16, 16), "slime")
	for sp in model.crab_spawns:
		_make_crawler(px(sp) + Vector2(16, 16), "crab")
	_ladder_tiles()
	_build_rail()
	if model.is_boss_floor():
		_build_boss()

func _build_boss() -> void:
	var days: int = int(boss_ready_cb.call()) if boss_ready_cb.is_valid() else 0
	if days > 0:
		message.emit("Rubble lies where the Warden fell. It stirs again in %d day%s" % [days, "" if days == 1 else "s"])
		return
	boss = BossView.new().setup(px(model.boss_spawn()) + Vector2(16, 24), player, model)
	boss.hurt_player.connect(func(a, from, force):
		bitten.emit(a)
		player.push(from, force))
	boss.shake.connect(func(a, s): player.shake(a, s))
	boss.sound.connect(func(n, g, p): sound.emit(n, g, p))
	boss.message.connect(func(m): message.emit(m))
	boss.defeated.connect(func(pos): boss_defeated.emit(pos))
	boss.z_index = -10   # warning rings lie on the floor, under everyone's feet
	_add(boss)
	_add(boss.body)

## --- the mine cart ---
func _build_rail() -> void:
	if model.rail.is_empty():
		return
	var tex_rail := _t("cave_rail")
	for i in model.rail.size():
		var c: Vector2i = model.rail[i]
		var a: Vector2i = model.rail[i - 1] - c if i > 0 else Vector2i.ZERO
		var b: Vector2i = model.rail[i + 1] - c if i < model.rail.size() - 1 else Vector2i.ZERO
		var s := Sprite2D.new()
		s.texture = tex_rail
		s.hframes = 6
		s.frame = CartMath.tile_frame(a, b)
		s.centered = false
		s.position = px(c)
		s.z_index = -17
		_add(s)
	cart_pts = CartMath.points(model.rail)
	for i in cart_pts.size():
		cart_pts[i] = cart_pts[i] + ORIGIN
	for end in [0, cart_pts.size() - 1]:   # sprung buffers
		var buf := ColorRect.new()
		var dir: Vector2 = (cart_pts[end] - cart_pts[1 if end == 0 else end - 1]).normalized()
		buf.size = Vector2(6, 20) if absf(dir.x) > 0.5 else Vector2(22, 6)
		buf.position = cart_pts[end] + dir * 17.0 - buf.size * 0.5
		buf.color = Color(0.55, 0.2, 0.14)
		buf.z_index = -16
		_add(buf)
	cart = {"s": 0.0, "v": 0.0}
	cart_node = Node2D.new()
	cart_sprite = Sprite2D.new()
	cart_sprite.texture = _t("cave_cart")
	cart_sprite.hframes = 4
	cart_sprite.offset = Vector2(0, -22)
	cart_node.add_child(cart_sprite)
	heap_node = Node2D.new()
	heap_node.draw.connect(_draw_heap)
	cart_node.add_child(heap_node)
	var sh := World.make_shadow(18.0)
	sh.position = Vector2(0, -3)
	sh.show_behind_parent = true
	cart_node.add_child(sh)
	_add(cart_node)
	_place_cart()

func _place_cart() -> void:
	var at := CartMath.pos_at(cart_pts, float(cart["s"]))
	# the node sorts a little below the rider so the tub hides the legs
	cart_node.position = at + Vector2(0, 18)
	var dir := CartMath.dir_at(cart_pts, float(cart["s"]))
	var side := absf(dir.x) > 0.5
	cart_sprite.frame = (0 if side else 2) + int(cart_roll / 9.0) % 2
	heap_node.queue_redraw()

func _draw_heap() -> void:
	## Lumps piled on the rim, bottom row first, coloured by ore.
	var lumps := cargo.heap()
	if lumps.is_empty() or cart_sprite == null:
		return
	var side := cart_sprite.frame < 2
	var base := -29.0 + cart_sprite.frame % 2 if side else -26.0
	var rows: Array = [5, 4, 3, 2] if side else [4, 4, 3, 2]
	var spots: Array[Vector2] = []
	for r in rows.size():
		for k in int(rows[r]):
			if spots.size() < lumps.size():
				spots.append(Vector2(roundf((k - (int(rows[r]) - 1) * 0.5) * 5.0 - 2.5), base - r * 3.0 - (k + r) % 2))
	for at in spots:   # one dark edge round the whole heap, then the lumps on top of it
		heap_node.draw_rect(Rect2(at + Vector2(-1, -1), Vector2(7, 6)), Color(0.12, 0.08, 0.09))
	for i in spots.size():
		var at := spots[i]
		var col: Color = CartCargo.COLORS[lumps[i]]
		heap_node.draw_rect(Rect2(at + Vector2(1, 0), Vector2(3, 4)), col)
		heap_node.draw_rect(Rect2(at + Vector2(0, 1), Vector2(5, 2)), col)
		heap_node.draw_rect(Rect2(at + Vector2(1, 0), Vector2(2, 1)), col.lightened(0.35))
		heap_node.draw_rect(Rect2(at + Vector2(1, 3), Vector2(3, 1)), col.darkened(0.35))

func at_door_end() -> bool:
	return not cart.is_empty() and float(cart["s"]) <= DOOR_END

func _cart_in_reach() -> bool:
	return active and not busy and not cart.is_empty() and (riding or near_cart())

func load_cargo() -> bool:
	## G: ore from the bag into the cart.
	if not _cart_in_reach() or not bag_cb.is_valid():
		return false
	if absf(float(cart["v"])) > CartMath.BUMP_V:
		message.emit("Slow down before loading (Shift)")
		return false
	var n := cargo.load_from(bag_cb.call())
	if n <= 0:
		message.emit("The cart is full" if cargo.count() >= CartCargo.CAPACITY else "No ore in your bag to load")
		return false
	_place_cart()
	sound.emit("ball_post", 0.5, 0.8)
	message.emit("Loaded %d ore (cart %d/%d). Heavier: slow to start, long to stop" % [n, cargo.count(), CartCargo.CAPACITY])
	return true

func unload_cargo() -> bool:
	## X: cart to bag, only at the door end of the track.
	if not _cart_in_reach() or not bag_cb.is_valid():
		return false
	if cargo.count() == 0:
		message.emit("The cart is empty")
		return false
	if not at_door_end() or absf(float(cart["v"])) > CartMath.BUMP_V:
		message.emit("Stop the cart at the door end of the track to unload")
		return false
	var res := cargo.unload_to(bag_cb.call())
	_place_cart()
	if int(res["left"]) > 0:
		message.emit("Bag full: unloaded %d, %d ore still in the cart" % [res["moved"], res["left"]])
	else:
		message.emit("Unloaded %d ore into your bag" % res["moved"])
	return int(res["moved"]) > 0

func _return_cargo() -> void:
	## Leaving the floor or the mine (or passing out): the ore follows you; what the bag cannot take stays in the hold.
	if cart.is_empty() or cargo.count() == 0 or not bag_cb.is_valid():
		return
	var res := cargo.unload_to(bag_cb.call())
	var text := "Cart ore packed into your bag (%d)" % res["moved"]
	if int(res["left"]) > 0:
		text = "Bag full: %d ore stays safe in the mine cart" % res["left"]
	message.emit.call_deferred(text)   # after the floor's own arrival message

func scoop(id: String, n: int, pos: Vector2) -> int:
	## A ridden cart picks up ore lying beside the track. Returns how many it took.
	if not active or busy or not riding or cart.is_empty():
		return 0
	if pos.distance_to(CartMath.pos_at(cart_pts, float(cart["s"]))) > SCOOP_R:
		return 0
	var took := cargo.add(id, n)
	if took > 0:
		_place_cart()
		sound.emit("step_wood", 0.9, 1.5)
	return took

func spill(speed: float, at: Vector2) -> int:
	var lost := cargo.spill(CartMath.spill_count(speed, cargo.load_fraction(), cargo.count()))
	var total := 0
	for id in lost:
		total += int(lost[id])
		cargo_spilled.emit(String(id), int(lost[id]), at)
	if total > 0:
		message.emit("Too fast for that bend! %d ore spilled by the track" % total)
	return total

func near_cart() -> bool:
	return cart_node != null and not cart.is_empty() and player.position.distance_to(CartMath.pos_at(cart_pts, float(cart["s"]))) < 42.0

func board() -> bool:
	if riding or not near_cart():
		return false
	riding = true
	player.set_physics_process(false)
	player.velocity = Vector2.ZERO
	player.move_v = Vector2.ZERO
	sound.emit("door_close", 0.8, 0.7)
	message.emit("In the cart. Move along the rails to pump, Shift brakes, E hops off")
	_seat_player()
	return true

func hop_off() -> bool:
	if not riding:
		return false
	if absf(float(cart["v"])) > CartMath.BUMP_V * 1.5:
		message.emit("Too fast to jump off. Brake first (Shift)")
		return false
	var at := CartMath.pos_at(cart_pts, float(cart["s"]))
	var dir := CartMath.dir_at(cart_pts, float(cart["s"]))
	var across := Vector2(-dir.y, dir.x)
	for off in [across * 30.0, -across * 30.0, -dir * 32.0, dir * 32.0]:
		var c := model_cell(at + off)
		if model.is_floor(c) and not model.ores.has(c):
			riding = false
			player.position = at + off
			player.set_physics_process(true)
			cart["v"] = 0.0
			return true
	return false

func interact() -> bool:
	if not active or busy:
		return false
	return hop_off() if riding else board()

func _seat_player() -> void:
	player.position = CartMath.pos_at(cart_pts, float(cart["s"])) + Vector2(0, 8)

func cart_tick(d: float, input: Vector2, braking: bool) -> void:
	## A parked, empty cart keeps its brake on.
	if cart.is_empty() or not riding:
		return
	var dir := CartMath.dir_at(cart_pts, float(cart["s"]))
	var res := CartMath.step(cart, cart_pts, CartMath.pump_from_input(input, dir), braking, d, cargo.load_fraction())
	var v := float(cart["v"])
	cart_roll += absf(v) * d
	if res["jolt"]:
		player.shake(1.2, 0.18)
		sound.emit("mine", 0.5, 1.6)
		_sparks(CartMath.pos_at(cart_pts, float(cart["s"])), 12)
		spill(float(res["jolt_v"]), CartMath.pos_at(cart_pts, float(res["jolt_s"])))
	if float(res["bump"]) > 0.0:
		player.shake(1.0 + float(res["bump"]) / 150.0, 0.2)
		sound.emit("ball_post", 0.8, 0.6)
	if braking and absf(v) > 40.0:
		rumble_t -= d
		if rumble_t <= 0.0:
			rumble_t = 0.12
			_sparks(CartMath.pos_at(cart_pts, float(cart["s"])) - dir * signf(v) * 10.0, 4)
	elif absf(v) > 20.0:
		rumble_t -= d
		if rumble_t <= 0.0:
			rumble_t = clampf(32.0 / absf(v), 0.1, 0.6)
			sound.emit("step_wood", 0.7, 0.7)   # wheels over the rail joints
	_place_cart()
	_seat_player()
	var face := dir * (1.0 if v >= 0.0 else -1.0)
	if absf(v) > 8.0:
		player.facing = PlayerMath.facing_for(face, player.facing)
	if absf(v) > 90.0:
		_ram(CartMath.pos_at(cart_pts, float(cart["s"])), face, absf(v))

func _ram(at: Vector2, dir: Vector2, speed: float) -> void:
	## A fast cart bowls monsters over.
	for b in bats.duplicate():
		var m: Dictionary = b["data"]
		if float(m["down"]) > 0.0 or (m["pos"] as Vector2).distance_to(at) > 24.0:
			continue
		_hurt_monster(b, speed * 0.1, (dir + Vector2(-dir.y, dir.x) * 0.7).normalized() * speed)

func _sparks(at: Vector2, n: int) -> void:
	var p := CPUParticles2D.new()
	p.position = at + Vector2(0, 6)
	p.one_shot = true
	p.emitting = true
	p.explosiveness = 1.0
	p.amount = n
	p.lifetime = 0.3
	p.direction = Vector2(0, -1)
	p.spread = 100.0
	p.initial_velocity_min = 40.0
	p.initial_velocity_max = 90.0
	p.gravity = Vector2(0, 260)
	p.color = Color(1.0, 0.82, 0.35)
	p.z_index = 3
	_add(p)
	get_tree().create_timer(0.7).timeout.connect(p.queue_free)

func _make_ore(c: Vector2i) -> void:
	var kind: String = model.ores[c]["kind"]
	var b := StaticBody2D.new()
	b.position = px(c) + Vector2(16, 30)
	var s := Sprite2D.new()
	s.texture = _t("cave_ore_" + kind)
	s.offset = Vector2(0, -16)
	b.add_child(s)
	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(30, 26)
	cs.shape = rs
	cs.position = Vector2(0, -13)
	b.add_child(cs)
	var sh := World.make_shadow(22.0)
	sh.position = Vector2(0, -2)
	b.add_child(sh)
	_add(b)
	ore_nodes[c] = b

func _splat(pos: Vector2, kind: String) -> void:
	var p := CPUParticles2D.new()
	p.position = pos + Vector2(0, -8)
	p.emitting = true
	p.one_shot = true
	p.explosiveness = 0.9
	p.amount = 14 if kind != "bat" else 8
	p.lifetime = 0.7
	p.direction = Vector2(0, -1)
	p.spread = 140.0
	p.initial_velocity_min = 30.0
	p.initial_velocity_max = 80.0
	p.gravity = Vector2(0, 220)
	p.scale_amount_min = 1.0
	p.scale_amount_max = 2.5
	p.color = CaveModel.splat_color(kind)
	_add(p)
	get_tree().create_timer(1.2).timeout.connect(p.queue_free)

func _make_motes() -> void:
	## Dust drifting through the miner's lamp light.
	motes = CPUParticles2D.new()
	motes.amount = 26
	motes.lifetime = 5.0
	motes.preprocess = 5.0
	motes.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	motes.emission_rect_extents = Vector2(210, 130)
	motes.direction = Vector2(0.4, -1)
	motes.spread = 60.0
	motes.initial_velocity_min = 2.0
	motes.initial_velocity_max = 7.0
	motes.gravity = Vector2.ZERO
	motes.scale_amount_min = 0.8
	motes.scale_amount_max = 1.4
	motes.color = Color(1.0, 0.9, 0.7, 0.35)
	motes.local_coords = false
	motes.z_index = 5
	player.add_child(motes)

func _ladder_tiles() -> void:
	var up := Sprite2D.new()
	up.texture = _t("cave_ladder_up")
	up.centered = false
	up.position = px(model.entrance + Vector2i(0, 1))
	up.z_index = -18
	_add(up)
	if model.has_ladder_down():
		var dn := Sprite2D.new()
		dn.texture = _t("cave_ladder_down")
		dn.centered = false
		dn.position = px(model.ladder_down)
		dn.z_index = -18
		_add(dn)
		var l := PointLight2D.new()
		l.texture = Lantern.light_texture()
		l.texture_scale = 1.6
		l.color = Color(1.0, 0.8, 0.5)
		l.energy = 0.8
		l.position = px(model.ladder_down) + Vector2(16, 16)
		_add(l)

func _make_crawler(p: Vector2, kind: String) -> void:
	var n := Node2D.new()
	n.position = p
	var s := Sprite2D.new()
	s.texture = _t("cave_" + kind)
	s.hframes = 4
	s.offset = Vector2(0, -14)
	n.add_child(s)
	var sh := World.make_shadow(14.0)
	sh.position = Vector2(0, 2)
	n.add_child(sh)
	_add(n)
	bats.append({"data": CaveModel.new_slime(p) if kind == "slime" else CaveModel.new_crab(p), "node": n, "sprite": s})

func _make_bat(p: Vector2) -> void:
	var n := Node2D.new()
	n.position = p
	var s := Sprite2D.new()
	s.texture = _t("cave_bat")
	s.hframes = 4
	s.offset = Vector2(0, -14)
	n.add_child(s)
	var sh := World.make_shadow(12.0)
	sh.position = Vector2(0, 2)
	n.add_child(sh)
	_add(n)
	bats.append({"data": CaveModel.new_bat(p), "node": n, "sprite": s})

func target_cell() -> Vector2i:
	return PlayerMath.facing_tile(player.position, player.facing) - CELL_OFFSET

func use_tool(tool: String, power: int) -> String:
	## Pickaxe on the faced ore. Returns the toast text ("" = nothing happened).
	if not active or busy:
		return ""
	if tool != "pickaxe":
		return ""
	var c := target_cell()
	var res := model.hit_ore(c, power)
	if res.is_empty():
		return ""
	var node: Node2D = ore_nodes.get(c)
	if res.has("id"):
		if node != null and is_instance_valid(node):
			node.queue_free()
		ore_nodes.erase(c)
		ore_broken.emit(String(res["id"]), int(res["n"]), px(c) + Vector2(16, 20), String(res["kind"]))
		return "Got %s" % String(res["id"]).replace("_", " ")
	if node != null and is_instance_valid(node):
		var tw := create_tween()
		tw.tween_property(node, "position:x", node.position.x + 2.0, 0.04)
		tw.tween_property(node, "position:x", node.position.x - 2.0, 0.04)
		tw.tween_property(node, "position:x", node.position.x, 0.04)
	return "Hit"

func club_swing(damage: float, reach: float, force: float) -> int:
	## Cone test against bats; returns how many were hit.
	if not active:
		return 0
	var face := CombatModel.facing_vec(player.facing)
	var origin := player.position + Vector2(0, -8)
	var hits := 0
	for b in bats.duplicate():
		var d: Dictionary = b["data"]
		var bp: Vector2 = (d["pos"] as Vector2) + Vector2(0, -14)
		if not CombatModel.in_swing(origin, face, bp, reach):
			continue
		hits += 1
		var dmg: float = CaveModel.crab_damage(damage) if d.get("kind", "bat") == "crab" else damage
		_hurt_monster(b, dmg, (bp - origin).normalized() * 220.0 * force)
	if boss != null and boss.club_swing(origin, face, damage, reach):
		hits += 1
	return hits

func _hurt_monster(b: Dictionary, dmg: float, knock: Vector2) -> void:
	var d: Dictionary = b["data"]
	d["hp"] = CombatModel.hit(float(d["hp"]), dmg)
	d["vel"] = knock
	d["down"] = 0.35
	(b["sprite"] as Sprite2D).modulate = Color(1.6, 1.6, 1.6)
	if CombatModel.is_down(float(d["hp"])):
		_splat(d["pos"], String(d.get("kind", "bat")))
		if d.get("kind", "bat") == "bat":
			bat_down.emit(d["pos"])
		else:
			monster_down.emit(String(d["kind"]), d["pos"])
		(b["node"] as Node).queue_free()
		bats.erase(b)

func rel() -> Vector2i:
	return model_cell(player.position)

func prompt() -> String:
	if not active or busy:
		return ""
	if riding or near_cart():
		return cart_prompt()
	var where := "Warden's Hall" if model.is_boss_floor() else "Floor %d/%d" % [floor_no, CaveModel.MAX_FLOOR]
	return "%s   Pickaxe: ore   Club: monsters   %sSouth: up" % [where, "Ladder down: deeper   " if model.has_ladder_down() else ""]

func cart_prompt() -> String:
	var n := cargo.count()
	var hold := "Cart %d/%d" % [n, CartCargo.CAPACITY]
	var slow := absf(float(cart["v"])) <= CartMath.BUMP_V
	var keys := ""
	if slow:
		keys = "G: load ore   "
		if n > 0:
			keys += "X: unload   " if at_door_end() else "(unload at door end)   "
	if not riding:
		return "E: ride   %s%s" % [keys, hold]
	if slow:
		return "Move: pump   %sE: off   %s" % [keys, hold]
	return "Move: pump   Shift: brake   E: off   %s" % hold

func _process(d: float) -> void:
	if not active or busy:
		return
	t += d
	for ts in torch_sprites:
		(ts as Sprite2D).frame = int(t * 8.0 + (ts as Sprite2D).position.x * 0.07) % 4
	if riding:
		cart_tick(minf(d, 0.05), Input.get_vector("move_left", "move_right", "move_up", "move_down"), Input.is_action_pressed("sprint"))
	if boss != null:
		boss.tick(minf(d, 0.05))
	var pp := player.position
	for b in bats:
		var data: Dictionary = b["data"]
		var old: Vector2 = data["pos"]
		var kind: String = data.get("kind", "bat")
		if kind == "bat":
			CaveModel.bat_step(data, pp + Vector2(0, -10), d)
		else:
			CaveModel.crawler_step(data, pp, d)
		var nc := model_cell(data["pos"])
		if not model.is_floor(nc) or (kind != "bat" and model.ores.has(nc)):
			data["pos"] = old
			data["vel"] = Vector2.ZERO
		(b["node"] as Node2D).position = data["pos"]
		var spr: Sprite2D = b["sprite"]
		spr.frame = int(t * (12.0 if kind == "bat" else 7.0) + float(data["t"])) % 4
		if kind == "slime":
			spr.scale = CaveModel.slime_squash(float(data["t"]))
		if kind != "bat" and (data["vel"] as Vector2).x != 0.0:
			spr.flip_h = (data["vel"] as Vector2).x < 0.0
		spr.modulate = spr.modulate.lerp(Color.WHITE, 0.2)
		var dmg: float = CaveModel.bat_bite(data, pp + Vector2(0, -10)) if kind == "bat" else CaveModel.crawler_bite(data, pp)
		if dmg > 0.0:
			bitten.emit(dmg)
			if not riding:
				player.push(data["pos"], CaveModel.bite_force(kind))
			player.shake(0.6, 0.12)
			data["vel"] = (data["pos"] - pp).normalized() * 160.0
	var c := rel()
	if riding:
		return
	if model.has_ladder_down():
		var near := Vector2(c - model.ladder_down).length()
		if ladder_lock and near > 1.8:
			ladder_lock = false
		elif not ladder_lock and c == model.ladder_down:
			change_floor(floor_no + 1, true)
			return
	if c.y >= model.entrance.y + 1 and absi(c.x - model.entrance.x) <= 3:
		if floor_no > 1:
			change_floor(floor_no - 1, false)
		else:
			leave()
