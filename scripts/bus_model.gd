class_name BusModel
extends RefCounted
## Pure bus network rules (Earth fast travel, PLAN E12): stops at the main places, distance fares (a money sink),
## a bus every 30 minutes between 06:00 and 23:00, ride time by distance.

const FIRST_HOUR := 6
const LAST_HOUR := 23          # no departures from 23:00 on
const INTERVAL := 30           # minutes between buses
const CELLS_PER_MIN := 4.5     # bus speed
const MIN_FARE := 5

static func make_stops(cave_mouth: Vector2i, hubs: Dictionary, workshop: Vector2i) -> Array:
	## {id, name, cell}; every stop stands a couple of cells off the place it serves, beside the road.
	var out: Array = [
		{"id": "home", "name": "Homestead", "cell": workshop + Vector2i(3, 2)},
		{"id": "city", "name": "Port Halden", "cell": CityModel.SPAWN + Vector2i(3, 0)},
		{"id": "harbour", "name": "Halden Harbour", "cell": HarbourModel.BOARD + Vector2i(-3, -1)},
		{"id": "circuit", "name": "Race Circuit", "cell": CircuitModel.START_CELL + Vector2i(3, 2)}]
	if cave_mouth.x != RoadNet.NO_CELL:
		out.append({"id": "mine", "name": "Mine", "cell": cave_mouth + Vector2i(-3, 2)})
	for id in ["farmland", "lumber", "vance"]:
		if hubs.has(id):
			var nm: String = {"farmland": "Halden Farmland", "lumber": "Lumber Camp", "vance": "Vance Aerospace"}[id]
			out.append({"id": id, "name": nm, "cell": Vector2i(hubs[id]) + Vector2i(2, 1)})
	return out

static func fare(a: Vector2i, b: Vector2i) -> int:
	return MIN_FARE + int(Vector2(a - b).length() / 9.0)

static func ride_minutes(a: Vector2i, b: Vector2i) -> int:
	return maxi(5, int(Vector2(a - b).length() / CELLS_PER_MIN))

static func in_service(minutes_since_6: float) -> bool:
	## Departures run from 06:00 up to (not including) 23:00.
	var h := FIRST_HOUR + int(minutes_since_6) / 60
	return h >= FIRST_HOUR and h < LAST_HOUR

static func wait_minutes(minutes_since_6: float) -> int:
	## Minutes until the next departure (buses leave on the hour and half hour).
	var m := fposmod(minutes_since_6, float(INTERVAL))
	return 0 if m < 0.001 else int(ceil(float(INTERVAL) - m))

static func options(stops: Array, here: String, money: int, open_cb: Callable) -> Array:
	## One row per other stop: {id, name, fare, minutes, ok, why}. `open_cb(cell)` is false inside a story-locked region.
	var from := Vector2i.ZERO
	for s in stops:
		if s["id"] == here:
			from = s["cell"]
	var out: Array = []
	for s in stops:
		if s["id"] == here:
			continue
		var f := fare(from, s["cell"])
		var row := {"id": s["id"], "name": s["name"], "cell": s["cell"], "fare": f, "minutes": ride_minutes(from, s["cell"]), "ok": true, "why": ""}
		if not open_cb.call(s["cell"]):
			row["ok"] = false
			row["why"] = "road closed"
		elif money < f:
			row["ok"] = false
			row["why"] = "need $%d" % f
		out.append(row)
	return out

static func nearest_stop(stops: Array, cell: Vector2, reach: float) -> Dictionary:
	var best := {}
	var bd := reach
	for s in stops:
		var d := cell.distance_to(Vector2(s["cell"]) + Vector2(0.5, 0.5))
		if d <= bd:
			bd = d
			best = s
	return best

static func arrival_minutes(now: float, from: Vector2i, to: Vector2i) -> float:
	## Clock minutes (since 06:00) when you step off.
	return now + float(wait_minutes(now) + ride_minutes(from, to))
