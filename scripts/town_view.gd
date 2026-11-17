class_name TownView
extends Node2D
## Builds the houses/barn/workshop from TownModel as y-sorted blocking props with door prompts.

var buildings: Array = []
var lights: Array = []   # PointLight2D at the windows, glow at night
const WINDOWS := {"house": [Vector2(20, 70), Vector2(68, 70)], "barn": [Vector2(23, 68), Vector2(105, 68)], "workshop": [Vector2(16, 57), Vector2(89, 57)]}
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
	world.interactables.add(b["door"], "door", "E: %s (locked)" % b["name"])
