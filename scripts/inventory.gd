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

func to_array() -> Array:
	return slots.duplicate(true)

func from_array(a: Array) -> void:
	slots = a.duplicate(true)
	for i in slots.size():
		if slots[i] != null:
			slots[i] = {"id": str(slots[i].id), "n": int(slots[i].n)}
