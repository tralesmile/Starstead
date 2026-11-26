class_name FerryModel
extends RefCounted
## Pure ferry rules (E13): Halden Harbour pier head <-> Gull Isle. Hourly sailings; the fare includes the trip home,
## and the trip home always runs (even broke or in a storm) so nobody gets stranded before the last boat.
## Times are clock minutes since 06:00.

const FARE := 60
const OUT_FIRST := 60      # 07:00
const OUT_LAST := 780      # 19:00
const BACK_FIRST := 120    # 08:00
const BACK_LAST := 960     # 22:00
const EVERY := 60
const CROSSING := 35
const ROUGH_EXTRA := 15
const STORM := 0.8
const HARBOUR_POST := Vector2i(218, 120)
const HARBOUR_LANDING := Vector2i(220, 120)
const HARBOUR_MOOR := Vector2(220.5, 123.4)   # cells: where the boat floats
const ISLE_MOOR := Vector2(263.5, 163.4)

static func next_departure(minutes: float, outbound: bool) -> int:
	## Next sailing at or after `minutes`, or -1 when the last boat has gone.
	var first := OUT_FIRST if outbound else BACK_FIRST
	var last := OUT_LAST if outbound else BACK_LAST
	if minutes <= first:
		return first
	var t := first + int(ceil((minutes - first) / float(EVERY))) * EVERY
	return t if t <= last else -1

static func crossing_minutes(rain: float) -> int:
	return CROSSING + (ROUGH_EXTRA if rain >= STORM else 0)

static func quote(minutes: float, rain: float, money: int, outbound: bool) -> Dictionary:
	## {ok, why, fare, depart, arrive (clock minutes)}
	var fare := FARE if outbound else 0
	var dep := next_departure(minutes, outbound)
	var out := {"ok": false, "why": "", "fare": fare, "depart": dep, "arrive": dep + crossing_minutes(rain)}
	if outbound and rain >= STORM:
		out["why"] = "Storm - the ferry stays tied up today"
	elif dep < 0:
		out["why"] = "The last boat has gone (07:00-19:00 out, back until 22:00)"
	elif money < fare:
		out["why"] = "A return ticket costs $%d" % fare
	else:
		out["ok"] = true
	return out

static func time_text(minutes: int) -> String:
	var m := (6 * 60 + minutes) % (24 * 60)
	return "%02d:%02d" % [m / 60, m % 60]

static func bob(t: float, rain: float) -> Dictionary:
	## Moored/sailing hull motion: heave in pixels and roll in radians; both grow with the weather.
	var rough := clampf(rain, 0.0, 1.0)
	return {"y": sin(t * 2.1) * lerpf(1.2, 4.0, rough), "roll": sin(t * 1.4 + 0.7) * lerpf(0.012, 0.06, rough)}

static func sail_progress(f: float) -> float:
	## Eases out of the berth and into the next one.
	var x := clampf(f, 0.0, 1.0)
	return x * x * (3.0 - 2.0 * x)

static func sail_speed(f: float) -> float:
	## 0..1.5: how fast the boat is moving (drives the wake length).
	var x := clampf(f, 0.0, 1.0)
	return 6.0 * x * (1.0 - x)
