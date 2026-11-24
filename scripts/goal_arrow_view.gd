class_name GoalArrowView
extends CanvasLayer
## Tutorial arrow on the screen edge pointing at the first-day goal (nearest tree, then the farmhouse bed). See GoalArrow.

var player: Node2D
var gen: WorldGen
var town: TownView
var kind := ""
var _spr: Sprite2D
var _t := 0.0
var _tree_cells: Array = []

func setup(p: Node2D, g: WorldGen, t: TownView) -> void:
	player = p
	gen = g
	town = t
	layer = 9
	_spr = Sprite2D.new()
	_spr.texture = load("res://assets/sprites/goal_arrow.png")
	_spr.scale = Vector2(3, 3)
	_spr.visible = false
	add_child(_spr)

func set_kind(k: String) -> void:
	kind = k

func target_world() -> Vector2:
	match kind:
		"tree":
			var pts: Array = []
			for c in gen.trees:
				pts.append(Vector2(c) * 32.0 + Vector2(16, 16))
			return GoalArrow.nearest(player.position, pts)
		"bed":
			for b in town.buildings:
				if String(b["id"]) == "farmhouse":
					return Vector2(b["door"]) * 32.0 + Vector2(16, 16)
	return Vector2.INF

func _process(delta: float) -> void:
	_t += delta
	var tgt := target_world() if kind != "" else Vector2.INF
	if tgt == Vector2.INF or player == null or player.indoors:
		_spr.visible = false
		return
	var a := GoalArrow.alpha(player.position.distance_to(tgt))
	_spr.visible = a > 0.0
	if not _spr.visible:
		return
	var vp := get_viewport().get_visible_rect().size
	var zoom: float = player.camera.zoom.x if player.camera != null else 1.5
	var centre: Vector2 = player.camera.get_screen_center_position() if player.camera != null else player.position
	var e := GoalArrow.edge_pos(centre, tgt, vp * 0.5 / zoom)
	var dir := Vector2.from_angle(float(e["angle"]))
	_spr.position = vp * 0.5 + (e["pos"] as Vector2) * zoom + dir * GoalArrow.bob(_t)
	_spr.rotation = float(e["angle"])
	_spr.modulate.a = a * 0.9
