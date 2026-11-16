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

func build(seed_value: int = 1) -> void:
	gen = WorldGen.new(seed_value)
	y_sort_enabled = true
	_build_ground()
	_build_collision()
	for p in gen.trees:
		var tex: String = PROP_TEX[gen.tree_kinds[p]]
		props[p] = _prop(tex, p, Vector2(12, 8), Vector2(0, -48 + 4))
	for p in gen.rocks:
		props[p] = _prop(PROP_TEX.rock, p, Vector2(24, 14), Vector2(0, -12))
	for p in gen.bushes:
		_prop(PROP_TEX.bush, p, Vector2(20, 8), Vector2(0, -12))
	_build_water_decor()

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
			var s := Sprite2D.new()
			s.texture = lily
			s.region_enabled = true
			s.region_rect = Rect2(16 * r.randi_range(0, 3), 0, 16, 16)
			s.position = Vector2(c) * 32.0 + Vector2(r.randf_range(6, 26), r.randf_range(6, 26)).round()
			s.z_index = -5
			add_child(s)
	var reed := load("res://assets/sprites/reeds.png")
	for c in gen.reeds:
		var s := Sprite2D.new()
		s.texture = reed
		s.flip_h = r.randf() < 0.5
		s.position = Vector2(c) * 32.0 + Vector2(16 + r.randi_range(-6, 6), 12)
		add_child(s)
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
