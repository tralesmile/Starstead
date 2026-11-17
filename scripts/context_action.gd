class_name ContextAction
extends RefCounted
## "Do the obvious thing" for E / right-click when nothing else is interactable.

const NONE := Vector2i(-9999, -9999)

static func ripe_cell(farm: FarmModel, facing_cell: Vector2i, own_cell: Vector2i) -> Vector2i:
	## A ripe crop on the faced tile, else on the tile underfoot, can be harvested with E; NONE otherwise.
	if farm.is_ripe(facing_cell):
		return facing_cell
	if farm.is_ripe(own_cell):
		return own_cell
	return NONE

static func hint(farm: FarmModel, facing_cell: Vector2i, own_cell: Vector2i) -> String:
	return "E: harvest" if ripe_cell(farm, facing_cell, own_cell) != NONE else ""
