class_name Neighbours
extends RefCounted
## Pure rules for neighbours who hear a break-in next door and phone the police. Noise at the house you are robbing
## fills a "report" meter faster the more awake residents live in the OTHER city homes; at 1.0 they call.

const QUIET_NOISE := 20.0     # below this nobody hears anything through the walls
const BASE_RATE := 0.10       # meter per second at full noise with one awake neighbour
const PER_NEIGHBOUR := 0.05
const MAX_NEIGHBOURS := 4
const RELAX_RATE := -0.15     # the meter cools when it is quiet
const CALL_HEAT := 35.0

static func awake_neighbours(building_id: String, hour: float, homes: Array) -> int:
	## Awake residents in every home except the one being robbed (homes = building ids).
	var n := 0
	for h in homes:
		if String(h) == building_id:
			continue
		n += Household.awake_home(String(h), hour).size()
	return n

static func rate(noise: float, awake: int) -> float:
	## Report meter change per second.
	if awake <= 0 or noise < QUIET_NOISE:
		return RELAX_RATE
	var loud := clampf(noise / 100.0, 0.0, 1.0)
	return loud * (BASE_RATE + PER_NEIGHBOUR * float(mini(awake, MAX_NEIGHBOURS) - 1) + 0.0)

static func step(meter: float, noise: float, awake: int, dt: float) -> float:
	return clampf(meter + rate(noise, awake) * dt, 0.0, 1.0)

static func calls(meter: float) -> bool:
	return meter >= 1.0

static func seconds_to_call(noise: float, awake: int) -> float:
	## Handy for the HUD hint and tests: how long constant noise takes to get a call (INF if never).
	var r := rate(noise, awake)
	return 1.0 / r if r > 0.0 else INF

static func heat() -> float:
	return CALL_HEAT
