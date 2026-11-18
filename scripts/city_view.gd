class_name CityView
extends RefCounted
## Street furniture for Port Halden (CityModel.props): iron streetlamps that glow at night, plaza benches, fountain.

static func build(world: World, lights: Array) -> void:
	for p in CityModel.props():
		var c: Vector2i = p["cell"]
		match String(p["kind"]):
			"lamp":
				var b := world.make_prop("res://assets/sprites/streetlamp.png", c, Vector2(8, 6), Vector2(0, -24))
				var l := PointLight2D.new()
				l.texture = Lantern.light_texture()
				l.texture_scale = 2.2
				l.color = Color(1.0, 0.82, 0.5)
				l.position = Vector2(0, -44)
				l.energy = 0.0
				l.visible = false
				b.add_child(l)
				lights.append(l)
			"bench":
				world.make_prop("res://assets/sprites/bench.png", c, Vector2(28, 8), Vector2(0, -10))
			"fountain":
				world.make_prop("res://assets/sprites/fountain.png", c, Vector2(52, 20), Vector2(0, -24))
