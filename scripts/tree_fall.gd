class_name TreeFall
extends RefCounted
## Pure model of a felled tree: the last axe hit topples it (no wood yet), the fallen trunk
## lies there as a log that needs LOG_HITS more axe hits, then it turns into wood drops.
## Transient (not saved): a log lost on reload only costs a few wood; the stump lives in ResourceNodes.

const FALL_TIME := 0.8
const LOG_HITS := 2
const LOG_WOOD := 3
const LAND := 1.5708  # a lying trunk is rotated a quarter turn

var logs: Dictionary = {}   # cell -> {"hp": int, "landed": bool, "dir": float}

## Trunk angle (radians) at time t seconds into the fall: slow start, accelerating, small rebound.
static func angle(t: float, dir: float) -> float:
	var k := clampf(t / FALL_TIME, 0.0, 1.0)
	var a := pow(k, 2.4) * LAND
	if k > 0.88 and k < 1.0:
		a += sin((k - 0.88) / 0.12 * PI) * 0.07 * (1.0 - (k - 0.88) / 0.12)
	return a * dir

## Whole-pixel sideways shake of the trunk right after it lands; zero before and after.
static func impact_shake(t: float) -> float:
	var s := t - FALL_TIME
	if s < 0.0 or s > 0.25:
		return 0.0
	return roundf(sin(s * 70.0) * 3.0 * (1.0 - s / 0.25))

func start(cell: Vector2i, dir: float) -> void:
	logs[cell] = {"hp": LOG_HITS, "landed": false, "dir": dir}

func land(cell: Vector2i) -> void:
	if logs.has(cell):
		logs[cell].landed = true

func has_log(cell: Vector2i) -> bool:
	return logs.has(cell) and logs[cell].landed

func is_falling(cell: Vector2i) -> bool:
	return logs.has(cell) and not logs[cell].landed

## {} when there is no landed log, {"hit":true,"hp"} while chopping, {"id","n"} when it falls apart.
func hit(cell: Vector2i) -> Dictionary:
	if not has_log(cell):
		return {}
	logs[cell].hp -= 1
	if logs[cell].hp > 0:
		return {"hit": true, "hp": logs[cell].hp}
	logs.erase(cell)
	return {"id": "wood", "n": LOG_WOOD}
