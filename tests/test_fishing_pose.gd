extends BaseTest

func test_no_pose() -> void:
	check_eq(PlayerMath.fishing_frame(false, 99.0, false, 0.0), -1)
	check_eq(PlayerMath.fishing_frame(false, 0.3, false, 1.0), -1, "follow-through is over at 0.3 s")

func test_cast_poses() -> void:
	check_eq(PlayerMath.fishing_frame(true, 99.0, false, 0.0), 8, "wind-up while charging")
	check_eq(PlayerMath.fishing_frame(true, 0.1, true, 0.5), 8, "charging wins")
	check_eq(PlayerMath.fishing_frame(false, 0.0, false, 0.0), 9)
	check_eq(PlayerMath.fishing_frame(false, 0.29, true, 0.5), 9, "follow-through beats reeling")

func test_reel_alternates() -> void:
	check_eq(PlayerMath.fishing_frame(false, 99.0, true, 0.05), 10)
	check_eq(PlayerMath.fishing_frame(false, 99.0, true, 0.22), 11)
	check_eq(PlayerMath.fishing_frame(false, 99.0, true, 0.38), 10)
	var changes := 0
	var last := PlayerMath.fishing_frame(false, 99.0, true, 0.001)
	for i in 100:
		var f := PlayerMath.fishing_frame(false, 99.0, true, 0.001 + float(i + 1) * 0.01)
		changes += 1 if f != last else 0
		last = f
	check_eq(changes, 6, "about 6 pose changes a second")

func test_sheet_columns() -> void:
	var tex: Texture2D = load("res://assets/sprites/player_hd.png")
	check_eq(tex.get_width(), PlayerMath.SHEET_COLS * 32)
	check_eq(tex.get_height(), 4 * 48)
