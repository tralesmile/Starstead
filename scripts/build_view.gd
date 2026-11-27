class_name BuildView
extends Node2D
## Build mode: B toggles, Q cycles the piece, F places, X demolishes. The ghost is green when valid, red when not.
## Placed pieces are sprites in the y-sorted world; solid ones get a collider.

const WALL_SHEET: Texture2D = preload("res://assets/sprites/build_wall_auto.png")
const WALL_LINK := ["wall", "door"]
const FENCE_SHEET: Texture2D = preload("res://assets/sprites/build_fence_auto.png")
var world: Node2D
var gen: WorldGen
var player: Player
var active := false
var idx := 0
var ghost: Sprite2D
var label: Label
var reason := ""
var _roofs: Dictionary = {}  # Vector2i -> roof Sprite2D
var inside := false
var _sprites: Dictionary = {}  # Vector2i -> Node2D
const DOOR_SHEET: Texture2D = preload("res://assets/sprites/build_door_anim.png")
var _doors: Dictionary = {}  # Vector2i -> {"s": Sprite2D, "open": 0..1, "want": bool}
signal door_moved(opening: bool)
signal message(text: String)

func setup(w: Node2D, g: WorldGen, p: Player) -> void:
	world = w; gen = g; player = p
	ghost = Sprite2D.new()
	ghost.z_index = 50
	ghost.centered = false
	add_child(ghost)
	ghost.visible = false
	for c in GameState.build.placed:
		_spawn(c, GameState.build.placed[c])

func piece() -> String:
	return BuildModel.PIECES[idx]

func _tex(piece_id: String) -> Texture2D:
	return load("res://assets/sprites/%s.png" % GameState.build.defs[piece_id].sprite)

func _spawn(cell: Vector2i, piece_id: String) -> void:
	if _sprites.has(cell):   # furniture set down on a floor replaces that sprite (the floor is redrawn under it)
		_sprites[cell].queue_free()
		_sprites.erase(cell)
	var body := StaticBody2D.new()
	body.position = Vector2(cell.x * 32 + 16, cell.y * 32 + 32)
	var s := Sprite2D.new()
	s.texture = _tex(piece_id)
	s.centered = false
	s.offset = Vector2(-16, -s.texture.get_height())
	if bool(GameState.build.defs[piece_id].get("roof", false)):
		s.z_index = 40  # over the player; faded while you are inside
		s.offset = Vector2(-16, -32 - 8)
		_roofs[cell] = s
	if piece_id == "fence":
		_fence_frame(s, cell)
	if piece_id == "wall":
		_wall_frame(s, cell)
	if piece_id == "door":
		s.texture = DOOR_SHEET
		s.region_enabled = true
		s.region_rect = Rect2(0, 0, 32, 48)
		s.offset = Vector2(-16, -48)
		_doors[cell] = {"s": s, "open": 0.0, "want": false}
	if piece_id == "floor":
		s.z_index = -8  # under props and the player
		body.position = Vector2(cell.x * 32 + 16, cell.y * 32 + 32)
	body.add_child(s)
	if GameState.build.under.has(cell):
		var fl := Sprite2D.new()
		fl.texture = _tex(String(GameState.build.under[cell]))
		fl.centered = false
		fl.offset = Vector2(-16, -32)
		fl.z_index = -8
		body.add_child(fl)
	if bool(GameState.build.defs[piece_id].get("light", false)):
		var l := PointLight2D.new()   # warm lamp pool, driven by main via the night_lights group
		l.texture = Lantern.light_texture()
		l.texture_scale = 2.4
		l.color = Color(1.0, 0.82, 0.5)
		l.position = Vector2(0, -34)
		l.energy = 0.0
		l.visible = false
		l.add_to_group("night_lights")
		body.add_child(l)
	if GameState.build.defs[piece_id].solid:
		var cs := CollisionShape2D.new()
		var r := RectangleShape2D.new()
		var furn: bool = GameState.build.is_furniture(piece_id)
		r.size = Vector2(28, 22) if furn else Vector2(32, 32)   # furniture leaves a little room to squeeze past
		cs.shape = r
		cs.position = Vector2(0, -13) if furn else Vector2(0, -16)
		body.add_child(cs)
	world.add_child(body)
	_sprites[cell] = body
	if piece_id == "fence" or piece_id == "wall" or piece_id == "door":
		_refresh_fence_neighbours(cell)

func _wall_frame(s: Sprite2D, cell: Vector2i) -> void:
	## Connected walls: same mask idea as fences (N1|E2|S4|W8), walls and doors link.
	s.texture = WALL_SHEET
	s.region_enabled = true
	s.region_rect = Rect2(Autotile.atlas_index(Autotile.mask(GameState.build.placed, cell, WALL_LINK)) * 32, 0, 32, 48)
	s.offset = Vector2(-16, -48)

func _fence_frame(s: Sprite2D, cell: Vector2i) -> void:
	## Connected fences: the sheet frame follows which neighbours are fences (Autotile mask N1|E2|S4|W8).
	s.texture = FENCE_SHEET
	s.region_enabled = true
	s.region_rect = Rect2(Autotile.atlas_index(Autotile.mask(GameState.build.placed, cell, ["fence"])) * 32, 0, 32, 32)
	s.offset = Vector2(-16, -32)

func _refresh_fence_neighbours(cell: Vector2i) -> void:
	for d in [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]:
		var n: Vector2i = cell + d
		if not _sprites.has(n):
			continue
		var kind = GameState.build.placed.get(n)
		if kind == "fence":
			_fence_frame(_sprites[n].get_child(0) as Sprite2D, n)
		elif kind == "wall":
			_wall_frame(_sprites[n].get_child(0) as Sprite2D, n)

func _update_doors(d: float) -> void:
	for c in _doors:
		var st: Dictionary = _doors[c]
		var want := DoorMath.wants_open(player.position.distance_to(Vector2(c) * 32.0 + Vector2(16, 16)), st.want)
		if want != st.want:
			door_moved.emit(want)
		st.want = want
		st.open = DoorMath.step(st.open, want, d)
		(st.s as Sprite2D).region_rect = Rect2(DoorMath.frame(st.open) * 32, 0, 32, 48)

func _unspawn(cell: Vector2i) -> void:
	_roofs.erase(cell)
	_doors.erase(cell)
	if _sprites.has(cell):
		_sprites[cell].queue_free()
		_sprites.erase(cell)
	_refresh_fence_neighbours(cell)

func target() -> Vector2i:
	return PlayerMath.facing_tile(player.position, player.facing)

func _blocked(c: Vector2i) -> bool:
	return GameState.nodes.is_solid(c) or GameState.farm.soil.has(c)

func _update_roofs(d: float) -> void:
	## Roofs fade out while the player stands on an enclosed floor, back in outside.
	var pc := Vector2i(floori(player.position.x / 32.0), floori(player.position.y / 32.0))
	inside = _roofs.size() > 0 and GameState.build.placed.has(pc) and GameState.build.placed[pc] in ["floor", "roof"] and GameState.build.is_enclosed(pc)
	var want := 0.0 if inside else 1.0
	for c in _roofs:
		var s: Sprite2D = _roofs[c]
		s.modulate.a = move_toward(s.modulate.a, want, d * 4.0)

var blueprint := "hut"

func stamp_blueprint(name: String) -> void:
	## Place the blueprint with its centre-top at the faced cell; only if every cell is free and dry.
	var o := target() - Vector2i(1, 0)
	var bm: BuildModel = GameState.build
	for e in BuildModel.BLUEPRINTS[name].cells:
		var c := o + Vector2i(int(e[0]), int(e[1]))
		var why := bm.check(c, "floor", gen.sdf_at(c.x, c.y), _blocked(c), GameState.bag) if bm.placed.has(c) == false else "Occupied"
		if why == "Occupied" or why == "Too close to water" or why == "Something is in the way":
			message.emit("No room: " + why)
			return
	if not GameState.bag.count("wood") >= int(bm.blueprint_cost(name).get("wood", 0)):
		message.emit("Need %d wood" % int(bm.blueprint_cost(name).get("wood", 0)))
		return
	var n := bm.stamp(name, o, GameState.bag)
	for e in BuildModel.BLUEPRINTS[name].cells:
		var c := o + Vector2i(int(e[0]), int(e[1]))
		if bm.placed.has(c) and not _sprites.has(c):
			_spawn(c, bm.placed[c])
	message.emit("Built %s (%d pieces)" % [BuildModel.BLUEPRINTS[name].name, n])

func _process(_d: float) -> void:
	_update_roofs(_d)
	_update_doors(_d)
	ghost.visible = active
	if not active:
		return
	var c := target()
	var pid := piece()
	ghost.texture = _tex(pid)
	ghost.offset = Vector2(0, -(ghost.texture.get_height() - 32))
	ghost.position = Vector2(c) * 32.0
	reason = GameState.build.check(c, pid, gen.sdf_at(c.x, c.y), _blocked(c), GameState.bag)
	if reason == "":
		ghost.modulate = Color(0.5, 1.0, 0.5, 0.65)
	else:
		ghost.modulate = Color(1.0, 0.4, 0.4, 0.65)

func handle_key(e: InputEvent) -> bool:
	## Returns true when the event was consumed by build mode.
	if e is InputEventKey and e.pressed and not e.echo:
		if e.keycode == KEY_B:
			active = not active
			message.emit("Build mode ON (Q piece, F place, R blueprint, H build it, X demolish)" if active else "Build mode off")
			return true
		if not active:
			return false
		if e.keycode == KEY_Q:
			idx = (idx + 1) % BuildModel.PIECES.size()
			message.emit(RoomModel.piece_label(GameState.build.defs, DataDB.load_json("rooms"), piece()))
			return true
		if e.keycode == KEY_R:
			blueprint = BuildModel.next_blueprint(blueprint)
			message.emit("Blueprint: %s (H to build, %d wood)" % [BuildModel.BLUEPRINTS[blueprint].name, int(GameState.build.blueprint_cost(blueprint).get("wood", 0))])
			return true
		if e.keycode == KEY_H:
			stamp_blueprint(blueprint)
			return true
		if e.keycode == KEY_X:
			var c := target()
			if GameState.build.remove_piece(c, GameState.bag):
				_unspawn(c)
				if GameState.build.placed.has(c):
					_spawn(c, GameState.build.placed[c])
				message.emit("Removed")
			return true
	if active and e.is_action_pressed("use_tool"):
		var c := target()
		var why := GameState.build.place(c, piece(), gen.sdf_at(c.x, c.y), _blocked(c), GameState.bag)
		if why == "":
			_spawn(c, piece())
		else:
			message.emit(why)
		return true
	return false
