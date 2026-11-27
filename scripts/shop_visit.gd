class_name ShopVisit
extends RefCounted
## Pure rules of day shoppers at your own Farm Shop: when one calls, the walk (a 4-way route that only enters
## through the front door) and the one-unit purchase. A day sale uses up part of tonight's customer quota
## (FarmShopModel.day_sold), so shoppers bring cash early, never extra. The view is ShopperView.

const REACH := 40   # search limit in steps

var next_in := -1.0   # game minutes until the next caller; -1 = not scheduled yet. Not saved: the quota is.

static func is_open(rule: Dictionary, hour: float) -> bool:
	return hour >= float(rule.open) and hour < float(rule.close)

static func shop_room(placed: Dictionary, rooms: Dictionary, defs: Dictionary) -> Dictionary:
	## The finished room that trades as the shop (most shelves): {"shelves", "flood"}, or {} when there is none.
	var best := {}
	for r in RoomModel.find_rooms(placed, rooms, defs):
		if RoomModel.missing(r.flood, rooms.shop, defs).is_empty():
			var n := int(r.flood.count.get("shelf", 0))
			if best.is_empty() or n > int(best.shelves):
				best = {"shelves": n, "flood": r.flood}
	return best

static func wants_visit(rule: Dictionary, hour: float, shop: FarmShopModel, room: Dictionary) -> bool:
	return is_open(rule, hour) and not room.is_empty() and shop.total() > 0 \
		and FarmShopModel.quota_left(rule, int(room.shelves), shop.day_sold) > 0

static func roll(span: Array, rng: RandomNumberGenerator) -> float:
	return rng.randf_range(float(span[0]), float(span[1]))

func tick(rule: Dictionary, minutes: float, eligible: bool, rng: RandomNumberGenerator) -> bool:
	## Advances the wait by game minutes; true when someone should set out now. Waits start over while ineligible.
	if not eligible:
		next_in = -1.0
		return false
	if next_in < 0.0:
		next_in = roll(rule.first_visit_min, rng)
	next_in -= minutes
	if next_in > 0.0:
		return false
	next_in = roll(rule.visit_gap_min, rng)
	return true

static func buy(shop: FarmShopModel, menu: ShopMenu, rule: Dictionary, shelves: int) -> Dictionary:
	## The shopper's purchase: {"id", "money"}, or {} when the shelves are bare or today's custom is used up.
	if FarmShopModel.quota_left(rule, shelves, shop.day_sold) <= 0:
		return {}
	var sale := shop.sell_one(menu, float(rule.premium))
	if not sale.is_empty():
		shop.day_sold += 1
	return sale

static func _search(passable: Callable, from: Vector2i, max_steps: int) -> Dictionary:
	## Breadth first, 4-way: {"from": {cell: previous cell}, "order": [cells], "steps": {cell: n}}
	var prev := {from: from}
	var steps := {from: 0}
	var order: Array[Vector2i] = [from]
	var i := 0
	while i < order.size():
		var c := order[i]
		i += 1
		if int(steps[c]) >= max_steps:
			continue
		for d in RoomModel.DIRS:
			var n: Vector2i = c + d
			if not prev.has(n) and passable.call(n):
				prev[n] = c
				steps[n] = int(steps[c]) + 1
				order.append(n)
	return {"prev": prev, "order": order, "steps": steps}

static func _back(prev: Dictionary, end: Vector2i) -> Array[Vector2i]:
	## The cells from `end` back to the search origin.
	var out: Array[Vector2i] = [end]
	while prev[out[-1]] != out[-1]:
		out.append(prev[out[-1]])
	return out

static func is_wall(placed: Dictionary, defs: Dictionary, c: Vector2i) -> bool:
	return RoomModel.is_edge(placed, c) or (placed.has(c) and bool(defs.get(placed[c], {}).get("solid", false)))

static func doorways(placed: Dictionary, defs: Dictionary, flood: Dictionary) -> Array:
	## Front-most first: {"door", "outside", "inside"} for each door that leads from outdoors straight into the room.
	var doors: Array = flood.doors.keys()
	doors.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.y > b.y or (a.y == b.y and a.x < b.x))
	var out := []
	for d in doors:
		for step in [Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1)]:
			var outside: Vector2i = d + step
			var inside: Vector2i = d - step
			if flood.cells.has(inside) and not flood.cells.has(outside) and not is_wall(placed, defs, outside) and not is_wall(placed, defs, inside):
				out.append({"door": d, "outside": outside, "inside": inside})
	return out

static func browse_route(placed: Dictionary, defs: Dictionary, flood: Dictionary, inside: Vector2i, rng: RandomNumberGenerator) -> Dictionary:
	## From just inside the door to a free floor tile beside a shelf (else the counter): {"path", "goods"} or {}.
	var free := func(c: Vector2i) -> bool: return flood.cells.has(c) and not is_wall(placed, defs, c)
	var found := _search(free, inside, REACH)
	for want in ["shelf", "shop_counter"]:
		var picks := []
		for c in found.order:
			for d in [Vector2i(0, -1), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, 1)]:   # rather face up at the goods
				if placed.get(c + d, "") == want and flood.cells.has(c + d):
					picks.append({"spot": c, "goods": c + d})
					break
		if not picks.is_empty():
			var p: Dictionary = picks[rng.randi() % picks.size()]
			var path := _back(found.prev, p.spot)
			path.reverse()
			return {"path": path, "goods": p.goods}
	return {}

static func approach(passable: Callable, outside: Vector2i, depth: int, rng: RandomNumberGenerator) -> Array[Vector2i]:
	## A walk of up to `depth` steps ending at the doorstep, from one of the farthest tiles that can reach it.
	var found := _search(passable, outside, depth)
	var far := 0
	for c in found.order:
		far = maxi(far, int(found.steps[c]))
	var picks: Array = found.order.filter(func(c): return int(found.steps[c]) == far)
	return _back(found.prev, picks[rng.randi() % picks.size()])

static func plan(placed: Dictionary, defs: Dictionary, flood: Dictionary, ground: Callable, depth: int, rng: RandomNumberGenerator) -> Dictionary:
	## The whole walk in: {"route": [cells], "door", "goods"}, or {} if nobody can get in.
	## ground.call(cell) says whether the land itself is walkable (water, trees, buildings).
	var outdoors := func(c: Vector2i) -> bool: return not flood.cells.has(c) and not is_wall(placed, defs, c) and ground.call(c)
	for way in doorways(placed, defs, flood):
		if not outdoors.call(way.outside):
			continue
		var browse := browse_route(placed, defs, flood, way.inside, rng)
		if browse.is_empty():
			continue
		var route := approach(outdoors, way.outside, depth, rng)
		if route.size() < 2:
			continue   # boxed in: nobody can come up to this door
		route.append(way.door)
		route.append_array(browse.path)
		return {"route": route, "door": way.door, "goods": browse.goods}
	return {}

static func route_clear(placed: Dictionary, defs: Dictionary, route: Array, door: Vector2i) -> bool:
	## False once building has put a wall or furniture on the walk, or taken the door away.
	for c in route:
		if c == door:
			if placed.get(c, "") != "door":
				return false
		elif is_wall(placed, defs, c):
			return false
	return true
