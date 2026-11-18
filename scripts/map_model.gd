class_name MapModel
extends RefCounted
## Pure world-map math + points of interest (key M). The whole Earth (512x512 cells) is shown as a 128x128 image, 4 cells per pixel.

const X0 := -192
const Y0 := -256
const SPAN := 512
const STEP := 4
const N := SPAN / STEP

static func to_map(cell: Vector2) -> Vector2:
	## World cell -> map pixel (float, may fall outside when the cell is beyond the world).
	return Vector2((cell.x - X0) / STEP, (cell.y - Y0) / STEP)

static func from_map(p: Vector2) -> Vector2:
	return Vector2(p.x * STEP + X0, p.y * STEP + Y0)

static func clamp_px(p: Vector2) -> Vector2:
	return Vector2(clampf(p.x, 0.0, N - 1.0), clampf(p.y, 0.0, N - 1.0))

static func pois(cave_mouth: Vector2i, hubs: Dictionary, workshop: Vector2i = Vector2i(20, 30)) -> Array:
	## {name, cell, kind}; kind picks the marker colour. fuel = places where the car can refuel (garage menu).
	var out: Array = []
	out.append({"name": "Homestead", "cell": Vector2i(32, 32), "kind": "home"})
	out.append({"name": "Workshop (fuel)", "cell": workshop, "kind": "fuel"})
	out.append({"name": "Port Halden", "cell": CityModel.SPAWN, "kind": "town"})
	for b in CityModel.buildings():
		if b["kind"] == "garage":
			out.append({"name": "Garage (fuel)", "cell": b["door"], "kind": "fuel"})
	out.append({"name": "Halden Harbour", "cell": HarbourModel.BOARD, "kind": "sea"})
	out.append({"name": "Race Circuit", "cell": CircuitModel.START_CELL, "kind": "race"})
	if cave_mouth.x != RoadNet.NO_CELL:
		out.append({"name": "Mine", "cell": cave_mouth, "kind": "cave"})
	for id in ["vance", "farmland", "lumber"]:
		if hubs.has(id):
			var nm: String = {"vance": "Vance Aerospace", "farmland": "Farmland", "lumber": "Lumber Camp"}[id]
			out.append({"name": nm, "cell": hubs[id], "kind": "place"})
	return out

static func nearest_fuel(cell: Vector2i, list: Array) -> Dictionary:
	var best := {}
	var bd := INF
	for p in list:
		if p["kind"] != "fuel":
			continue
		var d := Vector2(p["cell"] - cell).length()
		if d < bd:
			bd = d
			best = p
	return best

static func fuel_prompt(cell: Vector2i, list: Array) -> String:
	var f := nearest_fuel(cell, list)
	if f.is_empty():
		return ""
	return "%s: %s" % [f["name"], RoadNet.direction_text(cell, f["cell"])]
