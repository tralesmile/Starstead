extends BaseTest

func test_level_by_surface() -> void:
	var asp := SquealMath.level(150.0, 200.0, WorldGen.ASPHALT, 3.0)
	var gra := SquealMath.level(150.0, 200.0, WorldGen.GRASS, 3.0)
	check(asp > 0.5)
	check(gra < asp * 0.3, "grass is nearly silent")
	check(SquealMath.level(150.0, 200.0, WorldGen.ASPHALT, 3.0, 1.0) < asp, "rain muffles")

func test_quiet_cases() -> void:
	check_eq(SquealMath.level(20.0, 200.0, WorldGen.ASPHALT, 3.0), 0.0, "no slip")
	check_eq(SquealMath.level(200.0, 10.0, WorldGen.ASPHALT, 3.0), 0.0, "too slow")
	check_eq(SquealMath.level(200.0, 200.0, WorldGen.ASPHALT, 0.2), 0.0, "off the ground")
	check_eq(SquealMath.volume_db(0.0), SquealMath.SILENT_DB)

func test_volume_pitch_monotonic() -> void:
	check(SquealMath.volume_db(1.0) > SquealMath.volume_db(0.3))
	check(SquealMath.pitch(300.0) > SquealMath.pitch(50.0))
	check(SquealMath.pitch(9999.0) <= 1.5)

func test_loop_buffer() -> void:
	var b := SquealMath.loop_samples(1000)
	check_eq(b.size(), 2000)
	var any := false
	for i in b.size():
		if b[i] != 0:
			any = true
	check(any, "not silence")
	check_eq(SquealMath.loop_samples(500, 3), SquealMath.loop_samples(500, 3), "deterministic")
