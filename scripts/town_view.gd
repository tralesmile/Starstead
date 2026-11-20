class_name TownView
extends Node2D
## Builds the houses/barn/workshop from TownModel as y-sorted blocking props with door prompts.

var buildings: Array = []
var lights: Array = []   # PointLight2D at the windows, glow at night
var paddock_cells: Array[Vector2i] = []   # fence ring beside the barn
const WINDOWS := {"house": [Vector2(20, 70), Vector2(68, 70)], "barn": [Vector2(23, 68), Vector2(105, 68)], "workshop": [Vector2(16, 57), Vector2(89, 57)],
	"shop_building": [Vector2(30, 82), Vector2(108, 82)], "bank_building": [Vector2(25, 70), Vector2(133, 70)],
	"police_building": [Vector2(20, 66), Vector2(52, 66), Vector2(112, 70)], "hospital_building": [Vector2(18, 60), Vector2(46, 60), Vector2(112, 60), Vector2(142, 60), Vector2(18, 96), Vector2(142, 96)],
	"apartment_a": [Vector2(20, 40), Vector2(70, 40), Vector2(20, 84), Vector2(70, 84)], "apartment_b": [Vector2(20, 40), Vector2(70, 40), Vector2(20, 84), Vector2(70, 84)],
	"town_hall": [Vector2(36, 92), Vector2(124, 92)], "cafe_building": [Vector2(20, 70), Vector2(76, 70)], "garage_building": [Vector2(14, 70)], "pit_building": [Vector2(14, 72)], "sports_hall": [Vector2(30, 70), Vector2(126, 70)]}
const CHIMNEYS := {"house": Vector2(70, 4), "workshop": Vector2(82, 3)}

func set_night(k: float) -> void:
	for l in lights:
		(l as PointLight2D).energy = 0.9 * k
		(l as PointLight2D).visible = k > 0.01

func setup(world: World, gen: WorldGen, stall: Vector2i) -> void:
	var npcs: Dictionary = DataDB.load_json("npcs")
	var blocked: Array = []
	if stall.x >= 0:
		for dx in range(-1, 4):
			for dy in range(-1, 3):
				blocked.append(stall + Vector2i(dx, dy))
	for d in gen.dock:
		for dx in range(-2, 3):
			for dy in range(-2, 3):
				blocked.append(d + Vector2i(dx, dy))
	var ok := func(c: Vector2i) -> bool:
		return c.x > 1 and c.y > 1 and c.x < WorldGen.SIZE - 2 and c.y < WorldGen.SIZE - 2 and gen.sdf_at(c.x, c.y) >= 2.0 and gen.tile_at(c.x, c.y) < WorldGen.PATH and not (c in gen.trees) and not (c in gen.rocks) and not (c in gen.bushes)
	var home: Vector2i = Vector2i(int(npcs["npcs"][0]["home"][0]), int(npcs["npcs"][0]["home"][1]))
	if stall.x >= 0:
		home = stall + Vector2i(4, -3)  # your farmhouse settles near the start
	buildings = TownModel.layout(npcs["places"], home, ok, blocked)
	for b in buildings:
		_make(world, gen, b)
	if stall.x >= 0:
		_village(world, gen, stall)
	for b in CityModel.buildings():   # Port Halden (far east of the homestead chunk)
		buildings.append(b)
		_make(world, gen, b)
	for b in CircuitModel.buildings():   # Halden circuit pit office + Sports Hall (far west)
		buildings.append(b)
		_make(world, gen, b)
	CityView.build(world, lights)

func _village(world: World, gen: WorldGen, stall: Vector2i) -> void:
	## A fenced paddock beside the barn, then worn dirt footpaths from every village door to the market stall
	## (routed around the paddock fence).
	var hub := stall + Vector2i(1, 2)
	var walk := func(c: Vector2i) -> bool:
		return c.x > 0 and c.y > 0 and c.x < WorldGen.SIZE - 1 and c.y < WorldGen.SIZE - 1 and gen.sdf_at(c.x, c.y) >= 1.0 and not (c in gen.trees) and not (c in gen.rocks) and not (c in gen.dock)
	var taken := {}
	for ob in buildings:
		for c in TownModel.footprint_cells(ob):
			taken[c] = true
	var fences := {}
	for b in buildings:
		if String(b["id"]) != "barn":
			continue
		var free := func(c: Vector2i) -> bool:
			return walk.call(c) and not taken.has(c) and not (c in gen.bushes) and not GameState.farm.soil.has(c) and c != hub and c != stall
		var pd := TownModel.paddock(b, free)
		if pd.is_empty():
			continue
		for c in pd["fence"]:
			fences[c] = "fence"
		for c in pd["fence"]:
			var body := world.make_prop("res://assets/sprites/build_fence_auto.png", c, Vector2(30, 8), Vector2(0, -16))
			var spr := body.get_child(0) as Sprite2D
			spr.region_enabled = true
			spr.region_rect = Rect2(Autotile.atlas_index(Autotile.mask(fences, c, ["fence"])) * 32, 0, 32, 32)
			spr.offset = Vector2(0, -12)
			for ch in body.get_children():   # make_prop sized the shadow from the whole 16-frame sheet
				if ch is Sprite2D and ch != spr:
					ch.queue_free()
			var sh := World.make_shadow(22)
			sh.scale *= Vector2(1.0, 0.6)
			body.add_child(sh)
			paddock_cells.append(c)
	for b in buildings:
		if String(b["id"]) != "barn":
			continue
		var avoid := Rect2i()
		if not paddock_cells.is_empty():
			avoid = Rect2i(paddock_cells[0], Vector2i.ONE)
			for pc in paddock_cells:
				avoid = avoid.expand(pc)
		var fld := TownModel.field(b, avoid, func(c: Vector2i) -> bool:
			return walk.call(c) and not taken.has(c) and not (c in gen.bushes) and not fences.has(c) and c != hub and c != stall)
		for c in fld:
			gen.tiles[c.y * WorldGen.SIZE + c.x] = WorldGen.DIRT + (c.x * 5 + c.y * 11) % 3
			world.cut_tuft(c)
		if not fld.is_empty():
			world.refresh_ground()
	var walk_paths := func(c: Vector2i) -> bool: return walk.call(c) and not fences.has(c)
	var cells := TownModel.village_paths(buildings, hub, walk_paths, WorldGen.SIZE)
	for c in cells:
		if c in gen.bushes:
			continue
		gen.tiles[c.y * WorldGen.SIZE + c.x] = WorldGen.PATH + (c.x * 7 + c.y * 13) % 3
		world.cut_tuft(c)
	if not cells.is_empty():
		world.refresh_ground()

func _make(world: World, gen: WorldGen, b: Dictionary) -> void:
	var body := StaticBody2D.new()
	body.position = TownModel.sprite_bottom_center(b)
	var s := Sprite2D.new()
	s.texture = load("res://assets/sprites/%s.png" % b["sprite"])
	s.offset = Vector2(0, -s.texture.get_height() / 2.0)
	body.add_child(s)
	body.add_child(World.make_shadow(s.texture.get_width() * 0.8))
	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(float(b["w"]) * 32.0 - 6.0, 36.0)
	cs.shape = rs
	cs.position = Vector2(0, -20)
	body.add_child(cs)
	var tex_size := s.texture.get_size()
	var origin := Vector2(-tex_size.x / 2.0, -tex_size.y)   # sprite top-left relative to the body
	for wp in WINDOWS.get(b["sprite"], []):
		var l := PointLight2D.new()
		l.texture = Lantern.light_texture()
		l.texture_scale = 1.1
		l.color = Color(1.0, 0.8, 0.5)
		l.position = origin + wp + Vector2(0, 8)
		l.energy = 0.0
		l.visible = false
		body.add_child(l)
		lights.append(l)
	if CHIMNEYS.has(b["sprite"]):
		var sm := CPUParticles2D.new()
		sm.position = origin + CHIMNEYS[b["sprite"]]
		sm.amount = 7
		sm.lifetime = 2.6
		sm.direction = Vector2(0.3, -1)
		sm.spread = 12.0
		sm.initial_velocity_min = 8.0
		sm.initial_velocity_max = 16.0
		sm.gravity = Vector2(7, -6)
		sm.scale_amount_min = 2.0
		sm.scale_amount_max = 4.0
		var g := Gradient.new()
		g.set_color(0, Color(0.9, 0.9, 0.92, 0.55))
		g.set_color(1, Color(0.9, 0.9, 0.92, 0.0))
		sm.color_ramp = g
		sm.z_index = 3
		body.add_child(sm)
	world.add_child(body)
	var open_door: bool = String(b["id"]) in InteriorModel.PUBLIC
	world.interactables.add(b["door"], "door", ("E: Enter %s" if open_door else "E: %s (locked)") % b["name"])
