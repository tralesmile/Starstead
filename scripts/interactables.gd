class_name Interactables
extends RefCounted
## Registry of things the player can press E on (shop stall now; doors, beds, NPCs, cars later).

var cells: Dictionary = {}  # Vector2i -> {"kind": String, "prompt": String}

func add(cell: Vector2i, kind: String, prompt: String, extra: Dictionary = {}) -> void:
	var d := {"kind": kind, "prompt": prompt}
	d.merge(extra)
	cells[cell] = d

func at(cell: Vector2i) -> Dictionary:
	return cells.get(cell, {})

func near(pos: Vector2, facing_cell: Vector2i, tile: int = 32) -> Dictionary:
	## The interactable on the faced cell, else one on the player's own cell, else {}.
	var f := at(facing_cell)
	if not f.is_empty():
		return f
	return at(Vector2i(floori(pos.x / tile), floori(pos.y / tile)))
