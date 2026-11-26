class_name ImpactFx
extends RefCounted
## Short particle bursts where an arrow lands: feathers/fur off game, bark chips off wood, a dust kick on the ground.

static func style(kind: String) -> Dictionary:
	match kind:
		"game":
			return {"n": 10, "color": Color(0.95, 0.9, 0.82), "speed": 70.0, "gravity": 90.0, "life": 0.7}
		"wood":
			return {"n": 9, "color": Color(0.74, 0.52, 0.29), "speed": 80.0, "gravity": 260.0, "life": 0.45}
	return {"n": 6, "color": Color(0.7, 0.6, 0.4, 0.9), "speed": 35.0, "gravity": 120.0, "life": 0.4}

static func spawn(parent: Node, at: Vector2, kind: String) -> CPUParticles2D:
	var s := style(kind)
	var p := CPUParticles2D.new()
	p.position = at + Vector2(0, -8)
	p.z_index = 13
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = int(s["n"])
	p.lifetime = float(s["life"])
	p.direction = Vector2(0, -1)
	p.spread = 110.0
	p.initial_velocity_min = float(s["speed"]) * 0.4
	p.initial_velocity_max = float(s["speed"])
	p.gravity = Vector2(0, float(s["gravity"]))
	p.scale_amount_min = 1.0
	p.scale_amount_max = 2.5
	p.color = s["color"]
	p.emitting = true
	parent.add_child(p)
	if parent.is_inside_tree():
		parent.get_tree().create_timer(1.2).timeout.connect(p.queue_free)
	return p
