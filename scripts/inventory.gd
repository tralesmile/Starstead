class_name Inventory
extends RefCounted
## Slot-based inventory. Slots are {id, n} or null. First HOTBAR slots form the hotbar.

const HOTBAR := 10
var slots: Array = []
var stack_limits: Dictionary = {}  # id -> max stack (from items.json)

func _init(size: int = 30, limits: Dictionary = {}) -> void:
	slots.resize(size)
	stack_limits = limits

func limit(id: String) -> int:
	return int(stack_limits.get(id, 99))

func add(id: String, n: int = 1) -> int:
	## Returns the leftover that did not fit.
	for s in slots:
		if n <= 0:
			break
		if s != null and s.id == id and s.n < limit(id):
			var put := mini(n, limit(id) - s.n)
			s.n += put
			n -= put
	for i in slots.size():
		if n <= 0:
			break
		if slots[i] == null:
			var put := mini(n, limit(id))
			slots[i] = {"id": id, "n": put}
			n -= put
	return n

func fill_fraction() -> float:
	var used := 0
	for s in slots:
		if s != null:
			used += 1
	return float(used) / maxf(float(slots.size()), 1.0)

func count(id: String) -> int:
	var c := 0
	for s in slots:
		if s != null and s.id == id:
			c += s.n
	return c

func remove(id: String, n: int = 1) -> bool:
	if count(id) < n:
		return false
	for i in range(slots.size() - 1, -1, -1):
		var s = slots[i]
		if n <= 0:
			break
		if s != null and s.id == id:
			var take := mini(n, s.n)
			s.n -= take
			n -= take
			if s.n == 0:
				slots[i] = null
	return true

func ensure_size(n: int) -> void:
	## Grows the grid (never shrinks, so nothing is lost).
	if slots.size() < n:
		slots.resize(n)

func to_array() -> Array:
	return slots.duplicate(true)

func from_array(a: Array) -> void:
	slots = a.duplicate(true)
	for i in slots.size():
		if slots[i] != null:
			slots[i] = {"id": str(slots[i].id), "n": int(slots[i].n)}

## Move/merge slot i onto slot j: same item merges up to the stack limit, otherwise the two swap.
func swap(i: int, j: int) -> void:
	if i == j or i < 0 or j < 0 or i >= slots.size() or j >= slots.size():
		return
	var a = slots[i]
	var b = slots[j]
	if a != null and b != null and a.id == b.id:
		var put := mini(int(a.n), limit(a.id) - int(b.n))
		if put > 0:
			b.n += put
			a.n -= put
			if a.n <= 0:
				slots[i] = null
			return
	slots[i] = b
	slots[j] = a

## Throw away a whole slot (returns what was removed or null).
func trash(i: int):
	if i < 0 or i >= slots.size():
		return null
	var s = slots[i]
	slots[i] = null
	return s

## Merge stacks and order by item id; empty slots go to the end.
func sort() -> void:
	var totals := {}
	for s in slots:
		if s != null:
			totals[s.id] = int(totals.get(s.id, 0)) + int(s.n)
	var ids := totals.keys()
	ids.sort()
	for i in slots.size():
		slots[i] = null
	var k := 0
	for id in ids:
		var left: int = totals[id]
		while left > 0 and k < slots.size():
			var put := mini(left, limit(id))
			slots[k] = {"id": id, "n": put}
			k += 1
			left -= put

## Grid slot under point p (origin = top-left of slot 0, cell = slot pitch), or -1.
static func slot_at(p: Vector2, origin: Vector2, cell: float, cols: int, n: int) -> int:
	var d := (p - origin) / cell
	if d.x < 0.0 or d.y < 0.0:
		return -1
	var cx := floori(d.x)
	var cy := floori(d.y)
	if cx >= cols:
		return -1
	var i := cy * cols + cx
	return i if i < n else -1
