extends BaseTest

func test_gear_monotonic_with_speed() -> void:
	var g := 1
	for s in range(0, 331, 2):
		var n := EngineMath.gear_for(g, float(s))
		check(n >= g, "never downshifts while speeding up")
		g = n
	check_eq(g, EngineMath.GEARS)
	for s in range(330, -1, -2):
		var n := EngineMath.gear_for(g, float(s))
		check(n <= g, "never upshifts while slowing")
		g = n
	check_eq(g, 1)

func test_hysteresis_no_flutter() -> void:
	for i in EngineMath.GEARS - 1:
		var edge: float = EngineMath.GEAR_TOP[i]
		check(EngineMath.DOWN_AT[i] < edge - 10.0, "gap between shift points")
		var g := EngineMath.gear_for(i + 1, edge + 1.0)
		check_eq(g, i + 2)
		for k in 20:
			g = EngineMath.gear_for(g, edge + (3.0 if k % 2 == 0 else -3.0))
			check_eq(g, i + 2, "holds the gear around the shift point")

func test_rpm_climbs_and_drops_on_upshift() -> void:
	check(EngineMath.rpm(2, 130.0) > EngineMath.rpm(2, 90.0))
	for i in EngineMath.GEARS - 1:
		var s: float = EngineMath.GEAR_TOP[i] + 0.5
		var before := EngineMath.rpm(i + 1, s)
		var after := EngineMath.rpm(i + 2, s)
		check(after < before - 0.15, "rpm drops")
		check(EngineMath.pitch_scale(after, i + 2) < EngineMath.pitch_scale(before, i + 1), "pitch drops")
	check_eq(EngineMath.rpm(1, 0.0), EngineMath.IDLE_RPM)
	check(EngineMath.rpm(4, 999.0) <= 1.0)

func test_volume_rules() -> void:
	var idle := EngineMath.level(true, 10.0, EngineMath.IDLE_RPM, 0.0)
	check(idle > 0.01 and EngineMath.volume_db(idle) > EngineMath.SILENT_DB, "idle audible")
	check(EngineMath.level(true, 10.0, 0.6, 1.0) > EngineMath.level(true, 10.0, 0.6, 0.0), "throttle louder than coast")
	check_eq(EngineMath.level(false, 10.0, 0.6, 1.0), 0.0, "not driving")
	check_eq(EngineMath.level(true, 0.0, 0.6, 1.0), 0.0, "stalled")
	check_eq(EngineMath.volume_db(0.0), EngineMath.SILENT_DB)

func test_load() -> void:
	check_eq(EngineMath.engine_load(1.0, 100.0), 1.0)
	check_eq(EngineMath.engine_load(-1.0, 100.0), 0.0, "braking is not load")
	check(EngineMath.engine_load(-1.0, -30.0) > 0.0, "reversing works the engine")

func test_misfire() -> void:
	var coughs := 0
	for i in 200:
		var t := i / 30.0
		check_eq(EngineMath.misfire(100.0, t)["gain"], 1.0, "healthy runs clean")
		var a := EngineMath.misfire(10.0, t)
		check_eq(a, EngineMath.misfire(10.0, t), "deterministic")
		if float(a["gain"]) < 1.0:
			coughs += 1
	check(coughs > 10 and coughs < 150, "coughs some of the time")

func test_loop_buffer_and_seam() -> void:
	var b := EngineMath.loop_samples()
	check_eq(b.size(), EngineMath.LOOP_SAMPLES * 2)
	check_eq(EngineMath.LOOP_CYCLES % 2, 0)
	var biggest := 0
	var peak := 0
	for i in range(1, EngineMath.LOOP_SAMPLES):
		biggest = maxi(biggest, absi(b.decode_s16(i * 2) - b.decode_s16(i * 2 - 2)))
		peak = maxi(peak, absi(b.decode_s16(i * 2)))
	check(peak > 8000, "not silence")
	var seam := absi(b.decode_s16(0) - b.decode_s16(b.size() - 2))
	check(seam <= biggest, "seam step no bigger than any inner step")
	check_eq(b, EngineMath.loop_samples(), "deterministic")
