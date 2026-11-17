extends BaseTest

func test_rise_monotonic_and_whole() -> void:
	var prev := -1.0
	for i in 12:
		var r := FloatMath.rise(i * 0.1)
		check(r >= prev)
		check_eq(r, roundf(r))
		prev = r
	check_eq(FloatMath.rise(0.0), 0.0)

func test_alpha_holds_then_fades() -> void:
	check_eq(FloatMath.alpha(0.3), 1.0)
	check(FloatMath.alpha(0.9) < 1.0)
	check_eq(FloatMath.alpha(2.0), 0.0)

func test_stack_offsets_up() -> void:
	check(FloatMath.stack_offset(2) < FloatMath.stack_offset(1))
