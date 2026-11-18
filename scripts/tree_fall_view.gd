class_name TreeFallView
extends Node2D
## Animates a felled tree (rotates around its base, dust + leaves + shake on impact), leaves a log prop,
## and turns it into wood drops after LOG_HITS axe hits. Model: TreeFall.

var model := TreeFall.new()
var world: Node2D
var drops: Node
var nodes_by_cell: Dictionary = {}  # cell -> log Node2D

func setup(w: Node2D, d: Node) -> void:
	world = w
	drops = d

## Called on the final hit. `src` is the tree sprite, `base` its foot position.
func fell(cell: Vector2i, src: Sprite2D, base: Vector2, dir: float) -> void:
	model.start(cell, dir)
	var ghost := Node2D.new()
	ghost.position = base
	ghost.z_index = 2
	var s := Sprite2D.new()
	s.texture = src.texture
	s.offset = src.offset
	ghost.add_child(s)
	world.add_child(ghost)
	var tw := ghost.create_tween()
	tw.tween_method(func(t: float):
		ghost.rotation = TreeFall.angle(t, dir)
		ghost.position.x = base.x + TreeFall.impact_shake(t), 0.0, TreeFall.FALL_TIME + 0.25, TreeFall.FALL_TIME + 0.25)
	tw.tween_callback(func():
		ghost.queue_free()
		_land(cell, base, dir))
	# impact burst at the moment it touches the ground
	world.get_tree().create_timer(TreeFall.FALL_TIME * 0.92).timeout.connect(func():
		ChopFx.leaves(world, base + Vector2(dir * 40.0, -6.0), 14)
		_dust(base + Vector2(dir * 30.0, 0.0)))

func _land(cell: Vector2i, base: Vector2, dir: float) -> void:
	model.land(cell)
	var n := LogProp.new()
	n.dir = dir
	n.position = base + Vector2(dir * 18.0, -3.0)
	world.add_child(n)
	nodes_by_cell[cell] = n

## Axe hit on a fallen trunk. Returns true when this click was used on a log.
func hit_log(cell: Vector2i, from: Vector2) -> bool:
	var r := model.hit(cell)
	if r.is_empty():
		return false
	var n: Node2D = nodes_by_cell.get(cell)
	if n == null:
		return true
	_dust(n.position)
	if r.has("id"):
		ChopFx.leaves(world, n.position + Vector2(0, -8), 6)
		drops.spawn(r.id, int(r.n), n.position + Vector2(0, 8))
		n.queue_free()
		nodes_by_cell.erase(cell)
	else:
		var tw := n.create_tween()
		for k in [2.0, -2.0, 1.0, 0.0]:
			tw.tween_property(n, "scale:y", 1.0 + k * 0.05, 0.04)
	return true

func _dust(pos: Vector2) -> void:
	var p := CPUParticles2D.new()
	p.position = pos
	p.emitting = true
	p.one_shot = true
	p.explosiveness = 0.9
	p.amount = 8
	p.lifetime = 0.5
	p.direction = Vector2(0, -1)
	p.spread = 80.0
	p.initial_velocity_min = 10.0
	p.initial_velocity_max = 34.0
	p.gravity = Vector2(0, 20)
	p.scale_amount_min = 1.5
	p.scale_amount_max = 2.5
	p.color = Color(0.78, 0.7, 0.55, 0.8)
	world.add_child(p)
	world.get_tree().create_timer(1.0).timeout.connect(p.queue_free)

class LogProp extends Node2D:
	var dir := 1.0
	func _draw() -> void:
		draw_rect(Rect2(-18, -4, 36, 8), Color(0.42, 0.27, 0.14))
		draw_rect(Rect2(-18, -4, 36, 2), Color(0.55, 0.37, 0.2))
		draw_rect(Rect2(-18, 3, 36, 1), Color(0.3, 0.18, 0.09))
		var e := 18.0 * dir
		draw_circle(Vector2(e, 0), 4.0, Color(0.8, 0.62, 0.38))
		draw_arc(Vector2(e, 0), 2.0, 0, TAU, 12, Color(0.55, 0.37, 0.2), 1.0)
		draw_rect(Rect2(-18, -4, 36, 8), Color(0.15, 0.09, 0.04), false, 1.0)
