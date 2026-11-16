class_name BuildView
extends Node2D
## Build mode: B toggles, Q cycles the piece, F places, X demolishes. The ghost is green when valid, red when not.
## Placed pieces are sprites in the y-sorted world; solid ones get a collider.

var world: Node2D
var gen: WorldGen
var player: Player
var active := false
var idx := 0
var ghost: Sprite2D
var label: Label
var reason := ""
var _sprites: Dictionary = {}  # Vector2i -> Node2D
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
	var body := StaticBody2D.new()
	body.position = Vector2(cell.x * 32 + 16, cell.y * 32 + 32)
	var s := Sprite2D.new()
	s.texture = _tex(piece_id)
	s.centered = false
	s.offset = Vector2(-16, -s.texture.get_height())
	if piece_id == "floor":
		s.z_index = -8  # under props and the player
		body.position = Vector2(cell.x * 32 + 16, cell.y * 32 + 32)
	body.add_child(s)
	if GameState.build.defs[piece_id].solid:
		var cs := CollisionShape2D.new()
		var r := RectangleShape2D.new()
		r.size = Vector2(32, 32)
		cs.shape = r
		cs.position = Vector2(0, -16)
		body.add_child(cs)
	world.add_child(body)
	_sprites[cell] = body

func _unspawn(cell: Vector2i) -> void:
	if _sprites.has(cell):
		_sprites[cell].queue_free()
		_sprites.erase(cell)

func target() -> Vector2i:
	return PlayerMath.facing_tile(player.position, player.facing)

func _blocked(c: Vector2i) -> bool:
	return GameState.nodes.is_solid(c) or GameState.farm.soil.has(c)

func _process(_d: float) -> void:
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
			message.emit("Build mode ON (Q piece, F place, X demolish)" if active else "Build mode off")
			return true
		if not active:
			return false
		if e.keycode == KEY_Q:
			idx = (idx + 1) % BuildModel.PIECES.size()
			message.emit(GameState.build.defs[piece()].name)
			return true
		if e.keycode == KEY_X:
			var c := target()
			if GameState.build.remove_piece(c, GameState.bag):
				_unspawn(c)
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
