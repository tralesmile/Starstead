class_name CaveView
extends Node
## The Highlands mine in play. Like InteriorView: fade out, the cavern (CaveModel) is built far from the map,
## the player is moved in and gets a miner's lamp; torches light the walls, ore breaks under the pickaxe,
## bats chase and are driven off with the club. Walking off the bottom edge (or Esc) returns to the cave mouth.

signal ore_broken(id: String, n: int, pos: Vector2, kind: String)
signal bat_down(pos: Vector2)
signal bitten(amount: float)
signal message(msg: String)

const ORIGIN := Vector2(30016, 30016)
const CELL_OFFSET := Vector2i(938, 938)   # ORIGIN / 32
const DARK := Color(0.52, 0.52, 0.66)

var world: Node2D
var player: Player
var model: CaveModel
var model_day := -1
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
	if model == null or model_day != day:
		model = CaveModel.generate(day)
		model_day = day
	_freeze(true)
	var tw := create_tween()
	tw.tween_property(fade, "color:a", 1.0, 0.25)
	tw.tween_callback(_do_enter)
	tw.tween_property(fade, "color:a", 0.0, 0.25)
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
	player.position = px(model.entrance) + Vector2(16, 16)
	player.facing = PlayerMath.Facing.UP
	var c := ORIGIN + Vector2(CaveModel.W, CaveModel.H) * 16.0
	player.camera.limit_left = int(c.x - CaveModel.W * 16 - 40)
	player.camera.limit_right = int(c.x + CaveModel.W * 16 + 40)
	player.camera.limit_top = int(c.y - CaveModel.H * 16 - 40)
	player.camera.limit_bottom = int(c.y + CaveModel.H * 16 + 40)
	lamp = PointLight2D.new()
	lamp.texture = Lantern.light_texture()
	lamp.texture_scale = 2.4
	lamp.color = Color(1.0, 0.86, 0.6)
	lamp.energy = 0.85
	lamp.position = Vector2(0, -14)
	player.add_child(lamp)

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
	for n in nodes:
		if is_instance_valid(n):
			n.queue_free()
	nodes.clear()
	ore_nodes.clear()
	bats.clear()
	torch_sprites.clear()
	if lamp != null and is_instance_valid(lamp):
		lamp.queue_free()
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
		d["hp"] = CombatModel.hit(float(d["hp"]), damage)
		d["vel"] = (bp - origin).normalized() * 220.0 * force
		d["down"] = 0.35
		(b["sprite"] as Sprite2D).modulate = Color(1.6, 1.6, 1.6)
		if CombatModel.is_down(float(d["hp"])):
			bat_down.emit(d["pos"])
			(b["node"] as Node).queue_free()
			bats.erase(b)
	return hits

func rel() -> Vector2i:
	return model_cell(player.position)

func prompt() -> String:
	if not active or busy:
		return ""
	return "Pickaxe: mine ore   Club: bats   Walk south / Esc: leave"

func _process(d: float) -> void:
	if not active or busy:
		return
	t += d
	for ts in torch_sprites:
		(ts as Sprite2D).frame = int(t * 8.0 + (ts as Sprite2D).position.x * 0.07) % 4
	var pp := player.position
	for b in bats:
		var data: Dictionary = b["data"]
		var old: Vector2 = data["pos"]
		CaveModel.bat_step(data, pp + Vector2(0, -10), d)
		var nc := model_cell(data["pos"])
		if not model.is_floor(nc):
			data["pos"] = old
			data["vel"] = Vector2.ZERO
		(b["node"] as Node2D).position = data["pos"]
		var spr: Sprite2D = b["sprite"]
		spr.frame = int(t * 12.0 + float(data["t"])) % 4
		spr.modulate = spr.modulate.lerp(Color.WHITE, 0.2)
		var dmg := CaveModel.bat_bite(data, pp + Vector2(0, -10))
		if dmg > 0.0:
			bitten.emit(dmg)
			data["vel"] = (data["pos"] - pp).normalized() * 160.0
	var c := rel()
	if c.y >= model.entrance.y + 1 and absi(c.x - model.entrance.x) <= 3:
		leave()
