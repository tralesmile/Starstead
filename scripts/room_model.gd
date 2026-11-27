class_name RoomModel
extends RefCounted
## Pure rules for player-built rooms (data/rooms.json). A room is the space a flood fill reaches before it hits
## walls or doors. With a closed outline, a door, enough floor space and the right furniture it gets a purpose.
## `placed` is BuildModel.placed (Vector2i -> piece id); fences and lamps do not close a room.

const LIMIT := 64
const DIRS := [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]

static func is_edge(placed: Dictionary, c: Vector2i) -> bool:
	return placed.has(c) and (placed[c] == "wall" or placed[c] == "door")

static func flood(placed: Dictionary, start: Vector2i, limit: int = LIMIT) -> Dictionary:
	## {"enclosed", "cells": {cell: true}, "doors": {cell: true}, "count": {piece: n}}
	var out := {"enclosed": false, "cells": {}, "doors": {}, "count": {}}
	if is_edge(placed, start):
		return out
	var seen := {start: true}
	var q := [start]
	while not q.is_empty():
		var c: Vector2i = q.pop_back()
		if placed.has(c):
			out.count[placed[c]] = int(out.count.get(placed[c], 0)) + 1
		for d in DIRS:
			var n: Vector2i = c + d
			if is_edge(placed, n):
				if placed[n] == "door":
					out.doors[n] = true
				continue
			if seen.has(n):
				continue
			seen[n] = true
			if seen.size() > limit:
				return out   # leaks to the outdoors (or is far too big to be a room)
			q.append(n)
	out.enclosed = true
	out.cells = seen
	return out

static func missing(fl: Dictionary, type: Dictionary, defs: Dictionary) -> Array:
	## What stops this space being a room of `type`; empty = it works.
	var out := []
	if not fl.enclosed:
		out.append("walls closed all the way round")
		return out
	if fl.doors.is_empty():
		out.append("a door")
	for id in type.needs:
		var short := int(type.needs[id]) - int(fl.count.get(id, 0))
		if short > 0:
			out.append("a " + String(defs[id].name))
	if fl.cells.size() < int(type.min_cells):
		out.append("more space (%d of %d tiles)" % [fl.cells.size(), int(type.min_cells)])
	return out

static func needs_text(name: String, miss: Array) -> String:
	return "%s needs: %s" % [name, ", ".join(PackedStringArray(miss))]

static func station_type(rooms: Dictionary, piece: String) -> String:
	## The room type whose E-station this piece is, or "".
	for t in rooms:
		if String(rooms[t].station) == piece:
			return t
	return ""

static func station_check(placed: Dictionary, station: Vector2i, type_id: String, rooms: Dictionary, defs: Dictionary) -> Dictionary:
	## Does the room this station stands in work as `type_id`? {"ok", "missing", "flood"}
	var fl := flood(placed, station)
	var miss := missing(fl, rooms[type_id], defs)
	return {"ok": miss.is_empty(), "missing": miss, "flood": fl}

static func judge(placed: Dictionary, cell: Vector2i, rooms: Dictionary, defs: Dictionary) -> Dictionary:
	## The room at `cell`: {"type", "name", "valid", "missing", "flood"}. The first complete type (file order) names it;
	## otherwise the first type whose station stands there says what it lacks. An enclosed empty space has type "".
	var fl := flood(placed, cell)
	var out := {"type": "", "name": "", "valid": false, "missing": [], "flood": fl}
	if not fl.enclosed:
		return out
	for t in rooms:
		if missing(fl, rooms[t], defs).is_empty():
			return {"type": t, "name": String(rooms[t].name), "valid": true, "missing": [], "flood": fl}
	for pass_station in [true, false]:   # a station says more than a stray shelf or rack
		for t in rooms:
			var present := false
			for id in rooms[t].needs:
				if fl.count.has(id) and (not pass_station or String(rooms[t].station) == id):
					present = true
			if present:
				return {"type": t, "name": String(rooms[t].name), "valid": false, "missing": missing(fl, rooms[t], defs), "flood": fl}
	return out

static func find_rooms(placed: Dictionary, rooms: Dictionary, defs: Dictionary) -> Array:
	## Every complete room holding furniture, once each.
	var out := []
	var done := {}
	for c in placed:
		if done.has(c) or not bool(defs.get(placed[c], {}).get("furniture", false)):
			continue
		var r := judge(placed, c, rooms, defs)
		for k in r.flood.cells:
			done[k] = true
		if r.valid:
			out.append(r)
	return out

static func piece_label(defs: Dictionary, rooms: Dictionary, piece: String) -> String:
	## Build-mode caption: name, cost, and for furniture the room it belongs to.
	var cost := PackedStringArray()
	for id in defs[piece].cost:
		cost.append("%d %s" % [int(defs[piece].cost[id]), id])
	var t := String(defs[piece].get("room", ""))
	return "%s (%s)%s" % [defs[piece].name, ", ".join(cost), " for a " + String(rooms[t].name) if t != "" else ""]
