class_name EngineMath
extends RefCounted
## Pure rules for the car's engine note: a 4-gear automatic over VehicleMath's speed range, rpm that climbs within
## a gear and drops on the upshift, loudness from load, a misfire for battered engines, and a procedural loop
## (no audio assets). Sound only: nothing here touches the driving physics.

const RATE := 22050
const SILENT_DB := -60.0
const GEARS := 4
const GEAR_TOP: Array[float] = [75.0, 140.0, 215.0, VehicleMath.MAX_SPEED]   # px/s at redline per gear
const DOWN_AT: Array[float] = [55.0, 112.0, 180.0]   # below this, gear i+2 drops to i+1 (hysteresis under GEAR_TOP)
const IDLE_RPM := 0.15
const REV_RPM := 0.15        # extra revs from the throttle while barely moving (clutch slip in first)
const SHIFT_CUT := 0.12      # s of softer sound after an upshift
const SHIFT_GAIN := 0.45
const MISFIRE_HEALTH := 40.0
const MISFIRE_HZ := 14.0
const LOOP_SAMPLES := 4410   # 0.2 s
const LOOP_CYCLES := 12      # whole cycles of the 60 Hz fundamental; even, so the half-order is whole too

static func gear_for(gear: int, speed: float) -> int:
	## Next gear (1..4) from the current one; shifts up at GEAR_TOP, down only below DOWN_AT.
	var g := clampi(gear, 1, GEARS)
	var s := absf(speed)
	while g < GEARS and s > GEAR_TOP[g - 1]:
		g += 1
	while g > 1 and s < DOWN_AT[g - 2]:
		g -= 1
	return g

static func rpm(gear: int, speed: float, load_amt: float = 0.0) -> float:
	## IDLE_RPM..1 within the gear.
	var g := clampi(gear, 1, GEARS)
	var r := absf(speed) / GEAR_TOP[g - 1]
	var floor_rpm := IDLE_RPM + (REV_RPM * clampf(load_amt, 0.0, 1.0) if g == 1 else 0.0)
	return clampf(maxf(r, floor_rpm), IDLE_RPM, 1.0)

static func engine_load(throttle: float, forward_speed: float) -> float:
	## 0..1 how hard the engine works: throttle forward, or reversing under power. Braking is not load.
	if throttle > 0.0:
		return minf(throttle, 1.0)
	if throttle < 0.0 and forward_speed <= 1.0:
		return minf(-throttle, 1.0) * 0.6
	return 0.0

static func pitch_scale(r: float, gear: int) -> float:
	return 0.7 + 1.3 * clampf(r, 0.0, 1.0) + 0.08 * float(clampi(gear, 1, GEARS) - 1)

static func level(driving: bool, fuel: float, r: float, load_amt: float) -> float:
	## 0..1 loudness: silent with nobody driving or a stalled (empty) engine; throttle louder than coasting.
	if not driving or fuel <= 0.0:
		return 0.0
	return clampf(0.3 + 0.2 * clampf(r, 0.0, 1.0) + 0.45 * clampf(load_amt, 0.0, 1.0), 0.0, 1.0)

static func volume_db(lv: float) -> float:
	if lv <= 0.01:
		return SILENT_DB
	return lerpf(-30.0, -11.0, clampf(lv, 0.0, 1.0))

static func misfire(health: float, time: float) -> Dictionary:
	## {gain, pitch} multipliers. Healthy engines run clean; below MISFIRE_HEALTH some 1/14 s slots cough,
	## more often the worse the damage. Deterministic in (health, time).
	if health >= MISFIRE_HEALTH:
		return {"gain": 1.0, "pitch": 1.0}
	var sev := clampf(1.0 - health / MISFIRE_HEALTH, 0.0, 1.0)
	var slot := int(floor(maxf(time, 0.0) * MISFIRE_HZ))
	var roll := float(posmod(slot * 7919 + (slot * slot) * 31 + 13, 101)) / 101.0
	if roll < 0.15 + 0.3 * sev:
		return {"gain": 0.65 - 0.4 * sev, "pitch": 0.93 - 0.08 * sev}
	return {"gain": 1.0, "pitch": 1.0 + 0.025 * sev * sin(time * 23.0)}

static func loop_samples(n: int = LOOP_SAMPLES, cycles: int = LOOP_CYCLES, seed_v: int = 11) -> PackedByteArray:
	## 16-bit mono seamless loop: band-limited saw, a half-order pulse (cylinder lope) and low-passed noise.
	## Every tone completes whole cycles over n (cycles must be even) and the noise filter is warmed up on the
	## same noise, so its state wraps around too.
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	var noise := PackedFloat32Array()
	noise.resize(n)
	for i in n:
		noise[i] = rng.randf_range(-1.0, 1.0)
	var lp := 0.0
	for i in n:
		lp += 0.12 * (noise[i] - lp)
	var out := PackedByteArray()
	out.resize(n * 2)
	for i in n:
		var ph := TAU * float(cycles) * float(i) / float(n)
		var saw := 0.0
		for h in range(1, 9):
			saw += sin(ph * h) / float(h)
		var half := ph * 0.5
		var pulse := sin(half) + 0.5 * sin(half * 3.0) + 0.25 * sin(half * 5.0)
		lp += 0.12 * (noise[i] - lp)
		var v := clampf(saw * 0.34 + pulse * 0.2 + lp * 0.35, -1.0, 1.0)
		out.encode_s16(i * 2, int(v * 30000.0))
	return out
