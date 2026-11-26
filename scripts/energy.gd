class_name Energy
extends RefCounted
## Stardew-style limiter: tools cost energy; sleeping restores; passing out restores less.

const MAX := 100
const COSTS := {"hoe": 2, "watering_can": 1, "axe": 4, "pickaxe": 4, "seed": 0, "hand": 0, "rod": 2, "club": 2, "bow": 1, "scythe": 1, "sprinkler": 0, "scarecrow": 0, "crab_pot": 0, "snare": 0}
var value: float = MAX
var discounts: Dictionary = {}   # tool -> energy saved per use (perks); a costly tool never drops below 1

func cost_of(tool: String) -> int:
	var base := int(COSTS.get(tool, 0 if tool.ends_with("_seed") else 1))
	var saved := int(discounts.get(tool, 0))
	return maxi(1, base - saved) if base > 0 and saved > 0 else base

func can_use(tool: String) -> bool:
	return value >= cost_of(tool)

func spend(tool: String) -> bool:
	if not can_use(tool):
		return false
	value -= cost_of(tool)
	return true

func new_day(passed_out: bool) -> void:
	value = MAX * (0.5 if passed_out else 1.0)
	value = float(MAX) if not passed_out else 50.0
