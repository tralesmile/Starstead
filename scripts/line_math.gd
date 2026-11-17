class_name LineMath
extends RefCounted
## Pure helpers for upgraded hoes/cans that work a straight line of tiles away from the player.

static func dir_of(facing: int) -> Vector2i:
	return [Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1), Vector2i(1, 0)][facing]

static func cells(origin: Vector2i, facing: int, n: int) -> Array:
	## `n` tiles starting at origin and continuing in the facing direction (n >= 1).
	var out: Array = []
	var d := dir_of(facing)
	for i in maxi(n, 1):
		out.append(origin + d * i)
	return out

static func capacity_for(base: int, inv: Inventory, table: Dictionary) -> int:
	## Watering can capacity: the best can upgrade in the bag sets it (capacity key), else the base.
	var best := base
	for id in table:
		if String(id).begins_with("watering_can_") and inv.count(id) > 0:
			best = maxi(best, int(table[id].get("capacity", base)))
	return best
