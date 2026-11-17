class_name World
extends Node2D
## Builds the chunk: painted ground shader (from WorldGen data), invisible tile collision,
## y-sorted props (pines, oaks, bushes, rocks), water decor (lily pads, reeds, fish), a dock.

const PROP_TEX := {
	"pine": "res://assets/sprites/tree_pine.png",
	"oak": "res://assets/sprites/tree_oak.png",
	"rock": "res://assets/sprites/rock.png",
	"bush": "res://assets/sprites/bush.png",
}

var gen: WorldGen
var layer: TileMapLayer
var props: Dictionary = {}  # cell -> StaticBody2D (trees and rocks; ResourceNodes-driven)
var fish: Array[Node2D] = []
var lily_pads: Array[LilyPad] = []
var lanterns: Array[Lantern] = []
var reed_sprites: Array[Sprite2D] = []
var _reed_push: Dictionary = {}
var interactables := Interactables.new()

func build(seed_value: int = 1) -> void:
	gen = WorldGen.new(seed_value)
	y_sort_enabled = true
	_build_ground()
	_build_collision()
	for p in gen.trees:
		var tex: String = PROP_TEX[gen.tree_kinds[p]]
		props[p] = _prop(tex, p, Vector2(12, 8), Vector2(0, -48 + 4))
		Outline.set_sway(prop_sprite(p), 2.0 if gen.tree_kinds[p] == "oak" else 1.4, p.x * 0.7 + p.y * 0.3)
	for p in gen.rocks:
		props[p] = _prop(PROP_TEX.rock, p, Vector2(24, 14), Vector2(0, -12))
	for p in gen.bushes:
		var bush := _prop(PROP_TEX.bush, p, Vector2(20, 8), Vector2(0, -12))
		Outline.set_sway(bush.get_child(0), 1.0, p.x + p.y)
	_build_water_decor()
	_build_stall()
	_build_lanterns()

static func data_image(g: WorldGen) -> Image:
	## 64x64 RGBA8: R = sdf mapped to 0..1 (0.5 = shore), G = path mask, B = dirt mask.
	var img := Image.create(WorldGen.SIZE, WorldGen.SIZE, false, Image.FORMAT_RGBA8)
	for y in WorldGen.SIZE:
		for x in WorldGen.SIZE:
			var t := g.tile_at(x, y)
			var r := clampf(g.sdf_at(x, y) / 16.0 + 0.5, 0.0, 1.0)
			var pth := 1.0 if t >= WorldGen.PATH and t < WorldGen.PATH + 3 else 0.0
			var drt := 1.0 if t >= WorldGen.DIRT and t < WorldGen.DIRT + 3 else 0.0
			img.set_pixel(x, y, Color(r, pth, drt, 1.0))
	return img

func _build_ground() -> void:
	var rect := ColorRect.new()
	rect.size = Vector2(WorldGen.SIZE * 32, WorldGen.SIZE * 32)
	rect.z_index = -10
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := ShaderMaterial.new()
	m.shader = load("res://assets/shaders/ground.gdshader")
	m.set_shader_parameter("data", ImageTexture.create_from_image(data_image(gen)))
	m.set_shader_parameter("chunk_px", float(WorldGen.SIZE * 32))
	rect.material = m
	add_child(rect)

func _build_collision() -> void:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(32, 32)
	ts.add_physics_layer()
	var src := TileSetAtlasSource.new()
	src.texture = load("res://assets/tiles/atlas.png")
	src.texture_region_size = Vector2i(32, 32)
	src.create_tile(Vector2i(WorldGen.WATER_DEEP, 0))
	ts.add_source(src, 0)
	var td := src.get_tile_data(Vector2i(WorldGen.WATER_DEEP, 0), 0)
	td.add_collision_polygon(0)
	td.set_collision_polygon_points(0, 0, PackedVector2Array([Vector2(-16, -16), Vector2(16, -16), Vector2(16, 16), Vector2(-16, 16)]))
	layer = TileMapLayer.new()
	layer.tile_set = ts
	layer.visible = false  # the shader paints the ground; this layer only collides
	add_child(layer)
	for y in WorldGen.SIZE:
		for x in WorldGen.SIZE:
			var c := Vector2i(x, y)
			if WorldGen.is_water(gen.tile_at(x, y)) and not (c in gen.dock):
				layer.set_cell(c, 0, Vector2i(WorldGen.WATER_DEEP, 0))
	# world border
	for i in range(-1, WorldGen.SIZE + 1):
		for c in [Vector2i(i, -1), Vector2i(i, WorldGen.SIZE), Vector2i(-1, i), Vector2i(WorldGen.SIZE, i)]:
			layer.set_cell(c, 0, Vector2i(WorldGen.WATER_DEEP, 0))

func _prop(tex: String, cell: Vector2i, body: Vector2, off: Vector2) -> StaticBody2D:
	var b := StaticBody2D.new()
	b.position = Vector2(cell) * 32.0 + Vector2(16, 28)
	var s := Sprite2D.new()
	s.texture = load(tex)
	s.offset = off
	b.add_child(s)
	b.add_child(make_shadow(s.texture.get_width() * 0.7))
	var c := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = body
	c.shape = rs
	b.add_child(c)
	add_child(b)
	return b

func prop_sprite(cell: Vector2i) -> Sprite2D:
	return props[cell].get_child(0) if props.has(cell) else null

func _build_water_decor() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = gen.seed_value + 5
	var lily := load("res://assets/sprites/lily_pads.png")
	for c in gen.lilies:
		for k in r.randi_range(1, 3):
			var s := LilyPad.new()
			s.texture = lily
			s.region_enabled = true
			s.region_rect = Rect2(16 * r.randi_range(0, 3), 0, 16, 16)
			s.base = Vector2(c) * 32.0 + Vector2(r.randf_range(6, 26), r.randf_range(6, 26)).round()
			s.position = s.base
			s.phase = r.randf_range(0.0, TAU)
			lily_pads.append(s)
			s.z_index = -5
			add_child(s)
	var reed := load("res://assets/sprites/reeds.png")
	for c in gen.reeds:
		var s := Sprite2D.new()
		s.texture = reed
		s.flip_h = r.randf() < 0.5
		s.position = Vector2(c) * 32.0 + Vector2(16 + r.randi_range(-6, 6), 12)
		Outline.set_sway(s, 2.0, c.x * 1.3 + c.y)
		add_child(s)
		reed_sprites.append(s)
	if gen.dock.size() > 0:
		var a: Vector2i = gen.dock[0]
		var b: Vector2i = gen.dock[gen.dock.size() - 1]
		var left := mini(a.x, b.x)
		var d := Sprite2D.new()
		d.texture = load("res://assets/sprites/dock.png")
		d.centered = false
		var into_land := 10 if b.x < a.x else -10  # overlap the bank so the dock reads as attached
		d.position = Vector2(left * 32 + into_land, a.y * 32 - 24)
		d.z_index = -4
		add_child(d)
	# fish shadows swimming in deeper water
	var fish_tex := load("res://assets/sprites/fish.png")
	var spots: Array[Vector2i] = []
	for y in WorldGen.SIZE:
		for x in WorldGen.SIZE:
			if gen.sdf_at(x, y) < -1.2:
				spots.append(Vector2i(x, y))
	for i in mini(14, spots.size()):
		var f := FishShadow.new()
		f.setup(fish_tex, gen, spots[r.randi() % spots.size()], r.randi())
		add_child(f)
		fish.append(f)

func part_reeds(walker: Vector2, dt: float) -> void:
	## Reeds near the walker bend away and spring back (ReedMath), only those within range are touched.
	for s in reed_sprites:
		var cur: float = _reed_push.get(s, 0.0)
		var d := s.position - walker
		var tgt := 0.0
		if absf(d.x) < 24.0 and absf(d.y) < 24.0:
			tgt = ReedMath.bend(s.position, walker)
		if tgt == 0.0 and cur == 0.0:
			continue
		cur = ReedMath.ease_to(cur, tgt, dt)
		_reed_push[s] = cur
		(s.material as ShaderMaterial).set_shader_parameter("push", cur)

func sync_props(nodes: ResourceNodes) -> void:
	## Shows/hides prop sprites and collision to match ResourceNodes state.
	for cell in props:
		var b: StaticBody2D = props[cell]
		var solid := nodes.is_solid(cell)
		b.visible = solid
		b.get_child(2).set_deferred("disabled", not solid)

static func make_shadow(width: float) -> Sprite2D:
	## Soft oval drop shadow under a prop/character (drawn above ground, below sprites).
	var sh := Sprite2D.new()
	sh.texture = load("res://assets/sprites/shadow.png")
	sh.scale = Vector2(width / 32.0, maxf(1.0, width / 48.0)).round() if width > 40 else Vector2(1, 1)
	sh.position = Vector2(0, 2)
	sh.z_index = -3
	return sh

func stall_cell() -> Vector2i:
	return _stall_cell()

func _stall_cell() -> Vector2i:
	## Nearest dry, empty 2-wide spot 4-9 tiles from the spawn dock.
	var from := Vector2i(32, 32)
	if gen.dock.size() > 1:
		var d0: Vector2i = gen.dock[0]
		var d1: Vector2i = gen.dock[1]
		from = d0 - (d1 - d0)
	for r in range(4, 10):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if maxi(absi(dx), absi(dy)) != r:
					continue
				var c := from + Vector2i(dx, dy)
				var ok := true
				for k in 2:
					var q := c + Vector2i(k, 0)
					if q.x < 1 or q.y < 2 or q.x >= WorldGen.SIZE - 1 or q.y >= WorldGen.SIZE - 1:
						ok = false
					elif gen.sdf_at(q.x, q.y) < 2.5 or gen.tile_at(q.x, q.y) >= WorldGen.PATH or q in gen.trees or q in gen.rocks or q in gen.bushes:
						ok = false
				if ok:
					return c
	return Vector2i(-1, -1)

func _build_stall() -> void:
	var c := _stall_cell()
	if c.x < 0:
		return
	var b := _prop("res://assets/sprites/stall.png", c, Vector2(56, 10), Vector2(0, -28))
	b.position = Vector2(c.x * 32 + 32, c.y * 32 + 30)
	props.erase(c)  # not a ResourceNodes prop
	interactables.add(c, "shop", "E: Shop")
	interactables.add(c + Vector2i(1, 0), "shop", "E: Shop")

func _build_lanterns() -> void:
	## Lantern posts: one each side of the dock landing and one by the stall.
	var spots: Array[Vector2] = []
	if gen.dock.size() > 1:
		var d0: Vector2i = gen.dock[0]
		var d1: Vector2i = gen.dock[1]
		var land := d0 - (d1 - d0)
		spots.append((Vector2(land) + Vector2(0.5, 1.9)) * 32.0)
		spots.append((Vector2(land) + Vector2(0.5, -0.9)) * 32.0)
	var sc := _stall_cell()
	if sc.x >= 0:
		spots.append(Vector2(sc.x * 32 + 70, sc.y * 32 + 30))
	for i in spots.size():
		var l := Lantern.new()
		l.position = spots[i]
		l.phase = float(i) * 2.1
		add_child(l)
		lanterns.append(l)

func set_lamps(k: float) -> void:
	for l in lanterns:
		l.strength = k
