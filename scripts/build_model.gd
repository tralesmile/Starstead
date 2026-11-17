class_name BuildModel
extends RefCounted
## Pure build-mode rules: placement validity, cost, refund. Cells are Vector2i tile coords.

const PIECES := ["floor", "wall", "door", "fence", "roof"]
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

# --- Blueprints and rooms -------------------------------------------------
const BLUEPRINTS := {
	"hut": {
		"name": "Small Hut",
		"cells": [
			[0, 0, "wall"], [1, 0, "wall"], [2, 0, "wall"],
			[0, 1, "wall"], [1, 1, "floor"], [2, 1, "wall"],
			[0, 2, "wall"], [1, 2, "door"], [2, 2, "wall"],
		],
	},
}

func blueprint_cost(name: String) -> Dictionary:
	var total := {}
	for e in BLUEPRINTS[name].cells:
		for id in defs[e[2]].cost:
			total[id] = int(total.get(id, 0)) + int(defs[e[2]].cost[id])
	return total

func stamp(name: String, origin: Vector2i, bag: Inventory) -> int:
	## Places every affordable, free piece of the blueprint (no water/blocked data here,
	## the view pre-checks); returns the number of pieces placed.
	var n := 0
	if not BLUEPRINTS.has(name):
		return 0
	for e in BLUEPRINTS[name].cells:
		var c := origin + Vector2i(int(e[0]), int(e[1]))
		if place(c, str(e[2]), 3.0, false, bag) == "":
			n += 1
	return n

func is_enclosed(cell: Vector2i, limit: int = 64) -> bool:
	## True when `cell` (a floor) is sealed by solid pieces/doors: flood fill over
	## non-solid, non-door cells that stays under `limit` tiles. Used to fade roofs/interior.
	var seen := {cell: true}
	var q := [cell]
	while not q.is_empty():
		var c: Vector2i = q.pop_back()
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = c + d
			if seen.has(n):
				continue
			if placed.has(n) and (is_solid(n) or placed[n] == "door"):
				continue
			seen[n] = true
			if seen.size() > limit:
				return false
			q.append(n)
	return true
