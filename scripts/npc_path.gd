class_name NpcPath
extends RefCounted
## Pure A* routing over land cells (AStarGrid2D). is_land_cell: Callable(Vector2i)->bool.
## Returns a list of cell centres (pixels) from start to goal, or [] if unreachable.

static func build(size: int, is_land_cell: Callable) -> AStarGrid2D:
	var g := AStarGrid2D.new()
	g.region = Rect2i(0, 0, size, size)
	g.cell_size = Vector2(32, 32)
	g.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	g.update()
	for y in size:
		for x in size:
			if not is_land_cell.call(Vector2i(x, y)):
				g.set_point_solid(Vector2i(x, y), true)
	return g

static func route(g: AStarGrid2D, from: Vector2i, to: Vector2i) -> Array[Vector2]:
	var out: Array[Vector2] = []
	if not g.is_in_boundsv(from) or not g.is_in_boundsv(to):
		return out
	if g.is_point_solid(from) or g.is_point_solid(to):
		return out
	for c in g.get_id_path(from, to):
		out.append((Vector2(c) + Vector2(0.5, 0.6)) * 32.0)
	return out
