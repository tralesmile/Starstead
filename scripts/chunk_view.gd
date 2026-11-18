class_name ChunkView
extends RefCounted
## Builds one streamed neighbour chunk into the World (ground shader rect, shore + deep-water collision,
## y-sorted trees/rocks/bushes that ResourceNodes can chop/mine, reeds, lily pads, tufts, flowers)
## and frees it again when the player is far away. Cells are world cells (homestead = 0..63).

var chunk: Vector2i
var gen: WorldGen
var origin := Vector2i.ZERO
var nodes: Array[Node] = []
var cells: Array[Vector2i] = []        # prop cells registered in World.props
var layer_cells: Array[Vector2i] = []
var reeds: Array = []
var lilies: Array = []
var flowers: Array = []
var sign_cells: Array[Vector2i] = []

func build(world: World, g: WorldGen) -> void:
	gen = g
	chunk = g.chunk
	origin = ChunkGrid.origin_cell(chunk)
	_ground(world)
	_collision(world)
	_props(world)
	_decor(world)
	_flowers(world)
	_signs(world)

func _add(world: World, n: Node) -> void:
	world.add_child(n)
	nodes.append(n)

func _ground(world: World) -> void:
	var rect := ColorRect.new()
	rect.size = Vector2(WorldGen.SIZE * 32, WorldGen.SIZE * 32)
	rect.position = Vector2(origin) * 32.0
	rect.z_index = -10
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := ShaderMaterial.new()
	m.shader = load("res://assets/shaders/ground.gdshader")
	gen.stream_ref = world.stream
	m.set_shader_parameter("data", ImageTexture.create_from_image(World.data_image(gen, 1)))
	m.set_shader_parameter("data_size", float(WorldGen.SIZE + 2))
	m.set_shader_parameter("data_pad", 1.0)
	m.set_shader_parameter("chunk_px", float(WorldGen.SIZE * 32))
	m.set_shader_parameter("origin_tiles", Vector2(origin))
	rect.material = m
	world.chunk_mats.append(m)
	_add(world, rect)

func _collision(world: World) -> void:
	for y in WorldGen.SIZE:
		for x in WorldGen.SIZE:
			if gen.sdf_at(x, y) <= -2.5 and WorldGen.is_water(gen.tile_at(x, y)):
				var c := origin + Vector2i(x, y)
				world.layer.set_cell(c, 0, Vector2i(WorldGen.WATER_DEEP, 0))
				layer_cells.append(c)
	var rects := ShoreMath.blocked_rects(func(t: Vector2i) -> float: return gen.sdf_at(clampi(t.x, 0, WorldGen.SIZE - 1), clampi(t.y, 0, WorldGen.SIZE - 1)), WorldGen.SIZE, func(_t: Vector2i) -> bool: return false)
	var shore := StaticBody2D.new()
	shore.position = Vector2(origin) * 32.0
	for r in rects:
		var cs := CollisionShape2D.new()
		var rs := RectangleShape2D.new()
		rs.size = r.size
		cs.shape = rs
		cs.position = r.position + r.size * 0.5
		shore.add_child(cs)
	_add(world, shore)

func _props(world: World) -> void:
	for p in gen.trees:
		var wc := origin + p
		var b := world.make_prop(World.PROP_TEX[gen.tree_kinds[p]], wc, Vector2(12, 8), Vector2(0, -44))
		world.register_prop(wc, b, true)
		var st := world.prop_stump(wc, b)
		nodes.append(st)
		nodes.append(b)
		cells.append(wc)
		Outline.set_sway(b.get_child(0), 2.0 if gen.tree_kinds[p] == "oak" else 1.4, wc.x * 0.7 + wc.y * 0.3)
		if world.nodes_ref != null:
			world.nodes_ref.add_once("tree", wc)
	for p in gen.rocks:
		var wc := origin + p
		var b := world.make_prop(World.PROP_TEX.rock, wc, Vector2(24, 14), Vector2(0, -12))
		world.register_prop(wc, b, false)
		nodes.append(b)
		cells.append(wc)
		if world.nodes_ref != null:
			world.nodes_ref.add_once("rock", wc)
	for p in gen.bushes:
		var wc := origin + p
		var b := world.make_prop(World.PROP_TEX.bush, wc, Vector2(20, 8), Vector2(0, -12))
		nodes.append(b)
		Outline.set_sway(b.get_child(0), 1.0, wc.x + wc.y)

func _decor(world: World) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = gen.seed_value + 5 + chunk.x * 31 + chunk.y * 977
	var lily := load("res://assets/sprites/lily_pads.png")
	for c in gen.lilies:
		for k in r.randi_range(1, 3):
			var s := LilyPad.new()
			s.texture = lily
			s.region_enabled = true
			s.region_rect = Rect2(16 * r.randi_range(0, 3), 0, 16, 16)
			s.base = Vector2(origin + c) * 32.0 + Vector2(r.randf_range(6, 26), r.randf_range(6, 26)).round()
			s.position = s.base
			s.phase = r.randf_range(0.0, TAU)
			s.player = world.player_ref
			s.z_index = -5
			_add(world, s)
	var reed := load("res://assets/sprites/reeds.png")
	for c in gen.reeds:
		var s := Sprite2D.new()
		s.texture = reed
		s.flip_h = r.randf() < 0.5
		s.position = Vector2(origin + c) * 32.0 + Vector2(16 + r.randi_range(-6, 6), 12)
		Outline.set_sway(s, 2.0, c.x * 1.3 + c.y)
		_add(world, s)
	var tuft := load("res://assets/sprites/grass_tuft.png")
	for c in gen.tufts:
		var s := Sprite2D.new()
		s.texture = tuft
		s.flip_h = r.randf() < 0.5
		s.position = Vector2(origin + c) * 32.0 + Vector2(r.randi_range(6, 26), r.randi_range(14, 28))
		Outline.set_sway(s, 1.5, c.x * 0.9 + c.y)
		s.z_index = -3
		_add(world, s)

func _flowers(world: World) -> void:
	var noise := FastNoiseLite.new()
	noise.seed = gen.seed_value * 31 + 7
	noise.frequency = 0.09
	var hue := FastNoiseLite.new()
	hue.seed = gen.seed_value * 17 + 3
	hue.frequency = 0.05
	var r := RandomNumberGenerator.new()
	r.seed = gen.seed_value + 99 + chunk.x * 13 + chunk.y * 331
	var tex := load("res://assets/sprites/flowers.png")
	var count := 0
	var skip := {}
	for p in gen.trees: skip[p] = true
	for p in gen.rocks: skip[p] = true
	for p in gen.bushes: skip[p] = true
	for y in range(1, WorldGen.SIZE - 1):
		for x in range(1, WorldGen.SIZE - 1):
			var c := Vector2i(x, y)
			if gen.sdf_at(x, y) < 2.2 or gen.tile_at(x, y) >= WorldGen.PATH or skip.has(c):
				continue
			var w := origin + c
			if noise.get_noise_2d(w.x, w.y) < 0.18 or r.randf() > 0.38:
				continue
			var s := Sprite2D.new()
			s.texture = tex
			s.hframes = 6
			var base := int(clampf((hue.get_noise_2d(w.x, w.y) + 1.0) * 3.0, 0.0, 5.0))
			s.frame = base if r.randf() < 0.75 else r.randi_range(0, 5)
			s.flip_h = r.randf() < 0.5
			s.offset = Vector2(0, -7)
			s.position = Vector2(w) * 32.0 + Vector2(r.randi_range(6, 26), r.randi_range(12, 28))
			Outline.set_sway(s, 1.2, float(w.x) * 0.9 + float(w.y))
			s.z_index = -3
			_add(world, s)
			world.flower_sprites.append(s)
			flowers.append(s)
			count += 1
			if count >= 400:
				return

func _signs(world: World) -> void:
	if world.stream == null:
		return
	for sg in world.stream.roads.signs_in(chunk):
		var c: Vector2i = sg["cell"]
		var b := world.make_prop("res://assets/sprites/signpost.png", c, Vector2(10, 6), Vector2(0, -16))
		nodes.append(b)
		world.interactables.add(c, "sign", "E: Read sign", {"text": String(sg["text"])})
		sign_cells.append(c)

func unload(world: World) -> void:
	for c in layer_cells:
		world.layer.erase_cell(c)
	for c in cells:
		world.props.erase(c)
		world.stumps.erase(c)
	for s in flowers:
		world.flower_sprites.erase(s)
	for c in sign_cells:
		world.interactables.cells.erase(c)
	world.chunk_mats = world.chunk_mats.filter(func(m): return m != null and not _owns(m))
	for n in nodes:
		if is_instance_valid(n):
			n.queue_free()
	nodes.clear()

func _owns(m: ShaderMaterial) -> bool:
	for n in nodes:
		if n is ColorRect and n.material == m:
			return true
	return false
