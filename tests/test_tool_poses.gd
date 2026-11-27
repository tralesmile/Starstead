extends BaseTest

func test_kinds() -> void:
	for t in ["axe", "pickaxe", "club"]:
		check_eq(PoseMath.kind(t), "heavy", t)
	check_eq(PoseMath.kind("hoe"), "hoe")
	check_eq(PoseMath.kind("watering_can"), "can")
	for t in ["scythe", "hand", "rod", "turnip_seed", ""]:
		check_eq(PoseMath.frame(t, 0.5), PlayerMath.TOOL_FRAME, "generic pose for '%s'" % t)
		check(is_equal_approx(PoseMath.swing_time(t), 0.18), "generic timing unchanged")

func _sequence(tool: String) -> Array:
	var seq: Array = []
	for i in 101:
		var f := PoseMath.frame(tool, float(i) / 100.0)
		if seq.is_empty() or seq[-1] != f:
			seq.append(f)
	return seq

func test_phase_order() -> void:
	check_eq(_sequence("axe"), [12, 13, 14], "wind-up, strike, recover")
	check_eq(_sequence("pickaxe"), [12, 13, 14])
	check_eq(_sequence("hoe"), [15, 16, 17], "reach, chop, drag")
	check_eq(_sequence("watering_can"), [18, 19, 18], "hold, pour, level again")

func test_progress() -> void:
	check(is_equal_approx(PoseMath.progress(0.28, 0.28), 0.0))
	check(is_equal_approx(PoseMath.progress(0.0, 0.28), 1.0))
	check(is_equal_approx(PoseMath.progress(-1.0, 0.28), 1.0))
	check(is_equal_approx(PoseMath.progress(0.1, 0.0), 1.0), "no divide by zero")

func test_tool_stays_in_hands() -> void:
	for col in range(PoseMath.HEAVY_WIND, PoseMath.BOW_DRAWN):
		check(PoseMath.has_grip(col), "grip for column %d" % col)
		var r := PoseMath.grip(col, PlayerMath.Facing.RIGHT)
		var l := PoseMath.grip(col, PlayerMath.Facing.LEFT)
		check_eq(l, Vector2(-r.x, r.y), "left mirrors right")
	check(not PoseMath.has_grip(PlayerMath.TOOL_FRAME), "generic tools keep the old placement")

func test_grips_sit_on_the_drawn_fists() -> void:
	## Every grip must have a skin pixel of that frame within 3px (art and table cannot drift apart).
	var img: Image = (load("res://assets/sprites/player_hd.png") as Texture2D).get_image()
	var skins := [Color("#b87656"), Color("#d4986e"), Color("#e8b48c"), Color("#f6cca4"), Color("#7a4634")]
	for col in range(PoseMath.HEAVY_WIND, PoseMath.BOW_DRAWN):
		for facing in 4:
			var g := PoseMath.grip(col, facing) + Vector2(col * 32 + 16, facing * 48 + 46)
			var found := false
			for dx in range(-4, 5):
				for dy in range(-3, 4):
					var c := img.get_pixel(int(g.x) + dx, clampi(int(g.y) + dy, 0, 191))
					for s in skins:
						if c.a > 0.5 and c.is_equal_approx(s):
							found = true
			check(found, "fist under the grip, column %d facing %d" % [col, facing])

func test_angles() -> void:
	var r := PlayerMath.Facing.RIGHT
	check(PoseMath.tool_deg("axe", 0.2, r) > 90.0, "wind-up cocks the axe back over the head")
	check(PoseMath.tool_deg("axe", 0.6, r) < -20.0, "strike drives it down in front")
	check(PoseMath.tool_deg("axe", 0.6, PlayerMath.Facing.DOWN) < -75.0, "facing the camera the strike points down")
	check(PoseMath.tool_deg("hoe", 0.3, r) > 60.0 and PoseMath.tool_deg("hoe", 0.3, r) < 90.0, "hoe lifted high, out ahead of the face")
	check(PoseMath.tool_deg("hoe", 0.65, r) < -25.0, "hoe in the soil")
	var drag := PoseMath.tool_deg("hoe", 0.95, r)
	check(drag < -20.0 and drag > PoseMath.tool_deg("hoe", 0.71, r), "drag eases the head back")
	check(is_equal_approx(PoseMath.tool_deg("watering_can", 0.05, r), 45.0), "can held level")
	check(PoseMath.tool_deg("watering_can", 0.6, r) < 10.0, "spout tips down to pour")

func test_rotation_and_layering() -> void:
	check(is_equal_approx(PoseMath.rotation_for(45.0, 1.0), 0.0))
	check(PoseMath.rotation_for(-45.0, 1.0) > 0.0, "clockwise to point down-right")
	check(is_equal_approx(PoseMath.rotation_for(-45.0, -1.0), -PoseMath.rotation_for(-45.0, 1.0)))
	check_eq(PoseMath.grip_offset("axe", true).x, -PoseMath.grip_offset("axe", false).x)
	check(PoseMath.behind(PoseMath.HEAVY_STRIKE, PlayerMath.Facing.UP))
	check(not PoseMath.behind(PoseMath.HEAVY_WIND, PlayerMath.Facing.UP))
	check(not PoseMath.behind(PoseMath.HEAVY_STRIKE, PlayerMath.Facing.DOWN))
