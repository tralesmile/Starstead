class_name ChopFx
extends RefCounted
## Tree chopping visuals: wobble on each hit, falling-tree animation on the last hit, leaf bursts.

static func wobble(spr: Sprite2D, tree: Node) -> void:
	## Shake the canopy sideways a couple of whole pixels and settle.
	var base := spr.position
	var tw: Tween = tree.create_tween()
	for k in [3.0, -3.0, 2.0, -1.0, 0.0]:
		tw.tween_property(spr, "position:x", base.x + k, 0.04)

## Direction the tree falls: away from the chopper, left or right.
static func fall_dir(chopper_x: float, tree_x: float) -> float:
	return 1.0 if tree_x >= chopper_x else -1.0

## Rotation (radians) of a falling tree at progress k 0..1: slow start, accelerating, small bounce at the end.
static func fall_angle(k: float, dir: float) -> float:
	var kk := clampf(k, 0.0, 1.0)
	var a := kk * kk * 1.45
	if kk > 0.85:
		a -= sin((kk - 0.85) / 0.15 * PI) * 0.06
	return a * dir

static func leaves(world: Node2D, pos: Vector2, amount: int = 10) -> void:
	var p := CPUParticles2D.new()
	p.position = pos
	p.emitting = true
	p.one_shot = true
	p.explosiveness = 0.7
	p.amount = amount
	p.lifetime = 1.0
	p.direction = Vector2(0, 1)
	p.spread = 90.0
	p.initial_velocity_min = 8.0
	p.initial_velocity_max = 30.0
	p.gravity = Vector2(0, 40)
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(14, 6)
	p.scale_amount_min = 1.0
	p.scale_amount_max = 2.0
	p.color = Color(0.3, 0.55, 0.22)
	world.add_child(p)
	world.get_tree().create_timer(1.6).timeout.connect(p.queue_free)

## Spawn a copy of the tree that topples over its base, then fades; returns the ghost node.
static func fall(world: Node2D, src: Sprite2D, base: Vector2, dir: float) -> Node2D:
	var ghost := Node2D.new()
	ghost.position = base
	var s := Sprite2D.new()
	s.texture = src.texture
	s.offset = src.offset
	ghost.add_child(s)
	ghost.z_index = 2
	world.add_child(ghost)
	var tw := ghost.create_tween()
	tw.tween_method(func(k: float): ghost.rotation = fall_angle(k, dir), 0.0, 1.0, 0.75)
	tw.tween_callback(func(): leaves(world, ghost.position + Vector2(dir * 40.0, -6.0), 16))
	tw.tween_property(ghost, "modulate:a", 0.0, 0.5)
	tw.tween_callback(ghost.queue_free)
	return ghost
