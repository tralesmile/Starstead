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
var ground_mat: ShaderMaterial
var layer: TileMapLayer
var flower_sprites: Array = []
var stumps: Dictionary = {}  # cell -> Sprite2D shown while a tree is chopped
var props: Dictionary = {}  # cell -> StaticBody2D (trees and rocks; ResourceNodes-driven)
var fish: Array[Node2D] = []
var lily_pads: Array[LilyPad] = []
var lanterns: Array[Lantern] = []
var reed_sprites: Array[Sprite2D] = []
var tuft_sprites: Array[Sprite2D] = []
var _reed_push: Dictionary = {}
var interactables := Interactables.new()
var stream: ChunkStream
var chunk_views: Dictionary = {}   # chunk -> ChunkView
var chunk_mats: Array = []
var player_ref: Node2D = null
var nodes_ref: ResourceNodes = null   # set by main (World must not touch autoloads: tests compile it)
var season := 0
var region_id := ""
var stream_budget := 1             # chunks built per stream_update call

func build(seed_value: int = 1) -> void:
	gen = WorldGen.new(seed_value)
	stream = ChunkStream.new(seed_value, gen)
	gen.stream_ref = stream
	y_sort_enabled = true
	_build_ground()
	_build_collision()
	for p in gen.trees:
		var tex: String = PROP_TEX[gen.tree_kinds[p]]
		props[p] = _prop(tex, p, Vector2(12, 8), Vector2(0, -48 + 4))
		var st := Sprite2D.new()
		st.texture = load("res://assets/sprites/stump.png")
		st.offset = Vector2(0, -10)
		st.visible = false
		st.name = "Stump"
		add_child(st)
		st.position = (props[p] as Node2D).position
		stumps[p] = st
		Outline.set_sway(prop_sprite(p), 2.0 if gen.tree_kinds[p] == "oak" else 1.4, p.x * 0.7 + p.y * 0.3)
	for p in gen.rocks:
		props[p] = _prop(PROP_TEX.rock, p, Vector2(24, 14), Vector2(0, -12))
	for p in gen.bushes:
		var bush := _prop(PROP_TEX.bush, p, Vector2(20, 8), Vector2(0, -12))
		Outline.set_sway(bush.get_child(0), 1.0, p.x + p.y)
	_build_water_decor()
	_build_reflections()
	_build_flowers()
	_build_stall()
	_build_lanterns()
	_build_world_wall()

static func _city_alpha(t: int, wc: Vector2i) -> float:
	if t == WorldGen.ASPHALT:
		return [0.0, 0.08, 0.16][CityModel.zebra(wc)]   # asphalt alpha also flags the zebra bar direction
	if WorldGen.is_road(t) and CityModel.in_rect(wc):
		return 0.5
	return 1.0

static func data_image(g: WorldGen, pad: int = 0) -> Image:
	## (64+2*pad)^2 RGBA8: R = sdf mapped to 0..1 (0.5 = shore), G = path mask, B = dirt mask.
	## pad > 0 copies the neighbouring chunks' edge cells (via g.grid or the chunk's own stream) so the
	## linear filtering at a chunk edge sees the real neighbour instead of a clamped copy (no visible seam).
	var n := WorldGen.SIZE + 2 * pad
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var origin := ChunkGrid.origin_cell(g.chunk)
	for y in n:
		for x in n:
			var cx := x - pad
			var cy := y - pad
			var t: int
			var sd: float
			if cx >= 0 and cy >= 0 and cx < WorldGen.SIZE and cy < WorldGen.SIZE:
				t = g.tile_at(cx, cy)
				sd = g.sdf_at(cx, cy)
			elif g.stream_ref != null:
				t = g.stream_ref.tile_at(origin + Vector2i(cx, cy))
				sd = g.stream_ref.sdf_at(origin + Vector2i(cx, cy))
			else:
				t = g.tile_at(clampi(cx, 0, WorldGen.SIZE - 1), clampi(cy, 0, WorldGen.SIZE - 1))
				sd = g.sdf_at(clampi(cx, 0, WorldGen.SIZE - 1), clampi(cy, 0, WorldGen.SIZE - 1))
			var r := clampf(sd / 16.0 + 0.5, 0.0, 1.0)
			var pth := 1.0 if WorldGen.is_road(t) else 0.0
			var drt := 1.0 if t >= WorldGen.DIRT and t < WorldGen.DIRT + 3 else 0.0
			if t == WorldGen.ASPHALT:
				drt = [0.0, 0.5, 1.0][CityModel.lane(origin + Vector2i(cx, cy))]  # asphalt reuses B for the lane line
			img.set_pixel(x, y, Color(r, pth, drt, _city_alpha(t, origin + Vector2i(cx, cy))))  # alpha: 1 dirt path, 0.5 city sidewalk, 0 asphalt
	return img

func _build_ground() -> void:
	var rect := ColorRect.new()
	rect.size = Vector2(WorldGen.SIZE * 32, WorldGen.SIZE * 32)
	rect.z_index = -10
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := ShaderMaterial.new()
	m.shader = load("res://assets/shaders/ground.gdshader")
	m.set_shader_parameter("data", ImageTexture.create_from_image(data_image(gen, 1)))
	m.set_shader_parameter("data_size", float(WorldGen.SIZE + 2))
	m.set_shader_parameter("data_pad", 1.0)
	m.set_shader_parameter("chunk_px", float(WorldGen.SIZE * 32))
	rect.material = m
	ground_mat = m
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
	layer.visible = "--show-collision" in OS.get_cmdline_user_args()
	layer.modulate = Color(1, 0.2, 0.2, 0.45)  # the shader paints the ground; this layer only collides
	add_child(layer)
	# deep water: whole-tile collision; the shore band follows the painted contour (ShoreMath)
	for y in WorldGen.SIZE:
		for x in WorldGen.SIZE:
			var c := Vector2i(x, y)
			if WorldGen.is_water(gen.tile_at(x, y)) and not (c in gen.dock) and gen.sdf_at(x, y) <= -2.5:
				layer.set_cell(c, 0, Vector2i(WorldGen.WATER_DEEP, 0))
	var rects := ShoreMath.blocked_rects(func(t: Vector2i) -> float: return gen.sdf_at(clampi(t.x, 0, WorldGen.SIZE - 1), clampi(t.y, 0, WorldGen.SIZE - 1)), WorldGen.SIZE, func(t: Vector2i) -> bool: return t in gen.dock)
	var shore := StaticBody2D.new()
	for r in rects:
		var cs := CollisionShape2D.new()
		var rs := RectangleShape2D.new()
		rs.size = r.size
		cs.shape = rs
		cs.position = r.position + r.size * 0.5
		shore.add_child(cs)
		if "--show-collision" in OS.get_cmdline_user_args():
			var dr := ColorRect.new()
			dr.position = r.position
			dr.size = r.size
			dr.color = Color(1, 0.1, 0.1, 0.35)
			dr.z_index = 50
			add_child(dr)
	add_child(shore)

func _build_world_wall() -> void:
	## Sea wall around the whole 8x8 chunk world (the homestead is an interior chunk now).
	var wr := ChunkGrid.world_rect_px()
	var body := StaticBody2D.new()
	for r in [Rect2(wr.position.x - 64, wr.position.y - 64, wr.size.x + 128, 64), Rect2(wr.position.x - 64, wr.end.y, wr.size.x + 128, 64), Rect2(wr.position.x - 64, wr.position.y, 64, wr.size.y), Rect2(wr.end.x, wr.position.y, 64, wr.size.y)]:
		var cs := CollisionShape2D.new()
		var rs := RectangleShape2D.new()
		rs.size = r.size
		cs.shape = rs
		cs.position = r.position + r.size * 0.5
		body.add_child(cs)
	add_child(body)

func make_prop(tex: String, cell: Vector2i, body: Vector2, off: Vector2) -> StaticBody2D:
	return _prop(tex, cell, body, off)

func register_prop(cell: Vector2i, body: StaticBody2D, _tree: bool) -> void:
	props[cell] = body

func prop_stump(cell: Vector2i, body: Node2D) -> Sprite2D:
	var st := Sprite2D.new()
	st.texture = load("res://assets/sprites/stump.png")
	st.offset = Vector2(0, -10)
	st.visible = false
	st.name = "Stump"
	add_child(st)
	st.position = body.position
	stumps[cell] = st
	return st

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
	var tuft := load("res://assets/sprites/grass_tuft.png")
	for c in gen.tufts:
		var s := Sprite2D.new()
		s.texture = tuft
		s.flip_h = r.randf() < 0.5
		s.position = Vector2(c) * 32.0 + Vector2(r.randi_range(6, 26), r.randi_range(14, 28))
		Outline.set_sway(s, 1.5, c.x * 0.9 + c.y)
		s.z_index = -3
		add_child(s)
		tuft_sprites.append(s)
		reed_sprites.append(s)  # tufts part around the walker too (ReedMath)
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
		if stumps.has(cell):
			(stumps[cell] as Sprite2D).visible = not solid and nodes.nodes.has(cell)

func set_season(season: int) -> void:
	## Seasonal grass colours (shader), leaf colours on trees/bushes, flowers hidden in winter.
	self.season = season
	var mats: Array = chunk_mats.duplicate()
	if ground_mat != null:
		mats.append(ground_mat)
	var m := SeasonMath.ground_mul(season)
	for gm in mats:
		gm.set_shader_parameter("season_mul", Vector3(m.r, m.g, m.b))
		gm.set_shader_parameter("season_frost", SeasonMath.ground_frost(season))
	for ch in get_children():
		if ch is StaticBody2D and ch.get_child_count() > 0 and ch.get_child(0) is Sprite2D:
			var spr := ch.get_child(0) as Sprite2D
			if spr.texture != null:
				var k := SeasonMath.kind_of(spr.texture.resource_path)
				if k != "":
					var c := SeasonMath.tree_tint(season, k)
					spr.modulate = Color(c.r, c.g, c.b, spr.modulate.a)
	for f in flower_sprites:
		(f as Node2D).visible = SeasonMath.flowers_visible(season)

static func make_shadow(width: float) -> Sprite2D:
	## Soft oval drop shadow under a prop/character (drawn above ground, below sprites).
	var sh := Sprite2D.new()
	sh.texture = load("res://assets/sprites/shadow.png")
	sh.scale = Vector2(width / 32.0, maxf(1.0, width / 48.0)).round() if width > 40 else Vector2(1, 1)
	sh.position = Vector2(0, 2)
	sh.z_index = -3
	sh.add_to_group("sun_shadows")
	sh.set_meta("base_scale", sh.scale)
	sh.set_meta("base_pos", sh.position)
	return sh

static func apply_sun(tree: SceneTree, minutes: float) -> void:
	## Leans and stretches every drop shadow to the sun (ShadowMath), fading them at night.
	var dx := ShadowMath.offset_x(minutes)
	var st := ShadowMath.stretch(minutes)
	var a := ShadowMath.strength(minutes)
	for n in tree.get_nodes_in_group("sun_shadows"):
		var sh := n as Sprite2D
		if sh == null or not sh.has_meta("base_scale"):
			continue
		var bs: Vector2 = sh.get_meta("base_scale")
		var bp: Vector2 = sh.get_meta("base_pos")
		var w := bs.x * 32.0
		sh.scale = Vector2(bs.x * st, bs.y)
		sh.position = Vector2(bp.x + roundf(dx * clampf(w / 40.0, 0.35, 1.6)), bp.y)
		sh.modulate.a = a

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

# --- water reflections + dock foam (graphics pass) ---
var reflections: Array = []  # {sprite, base_x, phase}
var foam: Node2D

func _build_reflections() -> void:
	## Mirrored, tinted, wobbling copies of trees/rocks/bushes that stand on a bank with water to the south.
	var all := {}
	for p in gen.trees:
		all[p] = true
	for p in gen.rocks:
		all[p] = true
	for p in gen.bushes:
		all[p] = true
	for p in all:
		if not props.has(p):
			continue
		var src: Sprite2D = prop_sprite(p)
		if src == null or not (gen.sdf_at(p.x, p.y + 1) < -0.2):
			continue
		var r := Sprite2D.new()
		r.texture = src.texture
		r.flip_v = true
		r.offset = Vector2(src.offset.x, -src.offset.y - 2.0)
		r.position = (props[p] as Node2D).position
		r.modulate = Color(0.45, 0.68, 0.74, 0.34)
		r.z_index = -6
		add_child(r)
		reflections.append({"s": r, "src": props[p], "x": r.position.x, "phase": float(p.x) * 1.7 + float(p.y)})
	if gen.dock.size() > 0:
		foam = DockFoam.new()
		var a: Vector2i = gen.dock[0]
		var b: Vector2i = gen.dock[gen.dock.size() - 1]
		var left := mini(a.x, b.x)
		var into_land := 10 if b.x < a.x else -10
		foam.position = Vector2(left * 32 + into_land, a.y * 32 - 24)
		foam.z_index = -3
		add_child(foam)

func _process(_delta: float) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	for r in reflections:
		(r["s"] as Sprite2D).position.x = float(r["x"]) + roundf(sin(t * 1.6 + float(r["phase"])) * 1.4)
		(r["s"] as Sprite2D).visible = (r["src"] as Node2D).visible

func _build_flowers() -> void:
	## Clustered meadow flowers: low-frequency noise picks patches, each patch leans to one or two colours.
	var noise := FastNoiseLite.new()
	noise.seed = gen.seed_value * 31 + 7
	noise.frequency = 0.09
	var hue := FastNoiseLite.new()
	hue.seed = gen.seed_value * 17 + 3
	hue.frequency = 0.05
	var r := RandomNumberGenerator.new()
	r.seed = gen.seed_value + 99
	var tex := load("res://assets/sprites/flowers.png")
	var count := 0
	for y in range(2, WorldGen.SIZE - 2):
		for x in range(2, WorldGen.SIZE - 2):
			var c := Vector2i(x, y)
			if gen.sdf_at(x, y) < 2.2 or gen.tile_at(x, y) >= WorldGen.PATH or c in gen.trees or c in gen.rocks or c in gen.bushes or c in gen.dock:
				continue
			if noise.get_noise_2d(x, y) < 0.18 or r.randf() > 0.38:
				continue
			var s := Sprite2D.new()
			s.texture = tex
			s.hframes = 6
			var base := int(clampf((hue.get_noise_2d(x, y) + 1.0) * 3.0, 0.0, 5.0))
			s.frame = base if r.randf() < 0.75 else r.randi_range(0, 5)
			s.flip_h = r.randf() < 0.5
			s.offset = Vector2(0, -7)
			s.position = Vector2(c) * 32.0 + Vector2(r.randi_range(6, 26), r.randi_range(12, 28))
			Outline.set_sway(s, 1.2, float(x) * 0.9 + float(y))
			s.z_index = -3
			add_child(s)
			flower_sprites.append(s)
			reed_sprites.append(s)  # flowers bend away from the walker like tufts
			count += 1
			if count >= 520:
				return

func stream_update(player_px: Vector2) -> void:
	## Keeps the 3x3 chunks around the player built (one per call) and drops chunks beyond 2.
	var center := ChunkGrid.chunk_of_pos(player_px)
	var loaded: Array = chunk_views.keys()
	loaded.append(ChunkGrid.HOME)
	for ch in ChunkGrid.to_unload(loaded, center):
		if chunk_views.has(ch):
			(chunk_views[ch] as ChunkView).unload(self)
			chunk_views.erase(ch)
	var built := 0
	for ch in ChunkGrid.to_load(loaded, center):
		var v := ChunkView.new()
		v.build(self, stream.gen_for(ch))
		chunk_views[ch] = v
		built += 1
		if built >= stream_budget:
			break
	if built > 0:
		set_season(season)
		if nodes_ref != null:
			sync_props(nodes_ref)

func region_now(player_px: Vector2) -> Dictionary:
	return stream.region_at(ChunkGrid.chunk_of_pos(player_px))
