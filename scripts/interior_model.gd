class_name InteriorModel
extends RefCounted
## Pure interior room layouts. Cells are 32px; floor cells (0,0)..(w-1,h-1), the back wall is drawn above row 0.
## Furniture: {id, sprite, cell, size (cells), solid, action}. Door gap is the bottom-row cell door_x.

const PUBLIC := ["farmhouse", "barn", "workshop", "city_shop", "city_police", "city_cafe", "city_bank", "city_hospital", "city_garage", "city_hall", "circ_pit", "circ_hall"]   # walk straight in; other houses need their lock picked

static func kind_for(building_id: String) -> String:
	match building_id:
		"farmhouse": return "farmhouse"
		"barn": return "barn"
		"workshop": return "workshop"
	match CircuitModel.kind_of(building_id):
		"pit": return "circ_pit"
		"sports": return "circ_sports"
	var ck := CityModel.kind_of(building_id)
	if ck in ["shop", "police", "cafe", "bank", "hospital", "garage", "hall"]:
		return "city_" + ck
	return "house"

static func _f(id: String, sprite: String, x: int, y: int, w: int, h: int, solid: bool = true, action: String = "") -> Dictionary:
	return {"id": id, "sprite": sprite, "cell": Vector2i(x, y), "size": Vector2i(w, h), "solid": solid, "action": action}

static func layout(kind: String) -> Dictionary:
	match kind:
		"farmhouse":
			return {"w": 9, "h": 6, "door_x": 4, "window_x": [2, 6], "furniture": [
				_f("rug", "int_rug", 3, 2, 3, 2, false),
				_f("bed", "int_bed", 0, 1, 1, 2, true, "sleep"),
				_f("chest", "int_chest", 2, 0, 1, 1, true, "chest"),
				_f("stove", "int_stove", 4, 0, 1, 1, true, "cook"),
				_f("shelf", "int_shelf", 6, 0, 1, 1),
				_f("dresser", "int_dresser", 8, 0, 1, 1),
				_f("table", "int_table", 3, 3, 2, 1),
				_f("mat", "int_mat", 4, 5, 1, 1, false)]}
		"workshop":
			return {"w": 8, "h": 5, "door_x": 3, "window_x": [5], "furniture": [
				_f("furnace", "int_furnace", 5, 0, 1, 1, true, "smelt"),
				_f("workbench", "int_workbench", 2, 1, 2, 1, true, "garage"),
				_f("toolrack", "int_toolrack", 0, 0, 1, 1),
				_f("shelf", "int_shelf", 6, 0, 1, 1),
				_f("crate1", "int_crate", 6, 3, 1, 1),
				_f("crate2", "int_crate", 7, 3, 1, 1),
				_f("mat", "int_mat", 3, 4, 1, 1, false)]}
		"barn":
			return {"w": 9, "h": 6, "door_x": 4, "window_x": [7], "furniture": [
				_f("hay1", "int_hay", 0, 1, 1, 1),
				_f("hay2", "int_hay", 1, 1, 1, 1),
				_f("hay3", "int_hay", 0, 2, 1, 1),
				_f("sack1", "int_sack", 7, 0, 1, 1),
				_f("sack2", "int_sack", 8, 1, 1, 1),
				_f("crate", "int_crate", 8, 3, 1, 1),
				_f("mat", "int_mat", 4, 5, 1, 1, false)]}
		"city_shop":
			return {"w": 8, "h": 5, "door_x": 3, "window_x": [1, 5], "furniture": [
				_f("counter", "int_counter", 4, 1, 2, 1, true, "shop"),
				_f("register", "int_register", 6, 1, 1, 1),
				_f("shelf1", "int_shelf", 0, 0, 1, 1), _f("shelf2", "int_shelf", 2, 0, 1, 1), _f("shelf3", "int_shelf", 7, 0, 1, 1),
				_f("crate", "int_crate", 0, 3, 1, 1), _f("sack", "int_sack", 7, 3, 1, 1),
				_f("mat", "int_mat", 3, 4, 1, 1, false)]}
		"city_bank":
			return {"w": 9, "h": 6, "door_x": 4, "window_x": [2, 6], "furniture": [
				_f("teller", "int_teller", 3, 1, 2, 1, true, "bank"),
				_f("teller2", "int_teller", 5, 1, 2, 1),
				_f("vault", "int_vault", 8, 0, 1, 1),
				_f("desk", "int_desk", 0, 1, 2, 1),
				_f("rug", "int_rug", 3, 3, 3, 2, false),
				_f("mat", "int_mat", 4, 5, 1, 1, false)]}
		"city_police":
			return {"w": 8, "h": 5, "door_x": 3, "window_x": [1, 5], "furniture": [
				_f("desk", "int_desk", 2, 1, 2, 1, true, "fine"),
				_f("cell1", "int_cell", 6, 0, 1, 2), _f("cell2", "int_cell", 7, 0, 1, 2),
				_f("shelf", "int_shelf", 0, 0, 1, 1),
				_f("mat", "int_mat", 3, 4, 1, 1, false)]}
		"city_hospital":
			return {"w": 9, "h": 6, "door_x": 4, "window_x": [2, 6], "furniture": [
				_f("bed1", "int_hosp_bed", 0, 1, 1, 2, true, "heal"), _f("bed2", "int_hosp_bed", 2, 1, 1, 2, true, "heal"),
				_f("bed3", "int_hosp_bed", 6, 1, 1, 2),
				_f("medcab", "int_medcab", 4, 0, 1, 1), _f("medcab2", "int_medcab", 8, 0, 1, 1),
				_f("desk", "int_desk", 3, 3, 2, 1, true, "heal"),
				_f("mat", "int_mat", 4, 5, 1, 1, false)]}
		"city_garage":
			return {"w": 9, "h": 5, "door_x": 1, "window_x": [6], "furniture": [
				_f("lift", "int_lift", 3, 1, 2, 1, true, "garage"),
				_f("workbench", "int_workbench", 6, 0, 2, 1, true, "garage"),
				_f("tyres", "int_tyres", 0, 0, 1, 1), _f("tyres2", "int_tyres", 8, 3, 1, 1),
				_f("toolrack", "int_toolrack", 0, 2, 1, 1),
				_f("mat", "int_mat", 1, 4, 1, 1, false)]}
		"city_cafe":
			return {"w": 7, "h": 5, "door_x": 1, "window_x": [3, 5], "furniture": [
				_f("counter", "int_counter", 4, 0, 2, 1, true, "coffee"),
				_f("table1", "int_table", 1, 1, 2, 1), _f("table2", "int_table", 4, 3, 2, 1),
				_f("stove", "int_stove", 6, 0, 1, 1),
				_f("mat", "int_mat", 1, 4, 1, 1, false)]}
		"circ_pit":
			return {"w": 7, "h": 5, "door_x": 1, "window_x": [3, 5], "furniture": [
				_f("pitdesk", "int_pitdesk", 3, 0, 2, 1, true, "licence"),
				_f("tyres", "int_tyres", 0, 0, 1, 1), _f("tyres2", "int_tyres", 6, 3, 1, 1),
				_f("toolrack", "int_toolrack", 6, 0, 1, 1),
				_f("bench", "int_bench", 4, 3, 2, 1),
				_f("mat", "int_mat", 1, 4, 1, 1, false)]}
		"circ_sports":
			return {"w": 10, "h": 7, "door_x": 4, "window_x": [2, 7], "furniture": [
				_f("scoreboard", "int_scoreboard", 4, 0, 2, 1),
				_f("hoop", "int_hoop", 1, 0, 1, 1, true, "hoops"),
				_f("hoop2", "int_hoop", 8, 0, 1, 1, true, "hoops"),
				_f("ring", "int_ring", 6, 2, 3, 3, true, "ring"),
				_f("bag", "int_punchbag", 3, 1, 1, 1),
				_f("locker", "int_locker", 0, 3, 1, 1), _f("locker2", "int_locker", 0, 4, 1, 1),
				_f("bench", "int_bench", 2, 5, 2, 1),
				_f("mat", "int_mat", 4, 6, 1, 1, false)]}
		"city_hall":
			return {"w": 9, "h": 6, "door_x": 4, "window_x": [2, 6], "furniture": [
				_f("desk", "int_desk", 3, 1, 2, 1, true, "notice"),
				_f("shelf1", "int_shelf", 0, 0, 1, 1), _f("shelf2", "int_shelf", 8, 0, 1, 1),
				_f("rug", "int_rug", 3, 3, 3, 2, false),
				_f("mat", "int_mat", 4, 5, 1, 1, false)]}
	return {"w": 7, "h": 5, "door_x": 3, "window_x": [1, 5], "furniture": [
		_f("rug", "int_rug", 2, 2, 3, 2, false),
		_f("bed", "int_bed", 0, 1, 1, 2),
		_f("shelf", "int_shelf", 3, 0, 1, 1, true, "loot"),
		_f("dresser", "int_dresser", 5, 0, 1, 1, true, "loot"),
		_f("table", "int_table", 2, 2, 2, 1, true, "loot"),
		_f("chest", "int_chest", 6, 3, 1, 1, true, "loot"),
		_f("mat", "int_mat", 3, 4, 1, 1, false)]}

## Where the player appears when entering: just above the door mat, in pixels relative to the room origin.
static func entrance(l: Dictionary) -> Vector2:
	return Vector2((int(l["door_x"]) + 0.5) * 32.0, (int(l["h"]) - 1) * 32.0 + 8.0)

## True when the pixel position (relative to the room) has walked out through the door gap.
static func left_through_door(l: Dictionary, p: Vector2) -> bool:
	return p.y > int(l["h"]) * 32.0 + 4.0 and absf(p.x - (int(l["door_x"]) + 0.5) * 32.0) < 20.0

## Solid furniture rectangles in px (relative to the room) for collision.
static func solid_rects(l: Dictionary) -> Array[Rect2]:
	var out: Array[Rect2] = []
	for f in l["furniture"]:
		if f["solid"]:
			out.append(Rect2(Vector2(f["cell"]) * 32.0, Vector2(f["size"]) * 32.0))
	return out

## Furniture the player can use from p (within 40px of its footprint), or {}.
static func action_near(l: Dictionary, p: Vector2, want: Array = []) -> Dictionary:
	for f in l["furniture"]:
		var a := String(f["action"])
		if a == "" or (not want.is_empty() and not (a in want)):
			continue
		var r := Rect2(Vector2(f["cell"]) * 32.0, Vector2(f["size"]) * 32.0).grow(24.0)
		if r.has_point(p):
			return f
	return {}
