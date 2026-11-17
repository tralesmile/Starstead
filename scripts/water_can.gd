class_name WaterCan
extends RefCounted
## Watering can with limited water: each watered tile costs 1, refill by using it on water.

var capacity := 20
var level := 20

func is_empty() -> bool:
	return level <= 0

func fraction() -> float:
	return float(level) / float(maxi(capacity, 1))

## Spend one unit; false when empty.
func use() -> bool:
	if level <= 0:
		return false
	level -= 1
	return true

## Fill to capacity; returns how many units were added (0 when already full).
func refill() -> int:
	var added := capacity - level
	level = capacity
	return added

func set_capacity(cap: int) -> void:
	## Bigger can from a bag upgrade: the extra room starts filled (like a fresh purchase), never shrinks the level.
	cap = maxi(cap, 1)
	if cap > capacity:
		level += cap - capacity
	capacity = cap
	level = mini(level, capacity)

func upgrade(extra: int) -> void:
	capacity += extra
	level = capacity

func to_dict() -> Dictionary:
	return {"capacity": capacity, "level": level}

func from_dict(d: Dictionary) -> void:
	capacity = maxi(int(d.get("capacity", 20)), 1)
	level = clampi(int(d.get("level", capacity)), 0, capacity)
