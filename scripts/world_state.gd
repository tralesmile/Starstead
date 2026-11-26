class_name WorldState
extends RefCounted
## Pure packing of the live world into the save: where you stand, where the car is (with fuel and damage),
## and what every robbed house remembers. Bad or missing parts are dropped, never guessed.

static func pack(pos: Vector2, facing: int, car_pos: Vector2, heading: float, fuel: float, health: float, robbery: Dictionary, heat: float = 0.0) -> Dictionary:
	return {
		"player": {"x": roundf(pos.x), "y": roundf(pos.y), "facing": facing},
		"car": {"x": roundf(car_pos.x), "y": roundf(car_pos.y), "heading": snappedf(heading, 0.001), "fuel": snappedf(fuel, 0.01), "health": snappedf(health, 0.01)},
		"robbery": robbery.duplicate(true),
		"heat": snappedf(heat, 0.1),
	}

static func _inside(d, bounds: Rect2) -> bool:
	return d is Dictionary and d.has("x") and d.has("y") and bounds.has_point(Vector2(float(d["x"]), float(d["y"])))

## {} when there is no usable saved spot.
static func player_of(state: Dictionary, bounds: Rect2) -> Dictionary:
	var d = state.get("player")
	if not _inside(d, bounds):
		return {}
	return {"pos": Vector2(float(d["x"]), float(d["y"])), "facing": clampi(int(d.get("facing", 0)), 0, 3)}

static func car_of(state: Dictionary, bounds: Rect2) -> Dictionary:
	var d = state.get("car")
	if not _inside(d, bounds):
		return {}
	return {"pos": Vector2(float(d["x"]), float(d["y"])), "heading": wrapf(float(d.get("heading", 0.0)), -PI, PI),
		"fuel": clampf(float(d.get("fuel", VehicleMath.FUEL_MAX)), 0.0, VehicleMath.FUEL_MAX),
		"health": clampf(float(d.get("health", VehicleMath.HEALTH_MAX)), 0.0, VehicleMath.HEALTH_MAX)}

## Wanted heat, so quitting is not a way to shake the police.
static func heat_of(state: Dictionary) -> float:
	var h = state.get("heat", 0.0)
	return clampf(float(h), 0.0, WantedMath.MAX_HEAT) if (h is float or h is int) else 0.0

## House memory (locks, dogs, grudges, emptied safes). The noise meter always starts quiet. {} when none saved.
static func robbery_of(state: Dictionary) -> Dictionary:
	var d = state.get("robbery")
	if not (d is Dictionary) or not (d.get("houses") is Dictionary):
		return {}
	return {"noise": 0.0, "houses": d["houses"]}
