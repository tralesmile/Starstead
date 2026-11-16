class_name BuildModel
extends RefCounted
## Pure build-mode rules: placement validity, cost, refund. Cells are Vector2i tile coords.

const PIECES := ["floor", "wall", "door", "fence"]
var defs: Dictionary
var placed: Dictionary = {}  # Vector2i -> piece id

func _init(d: Dictionary = {}) -> void:
	defs = d

func can_afford(piece: String, bag: Inventory) -> bool:
	if not defs.has(piece):
		return false
	for id in defs[piece].cost:
		if bag.count(id) < int(defs[piece].cost[id]):
			return false
	return true

func check(cell: Vector2i, piece: String, sdf: float, blocked: bool, bag: Inventory) -> String:
	## "" when placeable, else the reason (shown in red by the ghost).
	if not defs.has(piece):
		return "Unknown piece"
	if sdf < 0.9:
		return "Too close to water"
	if blocked:
		return "Something is in the way"
	if placed.has(cell):
		return "Occupied"
	if not can_afford(piece, bag):
		return "Need materials"
	return ""

func place(cell: Vector2i, piece: String, sdf: float, blocked: bool, bag: Inventory) -> String:
	var why := check(cell, piece, sdf, blocked, bag)
	if why != "":
		return why
	for id in defs[piece].cost:
		bag.remove(id, int(defs[piece].cost[id]))
	placed[cell] = piece
	return ""

func remove_piece(cell: Vector2i, bag: Inventory) -> bool:
	## Demolish: refund half the cost (rounded down, at least 1 of the first material).
	if not placed.has(cell):
		return false
	var piece: String = placed[cell]
	for id in defs[piece].cost:
		bag.add(id, maxi(1, int(defs[piece].cost[id]) / 2))
	placed.erase(cell)
	return true

func is_solid(cell: Vector2i) -> bool:
	return placed.has(cell) and bool(defs[placed[cell]].solid)

func to_dict() -> Dictionary:
	var out := {}
	for c in placed:
		out["%d,%d" % [c.x, c.y]] = placed[c]
	return out

func from_dict(d: Dictionary) -> void:
	placed.clear()
	for k in d:
		var p: PackedStringArray = str(k).split(",")
		if p.size() == 2 and defs.has(str(d[k])):
			placed[Vector2i(int(p[0]), int(p[1]))] = str(d[k])
