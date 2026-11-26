class_name BikeModel
extends RefCounted
## Pure rules for the Halden criterium: LAPS anticlockwise laps of an oval shaped like CircuitModel's ellipse.
## Hold Space to push (burns stamina) or let it spin easy (recovers); drag grows with v^2 and a wheel in front
## takes a big bite out of it; bends have a grip limit sqrt(grip * radius), lower in the wet.
## Units: metres, seconds. `s` = distance along the centre line from the start line (negative on the grid),
## `l` = sideways offset from the centre line (+ = outside). Speeds are m/s along the rider's own (longer or shorter) line.

const A := 41.8                  # centre-line semi-axes (CircuitModel 22:15, scaled)
const B := 28.5
const LANES := [-2.3, 0.0, 2.3]  # inside, middle, outside
const START_LANE := 1
const LAPS := 3
const LINE_THETA := 0.62          # the line sits right of the middle of the near side: a long run-in for the sprint
const RIDERS := 5
const TICK := 1.0 / 60.0
const SAMPLES := 720

const P_HARD := 14.4             # pedal power per kg
const P_EASY := 4.4
const P_WINDED := 2.9
const MIN_DRIVE_V := 4.0         # below this the pedal force stops growing
const ROLL := 0.15               # rolling resistance (m/s^2)
const DRAG := 0.0045             # air drag per v^2
const BRAKE := 5.5
const DRAIN := 0.092             # stamina per second flat out
const REGEN := 0.062             # stamina per second spinning easy
const WINDED_REGEN := 0.05
const WIND_OK := 0.32

const DRAFT_MAX := 0.42          # share of the air drag a perfect wheel removes
const DRAFT_FULL := 5.2          # full effect up to this gap, none past DRAFT_END
const DRAFT_END := 11.0
const DRAFT_WIDTH := 1.5

const BIKE_LEN := 3.3
const BIKE_WIDTH := 1.5
const LINE_COST := 0.6            # how much of the extra length of a wider line really counts
const LANE_RATE := 3.6           # sideways m/s while changing line

const GRIP_DRY := 8.0
const GRIP_WET := 5.8
const SLIDE_RATIO := 1.13        # over the limit by more than this = slide
const WOBBLE_SCRUB := 5.0       # extra deceleration per unit of excess ratio
const SLIDE_TIME := 1.6
const SLIDE_KEEP := 0.38         # share of speed left after a slide
const SAFE_TIME := 1.2           # no second slide straight after getting up

const FEE := 20
const PRIZES := [100, 55, 30, 0, 0]   # best day: +$80, under one job shift
const BEST_KEY := "bike_best"
const DAY_KEY := "bike_day"

const NAMES := ["You", "Brandt", "Okoro", "Lind", "Moreau"]
const STYLES := ["player", "breakaway", "sprinter", "steady", "wheeler"]
const GRID := [[-5.6, 1], [-2.0, 0], [-2.0, 2], [-9.6, 0], [-9.6, 2]]   # [s, lane]; yours is the first one

static var _arc: PackedFloat32Array = PackedFloat32Array()

# ------------------------------------------------------------------ geometry

static func _table() -> PackedFloat32Array:
	if _arc.is_empty():
		var out := PackedFloat32Array([0.0])
		var prev := ellipse(0.0)
		for i in range(1, SAMPLES + 1):
			var p := ellipse(TAU * float(i) / SAMPLES)
			out.append(out[i - 1] + prev.distance_to(p))
			prev = p
		_arc = out
	return _arc

static func ellipse(theta: float) -> Vector2:
	## Centre-line point, screen axes (y down). theta 0 = bottom of the oval; theta grows heading east (anticlockwise on screen).
	return Vector2(A * sin(theta), B * cos(theta))

static func lap_length() -> float:
	return _table()[SAMPLES]

static func distance() -> float:
	return lap_length() * LAPS

static func _line_arc() -> float:
	return _table()[int(round(LINE_THETA / TAU * SAMPLES))]

static func theta_at(s: float) -> float:
	var t := _table()
	var d := fposmod(s + _line_arc(), t[SAMPLES])
	var i := clampi(t.bsearch(d) - 1, 0, SAMPLES - 1)
	var span := maxf(t[i + 1] - t[i], 0.0001)
	return TAU * (float(i) + (d - t[i]) / span) / SAMPLES

static func normal(theta: float) -> Vector2:
	## Unit vector pointing out of the oval.
	return Vector2(sin(theta) / A, cos(theta) / B).normalized()

static func tangent(theta: float) -> Vector2:
	## Unit vector in the direction of travel.
	return Vector2(A * cos(theta), -B * sin(theta)).normalized()

static func radius(s: float, l: float = 0.0) -> float:
	## Bend radius of the line `l` metres from the centre line.
	var th := theta_at(s)
	var q := A * A * cos(th) * cos(th) + B * B * sin(th) * sin(th)
	return pow(q, 1.5) / (A * B) + l

static func path_factor(s: float, l: float) -> float:
	## Metres of centre line covered per metre ridden: > 1 on the inside (shorter), < 1 outside.
	var r := radius(s)
	return r / (r + l * LINE_COST)

static func grip(wet: float) -> float:
	return lerpf(GRIP_DRY, GRIP_WET, clampf(wet, 0.0, 1.0))

static func wet_for(rain: float) -> float:
	return 0.0 if rain <= 0.0 else clampf(0.55 + 0.45 * rain, 0.0, 1.0)

static func corner_limit(s: float, l: float, wet: float) -> float:
	return sqrt(grip(wet) * maxf(radius(s, l), 1.0))

static func safe_speed(s: float, l: float, wet: float, horizon: float = 22.0) -> float:
	## Fastest speed now from which easing off and a touch of brake still makes every bend in the next `horizon` m.
	var best := 1e9
	var d := 0.0
	while d <= horizon:
		var lim := corner_limit(s + d, l, wet)
		best = minf(best, sqrt(lim * lim + 2.0 * BRAKE * 0.45 * d))
		d += 2.75
	return best

# ------------------------------------------------------------------ riders

static func rider(s: float = 0.0, lane: int = START_LANE, bonus: float = 0.0) -> Dictionary:
	return {"s": s, "lane": lane, "l": float(LANES[lane]), "v": 0.0, "stamina": 1.0, "winded": false, "bonus": bonus,
		"slide": 0.0, "safe": 0.0, "wobble": 0.0, "draft": 0.0, "blocked": false, "crashes": 0, "done": -1.0, "effort": 0.0, "pedal": 0.0}

static func grid(bonuses: Array = [], rng: RandomNumberGenerator = null) -> Array:
	## Starting field. With an rng the four rivals draw their grid spots; yours (mid-pack) is fixed.
	var slots: Array = GRID.duplicate()
	if rng != null:
		for k in range(RIDERS - 1, 1, -1):
			var j := rng.randi_range(1, k)
			var tmp: Array = slots[k]
			slots[k] = slots[j]
			slots[j] = tmp
	var out: Array = []
	for i in RIDERS:
		out.append(rider(float(slots[i][0]), int(slots[i][1]), float(bonuses[i]) if i < bonuses.size() else 0.0))
	return out

static func draft_strength(riders: Array, i: int) -> float:
	## 0..1: how good a wheel rider i is sitting on.
	var me: Dictionary = riders[i]
	var best := 0.0
	for j in riders.size():
		if j == i:
			continue
		var o: Dictionary = riders[j]
		var gap := float(o["s"]) - float(me["s"])
		var side := absf(float(o["l"]) - float(me["l"]))
		if gap <= 0.8 or gap >= DRAFT_END or side >= DRAFT_WIDTH:
			continue
		var k := clampf((DRAFT_END - gap) / (DRAFT_END - DRAFT_FULL), 0.0, 1.0)
		k *= clampf((DRAFT_WIDTH - side) / (DRAFT_WIDTH * 0.5), 0.0, 1.0)
		if float(o["slide"]) <= 0.0:
			best = maxf(best, k)
	return best

static func drag_mult(strength: float) -> float:
	return 1.0 - DRAFT_MAX * clampf(strength, 0.0, 1.0)

static func resist(v: float, draft: float) -> float:
	return ROLL + DRAG * v * v * drag_mult(draft)

static func lane_free(riders: Array, i: int, l: float) -> bool:
	## Can rider i occupy offset `l` here without riding into someone alongside?
	var me: Dictionary = riders[i]
	for j in riders.size():
		if j == i:
			continue
		var o: Dictionary = riders[j]
		if float(o["done"]) >= 0.0:
			continue
		if absf(float(o["s"]) - float(me["s"])) < BIKE_LEN * 0.95:
			var now := absf(float(o["l"]) - float(me["l"]))
			var then := absf(float(o["l"]) - l)
			if then < BIKE_WIDTH and then < now:
				return false
	return true

static func step_rider(riders: Array, i: int, inp: Dictionary, wet: float, dt: float) -> Array:
	## Advance one rider. inp: effort 0..1, brake bool, lane (target lane index). Returns events: "wobble", "slide", "winded".
	var r: Dictionary = riders[i]
	var events: Array = []
	var s := float(r["s"])
	var v := float(r["v"])
	r["safe"] = maxf(0.0, float(r["safe"]) - dt)
	r["wobble"] = maxf(0.0, float(r["wobble"]) - dt)
	var finished_already := float(r["done"]) >= 0.0
	var brake := bool(inp.get("brake", false))
	var effort := clampf(float(inp.get("effort", 0.0)), 0.0, 1.0)
	if finished_already:
		effort = 0.0
		brake = v > 5.0
	if float(r["slide"]) > 0.0:   # on the deck / unclipped: roll, catch breath, no pedalling
		r["slide"] = maxf(0.0, float(r["slide"]) - dt)
		v = maxf(0.0, v - 2.0 * dt)
		effort = 0.0
		brake = false
	r["lane"] = clampi(int(inp.get("lane", r["lane"])), 0, LANES.size() - 1)
	# sideways: slide towards the chosen line unless somebody is alongside
	if float(r["slide"]) <= 0.0:
		var want := move_toward(float(r["l"]), float(LANES[r["lane"]]), LANE_RATE * dt)
		if lane_free(riders, i, want):
			r["l"] = want
	var draft := draft_strength(riders, i)
	r["draft"] = draft
	# pedals
	var power := 0.0
	var stamina := float(r["stamina"])
	if float(r["slide"]) > 0.0:
		stamina += WINDED_REGEN * dt
	elif r["winded"]:
		power = P_WINDED if not brake else 0.0
		effort = 0.0
		stamina += WINDED_REGEN * dt
	elif brake:
		effort = 0.0
		stamina += REGEN * dt
	else:
		power = lerpf(P_EASY, P_HARD, effort)
		stamina += lerpf(REGEN, -DRAIN, effort) * dt
	r["effort"] = effort
	r["stamina"] = clampf(stamina, 0.0, 1.0)
	if float(r["stamina"]) <= 0.0 and not r["winded"]:
		r["winded"] = true
		events.append("winded")
	elif r["winded"] and float(r["stamina"]) >= WIND_OK:
		r["winded"] = false
	var acc := power * (1.0 + float(r["bonus"])) / maxf(v, MIN_DRIVE_V) - resist(v, draft)
	if brake:
		acc -= BRAKE
	v = maxf(0.0, v + acc * dt)
	# cornering
	if float(r["slide"]) <= 0.0 and not finished_already:
		var ratio := v / corner_limit(s, float(r["l"]), wet)
		if ratio > SLIDE_RATIO and float(r["safe"]) <= 0.0:
			v *= SLIDE_KEEP
			r["slide"] = SLIDE_TIME
			r["safe"] = SLIDE_TIME + SAFE_TIME
			r["crashes"] = int(r["crashes"]) + 1
			events.append("slide")
		elif ratio > 1.0:
			v = maxf(0.0, v - WOBBLE_SCRUB * (ratio - 1.0) * dt)
			if float(r["wobble"]) <= 0.0:
				events.append("wobble")
			r["wobble"] = 0.25
	# forward, but never through the back wheel of someone on the same line
	var ns := s + v * path_factor(s, float(r["l"])) * dt
	r["blocked"] = false
	for j in riders.size():
		if j == i:
			continue
		var o: Dictionary = riders[j]
		if float(o["done"]) >= 0.0 or absf(float(o["l"]) - float(r["l"])) >= BIKE_WIDTH:
			continue
		var os := float(o["s"])
		if os > s and ns > os - BIKE_LEN:
			ns = maxf(s, os - BIKE_LEN)
			v = minf(v, maxf(float(o["v"]), 1.0))
			r["blocked"] = true
	r["v"] = v
	r["s"] = ns
	r["pedal"] = fposmod(float(r["pedal"]) + (v * (0.35 + 0.75 * effort) if power > 0.0 else 0.0) * dt, 4.0)
	return events

static func step(riders: Array, inputs: Array, wet: float, t: float, dt: float) -> Array:
	## One tick for the whole field, leaders first. `t` = race time at the start of the tick.
	## Returns [{"i": rider, "ev": name}], including "lap" and "finish".
	var order: Array = range(riders.size())
	order.sort_custom(func(a, b): return float(riders[a]["s"]) > float(riders[b]["s"]))
	var out: Array = []
	var goal := distance()
	for i in order:
		var r: Dictionary = riders[i]
		var before := float(r["s"])
		for ev in step_rider(riders, i, inputs[i], wet, dt):
			out.append({"i": i, "ev": ev})
		var after := float(r["s"])
		if float(r["done"]) < 0.0:
			if after >= goal:
				var frac := (goal - before) / maxf(after - before, 0.0001)
				r["done"] = t + dt * clampf(frac, 0.0, 1.0)
				out.append({"i": i, "ev": "finish"})
			elif before >= 0.0 and int(after / lap_length()) > int(before / lap_length()):
				out.append({"i": i, "ev": "lap"})
	return out

static func place(riders: Array, i: int) -> int:
	## 0 = first. Finishers by time, then everyone else by distance.
	var me: Dictionary = riders[i]
	var p := 0
	for j in riders.size():
		if j == i:
			continue
		var o: Dictionary = riders[j]
		var tm := float(me["done"])
		var to := float(o["done"])
		if tm >= 0.0:
			if to >= 0.0 and to < tm:
				p += 1
		elif to >= 0.0 or float(o["s"]) > float(me["s"]):
			p += 1
	return p

static func lap_of(s: float) -> int:
	return clampi(int(floorf(maxf(s, 0.0) / lap_length())) + 1, 1, LAPS)

static func prize(place_idx: int) -> int:
	return PRIZES[clampi(place_idx, 0, PRIZES.size() - 1)]

static func ordinal(place_idx: int) -> String:
	return ["1st", "2nd", "3rd", "4th", "5th"][clampi(place_idx, 0, 4)]

# ------------------------------------------------------------------ one paid race a day (kept in sport_best, so it saves)

static func paid_today(best: Dictionary, day: int) -> bool:
	return int(best.get(DAY_KEY, -1)) == day

static func entry(best: Dictionary, day: int, money: int) -> Dictionary:
	## {"paid": bool, "why": "" | "done" | "broke"}; not paid = free practice.
	if paid_today(best, day):
		return {"paid": false, "why": "done"}
	if money < FEE:
		return {"paid": false, "why": "broke"}
	return {"paid": true, "why": ""}

static func record_time(best: Dictionary, seconds: float) -> bool:
	var cs := int(round(seconds * 100.0))
	if best.has(BEST_KEY) and cs >= int(best[BEST_KEY]):
		return false
	best[BEST_KEY] = cs
	return true

# ------------------------------------------------------------------ rivals

static func personality(i: int, rng: RandomNumberGenerator = null) -> Dictionary:
	## Rider i's style with a little day-to-day form, so no two races are the same.
	var jit := func(a: float) -> float: return 0.0 if rng == null else rng.randf_range(-a, a)
	var style: String = STYLES[i]
	var base: Dictionary = {
		"breakaway": {"bonus": -0.007, "kick": 45.0, "cruise": 0.48},
		"sprinter": {"bonus": 0.003, "kick": 115.0, "cruise": 0.46},
		"steady": {"bonus": 0.016, "kick": 112.0, "cruise": 0.57},
		"wheeler": {"bonus": 0.006, "kick": 100.0, "cruise": 0.50},
	}.get(style, {"bonus": 0.0, "kick": 110.0, "cruise": 0.5})
	return {"style": style, "bonus": float(base["bonus"]) + jit.call(0.015), "kick": float(base["kick"]) + jit.call(25.0),
		"cruise": float(base["cruise"]) + jit.call(0.035), "attack": 175.0 + jit.call(80.0), "nerve": 0.985 + jit.call(0.025), "attacking": false}

static func ahead_of(riders: Array, i: int, reach: float, lane_l: float = 1e9) -> int:
	## Nearest unfinished rider ahead within `reach` metres (optionally only near offset lane_l). -1 = none.
	var me: Dictionary = riders[i]
	var best := -1
	var bg := reach
	for j in riders.size():
		var o: Dictionary = riders[j]
		var gap := float(o["s"]) - float(me["s"])
		if j == i or gap <= 0.0 or gap >= bg or float(o["done"]) >= 0.0:
			continue
		if lane_l < 1e8 and absf(float(o["l"]) - lane_l) >= BIKE_WIDTH:
			continue
		best = j
		bg = gap
	return best

static func best_wheel(riders: Array, i: int, reach: float) -> int:
	## The wheel worth sitting on: the nearest rider ahead, unless they have let a gap open to someone further
	## up the road who is still in reach (then bridge to that one). -1 = nobody ahead.
	var pick := ahead_of(riders, i, reach)
	for hop in riders.size():
		if pick < 0:
			break
		var next := ahead_of(riders, pick, reach)
		if next < 0 or float(riders[next]["s"]) - float(riders[pick]["s"]) <= 6.0:
			break
		pick = next
	return pick

static func ai_input(riders: Array, i: int, who: Dictionary, wet: float) -> Dictionary:
	var r: Dictionary = riders[i]
	var s := float(r["s"])
	var left := distance() - s
	var stamina := float(r["stamina"])
	var style: String = who["style"]
	var effort := float(who["cruise"])
	var kicking := left < float(who["kick"])
	var wheel := ahead_of(riders, i, 16.0)
	if style == "sprinter" or style == "wheeler":
		wheel = best_wheel(riders, i, 18.0)
	match style:
		"breakaway":   # jumps off the front early, then hangs on
			if s > 25.0 and s < float(who["attack"]) and stamina > 0.22:
				effort = 0.9
			elif stamina < 0.28:
				effort = 0.28
		"sprinter", "wheeler":   # hide on a wheel, close gaps, save it for the line
			if wheel >= 0:
				var gap := float(riders[wheel]["s"]) - s
				effort = clampf(float(who["cruise"]) - 0.12 + (gap - 3.2) * 0.14, 0.05, 1.0 if stamina > 0.45 else 0.62)
			elif stamina > 0.5:
				effort = 0.7
		"steady":   # rides its own tempo
			effort = float(who["cruise"]) + (stamina - 0.55) * 0.35
			if wheel >= 0 and float(riders[wheel]["s"]) - s < 9.0:
				effort -= 0.08
	var front := 0.0
	for o in riders:
		front = maxf(front, float(o["s"]) - s)
	if style != "breakaway" and left < lap_length() * 1.3 and front > 5.0 and stamina > 0.4:
		effort = maxf(effort, 0.9)   # the bell is coming: nobody lets a gap stand
	if s < 25.0:
		effort = maxf(effort, 0.75)
	if stamina < 0.14 and not kicking:
		effort = minf(effort, 0.3)
	if kicking:
		effort = 1.0 if stamina > 0.04 else 0.45
	# line: follow the wheel, go round it when it is in the way, otherwise hug the inside
	var lane := int(r["lane"])
	var in_way := ahead_of(riders, i, 5.8, float(LANES[lane]))
	var boxed := in_way >= 0 and wheel >= 0 and in_way != wheel and float(riders[wheel]["s"]) - float(riders[in_way]["s"]) > 4.0
	if in_way >= 0 and (boxed or kicking or style == "breakaway" or float(riders[in_way]["v"]) < float(r["v"]) - 0.7):
		for cand in [lane - 1, lane + 1]:
			if cand >= 0 and cand < LANES.size() and ahead_of(riders, i, 7.4, float(LANES[cand])) < 0 and lane_free(riders, i, move_toward(float(r["l"]), float(LANES[cand]), 0.4)):
				lane = cand
				break
	elif wheel >= 0 and not kicking and (style == "sprinter" or style == "wheeler"):
		var wl := int(riders[wheel]["lane"])
		lane += signi(wl - lane)
	elif ahead_of(riders, i, 8.0, float(LANES[maxi(lane - 1, 0)])) < 0 and lane > 0 and lane_free(riders, i, float(r["l"]) - 0.4):
		lane -= 1
	# bends
	var allow := safe_speed(s, float(r["l"]), wet) * float(who["nerve"])
	var v := float(r["v"])
	var brake := v > allow * 1.01
	if v > allow * 0.965:
		effort = minf(effort, clampf((allow * 1.0 - v) * 1.6 + 0.2, 0.0, 1.0))
	return {"effort": effort, "brake": brake, "lane": lane}
