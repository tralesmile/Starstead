extends BaseTest

func test_inside_box_camera_stays() -> void:
	check_eq(CameraMath.deadzone(Vector2(100, 100), Vector2(104, 97), Vector2(8, 6)), Vector2(100, 100))

func test_leaving_box_drags_camera() -> void:
	check_eq(CameraMath.deadzone(Vector2(100, 100), Vector2(120, 100), Vector2(8, 6)), Vector2(112, 100))
	check_eq(CameraMath.deadzone(Vector2(100, 100), Vector2(100, 70), Vector2(8, 6)), Vector2(100, 76))

func test_target_never_outside_box_after_update() -> void:
	var cam := Vector2.ZERO
	for i in 50:
		var t := Vector2(i * 5.0, sin(i) * 40.0)
		cam = CameraMath.deadzone(cam, t, Vector2(8, 6))
		check(absf(t.x - cam.x) <= 8.001 and absf(t.y - cam.y) <= 6.001)
